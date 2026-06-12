extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const SplineToSegmentNode = preload("res://addons/flow_nodes_editor/nodes/split_splines.gd")
const SplineToSegmentSettings = preload("res://addons/flow_nodes_editor/nodes/split_splines_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_node_title_matches_ue() and passed
	passed = _test_outputs_one_point_per_control_point_segment() and passed

	if not passed:
		push_error("FlowSplineToSegmentTest failed.")
		quit(1)
		return
	quit(0)


func _test_node_title_matches_ue() -> bool:
	var node = SplineToSegmentNode.new()
	var meta := node.getMeta()
	var passed := (
		_expect(meta.get("title", "") == "Spline to Segment", "Node title should match UE PCG")
		and _expect(meta.get("outs", [])[0].get("label", "") == "Out", "Output pin should use the default point output label")
	)
	node.free()
	return passed


func _test_outputs_one_point_per_control_point_segment() -> bool:
	var path := Path3D.new()
	path.curve = Curve3D.new()
	path.curve.add_point(Vector3.ZERO)
	path.curve.add_point(Vector3(10.0, 0.0, 0.0))
	path.curve.add_point(Vector3(10.0, 0.0, 10.0))

	var in_data := FlowDataScript.Data.new()
	in_data.registerStream("node", [path], FlowDataScript.DataType.NodePath)

	var node = SplineToSegmentNode.new()
	node.name = "spline_to_segment"
	node.settings = SplineToSegmentSettings.new()
	node.deps = []
	node.dependants = []
	node.inputs = [in_data]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)

	var out_data = _get_output(node)
	var passed := (
		_expect_vectors(out_data, "position", PackedVector3Array([Vector3(5.0, 0.0, 0.0), Vector3(10.0, 0.0, 5.0)]), "Segment centers should come from adjacent control points")
		and _expect_vectors(out_data, "size", PackedVector3Array([Vector3(10.0, 1.0, 1.0), Vector3(10.0, 1.0, 1.0)]), "Segment sizes should use full segment length on local X")
		and _expect_ints(out_data, "SegmentIndex", PackedInt32Array([0, 1]), "SegmentIndex should match segment order")
		and _expect_ints(out_data, "SegmentPreviousIndex", PackedInt32Array([-1, 0]), "SegmentPreviousIndex should encode open-start boundary")
		and _expect_ints(out_data, "SegmentNextIndex", PackedInt32Array([1, -1]), "SegmentNextIndex should encode open-end boundary")
		and _expect(out_data.findStream("segment_start") == null, "Legacy segment_start output should not be emitted")
	)
	node.free()
	path.free()
	return passed


func _get_output(node):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	return bulk[0]


func _expect_vectors(data, stream_name : String, expected : PackedVector3Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(stream.container[i].is_equal_approx(expected[i]), "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect_ints(data, stream_name : String, expected : PackedInt32Array, message : String) -> bool:
	if not _expect(data != null, "%s: missing output" % message):
		return false
	var stream = data.findStream(stream_name)
	if not _expect(stream != null, "%s: missing stream '%s'" % [message, stream_name]):
		return false
	if not _expect(stream.container.size() == expected.size(), "%s: expected %d values, got %d" % [message, expected.size(), stream.container.size()]):
		return false
	for i in range(expected.size()):
		if not _expect(stream.container[i] == expected[i], "%s: index %d got %s" % [message, i, stream.container[i]]):
			return false
	return true


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
