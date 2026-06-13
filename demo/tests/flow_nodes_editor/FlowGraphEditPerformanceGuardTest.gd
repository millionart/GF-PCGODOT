extends SceneTree

const GRAPH_EDIT_SOURCE := "res://addons/flow_nodes_editor/flow_graph_edit.gd"
const FlowGraphEditScript = preload("res://addons/flow_nodes_editor/flow_graph_edit.gd")
const RerouteNodeScript = preload("res://addons/flow_nodes_editor/nodes/reroute.gd")


func _init() -> void:
	var source := FileAccess.get_file_as_string(GRAPH_EDIT_SOURCE)
	var passed := true
	passed = _test_graph_edit_script_instantiates() and passed
	passed = _test_reroute_endpoint_cache_resolves_runtime_endpoint() and passed
	passed = _test_reroute_endpoint_resolution_uses_frame_cache(source) and passed
	passed = _test_reroute_tangent_direction_is_cached(source) and passed
	passed = _test_drag_interaction_uses_low_latency_connection_lines(source) and passed

	if not passed:
		push_error("FlowGraphEditPerformanceGuardTest failed.")
		quit(1)
		return
	quit(0)


func _test_graph_edit_script_instantiates() -> bool:
	var graph_edit = FlowGraphEditScript.new()
	var passed := _expect(graph_edit != null, "FlowGraphEdit script should instantiate.")
	graph_edit.free()
	return passed


func _test_reroute_endpoint_cache_resolves_runtime_endpoint() -> bool:
	var graph_edit = FlowGraphEditScript.new()
	var reroute = RerouteNodeScript.new()
	reroute.node_template = "reroute"
	reroute.position_offset = Vector2(10, 20)
	reroute.size = Vector2(42, 24)
	graph_edit.add_child(reroute)

	var left_port: Vector2 = graph_edit._reroute_left_port_graph_position(reroute)
	var center: Vector2 = graph_edit._reroute_center_graph_position(reroute)
	var result: Dictionary = graph_edit._resolve_reroute_endpoint(left_port)
	var passed := _expect(result.get("node") == reroute, "Cached reroute endpoint should resolve the reroute node.")
	passed = _expect(result.get("position") == center, "Cached reroute endpoint should return the reroute center.") and passed
	graph_edit.free()
	return passed


func _test_reroute_endpoint_resolution_uses_frame_cache(source: String) -> bool:
	var resolve_body := _function_body(source, "_resolve_reroute_endpoint")
	var ensure_body := _function_body(source, "_ensure_reroute_endpoint_cache")
	return (
		_expect(
			resolve_body.contains("_ensure_reroute_endpoint_cache()"),
			"Reroute endpoint resolution should use the per-frame cache."
		)
		and _expect(
			not resolve_body.contains("get_children()"),
			"Reroute endpoint resolution should not scan all GraphEdit children per connection."
		)
		and _expect(
			ensure_body.contains("Engine.get_process_frames()"),
			"Reroute endpoint cache should rebuild at most once per frame."
		)
	)


func _test_reroute_tangent_direction_is_cached(source: String) -> bool:
	var tangent_body := _function_body(source, "_should_reverse_reroute_tangent")
	return (
		_expect(
			source.contains("var _reroute_tangent_reverse_cache"),
			"Reroute tangent direction should have a cache."
		)
		and _expect(
			tangent_body.contains("_reroute_tangent_reverse_cache.has(node_name)"),
			"Reroute tangent direction should reuse cached values."
		)
	)


func _test_drag_interaction_uses_low_latency_connection_lines(source: String) -> bool:
	var get_line_body := _function_body(source, "_get_connection_line")
	var interaction_body := _function_body(source, "_make_interaction_connection_line")
	var make_line_body := _function_body(source, "_make_connection_line")
	var setter_body := _function_body(source, "set_interaction_low_latency")
	return (
		_expect(
			get_line_body.find("_make_interaction_connection_line") < get_line_body.find("_resolve_reroute_endpoint"),
			"Interactive drags should use the fast connection-line path before reroute resolution."
		)
		and _expect(
			interaction_body.contains("points.append(from_position)") and interaction_body.contains("points.append(to_position)"),
			"Interactive connection-line preview should allocate only the two endpoint points."
		)
		and _expect(
			not make_line_body.contains("_low_latency_connection_lines"),
			"Full-quality connection line generation should stay independent from drag preview mode."
		)
		and _expect(
			setter_body.contains("queue_redraw()"),
			"Changing low-latency mode should redraw connection lines."
		)
	)


func _function_body(source: String, function_name: String) -> String:
	var start := source.find("func " + function_name)
	if start < 0:
		return ""
	var next_func := source.find("\nfunc ", start + 1)
	if next_func < 0:
		return source.substr(start)
	return source.substr(start, next_func - start)


func _expect(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
