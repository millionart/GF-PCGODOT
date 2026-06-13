@tool
extends FlowNodeBase

const DecomposeVectorNodeSettings = preload("res://addons/flow_nodes_editor/nodes/decompose_vector_settings.gd")

func _init():
	meta_node = {
		"title" : "Break Vector Attribute",
		"settings" : DecomposeVectorNodeSettings,
		"ins" : [{ "label": "In" }], 
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Breaks a vector or color attribute into component float attributes.",
		"aliases" : ["Decompose Vector"],
		"category" : "Metadata",
	}

func execute( ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = get_input(0)
	if in_data == null:
		if ctx.owner == null and Engine.is_editor_hint():
			set_output(0, FlowData.Data.new())
			return
		setError("Input 'In' is not connected")
		return
		
	var out_data : FlowData.Data = in_data.duplicate()
	var size = in_data.size()
	
	var s_in = in_data.findStream(settings.in_attribute)
	if s_in == null:
		if ctx.owner == null and Engine.is_editor_hint():
			set_output(0, FlowData.Data.new())
			return
		setError("Input attribute %s not found" % settings.in_attribute)
		return
		
	if s_in.data_type != FlowData.DataType.Vector and s_in.data_type != FlowData.DataType.Color:
		setError("Input attribute %s is not a Vector or Color" % settings.in_attribute)
		return
	var stream_size : int = s_in.container.size()
	if stream_size != size and stream_size != 1:
		setError("Input attribute %s must have %d values or 1 broadcast value (got %d)" % [settings.in_attribute, size, stream_size])
		return
	
	var out_x := PackedFloat32Array()
	var out_y := PackedFloat32Array()
	var out_z := PackedFloat32Array()
	var out_w := PackedFloat32Array()
	
	out_x.resize(size)
	out_y.resize(size)
	out_z.resize(size)
	out_w.resize(size)
	
	if s_in.data_type == FlowData.DataType.Color:
		var in_colors : PackedColorArray = s_in.container
		for i in range(size):
			var color : Color = in_colors[FlowData.bcast_idx(stream_size, i)]
			out_x[i] = color.r
			out_y[i] = color.g
			out_z[i] = color.b
			out_w[i] = color.a
	else:
		var in_vecs : PackedVector3Array = s_in.container
		for i in range(size):
			var v : Vector3 = in_vecs[FlowData.bcast_idx(stream_size, i)]
			out_x[i] = v.x
			out_y[i] = v.y
			out_z[i] = v.z
			out_w[i] = 0.0
		
	if settings.x_attribute != "":
		out_data.registerStream(settings.x_attribute, out_x, FlowData.DataType.Float)
	if settings.y_attribute != "":
		out_data.registerStream(settings.y_attribute, out_y, FlowData.DataType.Float)
	if settings.z_attribute != "":
		out_data.registerStream(settings.z_attribute, out_z, FlowData.DataType.Float)
	if settings.w_attribute != "":
		out_data.registerStream(settings.w_attribute, out_w, FlowData.DataType.Float)
		
	set_output(0, out_data)
