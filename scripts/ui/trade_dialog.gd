class_name TradeDialog
extends PopupPanel

const DIALOG_STYLER := preload("res://scripts/ui/dialog_styler.gd")

signal confirmed

var trade_box: HBoxContainer
var title_label: Label
var instruction_label: Label
var selection_label: Label
var confirm_button: Button
var cancel_button: Button
var _theme: Dictionary = {}


func _ready() -> void:
	title = "Trade Runes"
	exclusive = true
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.custom_minimum_size = Vector2(426, 0)
	margin.add_child(content)
	title_label = UiFactory.make_title("TRADE RUNES")
	content.add_child(title_label)
	instruction_label = UiFactory.make_body("Choose the runes to return to the bag.")
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(instruction_label)
	content.add_child(HSeparator.new())
	trade_box = HBoxContainer.new()
	trade_box.add_theme_constant_override("separation", 6)
	trade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(trade_box)
	selection_label = UiFactory.make_caption("No runes selected")
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(selection_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_button = UiFactory.make_button("Trade Selected")
	confirm_button.disabled = true
	confirm_button.pressed.connect(func(): confirmed.emit())
	actions.add_child(confirm_button)
	cancel_button = UiFactory.make_button("Never Mind")
	cancel_button.pressed.connect(hide)
	actions.add_child(cancel_button)
	content.add_child(actions)


func populate(rack: Array, selection: Dictionary) -> void:
	selection.clear()
	_update_selection_status(selection)
	for child in trade_box.get_children():
		child.queue_free()
	for index in range(rack.size()):
		var tile: Dictionary = rack[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(48, 56)
		button.toggle_mode = true
		button.text = tile["letter"] if tile["letter"] != "" else "?"
		button.tooltip_text = "%d points" % int(tile.get("value", 0))
		button.add_theme_font_size_override("font_size", 19)
		button.toggled.connect(func(on: bool):
			if on:
				selection[index] = true
			else:
				selection.erase(index)
			_update_selection_status(selection))
		trade_box.add_child(button)
		if not _theme.is_empty():
			DIALOG_STYLER.apply_button(button, _theme)


func apply_theme(theme: Dictionary) -> void:
	_theme = theme.duplicate(true)
	DIALOG_STYLER.apply_popup(self, theme)
	if title_label != null:
		DIALOG_STYLER.apply_heading(title_label, theme)
	if selection_label != null:
		DIALOG_STYLER.apply_caption(selection_label, theme)
	if confirm_button != null:
		DIALOG_STYLER.apply_button(confirm_button, theme)
	if cancel_button != null:
		DIALOG_STYLER.apply_button(cancel_button, theme)
	for button in trade_box.get_children():
		if button is Button:
			DIALOG_STYLER.apply_button(button, theme)


func _update_selection_status(selection: Dictionary) -> void:
	if selection_label == null or confirm_button == null:
		return
	var count := selection.size()
	selection_label.text = "No runes selected" if count == 0 else "%d rune%s selected" % [count, "" if count == 1 else "s"]
	confirm_button.disabled = count == 0
