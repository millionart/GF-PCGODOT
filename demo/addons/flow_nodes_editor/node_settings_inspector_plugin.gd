@tool
extends EditorInspectorPlugin
class_name FlowNodesInspectorPlugin

func _can_handle(object):
	if FlowInspectorPropertyPolicy.is_creating_default_editor(object):
		return false
	return (
		object is NodeSettings
		or object is FlowGraphResource
		or object is GraphFrame
		or FlowInspectorPropertyPolicy.is_flow_editor_settings_proxy(object)
	)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if object is GraphFrame:
		return false
	if FlowInspectorPropertyPolicy.is_flow_editor_settings_proxy(object):
		return _parse_flow_editor_setting_property(object, type, name, hint_type, hint_string, usage_flags, wide)

	var graph_resource := object as FlowGraphResource
	if graph_resource != null:
		return _parse_flow_graph_resource_property(object, type, name, hint_type, hint_string, usage_flags, wide)

	var settings : NodeSettings = object as NodeSettings
	if settings != null:
		if not FlowInspectorPropertyPolicy.should_show_property(object, name, usage_flags):
			return true
		var node := FlowNodeInspectorContextControls.get_node_context(settings)
		var custom_control := FlowNodeInspectorContextControls.create_custom_property_control(
			node,
			settings,
			name,
			Callable(self, "_on_context_value_changed")
		)
		if custom_control != null:
			add_property_editor(
				name,
				custom_control,
				false,
				FlowInspectorPropertyPolicy.localized_property_label(object, name)
			)
			return true
		return _add_localized_property_editor(
			object,
			type,
			name,
			hint_type,
			hint_string,
			usage_flags,
			wide,
			FlowInspectorPropertyPolicy.localized_property_label(object, name)
		)
	return false

func _parse_end(object: Object) -> void:
	var frame := object as GraphFrame
	if frame != null:
		var actions := FlowNodeInspectorContextControls.create_frame_actions(frame)
		if actions != null:
			add_custom_control(actions)
		return

	var settings := object as NodeSettings
	if settings == null:
		return
	var node := FlowNodeInspectorContextControls.get_node_context(settings)
	if node == null:
		return
	var extras := VBoxContainer.new()
	extras.add_theme_constant_override("separation", 8)
	if FlowNodeInspectorContextControls.add_variable_node_extras(node, settings, extras):
		add_custom_control(extras)

func _parse_flow_editor_setting_property(
	object: Object,
	type,
	name: String,
	hint_type,
	hint_string: String,
	usage_flags,
	wide: bool,
) -> bool:
	if not object.has_method("get_flow_editor_setting_label"):
		return false
	if not FlowInspectorPropertyPolicy.should_show_property(object, name, usage_flags):
		return true
	var label := FlowInspectorPropertyPolicy.localized_property_label(object, name)
	return _add_localized_property_editor(object, type, name, hint_type, hint_string, usage_flags, wide, label)

func _parse_flow_graph_resource_property(
	object: Object,
	type,
	name: String,
	hint_type,
	hint_string: String,
	usage_flags,
	wide: bool,
) -> bool:
	var graph_resource := object as FlowGraphResource
	if graph_resource == null:
		return false
	var label := ""
	if not FlowInspectorPropertyPolicy.should_show_property(object, name, usage_flags):
		return true
	match name:
		"in_params":
			_add_graph_parameters_control(
				graph_resource,
				"in_params",
				FlowI18n.t("Graph Inputs"),
				true
			)
			return true
		"out_params":
			_add_graph_parameters_control(
				graph_resource,
				"out_params",
				FlowI18n.t("Graph Outputs"),
				false
			)
			return true
		_:
			label = FlowInspectorPropertyPolicy.localized_property_label(object, name)
	return _add_localized_property_editor(object, type, name, hint_type, hint_string, usage_flags, wide, label)

func _add_graph_parameters_control(
	res: FlowGraphResource,
	prop_name: String,
	title: String,
	include_value: bool,
) -> void:
	var editor := FlowGraphParametersEditor.new()
	editor.setup(res, prop_name, title, include_value)
	editor.property_edited.connect(_notify_native_graph_parameter_edited, CONNECT_DEFERRED)
	add_custom_control(editor)

func _notify_native_graph_parameter_edited(prop_name: String) -> void:
	_notify_native_property_edited(prop_name)

func _notify_native_property_edited(prop_name: String) -> void:
	call_deferred("_emit_native_property_edited", prop_name)

func _emit_native_property_edited(prop_name: String) -> void:
	var inspector := EditorInterface.get_inspector()
	if inspector != null:
		inspector.property_edited.emit(prop_name)

func _on_context_value_changed(object: Object, prop_name: String, new_val) -> void:
	object.set(prop_name, new_val)
	if object is Resource:
		object.emit_changed()
	_notify_native_property_edited(prop_name)

func _add_localized_property_editor(
	object: Object,
	type,
	name: String,
	hint_type,
	hint_string: String,
	usage_flags,
	wide: bool,
	label: String,
) -> bool:
	return FlowInspectorPropertyPolicy.add_localized_property_editor(
		self,
		object,
		type,
		name,
		hint_type,
		hint_string,
		usage_flags,
		wide,
		label
	)
