@tool
extends "res://addons/flow_nodes_editor/node.gd"

const SortNodeSettings = preload("res://addons/flow_nodes_editor/nodes/sort_settings.gd")

func _init():
	meta_node = {
		"title" : "Sort Attributes",
		"settings" : SortNodeSettings,
		"aliases" : ["Sort", "Sort Points", "Sort Attributes"],
		"category" : "Utility",
		"ins" : [{"label": "In" }],
		"outs" : [{ "label" : "Out" }],
		"hide_inputs" : true,
		"tooltip" : "Sorts rows by one or more attributes (Bool, Int, Float or String).\nUse commas for multiple keys, e.g. 'group, rank:desc'.",
	}

func _parse_sort_entries() -> Dictionary:
	var entries := []
	for raw_part in settings.sort_by.split(",", false):
		var token := String(raw_part).strip_edges()
		if token == "":
			continue

		var descending : bool = settings.sort_method == SortNodeSettings.eSortMethod.Descending
		if token.begins_with("-"):
			descending = true
			token = token.substr(1).strip_edges()
		elif token.begins_with("+"):
			descending = false
			token = token.substr(1).strip_edges()

		var suffix_index := token.rfind(":")
		if suffix_index != -1:
			var direction := token.substr(suffix_index + 1).strip_edges().to_lower()
			var attr_name := token.substr(0, suffix_index).strip_edges()
			if direction == "asc" or direction == "ascending":
				descending = false
				token = attr_name
			elif direction == "desc" or direction == "descending":
				descending = true
				token = attr_name
			else:
				return { "ok": false, "error": "Invalid sort direction '%s' in '%s'" % [direction, raw_part] }

		if token == "":
			return { "ok": false, "error": "Sort attribute name can't be empty" }
		entries.append({ "name": token, "descending": descending })

	if entries.is_empty():
		return { "ok": false, "error": "Sort attribute not set" }
	return { "ok": true, "entries": entries }

func _is_comparable_stream(stream : Dictionary) -> bool:
	return (
		stream.data_type == FlowData.DataType.Bool
		or stream.data_type == FlowData.DataType.Int
		or stream.data_type == FlowData.DataType.Float
		or stream.data_type == FlowData.DataType.String
	)

func _resolve_sort_entries(in_data : FlowData.Data, raw_entries : Array, num_rows : int) -> Dictionary:
	var entries := []
	for raw_entry in raw_entries:
		var attr_name := String(raw_entry.name)
		var stream = in_data.findStream(attr_name)
		if stream == null:
			return { "ok": false, "error": "Sort attribute '%s' not found" % attr_name }
		if not _is_comparable_stream(stream):
			return { "ok": false, "error": "Unsupported sort data type: %d" % stream.data_type }
		var stream_size : int = stream.container.size()
		if stream_size != num_rows and stream_size != 1:
			return {
				"ok": false,
				"error": "Sort attribute '%s' must have %d values or 1 value (got %d)" % [attr_name, num_rows, stream_size],
			}
		entries.append({
			"name": attr_name,
			"stream": stream,
			"descending": bool(raw_entry.descending),
		})
	return { "ok": true, "entries": entries }

func _compare_stream_values(stream : Dictionary, row_a : int, row_b : int) -> int:
	var container = stream.container
	var idx_a := FlowData.bcast_idx(container.size(), row_a)
	var idx_b := FlowData.bcast_idx(container.size(), row_b)
	match stream.data_type:
		FlowData.DataType.Bool:
			var a_bool := int(container[idx_a]) != 0
			var b_bool := int(container[idx_b]) != 0
			if a_bool == b_bool:
				return 0
			return 1 if a_bool else -1
		FlowData.DataType.Int:
			var a_int := int(container[idx_a])
			var b_int := int(container[idx_b])
			if a_int == b_int:
				return 0
			return -1 if a_int < b_int else 1
		FlowData.DataType.Float:
			var a_float := float(container[idx_a])
			var b_float := float(container[idx_b])
			if is_equal_approx(a_float, b_float):
				return 0
			return -1 if a_float < b_float else 1
		FlowData.DataType.String:
			var a_string := String(container[idx_a])
			var b_string := String(container[idx_b])
			if a_string == b_string:
				return 0
			return -1 if a_string < b_string else 1
	return 0

func _compare_rows(row_a : int, row_b : int, entries : Array) -> int:
	for entry in entries:
		var result := _compare_stream_values(entry.stream, row_a, row_b)
		if result != 0:
			return -result if bool(entry.descending) else result
	return 0

func _build_sorted_indices(num_rows : int, entries : Array) -> PackedInt32Array:
	var indices := []
	for idx in range(num_rows):
		indices.append(idx)
	indices.sort_custom(func(a, b):
		var result := _compare_rows(int(a), int(b), entries)
		if result != 0:
			return result < 0
		if settings.use_stable_sort:
			return int(a) < int(b)
		return false
	)

	var packed := PackedInt32Array()
	packed.resize(indices.size())
	for idx in range(indices.size()):
		packed[idx] = int(indices[idx])
	return packed

func _filtered_stream_container(stream : Dictionary, indices : PackedInt32Array):
	var out_container = FlowData.Data.newContainerOfType(stream.data_type)
	if out_container == null:
		return null
	out_container.resize(indices.size())
	for idx in range(indices.size()):
		FlowData.Data.writeValue(out_container, idx, stream.container[indices[idx]], stream.data_type)
	return out_container

func _filter_preserving_broadcast(in_data : FlowData.Data, indices : PackedInt32Array, num_rows : int) -> Dictionary:
	var out_data := FlowData.Data.new()
	for stream in in_data.streams.values():
		var stream_size : int = stream.container.size()
		var out_container
		if stream_size == 1:
			out_container = stream.container.duplicate()
		elif stream_size == num_rows:
			out_container = _filtered_stream_container(stream, indices)
			if out_container == null:
				return { "ok": false, "error": "Unsupported attribute data type: %d" % stream.data_type }
		else:
			return {
				"ok": false,
				"error": "Attribute '%s' must have %d values or 1 value (got %d)" % [stream.name, num_rows, stream_size],
			}

		var err = out_data.registerStream(str(stream.name), out_container, stream.data_type)
		if err:
			return { "ok": false, "error": err }

	out_data.tags = in_data.tags.duplicate()
	out_data.last_added_stream_name = in_data.last_added_stream_name
	return { "ok": true, "data": out_data }

func execute( ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = require_input( 0, ctx )
	if in_data == null:
		return
	var num_rows := in_data.size()
	if num_rows == 0:
		set_output(0, in_data.duplicate())
		return

	var parse_result := _parse_sort_entries()
	if not parse_result.ok:
		setError(parse_result.error)
		return

	var resolve_result := _resolve_sort_entries(in_data, parse_result.entries, num_rows)
	if not resolve_result.ok:
		setError(resolve_result.error)
		return

	var indices := _build_sorted_indices(num_rows, resolve_result.entries)
	var filter_result := _filter_preserving_broadcast(in_data, indices, num_rows)
	if not filter_result.ok:
		setError(filter_result.error)
		return

	set_output( 0, filter_result.data )
