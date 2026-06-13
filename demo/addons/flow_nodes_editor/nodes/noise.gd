@tool
extends FlowNodeBase

const FlowSpatialNoiseBuiltin = preload("res://addons/flow_nodes_editor/spatial_noise_builtin.gd")
const FlowSpatialNoiseRegistry = preload("res://addons/flow_nodes_editor/spatial_noise_registry.gd")

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

func _target_is_none(target_name : String) -> bool:
	var trimmed := target_name.strip_edges()
	return trimmed == "" or trimmed.to_lower() == "none"

func _random_offset_from_seed(max_offset : Vector3, seed : int) -> Vector3:
	var random_source := RandomNumberGenerator.new()
	random_source.seed = seed
	return Vector3(
		max_offset.x * random_source.randf(),
		max_offset.y * random_source.randf(),
		max_offset.z * random_source.randf()
	)

func _resolved_algorithm_parameters(ctx : FlowData.EvaluationContext) -> Dictionary:
	var raw_parameters = getSettingValue(ctx, "algorithm_parameters", settings.algorithm_parameters)
	if raw_parameters is Dictionary:
		return raw_parameters.duplicate()
	return {}

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

func _sample_algorithm(algorithm : Dictionary, mode_id : String, context : Dictionary) -> Dictionary:
	if bool(algorithm.get("builtin", false)):
		return FlowSpatialNoiseBuiltin.sample(mode_id, context)
	var sampler : Callable = algorithm.get("sampler", Callable())
	if not sampler.is_valid():
		return { "ok": false, "error": "Spatial Noise algorithm '%s' has an invalid sampler" % mode_id }
	var sample = sampler.call(context)
	if sample is Dictionary:
		if not sample.has("ok"):
			sample["ok"] = sample.has("value")
		return sample
	return { "ok": false, "error": "Spatial Noise algorithm '%s' returned %s instead of Dictionary" % [mode_id, type_string(typeof(sample))] }

func _write_optional_float_stream(out_data : FlowData.Data, stream_name : String, values : PackedFloat32Array) -> bool:
	if _target_is_none(stream_name):
		return true
	var err = out_data.registerStream(stream_name, values, FlowData.DataType.Float)
	if err:
		setError(err)
		return false
	return true

func execute(ctx : FlowData.EvaluationContext):
	var in_data : FlowData.Data = require_input(0, ctx, "Input 'In'")
	if in_data == null:
		return

	var out_data : FlowData.Data = in_data.duplicate()
	var point_count := in_data.size()
	var value_target : String = str(getSettingValue(ctx, "value_target", settings.value_target)).strip_edges()
	if point_count == 0:
		if not _write_optional_float_stream(out_data, value_target, PackedFloat32Array()):
			return
		set_output(0, out_data)
		return

	var position_stream = _get_position_stream(in_data)
	if position_stream == null:
		setError("Spatial Noise requires a %s Vector stream with %d values or 1 value" % [FlowData.AttrPosition, point_count])
		return

	var mode_id : String = settings.get_mode_id()
	var algorithm := FlowSpatialNoiseRegistry.get_algorithm(mode_id)
	if algorithm.is_empty():
		setError("Spatial Noise algorithm '%s' is not registered" % mode_id)
		return

	var iterations : int = maxi(1, int(getSettingValue(ctx, "iterations", settings.iterations)))
	var brightness : float = float(getSettingValue(ctx, "brightness", settings.brightness))
	var contrast : float = float(getSettingValue(ctx, "contrast", settings.contrast))
	var random_seed : int = int(getSettingValue(ctx, "random_seed", settings.random_seed))
	var random_offset_limit : Vector3 = getSettingValue(ctx, "random_offset", settings.random_offset)
	var random_offset := _random_offset_from_seed(random_offset_limit, random_seed)
	var bounds := FlowSpatialNoiseBuiltin.position_bounds_2d(position_stream, point_count)
	var algorithm_parameters := _resolved_algorithm_parameters(ctx)

	var values := PackedFloat32Array()
	values.resize(point_count)
	var cell_ids := PackedFloat32Array()
	var rotations := PackedVector3Array()
	var writes_cell_id : bool = mode_id == FlowSpatialNoiseRegistry.ID_VORONOI_2D and not _target_is_none(settings.voronoi_cell_id_target)
	var writes_rotation : bool = mode_id == FlowSpatialNoiseRegistry.ID_VORONOI_2D and bool(settings.voronoi_orient_samples_to_cell_edge)
	if writes_cell_id:
		cell_ids.resize(point_count)
	if writes_rotation:
		rotations.resize(point_count)

	for idx in range(point_count):
		var read_idx := FlowData.bcast_idx(position_stream.container.size(), idx)
		var context := {
			"algorithm_id": mode_id,
			"settings": settings,
			"position": position_stream.container[read_idx],
			"random_offset": random_offset,
			"bounds": bounds,
			"iterations": iterations,
			"brightness": brightness,
			"contrast": contrast,
			"random_seed": random_seed,
			"algorithm_parameters": algorithm_parameters,
		}
		var sample := _sample_algorithm(algorithm, mode_id, context)
		if not bool(sample.get("ok", false)):
			setError(str(sample.get("error", "Spatial Noise algorithm '%s' failed" % mode_id)))
			return
		values[idx] = float(sample.get("value", 0.0))
		if not bool(sample.get("adjusted", false)):
			values[idx] = FlowSpatialNoiseBuiltin.apply_contrast(brightness + values[idx], contrast)
		if writes_cell_id:
			cell_ids[idx] = float(sample.get("cell_id", 0.0))
		if writes_rotation:
			rotations[idx] = sample.get("rotation", Vector3.ZERO)

	if not _write_optional_float_stream(out_data, value_target, values):
		return
	if writes_cell_id and not _write_optional_float_stream(out_data, settings.voronoi_cell_id_target, cell_ids):
		return
	if writes_rotation:
		var rotation_err = out_data.registerStream(FlowData.AttrRotation, rotations, FlowData.DataType.Vector)
		if rotation_err:
			setError(rotation_err)
			return

	set_output(0, out_data)
