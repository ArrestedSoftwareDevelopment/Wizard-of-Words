class_name BlankPicker
extends PopupPanel

const DIALOG_STYLER := preload("res://scripts/ui/dialog_styler.gd")

signal rune_chosen(rune: String)

var title_label: Label
var instruction_label: Label
var note_label: Label
var rune_buttons: Array[Button] = []
var cancel_button: Button


func _ready() -> void:
	title = "Choose a rune for thy blank"
	exclusive = true
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(358, 0)
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	title_label = UiFactory.make_title("CHOOSE A RUNE")
	content.add_child(title_label)
	instruction_label = UiFactory.make_body("Which letter shall the blank become?")
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction_label)
	content.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for index in range(26):
		var rune := char(65 + index)
		var button := Button.new()
		button.text = rune
		button.custom_minimum_size = Vector2(46, 46)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 18)
		button.pressed.connect(func(): rune_chosen.emit(rune))
		grid.add_child(button)
		rune_buttons.append(button)
	note_label = UiFactory.make_caption("Blank runes carry no point value.")
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note_label)
	cancel_button = UiFactory.make_button("Never Mind")
	cancel_button.pressed.connect(hide)
	content.add_child(cancel_button)


func apply_theme(theme: Dictionary) -> void:
	DIALOG_STYLER.apply_popup(self, theme)
	if title_label != null:
		DIALOG_STYLER.apply_heading(title_label, theme)
	if note_label != null:
		DIALOG_STYLER.apply_caption(note_label, theme)
	for button in rune_buttons:
		DIALOG_STYLER.apply_button(button, theme)
	if cancel_button != null:
		DIALOG_STYLER.apply_button(cancel_button, theme)
