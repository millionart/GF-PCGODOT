extends SceneTree

const FlowEditorScript = preload("res://addons/flow_nodes_editor/flow_editor.gd")
const PLUGIN_SOURCE := "res://addons/flow_nodes_editor/plugin.gd"


func _init() -> void:
	var passed := true
	passed = _test_flow_editor_is_not_floating_in_headless() and passed
	passed = _test_floating_graph_dock_skips_bottom_placement_watch() and passed
	if not passed:
		push_error("FlowGraphFloatingModeRuntimeGuardTest failed.")
		quit(1)
		return
	quit(0)


func _test_flow_editor_is_not_floating_in_headless() -> bool:
	var editor = FlowEditorScript.new()
	var floating := editor._is_graph_panel_floating()
	editor.free()
	if floating:
		push_error("Flow graph panel should not be floating outside the editor.")
		return false
	return true


func _test_floating_graph_dock_skips_bottom_placement_watch() -> bool:
	var source := FileAccess.get_file_as_string(PLUGIN_SOURCE)
	var watch_body := _function_body(source, "_watch_graph_dock_bottom_placement")
	var ensure_body := _function_body(source, "_ensure_graph_dock")
	var reconcile_body := _function_body(source, "_reconcile_graph_dock_after_editor_layout")
	return (
		_expect(
			source.contains("func _graph_dock_is_floating_window()"),
			"Plugin should expose a floating-window dock guard."
		)
		and _expect(
			watch_body.contains("if _graph_dock_is_floating_window():"),
			"Bottom placement watch should skip floating graph dock windows."
		)
		and _expect(
			ensure_body.contains("not _graph_dock_is_floating_window()"),
			"Graph dock ensure should not schedule bottom placement while floating."
		)
		and _expect(
			reconcile_body.contains("if _graph_dock_is_floating_window():"),
			"Layout reconcile should leave floating graph dock windows alone."
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
