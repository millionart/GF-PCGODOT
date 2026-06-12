@tool
class_name NoiseNodeSettings
extends NodeSettings

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

@export var mode : eMode = eMode.Perlin2D:
	set(value):
		value = clampi(value, 0, eMode.size() - 1)
		mode = value
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

func exposeParam(name : String) -> bool:
	if name == "iterations":
		return mode != eMode.Voronoi2D
	if name == "edge_mask_2d_mode" or name == "edge_blend_distance" \
			or name == "edge_blend_curve_offset" or name == "edge_blend_curve_intensity":
		return mode == eMode.EdgeMask2D
	if name == "voronoi_cell_randomness" or name == "voronoi_cell_id_target" \
			or name == "voronoi_orient_samples_to_cell_edge":
		return mode == eMode.Voronoi2D
	if name == "tiled_voronoi_resolution" or name == "tiled_voronoi_edge_blend_cell_count":
		return mode == eMode.Voronoi2D and tiling
	return true
