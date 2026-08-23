extends SceneTree


func _initialize() -> void:
	var failures: Array = []
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main.ai_check.button_pressed = false
	for cb in main.lexicon_checks:
		if str(cb.get_meta("file")) == "common_english.txt":
			cb.button_pressed = true
	main._on_new_game()
	await process_frame

	main.players[0]["rack"] = [
		{"letter": "", "value": 0, "blank": true},
		{"letter": "A", "value": 1, "blank": false},
	]
	main.refresh_rack()

	main._on_rack_pressed(0)
	main._on_cell_pressed(Vector2i(6, 7))
	await process_frame

	print("popup visible: ", main.blank_popup.visible)
	print("blank_target: ", main.blank_target)
	if not main.blank_popup.visible:
		failures.append("blank popup did not open")

	main._on_blank_chosen("Z")
	await process_frame

	if not main.pending.has(Vector2i(6, 7)):
		failures.append("blank was not placed into pending")
	else:
		print("pending blank letter: ", main.pending[Vector2i(6, 7)]["tile"]["letter"])
		if main.pending[Vector2i(6, 7)]["tile"]["letter"] != "Z":
			failures.append("blank letter not assigned")

	main._on_rack_pressed(0)
	main._on_cell_pressed(Vector2i(7, 7))
	await process_frame
	main._on_play()
	await process_frame

	var top_log: String = main.log_label.text.split("\n")[0]
	print("log: ", top_log)
	if main.board.tile_count() != 2:
		failures.append("ZA spell did not commit; last log: %s" % top_log)

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
