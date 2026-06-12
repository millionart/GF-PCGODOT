extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SortNode = preload("res://addons/flow_nodes_editor/nodes/sort.gd")
const SortSettings = preload("res://addons/flow_nodes_editor/nodes/sort_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_sorts_by_multiple_attributes() and passed
	passed = _test_sort_method_controls_default_direction() and passed
	passed = _test_stable_sort_preserves_equal_key_order() and passed
	passed = _test_preserves_broadcast_streams() and passed

	if not passed:
		push_error("FlowSortAttributesTest failed.")
		quit(1)
		return
	quit(0)


func _test_sorts_by_multiple_attributes() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("group", PackedInt32Array([2, 1, 1, 2, 1]), FlowDataScript.DataType.Int)
	in_data.registerStream("rank", PackedInt32Array([1, 1, 3, 3, 2]), FlowDataScript.DataType.Int)
	in_data.registerStream("name", PackedStringArray(["a", "b", "c", "d", "e"]), FlowDataScript.DataType.String)

	var node = _execute_sort(in_data, "group, rank:desc", SortSettings.eSortMethod.Ascending, true)
	var out_data = _get_output(node)
	var passed := (
		_expect_ints(out_data, "group", PackedInt32Array([1, 1, 1, 2, 2]), "group should be ascending")
		and _expect_ints(out_data, "rank", PackedInt32Array([3, 2, 1, 3, 1]), "rank should be descending within group")
		and _expect_strings(out_data, "name", PackedStringArray(["c", "e", "b", "d", "a"]), "payload rows should stay aligned")
	)
	node.free()
	return passed


func _test_sort_method_controls_default_direction() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("rank", PackedInt32Array([2, 1, 3]), FlowDataScript.DataType.Int)

	var node = _execute_sort(in_data, "rank", SortSettings.eSortMethod.Descending, true)
	var out_data = _get_output(node)
	var passed := _expect_ints(out_data, "rank", PackedInt32Array([3, 2, 1]), "Sort Method Descending should sort descending")
	node.free()
	return passed


func _test_stable_sort_preserves_equal_key_order() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("group", PackedInt32Array([1, 1, 1]), FlowDataScript.DataType.Int)
	in_data.registerStream("id", PackedInt32Array([3, 1, 2]), FlowDataScript.DataType.Int)

	var node = _execute_sort(in_data, "group", SortSettings.eSortMethod.Ascending, true)
	var out_data = _get_output(node)
	var passed := _expect_ints(out_data, "id", PackedInt32Array([3, 1, 2]), "stable sort should preserve equal-key order")
	node.free()
	return passed


func _test_preserves_broadcast_streams() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("rank", PackedInt32Array([2, 1, 3]), FlowDataScript.DataType.Int)
	in_data.registerStream("shared", PackedStringArray(["constant"]), FlowDataScript.DataType.String)

	var node = _execute_sort(in_data, "rank", SortSettings.eSortMethod.Ascending, true)
	var out_data = _get_output(node)
	var passed := (
		_expect_ints(out_data, "rank", PackedInt32Array([1, 2, 3]), "rank should sort ascending")
		and _expect_strings(out_data, "shared", PackedStringArray(["constant"]), "broadcast stream should stay broadcast")
	)
	node.free()
	return passed


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


func _get_output(node):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]


func _expect_ints(data, stream_name : String, expected : PackedInt32Array, message : String) -> bool:
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


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
