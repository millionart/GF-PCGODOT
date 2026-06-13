@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Attribute Curve Remap",
		"settings" : RemapNodeSettings,
		"ins" : [{ "label" : "In" }],
		"outs" : [{ "label" : "Out" }],
		"category" : "Metadata",
		"tooltip" : "Remaps numeric, vector, or color attributes component-wise using a curve.\nSet Out Name to '@in_name' to overwrite the source attribute in place.",
		"aliases" : ["Remap"],
	}

func _sample_curve(curve : Curve, value : float) -> float:
	if curve == null:
		return value
	return curve.sample(value)

func execute( _ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = require_input(0, _ctx)
	if in_data == null:
		return

	var sA = in_data.findStream( settings.in_name )
	if sA == null:
		setError( "Input %s not found" % [settings.in_name])
		return
		
	var out_name = settings.out_name
	if out_name == "@in_name":
		out_name = sA.name
		
	var out_data : FlowData.Data = in_data.duplicate()
	var in_container = sA.container
		
	var c : Curve = settings.remap_curve
	var in_size := in_data.size()
	var stream_size : int = in_container.size()
	if stream_size != in_size and stream_size != 1:
		setError( "Input stream %s must have %d values or 1 value (got %d)" % [settings.in_name, in_size, stream_size] )
		return
	var out_container
	match sA.data_type:
		FlowData.DataType.Float:
			out_container = PackedFloat32Array()
			out_container.resize( in_size )
			for idx in in_size:
				out_container[idx] = _sample_curve(c, in_container[FlowData.bcast_idx(stream_size, idx)])
		FlowData.DataType.Int:
			out_container = PackedInt32Array()
			out_container.resize( in_size )
			for idx in in_size:
				out_container[idx] = int(_sample_curve(c, float(in_container[FlowData.bcast_idx(stream_size, idx)])))
		FlowData.DataType.Vector:
			out_container = PackedVector3Array()
			out_container.resize( in_size )
			for idx in in_size:
				var v : Vector3 = in_container[FlowData.bcast_idx(stream_size, idx)]
				out_container[idx] = Vector3(
					_sample_curve(c, v.x),
					_sample_curve(c, v.y),
					_sample_curve(c, v.z)
				)
		FlowData.DataType.Color:
			out_container = PackedColorArray()
			out_container.resize( in_size )
			for idx in in_size:
				var color : Color = in_container[FlowData.bcast_idx(stream_size, idx)]
				out_container[idx] = Color(
					_sample_curve(c, color.r),
					_sample_curve(c, color.g),
					_sample_curve(c, color.b),
					_sample_curve(c, color.a)
				)
		_:
			setError( "Input stream %s should be numeric, vector, or color" % [settings.in_name])
			return
	var err = out_data.registerStream( out_name, out_container, sA.data_type )
	if err:
		setError(err)
		return
	
	set_output( 0, out_data )
