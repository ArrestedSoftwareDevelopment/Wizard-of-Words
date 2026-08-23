extends SceneTree


func _initialize() -> void:
	var failures: Array = []
	var shell: BoardShell = load("res://scenes/components/board_shell.tscn").instantiate()
	root.add_child(shell)
	await process_frame

	var skin := {
		"frame": "res://data/graphics/frames/Pirate Frame.png",
		"background": "res://data/graphics/backgrounds/Parchment Background.png"
	}
	shell.configure(skin, 15, 44.0, null, 2)
	await process_frame

	if shell.board_view.cell_buttons.size() != 225:
		failures.append("board view expected 225 cells, found %d" % shell.board_view.cell_buttons.size())
	var expected_grid := 15.0 * 31.0 + 14.0 * 2.0
	if shell.board_view.custom_minimum_size != Vector2(expected_grid, expected_grid):
		failures.append("board grid minimum size is incorrect: %s" % shell.board_view.custom_minimum_size)
	var expected_insets := {"left": 128, "top": 144, "right": 128, "bottom": 152}
	if shell.applied_insets != expected_insets:
		failures.append("pirate frame insets not loaded from catalog: %s" % shell.applied_insets)
	var expected_shell := Vector2(800.0, 800.0)
	if shell.custom_minimum_size != expected_shell:
		failures.append("board shell does not wrap grid and insets: %s" % shell.custom_minimum_size)
	if not shell.frame_rect.visible or shell.frame_rect.texture == null:
		failures.append("frame texture did not load")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
