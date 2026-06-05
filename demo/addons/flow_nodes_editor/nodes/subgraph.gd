@tool
extends FlowNodeBase

var _last_input_data_map: Dictionary = {}
var _debug_full_eval_queued: bool = false
var _debug_full_eval_running: bool = false

func _init():
	meta_node = {
		"title" : "Subgraph",
		"settings" : SubgraphNodeSettings,
		"ins" : [],
		"outs" : [],
		"is_final" : true,
		"tooltip" : "Evaluates a nested graph inside this node",
	}

func _exit_tree():
	super._exit_tree()
	disconnectGraphParameterSignal(_on_graph_params_changed)

func _on_graph_params_changed():
	refreshFromParameterSignal()

func getMeta() -> Dictionary:
	var ins = []
	var outs = []
	if settings and settings.graph:
		for param in settings.graph.in_params:
			if param:
				ins.append({
					"label": param.name,
					"data_type": param.data_type
				})
		if "out_params" in settings.graph and settings.graph.out_params.size() > 0:
			for param in settings.graph.out_params:
				if param:
					outs.append({
						"label": param.name,
						"data_type": param.data_type
					})
		elif settings.graph.data and settings.graph.data.has("nodes"):
			for n_data in settings.graph.data["nodes"]:
				if n_data.get("template") == "output":
					var node_settings = n_data.get("settings", {})
					var out_name = node_settings.get("name", "out_val")
					var out_type = node_settings.get("data_type", FlowData.DataType.Float)
					outs.append({
						"label": out_name,
						"data_type": out_type
					})
	meta_node.ins = ins
	meta_node.outs = outs
	return meta_node

func getTitle() -> String:
	if settings and settings.graph:
		var path = settings.graph.resource_path
		if path != "":
			return "Subgraph (%s)" % path.get_file().get_basename()
		return "Subgraph (New Graph)"
	return "Subgraph"

func refreshFromSettings():
	super.refreshFromSettings()
	if settings:
		connectGraphParameterSignal(settings.graph, _on_graph_params_changed)
	initFromScript()

func _on_settings_changed() -> void:
	if _handle_debug_enabled_settings_change():
		return
	dirty = true
	refreshFromSettings()
	var editor = getEditor()
	if editor:
		editor.queueRegen()

func onPropChanged( prop_name : String ):
	if prop_name == "debug_enabled":
		_handle_debug_enabled_settings_change()
		return
	super.onPropChanged( prop_name )
	if prop_name == "graph":
		if settings:
			connectGraphParameterSignal(settings.graph, _on_graph_params_changed)
		initFromScript()

func execute( ctx : FlowData.EvaluationContext ):
	if not settings.graph:
		setError("No graph assigned to Subgraph node '%s'" % getTitle())
		return
		
	var input_data_map = {}
	_last_input_data_map = {}
	if settings.graph:
		for i in range(settings.graph.in_params.size()):
			var param = settings.graph.in_params[i]
			if param:
				var in_data = get_optional_input(i)
				if in_data:
					# Priority 1: Connected wire
					input_data_map[param.name] = in_data
					_last_input_data_map[param.name] = in_data
				elif settings.has_param_override(param.name):
					# Priority 2: Per-instance override
					var override_val = settings.get_param_value(param)
					var override_data = FlowData.Data.new()
					var container = override_data.addStream(param.name, param.data_type)
					if container != null:
						container.resize(1)
						FlowData.Data.writeValue(container, 0, override_val, param.data_type)
					input_data_map[param.name] = override_data
					_last_input_data_map[param.name] = override_data
				# Priority 3: Graph default (handled by the evaluator's input node)
	
	var FlowNodeIOClass = load("res://addons/flow_nodes_editor/flow_nodes_io.gd")
	var child_depth := int(ctx.runtime_params.get("__eval_depth", 0)) + 1
	var debug_meta := _push_child_debug_input_meta(ctx, input_data_map)
	var outputs = FlowNodeIOClass.evaluate_graph(
		settings.graph,
		input_data_map,
		ctx,
		_child_runtime_params(),
		child_depth
	)
	_pop_child_debug_input_meta(debug_meta)
	
	var meta = getMeta()
	var missing_outputs := PackedStringArray()
	for i in range(meta.outs.size()):
		var out_info = meta.outs[i]
		var out_name = out_info.label
		var out_data = outputs.get(out_name, null)
		if out_data:
			set_output(i, out_data)
		else:
			set_output(i, FlowData.Data.new())
			missing_outputs.append(out_name)
	if missing_outputs.size() > 0:
		setError("Missing outputs: %s" % ", ".join(missing_outputs))

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		var editor = getEditor()
		if editor and settings and settings.graph:
			var owner = editor.resource_owner
			if owner:
				var debug_inputs := _debug_input_data_map()
				owner.set_meta("flow_debug_graph", settings.graph)
				owner.set_meta("flow_debug_input_data_map", debug_inputs)
			editor.setResourceToEdit(settings.graph, owner)
			accept_event()

func _debug_input_data_map() -> Dictionary:
	var data_map: Dictionary = {}
	if not settings or not settings.graph:
		return data_map
	for i in range(settings.graph.in_params.size()):
		var param = settings.graph.in_params[i]
		if param == null:
			continue
		var data = null
		if inputs.size() > i and inputs[i] != null:
			data = inputs[i]
		elif _last_input_data_map.has(param.name):
			data = _last_input_data_map[param.name]
		if data is FlowData.Data:
			data_map[param.name] = data
	return data_map

func setupDrawDebug() -> void:
	if settings != null and settings.debug_enabled:
		if not _debug_bulk_has_point_stream():
			if not _debug_full_eval_running:
				_queue_full_graph_eval_for_debug()
			return
	super.setupDrawDebug()
	_align_debug_draw_to_owner()

func _align_debug_draw_to_owner() -> void:
	if draw_debug == null or not draw_debug.instance_rid.is_valid():
		return
	var editor = getEditor()
	if editor == null:
		return
	var owner_node: Node3D = null
	if editor.resource_owner is Node3D:
		owner_node = editor.resource_owner
	elif editor.has_method("find_debug_world_node"):
		owner_node = editor.call("find_debug_world_node") as Node3D
	if owner_node == null or not owner_node.is_inside_tree():
		return
	RenderingServer.instance_set_transform(draw_debug.instance_rid, owner_node.global_transform)

func _push_child_debug_input_meta(ctx: FlowData.EvaluationContext, input_data_map: Dictionary) -> Dictionary:
	var owner = ctx.owner if ctx else null
	if owner == null:
		return {"owner": null}
	var previous := {
		"owner": owner,
		"had_graph": owner.has_meta("flow_debug_graph"),
		"graph": owner.get_meta("flow_debug_graph") if owner.has_meta("flow_debug_graph") else null,
		"had_input_data_map": owner.has_meta("flow_debug_input_data_map"),
		"input_data_map": owner.get_meta("flow_debug_input_data_map") if owner.has_meta("flow_debug_input_data_map") else null,
	}
	owner.set_meta("flow_debug_graph", settings.graph)
	owner.set_meta("flow_debug_input_data_map", input_data_map)
	return previous

func _pop_child_debug_input_meta(previous: Dictionary) -> void:
	var owner = previous.get("owner", null)
	if owner == null:
		return
	if bool(previous.get("had_graph", false)):
		owner.set_meta("flow_debug_graph", previous.get("graph"))
	else:
		owner.remove_meta("flow_debug_graph")
	if bool(previous.get("had_input_data_map", false)):
		owner.set_meta("flow_debug_input_data_map", previous.get("input_data_map"))
	else:
		owner.remove_meta("flow_debug_input_data_map")

func _child_runtime_params() -> Dictionary:
	if settings == null:
		return {}
	if settings.debug_enabled or settings.inspect_enabled or _is_currently_analyzed():
		return {"debug_enabled": true}
	return {}

func _debug_bulk_has_point_stream() -> bool:
	if generated_bulks.is_empty() or settings == null:
		return false
	var bulk_index := clampi(settings.debug_bulk, 0, generated_bulks.size() - 1)
	if generated_bulks[bulk_index].is_empty():
		return false
	var port_index := clampi(settings.debug_output, 0, generated_bulks[bulk_index].size() - 1)
	var out_data: FlowData.Data = get_bulk_output(bulk_index, port_index)
	return out_data != null and out_data.hasStream(FlowData.AttrPosition)

func _queue_full_graph_eval_for_debug() -> void:
	if _debug_full_eval_queued:
		return
	_debug_full_eval_queued = true
	call_deferred("_run_full_graph_eval_for_debug")

func _run_full_graph_eval_for_debug() -> void:
	_debug_full_eval_queued = false
	if settings == null or not settings.debug_enabled:
		return
	if _debug_bulk_has_point_stream():
		setupDrawDebug()
		return
	var editor = getEditor()
	if editor == null or _debug_full_eval_running:
		return
	_debug_full_eval_running = true
	dirty = true
	if editor.has_method(&"_cancel_regen_run"):
		editor.call(&"_cancel_regen_run")
	if editor.has_method(&"markAllNodesAsDirty"):
		editor.call(&"markAllNodesAsDirty")
	if editor.has_method(&"evalGraph"):
		editor.call(&"evalGraph")
	_debug_full_eval_running = false

func _is_currently_analyzed() -> bool:
	var editor = getEditor()
	if editor == null:
		return false
	if not ("current_analyzed_node" in editor):
		return false
	return editor.current_analyzed_node == self
