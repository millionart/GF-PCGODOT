extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const FlowGraphResourceScript = preload("res://addons/flow_nodes_editor/flow_graph_resource.gd")
const FlowNodeIO = preload("res://addons/flow_nodes_editor/flow_nodes_io.gd")
const SelectNode = preload("res://addons/flow_nodes_editor/nodes/select.gd")
const SelectSettings = preload("res://addons/flow_nodes_editor/nodes/select_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_pin_labels_match_ue_boolean_select() and passed
	passed = _test_use_input_b_selects_expected_input() and passed
	passed = _test_use_input_b_reads_connected_setting_input() and passed
	passed = _test_evaluate_graph_accepts_saved_setting_port_link() and passed
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
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [input_a, input_b]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)

	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "tag", PackedStringArray(["B"]), "Legacy select_b should still select Input B")
	node.free()
	return passed


func _test_use_input_b_reads_connected_setting_input() -> bool:
	var input_a := _make_data("A")
	var input_b := _make_data("B")
	var use_input_b := FlowDataScript.Data.new()
	use_input_b.registerStream("use_input_b", PackedByteArray([1]), FlowDataScript.DataType.Bool)

	var node = SelectNode.new()
	node.name = "select"
	node.settings = SelectSettings.new()
	node.args_ports_by_name = { "use_input_b": { "port": 2, "connected": true } }
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [input_a, input_b, use_input_b]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)

	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "tag", PackedStringArray(["B"]), "Connected use_input_b setting should select Input B")
	node.free()
	return passed


func _test_evaluate_graph_accepts_saved_setting_port_link() -> bool:
	var graph = FlowGraphResourceScript.new()
	graph.data = {
		"nodes": [
			{
				"name": "const_a",
				"template": "create_constant",
				"args_port": {},
				"settings": {
					"output_target": "tag",
					"data_type": FlowDataScript.DataType.String,
					"cte_string": "A",
				},
			},
			{
				"name": "const_b",
				"template": "create_constant",
				"args_port": {},
				"settings": {
					"output_target": "tag",
					"data_type": FlowDataScript.DataType.String,
					"cte_string": "B",
				},
			},
			{
				"name": "use_b",
				"template": "create_constant",
				"args_port": {},
				"settings": {
					"output_target": "use_input_b",
					"data_type": FlowDataScript.DataType.Bool,
					"cte_bool": true,
				},
			},
			{
				"name": "select",
				"template": "select",
				"args_port": { "use_input_b": { "port": 2, "connected": true } },
				"settings": { "use_input_b": false },
			},
			{
				"name": "out",
				"template": "output_result",
				"args_port": {},
				"settings": {
					"name": "result",
					"data_type": FlowDataScript.DataType.String,
				},
			},
		],
		"links": [
			{ "from_node": "const_a", "from_port": 0, "to_node": "select", "to_port": 0 },
			{ "from_node": "const_b", "from_port": 0, "to_node": "select", "to_port": 1 },
			{ "from_node": "use_b", "from_port": 0, "to_node": "select", "to_port": 2 },
			{ "from_node": "select", "from_port": 0, "to_node": "out", "to_port": 0 },
		],
	}

	var ctx = FlowDataScript.EvaluationContext.new()
	ctx.eval_id = 1
	ctx.runtime_params = {}
	var outputs := FlowNodeIO.evaluate_graph(graph, {}, ctx)
	var out_data = outputs.get("result")
	return _expect_strings(out_data, "tag", PackedStringArray(["B"]), "evaluate_graph should wire saved setting-port link")


func _make_data(tag : String) -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.registerStream("tag", PackedStringArray([tag]), FlowDataScript.DataType.String)
	return data


func _execute_select(input_a : FlowData.Data, input_b : FlowData.Data, use_input_b : bool):
	var node = SelectNode.new()
	node.name = "select"
	node.settings = SelectSettings.new()
	node.settings.use_input_b = use_input_b
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
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
