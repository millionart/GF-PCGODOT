@tool
extends FlowNodeBase

const GetAttributeFromPointIndexNodeSettings = preload("res://addons/flow_nodes_editor/nodes/get_attribute_from_point_index_settings.gd")

func _init():
	meta_node = {
		"title" : "Get Attribute From Point Index",
		"settings" : GetAttributeFromPointIndexNodeSettings,
		"ins" : [{ "label": "In" }],
		"outs" : [{ "label" : "Attribute" }, { "label" : "Point" }],
		"aliases" : ["Get Attribute From Point Index", "Extract Attribute at Index"],
		"category" : "Metadata",
		"tooltip" : "Extracts one attribute value from a point index into a single-row attribute set, and outputs the selected point.\nUse @source or an empty output name to keep the source attribute name.",
	}

func _resolve_read_index(stream : Dictionary, point_index : int, point_count : int, source_name : String) -> Dictionary:
	var stream_size : int = stream.container.size()
	if stream_size == point_count:
		return { "ok": true, "index": point_index }
	if stream_size == 1:
		return { "ok": true, "index": 0 }
	if stream_size == 0:
		return { "ok": false, "error": "Attribute '%s' has no values" % source_name }
	return {
		"ok": false,
		"error": "Attribute '%s' must have %d values or 1 value (got %d)" % [source_name, point_count, stream_size],
	}

func _resolve_output_attribute_name(source_name : String, stream : Dictionary) -> String:
	var output_name : String = settings.output_attribute_name.strip_edges()
	if output_name == "" or output_name.to_lower() == "@source":
		output_name = str(stream.get("name", source_name)).strip_edges()
	if "." in output_name:
		output_name = output_name.replace(".", "_")
	return output_name

func _single_value_container(stream : Dictionary, read_index : int) -> Dictionary:
	var container = FlowData.Data.newContainerOfType(stream.data_type)
	if container == null:
		return { "ok": false, "error": "Unsupported attribute data type %d" % stream.data_type }
	container.resize(1)
	FlowData.Data.writeValue(container, 0, stream.container[read_index], stream.data_type)
	return { "ok": true, "container": container }

func _copy_selected_point(in_data : FlowData.Data, point_index : int, point_count : int) -> Dictionary:
	var out_data := FlowData.Data.new()
	for stream in in_data.streams.values():
		var read_result := _resolve_read_index(stream, point_index, point_count, str(stream.name))
		if not read_result.ok:
			return read_result

		var value_result := _single_value_container(stream, read_result.index)
		if not value_result.ok:
			return value_result

		var err = out_data.registerStream(str(stream.name), value_result.container, stream.data_type)
		if err:
			return { "ok": false, "error": err }

	out_data.tags = in_data.tags.duplicate()
	out_data.last_added_stream_name = in_data.last_added_stream_name
	return { "ok": true, "data": out_data }

func execute(ctx : FlowData.EvaluationContext):
	var in_data : FlowData.Data = require_input(0, ctx, "Input 'In'")
	if in_data == null:
		return

	var point_count := in_data.size()
	var point_index : int = settings.point_index
	if point_index < 0 or point_index >= point_count:
		setError("Point index %d is out of range (0..%d)" % [point_index, point_count - 1])
		return

	var source_name : String = settings.input_attribute_name.strip_edges()
	if source_name == "":
		setError("Input attribute name can't be empty")
		return

	var stream = in_data.findStream(source_name)
	if stream == null:
		setError("Input attribute '%s' not found" % source_name)
		return

	var read_result := _resolve_read_index(stream, point_index, point_count, source_name)
	if not read_result.ok:
		setError(read_result.error)
		return

	var output_name := _resolve_output_attribute_name(source_name, stream)
	if output_name == "":
		setError("Output attribute name can't be empty")
		return

	var value_result := _single_value_container(stream, read_result.index)
	if not value_result.ok:
		setError(value_result.error)
		return

	var attribute_data := FlowData.Data.new()
	var err = attribute_data.registerStream(output_name, value_result.container, stream.data_type)
	if err:
		setError(err)
		return

	var point_result := _copy_selected_point(in_data, point_index, point_count)
	if not point_result.ok:
		setError(point_result.error)
		return

	set_output(0, attribute_data)
	set_output(1, point_result.data)
