@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Add Attribute",
		"settings" : AddAttributeNodeSettings,
		"ins" : [{ "label": "In" }],
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Adds a constant attribute to the input data, or copies attributes from the optional Attributes pin.",
		"aliases" : ["Add Attribute"],
		"category" : "Metadata",
	}
	
func getTitle() -> String:
	return "%s - %s" % [ settings.output_target, FlowData.DataType.keys()[settings.data_type] ]

func exposedAsInputNode( prop ):
	if prop.name == "attributes":
		return true
	if prop.name.begins_with( "cte_" ):
		var name_lc = FlowData.DataType.keys()[ settings.data_type ].to_lower()
		return prop.name == "cte_" + name_lc
	return false

func onPropChanged( prop_name : String ):
	super.onPropChanged( prop_name )
	if prop_name == "data_type":
		initFromScript()

func execute( ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = require_input(0, ctx)
	if in_data == null:
		return

	var attributes_data : FlowData.Data = _get_attributes_input()
	if attributes_data != null:
		_copy_from_attributes_pin(in_data, attributes_data)
		return

	if settings.output_target.strip_edges() == "":
		setError( "Attribute name can't be empty" )
		return

	var out_data : FlowData.Data = in_data.duplicate()
	var out_size = maxi(_data_entry_count(in_data), 1)
	var container = _make_constant_container(ctx, out_size)
	if container == null:
		return

	var err = out_data.registerStream( settings.output_target, container, settings.data_type )
	if err:
		setError( err )
		return
	set_output( 0, out_data )

func _get_attributes_input() -> FlowData.Data:
	if args_ports_by_name.has("attributes"):
		var port = int(args_ports_by_name["attributes"].port)
		return get_optional_input(port)
	if inputs.size() > 2:
		return get_optional_input(2)
	return null

func _make_constant_container(ctx : FlowData.EvaluationContext, out_size : int):
	var new_val
	match settings.data_type:
		FlowData.DataType.Bool:
			new_val = 1 if getSettingValue( ctx, "cte_bool") else 0
		FlowData.DataType.Int:
			new_val = getSettingValue( ctx, "cte_int" )
		FlowData.DataType.Float:
			new_val = getSettingValue( ctx, "cte_float" )
		FlowData.DataType.Vector:
			new_val = getSettingValue( ctx, "cte_vector" )
		FlowData.DataType.Color:
			new_val = getSettingValue( ctx, "cte_color" )
		FlowData.DataType.String:
			new_val = getSettingValue( ctx, "cte_string" )
		FlowData.DataType.Resource:
			new_val = getSettingValue( ctx, "cte_resource" )
		_:
			setError( "Data type %s is not supported by Add Attribute" % FlowData.DataType.keys()[settings.data_type] )
			return

	var container = FlowData.Data.newContainerOfType( settings.data_type )
	if container == null:
		setError( "Failed to create a container of type %s" % FlowData.DataType.keys()[settings.data_type] )
		return null
	container.resize( out_size )
	container.fill( new_val )
	return container

func _copy_from_attributes_pin(in_data : FlowData.Data, attributes_data : FlowData.Data) -> void:
	var out_data : FlowData.Data = in_data.duplicate()
	if settings.copy_all_attributes:
		for source_stream in attributes_data.streams.values():
			if not _copy_stream_to_output(source_stream, str(source_stream.name), out_data):
				return
		set_output(0, out_data)
		return

	var input_source : String = settings.input_source.strip_edges()
	if input_source == "":
		setError("Input Source can't be empty")
		return

	var source_stream = attributes_data.findStream(input_source)
	if source_stream == null:
		setError("Attributes input does not contain attribute '%s'" % input_source)
		return

	var output_target : String = settings.output_target.strip_edges()
	if output_target == "" or output_target.to_lower() == "@source":
		output_target = str(source_stream.name)

	if not _copy_stream_to_output(source_stream, output_target, out_data):
		return
	set_output(0, out_data)

func _copy_stream_to_output(source_stream : Dictionary, output_target : String, out_data : FlowData.Data) -> bool:
	if output_target.strip_edges() == "":
		setError("Output Target can't be empty")
		return false
	var source_size : int = source_stream.container.size()
	if source_size == 0:
		setError("Source attribute '%s' has no values" % source_stream.name)
		return false

	var target_size = _data_entry_count(out_data)
	if target_size == 0:
		target_size = source_size
	target_size = maxi(target_size, 1)
	var container = FlowData.Data.newContainerOfType(source_stream.data_type)
	if container == null:
		setError("Failed to create a container of type %s" % FlowData.DataType.keys()[source_stream.data_type])
		return false
	container.resize(target_size)
	for idx in range(target_size):
		FlowData.Data.writeValue(container, idx, source_stream.container[idx % source_size], source_stream.data_type)

	var err = out_data.registerStream(output_target, container, source_stream.data_type)
	if err:
		setError( err )
		return false
	_copy_stream_metadata(source_stream, out_data, output_target)
	return true

func _data_entry_count(data : FlowData.Data) -> int:
	var max_size := 0
	for stream in data.streams.values():
		max_size = maxi(max_size, stream.container.size())
	return max_size

func _copy_stream_metadata(source_stream : Dictionary, target_data : FlowData.Data, stream_name : String) -> void:
	var target_name = target_data.translateStreamName(stream_name)
	if "." in target_name or not target_data.streams.has(target_name):
		return
	var target_stream : Dictionary = target_data.streams[target_name]
	for key in source_stream.keys():
		if key == "container" or key == "name" or key == "data_type":
			continue
		target_stream[key] = source_stream[key]
