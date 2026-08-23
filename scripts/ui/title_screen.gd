class_name TitleScreen
extends Control

signal quick_play_requested
signal create_requested

const TITLE_ART_PATHS := [
	"res://data/graphics/title screens/Title Screen 2.png",
	"res://data/graphics/title screens/titlescreen1.png"
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	var art_path := ""
	for candidate in TITLE_ART_PATHS:
		if FileAccess.file_exists(candidate):
			art_path = candidate
			break
	var has_art := not art_path.is_empty()
	if has_art:
		var texture := UiFactory.load_texture_any(art_path)
		if texture != null:
			var art := TextureRect.new()
			art.texture = texture
			art.set_anchors_preset(Control.PRESET_FULL_RECT)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_SCALE
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(art)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.custom_minimum_size = Vector2(420, 0)
	buttons.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	buttons.grow_horizontal = Control.GROW_DIRECTION_BOTH
	buttons.grow_vertical = Control.GROW_DIRECTION_BEGIN
	buttons.offset_bottom = -48
	add_child(buttons)

	if not has_art:
		buttons.add_child(UiFactory.make_title("WIZARD OF WORDS"))
		buttons.add_child(UiFactory.make_caption("A duel of runes upon a living sigil"))

	var quick := UiFactory.make_button("Quick Play")
	quick.custom_minimum_size = Vector2(280, 0)
	quick.pressed.connect(func(): quick_play_requested.emit())
	buttons.add_child(quick)

	var create := UiFactory.make_button("Create")
	create.custom_minimum_size = Vector2(280, 0)
	create.pressed.connect(func(): create_requested.emit())
	buttons.add_child(create)

	if not has_art:
		var credit := UiFactory.make_caption("Code sorcery by ox-alpha, an LLM of undisclosed origin")
		credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buttons.add_child(credit)
