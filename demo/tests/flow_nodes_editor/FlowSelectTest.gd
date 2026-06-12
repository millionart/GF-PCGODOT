extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SelectNode = preload("res://addons/flow_nodes_editor/nodes/select.gd")
const SelectSettings = preload("res://addons/flow_nodes_editor/nodes/select_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_pin_labels_match_ue_boolean_select() and passed
	passed = _test_use_input_b_selects_expected_input() and passed
	passed = _test_legacy_select_b_still_selects_input_b() and passed

	if not passed:
		push_error("FlowSelectTest failed.")
		quit(1)
		return
	quit(0)


func _test_pin_labels_match_ue_boolean_select() -> bool:
	var node = SelectNode.new()
	var meta := node.getMeta()
	var inputs : Array = meta.get("ins", [])
	var passed := (
		_expect(inputs.size() == 2, "Select should have two input pins")
		and _expect(inputs[0].get("label", "") == "Input A", "First input pin should be 'Input A'")
		and _expect(inputs[1].get("label", "") == "Input B", "Second input pin should be 'Input B'")
	)
	node.free()
	return passed


func _test_use_input_b_selects_expected_input() -> bool:
	var input_a := _make_data("A")
	var input_b := _make_data("B")

	var node = _execute_select(input_a, input_b, true)
	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "tag", PackedStringArray(["B"]), "Use Input B should select Input B")
	node.free()
	return passed


func _test_legacy_select_b_still_selects_input_b() -> bool:
	var input_a := _make_data("A")
	var input_b := _make_data("B")

	var node = SelectNode.new()
	node.name = "select"
	node.settings = SelectSettings.new()
	node.settings.select_b = true
	node.deps = []
	node.dependants = []
	node.inputs = [input_a, input_b]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)

	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "tag", PackedStringArray(["B"]), "Legacy select_b should still select Input B")
	node.free()
	return passed


func _make_data(tag : String) -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.registerStream("tag", PackedStringArray([tag]), FlowDataScript.DataType.String)
	return data


func _execute_select(input_a : FlowData.Data, input_b : FlowData.Data, use_input_b : bool):
	var node = SelectNode.new()
	node.name = "select"
	node.settings = SelectSettings.new()
	node.settings.use_input_b = use_input_b
	node.deps = []
	node.dependants = []
	node.inputs = [input_a, input_b]

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
