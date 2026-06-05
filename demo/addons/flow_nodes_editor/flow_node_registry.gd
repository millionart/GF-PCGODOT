@tool
extends Object
class_name FlowNodeRegistry

const DEFAULT_NODE_DIRECTORY := "res://addons/flow_nodes_editor/nodes"

static var _extra_node_directories: Array[String] = []
static var _node_metadata_providers: Dictionary = {}
static var _node_metadata_cache: Dictionary = {}
static var _version := 0


static func register_node_directory(directory_path: String) -> void:
	var normalized := _normalize_directory_path(directory_path)
	if normalized.is_empty():
		return
	if normalized == DEFAULT_NODE_DIRECTORY:
		return
	if normalized in _extra_node_directories:
		return
	_extra_node_directories.append(normalized)
	_version += 1


static func unregister_node_directory(directory_path: String) -> void:
	var normalized := _normalize_directory_path(directory_path)
	var index := _extra_node_directories.find(normalized)
	if index == -1:
		return
	_extra_node_directories.remove_at(index)
	_version += 1


static func register_node_metadata_provider(provider_id: String, provider: Callable) -> void:
	var normalized := provider_id.strip_edges()
	if normalized.is_empty() or not provider.is_valid():
		return
	_node_metadata_providers[normalized] = provider
	_node_metadata_cache.erase(normalized)
	_version += 1


static func unregister_node_metadata_provider(provider_id: String) -> void:
	var normalized := provider_id.strip_edges()
	if not _node_metadata_providers.has(normalized):
		return
	_node_metadata_providers.erase(normalized)
	_node_metadata_cache.erase(normalized)
	_version += 1


static func get_node_directories() -> Array[String]:
	var directories: Array[String] = [DEFAULT_NODE_DIRECTORY]
	directories.append_array(_extra_node_directories)
	return directories


static func get_node_metadata(template_name: String) -> Dictionary:
	var normalized := template_name.strip_edges()
	if normalized.is_empty():
		return {}
	for provider_id in _node_metadata_providers.keys():
		var entries := _get_provider_metadata_entries(str(provider_id))
		if not entries.has(normalized):
			continue
		var metadata: Dictionary = entries[normalized]
		return metadata.duplicate()
	return {}


static func get_node_metadata_entries() -> Dictionary:
	var combined := {}
	for provider_id in _node_metadata_providers.keys():
		var entries := _get_provider_metadata_entries(str(provider_id))
		for template_name in entries.keys():
			var metadata: Variant = entries[template_name]
			if metadata is Dictionary:
				combined[str(template_name)] = metadata.duplicate()
	return combined


static func get_node_script_path(template_name: String) -> String:
	if template_name.begins_with("input_"):
		return DEFAULT_NODE_DIRECTORY + "/input.gd"
	if template_name.begins_with("output_"):
		return DEFAULT_NODE_DIRECTORY + "/output.gd"

	var metadata := get_node_metadata(template_name)
	var factory_path := str(metadata.get("factory_path", metadata.get("full_res_path", "")))
	if not factory_path.is_empty() and ResourceLoader.exists(factory_path, "Script"):
		return factory_path

	for directory_path in get_node_directories():
		var script_path := "%s/%s.gd" % [directory_path, template_name]
		if ResourceLoader.exists(script_path, "Script"):
			return script_path
	return ""


static func get_version() -> int:
	return _version


static func _normalize_directory_path(directory_path: String) -> String:
	var normalized := directory_path.strip_edges().replace("\\", "/")
	while normalized.ends_with("/"):
		normalized = normalized.trim_suffix("/")
	return normalized


static func _get_provider_metadata_entries(provider_id: String) -> Dictionary:
	if _node_metadata_cache.has(provider_id):
		return _node_metadata_cache[provider_id]
	if not _node_metadata_providers.has(provider_id):
		return {}

	var provider: Callable = _node_metadata_providers[provider_id]
	var result: Variant = provider.call()
	var entries := {}
	if result is Dictionary:
		for template_name in result.keys():
			var metadata: Variant = result[template_name]
			if not (metadata is Dictionary):
				continue
			var normalized := str(template_name).strip_edges()
			if normalized.is_empty():
				continue
			var metadata_copy: Dictionary = metadata.duplicate()
			if not metadata_copy.has("template"):
				metadata_copy["template"] = normalized
			entries[normalized] = metadata_copy
	_node_metadata_cache[provider_id] = entries
	return entries
