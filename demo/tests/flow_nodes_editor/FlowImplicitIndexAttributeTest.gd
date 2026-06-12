extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const FlowNodeInspectorContextControlsScript = preload("res://addons/flow_nodes_editor/flow_node_inspector_context_controls.gd")
const GetAttributeFromPointIndexNode = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index.gd")
const GetAttributeFromPointIndexSettings = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index_settings.gd")
const SortNode = preload("res://addons/flow_nodes_editor/nodes/sort.gd")
const SortSettings = preload("res://addons/flow_nodes_editor/nodes/sort_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_flow_data_exposes_implicit_index() and passed
	passed = _test_attribute_selector_includes_index() and passed
	passed = _test_get_attribute_from_point_index_reads_index() and passed
	passed = _test_sort_attributes_reads_index() and passed

	if not passed:
		push_error("FlowImplicitIndexAttributeTest failed.")
		quit(1)
		return
	quit(0)


func _test_flow_data_exposes_implicit_index() -> bool:
	var data := _make_point_data()
	var index_stream = data.findStream("$index")
	var legacy_index_stream = data.findStream("index")
	var checked_container = data.getContainerChecked("$index", FlowDataScript.DataType.Int)
	var names := data.getStreamNames()

	return (
		_expect(data.hasStream("$index"), "FlowData should report '$index' as available")
		and _expect(data.hasStreamOfType("$index", FlowDataScript.DataType.Int), "'$index' should be an int stream")
		and _expect(index_stream != null, "findStream('$index') should resolve the implicit index")
		and _expect(legacy_index_stream != null, "findStream('index') should keep resolving the legacy index alias")
		and _expect_int_container(index_stream.container, PackedInt32Array([0, 1, 2]), "'$index' values should match row indices")
		and _expect_int_container(legacy_index_stream.container, PackedInt32Array([0, 1, 2]), "'index' alias values should match row indices")
		and _expect_int_container(checked_container, PackedInt32Array([0, 1, 2]), "getContainerChecked('$index') should return row indices")
		and _expect(names.has("$index"), "getStreamNames should include '$index'")
	)


func _test_attribute_selector_includes_index() -> bool:
	var node: FlowNodeBase = FlowNodeBaseScript.new()
	node.inputs = [_make_point_data()]
	var names := FlowNodeInspectorContextControlsScript.get_input_stream_names(node, 0)
	node.free()
	return _expect(names.has("$index"), "Attribute selector should offer '$index'")


func _test_get_attribute_from_point_index_reads_index() -> bool:
	var node = _execute_get_attribute(_make_point_data(), "$index", 2, "@source")
	var attribute_data = _get_output(node, 0)
	var passed := _expect_ints(attribute_data, "$index", PackedInt32Array([2]), "Get Attribute From Point Index should read '$index'")
	node.free()
	return passed


func _test_sort_attributes_reads_index() -> bool:
	var in_data := _make_point_data()
	in_data.registerStream("label", PackedStringArray(["a", "b", "c"]), FlowDataScript.DataType.String)

	var node = _execute_sort(in_data, "$index", SortSettings.eSortMethod.Descending, true)
	var out_data = _get_output(node, 0)
	var passed := _expect_strings(out_data, "label", PackedStringArray(["c", "b", "a"]), "Sort Attributes should sort by '$index'")
	node.free()
	return passed


func _make_point_data() -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.addCommonStreams(3)
	return data


func _execute_get_attribute(in_data : FlowData.Data, source_name : String, point_index : int, out_name : String):
	var node = GetAttributeFromPointIndexNode.new()
	node.name = "get_attribute_from_point_index"
	node.settings = GetAttributeFromPointIndexSettings.new()
	node.settings.input_attribute_name = source_name
	node.settings.point_index = point_index
	node.settings.output_attribute_name = out_name
	node.deps = []
	node.dependants = []
	node.inputs = [in_data]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)
	return node


func _execute_sort(in_data : FlowData.Data, sort_by : String, sort_method : int, stable : bool):
	var node = SortNode.new()
	node.name = "sort"
	node.settings = SortSettings.new()
	node.settings.sort_by = sort_by
	node.settings.sort_method = sort_method
	node.settings.use_stable_sort = stable
	node.deps = []
	node.dependants = []
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


func _expect_ints(data, stream_name : String, expected : PackedInt32Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	return _expect_int_container(stream.container, expected, message)


func _expect_strings(data, stream_name : String, expected : PackedStringArray, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(stream.container[i] == expected[i], "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect_int_container(container, expected : PackedInt32Array, message : String) -> bool:
	if not _expect(container != null, "%s: missing container" % message):
		return false
	if not _expect(container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(int(container[i]) == expected[i], "%s: index %d got %s" % [message, i, container[i]]):
			return false
	return true


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
