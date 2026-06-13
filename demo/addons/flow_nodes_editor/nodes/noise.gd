@tool
extends FlowNodeBase

const MAGIC_SCALE_FACTOR := 0.0001
const PERLIN_M := [
	Vector2(1.6, 1.2),
	Vector2(-1.2, 1.6),
]
const FRACTIONAL_BROWNIAN_M := [
	Vector2(1.910673, -0.5910404),
	Vector2(0.5910404, 1.910673),
]
const MIN_BOUNDS_SIZE := 0.0001

func _init():
	meta_node = {
		"title" : "Spatial Noise",
		"settings" : NoiseNodeSettings,
		"ins" : [{ "label" : "In" }],
		"outs" : [{ "label" : "Out" }],
		"aliases" : ["Noise"],
		"category" : "Spatial",
		"tooltip" : "Applies UE PCG-style 2D spatial noise to point data and writes the result to Value Target.",
	}

func _fract(value : float) -> float:
	return value - floorf(value)

func _fract_vec2(value : Vector2) -> Vector2:
	return Vector2(_fract(value.x), _fract(value.y))

func _floor_vec2(value : Vector2) -> Vector2:
	return Vector2(floorf(value.x), floorf(value.y))

func _multiply_matrix_2d(point : Vector2, matrix : Array) -> Vector2:
	return point.x * matrix[0] + point.y * matrix[1]

func _floor_vec2i(value : Vector2) -> Vector2i:
	return Vector2i(floori(value.x), floori(value.y))

func _value_hash(position : Vector2) -> float:
	position = 50.0 * _fract_vec2(position * 0.3183099 + Vector2(0.71, 0.113))
	return -1.0 + 2.0 * _fract(position.x * position.y * (position.x + position.y))

func _voronoi_hash_2d(cell : Vector2i) -> Vector2:
	var p := Vector2(float(cell.x), float(cell.y))
	var p2 := Vector2(
		p.dot(Vector2(127.1, 311.7)),
		p.dot(Vector2(269.5, 183.3))
	)
	return Vector2(
		_fract(sin(p2.x) * 17.1717) - 0.5,
		_fract(sin(p2.y) * 17.1717) - 0.5
	)

func _calc_voronoi_2d(position : Vector2, hash_func : Callable) -> Dictionary:
	var world_idx := _floor_vec2i(position)
	var cell_hash_value := Vector2.ZERO
	var cell_position := Vector2.ZERO
	var cell_idx := Vector2i.ZERO
	var min_distance_sq := INF

	for y in range(world_idx.y - 1, world_idx.y + 2):
		for x in range(world_idx.x - 1, world_idx.x + 2):
			var this_cell_idx := Vector2i(x, y)
			var this_cell_hash_value : Vector2 = hash_func.call(this_cell_idx)
			var this_cell_position := Vector2(float(x), float(y)) + this_cell_hash_value
			var cell_dist_squared := this_cell_position.distance_squared_to(position)
			if cell_dist_squared > min_distance_sq:
				continue
			min_distance_sq = cell_dist_squared
			cell_hash_value = this_cell_hash_value
			cell_position = this_cell_position
			cell_idx = this_cell_idx

	var result := {
		"distance_to_edge": INF,
		"id": 0.5 + 0.5 * cos((cell_hash_value.x + cell_hash_value.y) * 6.2831),
		"cell_edge_direction": Vector2.ZERO,
	}

	for y in range(cell_idx.y - 2, cell_idx.y + 3):
		for x in range(cell_idx.x - 2, cell_idx.x + 3):
			var this_cell_idx := Vector2i(x, y)
			if this_cell_idx == cell_idx:
				continue
			var this_cell_position : Vector2 = Vector2(float(x), float(y)) + hash_func.call(this_cell_idx)
			var edge_direction : Vector2 = this_cell_position - cell_position
			if edge_direction.length_squared() <= 0.000001:
				continue
			var plane_normal : Vector2 = edge_direction.normalized()
			var point_on_plane : Vector2 = cell_position + edge_direction * 0.5
			var distance_to_edge := absf((position - point_on_plane).dot(plane_normal))
			if distance_to_edge > float(result.distance_to_edge):
				continue
			result.distance_to_edge = distance_to_edge
			result.cell_edge_direction = plane_normal

	if not is_finite(float(result.distance_to_edge)):
		result.distance_to_edge = 0.0
	return result

func _noise_2d(position : Vector2) -> float:
	var floor_position := _floor_vec2(position)
	var fraction := position - floor_position
	var u := fraction * fraction * (Vector2(3.0, 3.0) - 2.0 * fraction)
	return lerpf(
		lerpf(_value_hash(floor_position), _value_hash(floor_position + Vector2(1.0, 0.0)), u.x),
		lerpf(_value_hash(floor_position + Vector2(0.0, 1.0)), _value_hash(floor_position + Vector2(1.0, 1.0)), u.x),
		u.y
	)

func _calc_perlin_2d(position : Vector2, iterations : int) -> float:
	var value := 0.0
	var strength := 1.0
	for _idx in range(iterations):
		strength *= 0.5
		value += strength * _noise_2d(position)
		position = _multiply_matrix_2d(position, PERLIN_M)
	return 0.5 + 0.5 * value

func _calc_fractional_brownian_2d(position : Vector2, iterations : int) -> float:
	var z := 0.5
	var result := 0.0
	for _idx in range(iterations):
		result += absf(_noise_2d(position)) * z
		z *= 0.5
		position = _multiply_matrix_2d(position, FRACTIONAL_BROWNIAN_M)
	return result

func _calc_caustic_2d(position : Vector2, iterations : int) -> float:
	var p := _fract_vec2(position * 0.2) * (PI * 2.0) - Vector2(250.0, 250.0)
	var i := p
	var value := 0.0
	for n in range(iterations):
		var t := 1.0 - (3.5 / float(n + 1))
		i = p + Vector2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x))
		var s := sin(i.x + t)
		var c := cos(i.y + t)
		var temp := Vector2(
			p.x / s if absf(s) > 0.0001 else 1000.0,
			p.y / c if absf(c) > 0.0001 else 1000.0
		)
		value += 1.0 / sqrt(temp.length_squared())
	return value / (0.003 * float(iterations))

func _sample_fractal_value(mode : int, position : Vector2, iterations : int) -> Dictionary:
	match mode:
		NoiseNodeSettings.eMode.Perlin2D:
			return { "ok": true, "value": _calc_perlin_2d(position, iterations) }
		NoiseNodeSettings.eMode.FractionalBrownian2D:
			return { "ok": true, "value": _calc_fractional_brownian_2d(position, iterations) }
		NoiseNodeSettings.eMode.Caustic2D:
			return { "ok": true, "value": _calc_caustic_2d(position, iterations) }
	return { "ok": false, "error": "Unsupported Spatial Noise fractal mode %d" % mode }

func _edge_mask_fractal_mode() -> int:
	match settings.edge_mask_2d_mode:
		NoiseNodeSettings.eEdgeMask2DMode.Caustic:
			return NoiseNodeSettings.eMode.Caustic2D
		NoiseNodeSettings.eEdgeMask2DMode.FractionalBrownian:
			return NoiseNodeSettings.eMode.FractionalBrownian2D
	return NoiseNodeSettings.eMode.Perlin2D

func _apply_contrast(value : float, contrast : float) -> float:
	if contrast == 1.0:
		return value
	if contrast <= 0.0:
		return 0.5
	value = clampf(value, 0.0, 1.0)
	if value == 1.0:
		return 1.0
	return 1.0 / (1.0 + pow(value / (1.0 - value), -contrast))

func _target_is_none(target_name : String) -> bool:
	var trimmed := target_name.strip_edges()
	return trimmed == "" or trimmed.to_lower() == "none"

func _random_offset_from_seed(max_offset : Vector3) -> Vector3:
	var random_source := RandomNumberGenerator.new()
	random_source.seed = int(settings.random_seed)
	return Vector3(
		max_offset.x * random_source.randf(),
		max_offset.y * random_source.randf(),
		max_offset.z * random_source.randf()
	)

func _position_to_noise_position(position : Vector3, random_offset : Vector3, transform : Transform3D) -> Vector2:
	var transformed := transform * (position + random_offset)
	transformed *= MAGIC_SCALE_FACTOR
	return Vector2(transformed.x, transformed.z)

func _settings_noise_scale_2d() -> Vector2:
	var scale : Vector3 = settings.transform.basis.get_scale()
	return Vector2(
		maxf(absf(scale.x), MIN_BOUNDS_SIZE) * MAGIC_SCALE_FACTOR,
		maxf(absf(scale.z), MIN_BOUNDS_SIZE) * MAGIC_SCALE_FACTOR
	)

func _position_bounds_2d(position_stream : Dictionary, point_count : int) -> Dictionary:
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	var positions : PackedVector3Array = position_stream.container
	for idx in range(point_count):
		var read_idx := FlowData.bcast_idx(positions.size(), idx)
		var p := positions[read_idx]
		var p2 := Vector2(p.x, p.z)
		min_pos.x = minf(min_pos.x, p2.x)
		min_pos.y = minf(min_pos.y, p2.y)
		max_pos.x = maxf(max_pos.x, p2.x)
		max_pos.y = maxf(max_pos.y, p2.y)
	if point_count == 0:
		min_pos = Vector2.ZERO
		max_pos = Vector2.ONE
	return { "min": min_pos, "max": max_pos }

func _bounds_size(bounds : Dictionary) -> Vector2:
	var raw_size : Vector2 = bounds.max - bounds.min
	return Vector2(maxf(absf(raw_size.x), MIN_BOUNDS_SIZE), maxf(absf(raw_size.y), MIN_BOUNDS_SIZE))

func _calc_local_coordinates_2d(position : Vector3, bounds : Dictionary, scale : Vector2) -> Dictionary:
	var local_position := Vector2(position.x, position.z)
	var bounds_size := _bounds_size(bounds)
	var left_dist : float = local_position.x - float(bounds.min.x)
	var right_dist : float = local_position.x - float(bounds.max.x)
	var top_dist : float = local_position.y - float(bounds.min.y)
	var bottom_dist : float = local_position.y - float(bounds.max.y)
	return {
		"x0": left_dist * scale.x,
		"x1": right_dist * scale.x,
		"y0": top_dist * scale.y,
		"y1": bottom_dist * scale.y,
		"frac_x": clampf(left_dist / bounds_size.x, 0.0, 1.0),
		"frac_y": clampf(top_dist / bounds_size.y, 0.0, 1.0),
	}

func _calc_edge_blend_amount_2d(local_coords : Dictionary, edge_blend_distance : float) -> float:
	if edge_blend_distance < 0.01:
		return 1.0
	var use_x : float = local_coords.x0 if absf(local_coords.x0) < absf(local_coords.x1) else local_coords.x1
	var use_y : float = local_coords.y0 if absf(local_coords.y0) < absf(local_coords.y1) else local_coords.y1
	var current_edge_amount : float = minf(absf(use_x), absf(use_y))
	if edge_blend_distance <= current_edge_amount:
		return 0.0
	return clampf((edge_blend_distance - current_edge_amount) / edge_blend_distance, 0.0, 1.0)

func _bi_lerp(v00 : float, v10 : float, v01 : float, v11 : float, tx : float, ty : float) -> float:
	return lerpf(lerpf(v00, v10, tx), lerpf(v01, v11, tx), ty)

func _sample_tiled_fractal(mode : int, local_coords : Dictionary, iterations : int) -> Dictionary:
	var v00 = _sample_fractal_value(mode, Vector2(local_coords.x0, local_coords.y0), iterations)
	if not v00.ok:
		return v00
	var v10 = _sample_fractal_value(mode, Vector2(local_coords.x1, local_coords.y0), iterations)
	if not v10.ok:
		return v10
	var v01 = _sample_fractal_value(mode, Vector2(local_coords.x0, local_coords.y1), iterations)
	if not v01.ok:
		return v01
	var v11 = _sample_fractal_value(mode, Vector2(local_coords.x1, local_coords.y1), iterations)
	if not v11.ok:
		return v11
	return {
		"ok": true,
		"value": _bi_lerp(
			float(v00.value),
			float(v10.value),
			float(v01.value),
			float(v11.value),
			float(local_coords.frac_x),
			float(local_coords.frac_y)
		),
	}

func _sample_spatial_fractal(mode : int, position : Vector3, random_offset : Vector3, bounds : Dictionary, iterations : int) -> Dictionary:
	if settings.tiling:
		var local_coords := _calc_local_coordinates_2d(position, bounds, _settings_noise_scale_2d())
		return _sample_tiled_fractal(mode, local_coords, iterations)
	return _sample_fractal_value(mode, _position_to_noise_position(position, random_offset, settings.transform), iterations)

func _tiled_voronoi_position(position : Vector3, bounds : Dictionary, resolution : int) -> Vector2:
	var bounds_size := _bounds_size(bounds)
	return Vector2(
		((position.x - float(bounds.min.x)) / bounds_size.x) * float(resolution) + 0.5,
		((position.z - float(bounds.min.y)) / bounds_size.y) * float(resolution) + 0.5
	)

func _make_voronoi_hash_func() -> Callable:
	var randomness : float = settings.voronoi_cell_randomness
	if not settings.tiling:
		return func(cell : Vector2i) -> Vector2:
			return _voronoi_hash_2d(cell) * randomness

	var resolution := maxi(1, settings.tiled_voronoi_resolution)
	var edge_blend_cell_count := maxi(0, settings.tiled_voronoi_edge_blend_cell_count)
	var max_blending_tile_index := resolution - edge_blend_cell_count
	var interior_offset := _floor_vec2i(Vector2(settings.transform.origin.x, settings.transform.origin.z))
	var edge_offset := interior_offset
	return func(cell : Vector2i) -> Vector2:
		var is_edge_cell := (
			edge_blend_cell_count > 0
			and (
				cell.x < edge_blend_cell_count
				or cell.y < edge_blend_cell_count
				or cell.x >= max_blending_tile_index
				or cell.y >= max_blending_tile_index
			)
		)
		if is_edge_cell:
			var wrapped := Vector2i(
				posmod(cell.x + edge_offset.x, resolution),
				posmod(cell.y + edge_offset.y, resolution)
			)
			return _voronoi_hash_2d(wrapped) * randomness
		return _voronoi_hash_2d(cell + interior_offset) * randomness

func _sample_voronoi(position : Vector3, random_offset : Vector3, bounds : Dictionary) -> Dictionary:
	var sample_position : Vector2
	if settings.tiling:
		sample_position = _tiled_voronoi_position(position, bounds, maxi(1, settings.tiled_voronoi_resolution))
	else:
		sample_position = _position_to_noise_position(position, random_offset, settings.transform)
	return _calc_voronoi_2d(sample_position, _make_voronoi_hash_func())

func _rotation_from_voronoi_edge(edge_direction : Vector2) -> Vector3:
	if edge_direction.length_squared() <= 0.000001:
		return Vector3.ZERO
	var yaw := rad_to_deg(atan2(edge_direction.x, edge_direction.y))
	return Vector3(0.0, yaw, 0.0)

func _get_position_stream(in_data : FlowData.Data):
	var position_stream = in_data.findStream(FlowData.AttrPosition)
	if position_stream == null:
		return null
	if position_stream.data_type != FlowData.DataType.Vector:
		return null
	var position_size : int = position_stream.container.size()
	var point_count := in_data.size()
	if position_size == point_count or position_size == 1:
		return position_stream
	return null

func execute(ctx : FlowData.EvaluationContext):
	var in_data : FlowData.Data = require_input(0, ctx, "Input 'In'")
	if in_data == null:
		return

	var out_data : FlowData.Data = in_data.duplicate()
	var point_count := in_data.size()
	var value_target : String = str(getSettingValue(ctx, "value_target", settings.value_target)).strip_edges()
	if point_count == 0:
		if not _target_is_none(value_target):
			var empty_values := PackedFloat32Array()
			var empty_err = out_data.registerStream(value_target, empty_values, FlowData.DataType.Float)
			if empty_err:
				setError(empty_err)
				return
		set_output(0, out_data)
		return

	var position_stream = _get_position_stream(in_data)
	if position_stream == null:
		setError("Spatial Noise requires a %s Vector stream with %d values or 1 value" % [FlowData.AttrPosition, point_count])
		return

	var iterations : int = maxi(1, int(getSettingValue(ctx, "iterations", settings.iterations)))
	var brightness : float = float(getSettingValue(ctx, "brightness", settings.brightness))
	var contrast : float = float(getSettingValue(ctx, "contrast", settings.contrast))
	var random_offset_limit : Vector3 = getSettingValue(ctx, "random_offset", settings.random_offset)
	var random_offset := _random_offset_from_seed(random_offset_limit)
	var bounds := _position_bounds_2d(position_stream, point_count)

	var values := PackedFloat32Array()
	values.resize(point_count)

	match settings.mode:
		NoiseNodeSettings.eMode.Perlin2D, NoiseNodeSettings.eMode.Caustic2D, NoiseNodeSettings.eMode.FractionalBrownian2D:
			for idx in range(point_count):
				var read_idx := FlowData.bcast_idx(position_stream.container.size(), idx)
				var sample := _sample_spatial_fractal(settings.mode, position_stream.container[read_idx], random_offset, bounds, iterations)
				if not sample.ok:
					setError(sample.error)
					return
				values[idx] = _apply_contrast(brightness + float(sample.value), contrast)
		NoiseNodeSettings.eMode.Voronoi2D:
			var cell_ids := PackedFloat32Array()
			cell_ids.resize(point_count)
			var rotations := PackedVector3Array()
			if settings.voronoi_orient_samples_to_cell_edge:
				rotations.resize(point_count)
			for idx in range(point_count):
				var read_idx := FlowData.bcast_idx(position_stream.container.size(), idx)
				var sample := _sample_voronoi(position_stream.container[read_idx], random_offset, bounds)
				values[idx] = _apply_contrast(brightness + float(sample.distance_to_edge) / MAGIC_SCALE_FACTOR, contrast)
				cell_ids[idx] = float(sample.id)
				if settings.voronoi_orient_samples_to_cell_edge:
					rotations[idx] = _rotation_from_voronoi_edge(sample.cell_edge_direction)
			if not _target_is_none(settings.voronoi_cell_id_target):
				var cell_err = out_data.registerStream(settings.voronoi_cell_id_target, cell_ids, FlowData.DataType.Float)
				if cell_err:
					setError(cell_err)
					return
			if settings.voronoi_orient_samples_to_cell_edge:
				var rotation_err = out_data.registerStream(FlowData.AttrRotation, rotations, FlowData.DataType.Vector)
				if rotation_err:
					setError(rotation_err)
					return
		NoiseNodeSettings.eMode.EdgeMask2D:
			var edge_mode := _edge_mask_fractal_mode()
			for idx in range(point_count):
				var read_idx := FlowData.bcast_idx(position_stream.container.size(), idx)
				var position : Vector3 = position_stream.container[read_idx]
				var local_coords := _calc_local_coordinates_2d(position, bounds, _settings_noise_scale_2d())
				var edge_blend_amount := _calc_edge_blend_amount_2d(local_coords, settings.edge_blend_distance)
				var value := 1.0
				if edge_blend_amount > 0.0001:
					var sample := _sample_fractal_value(edge_mode, _position_to_noise_position(position, random_offset, settings.transform), iterations)
					if not sample.ok:
						setError(sample.error)
						return
					var remapped_noise_value := _apply_contrast(float(sample.value), settings.edge_blend_curve_intensity)
					var offset_amount := pow(edge_blend_amount, settings.edge_blend_curve_offset)
					var noised_amount := lerpf(
						minf(offset_amount, remapped_noise_value * offset_amount),
						1.0 - minf(1.0 - offset_amount, (1.0 - remapped_noise_value) * (1.0 - offset_amount)),
						offset_amount
					)
					value = 1.0 - clampf(_apply_contrast(noised_amount + brightness, contrast), 0.0, 1.0)
				values[idx] = value
		_:
			setError("Unsupported Spatial Noise mode %d" % settings.mode)
			return

	if not _target_is_none(value_target):
		var err = out_data.registerStream(value_target, values, FlowData.DataType.Float)
		if err:
			setError(err)
			return

	set_output(0, out_data)
