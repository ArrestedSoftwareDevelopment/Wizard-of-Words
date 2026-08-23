extends SceneTree

const TITLE_ART := [
	"res://data/graphics/title screens/Title Screen 2.png",
	"res://data/graphics/title screens/titlescreen1.png",
]
const THEME_CATALOG := preload("res://scripts/ui/theme_catalog.gd")


func _initialize() -> void:
	var failures: Array = []
	for path in TITLE_ART:
		_check_texture(path, "title art", failures)

	var themes: Array[Dictionary] = THEME_CATALOG.all()
	if themes.size() != 7:
		failures.append("theme catalog expected 7 themes, found %d" % themes.size())
	var seen_ids: Dictionary = {}
	for theme in themes:
		var theme_id := str(theme.get("id", ""))
		if theme_id == "" or seen_ids.has(theme_id):
			failures.append("theme catalog has missing or duplicate id: %s" % theme_id)
		seen_ids[theme_id] = true
		_check_texture(str(theme.get("backdrop", "")), "%s backdrop" % theme_id, failures)
		var bonus_file := str(theme.get("bonus_lexicon", ""))
		if bonus_file != "" and not FileAccess.file_exists("res://data/dictionaries/" + bonus_file):
			failures.append("%s bonus lexicon missing: %s" % [theme_id, bonus_file])

	var dir := DirAccess.open("res://data/rulesets")
	if dir == null:
		failures.append("cannot open ruleset directory")
	else:
		dir.list_dir_begin()
		var filename := dir.get_next()
		while filename != "":
			if not dir.current_is_dir() and filename.get_extension().to_lower() == "json":
				_check_ruleset_assets("res://data/rulesets/" + filename, failures)
			filename = dir.get_next()
		dir.list_dir_end()

	var catalog_path := "res://data/graphics/frames/index.json"
	if not FileAccess.file_exists(catalog_path):
		failures.append("frame catalog is missing")
	else:
		var catalog = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
		if not (catalog is Dictionary):
			failures.append("frame catalog is invalid JSON")
		else:
			for filename in catalog:
				_check_texture("res://data/graphics/frames/" + String(filename), "frame catalog", failures)

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)


func _check_ruleset_assets(path: String, failures: Array) -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		failures.append("invalid ruleset JSON: %s" % path)
		return
	var skin: Dictionary = parsed.get("skin", {})
	for key in ["tiles", "background", "frame"]:
		if skin.has(key):
			_check_texture(String(skin[key]), "%s skin" % path.get_file(), failures)


func _check_texture(path: String, label: String, failures: Array) -> void:
	if not FileAccess.file_exists(path):
		failures.append("%s missing: %s" % [label, path])
		return
	if not (load(path) is Texture2D):
		failures.append("%s is not a loadable texture: %s" % [label, path])
