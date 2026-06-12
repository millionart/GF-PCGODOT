@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Create Spline",
		"settings" : CreateSplineNodeSettings,
		"ins" : [{ "label": "In" }],
		"outs" : [{ "label" : "Splines", "data_type": FlowData.DataType.NodePath }],
		"tooltip" : "Creates PCG spline data from input points in sequential order.",
		"aliases" : ["Create Spline"],
		"category" : "Spatial",
	}

func removeInstancedNodes( root : Node ):
	var nodes : Array[Node] = []
	for child in root.get_children():
		if !child.has_meta( "flow_owner" ):
			continue
		if child.get_meta( "flow_owner" ) == name:
			nodes.append( child )
	for node in nodes:
		node.queue_free()

func execute( ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = require_input(0, ctx)
	if in_data == null:
		return

	var positions = in_data.getContainerChecked( FlowData.AttrPosition, FlowData.DataType.Vector )
	if positions == null:
		setError( "Invalid input. Missing required attribute %s" % FlowData.AttrPosition )
		return

	var path := _create_path_from_points( in_data, positions )
	if path == null:
		return

	if settings.mode == CreateSplineNodeSettings.eMode.CreateComponent:
		if not _attach_path_to_owner( path, ctx ):
			return
	else:
		_remove_previous_component( ctx )

	var output := FlowData.Data.new()
	output.registerStream( "node", [path], FlowData.DataType.NodePath )
	output.registerStream( "curve", [path.curve], FlowData.DataType.Resource )
	set_output( 0, output )

func _attach_path_to_owner( path : Path3D, ctx : FlowData.EvaluationContext ) -> bool:
	var root = ctx.owner
	if root == null or root.get_tree() == null:
		if Engine.is_editor_hint():
			set_output( 0, FlowData.Data.new() )
			return false
		setError( "Create Spline needs a scene owner to spawn the Path3D under" )
		return false

	removeInstancedNodes( root )

	var scene_root = root.get_tree().current_scene
	var owner_of_spawned_nodes : Node = scene_root if scene_root else root

	root.add_child( path )
	path.owner = owner_of_spawned_nodes
	return true

func _remove_previous_component( ctx : FlowData.EvaluationContext ) -> void:
	var root = ctx.owner
	if root != null and root.get_tree() != null:
		removeInstancedNodes( root )

func _create_path_from_points( in_data : FlowData.Data, positions : PackedVector3Array ) -> Path3D:
	var path := Path3D.new()
	path.name = settings.node_name.strip_edges()
	if path.name == "":
		path.name = "Spline"
	path.set_meta( "flow_owner", name )
	path.set_meta( "pcg_create_spline_mode", settings.mode )
	path.set_meta( "closed_loop", settings.closed_loop )
	path.set_meta( "linear", settings.linear )
	path.curve = Curve3D.new()

	var num_points : int = positions.size()
	var needs_custom_tangents : bool = settings.apply_custom_tangents == true and settings.linear != true
	var arrive_tangents = _optional_vector_stream( in_data, settings.arrive_tangent_attribute, needs_custom_tangents )
	if arrive_tangents == null and needs_custom_tangents:
		return null
	var leave_tangents = _optional_vector_stream( in_data, settings.leave_tangent_attribute, needs_custom_tangents )
	if leave_tangents == null and needs_custom_tangents:
		return null
	var interp_types = _optional_int_stream( in_data, settings.interp_type_attribute, settings.use_interp_type_attribute )
	if interp_types == null and settings.use_interp_type_attribute:
		return null
	if arrive_tangents != null and not _validate_stream_size( arrive_tangents, num_points, settings.arrive_tangent_attribute ):
		return null
	if leave_tangents != null and not _validate_stream_size( leave_tangents, num_points, settings.leave_tangent_attribute ):
		return null
	if interp_types != null and not _validate_stream_size( interp_types, num_points, settings.interp_type_attribute ):
		return null

	for idx in range( num_points ):
		_add_curve_point( path.curve, positions, idx, arrive_tangents, leave_tangents, interp_types )

	if settings.closed_loop and num_points > 1:
		_add_curve_point( path.curve, positions, 0, arrive_tangents, leave_tangents, interp_types )

	return path

func _add_curve_point(
	curve : Curve3D,
	positions : PackedVector3Array,
	idx : int,
	arrive_tangents,
	leave_tangents,
	interp_types
) -> void:
	var pos : Vector3 = positions[idx]
	var in_tan : Vector3 = Vector3.ZERO
	var out_tan : Vector3 = Vector3.ZERO
	var point_type : int = _point_type_at( interp_types, idx )
	var use_custom : bool = point_type == CreateSplineNodeSettings.INTERP_TYPE_CURVE_CUSTOM_TANGENT
	var use_linear : bool = settings.linear == true or point_type == CreateSplineNodeSettings.INTERP_TYPE_LINEAR

	if settings.apply_custom_tangents and not settings.linear and use_custom:
		in_tan = _vector_stream_value( arrive_tangents, idx )
		out_tan = _vector_stream_value( leave_tangents, idx )
	elif not use_linear:
		var num_points : int = positions.size()
		if settings.closed_loop and num_points > 2:
			var prev_idx := (idx - 1 + num_points) % num_points
			var next_idx := (idx + 1) % num_points
			var dir : Vector3 = positions[next_idx] - positions[prev_idx]
			var ndir : Vector3 = dir.normalized() * 0.5
			in_tan = -ndir
			out_tan = ndir
		elif idx > 0 and idx < num_points - 1:
			var dir : Vector3 = positions[idx + 1] - positions[idx - 1]
			var ndir : Vector3 = dir.normalized() * 0.5
			in_tan = -ndir
			out_tan = ndir

	curve.add_point( pos, in_tan, out_tan )

func _optional_vector_stream(in_data : FlowData.Data, stream_name : String, required : bool):
	if stream_name.strip_edges() == "":
		if required:
			setError( "Vector attribute name can't be empty" )
		return null
	var stream = in_data.findStream( stream_name )
	if stream == null:
		if required:
			setError( "Input does not contain vector attribute '%s'" % stream_name )
		return null
	if stream.data_type != FlowData.DataType.Vector:
		if required:
			setError( "Attribute '%s' must be a Vector" % stream_name )
		return null
	return stream

func _optional_int_stream(in_data : FlowData.Data, stream_name : String, required : bool):
	if stream_name.strip_edges() == "":
		if required:
			setError( "Interp type attribute name can't be empty" )
		return null
	var stream = in_data.findStream( stream_name )
	if stream == null:
		if required:
			setError( "Input does not contain int attribute '%s'" % stream_name )
		return null
	if stream.data_type != FlowData.DataType.Int:
		if required:
			setError( "Attribute '%s' must be an Int" % stream_name )
		return null
	return stream

func _validate_stream_size( stream, num_points : int, stream_name : String ) -> bool:
	var stream_size : int = stream.container.size()
	if stream_size == 1 or stream_size == num_points:
		return true
	setError( "Attribute '%s' has %d values; expected 1 or %d" % [stream_name, stream_size, num_points] )
	return false

func _vector_stream_value(stream, idx : int) -> Vector3:
	var container = stream.container
	return container[FlowData.bcast_idx( container.size(), idx )]

func _point_type_at(stream, idx : int) -> int:
	if stream == null:
		if settings.linear:
			return CreateSplineNodeSettings.INTERP_TYPE_LINEAR
		if settings.apply_custom_tangents:
			return CreateSplineNodeSettings.INTERP_TYPE_CURVE_CUSTOM_TANGENT
		return CreateSplineNodeSettings.INTERP_TYPE_CURVE
	var container = stream.container
	return int(container[FlowData.bcast_idx( container.size(), idx )])
