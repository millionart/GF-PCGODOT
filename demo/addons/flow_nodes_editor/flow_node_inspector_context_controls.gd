@tool
extends RefCounted
class_name FlowNodeInspectorContextControls

const NODE_CONTEXT_META := &"_flow_inspector_node_context"


static func set_node_context(settings: Object, node: FlowNodeBase) -> void:
	if settings == null:
		return
	if settings.has_meta(NODE_CONTEXT_META):
		settings.remove_meta(NODE_CONTEXT_META)
	settings.set_meta(NODE_CONTEXT_META, node)


static func get_node_context(settings: Object) -> FlowNodeBase:
	if settings == null or not settings.has_meta(NODE_CONTEXT_META):
		return null
	var node := settings.get_meta(NODE_CONTEXT_META) as FlowNodeBase
	if node == null or not is_instance_valid(node):
		return null
	return node


static func create_custom_property_control(
	node: GraphNode,
	settings: Object,
	prop_name: String,
	value_changed_callback: Callable,
	font_size: int = 11,
) -> Control:
	if node == null:
		return null
	var attr_port := _attribute_selector_port(settings, prop_name)
	if attr_port >= 0:
		return create_attribute_selector(node, settings, prop_name, attr_port, value_changed_callback, font_size)
	if _is_variable_selector_prop(settings, prop_name):
		return create_variable_selector(node, settings, prop_name, value_changed_callback, font_size)
	return null


static func add_variable_node_extras(
	node: FlowNodeBase,
	settings: Object,
	parent: VBoxContainer,
	font_size: int = 11,
) -> bool:
	if node == null or settings == null or parent == null:
		return false
	var added := false
	if node.node_template == "get_variable":
		parent.add_child(create_row(
			FlowI18n.t("Source"),
			create_get_variable_source_button(node, settings, font_size),
			font_size
		))
		added = true
	elif node.node_template == "set_variable":
		parent.add_child(create_set_variable_get_references(node, settings, font_size))
		added = true
	return added


static func create_row(label_text: String, control: Control, font_size: int = 11) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("cbd5e1"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	row.add_child(label)

	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


static func create_attribute_selector(
	node: GraphNode,
	settings: Object,
	prop_name: String,
	port: int,
	value_changed_callback: Callable,
	font_size: int = 11,
) -> Control:
	var current_val := str(settings.get(prop_name))
	var stream_names := get_input_stream_names(node, port)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)

	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", font_size)
	option.custom_minimum_size.x = 100

	var edit := LineEdit.new()
	edit.text = current_val
	edit.placeholder_text = FlowI18n.t("attribute name...")
	edit.add_theme_font_size_override("font_size", font_size)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color("111318")
	stylebox.set_corner_radius_all(3)
	stylebox.content_margin_left = 6
	stylebox.content_margin_right = 6
	edit.add_theme_stylebox_override("normal", stylebox)
	edit.visible = false

	var selected_idx := -1
	var idx := 0
	for stream_name in stream_names:
		option.add_item(stream_name, idx)
		if stream_name == current_val:
			selected_idx = idx
		idx += 1

	var custom_idx := idx
	option.add_separator()
	option.add_item(FlowI18n.t("(custom...)"), custom_idx + 1)

	if stream_names.is_empty():
		option.selected = option.item_count - 1
		option.set_item_text(option.item_count - 1, FlowI18n.t("(no attributes found)"))
		option.disabled = true
		option.visible = true
		edit.visible = true
	elif selected_idx >= 0:
		option.selected = selected_idx
		option.disabled = false
		option.set_item_text(option.item_count - 1, FlowI18n.t("(custom...)"))
		option.visible = true
		edit.visible = false
	else:
		option.selected = option.item_count - 1
		option.disabled = false
		option.set_item_text(option.item_count - 1, FlowI18n.t("(custom...)"))
		option.visible = true
		edit.visible = true

	option.item_selected.connect(func(index):
		var item_id := option.get_item_id(index)
		if item_id == custom_idx + 1:
			edit.visible = true
			edit.grab_focus()
		else:
			var chosen := option.get_item_text(index)
			edit.visible = false
			edit.text = chosen
			_emit_value_changed(settings, prop_name, chosen, value_changed_callback)
	, CONNECT_DEFERRED)

	edit.text_submitted.connect(func(new_text):
		_emit_value_changed(settings, prop_name, new_text, value_changed_callback)
	, CONNECT_DEFERRED)
	edit.focus_exited.connect(func():
		if str(settings.get(prop_name)) != edit.text:
			_emit_value_changed(settings, prop_name, edit.text, value_changed_callback)
	, CONNECT_DEFERRED)

	wrapper.add_child(option)
	wrapper.add_child(edit)
	return wrapper


static func create_variable_selector(
	node: GraphNode,
	settings: Object,
	prop_name: String,
	value_changed_callback: Callable,
	font_size: int = 11,
) -> Control:
	var current_val := str(settings.get(prop_name))
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", font_size)
	option.custom_minimum_size.x = 100

	var selected_idx := -1
	var item_idx := 0
	var editor_instance = node.getEditor() if node and node.has_method("getEditor") else null
	var definitions := []
	if editor_instance and editor_instance.has_method("getSetVariableDefinitions"):
		definitions = editor_instance.getSetVariableDefinitions()

	for definition in definitions:
		var variable_name := String(definition.get("name", ""))
		if variable_name.is_empty():
			continue
		option.add_item(variable_name, item_idx)
		if variable_name == current_val:
			selected_idx = item_idx
		item_idx += 1

	if item_idx == 0:
		option.add_item(FlowI18n.t("No variables set"), 0)
		option.selected = 0
		option.disabled = true
	else:
		option.disabled = false
		option.select(selected_idx)

	option.item_selected.connect(func(index):
		if option.disabled:
			return
		_emit_value_changed(settings, prop_name, option.get_item_text(index), value_changed_callback)
		if node and node.has_method("refreshVariableChoices"):
			node.refreshVariableChoices()
	, CONNECT_DEFERRED)
	return option


static func create_set_variable_get_references(
	node: FlowNodeBase,
	settings: Object,
	font_size: int = 11,
) -> Control:
	var variable_name := str(settings.get("variable_name")).strip_edges()
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 4)

	var header := Label.new()
	header.text = FlowI18n.t("Get nodes using this variable")
	header.add_theme_font_size_override("font_size", font_size)
	header.add_theme_color_override("font_color", Color("a1a1aa"))
	section.add_child(header)

	if variable_name.is_empty():
		var hint := _make_hint_label(FlowI18n.t("Set a variable name first"), font_size)
		section.add_child(hint)
		return section

	var editor_instance: FlowEditor = null
	if node.has_method("getEditor"):
		editor_instance = node.getEditor() as FlowEditor
	if editor_instance == null or not editor_instance.has_method("getGetVariableNodes"):
		return section

	var get_nodes := editor_instance.getGetVariableNodes(variable_name)
	if get_nodes.is_empty():
		section.add_child(_make_hint_label(FlowI18n.t("No get nodes use this variable"), font_size))
		return section

	for get_node in get_nodes:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_child(row)

		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", font_size)
		if get_node.has_method("getTitle"):
			button.text = String(get_node.call("getTitle"))
		else:
			button.text = String(get_node.name)
		button.tooltip_text = FlowI18n.t("Pan to this get node without changing selection")
		button.disabled = not editor_instance.has_method("focusGetVariableNode")
		var target := get_node
		button.pressed.connect(func():
			if editor_instance and editor_instance.has_method("focusGetVariableNode"):
				editor_instance.focusGetVariableNode(target)
		, CONNECT_DEFERRED)
		row.add_child(button)

	return section


static func create_get_variable_source_button(
	node: FlowNodeBase,
	settings: Object,
	font_size: int = 11,
) -> Button:
	var button := Button.new()
	button.text = FlowI18n.t("Locate Set Variable")
	button.add_theme_font_size_override("font_size", font_size)

	var editor_instance = node.getEditor() if node and node.has_method("getEditor") else null
	button.disabled = editor_instance == null or not editor_instance.has_method("focusSetVariableNode")
	button.pressed.connect(func():
		var variable_name := str(settings.get("variable_name")).strip_edges()
		if variable_name.is_empty():
			return
		editor_instance.focusSetVariableNode(variable_name)
	, CONNECT_DEFERRED)
	return button


static func get_input_stream_names(node: GraphNode, port: int) -> PackedStringArray:
	var names := PackedStringArray()
	if not node or not "inputs" in node:
		return names
	if port < 0 or port >= node.inputs.size():
		return names
	var input_data = node.inputs[port]
	if input_data == null or not input_data is FlowData.Data:
		return names
	for stream_name in input_data.streams.keys():
		names.append(str(stream_name))
	names.sort()
	return names


static func _attribute_selector_port(settings: Object, prop_name: String) -> int:
	if settings == null or not settings.has_method("_get_attribute_selector_props"):
		return -1
	for entry in settings._get_attribute_selector_props():
		if str(entry.get("prop", "")) == prop_name:
			return int(entry.get("port", 0))
	return -1


static func _is_variable_selector_prop(settings: Object, prop_name: String) -> bool:
	if settings == null or not settings.has_method("_get_variable_selector_props"):
		return false
	for entry in settings._get_variable_selector_props():
		if str(entry.get("prop", "")) == prop_name:
			return true
	return false


static func _emit_value_changed(
	settings: Object,
	prop_name: String,
	new_value,
	value_changed_callback: Callable,
) -> void:
	if value_changed_callback.is_valid():
		value_changed_callback.call(settings, prop_name, new_value)
		return
	settings.set(prop_name, new_value)
	if settings is Resource:
		settings.emit_changed()


static func _make_hint_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("71717a"))
	return label
