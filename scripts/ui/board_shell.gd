class_name BoardShell
extends Control

signal cell_pressed(pos: Vector2i)

const FRAME_CATALOG_PATH := "res://data/graphics/frames/index.json"
const DEFAULT_FRAME_RATIOS := {"left": 0.18, "top": 0.18, "right": 0.18, "bottom": 0.18}
const FRAMELESS_INSETS := {"left": 6, "top": 6, "right": 6, "bottom": 6}
const MAX_FRAMED_EXTENT := 800.0

@onready var frame_rect: TextureRect = %Frame
@onready var content_margin: MarginContainer = %ContentMargin
@onready var board_panel: PanelContainer = %BoardPanel
@onready var board_view: BoardView = %BoardView

var applied_insets: Dictionary = {}


func _ready() -> void:
	board_view.cell_pressed.connect(func(pos: Vector2i): cell_pressed.emit(pos))


func configure(skin: Dictionary, board_size: int, cell_size: float, interaction_host: Variant, gap := 2) -> void:
	var frame_path := String(skin.get("frame", ""))
	var frame_texture := _load_texture_any(frame_path)
	var effective_cell_size := cell_size
	if frame_texture != null:
		var ratios := _resolve_frame_ratios(skin, frame_path)
		applied_insets = {
			"left": roundi(float(ratios["left"]) * MAX_FRAMED_EXTENT),
			"top": roundi(float(ratios["top"]) * MAX_FRAMED_EXTENT),
			"right": roundi(float(ratios["right"]) * MAX_FRAMED_EXTENT),
			"bottom": roundi(float(ratios["bottom"]) * MAX_FRAMED_EXTENT)
		}
		var inner_width := MAX_FRAMED_EXTENT - float(applied_insets["left"] + applied_insets["right"])
		var inner_height := MAX_FRAMED_EXTENT - float(applied_insets["top"] + applied_insets["bottom"])
		var inner_extent: float = minf(inner_width, inner_height)
		effective_cell_size = minf(cell_size, floorf((inner_extent - maxi(0, board_size - 1) * gap) / board_size))
	else:
		applied_insets = FRAMELESS_INSETS.duplicate()
	_apply_insets(applied_insets)

	frame_rect.visible = frame_texture != null
	frame_rect.texture = frame_texture

	_apply_board_background(String(skin.get("background", "")), skin)
	board_view.setup(board_size, effective_cell_size, interaction_host, gap)
	board_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board_view.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if frame_texture != null:
		custom_minimum_size = Vector2(MAX_FRAMED_EXTENT, MAX_FRAMED_EXTENT)
	else:
		var horizontal := float(applied_insets["left"] + applied_insets["right"])
		var vertical := float(applied_insets["top"] + applied_insets["bottom"])
		custom_minimum_size = board_view.custom_minimum_size + Vector2(horizontal, vertical)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _resolve_frame_ratios(skin: Dictionary, frame_path: String) -> Dictionary:
	if skin.has("frame_content_ratios") and skin["frame_content_ratios"] is Dictionary:
		return _normalized_ratios(skin["frame_content_ratios"])
	var catalog := _load_frame_catalog()
	var filename := frame_path.get_file()
	if catalog.has(filename) and catalog[filename] is Dictionary:
		var entry: Dictionary = catalog[filename]
		if entry.has("content_ratios") and entry["content_ratios"] is Dictionary:
			return _normalized_ratios(entry["content_ratios"])
	return DEFAULT_FRAME_RATIOS.duplicate()


func _normalized_ratios(raw: Dictionary) -> Dictionary:
	return {
		"left": clampf(float(raw.get("left", DEFAULT_FRAME_RATIOS["left"])), 0.0, 0.45),
		"top": clampf(float(raw.get("top", DEFAULT_FRAME_RATIOS["top"])), 0.0, 0.45),
		"right": clampf(float(raw.get("right", DEFAULT_FRAME_RATIOS["right"])), 0.0, 0.45),
		"bottom": clampf(float(raw.get("bottom", DEFAULT_FRAME_RATIOS["bottom"])), 0.0, 0.45)
	}


func _apply_insets(insets: Dictionary) -> void:
	content_margin.add_theme_constant_override("margin_left", int(insets["left"]))
	content_margin.add_theme_constant_override("margin_top", int(insets["top"]))
	content_margin.add_theme_constant_override("margin_right", int(insets["right"]))
	content_margin.add_theme_constant_override("margin_bottom", int(insets["bottom"]))


func _apply_board_background(path: String, skin: Dictionary) -> void:
	var texture := _load_texture_any(path)
	if texture != null:
		var textured := StyleBoxTexture.new()
		textured.texture = texture
		board_panel.add_theme_stylebox_override("panel", textured)
		return
	var fallback := StyleBoxFlat.new()
	fallback.bg_color = Color(str(skin.get("board_color", "#1c1430")))
	fallback.bg_color.a = 0.0
	fallback.border_color = Color(str(skin.get("board_border_color", "#b58b42")))
	fallback.set_border_width_all(2)
	fallback.set_corner_radius_all(6)
	fallback.shadow_color = Color(0, 0, 0, 0.65)
	fallback.shadow_size = 8
	board_panel.add_theme_stylebox_override("panel", fallback)


func _load_frame_catalog() -> Dictionary:
	if not FileAccess.file_exists(FRAME_CATALOG_PATH):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(FRAME_CATALOG_PATH))
	return parsed if parsed is Dictionary else {}


func _load_texture_any(path: String) -> Texture2D:
	if path == "":
		return null
	var loaded: Variant = load(path)
	if loaded is Texture2D:
		return loaded
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null
