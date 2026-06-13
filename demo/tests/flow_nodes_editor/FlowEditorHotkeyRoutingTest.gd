extends SceneTree

const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"


func _init() -> void:
	var source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_node_state_hotkeys_are_only_dispatched_from_input(source) and passed
	passed = _test_graph_edit_hotkeys_do_not_dispatch_node_state_actions(source) and passed
	passed = _test_hotkeys_ignore_text_editing_focus(source) and passed
	passed = _test_set_variable_name_edit_does_not_reinspect(source) and passed

	if not passed:
		push_error("FlowEditorHotkeyRoutingTest failed.")
		quit(1)
		return
	quit(0)


func _test_node_state_hotkeys_are_only_dispatched_from_input(source: String) -> bool:
	var input_body := _function_body(source, "_input")
	return (
		_expect(input_body.contains("_handle_flow_key_command(key_event)"), "_input should dispatch node-state hotkeys.")
		and _expect(input_body.contains("get_viewport().set_input_as_handled()"), "_input should mark handled node-state hotkeys.")
	)


func _test_graph_edit_hotkeys_do_not_dispatch_node_state_actions(source: String) -> bool:
	var graph_input_body := _function_body(source, "_on_graph_edit_gui_input")
	var forbidden := [
		"_hotkey_toggle_debug",
		"_hotkey_toggle_inspect",
		"_hotkey_toggle_trace",
		"_hotkey_toggle_disabled",
		"_hotkey_clear_all_debug",
	]
	var passed := true
	for token in forbidden:
		passed = _expect(not graph_input_body.contains(token), "GraphEdit gui_input should not dispatch %s." % token) and passed
	return passed


func _test_hotkeys_ignore_text_editing_focus(source: String) -> bool:
	var input_body := _function_body(source, "_input")
	var graph_input_body := _function_body(source, "_on_graph_edit_gui_input")
	return (
		_expect(input_body.contains("_is_text_editing_focus_active()"), "_input should ignore text editing focus.")
		and _expect(graph_input_body.contains("_is_text_editing_focus_active()"), "GraphEdit gui_input should ignore text editing focus.")
	)


func _test_set_variable_name_edit_does_not_reinspect(source: String) -> bool:
	var property_changed_body := _function_body(source, "onNodePropertyChanged")
	return _expect(
		not property_changed_body.contains("_inspect_graph_element(inspected_node)"),
		"Set Variable name edits should not rebuild inspectors while text input has focus."
	)


func _function_body(source: String, function_name: String) -> String:
	var start := source.find("func " + function_name)
	if start < 0:
		return ""
	var next_func := source.find("\nfunc ", start + 1)
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
