@tool
extends NodeSettings

@export_group("Spline to Segment")

const _legacy_props : Array[String] = [
	"uniform_interval",
	"segment_size_xy",
	"out_segment_index_attribute",
	"out_spline_index_attribute",
	"out_start_attribute",
	"out_end_attribute",
	"include_spline_ref",
	"out_spline_attribute",
]

@export var spline_stream_attribute : String = "node"
@export var extract_tangents : bool = false
@export var extract_angles : bool = true
@export var extract_connectivity_info : bool = true
@export var extract_clockwise_info : bool = true

@export var uniform_interval : float = 1.0
@export var segment_size_xy : Vector2 = Vector2.ONE
@export var out_segment_index_attribute : String = "segment_index"
@export var out_spline_index_attribute : String = "spline_index"
@export var out_start_attribute : String = "segment_start"
@export var out_end_attribute : String = "segment_end"
@export var include_spline_ref : bool = true
@export var out_spline_attribute : String = "node"

func _init():
	super._init()
	resource_name = "Spline to Segment Settings"

func _validate_property(property : Dictionary) -> void:
	if property.name in _legacy_props:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func exposeParam(name : String) -> bool:
	return not (name in _legacy_props)
