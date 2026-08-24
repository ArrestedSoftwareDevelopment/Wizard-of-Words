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
		main.ruleset.layout = THEME_CATALOG.board_layout(theme_id)
		main.game_hud.apply_theme(theme)
		main.game_hud.set_premium_legend(main.ruleset.legend, theme)
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
		var center: Button = main.board_shell.board_view.cell_buttons[Vector2i(main.ruleset.board_size / 2, main.ruleset.board_size / 2)]
		if center.find_children("*", "PremiumGlyph", true, false).is_empty():
			failures.append("%s premium glyph atlas was not applied" % theme_id)
		if center.has_meta("value_label") or center.has_meta("hover_connected"):
			failures.append("%s premium cell still contains the tiny hover legend" % theme_id)
		if main.game_hud.premium_legend_box.get_child_count() != 5:
			failures.append("%s shelf sigil key is incomplete" % theme_id)
		var empty_cell: Button = main.board_shell.board_view.cell_buttons[Vector2i(1, 0)]
		var empty_textures := empty_cell.find_children("*", "TextureRect", true, false)
		if empty_textures.is_empty() or not is_equal_approx(empty_textures[0].self_modulate.a, main.EMPTY_BOARD_OPACITY):
			failures.append("%s empty board cells are not translucent" % theme_id)
		var hover_style = empty_cell.get_theme_stylebox("hover")
		if hover_style is StyleBoxFlat and not is_equal_approx(hover_style.bg_color.a, 0.0):
			failures.append("%s empty board hover becomes opaque" % theme_id)
		var solid_probe := Vector2i(1, 0)
		main.board.place(solid_probe, {"letter": "A", "value": 1, "blank": false})
		main.refresh_board()
		var placed_cell: Button = main.board_shell.board_view.cell_buttons[solid_probe]
		var placed_textures := placed_cell.find_children("*", "TextureRect", true, false)
		if placed_textures.is_empty() or not is_equal_approx(placed_textures[0].self_modulate.a, 1.0):
			failures.append("%s placed letter tiles are not opaque" % theme_id)
		main.board.remove(solid_probe)
		main.refresh_board()
		if not _capture("res://.godot/theme-%s.png" % theme_id):
			failures.append("%s screenshot failed" % theme_id)

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
