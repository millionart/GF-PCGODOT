@tool
class_name SelectNodeSettings
extends NodeSettings

@export_group("Select")

var _syncing_use_input_b := false

@export var use_input_b: bool = false:
	set(value):
		use_input_b = value
		if not _syncing_use_input_b:
			_syncing_use_input_b = true
			select_b = value
			_syncing_use_input_b = false
		emit_changed()

@export var select_b: bool = false:
	set(value):
		select_b = value
		if not _syncing_use_input_b:
			_syncing_use_input_b = true
			use_input_b = value
			_syncing_use_input_b = false
		emit_changed()

@export var use_attribute: bool = false
@export var attribute_name: String = ""

func _init():
	super._init()
	resource_name = "Select Settings"

func _validate_property(property : Dictionary) -> void:
	if property.name == "select_b" or property.name == "use_attribute" or property.name == "attribute_name":
		property.usage &= ~PROPERTY_USAGE_EDITOR

func exposeParam(name : String) -> bool:
	if name == "select_b" or name == "use_attribute" or name == "attribute_name":
		return false
	return true
