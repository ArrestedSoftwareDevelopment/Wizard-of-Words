class_name ThemeLanguage
extends RefCounted

const BASE_PATH := "res://data/language/"

var theme_id := "wizardry"
var entries: Dictionary = {}


func load_for(id: String) -> RefCounted:
	theme_id = id
	var path := BASE_PATH + id + ".json"
	if not FileAccess.file_exists(path):
		path = BASE_PATH + "wizardry.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		entries = parsed
	return self


func line(event_type: String, context: Dictionary = {}, sequence := 0) -> String:
	var variants: Variant = entries.get(event_type, [])
	if not (variants is Array) or variants.is_empty():
		return ""
	# Presentation choices are derived from event data. Remote play therefore
	# sends the event once and each client can render identical flavor locally.
	var stable_context := context.duplicate(true)
	# Animation punctuation changes often; it must not swap the underlying line.
	stable_context.erase("dots")
	var stable_keys: Array = stable_context.keys()
	stable_keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
	var signature_parts: Array[String] = []
	for key in stable_keys:
		signature_parts.append("%s=%s" % [str(key), JSON.stringify(stable_context[key])])
	var signature := "%s|%s|%d|%s" % [theme_id, event_type, sequence, "|".join(signature_parts)]
	var index: int = int(signature.hash() & 0x7fffffff) % variants.size()
	var rendered := str(variants[index])
	var keys: Array = context.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
	for key in keys:
		rendered = rendered.replace("{%s}" % str(key), str(context[key]))
	return rendered


func has_event(event_type: String) -> bool:
	return entries.has(event_type) and entries[event_type] is Array and not entries[event_type].is_empty()
