extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const AddAttributeNode = preload("res://addons/flow_nodes_editor/nodes/add_attribute.gd")
const AddAttributeSettings = preload("res://addons/flow_nodes_editor/nodes/add_attribute_settings.gd")
const CreateConstantNode = preload("res://addons/flow_nodes_editor/nodes/create_constant.gd")
const CreateConstantSettings = preload("res://addons/flow_nodes_editor/nodes/create_constant_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_create_constant_outputs_single_attribute_set() and passed
	passed = _test_add_attribute_requires_input() and passed
	passed = _test_add_attribute_constant_requires_input_and_fills_rows() and passed
	passed = _test_add_attribute_keeps_legacy_constant_port_position() and passed
	passed = _test_add_attribute_copies_selected_attribute_from_attributes_pin() and passed
	passed = _test_add_attribute_copies_all_attributes_from_attributes_pin() and passed

	if not passed:
		push_error("FlowCreateConstantAndAddAttributeTest failed.")
		quit(1)
		return
	quit(0)


func _test_create_constant_outputs_single_attribute_set() -> bool:
	var node = CreateConstantNode.new()
	node.name = "create_constant"
	node.settings = CreateConstantSettings.new()
	node.settings.output_target = "category"
	node.settings.data_type = FlowDataScript.DataType.String
	node.settings.cte_string = "Alpha"
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = []

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)

	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "category", PackedStringArray(["Alpha"]), "Create Constant should output one string value")
	node.free()
	return passed


func _test_add_attribute_requires_input() -> bool:
	var node = AddAttributeNode.new()
	node.name = "add_attribute"
	node.settings = AddAttributeSettings.new()
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = []

	_execute_node(node)

	var passed := (
		_expect(node.generated_bulks.is_empty(), "Add Attribute without input should not emit output")
		and _expect(node.err.contains("Input not connected"), "Add Attribute without input should report missing input")
	)
	node.free()
	return passed


func _test_add_attribute_constant_requires_input_and_fills_rows() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("shared", PackedStringArray(["broadcast"]), FlowDataScript.DataType.String)
	in_data.registerStream("id", PackedInt32Array([1, 2, 3]), FlowDataScript.DataType.Int)

	var node = _make_add_attribute(in_data, null)
	node.settings.output_target = "weight"
	node.settings.data_type = FlowDataScript.DataType.Float
	node.settings.cte_float = 2.5
	_execute_node(node)

	var out_data = _get_output(node)
	var passed := (
		_expect_ints(out_data, "id", PackedInt32Array([1, 2, 3]), "Input streams should be preserved")
		and _expect_strings(out_data, "shared", PackedStringArray(["broadcast"]), "Broadcast streams should stay broadcast")
		and _expect_floats(out_data, "weight", PackedFloat32Array([2.5, 2.5, 2.5]), "Constant attribute should fill input rows")
	)
	node.free()
	return passed


func _test_add_attribute_keeps_legacy_constant_port_position() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2]), FlowDataScript.DataType.Int)

	var legacy_cte_input := FlowDataScript.Data.new()
	legacy_cte_input.registerStream("not_attributes", PackedFloat32Array([9.0]), FlowDataScript.DataType.Float)

	var node = AddAttributeNode.new()
	node.name = "add_attribute"
	node.settings = AddAttributeSettings.new()
	node.settings.output_target = "weight"
	node.settings.data_type = FlowDataScript.DataType.Float
	node.settings.cte_float = 1.0
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data, legacy_cte_input]
	node.args_ports_by_name = { "cte_float": { "port": 1, "connected": true } }

	_execute_node(node)

	var out_data = _get_output(node)
	var passed := (
		_expect_floats(out_data, "weight", PackedFloat32Array([9.0, 9.0]), "Legacy cte_* port should still drive the constant value")
		and _expect(out_data.findStream("not_attributes") == null, "Port 1 should not be treated as the Attributes pin")
	)
	node.free()
	return passed


func _test_add_attribute_copies_selected_attribute_from_attributes_pin() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2, 3]), FlowDataScript.DataType.Int)

	var attributes_data := FlowDataScript.Data.new()
	attributes_data.registerStream("category", PackedStringArray(["A"]), FlowDataScript.DataType.String)

	var node = _make_add_attribute(in_data, attributes_data)
	node.settings.input_source = "category"
	node.settings.output_target = "copied_category"
	_execute_node(node)

	var out_data = _get_output(node)
	var passed := _expect_strings(out_data, "copied_category", PackedStringArray(["A", "A", "A"]), "Attributes pin should broadcast a single source value")
	node.free()
	return passed


func _test_add_attribute_copies_all_attributes_from_attributes_pin() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([1, 2]), FlowDataScript.DataType.Int)

	var attributes_data := FlowDataScript.Data.new()
	attributes_data.registerStream("category", PackedStringArray(["A", "B"]), FlowDataScript.DataType.String)
	attributes_data.registerStream("rank", PackedInt32Array([5]), FlowDataScript.DataType.Int)

	var node = _make_add_attribute(in_data, attributes_data)
	node.settings.copy_all_attributes = true
	_execute_node(node)

	var out_data = _get_output(node)
	var passed := (
		_expect_strings(out_data, "category", PackedStringArray(["A", "B"]), "Copy all should copy matching-size streams")
		and _expect_ints(out_data, "rank", PackedInt32Array([5, 5]), "Copy all should broadcast single-value streams")
	)
	node.free()
	return passed


func _make_add_attribute(in_data : FlowData.Data, attributes_data):
	var node = AddAttributeNode.new()
	node.name = "add_attribute"
	node.settings = AddAttributeSettings.new()
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data, null, attributes_data]
	return node


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


func _expect_floats(data, stream_name : String, expected : PackedFloat32Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(absf(float(stream.container[i]) - expected[i]) <= 0.0001, "%s: index %d got %s" % [message, i, stream.container[i]]):
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
