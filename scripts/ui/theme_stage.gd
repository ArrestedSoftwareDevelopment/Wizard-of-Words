class_name ThemeStage
extends TextureRect

signal layout_changed

const DEFAULT_CELL_SIZE := 44.0
const MAX_CELL_SIZE := 68.0
const HUD_WIDTH := 460.0
const GAME_MARGIN := 24.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(func(): layout_changed.emit())


func apply_theme(theme: Dictionary) -> void:
	texture = UiFactory.load_texture_any(str(theme.get("backdrop", "")))


func calculate_cell_size(board_size: int, grid_gap: int) -> float:
	if board_size <= 0:
		return DEFAULT_CELL_SIZE
	var viewport_size := get_viewport_rect().size
	var width_budget := maxf(480.0, viewport_size.x - HUD_WIDTH - GAME_MARGIN * 3.0)
	var height_budget := maxf(480.0, viewport_size.y - GAME_MARGIN * 2.0)
	var grid_budget := minf(width_budget, height_budget) - 12.0
	var gaps := float(maxi(0, board_size - 1) * grid_gap)
	return clampf(floorf((grid_budget - gaps) / float(board_size)), 30.0, MAX_CELL_SIZE)
