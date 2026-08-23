extends SceneTree

const THEME_CATALOG := preload("res://scripts/ui/theme_catalog.gd")


func _initialize() -> void:
	call_deferred("_run")


func _capture(path: String) -> bool:
	var texture := root.get_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	return image != null and image.save_png(path) == OK


func _run() -> void:
	var failures: Array[String] = []
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.title_screen.visible = false
	main.setup_screen.visible = false
	main.theme_intro_card.visible = true
	main.theme_intro_card.modulate.a = 1.0
	for theme in THEME_CATALOG.all():
		var theme_id := str(theme.get("id", "unknown"))
		main._apply_theme(theme)
		main.theme_intro_card.configure(theme)
		await process_frame
		if main.theme_intro_card.title_label.text == "":
			failures.append("%s title is empty" % theme_id)
		if not _capture("res://.godot/theme-intro-%s.png" % theme_id):
			failures.append("%s title screenshot failed" % theme_id)
	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
