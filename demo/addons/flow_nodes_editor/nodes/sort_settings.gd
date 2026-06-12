@tool
class_name SortNodeSettings
extends NodeSettings

@export_group("Sort")

enum eSortMethod {
	Ascending,
	Descending,
}

var _syncing_sort_method := false

@export var sort_by : String
@export var sort_method : eSortMethod = eSortMethod.Ascending:
	set(value):
		value = clampi(value, 0, eSortMethod.size() - 1)
		sort_method = value
		if not _syncing_sort_method:
			_syncing_sort_method = true
			sort_descending = sort_method == eSortMethod.Descending
			_syncing_sort_method = false
		emit_changed()

@export var sort_descending : bool = false:
	set(value):
		sort_descending = value
		if not _syncing_sort_method:
			_syncing_sort_method = true
			sort_method = eSortMethod.Descending if sort_descending else eSortMethod.Ascending
			_syncing_sort_method = false
		emit_changed()

@export var use_stable_sort : bool = true

func _init():
	super._init()
	resource_name = "Sort Settings"

func _validate_property(property : Dictionary) -> void:
	if property.name == "sort_descending":
		property.usage &= ~PROPERTY_USAGE_EDITOR

func exposeParam(name : String):
	if name == "sort_descending":
		return false
	return true

func _get_attribute_selector_props() -> Array[Dictionary]:
	return [
		{ "prop": "sort_by", "port": 0 },
	]
