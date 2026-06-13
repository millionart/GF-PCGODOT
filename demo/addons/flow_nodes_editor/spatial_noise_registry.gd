@tool
extends Object
class_name FlowSpatialNoiseRegistry

const ID_PERLIN_2D := "Perlin2D"
const ID_CAUSTIC_2D := "Caustic2D"
const ID_VORONOI_2D := "Voronoi2D"
const ID_FRACTIONAL_BROWNIAN_2D := "FractionalBrownian2D"
const ID_EDGE_MASK_2D := "EdgeMask2D"

const BUILTIN_IDS := [
	ID_PERLIN_2D,
	ID_CAUSTIC_2D,
	ID_VORONOI_2D,
	ID_FRACTIONAL_BROWNIAN_2D,
	ID_EDGE_MASK_2D,
]

static var _external_algorithms := {}


static func register_algorithm(id : String, sampler : Callable, options := {}) -> String:
	var normalized := _normalize_id(id)
	if normalized.is_empty():
		return "Spatial Noise algorithm id cannot be empty"
	if _is_builtin_id(normalized):
		return "Spatial Noise algorithm '%s' is reserved by Flow editor" % normalized
	if not normalized.contains("/"):
		return "External Spatial Noise algorithm id must use 'PluginName/NoiseName': %s" % normalized
	if not sampler.is_valid():
		return "Spatial Noise algorithm '%s' has an invalid sampler" % normalized
	if _external_algorithms.has(normalized):
		return "Spatial Noise algorithm '%s' is already registered" % normalized

	var label := str(options.get("label", normalized)).strip_edges()
	if label.is_empty():
		label = normalized
	_external_algorithms[normalized] = {
		"id": normalized,
		"label": label,
		"sampler": sampler,
		"builtin": false,
	}
	return ""


static func unregister_algorithm(id : String) -> void:
	_external_algorithms.erase(_normalize_id(id))


static func clear_external_algorithms() -> void:
	_external_algorithms.clear()


static func get_algorithm(id : String) -> Dictionary:
	var normalized := _normalize_id(id)
	if _is_builtin_id(normalized):
		return {
			"id": normalized,
			"label": normalized,
			"builtin": true,
		}
	if _external_algorithms.has(normalized):
		return _external_algorithms[normalized].duplicate()
	return {}


static func has_algorithm(id : String) -> bool:
	return not get_algorithm(id).is_empty()


static func is_external_algorithm(id : String) -> bool:
	var normalized := _normalize_id(id)
	return _external_algorithms.has(normalized)


static func get_algorithm_ids() -> Array[String]:
	var ids : Array[String] = []
	for id in BUILTIN_IDS:
		ids.append(id)
	var external_ids := _external_algorithms.keys()
	external_ids.sort()
	for id in external_ids:
		ids.append(str(id))
	return ids


static func get_mode_hint_string() -> String:
	return ",".join(get_algorithm_ids())


static func mode_value_to_id(value) -> String:
	if typeof(value) == TYPE_INT:
		var index := int(value)
		if index >= 0 and index < BUILTIN_IDS.size():
			return BUILTIN_IDS[index]
		return ID_PERLIN_2D
	var normalized := _normalize_id(str(value))
	if normalized.is_valid_int() and not normalized.contains("/"):
		return mode_value_to_id(int(normalized))
	if normalized.is_empty():
		return ID_PERLIN_2D
	return normalized


static func _normalize_id(id : String) -> String:
	return id.strip_edges()


static func _is_builtin_id(id : String) -> bool:
	return id in BUILTIN_IDS
