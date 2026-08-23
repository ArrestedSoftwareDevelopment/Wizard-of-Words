class_name GameHud
extends VBoxContainer

signal cast_requested
signal recall_requested
signal shuffle_requested
signal pass_requested
signal trade_requested
signal new_game_requested

const COLOR_PANEL := Color("33245c")
const COLOR_GOLD := Color("e8b23a")
const MIN_HUD_WIDTH := 400.0
const RACK_TILE_WIDTH := 48.0
const RACK_GAP := 6.0
const PANEL_HORIZONTAL_PADDING := 32.0

var rack_box: HBoxContainer
var rack_values_label: Label
var premium_legend_box: HBoxContainer
var score_label: Label
var turn_label: Label
var log_label: Label
var play_button: Button
var recall_button: Button
var shuffle_button: Button
var pass_button: Button
var trade_button: Button
var new_game_button: Button
var panel: PanelContainer
var panel_style: StyleBoxFlat


func _ready() -> void:
	custom_minimum_size = Vector2(MIN_HUD_WIDTH, 0)
	add_theme_constant_override("separation", 10)
	_build()
	set_rack_capacity(8)


func _build() -> void:
	panel = PanelContainer.new()
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.set_content_margin_all(16.0)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	content.add_child(UiFactory.make_title("WIZARD OF WORDS"))
	turn_label = UiFactory.make_body("")
	turn_label.add_theme_color_override("font_color", COLOR_GOLD)
	content.add_child(turn_label)
	score_label = UiFactory.make_body("")
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(score_label)
	content.add_child(HSeparator.new())
	content.add_child(UiFactory.make_caption("Thy rack of runes"))
	rack_box = HBoxContainer.new()
	rack_box.add_theme_constant_override("separation", 6)
	content.add_child(rack_box)
	rack_values_label = UiFactory.make_caption("")
	rack_values_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rack_values_label.custom_minimum_size.y = 20
	content.add_child(rack_values_label)
	content.add_child(UiFactory.make_caption("Sigil key"))
	premium_legend_box = HBoxContainer.new()
	premium_legend_box.add_theme_constant_override("separation", 4)
	premium_legend_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(premium_legend_box)

	var primary_actions := HBoxContainer.new()
	primary_actions.add_theme_constant_override("separation", 8)
	play_button = _action_button("Cast Spell", cast_requested, primary_actions)
	recall_button = _action_button("Recall", recall_requested, primary_actions)
	shuffle_button = _action_button("Shuffle", shuffle_requested, primary_actions)
	content.add_child(primary_actions)

	var turn_actions := HBoxContainer.new()
	turn_actions.add_theme_constant_override("separation", 8)
	pass_button = _action_button("Pass Turn", pass_requested, turn_actions)
	trade_button = _action_button("Trade", trade_requested, turn_actions)
	new_game_button = _action_button("New Game", new_game_requested, turn_actions)
	content.add_child(turn_actions)

	content.add_child(HSeparator.new())
	log_label = UiFactory.make_body("The duel begins...")
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(0, 180)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(log_label)


func set_rack_capacity(capacity: int) -> void:
	if rack_box == null:
		return
	var slots := maxi(1, capacity)
	var reserved_rack_width := float(slots) * RACK_TILE_WIDTH + float(slots - 1) * RACK_GAP
	rack_box.custom_minimum_size.x = reserved_rack_width
	custom_minimum_size.x = maxf(MIN_HUD_WIDTH, reserved_rack_width + PANEL_HORIZONTAL_PADDING)


func set_rack_values(rack: Array) -> void:
	if rack_values_label == null:
		return
	var entries := PackedStringArray()
	for tile in rack:
		var letter := str(tile.get("letter", "?"))
		if letter == "":
			letter = "?"
		entries.append("%s %d" % [letter, int(tile.get("value", 0))])
	rack_values_label.text = "Rune worth  ·  " + "   ·   ".join(entries)


func set_premium_legend(legend: Dictionary, theme: Dictionary) -> void:
	if premium_legend_box == null:
		return
	for child in premium_legend_box.get_children():
		child.queue_free()
	var atlas_path := str(theme.get("premium_glyph_atlas", ""))
	for key in ["d", "t", "*", "D", "T"]:
		var premium: Dictionary = legend.get(key, {})
		var item := VBoxContainer.new()
		item.custom_minimum_size.x = 70
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_theme_constant_override("separation", 0)
		premium_legend_box.add_child(item)
		var icon_holder := Control.new()
		icon_holder.custom_minimum_size = Vector2(38, 38)
		item.add_child(icon_holder)
		var glyph := PremiumGlyph.new()
		if atlas_path != "" and glyph.configure(atlas_path, key):
			icon_holder.add_child(glyph)
		else:
			glyph.queue_free()
			var fallback := UiFactory.make_body(str(premium.get("glyph", "")))
			fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_holder.add_child(fallback)
		var kind := "WORD" if str(premium.get("type", "")) == "word" else "RUNE"
		var caption := UiFactory.make_caption("CENTER" if key == "*" else "%d× %s" % [int(premium.get("mult", 1)), kind])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 11)
		item.add_child(caption)
		item.tooltip_text = str(premium.get("name", ""))


func apply_theme(theme: Dictionary) -> void:
	if panel_style == null:
		return
	var panel_color := Color(str(theme.get("panel_color", COLOR_PANEL.to_html(false))))
	panel_color.a = 0.94
	panel_style.bg_color = panel_color
	var accent := Color(str(theme.get("accent_color", COLOR_GOLD.to_html(false))))
	if turn_label != null:
		turn_label.add_theme_color_override("font_color", accent)


func _action_button(text: String, action: Signal, parent: Control) -> Button:
	var button := UiFactory.make_button(text)
	button.pressed.connect(func(): action.emit())
	parent.add_child(button)
	return button
