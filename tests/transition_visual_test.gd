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
	await create_timer(main.MENU_FADE_SECONDS + main.BACKDROP_PRE_TITLE_SECONDS + main.TITLE_FADE_IN_SECONDS + 0.1).timeout
	if main.setup_screen.visible:
		failures.append("setup screen remains visible during theme title")
	if main.game_root != null:
		failures.append("game UI appeared before theme title completed")
	if not main.theme_intro_card.visible or main.theme_intro_card.title_label.text != "PRAIRIE HOMESTEAD":
		failures.append("theme title card did not present the selected board")
	_capture("res://.godot/theme-transition-title.png")
	await create_timer(main.TITLE_HOLD_SECONDS + main.TITLE_FADE_OUT_SECONDS + main.BACKDROP_POST_TITLE_SECONDS + main.GAME_FADE_SECONDS + 0.35).timeout
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
