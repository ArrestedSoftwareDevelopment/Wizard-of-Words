extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var texture := root.get_texture()
	if texture == null:
		return
	var image := texture.get_image()
	if image != null:
		image.save_png(path)


func _run() -> void:
	var failures: Array[String] = []
	if int(ProjectSettings.get_setting("display/window/size/mode", 0)) != 3:
		failures.append("fullscreen is not the default window mode")
	if str(ProjectSettings.get_setting("display/window/stretch/mode", "")) != "canvas_items":
		failures.append("canvas scaling is not enabled")
	if str(ProjectSettings.get_setting("display/window/stretch/aspect", "")) != "expand":
		failures.append("expanded aspect scaling is not enabled")
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	if not main.title_screen is TitleScreen or main.title_center != main.title_screen:
		failures.append("title screen was not extracted or aliased")
	if not main.setup_screen is SetupScreen or main.setup_panel != main.setup_screen.panel:
		failures.append("setup screen was not extracted or aliased")
	if not main.blank_popup is BlankPicker:
		failures.append("blank picker was not extracted")
	_capture("res://.godot/phase2-title.png")

	main._show_create()
	await process_frame
	if not main.setup_screen.visible or main.title_screen.visible:
		failures.append("create screen visibility is incorrect")
	if main.setup_screen.theme_select.item_count != 7:
		failures.append("setup screen does not expose all seven themes")
	if main.setup_screen.theme_preview.texture == null:
		failures.append("setup theme preview did not load")
	main.setup_screen.select_theme("prairie_homestead")
	if main.setup_screen.theme_bonus_check.disabled:
		failures.append("Prairie bonus vocabulary should be available")
	main.setup_screen.select_theme("velvet_leather")
	if main.setup_screen.theme_bonus_check.disabled:
		failures.append("Velvet bonus vocabulary should be available")
	main.setup_screen.select_theme("wizardry")
	if main.setup_screen.theme_bonus_check.disabled:
		failures.append("Wizardry bonus vocabulary should be available")
	_capture("res://.godot/phase2-setup.png")

	main._on_new_game()
	await process_frame
	await process_frame
	if not main.game_hud is GameHud or main.rack_box != main.game_hud.rack_box:
		failures.append("game HUD was not extracted or aliased")
	if main.backdrop_rect.texture == null:
		failures.append("game backdrop did not load")
	if main.board_shell.frame_rect.visible:
		failures.append("legacy ornate frame should be hidden during themed play")
	main._ensure_trade_popup()
	if not main.trade_popup is TradeDialog or main.trade_box != main.trade_dialog.trade_box:
		failures.append("trade dialog was not extracted or aliased")
	_capture("res://.godot/phase2-game.png")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
