extends SceneTree

const FlowEditorScript = preload("res://addons/flow_nodes_editor/flow_editor.gd")
const FlowEditorScene = preload("res://addons/flow_nodes_editor/flow_editor.tscn")


func _init() -> void:
	if not _run_test():
		push_error("FlowNodeIdNavigationTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var passed := true
	passed = _test_locate_button_sits_before_arrange() and passed
	passed = _test_node_id_text_parsing_and_lookup() and passed
	return passed


func _test_locate_button_sits_before_arrange() -> bool:
	var editor := FlowEditorScene.instantiate()
	var toolbar := editor.get_node("VBoxContainer/ScrollContainer/HBoxContainer")
	var locate_button := toolbar.get_node_or_null("ButtonLocateNode")
	var arrange_button := toolbar.get_node_or_null("ButtonArrange")
	var passed := (
		_expect(locate_button != null, "Toolbar should include ButtonLocateNode.")
		and _expect(arrange_button != null, "Toolbar should include ButtonArrange.")
		and _expect(
			locate_button.get_index() == arrange_button.get_index() - 1,
			"ButtonLocateNode should be immediately left of ButtonArrange."
		)
	)
	editor.free()
	return passed


func _test_node_id_text_parsing_and_lookup() -> bool:
	var editor = FlowEditorScript.new()
	var graph_edit := GraphEdit.new()
	var node := GraphNode.new()
	node.name = "id_0049_match_and_set"
	graph_edit.add_child(node)
	editor.gedit = graph_edit

	var passed := (
		_expect(
			editor._extract_node_id_from_text("id_0049_match_and_set") == "id_0049_match_and_set",
			"Exact node id should parse as itself."
		)
		and _expect(
			editor._extract_node_id_from_text("node id: id_0049_match_and_set") == "id_0049_match_and_set",
			"Embedded node id should be extracted from clipboard text."
		)
		and _expect(
			editor._find_graph_node_by_id(" id_0049_match_and_set ") == node,
			"Node lookup should find a GraphNode by id."
		)
	)

	graph_edit.free()
	editor.free()
	return passed


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
