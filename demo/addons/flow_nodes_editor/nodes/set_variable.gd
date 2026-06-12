@tool
extends FlowNodeBase

const SetVariableNodeSettings = preload("res://addons/flow_nodes_editor/nodes/set_variable_settings.gd")

func _init():
	meta_node = {
		"title" : "Set Variable",
		"settings" : SetVariableNodeSettings,
		"ins" : [{ "label" : "In", "data_type" : FlowData.DataType.Invalid, "multiple_connections" : false }],
		"outs" : [{ "label" : "Out", "data_type" : FlowData.DataType.Invalid }],
		"tooltip" : "Stores the input data in a named graph variable and passes it through unchanged.",
		"category" : "Metadata",
		"aliases" : ["variable", "set"],
	}

func _variable_name() -> String:
	if not settings or not ("variable_name" in settings):
		return ""
	return String(settings.variable_name).strip_edges()

func _get_custom_node_color() -> Color:
	if settings and "node_color" in settings:
		return settings.node_color
	return Color("22d3ee")

func getTitle() -> String:
	var variable_name := _variable_name()
	if variable_name.is_empty():
		return "Set Variable"
	return "Set: %s" % variable_name

func getExposedParams():
	return []

func getVariableDataType() -> FlowData.DataType:
	var data_type := _get_connected_input_data_type()
	if data_type != FlowData.DataType.Invalid:
		return data_type
	return _get_generated_data_type()

func refreshFromSettings():
	super.refreshFromSettings()
	title = getTitle()
	refreshVariablePinColors()

func refreshVariablePinColors() -> void:
	var data_type := getVariableDataType()
	var color := Color.WHITE
	if data_type != FlowData.DataType.Invalid:
		color = getColorForFlowDataType(data_type)
	if is_slot_enabled_left(0):
		set_slot_color_left(0, color)
		set_slot_type_left(0, FlowData.DataType.Invalid)
	if is_slot_enabled_right(0):
		set_slot_color_right(0, color)
		set_slot_type_right(0, FlowData.DataType.Invalid)

func _get_connected_input_data_type() -> FlowData.DataType:
	var editor = getEditor()
	if editor == null or not editor.has_method("get_connected_sources"):
		return FlowData.DataType.Invalid
	var sources: Array = editor.get_connected_sources(name, 0)
	for source in sources:
		if source.size() < 2:
			continue
		var source_node = editor.gedit_nodes_by_name.get(source[0]) as FlowNodeBase
		if source_node == null:
			continue
		var data_type := _get_explicit_source_port_data_type(source_node, int(source[1]))
		if data_type != FlowData.DataType.Invalid:
			return data_type
		if source_node.has_method("getVariableDataType"):
			data_type = int(source_node.call("getVariableDataType"))
			if data_type != FlowData.DataType.Invalid:
				return data_type
	return FlowData.DataType.Invalid

func _get_explicit_source_port_data_type(source_node: FlowNodeBase, source_port: int) -> FlowData.DataType:
	var source_meta: Dictionary = source_node.getMeta()
	var output_ports: Array = source_meta.get("outs", [])
	if source_port < 0 or source_port >= output_ports.size():
		return FlowData.DataType.Invalid
	var output_port = output_ports[source_port]
	if not (output_port is Dictionary) or not output_port.has("data_type"):
		return FlowData.DataType.Invalid
	return int(output_port.get("data_type", FlowData.DataType.Invalid))

func _get_generated_data_type() -> FlowData.DataType:
	for bulk_idx in range(generated_bulks.size() - 1, -1, -1):
		var bulk: Array = generated_bulks[bulk_idx]
		if bulk.is_empty():
			continue
		var data := bulk[0] as FlowData.Data
		var data_type := _get_first_stream_data_type(data)
		if data_type != FlowData.DataType.Invalid:
			return data_type
	var in_data := get_optional_input(0) as FlowData.Data
	return _get_first_stream_data_type(in_data)

func _get_first_stream_data_type(data: FlowData.Data) -> FlowData.DataType:
	if data == null or data.streams.is_empty():
		return FlowData.DataType.Invalid
	var stream = data.streams[data.streams.keys()[0]]
	return int(stream.get("data_type", FlowData.DataType.Invalid))

func execute(ctx : FlowData.EvaluationContext):
	var in_data : FlowData.Data = get_optional_input(0)
	if in_data == null:
		in_data = FlowData.Data.new()
	var variable_name := _variable_name()
	if variable_name.is_empty():
		setError("Variable name can't be empty")
		set_output(0, in_data)
		refreshVariablePinColors()
		return
	ctx.variables[variable_name] = in_data
	set_output(0, in_data)
	refreshVariablePinColors()
