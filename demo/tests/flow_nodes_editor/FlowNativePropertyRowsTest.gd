extends SceneTree

const FlowNativePropertyRows = preload("res://addons/flow_nodes_editor/flow_native_property_rows.gd")
const FlowEditor = preload("res://addons/flow_nodes_editor/flow_editor.gd")
const SetVariableNodeSettings = preload("res://addons/flow_nodes_editor/nodes/set_variable_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_intermediate_text_edit_does_not_emit_property_edited() and passed
	passed = _test_flow_editor_detects_text_editing_focus_controls() and passed

	if not passed:
		push_error("FlowNativePropertyRowsTest failed.")
		quit(1)
		return
	quit(0)


func _test_intermediate_text_edit_does_not_emit_property_edited() -> bool:
	var rows := FlowNativePropertyRows.new()
	var settings := SetVariableNodeSettings.new()
	var edited_properties: Array[String] = []
	rows.edited_object = settings
	rows.property_edited.connect(func(prop_name: String):
		edited_properties.append(prop_name)
	)

	rows._on_property_changed(&"variable_name", "a", &"", true)
	var passed := _expect(settings.variable_name == "a", "Intermediate text edits should update the setting value.")
	passed = _expect(edited_properties.is_empty(), "Intermediate text edits should not emit property_edited.") and passed

	rows._on_property_changed(&"variable_name", "ab", &"", false)
	passed = _expect(settings.variable_name == "ab", "Final text edits should update the setting value.") and passed
	passed = _expect(edited_properties == ["variable_name"], "Final text edits should emit property_edited once.") and passed
	rows.free()
	return passed


func _test_flow_editor_detects_text_editing_focus_controls() -> bool:
	var line_edit := LineEdit.new()
	var text_edit := TextEdit.new()
	var spin_box := SpinBox.new()
	var child_control := Control.new()
	line_edit.add_child(child_control)

	var passed := _expect(FlowEditor.is_text_editing_control(line_edit), "LineEdit should count as text editing.")
	passed = _expect(FlowEditor.is_text_editing_control(text_edit), "TextEdit should count as text editing.") and passed
	passed = _expect(FlowEditor.is_text_editing_control(spin_box), "SpinBox should count as text editing.") and passed
	passed = _expect(FlowEditor.is_text_editing_control(child_control), "LineEdit child focus should count as text editing.") and passed

	line_edit.free()
	text_edit.free()
	spin_box.free()
	return passed


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
