extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SpatialNoiseNode = preload("res://addons/flow_nodes_editor/nodes/noise.gd")
const SpatialNoiseSettings = preload("res://addons/flow_nodes_editor/nodes/noise_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_perlin_writes_default_density_for_inspector() and passed
	passed = _test_iterations_changes_perlin_result() and passed
	passed = _test_random_offset_uses_node_seed() and passed
	passed = _test_tiling_changes_fractal_result() and passed
	passed = _test_voronoi_writes_distance_and_cell_id() and passed
	passed = _test_voronoi_tiling_writes_output() and passed
	passed = _test_edge_mask_uses_source_bounds() and passed
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


func _test_tiling_changes_fractal_result() -> bool:
	var data := _make_bounds_point_data()
	var non_tiled = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.random_offset = Vector3.ZERO
		settings.tiling = false
	)
	var tiled = _execute_node(data, func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Perlin2D
		settings.random_offset = Vector3.ZERO
		settings.tiling = true
	)

	var density_name := str(FlowDataScript.AttrDensity)
	var non_tiled_stream = _get_output(non_tiled).findStream(density_name)
	var tiled_stream = _get_output(tiled).findStream(density_name)
	var passed := _expect_streams_differ(non_tiled_stream, tiled_stream, "Tiling should use source bounds and change Perlin2D output")
	non_tiled.free()
	tiled.free()
	return passed


func _test_voronoi_writes_distance_and_cell_id() -> bool:
	var node = _execute_node(_make_bounds_point_data(), func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Voronoi2D
		settings.value_target = "edge_distance"
		settings.voronoi_cell_id_target = "cell_id"
		settings.random_offset = Vector3.ZERO
	)
	var out_data = _get_output(node)
	var passed := (
		_expect_float_stream_size(out_data, "edge_distance", 5, "Voronoi2D should write distance-to-edge values")
		and _expect_float_stream_size(out_data, "cell_id", 5, "Voronoi2D should write cell id values")
		and _expect_float_stream_range(out_data, "cell_id", 0.0, 1.0, "Voronoi2D cell ids should be normalized")
	)
	node.free()
	return passed


func _test_voronoi_tiling_writes_output() -> bool:
	var node = _execute_node(_make_bounds_point_data(), func(settings):
		settings.mode = SpatialNoiseSettings.eMode.Voronoi2D
		settings.value_target = "tiled_edge_distance"
		settings.voronoi_cell_id_target = "tiled_cell_id"
		settings.tiling = true
		settings.tiled_voronoi_resolution = 4
		settings.tiled_voronoi_edge_blend_cell_count = 1
		settings.random_offset = Vector3.ZERO
	)
	var out_data = _get_output(node)
	var passed := (
		_expect_float_stream_size(out_data, "tiled_edge_distance", 5, "Tiled Voronoi2D should write distance values")
		and _expect_float_stream_size(out_data, "tiled_cell_id", 5, "Tiled Voronoi2D should write cell id values")
	)
	node.free()
	return passed


func _test_edge_mask_uses_source_bounds() -> bool:
	var node = _execute_node(_make_bounds_point_data(), func(settings):
		settings.mode = SpatialNoiseSettings.eMode.EdgeMask2D
		settings.edge_mask_2d_mode = SpatialNoiseSettings.eEdgeMask2DMode.Perlin
		settings.value_target = "edge_mask"
		settings.edge_blend_distance = 0.02
		settings.random_offset = Vector3.ZERO
	)
	var out_data = _get_output(node)
	if not _expect_float_stream_size(out_data, "edge_mask", 5, "EdgeMask2D should write mask values"):
		node.free()
		return false
	var stream = out_data.findStream("edge_mask")
	var center_value := float(stream.container[4])
	var edge_value := float(stream.container[0])
	var passed := (
		_expect(is_equal_approx(center_value, 1.0), "EdgeMask2D center point should stay fully inside the source bounds")
		and _expect(edge_value < 0.999, "EdgeMask2D edge point should be blended by edge noise")
	)
	node.free()
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


func _make_bounds_point_data() -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.addCommonStreams(5)
	var positions : PackedVector3Array = data.getContainerChecked(str(FlowDataScript.AttrPosition), FlowDataScript.DataType.Vector)
	positions[0] = Vector3(0.0, 0.0, 0.0)
	positions[1] = Vector3(1000.0, 0.0, 0.0)
	positions[2] = Vector3(0.0, 0.0, 1000.0)
	positions[3] = Vector3(1000.0, 0.0, 1000.0)
	positions[4] = Vector3(500.0, 0.0, 500.0)
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


func _expect_float_stream_range(data, stream_name : String, min_value : float, max_value : float, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	for idx in range(stream.container.size()):
		var value := float(stream.container[idx])
		if not _expect(value >= min_value and value <= max_value, "%s: index %d got %s" % [message, idx, value]):
			return false
	return true


func _expect_streams_differ(first_stream, second_stream, message : String) -> bool:
	if not _expect(first_stream != null, "%s: missing first stream" % message):
		return false
	if not _expect(second_stream != null, "%s: missing second stream" % message):
		return false
	if not _expect(first_stream.container.size() == second_stream.container.size(), "%s: stream sizes differ" % message):
		return false
	for idx in range(first_stream.container.size()):
		if absf(float(first_stream.container[idx]) - float(second_stream.container[idx])) > 0.0001:
			return true
	push_error(message)
	return false


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
