extends SceneTree

const EFFECT_DIRECTOR := preload("res://scripts/effects/effect_director.gd")
const THEMES := [
	"wizardry",
	"gothic_horror",
	"pirate",
	"space_age",
	"kitchen_witchery",
	"prairie_homestead",
	"velvet_leather",
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var director: Node = EFFECT_DIRECTOR.new()
	root.add_child(director)
	var signal_cues: Array = []
	var batch_counter := {"count": 0}
	director.cue_requested.connect(func(cue: Dictionary): signal_cues.append(cue))
	director.events_presented.connect(func(_events: Array, _context: Dictionary): batch_counter["count"] += 1)

	for theme_id in THEMES:
		if not director.load_theme(theme_id):
			failures.append("%s effect profile failed to load" % theme_id)
			continue
		var cues: Dictionary = director.profile().get("cues", {})
		for required in ["tile_placed", "move_committed", "theme_bonus", "turn_passed", "tiles_traded", "match_ended"]:
			if not cues.has(required) or cues[required].is_empty():
				failures.append("%s profile lacks %s" % [theme_id, required])

	director.load_theme("pirate")
	var move_event := MatchEvent.create("move_committed", {
		"player_index": 0,
		"score": 18,
		"words": ["TIDE"],
		"positions": [{"x": 6, "y": 7}, {"x": 7, "y": 7}, {"x": 8, "y": 7}, {"x": 9, "y": 7}],
		"bonus_hits": [{"label": "Buried treasure", "points": 5, "words": ["TIDE"]}],
	}, 7)
	var first: Array = director.present([move_event], {"match_id": "fixture-duel"})
	if first.size() != 3 or signal_cues.size() != 3:
		failures.append("committed bonus move did not emit trace, score, and bonus cues")
	else:
		if str(first[0].get("identity", "")) != "fixture-duel:7:0:compass_trace":
			failures.append("cue identity is not stable")
		if str(first[1].get("identity", "")) != "fixture-duel:7:0:score_burst":
			failures.append("second cue identity lost the event index")
	if not director.present([move_event], {"match_id": "fixture-duel"}).is_empty():
		failures.append("duplicate event batch replayed effects")
	if int(batch_counter["count"]) != 2:
		failures.append("each accepted presentation call did not emit one ordered batch")

	director.clear_history()
	director.reduced_motion = true
	var reduced: Array = director.present([move_event], {"match_id": "reduced-duel"})
	if reduced.is_empty() or str(reduced[0].get("visual", "")) != "pulse" or float(reduced[0].get("duration", 1.0)) > 0.25:
		failures.append("reduced motion did not replace travel with a short pulse")

	director.clear_history()
	director.reduced_motion = false
	director.set_effects_mode("off")
	if not director.present([move_event], {"match_id": "silent-duel"}).is_empty():
		failures.append("effects-off emitted a cue")
	director.set_effects_mode("full")
	if not director.present([move_event], {"match_id": "silent-duel"}).is_empty():
		failures.append("an event observed while effects were off replayed later")

	var layer_scene: PackedScene = load("res://scenes/effects/effect_layer.tscn")
	if layer_scene == null:
		failures.append("effect layer scene failed to load")
	else:
		var layer: Control = layer_scene.instantiate()
		root.add_child(layer)
		await process_frame
		if layer.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			failures.append("effect layer intercepts input")
		for canvas in [layer.atmosphere_canvas, layer.board_canvas, layer.foreground_canvas]:
			if canvas == null or canvas.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				failures.append("an effect canvas intercepts input")
		layer.queue_free()

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
