extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	var main: Variant = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.ai_check.button_pressed = false
	main._on_new_game()
	await process_frame

	for _index in range(6):
		if not main.game_over:
			main._on_pass()
	if not main.game_over or not main.match_state.game_over:
		failures.append("six consecutive passes did not end the match")
	if main.match_state.sequence != 6:
		failures.append("pass commands did not receive six sequence numbers")
	if main.match_state.result.get("reason") != "consecutive_passes":
		failures.append("pass ending reason was not recorded")
	var winners: Array = main.match_state.result.get("winners", [])
	var final_score := str(main.match_state.result.get("score", 0))
	if winners.is_empty() or not main.log_label.text.contains(str(winners[0])) or not main.log_label.text.contains(final_score):
		failures.append("match result was not rendered")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
