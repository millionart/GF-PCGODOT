extends SceneTree

const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"


func _init() -> void:
	var source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_node_state_hotkeys_are_only_dispatched_from_input(source) and passed
	passed = _test_graph_edit_hotkeys_do_not_dispatch_node_state_actions(source) and passed
	passed = _test_hotkeys_ignore_text_editing_focus(source) and passed
	passed = _test_set_variable_name_edit_does_not_reinspect(source) and passed
	passed = _test_flow_inspector_text_edits_are_deferred(source) and passed
	passed = _test_box_select_defers_selection_inspection(source) and passed
	passed = _test_node_move_toggles_low_latency_connection_lines(source) and passed
	passed = _test_blank_click_hides_floating_internal_inspector(source) and passed
	passed = _test_right_drag_pan_uses_screen_delta(source) and passed

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


func _test_flow_inspector_text_edits_are_deferred(source: String) -> bool:
	var flow_edit_body := _function_body(source, "_on_flow_inspector_property_edited")
	var flush_body := _function_body(source, "_flush_pending_flow_inspector_edits")
	return (
		_expect(
			flow_edit_body.contains("_queue_flow_inspector_property_edited_until_text_edit_finished(prop_name)"),
			"Flow inspector edits should be deferred while text input has focus."
		)
		and _expect(
			flush_body.contains("_apply_flow_inspector_property_edited(String(prop_name))"),
			"Deferred Flow inspector edits should use the normal apply path."
		)
	)


func _test_box_select_defers_selection_inspection(source: String) -> bool:
	var selected_body := _function_body(source, "_on_graph_edit_node_selected")
	var input_body := _function_body(source, "_on_graph_edit_gui_input")
	var deferred_body := _function_body(source, "_inspect_graph_selection_after_box_select")
	return (
		_expect(
			selected_body.contains("if defer_selection_inspection_until_mouse_release:"),
			"Box-select node_selected events should defer inspector work."
		)
		and _expect(
			selected_body.contains("selection_inspection_pending_after_drag = true"),
			"Box-select node_selected events should mark a deferred inspection."
		)
		and _expect(
			input_body.contains("_track_left_box_select_drag(event)"),
			"GraphEdit input should track box-select drag state."
		)
		and _expect(
			deferred_body.contains("_inspect_graph_element(selected_nodes[0], false)"),
			"Final single-node box selection should inspect once after release without prefetching attribute lists."
		)
	)


func _test_node_move_toggles_low_latency_connection_lines(source: String) -> bool:
	var begin_body := _function_body(source, "_on_graph_edit_begin_node_move")
	var end_body := _function_body(source, "_on_graph_edit_end_node_move")
	return (
		_expect(
			begin_body.contains("set_interaction_low_latency") and begin_body.contains("true"),
			"Node move should enable low-latency connection lines."
		)
		and _expect(
			end_body.contains("set_interaction_low_latency") and end_body.contains("false"),
			"Node move should disable low-latency connection lines."
		)
	)


func _test_blank_click_hides_floating_internal_inspector(source: String) -> bool:
	var input_body := _function_body(source, "_on_graph_edit_gui_input")
	var hide_body := _function_body(source, "_hide_internal_inspector_on_blank_click")
	return (
		_expect(
			input_body.contains("_hide_internal_inspector_on_blank_click(evt_mouse)"),
			"Plain blank GraphEdit clicks should hide the floating internal inspector."
		)
		and _expect(
			hide_body.contains("internal_inspector_floating_mode"),
			"Blank-click inspector hiding should only run for floating internal inspector mode."
		)
		and _expect(
			hide_body.contains("_get_graph_element_at_local_position(event.position)"),
			"Blank-click inspector hiding should not run when clicking a node or comment frame."
		)
		and _expect(
			hide_body.contains("_clear_current_inspector()") and hide_body.contains("_apply_internal_inspector_mode(true)"),
			"Blank-click inspector hiding should clear and relayout the internal inspector."
		)
	)


func _test_right_drag_pan_uses_screen_delta(source: String) -> bool:
	var input_body := _function_body(source, "_input")
	var pan_body := _function_body(source, "_handle_right_mouse_pan")
	var active_body := _function_body(source, "_handle_active_right_mouse_pan_input")
	var update_body := _function_body(source, "_update_right_mouse_pan")
	return (
		_expect(
			input_body.contains("_handle_active_right_mouse_pan_input(event)"),
			"Active right-drag panning should capture motion from _input so child controls cannot interrupt it."
		)
		and _expect(
			active_body.contains("_update_right_mouse_pan(evt_motion.relative)"),
			"Viewport-level mouse motion should update active right-drag panning from raw movement delta."
		)
		and _expect(
			active_body.contains("_end_right_mouse_pan(evt_mouse.position)"),
			"Viewport-level right mouse release should end active right-drag panning."
		)
		and _expect(
			update_body.contains("gedit.scroll_offset -= screen_delta"),
			"Right-drag panning should update the view from each screen-space cursor delta."
		)
		and _expect(
			update_body.contains("right_drag_pan_total_distance += screen_delta.length()"),
			"Right-drag panning should use accumulated travel distance for click-vs-drag detection."
		)
		and _expect(
			not pan_body.contains("delta / maxf(gedit.zoom") and not update_body.contains("screen_delta / maxf(gedit.zoom"),
			"Right-drag panning should not divide mouse delta by zoom."
		)
		and _expect(
			not update_body.contains("sync_scroll_offset_immediately") and not update_body.contains("queue_redraw()"),
			"Right-drag panning should not do extra per-motion redraw or GDScript layout work."
		)
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
