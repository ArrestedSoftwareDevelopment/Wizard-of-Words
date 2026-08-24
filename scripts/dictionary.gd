class_name Lexicon
extends RefCounted

var lexicon_name := ""
var words: Dictionary = {}
var blacklist: Dictionary = {}
var slur_blacklist: Dictionary = {}
var proper_nouns: Dictionary = {}
var brands_trademarks: Dictionary = {}
var trusted_two_letter: Dictionary = {}
var bonus_sets: Array = []


static func load_word_set(path: String) -> Dictionary:
	var out := {}
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return out
	if path.get_extension().to_lower() == "json":
		var parsed = JSON.parse_string(fa.get_as_text())
		if parsed is Array:
			for w in parsed:
				_add_to(out, str(w))
		elif parsed is Dictionary:
			if parsed.has("words") and parsed["words"] is Array:
				for w in parsed["words"]:
					_add_to(out, str(w))
			else:
				for k in parsed:
					var val = parsed[k]
					if val is bool and val:
						_add_to(out, str(k))
					elif val is String:
						_add_to(out, val)
	else:
		for line in fa.get_as_text().split("\n"):
			_add_to(out, line)
	return out


static func _add_to(set_words: Dictionary, raw: String) -> void:
	var w := raw.strip_edges().to_upper()
	if w != "" and _is_letters(w):
		set_words[w] = true


static func _is_letters(w: String) -> bool:
	for ch in w:
		if ch < "A" or ch > "Z":
			return false
	return true


static func load_from(path: String) -> Lexicon:
	var lx := Lexicon.new()
	lx.lexicon_name = path.get_file().get_basename()
	lx.words = load_word_set(path)
	return lx


func merge_from(other: Lexicon) -> void:
	for w in other.words:
		words[w] = true


func has_word(w: String) -> bool:
	return words.has(w.to_upper())


func word_list() -> Array:
	return words.keys()


func size() -> int:
	return words.size()


func load_policy_set(role: String, path: String) -> void:
	var loaded := load_word_set(path)
	match role:
		"profanity": blacklist = loaded
		"slur": slur_blacklist = loaded
		"proper_noun": proper_nouns = loaded
		"brand_trademark": brands_trademarks = loaded
		"trusted_two_letter": trusted_two_letter = loaded
