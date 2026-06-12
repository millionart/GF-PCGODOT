extends SceneTree

const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const GetAttributeFromPointIndexNode = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index.gd")
const MakeVectorNode = preload("res://addons/flow_nodes_editor/nodes/make_vector.gd")
const SetVariableNode = preload("res://addons/flow_nodes_editor/nodes/set_variable.gd")


func _init() -> void:
	if not _run_test():
		push_error("FlowUnknownPinTypeColorTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var set_variable := SetVariableNode.new()
	var dynamic_source := GetAttributeFromPointIndexNode.new()
	var typed_source := MakeVectorNode.new()

	var passed := (
		_expect(
			FlowNodeBaseScript.getColorForFlowDataType(FlowData.DataType.Invalid) == Color.WHITE,
			"Unknown static flow data type should display white."
		)
		and _expect(
			set_variable._get_explicit_source_port_data_type(dynamic_source, 0) == FlowData.DataType.Invalid,
			"Dynamic outputs without explicit data_type should stay unknown instead of falling back to Bool."
		)
		and _expect(
			set_variable._get_explicit_source_port_data_type(typed_source, 0) == FlowData.DataType.Vector,
			"Outputs with explicit data_type should keep their declared type."
		)
	)

	set_variable.free()
	dynamic_source.free()
	typed_source.free()
	return passed


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
