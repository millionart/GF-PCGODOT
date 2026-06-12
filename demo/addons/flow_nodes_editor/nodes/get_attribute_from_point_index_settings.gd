@tool
extends NodeSettings

@export_group("Get Attribute From Point Index")

@export var input_attribute_name : String = FlowData.AttrDensity:
	set(value):
		input_attribute_name = value.strip_edges()
		emit_changed()

@export var point_index : int = 0:
	set(value):
		point_index = value
		emit_changed()

@export var output_attribute_name : String = "@source":
	set(value):
		output_attribute_name = value.strip_edges()
		emit_changed()

func _init():
	super._init()
	resource_name = "Get Attribute From Point Index Settings"

func _get_attribute_selector_props() -> Array[Dictionary]:
	return [
		{ "prop": "input_attribute_name", "port": 0 },
	]
