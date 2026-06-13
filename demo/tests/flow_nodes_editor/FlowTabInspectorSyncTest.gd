extends SceneTree

const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"


func _init() -> void:
	var source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_tab_switch_syncs_inspector(source) and passed
	passed = _test_tab_switch_caches_per_tab_inspector_state(source) and passed
	passed = _test_tab_switch_clears_stale_native_inspector(source) and passed

	if not passed:
		push_error("FlowTabInspectorSyncTest failed.")
		quit(1)
		return
	quit(0)


func _test_tab_switch_syncs_inspector(source: String) -> bool:
	var finish_body := _function_body(source, "_finish_tab_switch")
	var sync_body := _function_body(source, "_sync_inspector_after_tab_switch")
	var selection_body := _function_body(source, "_sync_inspector_from_current_selection")
	return (
		_expect(
			finish_body.contains("_sync_inspector_after_tab_switch()"),
			"Tab switch finish should sync the inspector to the active tab."
		)
		and _expect(
			sync_body.contains("_restore_inspector_state(cached_state)"),
			"Tab switch should restore the active tab's cached inspector state before using selection fallback."
		)
		and _expect(
			selection_body.contains("_inspect_graph_element(selected_nodes[0])"),
			"Single selected node should be inspected after tab switch."
		)
		and _expect(
			selection_body.contains("_inspect_graph_element(selected_frames[0])"),
			"Single selected frame should be inspected after tab switch."
		)
	)


func _test_tab_switch_caches_per_tab_inspector_state(source: String) -> bool:
	var cache_body := _function_body(source, "_cache_active_tab_graph_ui")
	var capture_body := _function_body(source, "_capture_current_inspector_state")
	var restore_body := _function_body(source, "_restore_inspector_state")
	var helper_body := _function_body(source, "_inspector_is_showing_current_graph_resource")
	return (
		_expect(
			not source.contains("inspect_graph_resource_after_tab_switch"),
			"Inspector state should be cached per tab instead of using a cross-tab flag."
		)
		and _expect(
			cache_body.contains("\"cached_inspector_state\"") and cache_body.contains("_capture_current_inspector_state()"),
			"Tab cache should store the current tab's inspector state."
		)
		and _expect(
			capture_body.contains("INSPECTOR_STATE_GRAPH_RESOURCE") and capture_body.contains("INSPECTOR_STATE_GRAPH_ELEMENT"),
			"Inspector state capture should handle graph-level panels and graph elements."
		)
		and _expect(
			restore_body.contains("inspector.edit(current_resource)") and restore_body.contains("_inspect_in_native(current_resource)"),
			"Restored graph-level panels should update both Flow and native inspectors."
		)
		and _expect(
			restore_body.contains("_inspect_graph_element(node)"),
			"Restored node or comment inspector state should re-inspect that graph element."
		)
		and _expect(
			helper_body.contains("native_inspector_target == current_resource"),
			"Graph resource inspector mode detection should include Godot's native inspector target."
		)
		and _expect(
			helper_body.contains("inspected_node != null"),
			"Graph resource inspector mode should not misclassify selected input/output nodes as graph-level panels."
		)
	)


func _test_tab_switch_clears_stale_native_inspector(source: String) -> bool:
	var clear_body := _function_body(source, "_clear_current_inspector")
	return (
		_expect(
			clear_body.contains("native_inspector_target = null"),
			"Tab switch should clear stale native inspector target when there is no single selection."
		)
		and _expect(
			clear_body.contains("native_inspector.edit(null)"),
			"Tab switch should clear Godot's native inspector when there is no single selection."
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
