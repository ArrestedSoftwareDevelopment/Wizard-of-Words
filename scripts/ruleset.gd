class_name WordRuleset
extends RefCounted

var ruleset_name := ""
var board_size := 15
var rack_size := 7
var bingo_bonus := 50
var end_penalty := true
var blank_count := 2
var min_word_length := 2
var allow_any_two_letter := false
var strict_two_letter := false
var fog_of_war := false
var fog_radius := 2
var skin: Dictionary = {}
var profanity_filter := false
var layout: Array = []
var legend: Dictionary = {}
var letters: Dictionary = {}

const DEFAULT_LEGEND := {
	".": {"name": "", "type": "", "mult": 1, "color": Color("3a2b52"), "glyph": ""},
	"D": {"name": "Double Word", "type": "word", "mult": 2, "color": Color("c46a8f"), "glyph": "☽"},
	"T": {"name": "Triple Word", "type": "word", "mult": 3, "color": Color("b03a48"), "glyph": "☉"},
	"d": {"name": "Double Letter", "type": "letter", "mult": 2, "color": Color("4f8fbf"), "glyph": "☿"},
	"t": {"name": "Triple Letter", "type": "letter", "mult": 3, "color": Color("2f5f96"), "glyph": "♄"},
	"*": {"name": "Center Star", "type": "word", "mult": 2, "color": Color("e8b23a"), "glyph": "⛤"}
}


static func load_from(path: String) -> WordRuleset:
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		push_error("Cannot open ruleset: %s" % path)
		return null
	var parsed = JSON.parse_string(fa.get_as_text())
	if not (parsed is Dictionary):
		push_error("Invalid ruleset JSON: %s" % path)
		return null
	var data: Dictionary = parsed
	var r := WordRuleset.new()
	r.ruleset_name = str(data.get("name", path.get_file().get_basename()))
	r.board_size = int(data.get("board_size", 15))
	r.rack_size = int(data.get("rack_size", 7))
	r.bingo_bonus = int(data.get("bingo_bonus", 50))
	r.end_penalty = bool(data.get("end_penalty", true))
	r.blank_count = int(data.get("blank_count", 2))
	r.min_word_length = int(data.get("min_word_length", 2))
	r.allow_any_two_letter = bool(data.get("allow_any_two_letter", false))
	r.strict_two_letter = bool(data.get("strict_two_letter", false))
	r.fog_of_war = bool(data.get("fog_of_war", false))
	r.fog_radius = clampi(int(data.get("fog_radius", 2)), 1, 5)
	if data.has("skin") and data["skin"] is Dictionary:
		r.skin = data["skin"]
	r.profanity_filter = bool(data.get("profanity_filter", false))
	r.layout = data.get("layout", [])
	r.legend = DEFAULT_LEGEND.duplicate(true)
	if data.has("legend"):
		for k in data["legend"]:
			var entry: Dictionary = data["legend"][k]
			var key := str(k)
			var base: Dictionary = DEFAULT_LEGEND.get(key, DEFAULT_LEGEND["."])
			var copy: Dictionary = base.duplicate()
			copy["name"] = str(entry.get("name", ""))
			copy["type"] = str(entry.get("type", ""))
			copy["mult"] = int(entry.get("mult", 1))
			copy["color"] = Color(str(entry.get("color", "#3a2b52")))
			copy["glyph"] = str(entry.get("glyph", base.get("glyph", "")))
			r.legend[key] = copy
	if data.has("letters"):
		for k in data["letters"]:
			var info: Dictionary = data["letters"][k]
			r.letters[str(k).to_upper()] = {
				"count": int(info.get("count", 1)),
				"value": int(info.get("value", 1))
			}
	return r


func premium_at(p: Vector2i) -> Dictionary:
	if p.y >= 0 and p.y < layout.size():
		var row: String = layout[p.y]
		if p.x >= 0 and p.x < row.length():
			return legend.get(row[p.x], legend["."])
	return legend["."]


func letter_value(ch: String) -> int:
	ch = ch.to_upper()
	if letters.has(ch):
		return int(letters[ch]["value"])
	return 0


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if layout.size() != board_size:
		errors.append("layout must have %d rows (found %d)" % [board_size, layout.size()])
	for i in range(layout.size()):
		if String(layout[i]).length() != board_size:
			errors.append("layout row %d must be %d chars" % [i, board_size])
	var star_row := -1
	var star_col := -1
	for y in range(layout.size()):
		var x := String(layout[y]).find("*")
		if x >= 0:
			star_row = y
			star_col = x
			break
	@warning_ignore("integer_division")
	var half := board_size / 2
	if star_row >= 0 and (star_col != half or star_row != half):
		errors.append("center star must sit at column %d row %d; found at column %d row %d" % [half + 1, half + 1, star_col + 1, star_row + 1])
	if letters.is_empty():
		errors.append("letters distribution is empty")
	return errors
