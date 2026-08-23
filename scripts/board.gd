class_name GameBoard
extends RefCounted

var size := 15
var cells: Dictionary = {}


func setup(board_size: int) -> void:
	size = board_size
	cells.clear()


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < size and p.y < size


func tile_at(p: Vector2i) -> Variant:
	if cells.has(p):
		return cells[p]
	return null


func place(p: Vector2i, tile: Dictionary) -> void:
	cells[p] = tile


func remove(p: Vector2i) -> void:
	cells.erase(p)


func tile_count() -> int:
	return cells.size()


func center() -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(size / 2, size / 2)
