extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const BreakVectorNode = preload("res://addons/flow_nodes_editor/nodes/decompose_vector.gd")
const BreakVectorSettings = preload("res://addons/flow_nodes_editor/nodes/decompose_vector_settings.gd")
const DensityRemapNode = preload("res://addons/flow_nodes_editor/nodes/density_remap.gd")
const DensityRemapSettings = preload("res://addons/flow_nodes_editor/nodes/density_remap_settings.gd")
const RemapNode = preload("res://addons/flow_nodes_editor/nodes/remap.gd")
const RemapSettings = preload("res://addons/flow_nodes_editor/nodes/remap_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_density_remap_reads_broadcast_density() and passed
	passed = _test_attribute_curve_remap_processes_vector_components() and passed
	passed = _test_break_vector_outputs_color_w_component() and passed

	if not passed:
		push_error("FlowMetadataParityRegressionTest failed.")
		quit(1)
		return
	quit(0)


func _test_density_remap_reads_broadcast_density() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2, 3]), FlowDataScript.DataType.Int)
	in_data.registerStream(str(FlowDataScript.AttrDensity), PackedFloat32Array([0.25]), FlowDataScript.DataType.Float)

	var node = DensityRemapNode.new()
	node.name = "density_remap"
	node.settings = DensityRemapSettings.new()
	node.settings.out_max = 2.0
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	_execute_node(node)

	var out_data = _get_output(node)
	var passed := _expect_floats(
		out_data,
		str(FlowDataScript.AttrDensity),
		PackedFloat32Array([0.5, 0.5, 0.5]),
		"Density Remap should broadcast a one-value $Density stream"
	)
	node.free()
	return passed


func _test_attribute_curve_remap_processes_vector_components() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2]), FlowDataScript.DataType.Int)
	in_data.registerStream("uvw", PackedVector3Array([Vector3(0.0, 0.5, 1.0), Vector3(1.0, 0.5, 0.0)]), FlowDataScript.DataType.Vector)

	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.0))

	var node = RemapNode.new()
	node.name = "remap"
	node.settings = RemapSettings.new()
	node.settings.in_name = "uvw"
	node.settings.out_name = "remapped"
	node.settings.remap_curve = curve
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	_execute_node(node)

	var out_data = _get_output(node)
	var passed := _expect_vectors(
		out_data,
		"remapped",
		PackedVector3Array([Vector3(1.0, 0.5, 0.0), Vector3(0.0, 0.5, 1.0)]),
		"Attribute Curve Remap should remap Vector components independently"
	)
	node.free()
	return passed


func _test_break_vector_outputs_color_w_component() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2]), FlowDataScript.DataType.Int)
	in_data.registerStream("tint", PackedColorArray([Color(0.1, 0.2, 0.3, 0.4), Color(0.5, 0.6, 0.7, 0.8)]), FlowDataScript.DataType.Color)

	var node = BreakVectorNode.new()
	node.name = "break_vector"
	node.settings = BreakVectorSettings.new()
	node.settings.in_attribute = "tint"
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	_execute_node(node)

	var out_data = _get_output(node)
	var passed := (
		_expect_floats(out_data, "x", PackedFloat32Array([0.1, 0.5]), "Break Vector should output Color R as X")
		and _expect_floats(out_data, "y", PackedFloat32Array([0.2, 0.6]), "Break Vector should output Color G as Y")
		and _expect_floats(out_data, "z", PackedFloat32Array([0.3, 0.7]), "Break Vector should output Color B as Z")
		and _expect_floats(out_data, "w", PackedFloat32Array([0.4, 0.8]), "Break Vector should output Color A as W")
	)
	node.free()
	return passed


func _execute_node(node) -> void:
	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)


func _get_output(node):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]


func _empty_connections() -> Array[Dictionary]:
	return []


func _expect_floats(data, stream_name : String, expected : PackedFloat32Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.data_type == FlowDataScript.DataType.Float, "%s: expected Float stream" % message):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(absf(float(stream.container[i]) - expected[i]) <= 0.0001, "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect_vectors(data, stream_name : String, expected : PackedVector3Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.data_type == FlowDataScript.DataType.Vector, "%s: expected Vector stream" % message):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(stream.container[i].is_equal_approx(expected[i]), "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
