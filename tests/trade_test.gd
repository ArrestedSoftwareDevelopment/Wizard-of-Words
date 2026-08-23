extends SceneTree


func _initialize() -> void:
	var failures: Array = []
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame

	main.ai_check.button_pressed = false
	main._on_new_game()
	await process_frame

	main.players[0]["rack"] = [
		{"letter": "Q", "value": 10, "blank": false},
		{"letter": "Z", "value": 10, "blank": false},
		{"letter": "X", "value": 8, "blank": false},
		{"letter": "V", "value": 4, "blank": false},
		{"letter": "A", "value": 1, "blank": false},
		{"letter": "B", "value": 3, "blank": false},
		{"letter": "C", "value": 3, "blank": false},
		{"letter": "D", "value": 2, "blank": false},
	]
	main.refresh_rack()

	var bag_before: int = main.bag.size()

	main._open_trade()
	await process_frame
	if not main.blank_popup.visible and not main.trade_popup.visible:
		failures.append("trade popup did not open")
	if not main.trade_popup.visible:
		failures.append("trade popup did not open")

	main.trade_selection = {0: true, 2: true}
	main._confirm_trade()
	await process_frame

	if main.trade_popup.visible:
		failures.append("trade popup did not close")
	if main.players[0]["rack"].size() != main.ruleset.rack_size:
		failures.append("rack not refilled after trade: %d" % main.players[0]["rack"].size())
	if main.bag.size() != bag_before:
		failures.append("bag size changed by trade: %d -> %d" % [bag_before, main.bag.size()])
	if main.current != 1:
		failures.append("turn did not pass after trade")
	if main.board.tile_count() != 0:
		failures.append("board changed during trade")

	var top_log: String = main.log_label.text.split("\n")[0]
	print("log: ", top_log)

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
