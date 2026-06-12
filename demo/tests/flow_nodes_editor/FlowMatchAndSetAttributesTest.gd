extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const MatchAndSetNode = preload("res://addons/flow_nodes_editor/nodes/match_and_set.gd")
const MatchAndSetSettings = preload("res://addons/flow_nodes_editor/nodes/match_and_set_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_random_n_to_one_copies_weighted_match_data() and passed
	passed = _test_explicit_match_copies_matching_attributes() and passed
	passed = _test_explicit_match_keeps_unmatched_rows() and passed
	passed = _test_explicit_match_removes_unmatched_rows() and passed
	passed = _test_single_match_data_bulk_broadcasts_to_multiple_input_bulks() and passed
	passed = _test_missing_match_data_passes_input_with_error() and passed

	if not passed:
		push_error("FlowMatchAndSetAttributesTest failed.")
		quit(1)
		return
	quit(0)


func _test_random_n_to_one_copies_weighted_match_data() -> bool:
	var in_data := _make_point_data(3)
	in_data.registerStream(str(FlowDataScript.AttrSeed), PackedInt32Array([11, 22, 33]), FlowDataScript.DataType.Int)

	var match_data := FlowDataScript.Data.new()
	match_data.registerStream("asset", PackedStringArray(["low", "high"]), FlowDataScript.DataType.String)
	match_data.registerStream("weight", PackedFloat32Array([0.0, 1.0]), FlowDataScript.DataType.Float)

	var node = _execute_node(in_data, match_data, func(settings):
		settings.match_attributes = false
		settings.use_weight_attribute = true
		settings.weight_attr = "weight"
	)
	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Random Match And Set should emit output")
		and _expect(out_data.size() == 3, "Random Match And Set should preserve input row count")
		and _expect_strings(out_data, "asset", PackedStringArray(["high", "high", "high"]), "Weight 0/1 should always pick the weighted row")
		and _expect(out_data.findStream("weight") == null, "Weight Attribute should not be copied to output")
	)
	node.free()
	return passed


func _test_explicit_match_copies_matching_attributes() -> bool:
	var in_data := _make_point_data(3)
	in_data.registerStream("zone", PackedStringArray(["A", "B", "A"]), FlowDataScript.DataType.String)

	var match_data := FlowDataScript.Data.new()
	match_data.registerStream("zone", PackedStringArray(["A", "B"]), FlowDataScript.DataType.String)
	match_data.registerStream("asset", PackedStringArray(["apple", "banana"]), FlowDataScript.DataType.String)

	var node = _execute_node(in_data, match_data, func(settings):
		settings.match_attributes = true
		settings.input_attribute = "zone"
		settings.match_attr = "zone"
	)
	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Explicit Match And Set should emit output")
		and _expect_strings(out_data, "asset", PackedStringArray(["apple", "banana", "apple"]), "Explicit match should copy selected attributes")
		and _expect_strings(out_data, "zone", PackedStringArray(["A", "B", "A"]), "Match Attribute should not overwrite input attribute")
	)
	node.free()
	return passed


func _test_explicit_match_keeps_unmatched_rows() -> bool:
	var in_data := _make_point_data(2)
	in_data.registerStream("zone", PackedStringArray(["A", "C"]), FlowDataScript.DataType.String)
	in_data.registerStream("asset", PackedStringArray(["old_a", "old_c"]), FlowDataScript.DataType.String)

	var match_data := FlowDataScript.Data.new()
	match_data.registerStream("zone", PackedStringArray(["A"]), FlowDataScript.DataType.String)
	match_data.registerStream("asset", PackedStringArray(["apple"]), FlowDataScript.DataType.String)

	var node = _execute_node(in_data, match_data, func(settings):
		settings.match_attributes = true
		settings.input_attribute = "zone"
		settings.match_attr = "zone"
		settings.keep_unmatched = true
	)
	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Keep unmatched should emit output")
		and _expect(out_data.size() == 2, "Keep unmatched should preserve row count")
		and _expect_strings(out_data, "asset", PackedStringArray(["apple", "old_c"]), "Unmatched rows should keep existing values")
	)
	node.free()
	return passed


func _test_explicit_match_removes_unmatched_rows() -> bool:
	var in_data := _make_point_data(3)
	in_data.registerStream("zone", PackedStringArray(["A", "C", "B"]), FlowDataScript.DataType.String)

	var match_data := FlowDataScript.Data.new()
	match_data.registerStream("zone", PackedStringArray(["A", "B"]), FlowDataScript.DataType.String)
	match_data.registerStream("asset", PackedStringArray(["apple", "banana"]), FlowDataScript.DataType.String)

	var node = _execute_node(in_data, match_data, func(settings):
		settings.match_attributes = true
		settings.input_attribute = "zone"
		settings.match_attr = "zone"
		settings.keep_unmatched = false
	)
	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Remove unmatched should emit output")
		and _expect(out_data.size() == 2, "Remove unmatched should drop rows without a match")
		and _expect_strings(out_data, "zone", PackedStringArray(["A", "B"]), "Remaining rows should preserve input order")
		and _expect_strings(out_data, "asset", PackedStringArray(["apple", "banana"]), "Remaining rows should receive matched attributes")
	)
	node.free()
	return passed


func _test_missing_match_data_passes_input_with_error() -> bool:
	var in_data := _make_point_data(1)
	var node = _execute_node(in_data, null, func(settings):
		settings.match_attributes = false
	)
	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Missing Match Data should still emit a pass-through output")
		and _expect(out_data.size() == 1, "Missing Match Data pass-through should keep input rows")
		and _expect(node.err.contains("Match Data"), "Missing Match Data should report an error")
	)
	node.free()
	return passed


func _test_single_match_data_bulk_broadcasts_to_multiple_input_bulks() -> bool:
	var in_data_a := _make_point_data(1)
	var in_data_b := _make_point_data(1)
	var match_data := FlowDataScript.Data.new()
	match_data.registerStream("asset", PackedStringArray(["market"]), FlowDataScript.DataType.String)

	var in_source: FlowNodeBase = FlowNodeBaseScript.new()
	in_source.name = "in_source"
	in_source.num_generated_bulks = 2
	in_source.generated_bulks = [[in_data_a], [in_data_b]]

	var match_source: FlowNodeBase = FlowNodeBaseScript.new()
	match_source.name = "match_source"
	match_source.num_generated_bulks = 1
	match_source.generated_bulks = [[match_data]]

	var node = MatchAndSetNode.new()
	node.name = "match_and_set"
	node.settings = MatchAndSetSettings.new()
	var deps: Array[Dictionary] = [
		{ "from_node": "in_source", "from_port": 0, "to_node": "match_and_set", "to_port": 0 },
		{ "from_node": "match_source", "from_port": 0, "to_node": "match_and_set", "to_port": 1 },
	]
	node.deps = deps
	node.dependants = _empty_connections()

	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.gedit_nodes_by_name = {
		"in_source": in_source,
		"match_source": match_source,
	}
	node.preExecute(ctx)
	node.run(ctx)

	var out_data_a = _get_output_bulk(node, 0, 0)
	var out_data_b = _get_output_bulk(node, 1, 0)
	var passed := (
		_expect(node.generated_bulks.size() == 2, "Single Match Data bulk should be reused for both input bulks")
		and _expect_strings(out_data_a, "asset", PackedStringArray(["market"]), "First input bulk should receive Match Data")
		and _expect_strings(out_data_b, "asset", PackedStringArray(["market"]), "Second input bulk should receive broadcast Match Data")
	)
	node.free()
	in_source.free()
	match_source.free()
	return passed


func _make_point_data(num_points : int) -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.addCommonStreams(num_points)
	return data


func _execute_node(in_data : FlowData.Data, match_data, configure : Callable):
	var node = MatchAndSetNode.new()
	node.name = "match_and_set"
	node.settings = MatchAndSetSettings.new()
	configure.call(node.settings)
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]
	if match_data != null:
		node.inputs.append(match_data)

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


func _get_output_bulk(node, bulk_index : int, port : int):
	if bulk_index >= node.generated_bulks.size():
		return null
	var bulk = node.generated_bulks[bulk_index]
	if port >= bulk.size():
		return null
	return bulk[port]


func _empty_connections() -> Array[Dictionary]:
	return []


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
