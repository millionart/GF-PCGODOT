@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Match And Set Attributes",
		"settings" : MatchAndSetNodeSettings,
		"ins" : [{ "label" : "In" }, { "label" : "Match Data", "broadcastable" : true }],
		"outs" : [{ "label" : "Out" }],
		"aliases" : ["Match And Set"],
		"category" : "Metadata",
		"tooltip" : "Matches or randomly assigns values from the Match Data attribute set to the input data." +
					"\nWhen Match Attributes is off, each input row picks a Match Data row using $Seed and the node seed." +
					"\nWhen Match Attributes is on, Input Attribute is compared against Match Attribute; Keep Unmatched controls rows without a match." +
					"\nUse Weight Attribute explicitly enables weighted selection from Match Data."
	}

func _read_stream_value(stream : Dictionary, row_index : int):
	var container = stream.container
	return container[FlowData.bcast_idx(container.size(), row_index)]

func _stream_size_is_valid(stream : Dictionary, expected_size : int) -> bool:
	var stream_size : int = stream.container.size()
	return stream_size == expected_size or stream_size == 1

func _make_row_rng(in_data : FlowData.Data, seed_stream, row_index : int) -> RandomNumberGenerator:
	var local_rng := RandomNumberGenerator.new()
	if seed_stream != null and seed_stream.container.size() > 0:
		var seed_index := FlowData.bcast_idx(seed_stream.container.size(), row_index)
		local_rng.seed = (int(seed_stream.container[seed_index]) ^ int(settings.random_seed)) & 0x7fffffff
	else:
		local_rng.seed = int(settings.random_seed) + row_index * 19937
	return local_rng

func _collect_candidate_weights(candidate_indices : Array[int], weights : PackedFloat32Array) -> Dictionary:
	var total_weight := 0.0
	var candidate_weights : Array[float] = []
	for candidate_index in candidate_indices:
		var weight := float(weights[candidate_index])
		if weight < 0.0:
			weight = 0.0
		candidate_weights.append(weight)
		total_weight += weight
	return { "weights": candidate_weights, "total": total_weight }

func _select_weighted_entry(candidate_indices : Array[int], weights : PackedFloat32Array, local_rng : RandomNumberGenerator) -> int:
	if candidate_indices.is_empty():
		return -1
	var weight_result := _collect_candidate_weights(candidate_indices, weights)
	var total_weight : float = weight_result.total
	if total_weight <= 0.0:
		return -1
	var pick := local_rng.randf() * total_weight
	var accumulated := 0.0
	var candidate_weights : Array = weight_result.weights
	for idx in range(candidate_indices.size()):
		accumulated += float(candidate_weights[idx])
		if pick <= accumulated:
			return candidate_indices[idx]
	return candidate_indices[candidate_indices.size() - 1]

func _make_uniform_weights(num_entries : int) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(num_entries)
	for idx in range(num_entries):
		weights[idx] = 1.0
	return weights

func _resolve_weights(attrs_data : FlowData.Data, num_entries : int) -> Dictionary:
	if not settings.use_weight_attribute:
		return { "ok": true, "weights": _make_uniform_weights(num_entries) }

	var weight_attr : String = settings.weight_attr.strip_edges()
	if weight_attr == "":
		return { "ok": false, "error": "Use Weight Attribute is enabled, but Weight Attribute is empty" }

	var weight_stream = attrs_data.findStream(weight_attr)
	if weight_stream == null:
		return { "ok": false, "error": "Can't find weight attribute %s in Match Data input" % weight_attr }
	if (
		weight_stream.data_type != FlowData.DataType.Float
		and weight_stream.data_type != FlowData.DataType.Int
		and weight_stream.data_type != FlowData.DataType.Bool
	):
		return { "ok": false, "error": "Weight Attribute %s must be numeric or bool" % weight_attr }
	if not _stream_size_is_valid(weight_stream, num_entries):
		return { "ok": false, "error": "Weight Attribute %s must have %d values or 1 value" % [weight_attr, num_entries] }

	var weights := PackedFloat32Array()
	weights.resize(num_entries)
	for idx in range(num_entries):
		weights[idx] = float(_read_stream_value(weight_stream, idx))
	return { "ok": true, "weights": weights }

func _build_match_lut(in_data : FlowData.Data, attrs_data : FlowData.Data, num_entries : int) -> Dictionary:
	var input_attribute : String = settings.input_attribute.strip_edges()
	var match_attr : String = settings.match_attr.strip_edges()
	if input_attribute == "":
		return { "ok": false, "error": "Input Attribute can't be empty when Match Attributes is enabled" }
	if match_attr == "":
		return { "ok": false, "error": "Match Attribute can't be empty when Match Attributes is enabled" }

	var input_stream = in_data.findStream(input_attribute)
	if input_stream == null:
		return { "ok": false, "error": "Can't find Input Attribute %s in In input" % input_attribute }
	var match_stream = attrs_data.findStream(match_attr)
	if match_stream == null:
		return { "ok": false, "error": "Can't find Match Attribute %s in Match Data input" % match_attr }
	if input_stream.data_type != match_stream.data_type:
		return { "ok": false, "error": "Input Attribute and Match Attribute must have the same type" }
	if not _stream_size_is_valid(input_stream, in_data.size()):
		return { "ok": false, "error": "Input Attribute %s must have %d values or 1 value" % [input_attribute, in_data.size()] }
	if not _stream_size_is_valid(match_stream, num_entries):
		return { "ok": false, "error": "Match Attribute %s must have %d values or 1 value" % [match_attr, num_entries] }

	var lut := {}
	for idx in range(num_entries):
		var value_key := var_to_str(_read_stream_value(match_stream, idx))
		if not lut.has(value_key):
			var empty_candidates : Array[int] = []
			lut[value_key] = empty_candidates
		lut[value_key].append(idx)

	return { "ok": true, "lut": lut, "input_stream": input_stream }

func _should_copy_match_stream(stream_name : String) -> bool:
	if settings.match_attributes and stream_name == settings.match_attr.strip_edges():
		return false
	if settings.use_weight_attribute and stream_name == settings.weight_attr.strip_edges():
		return false
	return true

func _copy_match_streams(
	in_data : FlowData.Data,
	attrs_data : FlowData.Data,
	out_data : FlowData.Data,
	output_indices : PackedInt32Array,
	selected_entries : PackedInt32Array
) -> Dictionary:
	for attr_stream in attrs_data.streams.values():
		var stream_name := str(attr_stream.name)
		if not _should_copy_match_stream(stream_name):
			continue
		if not _stream_size_is_valid(attr_stream, attrs_data.size()):
			return { "ok": false, "error": "Match Data stream %s must have %d values or 1 value" % [stream_name, attrs_data.size()] }

		var new_container = FlowData.Data.newContainerOfType(attr_stream.data_type)
		if new_container == null:
			return { "ok": false, "error": "Unsupported Match Data stream type %d" % attr_stream.data_type }
		new_container.resize(output_indices.size())
		var existing_stream = in_data.findStream(stream_name)

		for out_idx in range(output_indices.size()):
			var selected_entry : int = selected_entries[out_idx]
			if selected_entry >= 0:
				FlowData.Data.writeValue(new_container, out_idx, _read_stream_value(attr_stream, selected_entry), attr_stream.data_type)
			elif existing_stream != null and existing_stream.data_type == attr_stream.data_type and _stream_size_is_valid(existing_stream, in_data.size()):
				FlowData.Data.writeValue(new_container, out_idx, _read_stream_value(existing_stream, output_indices[out_idx]), attr_stream.data_type)

		var err = out_data.registerStream(stream_name, new_container, attr_stream.data_type)
		if err:
			return { "ok": false, "error": err }
	return { "ok": true }

func execute( ctx : FlowData.EvaluationContext ):
	var in_data : FlowData.Data = require_input(0, ctx, "Input 'In'")
	if in_data == null:
		return
	var raw_attrs = get_optional_input(1)
	if not raw_attrs is FlowData.Data:
		setError("Input 'Match Data' not connected")
		set_output(0, in_data.duplicate())
		return
	var attrs_data : FlowData.Data = raw_attrs

	var seed_stream = in_data.streams.get(FlowData.AttrSeed, null)
	var num_entries := attrs_data.size()
	var weight_result := _resolve_weights(attrs_data, num_entries)
	if not weight_result.ok:
		setError(weight_result.error)
		return
	var weights : PackedFloat32Array = weight_result.weights

	var match_lut := {}
	var input_match_stream = null
	if settings.match_attributes:
		var lut_result := _build_match_lut(in_data, attrs_data, num_entries)
		if not lut_result.ok:
			setError(lut_result.error)
			return
		match_lut = lut_result.lut
		input_match_stream = lut_result.input_stream

	var output_indices := PackedInt32Array()
	var selected_entries := PackedInt32Array()
	for idx in range(in_data.size()):
		var local_rng := _make_row_rng(in_data, seed_stream, idx)
		var candidates : Array[int] = []
		if settings.match_attributes:
			var value_key := var_to_str(_read_stream_value(input_match_stream, idx))
			if match_lut.has(value_key):
				candidates = match_lut[value_key]
		else:
			for entry_idx in range(num_entries):
				candidates.append(entry_idx)

		var selected_entry := _select_weighted_entry(candidates, weights, local_rng)
		if selected_entry >= 0 or settings.keep_unmatched:
			output_indices.append(idx)
			selected_entries.append(selected_entry)

	var out_data := in_data.filter(output_indices)
	var copy_result := _copy_match_streams(in_data, attrs_data, out_data, output_indices, selected_entries)
	if not copy_result.ok:
		setError(copy_result.error)
		return
	set_output(0, out_data)
