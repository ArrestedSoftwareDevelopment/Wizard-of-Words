class_name ThemeIntroCard
extends Control

const MIN_TITLE_SIZE := 64
const MAX_TITLE_SIZE := 180
const TITLE_WIDTH_RATIO := 0.86

var title_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	title_label = Label.new()
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_constant_override("outline_size", 10)
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 6)
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	add_child(title_label)


func configure(theme: Dictionary) -> void:
	var title := str(theme.get("title", theme.get("id", "Wizard of Words")))
	title_label.text = title.to_upper()
	title_label.add_theme_color_override("font_color", Color(str(theme.get("title_color", theme.get("accent_color", "#f4df9b")))))
	title_label.add_theme_color_override("font_outline_color", Color(str(theme.get("title_outline_color", "#160f18"))))

	var font := _load_font(str(theme.get("title_font", "")))
	if font != null:
		title_label.add_theme_font_override("font", font)
	else:
		title_label.remove_theme_font_override("font")
	_fit_title(title, font)


func play(theme: Dictionary, fade_in_seconds: float, hold_seconds: float, fade_out_seconds: float) -> void:
	configure(theme)
	modulate.a = 0.0
	visible = true
	var entrance := create_tween()
	entrance.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	entrance.tween_property(self, "modulate:a", 1.0, fade_in_seconds)
	await entrance.finished
	await get_tree().create_timer(hold_seconds).timeout
	var exit_tween := create_tween()
	exit_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(self, "modulate:a", 0.0, fade_out_seconds)
	await exit_tween.finished
	visible = false


func _fit_title(title: String, font: Font) -> void:
	var viewport_width := get_viewport_rect().size.x
	var viewport_height := get_viewport_rect().size.y
	var size := clampi(int(viewport_height * 0.15), MIN_TITLE_SIZE, MAX_TITLE_SIZE)
	if font != null:
		var width_limit := viewport_width * TITLE_WIDTH_RATIO
		while size > MIN_TITLE_SIZE and font.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width_limit:
			size -= 2
	title_label.add_theme_font_size_override("font_size", size)


func _load_font(path: String) -> FontFile:
	if path == "" or not FileAccess.file_exists(path):
		return null
	var font := FontFile.new()
	return font if font.load_dynamic_font(path) == OK else null
