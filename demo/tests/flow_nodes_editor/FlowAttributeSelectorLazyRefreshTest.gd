extends SceneTree

const CONTEXT_CONTROLS_SOURCE := "res://addons/flow_nodes_editor/flow_node_inspector_context_controls.gd"
const FLOW_EDITOR_SOURCE := "res://addons/flow_nodes_editor/flow_editor.gd"


func _init() -> void:
	var controls_source := FileAccess.get_file_as_string(CONTEXT_CONTROLS_SOURCE)
	var editor_source := FileAccess.get_file_as_string(FLOW_EDITOR_SOURCE)
	var passed := true
	passed = _test_attribute_selector_does_not_fetch_on_dropdown_click(controls_source) and passed
	passed = _test_node_click_prefetches_attribute_lists(editor_source) and passed
	passed = _test_editor_populates_attribute_selector_inputs_without_persistent_inspect(editor_source) and passed

	if not passed:
		push_error("FlowAttributeSelectorLazyRefreshTest failed.")
		quit(1)
		return
	quit(0)


func _test_attribute_selector_does_not_fetch_on_dropdown_click(source: String) -> bool:
	var create_body := _function_body(source, "create_attribute_selector")
	return (
		_expect(
			not source.contains("_request_attribute_selector_input_data"),
			"Attribute selector should not keep a separate dropdown-click fetch path."
		)
		and _expect(
			not create_body.contains("about_to_popup") and not create_body.contains("option.pressed.connect"),
			"Attribute selector dropdown clicks should not trigger graph evaluation."
		)
		and _expect(
			create_body.contains("_populate_attribute_selector_options(option, edit, current_val, get_input_stream_names(node, port))"),
			"Attribute selector should render only the data already prefetched by FlowEditor."
		)
	)


func _test_node_click_prefetches_attribute_lists(source: String) -> bool:
	var inspect_body := _function_body(source, "_inspect_graph_element")
	var prefill_body := _function_body(source, "_prefill_attribute_selector_inputs")
	var selected_body := _function_body(source, "_on_graph_edit_node_selected")
	var box_select_body := _function_body(source, "_inspect_graph_selection_after_box_select")
	return (
		_expect(
			inspect_body.contains("prefetch_attribute_selectors") and inspect_body.contains("_prefill_attribute_selector_inputs(flow_node)"),
			"Graph element inspection should optionally prefetch attribute selector inputs before drawing the inspector."
		)
		and _expect(
			prefill_body.contains("_get_attribute_selector_props") and prefill_body.contains("populateAttributeSelectorInputData(node, port)"),
			"Attribute selector prefetch should reuse each settings resource's declared selector ports."
		)
		and _expect(
			selected_body.contains("_inspect_graph_element(inspected_node, true)"),
			"Single node click should prefetch attribute selector lists."
		)
		and _expect(
			box_select_body.contains("_inspect_graph_element(selected_nodes[0], false)"),
			"Box-select inspection should not prefetch attribute selector lists."
		)
	)


func _test_editor_populates_attribute_selector_inputs_without_persistent_inspect(source: String) -> bool:
	var body := _function_body(source, "populateAttributeSelectorInputData")
	return (
		_expect(
			body.contains("previous_inspect_enabled"),
			"Attribute selector data population should remember the node's inspect state."
		)
		and _expect(
			body.contains("node.settings.inspect_enabled = true"),
			"Attribute selector data population should make the target node a temporary eval root."
		)
		and _expect(
			body.contains("node.settings.inspect_enabled = previous_inspect_enabled"),
			"Attribute selector data population should restore the node's inspect state."
		)
		and _expect(
			body.contains("_run_forced_graph_eval(node)"),
			"Attribute selector data population should use the silent forced graph evaluation path."
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
