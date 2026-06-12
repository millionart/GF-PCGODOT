@tool
class_name CreateSplineNodeSettings
extends NodeSettings

@export_group("Create Spline")

enum eMode {
	CreateDataOnly,
	CreateComponent,
}

const INTERP_TYPE_LINEAR := 0
const INTERP_TYPE_CURVE := 1
const INTERP_TYPE_CURVE_CUSTOM_TANGENT := 4

@export var mode : eMode = eMode.CreateDataOnly:
	set(value):
		value = clampi(value, 0, eMode.size() - 1)
		mode = value
		notify_property_list_changed()

@export var closed_loop : bool = false
@export var linear : bool = false:
	set(value):
		linear = value
		notify_property_list_changed()

@export var apply_custom_tangents : bool = false:
	set(value):
		apply_custom_tangents = value
		notify_property_list_changed()

@export var arrive_tangent_attribute : String = "ArriveTangent"
@export var leave_tangent_attribute : String = "LeaveTangent"
@export var use_interp_type_attribute : bool = false:
	set(value):
		use_interp_type_attribute = value
		notify_property_list_changed()

@export var interp_type_attribute : String = "InterpType"
@export var node_name : String = "Spline"

func _init():
	super._init()
	resource_name = "Create Spline Settings"

func exposeParam(name : String) -> bool:
	if name == "arrive_tangent_attribute" or name == "leave_tangent_attribute":
		return not linear and apply_custom_tangents
	if name == "interp_type_attribute":
		return use_interp_type_attribute
	if name == "node_name":
		return mode == eMode.CreateComponent
	return true

func _get_attribute_selector_props() -> Array[Dictionary]:
	return [
		{ "prop": "arrive_tangent_attribute", "port": 0 },
		{ "prop": "leave_tangent_attribute", "port": 0 },
		{ "prop": "interp_type_attribute", "port": 0 },
	]
