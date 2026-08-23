extends SceneTree

const THEME_CATALOG := preload("res://scripts/ui/theme_catalog.gd")
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
	await process_frame
	main.ai_check.button_pressed = false
	main.theme_bonus_check.button_pressed = false
	main._on_new_game()
	await process_frame
	await process_frame

	for theme in THEME_CATALOG.all():
		var theme_id := str(theme.get("id", "unknown"))
		main._apply_theme(theme)
		main.game_hud.apply_theme(theme)
		main._resize_game_board()
		main.refresh_rack()
		await process_frame
		await process_frame
		if main.backdrop_rect.texture == null:
			failures.append("%s backdrop is missing" % theme_id)
		if main.board_shell.frame_rect.visible:
			failures.append("%s unexpectedly shows a legacy frame" % theme_id)
		if main.board_shell.board_view.cell_buttons.size() != main.ruleset.board_size * main.ruleset.board_size:
			failures.append("%s board grid is incomplete" % theme_id)
		if not _capture("res://.godot/theme-%s.png" % theme_id):
			failures.append("%s screenshot failed" % theme_id)

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
