extends SceneTree


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
	root.size = Vector2i(1680, 1050)
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	main.skip_intro_animation = true
	root.add_child(main)
	await process_frame
	await process_frame
	main._show_create()
	main.setup_screen.select_theme("pirate")
	main._on_theme_changed("pirate")
	main.ai_check.button_pressed = false
	main._on_new_game()
	await process_frame
	await process_frame

	var event := MatchEvent.create("move_committed", {
		"player_index": 0,
		"score": 24,
		"words": ["TIDE"],
		"positions": [{"x": 6, "y": 7}, {"x": 7, "y": 7}, {"x": 8, "y": 7}, {"x": 9, "y": 7}],
		"bonus_hits": [{"label": "Buried treasure", "points": 5, "words": ["TIDE"]}],
	}, 99)
	main.effect_director.present([event], {"match_id": "visual-fixture"})
	await create_timer(0.12).timeout
	var active_count: int = main.effect_layer.board_canvas.get_child_count() + main.effect_layer.foreground_canvas.get_child_count()
	if active_count != 3:
		failures.append("expected three visible pirate cues, found %d" % active_count)
	if not _capture("res://.godot/effect-pirate.png"):
		failures.append("effect screenshot failed")
	await create_timer(1.35).timeout
	if main.effect_layer.board_canvas.get_child_count() != 0 or main.effect_layer.foreground_canvas.get_child_count() != 0:
		failures.append("transient cues did not clean themselves up")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
