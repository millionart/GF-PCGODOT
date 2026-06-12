extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SpatialNoiseNode = preload("res://addons/flow_nodes_editor/nodes/noise.gd")
const SpatialNoiseSettings = preload("res://addons/flow_nodes_editor/nodes/noise_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_perlin_writes_default_density_for_inspector() and passed
	passed = _test_iterations_changes_perlin_result() and passed
	passed = _test_random_offset_uses_node_seed() and passed
	passed = _test_value_target_writes_named_attribute() and passed
	passed = _test_empty_input_emits_empty_value_target() and passed
	passed = _test_missing_position_reports_error() and passed

	if not passed:
		push_error("FlowSpatialNoiseTest failed.")
		quit(1)
		return
	quit(0)


func _test_perlin_writes_default_density_for_inspector() -> bool:
	var node = _execute_node(_make_point_data(), func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.random_offset = Vector3.ZERO
	)
	var out_data = _get_output(node)
	var density_name := str(FlowDataScript.AttrDensity)
	var passed := (
		_expect_float_stream_size(out_data, density_name, 3, "Spatial Noise should write default $Density")
		and _expect(out_data.getStreamNames().has(density_name), "Inspector stream names should include Spatial Noise output")
	)
	node.free()
	return passed


func _test_iterations_changes_perlin_result() -> bool:
	var data := _make_point_data()
	var one_iteration = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.iterations = 1
		settings.random_offset = Vector3.ZERO
	)
	var four_iterations = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.iterations = 4
		settings.random_offset = Vector3.ZERO
	)

	var density_name := str(FlowDataScript.AttrDensity)
	var first_stream = _get_output(one_iteration).findStream(density_name)
	var second_stream = _get_output(four_iterations).findStream(density_name)
	var changed := false
	if first_stream != null and second_stream != null:
		for idx in range(first_stream.container.size()):
			if absf(float(first_stream.container[idx]) - float(second_stream.container[idx])) > 0.0001:
				changed = true
				break
	var passed := _expect(changed, "Changing Iterations should change Perlin2D output")
	one_iteration.free()
	four_iterations.free()
	return passed


func _test_value_target_writes_named_attribute() -> bool:
	var node = _execute_node(_make_point_data(), func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.value_target = "coast_noise"
		settings.random_offset = Vector3.ZERO
	)
	var out_data = _get_output(node)
	var passed := (
		_expect_float_stream_size(out_data, "coast_noise", 3, "Value Target should create the named output attribute")
		and _expect(out_data.findStream(str(FlowDataScript.AttrDensity)) == null, "Custom Value Target should not create default $Density")
	)
	node.free()
	return passed


func _test_random_offset_uses_node_seed() -> bool:
	var data := _make_point_data()
	var seed_a = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.random_seed = 111
	)
	var seed_b = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.random_seed = 222
	)

	var density_name := str(FlowDataScript.AttrDensity)
	var first_stream = _get_output(seed_a).findStream(density_name)
	var second_stream = _get_output(seed_b).findStream(density_name)
	var changed := false
	if first_stream != null and second_stream != null:
		for idx in range(first_stream.container.size()):
			if absf(float(first_stream.container[idx]) - float(second_stream.container[idx])) > 0.0001:
				changed = true
				break
	var passed := _expect(changed, "Changing random_seed should change Spatial Noise output when RandomOffset is non-zero")
	seed_a.free()
	seed_b.free()
	return passed


func _test_empty_input_emits_empty_value_target() -> bool:
	var data := FlowDataScript.Data.new()
	data.registerStream(str(FlowDataScript.AttrPosition), PackedVector3Array(), FlowDataScript.DataType.Vector)

	var node = _execute_node(data, func(settings):
		settings.value_target = "noise_value"
	)
	var out_data = _get_output(node)
	var passed := _expect_float_stream_size(out_data, "noise_value", 0, "Empty input should keep an empty output schema")
	node.free()
	return passed


func _test_missing_position_reports_error() -> bool:
	var data := FlowDataScript.Data.new()
	data.registerStream("id", PackedInt32Array([1, 2]), FlowDataScript.DataType.Int)

	var node = _execute_node(data, func(_settings):
		pass
	)
	var passed := (
		_expect(node.generated_bulks.is_empty(), "Missing $Position should not emit output")
		and _expect(node.err.contains(str(FlowDataScript.AttrPosition)), "Missing $Position should report an error")
	)
	node.free()
	return passed


func _make_point_data() -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.addCommonStreams(3)
	var positions : PackedVector3Array = data.getContainerChecked(str(FlowDataScript.AttrPosition), FlowDataScript.DataType.Vector)
	positions[0] = Vector3(0.0, 0.0, 0.0)
	positions[1] = Vector3(1000.0, 0.0, 0.0)
	positions[2] = Vector3(0.0, 0.0, 1000.0)
	return data


func _execute_node(in_data : FlowData.Data, configure : Callable):
	var node = SpatialNoiseNode.new()
	node.name = "spatial_noise"
	node.settings = SpatialNoiseSettings.new()
	configure.call(node.settings)
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)
	return node


func _get_output(node):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]


func _empty_connections() -> Array[Dictionary]:
	return []


func _expect_float_stream_size(data, stream_name : String, expected_size : int, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.data_type == FlowDataScript.DataType.Float, "%s: expected Float stream" % message):
		return false
	return _expect(stream.container.size() == expected_size, "%s: expected %d values, got %d" % [message, expected_size, stream.container.size()])


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
