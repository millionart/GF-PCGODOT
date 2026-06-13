extends SceneTree

const PluginScript = preload("res://addons/flow_nodes_editor/plugin.gd")
const PLUGIN_SOURCE := "res://addons/flow_nodes_editor/plugin.gd"


func _init() -> void:
	var source := FileAccess.get_file_as_string(PLUGIN_SOURCE)
	var passed := true
	passed = _test_plugin_skips_reopening_active_graph_resource(source) and passed

	if not passed:
		push_error("FlowPluginResourceOpenGuardTest failed.")
		quit(1)
		return
	quit(0)


func _test_plugin_skips_reopening_active_graph_resource(source: String) -> bool:
	var helper_body := _function_body(source, "_is_active_graph_resource")
	var open_body := _function_body(source, "_open_flow_graph_resource_from_filesystem")
	return (
		_expect(
			source.contains("func _is_active_graph_resource(graph_resource: FlowGraphResource) -> bool:"),
			"Plugin should have an active graph resource guard."
		)
		and _expect(
			helper_body.contains("current_resource == graph_resource"),
			"Active graph guard should detect the same resource instance."
		)
		and _expect(
			helper_body.contains("current_resource.resource_path == graph_resource.resource_path"),
			"Active graph guard should detect the same saved resource path."
		)
		and _expect(
			open_body.contains("if _is_active_graph_resource(graph_resource):"),
			"Plugin resource open path should skip reopening the active graph."
		)
		and _expect(
			open_body.contains("_make_graph_dock_visible()") and open_body.contains("return"),
			"Skipping active graph reopen should still make the graph dock visible."
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
