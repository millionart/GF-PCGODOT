extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const BranchNode = preload("res://addons/flow_nodes_editor/nodes/branch.gd")
const BranchSettings = preload("res://addons/flow_nodes_editor/nodes/branch_settings.gd")
const ExpressionNode = preload("res://addons/flow_nodes_editor/nodes/expression.gd")
const ExpressionSettings = preload("res://addons/flow_nodes_editor/nodes/expression_settings.gd")
const PointToAttributeSetNode = preload("res://addons/flow_nodes_editor/nodes/point_to_attribute_set.gd")
const PointToAttributeSetSettings = preload("res://addons/flow_nodes_editor/nodes/point_to_attribute_set_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_expression_writes_bool_stream_as_bytes() and passed
	passed = _test_branch_unselected_output_keeps_empty_schema() and passed
	passed = _test_point_to_attribute_set_preserves_transforms_without_nil_return_error() and passed

	if not passed:
		push_error("FlowCommonNodeRegressionTest failed.")
		quit(1)
		return
	quit(0)


func _test_expression_writes_bool_stream_as_bytes() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("value", PackedInt32Array([0, 1, 2]), FlowDataScript.DataType.Int)

	var node = ExpressionNode.new()
	node.name = "expression"
	node.settings = ExpressionSettings.new()
	node.settings.expression = "Index == 1"
	node.settings.out_name = "is_middle"
	node.deps = []
	node.dependants = []
	node.inputs = [in_data]

	_execute_node(node)

	var out_data = _get_output(node, 0)
	var passed := _expect_byte_stream(
		out_data,
		"is_middle",
		PackedByteArray([0, 1, 0]),
		"Expression should write bool results as 0/1 bytes"
	)
	node.free()
	return passed


func _test_branch_unselected_output_keeps_empty_schema() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("id", PackedInt32Array([10, 20, 30]), FlowDataScript.DataType.Int)
	in_data.registerStream("shared", PackedStringArray(["constant"]), FlowDataScript.DataType.String)

	var node = BranchNode.new()
	node.name = "branch"
	node.settings = BranchSettings.new()
	node.settings.branch_value = true
	node.deps = []
	node.dependants = []
	node.inputs = [in_data]

	_execute_node(node)

	var selected_data = _get_output(node, 0)
	var unselected_data = _get_output(node, 1)
	var passed := (
		_expect(selected_data == in_data, "Selected branch should forward the input data")
		and _expect(unselected_data != null, "Unselected branch should emit data")
		and _expect(unselected_data.size() == 0, "Unselected branch should have zero rows")
		and _expect_empty_stream(unselected_data, "id", FlowDataScript.DataType.Int)
		and _expect_empty_stream(unselected_data, "shared", FlowDataScript.DataType.String)
	)
	node.free()
	return passed


func _test_point_to_attribute_set_preserves_transforms_without_nil_return_error() -> bool:
	var in_data := FlowDataScript.Data.new()
	in_data.addCommonStreams(1)

	var node = PointToAttributeSetNode.new()
	node.name = "point_to_attribute_set"
	node.settings = PointToAttributeSetSettings.new()
	node.settings.drop_point_transform_streams = true
	node.settings.preserve_transforms_as_attributes = true
	node.deps = []
	node.dependants = []
	node.inputs = [in_data]

	_execute_node(node)

	var out_data = _get_output(node, 0)
	var passed := (
		_expect(out_data != null, "Point To Attribute Set should emit output")
		and _expect(out_data.findStream("position") == null, "Position stream should be dropped")
		and _expect(out_data.findStream("rotation") == null, "Rotation stream should be dropped")
		and _expect(out_data.findStream("size") == null, "Size stream should be dropped")
		and _expect_stream_size(out_data, "point_position", FlowDataScript.DataType.Vector, 1)
		and _expect_stream_size(out_data, "point_rotation", FlowDataScript.DataType.Vector, 1)
		and _expect_stream_size(out_data, "point_size", FlowDataScript.DataType.Vector, 1)
	)
	node.free()
	return passed


func _execute_node(node) -> void:
	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)


func _get_output(node, port : int):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if port >= bulk.size():
		return null
	return bulk[port]


func _expect_empty_stream(data, stream_name : String, data_type : int) -> bool:
	return _expect_stream_size(data, stream_name, data_type, 0)


func _expect_stream_size(data, stream_name : String, data_type : int, expected_size : int) -> bool:
	if not _expect(data != null, "Missing data for stream '%s'" % stream_name):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "Missing stream '%s'" % stream_name):
		return false
	return (
		_expect(stream.data_type == data_type, "Stream '%s' has type %d" % [stream_name, stream.data_type])
		and _expect(stream.container.size() == expected_size, "Stream '%s' should have %d values" % [stream_name, expected_size])
	)


func _expect_byte_stream(data, stream_name : String, expected : PackedByteArray, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.data_type == FlowDataScript.DataType.Bool, "%s: expected Bool stream" % message):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values" % [message, expected.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(int(stream.container[i]) == int(expected[i]), "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
