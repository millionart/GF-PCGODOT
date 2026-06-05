@tool
class_name FlowEditorChrome
extends RefCounted

## Toolbar + tab row (styles, signals, i18n). Does not touch graph / comment code.

const INITIALIZED_META := &"flow_editor_chrome_initialized"
const GRAPH_MENU_PANEL_MIN_ALPHA := 0.68
const TOOLBAR_ICON_BY_NAME := {
	"ButtonSave": "Save",
	"ButtonBrowse": "ShowInFileSystem",
	"ButtonReload": "Reload",
	"ButtonAnalyze": "Search",
	"ButtonRegenerate": "RandomNumberGenerator",
	"ButtonMinimap": "GridMinimap",
	"ButtonInputs": "GraphEdit",
	"ButtonSettings": "Tools",
}
const TOOLBAR_TOOLTIP_BY_NAME := {
	"ButtonSave": "Save the current FlowGraph resource",
	"ButtonBrowse": "Reveal the saved graph resource in the FileSystem dock",
	"ButtonReload": "Reload the current FlowGraph resource",
	"ButtonAnalyze": "Inspect selected node raw data (A)",
	"ButtonRegenerate": "Regenerate the graph output",
	"ButtonMinimap": "Toggle the graph minimap.",
	"ButtonInputs": "Edit graph inputs",
	"ButtonSettings": "Open Flow editor settings",
}


class Refs:
	var host: Control
	var tab_bar: TabBar
	var toolbar_hbox: HBoxContainer
	var graph_edit: GraphEdit
	var open_graph_button: Button
	var expand_graph_button: Button

	func is_valid() -> bool:
		return host != null and tab_bar != null and toolbar_hbox != null


static func is_valid_layout(host: Control) -> bool:
	return host.has_node("VBoxContainer/TabBarPanel/TabBarRow/TabBar")


static func clear_initialized(host: Control) -> void:
	if host.has_meta(INITIALIZED_META):
		host.remove_meta(INITIALIZED_META)


static func setup(refs: Refs) -> void:
	if not refs.is_valid():
		return
	if refs.host.has_meta(INITIALIZED_META):
		_attach_toolbar_to_graph_menu(refs)
		apply_styles(refs)
		apply_translations(refs)
		return
	enforce_vbox_order(refs)
	_attach_toolbar_to_graph_menu(refs)
	connect_signals(refs)
	apply_styles(refs)
	apply_translations(refs)
	refs.host.set_meta(INITIALIZED_META, true)


static func retarget_graph_edit(refs: Refs, graph_edit: GraphEdit) -> void:
	if not refs.is_valid() or graph_edit == null:
		return
	refs.graph_edit = graph_edit
	_attach_toolbar_to_graph_menu(refs)
	_style_graph_menu_toolbar(refs)


static func enforce_vbox_order(refs: Refs) -> void:
	var vbox := refs.host.get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	var legacy_breadcrumb := vbox.get_node_or_null("BreadcrumbPanel")
	if legacy_breadcrumb:
		legacy_breadcrumb.free()
	var legacy_open := refs.toolbar_hbox.get_node_or_null("ButtonOpenGraph")
	if legacy_open:
		legacy_open.free()
	var order := [
		"TabBarPanel",
		"ScrollContainer",
		"VSplitContainer",
		"StatusPanel",
	]
	for i in order.size():
		var node := vbox.get_node_or_null(order[i])
		if node:
			vbox.move_child(node, i)


static func _attach_toolbar_to_graph_menu(refs: Refs) -> void:
	if refs.graph_edit == null:
		return
	var graph_menu_hbox := refs.graph_edit.get_menu_hbox()
	if graph_menu_hbox == null:
		return
	var graph_menu_panel := graph_menu_hbox.get_parent() as PanelContainer
	if graph_menu_panel == null:
		return
	var editor_scale := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	refs.graph_edit.show_menu = true
	graph_menu_hbox.visible = false
	graph_menu_panel.visible = true
	graph_menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph_menu_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE, int(10 * editor_scale))
	if refs.toolbar_hbox.get_parent() != graph_menu_panel:
		if refs.toolbar_hbox.get_parent() != null:
			refs.toolbar_hbox.get_parent().remove_child(refs.toolbar_hbox)
		graph_menu_panel.add_child(refs.toolbar_hbox)
	refs.toolbar_hbox.visible = true
	refs.toolbar_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	refs.toolbar_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var old_toolbar_container := refs.host.get_node_or_null("VBoxContainer/ScrollContainer") as ScrollContainer
	if old_toolbar_container:
		old_toolbar_container.visible = false
		old_toolbar_container.custom_minimum_size = Vector2.ZERO
		old_toolbar_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


static func connect_signals(refs: Refs) -> void:
	var host := refs.host
	if refs.tab_bar:
		if not refs.tab_bar.tab_changed.is_connected(host._on_tab_changed):
			refs.tab_bar.tab_changed.connect(host._on_tab_changed)
		if not refs.tab_bar.tab_close_pressed.is_connected(host._on_tab_close_pressed):
			refs.tab_bar.tab_close_pressed.connect(host._on_tab_close_pressed)
	if refs.open_graph_button and not refs.open_graph_button.pressed.is_connected(host._on_button_open_pressed):
		refs.open_graph_button.pressed.connect(host._on_button_open_pressed)
	_connect_pressed(refs, "ButtonSave", host._on_button_save_pressed)
	_connect_pressed(refs, "ButtonBrowse", host._on_button_browse_pressed)
	_connect_pressed(refs, "ButtonReload", host._on_button_reload_pressed)
	_connect_pressed(refs, "ButtonAnalyze", host._on_button_analyze_pressed)
	_connect_pressed(refs, "ButtonRegenerate", host._on_button_regenerate_pressed)
	_connect_button_toggled(refs, "ButtonMinimap", host._on_button_minimap_toggled)
	_connect_pressed(refs, "ButtonInputs", host._on_button_inputs_pressed)
	_connect_pressed(refs, "ButtonSettings", host._on_button_settings_pressed)
	_connect_toggled(refs, "AutoRegen", host._on_auto_regen_toggled)
	_connect_toggled(refs, "CheckColorNodes", host._on_color_nodes_toggled)
	var inputs_button := refs.toolbar_hbox.get_node_or_null("ButtonInputs") as Button
	if inputs_button:
		inputs_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if refs.expand_graph_button and not refs.expand_graph_button.pressed.is_connected(host._on_button_expand_graph_pressed):
		refs.expand_graph_button.pressed.connect(host._on_button_expand_graph_pressed)


static func _connect_pressed(refs: Refs, node_name: String, callback: Callable) -> void:
	var button := refs.toolbar_hbox.get_node_or_null(node_name) as Button
	if button and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


static func _connect_button_toggled(refs: Refs, node_name: String, callback: Callable) -> void:
	var button := refs.toolbar_hbox.get_node_or_null(node_name) as Button
	if button:
		button.toggle_mode = true
		if not button.toggled.is_connected(callback):
			button.toggled.connect(callback)


static func _connect_toggled(refs: Refs, node_name: String, callback: Callable) -> void:
	var checkbox := refs.toolbar_hbox.get_node_or_null(node_name) as CheckBox
	if checkbox and not checkbox.toggled.is_connected(callback):
		checkbox.toggled.connect(callback)


static func apply_styles(refs: Refs) -> void:
	if not refs.is_valid():
		return
	_attach_toolbar_to_graph_menu(refs)
	var vbox := refs.host.get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	var tab_panel := vbox.get_node_or_null("TabBarPanel") as PanelContainer
	if tab_panel:
		var tab_sb := StyleBoxFlat.new()
		tab_sb.bg_color = Color("0e1016")
		tab_sb.content_margin_left = 4
		tab_sb.content_margin_right = 4
		tab_sb.content_margin_top = 2
		tab_sb.content_margin_bottom = 0
		tab_panel.add_theme_stylebox_override("panel", tab_sb)
	var toolbar_container := vbox.get_node_or_null("ScrollContainer") as ScrollContainer
	if toolbar_container:
		toolbar_container.visible = false
	_style_graph_menu_toolbar(refs)
	var status_panel := vbox.get_node_or_null("StatusPanel") as PanelContainer
	if status_panel:
		var status_sb := StyleBoxFlat.new()
		status_sb.bg_color = Color("0a0c12")
		status_sb.border_width_top = 1
		status_sb.border_color = Color(1.0, 1.0, 1.0, 0.04)
		status_sb.content_margin_left = 12
		status_sb.content_margin_right = 12
		status_sb.content_margin_top = 4
		status_sb.content_margin_bottom = 4
		status_panel.add_theme_stylebox_override("panel", status_sb)
	for child in refs.toolbar_hbox.get_children():
		if child is Button:
			var button := child as Button
			if TOOLBAR_ICON_BY_NAME.has(button.name):
				_style_toolbar_icon_button(button, String(TOOLBAR_ICON_BY_NAME[button.name]))
			else:
				_style_toolbar_button(button)
	if refs.open_graph_button:
		_style_open_graph_button(refs.open_graph_button)
	if refs.expand_graph_button:
		_style_expand_graph_button(refs.expand_graph_button)


static func apply_translations(refs: Refs) -> void:
	if not refs.is_valid():
		return
	FlowI18n.reload_locale_files()
	var text_by_name := {
		"AutoRegen": "Auto Generate",
		"CheckColorNodes": "Color Nodes",
	}
	for node_name in text_by_name:
		var control := _get_control(refs, node_name)
		if control is Button:
			(control as Button).text = FlowI18n.t(String(text_by_name[node_name]))
		elif control is Label:
			(control as Label).text = FlowI18n.t(String(text_by_name[node_name]))
	var tooltip_by_name := {
		"ButtonExpandGraph": "Float and Maximize Graph Panel",
	}
	for node_name in TOOLBAR_TOOLTIP_BY_NAME:
		var control := _get_control(refs, node_name)
		if control:
			control.tooltip_text = FlowI18n.t(String(TOOLBAR_TOOLTIP_BY_NAME[node_name]))
	for node_name in tooltip_by_name:
		var control := _get_control(refs, node_name)
		if control:
			control.tooltip_text = FlowI18n.t(String(tooltip_by_name[node_name]))
	if refs.open_graph_button:
		refs.open_graph_button.text = ""
		refs.open_graph_button.tooltip_text = FlowI18n.t("Open a FlowGraph resource")
	if refs.expand_graph_button:
		refs.expand_graph_button.text = ""
		refs.expand_graph_button.tooltip_text = FlowI18n.t("Float and Maximize Graph Panel")


static func _get_control(refs: Refs, node_name: String) -> Control:
	var control := refs.toolbar_hbox.get_node_or_null(node_name) as Control
	if control:
		return control
	if node_name == "ButtonOpenGraph" and refs.open_graph_button:
		return refs.open_graph_button
	if node_name == "ButtonExpandGraph" and refs.expand_graph_button:
		return refs.expand_graph_button
	return null


static func _style_toolbar_button(btn: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(1.0, 1.0, 1.0, 0.05)
	sb_normal.set_border_width_all(1)
	sb_normal.border_color = Color(1.0, 1.0, 1.0, 0.1)
	sb_normal.set_corner_radius_all(3)
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 4
	sb_normal.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb_normal)
	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(1.0, 1.0, 1.0, 0.09)
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color(1.0, 1.0, 1.0, 0.02)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", Color("cdd0dc"))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color("a1a1aa"))


static func _style_toolbar_icon_button(btn: Button, icon_name: String) -> void:
	var editor_scale := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	btn.text = ""
	btn.theme_type_variation = "FlatButton"
	btn.focus_mode = Control.FOCUS_ACCESSIBILITY
	btn.custom_minimum_size = Vector2(34, 32) * editor_scale
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = false
	if Engine.is_editor_hint():
		var editor_theme := EditorInterface.get_editor_theme()
		if editor_theme != null and editor_theme.has_icon(icon_name, "EditorIcons"):
			btn.icon = editor_theme.get_icon(icon_name, "EditorIcons")
	if btn.name == "ButtonRegenerate":
		_style_regenerate_button(btn)


static func _style_open_graph_button(btn: Button) -> void:
	var editor_scale := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	btn.text = ""
	btn.theme_type_variation = "FlatMenuButton"
	btn.focus_mode = Control.FOCUS_ACCESSIBILITY
	btn.custom_minimum_size = Vector2(28, 28) * editor_scale
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = false
	if Engine.is_editor_hint():
		var editor_theme := EditorInterface.get_editor_theme()
		if editor_theme != null and editor_theme.has_icon("Load", "EditorIcons"):
			btn.icon = editor_theme.get_icon("Load", "EditorIcons")


static func _style_expand_graph_button(btn: Button) -> void:
	var editor_scale := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	btn.text = ""
	btn.theme_type_variation = "BottomPanelButton"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(28, 28) * editor_scale
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = false
	if Engine.is_editor_hint():
		var editor_theme := EditorInterface.get_editor_theme()
		if editor_theme != null and editor_theme.has_icon("ExpandBottomDock", "EditorIcons"):
			btn.icon = editor_theme.get_icon("ExpandBottomDock", "EditorIcons")


static func _style_regenerate_button(btn: Button) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color("1b1e28")
	sb_normal.set_border_width_all(1)
	sb_normal.border_color = Color("22d3ee")
	sb_normal.set_corner_radius_all(3)
	sb_normal.content_margin_left = 10
	sb_normal.content_margin_right = 10
	sb_normal.content_margin_top = 4
	sb_normal.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb_normal)
	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color("252836")
	btn.add_theme_stylebox_override("hover", sb_hover)
	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color("111318")
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", Color("22d3ee"))
	btn.add_theme_color_override("font_hover_color", Color("22d3ee"))
	btn.add_theme_color_override("font_pressed_color", Color("22d3ee"))


static func _style_graph_menu_toolbar(refs: Refs) -> void:
	if refs.graph_edit == null:
		return
	var graph_menu_hbox := refs.graph_edit.get_menu_hbox()
	if graph_menu_hbox == null:
		return
	var graph_menu_panel := graph_menu_hbox.get_parent() as PanelContainer
	if graph_menu_panel == null:
		return
	var editor_scale := EditorInterface.get_editor_scale() if Engine.is_editor_hint() else 1.0
	var panel_style := _make_graph_menu_panel_style(refs.graph_edit)
	if panel_style != null:
		graph_menu_panel.add_theme_stylebox_override("panel", panel_style)
		graph_menu_panel.call_deferred(
			"add_theme_stylebox_override",
			"panel",
			_make_graph_menu_panel_style(refs.graph_edit),
		)
	refs.toolbar_hbox.add_theme_constant_override("separation", int(4 * editor_scale))


static func _make_graph_menu_panel_style(graph_edit: GraphEdit) -> StyleBox:
	if graph_edit == null:
		return null
	var panel_style := graph_edit.get_theme_stylebox("menu_panel", "GraphEdit")
	if panel_style == null:
		return null
	var toolbar_panel_style := panel_style.duplicate()
	if toolbar_panel_style is StyleBoxFlat:
		var flat_style := toolbar_panel_style as StyleBoxFlat
		var bg_color := flat_style.bg_color
		bg_color.a = maxf(bg_color.a, GRAPH_MENU_PANEL_MIN_ALPHA)
		flat_style.bg_color = bg_color
	return toolbar_panel_style
