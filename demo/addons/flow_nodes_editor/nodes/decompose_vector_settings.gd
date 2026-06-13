@tool
class_name DecomposeVectorNodeSettings
extends NodeSettings

@export_group("Break Vector Attribute")
@export var in_attribute: String = FlowData.AttrPosition
@export var x_attribute: String = "x"
@export var y_attribute: String = "y"
@export var z_attribute: String = "z"
@export var w_attribute: String = "w"

func _init():
	super._init()
	resource_name = "Break Vector Attribute Settings"

func _get_attribute_selector_props() -> Array[Dictionary]:
	return [
		{ "prop": "in_attribute", "port": 0 },
	]
