extends SceneTree

const FlowDataScript = preload("res://addons/flow_nodes_editor/flow_data.gd")
const CreateSplineNode = preload("res://addons/flow_nodes_editor/nodes/create_spline.gd")
const CreateSplineSettings = preload("res://addons/flow_nodes_editor/nodes/create_spline_settings.gd")


func _init() -> void:
	var passed := true
	passed = _test_create_data_only_does_not_require_owner() and passed
	passed = _test_closed_loop_adds_closing_point() and passed
	passed = _test_linear_mode_uses_zero_tangents() and passed
	passed = _test_custom_tangents_use_attributes() and passed

	if not passed:
		push_error("FlowCreateSplineTest failed.")
		quit(1)
		return
	quit(0)


func _test_create_data_only_does_not_require_owner() -> bool:
	var node = _execute_create_spline(_make_position_data(), null)
	var path = _get_output_path(node)
	var passed := (
		_expect(path != null, "CreateDataOnly should output a Path3D")
		and _expect(path.get_parent() == null, "CreateDataOnly path should not be added to the scene tree")
		and _expect(path.curve.get_point_count() == 3, "CreateDataOnly should preserve control point count")
		and _expect(path.curve.get_point_position(1).is_equal_approx(Vector3(10.0, 0.0, 0.0)), "Control point order should follow input order")
	)
	node.free()
	return passed


func _test_closed_loop_adds_closing_point() -> bool:
	var configure := func(settings):
		settings.closed_loop = true
		settings.linear = true
	var node = _execute_create_spline(_make_position_data(), configure)
	var path = _get_output_path(node)
	var passed := (
		_expect(path != null, "Closed loop should output a Path3D")
		and _expect(path.curve.get_point_count() == 4, "Closed loop should add a closing point")
		and _expect(path.curve.get_point_position(3).is_equal_approx(path.curve.get_point_position(0)), "Closing point should match first point")
	)
	node.free()
	return passed


func _test_linear_mode_uses_zero_tangents() -> bool:
	var configure := func(settings):
		settings.linear = true
	var node = _execute_create_spline(_make_position_data(), configure)
	var path = _get_output_path(node)
	var passed := (
		_expect(path != null, "Linear mode should output a Path3D")
		and _expect(path.curve.get_point_in(1).is_equal_approx(Vector3.ZERO), "Linear mode should zero arrive tangent")
		and _expect(path.curve.get_point_out(1).is_equal_approx(Vector3.ZERO), "Linear mode should zero leave tangent")
	)
	node.free()
	return passed


func _test_custom_tangents_use_attributes() -> bool:
	var data := _make_position_data()
	data.registerStream("ArriveTangent", PackedVector3Array([
		Vector3(-1.0, 0.0, 0.0),
		Vector3(-2.0, 0.0, 0.0),
		Vector3(-3.0, 0.0, 0.0),
	]), FlowDataScript.DataType.Vector)
	data.registerStream("LeaveTangent", PackedVector3Array([
		Vector3(1.0, 0.0, 0.0),
		Vector3(2.0, 0.0, 0.0),
		Vector3(3.0, 0.0, 0.0),
	]), FlowDataScript.DataType.Vector)

	var configure := func(settings):
		settings.apply_custom_tangents = true
	var node = _execute_create_spline(data, configure)
	var path = _get_output_path(node)
	var passed := (
		_expect(path != null, "Custom tangent mode should output a Path3D")
		and _expect(path.curve.get_point_in(1).is_equal_approx(Vector3(-2.0, 0.0, 0.0)), "ArriveTangent should drive point in tangent")
		and _expect(path.curve.get_point_out(1).is_equal_approx(Vector3(2.0, 0.0, 0.0)), "LeaveTangent should drive point out tangent")
	)
	node.free()
	return passed


func _make_position_data() -> FlowData.Data:
	var data := FlowDataScript.Data.new()
	data.registerStream(str(FlowDataScript.AttrPosition), PackedVector3Array([
		Vector3.ZERO,
		Vector3(10.0, 0.0, 0.0),
		Vector3(20.0, 10.0, 0.0),
	]), FlowDataScript.DataType.Vector)
	return data


func _execute_create_spline(in_data : FlowData.Data, configure):
	var node = CreateSplineNode.new()
	node.name = "create_spline"
	node.settings = CreateSplineSettings.new()
	if configure != null:
		configure.call(node.settings)
	node.deps = _empty_connections()
	node.dependants = _empty_connections()
	node.inputs = [in_data]

	var ctx = FlowDataScript.EvaluationContext.new()
	node.preExecute(ctx)
	node.execute(ctx)
	return node


func _get_output_path(node):
	if node.generated_bulks.is_empty():
		return null
	var bulk = node.generated_bulks[0]
	if bulk.is_empty():
		return null
	var out_data = bulk[0]
	if out_data == null:
		return null
	var stream = out_data.findStream("node")
	if stream == null or stream.container.is_empty():
		return null
	return stream.container[0] as Path3D


func _empty_connections() -> Array[Dictionary]:
	return []


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
