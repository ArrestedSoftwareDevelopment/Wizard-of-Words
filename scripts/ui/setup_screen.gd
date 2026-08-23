class_name SetupScreen
extends CenterContainer

signal begin_requested
signal back_requested
signal visual_theme_changed(theme_id: String)

const THEME_CATALOG := preload("res://scripts/ui/theme_catalog.gd")

const COLOR_PANEL := Color("33245c")

var panel: PanelContainer
var ruleset_select: OptionButton
var ruleset_preview: TextureRect
var lexicon_checks: Array = []
var theme_select: OptionButton
var theme_preview: TextureRect
var theme_bonus_check: CheckButton
var ai_check: CheckButton
var ai_difficulty_select: OptionButton
var fog_check: CheckButton
var begin_button: Button
var dict_meta: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _build() -> void:
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.set_corner_radius_all(12)
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 820)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)

	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(560, 0)
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	content.add_child(UiFactory.make_title("WIZARD OF WORDS"))
	content.add_child(UiFactory.make_caption("Forge thy spell from runes and grimoires"))
	content.add_child(UiFactory.make_caption("Ruleset"))

	var ruleset_row := HBoxContainer.new()
	ruleset_row.add_theme_constant_override("separation", 10)
	content.add_child(ruleset_row)
	var ruleset_column := VBoxContainer.new()
	ruleset_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ruleset_row.add_child(ruleset_column)
	ruleset_select = OptionButton.new()
	for filename in UiFactory.list_files("res://data/rulesets", ["json"]):
		ruleset_select.add_item(filename)
	ruleset_select.item_selected.connect(func(_index: int): update_ruleset_preview())
	ruleset_column.add_child(ruleset_select)
	ruleset_preview = TextureRect.new()
	ruleset_preview.custom_minimum_size = Vector2(96, 96)
	ruleset_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruleset_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruleset_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ruleset_row.add_child(ruleset_preview)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	content.add_child(columns)
	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.add_theme_constant_override("separation", 6)
	columns.add_child(left_column)
	var right_column := VBoxContainer.new()
	right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_column.add_theme_constant_override("separation", 6)
	columns.add_child(right_column)
	left_column.add_child(UiFactory.make_caption("Grimoires"))
	_build_lexicon_choices(left_column)
	right_column.add_child(UiFactory.make_caption("Visual Theme"))
	theme_select = OptionButton.new()
	for theme in THEME_CATALOG.all():
		theme_select.add_item(str(theme.get("title", theme.get("id", "Theme"))))
		theme_select.set_item_metadata(theme_select.item_count - 1, str(theme.get("id", "")))
	theme_select.item_selected.connect(_on_theme_selected)
	right_column.add_child(theme_select)
	theme_preview = TextureRect.new()
	theme_preview.custom_minimum_size = Vector2(250, 141)
	theme_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	theme_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	theme_preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	right_column.add_child(theme_preview)
	theme_bonus_check = CheckButton.new()
	theme_bonus_check.text = "Theme Word Bonuses"
	theme_bonus_check.tooltip_text = "Award the selected theme's vocabulary bonus when matching words are played."
	theme_bonus_check.button_pressed = true
	right_column.add_child(theme_bonus_check)

	ai_check = CheckButton.new()
	ai_check.text = "Face the Word Wizard (AI)"
	ai_check.button_pressed = true
	content.add_child(ai_check)
	content.add_child(UiFactory.make_caption("Wizard Difficulty"))
	ai_difficulty_select = OptionButton.new()
	for difficulty in ["Apprentice", "Adept", "Archmage"]:
		ai_difficulty_select.add_item(difficulty)
	ai_difficulty_select.selected = 1
	content.add_child(ai_difficulty_select)

	fog_check = CheckButton.new()
	fog_check.text = "Fog of War"
	fog_check.tooltip_text = "Bonus squares stay hidden until revealed near recently played tiles."
	content.add_child(fog_check)

	begin_button = UiFactory.make_button("Begin the Duel")
	begin_button.pressed.connect(func(): begin_requested.emit())
	content.add_child(begin_button)
	var back := UiFactory.make_button("Return to Title")
	back.pressed.connect(func(): back_requested.emit())
	content.add_child(back)
	var credit := UiFactory.make_caption("Code sorcery by ox-alpha, an LLM of undisclosed origin")
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(credit)
	update_ruleset_preview()
	update_theme_preview()


func _build_lexicon_choices(left_column: VBoxContainer) -> void:
	var metadata_path := "res://data/dictionaries/index.json"
	if FileAccess.file_exists(metadata_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if parsed is Dictionary:
			dict_meta = parsed
	for filename in UiFactory.list_files("res://data/dictionaries", ["txt", "json"]):
		if filename == "index.json" or filename.begins_with("profanity_") or filename.begins_with("two_letter_"):
			continue
		var checkbox := CheckBox.new()
		checkbox.text = filename.get_basename().replace("_", " ").capitalize()
		checkbox.set_meta("file", filename)
		var info: Dictionary = dict_meta.get(filename, {})
		if info.is_empty():
			info = dict_meta.get(filename.get_basename(), {})
		if info.has("bonus_points"):
			continue
		checkbox.button_pressed = bool(info.get("default_checked", true))
		if not info.is_empty():
			checkbox.tooltip_text = str(info.get("title", "")) + "\n" + str(info.get("description", ""))
		lexicon_checks.append(checkbox)
		left_column.add_child(checkbox)


func selected_theme_id() -> String:
	if theme_select == null or theme_select.selected < 0:
		return str(THEME_CATALOG.default_theme().get("id", "wizardry"))
	return str(theme_select.get_item_metadata(theme_select.selected))


func select_theme(theme_id: String) -> void:
	if theme_select == null:
		return
	for index in range(theme_select.item_count):
		if str(theme_select.get_item_metadata(index)) == theme_id:
			theme_select.select(index)
			update_theme_preview()
			return


func _on_theme_selected(_index: int) -> void:
	update_theme_preview()
	visual_theme_changed.emit(selected_theme_id())


func update_theme_preview() -> void:
	if theme_preview == null:
		return
	var theme: Dictionary = THEME_CATALOG.find(selected_theme_id())
	theme_preview.texture = UiFactory.load_texture_any(str(theme.get("backdrop", "")))
	var bonus_file := str(theme.get("bonus_lexicon", ""))
	theme_bonus_check.disabled = bonus_file == ""
	theme_bonus_check.text = "Theme Word Bonuses" if bonus_file != "" else "Theme Word Bonuses (vocabulary pending)"
	theme_bonus_check.tooltip_text = (
		"Award the selected theme's vocabulary bonus when matching words are played."
		if bonus_file != ""
		else "This theme's custom bonus vocabulary has not been curated yet."
	)


func update_ruleset_preview() -> void:
	if ruleset_preview == null or ruleset_select.item_count == 0 or ruleset_select.selected < 0:
		return
	var path := "res://data/rulesets/" + ruleset_select.get_item_text(ruleset_select.selected)
	var selected_ruleset := WordRuleset.load_from(path)
	if selected_ruleset == null:
		return
	var board_size: int = selected_ruleset.board_size
	var image := Image.create(board_size, board_size, false, Image.FORMAT_RGBA8)
	image.fill(Color("241a38"))
	for y in range(board_size):
		if y >= selected_ruleset.layout.size():
			continue
		var row := String(selected_ruleset.layout[y])
		for x in range(mini(row.length(), board_size)):
			var premium: Dictionary = selected_ruleset.legend.get(row[x], selected_ruleset.legend["."])
			image.set_pixel(x, y, premium["color"])
	ruleset_preview.texture = ImageTexture.create_from_image(image)
	if fog_check != null:
		fog_check.button_pressed = selected_ruleset.fog_of_war
