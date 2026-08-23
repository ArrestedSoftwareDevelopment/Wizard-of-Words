class_name ThemeCatalog
extends RefCounted

const CATALOG_PATH := "res://data/themes/index.json"

static var _cache: Array[Dictionary] = []


static func all() -> Array[Dictionary]:
	if _cache.is_empty():
		_load()
	return _cache.duplicate(true)


static func find(theme_id: String) -> Dictionary:
	for theme in all():
		if str(theme.get("id", "")) == theme_id:
			return theme
	return default_theme()


static func default_theme() -> Dictionary:
	var themes := all()
	return themes[0] if not themes.is_empty() else {}


static func _load() -> void:
	_cache.clear()
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Theme catalog is missing: %s" % CATALOG_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
	if not (parsed is Array):
		push_error("Theme catalog must contain an array.")
		return
	for entry in parsed:
		if entry is Dictionary and str(entry.get("id", "")) != "":
			_cache.append(entry.duplicate(true))
