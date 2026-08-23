class_name RackTileButton
extends Button

var game
var rack_index := -1


func _get_drag_data(_at: Vector2) -> Variant:
	if disabled or game == null:
		return null
	var data: Dictionary = game.get_rack_drag(rack_index)
	if data.is_empty():
		return null
	var t: Dictionary = game.players[game.current]["rack"][rack_index]
	var preview := Button.new()
	preview.text = t["letter"] if t["letter"] != "" else "?"
	preview.custom_minimum_size = Vector2(48, 56)
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = Vector2(-24, -28)
	set_drag_preview(holder)
	return data


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if game == null:
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var k := String(data.get("kind", ""))
	return k == "rack" or k == "board"


func _drop_data(_at: Vector2, data: Variant) -> void:
	match String(data.get("kind", "")):
		"rack":
			game.reorder_rack(int(data["index"]), rack_index)
		"board":
			game.recall_tile(Vector2i(data["pos"]))
