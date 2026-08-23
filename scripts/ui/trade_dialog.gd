class_name TradeDialog
extends PopupPanel

signal confirmed

var trade_box: HBoxContainer


func _ready() -> void:
	title = "Trade Runes"
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.custom_minimum_size = Vector2(320, 0)
	add_child(content)
	content.add_child(UiFactory.make_caption("Choose runes to sacrifice to the bag"))
	trade_box = HBoxContainer.new()
	trade_box.add_theme_constant_override("separation", 6)
	content.add_child(trade_box)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	var confirm := UiFactory.make_button("Trade Them")
	confirm.pressed.connect(func(): confirmed.emit())
	actions.add_child(confirm)
	var cancel := UiFactory.make_button("Never Mind")
	cancel.pressed.connect(hide)
	actions.add_child(cancel)
	content.add_child(actions)


func populate(rack: Array, selection: Dictionary) -> void:
	selection.clear()
	for child in trade_box.get_children():
		child.queue_free()
	for index in range(rack.size()):
		var tile: Dictionary = rack[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(44, 50)
		button.toggle_mode = true
		button.text = tile["letter"] if tile["letter"] != "" else "?"
		button.toggled.connect(func(on: bool):
			if on:
				selection[index] = true
			else:
				selection.erase(index))
		trade_box.add_child(button)
