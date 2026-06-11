extends SceneTree

const FlowEditorChrome = preload("res://addons/flow_nodes_editor/flow_editor_chrome.gd")


func _init() -> void:
	if not _run_test():
		push_error("FlowGraphMenuPanelStyleTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var host := Control.new()
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	host.add_child(vbox)

	var tab_panel := PanelContainer.new()
	tab_panel.name = "TabBarPanel"
	var tab_row := HBoxContainer.new()
	tab_row.name = "TabBarRow"
	var tab_bar := TabBar.new()
	tab_bar.name = "TabBar"
	tab_row.add_child(tab_bar)
	tab_panel.add_child(tab_row)
	vbox.add_child(tab_panel)

	var toolbar_hbox := HBoxContainer.new()
	toolbar_hbox.name = "HBoxContainer"
	var scroll_container := ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.add_child(toolbar_hbox)
	vbox.add_child(scroll_container)

	var graph_edit := GraphEdit.new()
	var light_menu_panel := StyleBoxFlat.new()
	light_menu_panel.bg_color = Color(1.0, 1.0, 1.0, 0.35)
	graph_edit.add_theme_stylebox_override("menu_panel", light_menu_panel)
	vbox.add_child(graph_edit)

	var refs := FlowEditorChrome.Refs.new()
	refs.host = host
	refs.tab_bar = tab_bar
	refs.toolbar_hbox = toolbar_hbox
	refs.graph_edit = graph_edit
	FlowEditorChrome.apply_styles(refs)

	var menu_hbox := graph_edit.get_menu_hbox()
	if menu_hbox == null:
		host.free()
		push_error("GraphEdit menu hbox should exist.")
		return false
	var graph_menu_panel := menu_hbox.get_parent() as PanelContainer
	if graph_menu_panel == null:
		host.free()
		push_error("GraphEdit menu panel should be a PanelContainer.")
		return false
	var menu_panel_style := graph_menu_panel.get_theme_stylebox("panel")
	host.free()
	if not (menu_panel_style is StyleBoxFlat):
		push_error("Graph menu panel style should be StyleBoxFlat.")
		return false

	var bg_color: Color = (menu_panel_style as StyleBoxFlat).bg_color
	var luminance := (bg_color.r + bg_color.g + bg_color.b) / 3.0
	if luminance >= 0.35:
		push_error("Graph menu panel style should stay dark, got: %s." % bg_color)
		return false
	if bg_color.a < 0.68:
		push_error("Graph menu panel alpha should stay semi-opaque, got: %f." % bg_color.a)
		return false
	return true
