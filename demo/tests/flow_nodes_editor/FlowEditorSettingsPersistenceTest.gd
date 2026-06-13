extends SceneTree

const FlowEditorSettingsProxyScript = preload("res://addons/flow_nodes_editor/flow_editor_settings_proxy.gd")
const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"

const EXPECTED_SETTING_PATHS := {
	"auto_generate": "addons/flow_nodes_editor/auto_generate",
	"color_nodes": "addons/flow_nodes_editor/color_nodes",
	"native_graph_grid": "addons/flow_nodes_editor/use_native_graph_grid",
	"node_translation": "addons/flow_nodes_editor/node_translation",
	"hide_inspector_title": "addons/flow_nodes_editor/hide_inspector_title",
	"hide_resource_builtin_rows": "addons/flow_nodes_editor/hide_resource_builtin_rows",
	"track_external_edits": "addons/flow_nodes_editor/track_external_edits",
}


func _init() -> void:
	var source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_all_proxy_settings_have_editor_settings_paths(source) and passed
	passed = _test_color_nodes_is_loaded_saved_and_saved_on_toggle(source) and passed
	passed = _test_node_translation_is_loaded_saved_and_saved_on_toggle(source) and passed
	passed = _test_native_graph_grid_uses_only_graphedit_grid(source) and passed

	if not passed:
		push_error("FlowEditorSettingsPersistenceTest failed.")
		quit(1)
		return
	quit(0)


func _test_all_proxy_settings_have_editor_settings_paths(source : String) -> bool:
	var passed := true
	for setting in FlowEditorSettingsProxyScript.SETTINGS:
		var property_name := str(setting.property)
		var setting_path : String = EXPECTED_SETTING_PATHS.get(property_name, "")
		passed = _expect(setting_path != "", "Missing expected EditorSettings path for '%s'" % property_name) and passed
		passed = _expect(source.contains(setting_path), "FlowEditor should reference EditorSettings path '%s'" % setting_path) and passed
	return passed


func _test_color_nodes_is_loaded_saved_and_saved_on_toggle(source : String) -> bool:
	return (
		_expect(source.contains("color_nodes = bool(editor_settings.get_setting(EDITOR_SETTING_COLOR_NODES))"), "Color Nodes should load from EditorSettings")
		and _expect(source.contains("editor_settings.set_setting(EDITOR_SETTING_COLOR_NODES, color_nodes)"), "Color Nodes should save to EditorSettings")
		and _expect(_function_body_contains(source, "_on_color_nodes_toggled", "_save_editor_settings()"), "Color Nodes toggle should save immediately")
	)


func _test_node_translation_is_loaded_saved_and_saved_on_toggle(source : String) -> bool:
	return (
		_expect(source.contains("FlowI18n.set_node_translation_enabled(bool(editor_settings.get_setting(EDITOR_SETTING_NODE_TRANSLATION)))"), "Node Language should load from EditorSettings")
		and _expect(source.contains("editor_settings.set_setting(EDITOR_SETTING_NODE_TRANSLATION, FlowI18n.is_node_translation_enabled())"), "Node Language should save to EditorSettings")
		and _expect(_function_body_contains(source, "_on_node_translation_toggled", "_save_editor_settings()"), "Node Language toggle should save immediately")
	)


func _test_native_graph_grid_uses_only_graphedit_grid(source : String) -> bool:
	var grid_body := _function_body(source, "_apply_graph_grid_mode")
	return (
		_expect(grid_body.contains("gedit.show_grid = use_native_graph_grid"), "Native GraphEdit Grid should control GraphEdit.show_grid.")
		and _expect(not source.contains("custom_graph_grid"), "FlowEditor should not keep a custom grid instance.")
		and _expect(not source.contains("CustomGraphGrid"), "FlowEditor should not create CustomGraphGrid.")
		and _expect(not source.contains("custom_grid.gd"), "FlowEditor should not preload the custom grid script.")
	)


func _function_body(source : String, function_name : String) -> String:
	var start := source.find("func " + function_name)
	if start < 0:
		return ""
	var next_func := source.find("\nfunc ", start + 1)
	return source.substr(start) if next_func < 0 else source.substr(start, next_func - start)


func _function_body_contains(source : String, function_name : String, needle : String) -> bool:
	return _function_body(source, function_name).contains(needle)


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
