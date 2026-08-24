extends SceneTree

const CAPTURE_SIZE := Vector2i(1680, 1050)


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var texture := root.get_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	return image != null and image.save_png(path) == OK


func _run() -> void:
	var failures: Array[String] = []
	root.mode = Window.MODE_WINDOWED
	root.size = CAPTURE_SIZE
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	main.skip_intro_animation = true
	root.add_child(main)
	await process_frame
	main.ai_check.button_pressed = false
	main.setup_screen.select_theme("velvet_leather")
	main._on_new_game()
	await process_frame
	await process_frame
	main.players[0]["rack"] = [
		{"letter": "", "value": 0, "blank": true},
		{"letter": "A", "value": 1, "blank": false},
		{"letter": "B", "value": 3, "blank": false},
		{"letter": "C", "value": 3, "blank": false},
		{"letter": "D", "value": 2, "blank": false},
		{"letter": "E", "value": 1, "blank": false},
		{"letter": "F", "value": 4, "blank": false},
		{"letter": "G", "value": 2, "blank": false},
	]
	main.refresh_rack()
	main._on_rack_pressed(0)
	main._on_cell_pressed(Vector2i(6, 7))
	await process_frame
	await process_frame
	if main.blank_popup.size.x > 520 or main.blank_popup.size.y > 520:
		failures.append("blank picker is too large for a compact dialogue")
	if main.blank_popup.get_theme_stylebox("panel") == null:
		failures.append("blank picker has no themed panel chrome")
	if not _capture("res://.godot/dialog-blank-picker.png"):
		failures.append("blank picker screenshot failed")
	main.blank_popup.hide()
	main._open_trade()
	await process_frame
	await process_frame
	var first_trade_button: Button = main.trade_box.get_child(0)
	first_trade_button.button_pressed = true
	await process_frame
	if main.trade_dialog.confirm_button.disabled:
		failures.append("trade confirmation did not enable after selection")
	if main.trade_dialog.selection_label.text != "1 rune selected":
		failures.append("trade selection feedback is incorrect")
	if main.trade_popup.size.x > 560 or main.trade_popup.size.y > 420:
		failures.append("trade window is too large for a compact dialogue")
	if not _capture("res://.godot/dialog-trade.png"):
		failures.append("trade dialogue screenshot failed")
	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
