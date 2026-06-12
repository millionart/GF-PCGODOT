@tool
extends FlowNodeBase

const CreateConstantNodeSettings = preload("res://addons/flow_nodes_editor/nodes/create_constant_settings.gd")

func _init():
	meta_node = {
		"title" : "Create Constant",
		"settings" : CreateConstantNodeSettings,
		"ins" : [],
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Outputs an attribute set containing one constant value.",
		"aliases" : ["Create Attribute"],
		"category" : "Metadata",
	}

func getTitle() -> String:
	return "%s - %s" % [ settings.output_target, FlowData.DataType.keys()[settings.data_type] ]

func exposedAsInputNode( prop ):
	if prop.name.begins_with( "cte_" ):
		var name_lc = FlowData.DataType.keys()[ settings.data_type ].to_lower()
		return prop.name == "cte_" + name_lc
	return false

func onPropChanged( prop_name : String ):
	super.onPropChanged( prop_name )
	if prop_name == "data_type":
		initFromScript()

func execute( ctx : FlowData.EvaluationContext ):
	if settings.output_target.strip_edges() == "":
		setError( "Attribute name can't be empty" )
		return

	var out_data := FlowData.Data.new()
	var container = _make_constant_container(ctx)
	if container == null:
		return

	var err = out_data.registerStream( settings.output_target, container, settings.data_type )
	if err:
		setError( err )
		return
	set_output( 0, out_data )

func _make_constant_container(ctx : FlowData.EvaluationContext):
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
			setError( "Data type %s is not supported by Create Constant" % FlowData.DataType.keys()[settings.data_type] )
			return null

	var container = FlowData.Data.newContainerOfType( settings.data_type )
	if container == null:
		setError( "Failed to create a container of type %s" % FlowData.DataType.keys()[settings.data_type] )
		return null
	container.resize( 1 )
	container.fill( new_val )
	return container
