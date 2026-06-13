extends SceneTree

const FlowNodeIO = preload("res://addons/flow_nodes_editor/flow_nodes_io.gd")


class MockFlowEditor:
	extends Control

	var ui_scale := 1.0
	var gedit := GraphEdit.new()

	func _init() -> void:
		add_child(gedit)


func _init() -> void:
	var passed := true
	passed = _test_default_comment_tint_matches_ue_color() and passed
	passed = _test_serializes_comment_frame_without_nodes() and passed
	passed = _test_serializes_with_null_previous_data() and passed

	if not passed:
		push_error("FlowNodeIOSerializationTest failed.")
		quit(1)
		return
	quit(0)


func _test_default_comment_tint_matches_ue_color() -> bool:
	var color := FlowNodeIO.DEFAULT_COMMENT_FRAME_TINT_COLOR
	return (
		_expect(is_equal_approx(color.r, 0.15), "Default comment frame tint red should match UE.")
		and _expect(is_equal_approx(color.g, 0.15), "Default comment frame tint green should match UE.")
		and _expect(is_equal_approx(color.b, 0.15), "Default comment frame tint blue should match UE.")
		and _expect(is_equal_approx(color.a, 0.5), "Default comment frame tint alpha should match UE.")
	)


func _test_serializes_comment_frame_without_nodes() -> bool:
	var editor := MockFlowEditor.new()
	var frame := _make_frame()
	editor.gedit.add_child(frame)

	var data := FlowNodeIO.nodes_as_dict([], [frame], editor, false)
	var frames: Array = data.get("frames", [])
	var passed := (
		_expect(data.get("min_pos") == Vector2(40, 80), "Frame-only serialization should use frame position as min_pos.")
		and _expect(frames.size() == 1, "Frame-only serialization should include the frame.")
		and _expect(frames[0].get("position") == Vector2.ZERO, "Frame position should be relative to min_pos.")
	)
	editor.free()
	return passed


func _test_serializes_with_null_previous_data() -> bool:
	var editor := MockFlowEditor.new()
	var frame := _make_frame()
	editor.gedit.add_child(frame)

	var data := FlowNodeIO.nodes_as_dict([], [frame], editor, false, null)
	var passed := _expect(data.get("frames", []).size() == 1, "Nil previous_data should be treated as empty data.")
	editor.free()
	return passed


func _make_frame() -> GraphFrame:
	var frame := GraphFrame.new()
	frame.name = "comment"
	frame.title = "Comment"
	frame.position_offset = Vector2(40, 80)
	frame.size = Vector2(320, 200)
	frame.tint_color = FlowNodeIO.DEFAULT_COMMENT_FRAME_TINT_COLOR
	frame.tint_color_enabled = true
	return frame


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
