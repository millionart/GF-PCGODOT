extends SceneTree

const FlowI18nScript = preload("res://addons/flow_nodes_editor/flow_i18n.gd")
const FlowNodeScene = preload("res://addons/flow_nodes_editor/node.tscn")
const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const NodeSettingsScript = preload("res://addons/flow_nodes_editor/node_settings.gd")
const SearchAddNodePopupScript = preload("res://addons/flow_nodes_editor/search_add_node_popup.gd")


func _init() -> void:
	var previous_locale := TranslationServer.get_locale()
	var previous_node_translation := FlowI18nScript.is_node_translation_enabled()
	TranslationServer.set_locale("zh_CN")

	var passed := true
	passed = _test_node_scene_disables_engine_auto_translation() and passed
	passed = _test_search_popup_disables_engine_auto_translation() and passed
	passed = _test_custom_title_survives_node_translation_disabled() and passed

	TranslationServer.set_locale(previous_locale)
	FlowI18nScript.set_node_translation_enabled(previous_node_translation)

	if not passed:
		push_error("FlowNodeTranslationTitleTest failed.")
		quit(1)
		return
	quit(0)


func _test_node_scene_disables_engine_auto_translation() -> bool:
	var node := FlowNodeScene.instantiate()
	var passed := _expect(
		node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED,
		"Flow graph nodes should disable Godot engine auto translation"
	)
	node.free()
	return passed


func _test_search_popup_disables_engine_auto_translation() -> bool:
	var popup = SearchAddNodePopupScript.new()
	get_root().add_child(popup)
	var passed := _expect(
		popup.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED,
		"Search add node popup should disable Godot engine auto translation"
	)
	popup.queue_free()
	return passed


func _test_custom_title_survives_node_translation_disabled() -> bool:
	var node := _make_node("Switch", "Route By Biome")
	FlowI18nScript.set_node_translation_enabled(false)
	var passed := _expect(node.getLocalizedTitle() == "Route By Biome", "Custom node title should not be replaced by template title")
	node.free()
	return passed


func _make_node(template_title : String, settings_title : String):
	var node = FlowNodeBaseScript.new()
	node.meta_node = { "title": template_title }
	node.settings = NodeSettingsScript.new()
	node.settings.title = settings_title
	return node


func _expect(condition : bool, message : String) -> bool:
	if condition:
		return true
	push_error(message)
	return false
