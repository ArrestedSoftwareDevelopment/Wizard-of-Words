extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> void:
	var texture := root.get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image != null:
		image.save_png(path)


func _run() -> void:
	var failures: Array[String] = []
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._show_create()
	main.setup_screen.select_theme("prairie_homestead")
	main._on_theme_changed("prairie_homestead")
	main._on_new_game()
	await create_timer(main.MENU_FADE_SECONDS + 0.15).timeout
	if main.setup_screen.visible:
		failures.append("setup screen remains visible during atmosphere hold")
	if main.game_root != null:
		failures.append("game UI appeared before atmosphere hold completed")
	_capture("res://.godot/theme-transition-soak.png")
	await create_timer(main.ATMOSPHERE_HOLD_SECONDS + main.GAME_FADE_SECONDS + 0.25).timeout
	if main.game_root == null:
		failures.append("game UI did not appear after atmosphere hold")
	elif not is_equal_approx(main.game_root.modulate.a, 1.0):
		failures.append("game UI did not finish fading in")
	_capture("res://.godot/theme-transition-game.png")
	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
