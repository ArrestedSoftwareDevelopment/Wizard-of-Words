class_name BoardView
extends GridContainer

signal cell_pressed(pos: Vector2i)

var cell_buttons: Dictionary = {}
var _interaction_host: Variant = null


func setup(board_size: int, cell_size: float, interaction_host: Variant, gap := 2) -> void:
	_interaction_host = interaction_host
	columns = board_size
	add_theme_constant_override("h_separation", gap)
	add_theme_constant_override("v_separation", gap)
	_clear_cells()

	var grid_extent := board_size * cell_size + maxi(0, board_size - 1) * gap
	custom_minimum_size = Vector2(grid_extent, grid_extent)
	for y in range(board_size):
		for x in range(board_size):
			var pos := Vector2i(x, y)
			var button := CellButton.new()
			button.game = _interaction_host
			button.cell_pos = pos
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			button.focus_mode = Control.FOCUS_NONE
			button.pressed.connect(_emit_cell_pressed.bind(pos))
			add_child(button)
			cell_buttons[pos] = button


func _emit_cell_pressed(pos: Vector2i) -> void:
	cell_pressed.emit(pos)


func _clear_cells() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	cell_buttons.clear()
