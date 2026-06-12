@tool
class_name MatchAndSetNodeSettings
extends NodeSettings

@export_group("Match And Set Attributes")

@export var match_attributes : bool = false:
	set(value):
		match_attributes = value
		notify_property_list_changed()
		emit_changed()

@export var input_attribute : String = "":
	set(value):
		input_attribute = value.strip_edges()
		emit_changed()

@export var match_attr : String = "":
	set(value):
		match_attr = value.strip_edges()
		emit_changed()

@export var keep_unmatched : bool = true:
	set(value):
		keep_unmatched = value
		emit_changed()

@export var use_weight_attribute : bool = false:
	set(value):
		use_weight_attribute = value
		notify_property_list_changed()
		emit_changed()

@export var weight_attr : String = "":
	set(value):
		weight_attr = value.strip_edges()
		emit_changed()

func _init():
	super._init()
	resource_name = "Match And Set Attributes"

func exposeParam(name : String) -> bool:
	if name == "input_attribute" or name == "match_attr" or name == "keep_unmatched":
		return match_attributes
	if name == "weight_attr":
		return use_weight_attribute
	return true

func _get_attribute_selector_props() -> Array[Dictionary]:
	return [
		{ "prop": "input_attribute", "port": 0 },
		{ "prop": "match_attr", "port": 1 },
		{ "prop": "weight_attr", "port": 1 },
	]
