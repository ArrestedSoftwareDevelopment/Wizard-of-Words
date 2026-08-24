class_name ThemeCatalog
extends RefCounted

const CATALOG_PATH := "res://data/themes/index.json"
const BOARD_LAYOUTS_PATH := "res://data/themes/board_layouts.json"

static var _cache: Array[Dictionary] = []
static var _board_layout_cache: Dictionary = {}


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


static func board_layout(theme_id: String) -> Array:
	_load_board_layouts()
	var entry: Dictionary = _board_layout_cache.get(theme_id, {})
	return entry.get("layout", []).duplicate(true)


static func board_layout_name(theme_id: String) -> String:
	_load_board_layouts()
	var entry: Dictionary = _board_layout_cache.get(theme_id, {})
	return str(entry.get("name", "Theme Board"))


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


static func _load_board_layouts() -> void:
	if not _board_layout_cache.is_empty():
		return
	if not FileAccess.file_exists(BOARD_LAYOUTS_PATH):
		push_error("Theme board layouts are missing: %s" % BOARD_LAYOUTS_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOARD_LAYOUTS_PATH))
	if not (parsed is Dictionary):
		push_error("Theme board layouts must be a dictionary.")
		return
	_board_layout_cache = parsed.duplicate(true)
