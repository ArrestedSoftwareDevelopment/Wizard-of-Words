extends SceneTree

const THEME_LANGUAGE := preload("res://scripts/language/theme_language.gd")
const REQUIRED_EVENTS := {
	"move": 8,
	"bonus": 6,
	"pass": 6,
	"trade": 6,
	"ai_pass": 6,
	"ai_fumble": 6,
	"thinking": 6,
	"match_start": 4,
	"match_end": 4,
}


func _initialize() -> void:
	var failures: Array = []
	var catalog_path := "res://data/dictionaries/index.json"
	var catalog: Variant = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	if not (catalog is Dictionary):
		failures.append("dictionary catalog is invalid JSON")
	else:
		_verify_dictionaries(catalog, failures)
	_verify_theme_language(failures)
	_verify_policy_sets(failures)
	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)


func _verify_dictionaries(catalog: Dictionary, failures: Array) -> void:
	var required_roles := {
		"profanity_blacklist.txt": "profanity",
		"slur_blacklist.txt": "slur",
		"proper_nouns_reference.txt": "proper_noun",
		"brands_trademarks.txt": "brand_trademark",
		"two_letter_whitelist.txt": "trusted_two_letter",
	}
	for filename in required_roles:
		var policy: Dictionary = catalog.get(filename, {})
		if bool(policy.get("selectable", true)) or str(policy.get("policy_role", "")) != str(required_roles[filename]):
			failures.append("%s is not configured as hidden policy role %s" % [filename, required_roles[filename]])
	var required_modules := ["acronyms.txt", "given_names.txt", "african_american_english.txt", "tech_jargon.txt", "science_jargon.txt", "spanish_starter.txt", "french_starter.txt", "italian_starter.txt"]
	for filename in required_modules:
		var module: Dictionary = catalog.get(filename, {})
		if not bool(module.get("selectable", true)) or bool(module.get("default_checked", true)):
			failures.append("%s should be selectable and opt-in" % filename)
	var default_bases := 0
	for filename in catalog:
		var metadata: Variant = catalog[filename]
		if metadata is Dictionary and str(metadata.get("category", "")) == "base" and bool(metadata.get("default_checked", false)):
			default_bases += 1
	if default_bases != 1:
		failures.append("exactly one base grimoire should be checked by default; found %d" % default_bases)
	var directory := DirAccess.open("res://data/dictionaries")
	if directory == null:
		failures.append("dictionary directory cannot be opened")
		return
	for filename in directory.get_files():
		if filename.get_extension().to_lower() != "txt":
			continue
		if not catalog.has(filename):
			failures.append("dictionary lacks catalog metadata: %s" % filename)
		var metadata: Dictionary = catalog.get(filename, {})
		var inherited_source := str(metadata.get("source_id", "")).begins_with("enable") or str(metadata.get("source_id", "")).begins_with("12dicts")
		var words := _lines("res://data/dictionaries/" + filename)
		var seen: Dictionary = {}
		var previous := ""
		for raw_word in words:
			var word := raw_word.to_upper()
			if not _is_ascii_word(word) or (not inherited_source and raw_word != word):
				failures.append("%s contains malformed word: %s" % [filename, raw_word])
			if seen.has(word):
				failures.append("%s repeats word: %s" % [filename, raw_word])
			if previous != "" and word < previous:
				failures.append("%s is not sorted at: %s" % [filename, raw_word])
			seen[word] = true
			previous = word
	var minimums := {
		"acronyms.txt": 60,
		"brands_trademarks.txt": 100,
		"given_names.txt": 200,
		"profanity_blacklist.txt": 30,
		"proper_nouns_reference.txt": 100,
		"science_jargon.txt": 75,
		"tech_jargon.txt": 100,
	}
	for filename in minimums:
		var count := _lines("res://data/dictionaries/" + filename).size()
		if count < int(minimums[filename]):
			failures.append("%s has only %d words; expected at least %d" % [filename, count, minimums[filename]])
	var themes: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/themes/index.json"))
	if themes is Array:
		for theme in themes:
			var bonus_file := str(theme.get("bonus_lexicon", ""))
			if _lines("res://data/dictionaries/" + bonus_file).size() < 75:
				failures.append("%s needs at least 75 themed words" % bonus_file)


func _verify_theme_language(failures: Array) -> void:
	var themes: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/themes/index.json"))
	if not (themes is Array):
		failures.append("theme catalog unavailable to language verifier")
		return
	var context := {
		"actor": "Apprentice",
		"words": "MOON LIGHT",
		"score": 42,
		"point_word": "points",
		"bonus": "The test hums",
		"points": 25,
		"count": 3,
		"rune_word": "runes",
		"reason": "test reason",
		"dots": "...",
		"ruleset": "Classic Grimoire",
		"theme": "Test Theme",
		"winner": "Apprentice",
		"lexicon": "Test Lexicon",
		"word_count": 1000,
	}
	for theme in themes:
		var theme_id := str(theme.get("id", ""))
		var path := "res://data/language/" + theme_id + ".json"
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			failures.append("language pack missing or invalid: %s" % theme_id)
			continue
		for event_type in REQUIRED_EVENTS:
			var variants: Variant = parsed.get(event_type, [])
			if not (variants is Array) or variants.size() < int(REQUIRED_EVENTS[event_type]):
				failures.append("%s needs %d %s variants" % [theme_id, REQUIRED_EVENTS[event_type], event_type])
		var language: RefCounted = THEME_LANGUAGE.new().load_for(theme_id)
		for event_type in REQUIRED_EVENTS:
			var first: String = language.line(event_type, context, 12)
			var second: String = language.line(event_type, context, 12)
			if first.is_empty() or first != second:
				failures.append("%s %s is empty or nondeterministic" % [theme_id, event_type])
			if first.contains("{") or first.contains("}"):
				failures.append("%s %s leaves an unresolved placeholder: %s" % [theme_id, event_type, first])


func _verify_policy_sets(failures: Array) -> void:
	var ruleset := WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	var lexicon := Lexicon.new()
	lexicon.words = {"SHIT": true, "FAG": true, "MARS": true, "APPLE": true}
	lexicon.blacklist = Lexicon.load_word_set("res://data/dictionaries/profanity_blacklist.txt")
	lexicon.slur_blacklist = Lexicon.load_word_set("res://data/dictionaries/slur_blacklist.txt")
	lexicon.proper_nouns = Lexicon.load_word_set("res://data/dictionaries/proper_nouns_reference.txt")
	lexicon.brands_trademarks = Lexicon.load_word_set("res://data/dictionaries/brands_trademarks.txt")
	ruleset.profanity_filter = true
	if MoveLogic.validate(_empty_board(), _move("SHIT"), ruleset, lexicon)["ok"]:
		failures.append("profanity policy did not reject its fixture")
	ruleset.profanity_filter = false
	ruleset.slur_filter = true
	if MoveLogic.validate(_empty_board(), _move("FAG"), ruleset, lexicon)["ok"]:
		failures.append("slur policy did not reject its fixture")
	ruleset.slur_filter = false
	ruleset.proper_noun_filter = true
	if MoveLogic.validate(_empty_board(), _move("MARS"), ruleset, lexicon)["ok"]:
		failures.append("proper-noun policy did not reject its fixture")
	ruleset.proper_noun_filter = false
	ruleset.brand_trademark_filter = true
	if MoveLogic.validate(_empty_board(), _move("APPLE"), ruleset, lexicon)["ok"]:
		failures.append("brand/trademark policy did not reject its fixture")


func _lines(path: String) -> Array[String]:
	var result: Array[String] = []
	if not FileAccess.file_exists(path):
		return result
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		var word := raw.strip_edges()
		if word != "":
			result.append(word)
	return result


func _is_ascii_word(word: String) -> bool:
	if word.is_empty() or word != word.to_upper():
		return false
	for character in word:
		if character < "A" or character > "Z":
			return false
	return true


func _empty_board() -> GameBoard:
	var board := GameBoard.new()
	board.setup(15)
	return board


func _move(word: String) -> Array:
	var result := []
	var start_x := 7 - int(word.length() / 2.0)
	for index in range(word.length()):
		result.append({
			"pos": Vector2i(start_x + index, 7),
			"tile": {"letter": word.substr(index, 1), "value": 1, "blank": false},
		})
	return result
