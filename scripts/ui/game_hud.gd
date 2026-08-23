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

var rack_box: HBoxContainer
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
	custom_minimum_size = Vector2(400, 0)
	add_theme_constant_override("separation", 10)
	_build()


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
