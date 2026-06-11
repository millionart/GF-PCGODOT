extends SceneTree

const FlowEditorScript = preload("res://addons/flow_nodes_editor/flow_editor.gd")


func _init() -> void:
	if not _run_test():
		push_error("FlowGraphFloatingModeRuntimeGuardTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var editor = FlowEditorScript.new()
	var floating := editor._is_graph_panel_floating()
	editor.free()
	if floating:
		push_error("Flow graph panel should not be floating outside the editor.")
		return false
	return true
