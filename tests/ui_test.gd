extends SceneTree


func _initialize() -> void:
	var failures: Array = []
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main._on_new_game()
	await process_frame

	if main.lexicon == null or main.lexicon.size() < 100000:
		failures.append("merged lexicon too small")
	else:
		print("lexicon ok: ", main.lexicon.size())

	main.players[0]["rack"] = [
		{"letter": "C", "value": 3, "blank": false},
		{"letter": "A", "value": 1, "blank": false},
		{"letter": "T", "value": 1, "blank": false},
		{"letter": "Q", "value": 10, "blank": false},
	]
	main.refresh_rack()

	var cells := [Vector2i(7, 5), Vector2i(7, 6), Vector2i(7, 7)]
	for c in cells:
		main._on_rack_pressed(0)
		main._on_cell_pressed(c)
	await process_frame

	main._on_play()
	await process_frame

	var top_log: String = main.log_label.text.split("\n")[0]
	print("log: ", top_log)

	if main.board.tile_count() != 3:
		failures.append("vertical opening did not commit; last log: %s" % top_log)

	main.players[1]["rack"] = [
		{"letter": "A", "value": 1, "blank": false},
		{"letter": "E", "value": 1, "blank": false},
		{"letter": "N", "value": 1, "blank": false},
		{"letter": "O", "value": 1, "blank": false},
		{"letter": "R", "value": 1, "blank": false},
		{"letter": "S", "value": 1, "blank": false},
		{"letter": "T", "value": 1, "blank": false},
		{"letter": "M", "value": 3, "blank": false},
	]

	print("waiting for AI turn...")
	var waited := 0.0
	while main.board.tile_count() <= 3 and waited < 12.0:
		await create_timer(1.0).timeout
		waited += 1.0
	await process_frame

	if main.board.tile_count() <= 3:
		failures.append("AI move never appeared on board (%d tiles)" % main.board.tile_count())
	else:
		print("AI placed; board tiles now: ", main.board.tile_count())

	var ai_rack: Array = main.players[1]["rack"]
	if ai_rack.size() != main.ruleset.rack_size:
		failures.append("AI rack not refilled: %d" % ai_rack.size())
	else:
		print("AI rack refilled to ", ai_rack.size())

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
