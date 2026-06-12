extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const GetAttributeFromPointIndexNode = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index.gd")
const GetAttributeFromPointIndexSettings = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_extracts_attribute_and_selected_point() and passed
	passed = _test_reads_broadcast_attribute_from_selected_point() and passed
	passed = _test_rejects_out_of_range_index() and passed

	if not passed:
		push_error("FlowGetAttributeFromPointIndexTest failed.")
		quit(1)
		return
	quit(0)


func _test_extracts_attribute_and_selected_point() -> bool:
	var in_data := _make_point_data()
	var density_name := str(FlowDataScript.AttrDensity)
	in_data.registerStream(density_name, PackedFloat32Array([0.25, 0.5, 0.75]), FlowDataScript.DataType.Float)
	in_data.registerStream("label", PackedStringArray(["a", "b", "c"]), FlowDataScript.DataType.String)

	var node = _execute_node(in_data, density_name, 1, "@source")
	var attribute_data = _get_output(node, 0)
	var point_data = _get_output(node, 1)

	var passed := (
		_expect_float_stream(attribute_data, density_name, 0.5, "attribute output should contain $Density[1]")
		and _expect_float_stream(point_data, density_name, 0.5, "point output should keep $Density[1]")
		and _expect_string_stream(point_data, "label", "b", "point output should keep label[1]")
		and _expect_vector_stream(point_data, str(FlowDataScript.AttrPosition), Vector3(10.0, 0.0, 0.0), "point output should keep $Position[1]")
	)
	node.free()
	return passed


func _test_reads_broadcast_attribute_from_selected_point() -> bool:
	var in_data := _make_point_data()
	var density_name := str(FlowDataScript.AttrDensity)
	in_data.registerStream(density_name, PackedFloat32Array([0.9]), FlowDataScript.DataType.Float)

	var node = _execute_node(in_data, density_name, 2, "@source")
	var attribute_data = _get_output(node, 0)
	var point_data = _get_output(node, 1)

	var passed := (
		_expect_float_stream(attribute_data, density_name, 0.9, "attribute output should read broadcast $Density")
		and _expect_float_stream(point_data, density_name, 0.9, "point output should keep broadcast $Density")
		and _expect_vector_stream(point_data, str(FlowDataScript.AttrPosition), Vector3(20.0, 0.0, 0.0), "point output should keep $Position[2]")
	)
	node.free()
	return passed


func _test_rejects_out_of_range_index() -> bool:
	var in_data := _make_point_data()
	var density_name := str(FlowDataScript.AttrDensity)
	in_data.registerStream(density_name, PackedFloat32Array([0.25, 0.5, 0.75]), FlowDataScript.DataType.Float)

	var node = _execute_node(in_data, density_name, 3, "@source")
	var passed := (
		_expect(node.generated_bulks.is_empty(), "out-of-range index should not emit outputs")
		and _expect(node.err.contains("out of range"), "out-of-range index should report an error")
	)
	node.free()
	return passed


func _make_point_data() -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.addCommonStreams(3)
	var positions : PackedVector3Array = data.getContainerChecked(str(FlowDataScript.AttrPosition), FlowDataScript.DataType.Vector)
	positions[0] = Vector3.ZERO
	positions[1] = Vector3(10.0, 0.0, 0.0)
	positions[2] = Vector3(20.0, 0.0, 0.0)
	return data


func _execute_node(in_data : FlowData.Data, source_name : String, point_index : int, out_name : String):
	var node = GetAttributeFromPointIndexNode.new()
	node.name = "get_attribute_from_point_index"
	node.settings = GetAttributeFromPointIndexSettings.new()
	node.settings.input_attribute_name = source_name
	node.settings.point_index = point_index
	node.settings.output_attribute_name = out_name
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)
	return node


func _get_output(node, port : int):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if port >= bulk.size():
		return null
	return bulk[port]


func _empty_connections() -> Array[Dictionary]:
	return []


func _expect_float_stream(data, stream_name : String, expected : float, message : String) -> bool:
	if not _expect(data != null, "%s: missing data" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == 1, "%s: expected one value, got %d" % [message, stream.container.size()]):
		return false
	return _expect(absf(float(stream.container[0]) - expected) <= 0.0001, "%s: got %s" % [message, stream.container[0]])


func _expect_string_stream(data, stream_name : String, expected : String, message : String) -> bool:
	if not _expect(data != null, "%s: missing data" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == 1, "%s: expected one value, got %d" % [message, stream.container.size()]):
		return false
	return _expect(stream.container[0] == expected, "%s: got %s" % [message, stream.container[0]])


func _expect_vector_stream(data, stream_name : String, expected : Vector3, message : String) -> bool:
	if not _expect(data != null, "%s: missing data" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == 1, "%s: expected one value, got %d" % [message, stream.container.size()]):
		return false
	return _expect(stream.container[0].is_equal_approx(expected), "%s: got %s" % [message, stream.container[0]])


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
