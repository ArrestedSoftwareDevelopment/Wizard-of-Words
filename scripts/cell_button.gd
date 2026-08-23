class_name CellButton
extends Button

var game
var cell_pos := Vector2i.ZERO


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if game == null:
		return false
	return game.can_drop(cell_pos, data)


func _drop_data(_at: Vector2, data: Variant) -> void:
	game.handle_drop(cell_pos, data)


func _get_drag_data(_at: Vector2) -> Variant:
	if game == null:
		return null
	return game.get_board_drag(cell_pos)
