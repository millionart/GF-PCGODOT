@tool
class_name NoiseNodeSettings
extends NodeSettings

const FlowSpatialNoiseRegistry = preload("res://addons/flow_nodes_editor/spatial_noise_registry.gd")

@export_group("Spatial Noise")

enum eMode {
	Perlin2D,
	Caustic2D,
	Voronoi2D,
	FractionalBrownian2D,
	EdgeMask2D,
}

enum eEdgeMask2DMode {
	Perlin,
	Caustic,
	FractionalBrownian,
}

@export var mode = FlowSpatialNoiseRegistry.ID_PERLIN_2D:
	set(value):
		var next_mode_id := FlowSpatialNoiseRegistry.mode_value_to_id(value)
		if mode == next_mode_id:
			return
		mode = next_mode_id
		notify_property_list_changed()
		emit_changed()

@export var edge_mask_2d_mode : eEdgeMask2DMode = eEdgeMask2DMode.Perlin:
	set(value):
		value = clampi(value, 0, eEdgeMask2DMode.size() - 1)
		edge_mask_2d_mode = value
		emit_changed()

@export var iterations : int = 4:
	set(value):
		iterations = maxi(1, value)
		emit_changed()

@export var tiling : bool = false:
	set(value):
		tiling = value
		notify_property_list_changed()
		emit_changed()

@export var brightness : float = 0.0:
	set(value):
		brightness = value
		emit_changed()

@export var contrast : float = 1.0:
	set(value):
		contrast = value
		emit_changed()

@export var value_target : String = FlowData.AttrDensity:
	set(value):
		value_target = value.strip_edges()
		emit_changed()

@export var random_offset : Vector3 = Vector3(100000.0, 100000.0, 100000.0):
	set(value):
		random_offset = value
		emit_changed()

@export var transform : Transform3D = Transform3D.IDENTITY:
	set(value):
		transform = value
		emit_changed()

@export var algorithm_parameters : Dictionary = {}:
	set(value):
		algorithm_parameters = value.duplicate()
		emit_changed()

@export var voronoi_cell_randomness : float = 1.0:
	set(value):
		voronoi_cell_randomness = clampf(value, 0.0, 1.0)
		emit_changed()

@export var voronoi_cell_id_target : String = "":
	set(value):
		voronoi_cell_id_target = value.strip_edges()
		emit_changed()

@export var voronoi_orient_samples_to_cell_edge : bool = false:
	set(value):
		voronoi_orient_samples_to_cell_edge = value
		emit_changed()

@export var tiled_voronoi_resolution : int = 8:
	set(value):
		tiled_voronoi_resolution = maxi(1, value)
		emit_changed()

@export var tiled_voronoi_edge_blend_cell_count : int = 2:
	set(value):
		tiled_voronoi_edge_blend_cell_count = maxi(0, value)
		emit_changed()

@export var edge_blend_distance : float = 1.0:
	set(value):
		edge_blend_distance = value
		emit_changed()

@export var edge_blend_curve_offset : float = 1.0:
	set(value):
		edge_blend_curve_offset = maxf(0.0, value)
		emit_changed()

@export var edge_blend_curve_intensity : float = 1.0:
	set(value):
		edge_blend_curve_intensity = maxf(0.0, value)
		emit_changed()

func _init():
	super._init()
	resource_name = "Spatial Noise Settings"

func _validate_property(property : Dictionary) -> void:
	if property.name != "mode":
		return
	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = FlowSpatialNoiseRegistry.get_mode_hint_string()

func get_mode_id() -> String:
	return mode

func exposeParam(name : String) -> bool:
	var active_mode := get_mode_id()
	if name == "algorithm_parameters":
		return FlowSpatialNoiseRegistry.is_external_algorithm(active_mode)
	if name == "iterations":
		return active_mode != FlowSpatialNoiseRegistry.ID_VORONOI_2D
	if name == "edge_mask_2d_mode" or name == "edge_blend_distance" \
			or name == "edge_blend_curve_offset" or name == "edge_blend_curve_intensity":
		return active_mode == FlowSpatialNoiseRegistry.ID_EDGE_MASK_2D
	if name == "voronoi_cell_randomness" or name == "voronoi_cell_id_target" \
			or name == "voronoi_orient_samples_to_cell_edge":
		return active_mode == FlowSpatialNoiseRegistry.ID_VORONOI_2D
	if name == "tiled_voronoi_resolution" or name == "tiled_voronoi_edge_blend_cell_count":
		return active_mode == FlowSpatialNoiseRegistry.ID_VORONOI_2D and tiling
	return true
