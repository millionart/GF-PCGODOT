extends SceneTree

const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"


func _init() -> void:
	var source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_comment_controls_include_random_color_button(source) and passed
	passed = _test_random_color_handler_updates_frame_tint(source) and passed
	passed = _test_random_color_preserves_alpha(source) and passed
	passed = _test_new_comment_default_uses_ue_color(source) and passed

	if not passed:
		push_error("FlowCommentFrameControlsTest failed.")
		quit(1)
		return
	quit(0)


func _test_comment_controls_include_random_color_button(source: String) -> bool:
	var body := _function_body(source, "_ensure_comment_frame_controls")
	return (
		_expect(body.contains("\"RandomColor\""), "Comment controls should include a RandomColor button.")
		and _expect(body.contains("\"Random Comment Color\""), "RandomColor button should have a tooltip.")
		and _expect(body.contains("_on_comment_frame_random_color_pressed.bind(frame)"), "RandomColor button should call its handler.")
	)


func _test_random_color_handler_updates_frame_tint(source: String) -> bool:
	var body := _function_body(source, "_on_comment_frame_random_color_pressed")
	return (
		_expect(body.contains("frame.tint_color = _random_comment_frame_color(frame.tint_color.a)"), "Random color handler should update frame tint_color.")
		and _expect(body.contains("frame.tint_color_enabled = true"), "Random color handler should enable frame tint.")
		and _expect(body.contains("record_undo_action(\"Random Comment Color\", before_state)"), "Random color handler should record undo.")
		and _expect(body.contains("queueSave()"), "Random color handler should save the graph.")
	)


func _test_random_color_preserves_alpha(source: String) -> bool:
	var body := _function_body(source, "_random_comment_frame_color")
	return _expect(body.contains("alpha)"), "Random comment color should preserve the existing alpha.")


func _test_new_comment_default_uses_ue_color(source: String) -> bool:
	var body := _function_body(source, "addComment")
	return _expect(body.contains("FlowNodeIO.DEFAULT_COMMENT_FRAME_TINT_COLOR"), "New comment frames should use the shared UE default color.")


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
