class_name BlankPicker
extends PopupPanel

signal rune_chosen(rune: String)


func _ready() -> void:
	title = "Choose a rune for thy blank"
	var content := VBoxContainer.new()
	add_child(content)
	content.add_child(UiFactory.make_caption("The blank takes which rune's power?"))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	content.add_child(grid)
	for index in range(26):
		var rune := char(65 + index)
		var button := Button.new()
		button.text = rune
		button.custom_minimum_size = Vector2(44, 44)
		button.pressed.connect(func(): rune_chosen.emit(rune))
		grid.add_child(button)
