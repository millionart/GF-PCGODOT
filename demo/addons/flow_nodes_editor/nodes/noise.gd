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

func _value_hash(position : Vector2) -> float:
	position = 50.0 * _fract_vec2(position * 0.3183099 + Vector2(0.71, 0.113))
	return -1.0 + 2.0 * _fract(position.x * position.y * (position.x + position.y))

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

func _sample_value(position : Vector2, iterations : int) -> Dictionary:
	match settings.mode:
		NoiseNodeSettings.eMode.Perlin2D:
			return { "ok": true, "value": _calc_perlin_2d(position, iterations) }
		NoiseNodeSettings.eMode.FractionalBrownian2D:
			return { "ok": true, "value": _calc_fractional_brownian_2d(position, iterations) }
		NoiseNodeSettings.eMode.Caustic2D:
			return { "ok": true, "value": _calc_caustic_2d(position, iterations) }
		NoiseNodeSettings.eMode.Voronoi2D:
			return { "ok": false, "error": "Spatial Noise mode Voronoi2D is not implemented yet" }
		NoiseNodeSettings.eMode.EdgeMask2D:
			return { "ok": false, "error": "Spatial Noise mode EdgeMask2D is not implemented yet" }
	return { "ok": false, "error": "Unsupported Spatial Noise mode %d" % settings.mode }

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

	var values := PackedFloat32Array()
	values.resize(point_count)
	for idx in range(point_count):
		var read_idx := FlowData.bcast_idx(position_stream.container.size(), idx)
		var noise_position := _position_to_noise_position(position_stream.container[read_idx], random_offset, settings.transform)
		var sample := _sample_value(noise_position, iterations)
		if not sample.ok:
			setError(sample.error)
			return
		values[idx] = _apply_contrast(brightness + float(sample.value), contrast)

	if not _target_is_none(value_target):
		var err = out_data.registerStream(value_target, values, FlowData.DataType.Float)
		if err:
			setError(err)
			return

	set_output(0, out_data)
