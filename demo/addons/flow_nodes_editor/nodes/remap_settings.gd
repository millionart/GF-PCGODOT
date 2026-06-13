@tool
class_name RemapNodeSettings
extends NodeSettings

@export_group("Attribute Curve Remap")

@export var in_name : String = FlowData.AttrDensity
@export var out_name : String = "@in_name"
@export var remap_curve : Curve

func _init():
	super._init()
	remap_curve = Curve.new()
	remap_curve.add_point( Vector2(0,0) )
	remap_curve.add_point( Vector2(1,1) )
	resource_name = "Attribute Curve Remap Settings"
