@tool
extends FlowNodeBase

const SplineToSegmentSettings = preload("res://addons/flow_nodes_editor/nodes/spline_to_segment_settings.gd")

const ATTR_PREVIOUS_TANGENT := "PreviousTangent"
const ATTR_NEXT_TANGENT := "NextTangent"
const ATTR_SEGMENT_INDEX := "SegmentIndex"
const ATTR_PREVIOUS_INDEX := "SegmentPreviousIndex"
const ATTR_NEXT_INDEX := "SegmentNextIndex"
const ATTR_PREVIOUS_ANGLE := "PreviousAngle"
const ATTR_NEXT_ANGLE := "NextAngle"
const ATTR_CLOCKWISE := "Clockwise"

func _init():
	meta_node = {
		"title" : "Spline to Segment",
		"settings" : SplineToSegmentSettings,
		"aliases" : ["Spline To Segment", "SplineToSegment"],
		"category" : "Spatial",
		"ins" : [{ "label" : "Input", "data_type" : FlowData.DataType.NodePath }],
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Takes Path3D splines as input and creates point data where each point represents one segment between two connected control points.",
	}

func execute(ctx : FlowData.EvaluationContext):
	var in_data : FlowData.Data = require_input(0, ctx)
	if in_data == null:
		return
	var stream = in_data.findStream(settings.spline_stream_attribute)
	if stream == null or stream.data_type != FlowData.DataType.NodePath:
		setError("Input must provide a Path3D node stream named '%s'" % settings.spline_stream_attribute)
		return

	var positions := PackedVector3Array()
	var rotations := PackedVector3Array()
	var sizes := PackedVector3Array()
	var segment_indices := PackedInt32Array()
	var previous_indices := PackedInt32Array()
	var next_indices := PackedInt32Array()
	var previous_angles := PackedFloat32Array()
	var next_angles := PackedFloat32Array()
	var previous_tangents := PackedVector3Array()
	var next_tangents := PackedVector3Array()
	var clockwise_values := PackedByteArray()

	for _spline_idx in range(stream.container.size()):
		var path := stream.container[_spline_idx] as Path3D
		if path == null or path.curve == null:
			continue
		var curve : Curve3D = path.curve
		var num_segments := _curve_segment_count(path)
		if num_segments < 1:
			continue

		var directions := PackedVector3Array()
		directions.resize(num_segments)
		for seg_idx in range(num_segments):
			var next_idx := (seg_idx + 1) % curve.get_point_count()
			var p0 := _control_point_world_position(path, seg_idx)
			var p1 := _control_point_world_position(path, next_idx)
			var delta := p1 - p0
			if delta.length_squared() <= 0.0000001:
				directions[seg_idx] = Vector3.ZERO
				continue
			directions[seg_idx] = delta.normalized()

		var is_closed := _is_closed_loop(path)
		var is_clockwise := is_closed and _is_clockwise(directions)
		for seg_idx in range(num_segments):
			var direction : Vector3 = directions[seg_idx]
			if direction == Vector3.ZERO:
				continue
			var next_idx := (seg_idx + 1) % curve.get_point_count()
			var p0 := _control_point_world_position(path, seg_idx)
			var p1 := _control_point_world_position(path, next_idx)
			var delta := p1 - p0
			var center := (p0 + p1) * 0.5
			var basis := _basis_from_x_axis(direction, _path_transform(path).basis.y)
			positions.append(center)
			rotations.append(FlowData.basisToEuler(basis))
			sizes.append(Vector3(delta.length(), 1.0, 1.0))
			segment_indices.append(seg_idx)
			if settings.extract_connectivity_info:
				previous_indices.append(_previous_segment_index(seg_idx, num_segments, is_closed))
				next_indices.append(_next_segment_index(seg_idx, num_segments, is_closed))
			if settings.extract_angles:
				previous_angles.append(_previous_angle(seg_idx, directions, is_closed))
				next_angles.append(_next_angle(seg_idx, directions, is_closed))
			if settings.extract_tangents:
				previous_tangents.append(_previous_tangent(seg_idx, directions, is_closed))
				next_tangents.append(_next_tangent(seg_idx, directions, is_closed))
			if settings.extract_clockwise_info:
				clockwise_values.append(1 if is_clockwise else 0)

	var out := FlowData.Data.new()
	out.addCommonStreams(positions.size())
	var op := out.getVector3Container(FlowData.AttrPosition)
	var orot := out.getVector3Container(FlowData.AttrRotation)
	var osize := out.getVector3Container(FlowData.AttrSize)
	for i in range(positions.size()):
		op[i] = positions[i]
		orot[i] = rotations[i]
		osize[i] = sizes[i]
	if settings.extract_connectivity_info:
		out.registerStream(ATTR_SEGMENT_INDEX, segment_indices, FlowData.DataType.Int)
		out.registerStream(ATTR_PREVIOUS_INDEX, previous_indices, FlowData.DataType.Int)
		out.registerStream(ATTR_NEXT_INDEX, next_indices, FlowData.DataType.Int)
	if settings.extract_angles:
		out.registerStream(ATTR_PREVIOUS_ANGLE, previous_angles, FlowData.DataType.Float)
		out.registerStream(ATTR_NEXT_ANGLE, next_angles, FlowData.DataType.Float)
	if settings.extract_tangents:
		out.registerStream(ATTR_PREVIOUS_TANGENT, previous_tangents, FlowData.DataType.Vector)
		out.registerStream(ATTR_NEXT_TANGENT, next_tangents, FlowData.DataType.Vector)
	if settings.extract_clockwise_info:
		out.registerStream(ATTR_CLOCKWISE, clockwise_values, FlowData.DataType.Bool)
	set_output(0, out)

func _curve_segment_count(path : Path3D) -> int:
	var point_count : int = path.curve.get_point_count()
	if point_count < 2:
		return 0
	if _is_closed_loop(path) and not _last_point_duplicates_first(path):
		return point_count
	return point_count - 1

func _is_closed_loop(path : Path3D) -> bool:
	return path.has_meta("closed_loop") and bool(path.get_meta("closed_loop"))

func _last_point_duplicates_first(path : Path3D) -> bool:
	var point_count : int = path.curve.get_point_count()
	if point_count < 2:
		return false
	return path.curve.get_point_position(0).is_equal_approx(path.curve.get_point_position(point_count - 1))

func _control_point_world_position(path : Path3D, point_idx : int) -> Vector3:
	return _path_transform(path) * path.curve.get_point_position(point_idx)

func _path_transform(path : Path3D) -> Transform3D:
	if path.is_inside_tree():
		return path.global_transform

	var path_transform := path.transform
	var parent := path.get_parent()
	while parent is Node3D:
		var parent_3d := parent as Node3D
		path_transform = parent_3d.transform * path_transform
		parent = parent_3d.get_parent()
	return path_transform

func _basis_from_x_axis(x_axis : Vector3, up_axis : Vector3) -> Basis:
	var x := x_axis.normalized()
	var up := up_axis.normalized()
	if up.length_squared() <= 0.0000001 or absf(x.dot(up)) > 0.999:
		up = Vector3.UP if absf(x.dot(Vector3.UP)) <= 0.999 else Vector3.FORWARD
	var z := x.cross(up).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z).orthonormalized()

func _previous_segment_index(seg_idx : int, num_segments : int, is_closed : bool) -> int:
	if seg_idx > 0:
		return seg_idx - 1
	return num_segments - 1 if is_closed else -1

func _next_segment_index(seg_idx : int, num_segments : int, is_closed : bool) -> int:
	if seg_idx < num_segments - 1:
		return seg_idx + 1
	return 0 if is_closed else -1

func _previous_tangent(seg_idx : int, directions : PackedVector3Array, is_closed : bool) -> Vector3:
	var previous_idx := _previous_segment_index(seg_idx, directions.size(), is_closed)
	return directions[previous_idx] if previous_idx >= 0 else Vector3.ZERO

func _next_tangent(seg_idx : int, directions : PackedVector3Array, is_closed : bool) -> Vector3:
	var next_idx := _next_segment_index(seg_idx, directions.size(), is_closed)
	return directions[next_idx] if next_idx >= 0 else Vector3.ZERO

func _previous_angle(seg_idx : int, directions : PackedVector3Array, is_closed : bool) -> float:
	var previous := _previous_tangent(seg_idx, directions, is_closed)
	if previous == Vector3.ZERO:
		return 0.0
	return _signed_angle_degrees(previous, directions[seg_idx])

func _next_angle(seg_idx : int, directions : PackedVector3Array, is_closed : bool) -> float:
	var next := _next_tangent(seg_idx, directions, is_closed)
	if next == Vector3.ZERO:
		return 0.0
	return _signed_angle_degrees(directions[seg_idx], next)

func _signed_angle_degrees(from_dir : Vector3, to_dir : Vector3) -> float:
	var from_norm := from_dir.normalized()
	var to_norm := to_dir.normalized()
	var sin_value := from_norm.cross(to_norm).dot(Vector3.UP)
	var cos_value := clampf(from_norm.dot(to_norm), -1.0, 1.0)
	return rad_to_deg(atan2(sin_value, cos_value))

func _is_clockwise(directions : PackedVector3Array) -> bool:
	var cumulative_angle := 0.0
	for idx in range(directions.size()):
		var next_idx := (idx + 1) % directions.size()
		cumulative_angle += _signed_angle_degrees(directions[idx], directions[next_idx])
	return cumulative_angle <= 0.0
