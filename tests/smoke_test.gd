extends SceneTree


func _initialize() -> void:
	var failures: Array = []

	var rs := WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	if rs == null:
		failures.append("ruleset failed to load")
		print("RESULT: FAIL ", failures)
		quit(1)
		return
	var errs := rs.validate()
	if not errs.is_empty():
		failures.append("ruleset invalid: " + "; ".join(errs))

	for path in ["res://data/rulesets/spiral_sigil.json", "res://data/rulesets/arcane_codex.json"]:
		var alt := WordRuleset.load_from(path)
		if alt == null:
			failures.append("%s failed to load" % path)
		else:
			var aerrs := alt.validate()
			if not aerrs.is_empty():
				failures.append("%s invalid: %s" % [path, "; ".join(aerrs)])
	if rs == null:
		print("RESULT: FAIL ", failures)
		quit(1)
		return
	var spiral := WordRuleset.load_from("res://data/rulesets/spiral_sigil.json")
	if spiral != null and not spiral.fog_of_war:
		failures.append("spiral_sigil should have fog_of_war enabled")

	var lx := Lexicon.load_from("res://data/dictionaries/enable1.txt")
	if lx.size() < 100000:
		failures.append("enable1 suspiciously small: %d" % lx.size())
	for w in ["MICE", "CAT", "HAT", "AA"]:
		if not lx.has_word(w):
			failures.append("enable1 missing %s" % w)
	if lx.has_word("NOTAREALWORD"):
		failures.append("enable1 contains junk")

	var board := GameBoard.new()
	board.setup(rs.board_size)

	var first := [
		{"pos": Vector2i(6, 7), "tile": {"letter": "M", "value": 3, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "I", "value": 1, "blank": false}},
		{"pos": Vector2i(8, 7), "tile": {"letter": "C", "value": 3, "blank": false}},
		{"pos": Vector2i(9, 7), "tile": {"letter": "E", "value": 1, "blank": false}},
	]
	var res := MoveLogic.validate(board, first, rs, lx)
	if not res["ok"]:
		failures.append("first move MICE rejected: %s" % res["error"])
	elif int(res["score"]) != 16:
		failures.append("MICE score expected 16 (center x2), got %d" % int(res["score"]))
	else:
		for item in first:
			board.place(item["pos"], item["tile"])

	var vertical := [
		{"pos": Vector2i(9, 8), "tile": {"letter": "A", "value": 1, "blank": false}},
		{"pos": Vector2i(9, 9), "tile": {"letter": "T", "value": 1, "blank": false}},
	]
	var res2 := MoveLogic.validate(board, vertical, rs, lx)
	if not res2["ok"]:
		failures.append("second move EAT rejected: %s" % res2["error"])

	var vertical_open := [
		{"pos": Vector2i(7, 5), "tile": {"letter": "C", "value": 3, "blank": false}},
		{"pos": Vector2i(7, 6), "tile": {"letter": "A", "value": 1, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "T", "value": 1, "blank": false}},
	]
	var empty_board := GameBoard.new()
	empty_board.setup(rs.board_size)
	var res_v := MoveLogic.validate(empty_board, vertical_open, rs, lx)
	if not res_v["ok"]:
		failures.append("vertical opening CAT rejected: %s" % res_v["error"])

	var disconnected := [
		{"pos": Vector2i(0, 0), "tile": {"letter": "D", "value": 2, "blank": false}},
		{"pos": Vector2i(0, 1), "tile": {"letter": "O", "value": 1, "blank": false}},
	]
	if MoveLogic.validate(board, disconnected, rs, lx)["ok"]:
		failures.append("disconnected move wrongly accepted")

	var gap_move := [
		{"pos": Vector2i(5, 7), "tile": {"letter": "Z", "value": 10, "blank": false}},
		{"pos": Vector2i(9, 7), "tile": {"letter": "X", "value": 8, "blank": false}},
	]
	if MoveLogic.validate(board, gap_move, rs, lx)["ok"]:
		failures.append("gapped move wrongly accepted")

	var offcenter := [
		{"pos": Vector2i(2, 2), "tile": {"letter": "A", "value": 1, "blank": false}},
		{"pos": Vector2i(3, 2), "tile": {"letter": "T", "value": 1, "blank": false}},
	]
	if MoveLogic.validate(empty_board, offcenter, rs, lx)["ok"]:
		failures.append("non-center opening wrongly accepted")

	var ai_move: Variant = AiPlayer.choose_move(board, _rack("AERTION"), rs, lx)
	if ai_move.is_empty():
		failures.append("AI found no move on open board")
	else:
		var res6 := MoveLogic.validate(board, ai_move, rs, lx)
		if not res6["ok"]:
			failures.append("AI move invalid: %s" % res6["error"])

	var strict_rs: WordRuleset = WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	strict_rs.strict_two_letter = true
	var zz_lex := Lexicon.new()
	zz_lex.words["ZZ"] = true
	zz_lex.words["ZA"] = true
	zz_lex.trusted_two_letter = {"ZA": true}
	var empty2 := GameBoard.new()
	empty2.setup(15)
	var zz_move := [
		{"pos": Vector2i(6, 7), "tile": {"letter": "Z", "value": 10, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "Z", "value": 10, "blank": false}},
	]
	if MoveLogic.validate(empty2, zz_move, strict_rs, zz_lex)["ok"]:
		failures.append("strict mode accepted non-whitelisted ZZ")
	strict_rs.strict_two_letter = false
	if not MoveLogic.validate(empty2, zz_move, strict_rs, zz_lex)["ok"]:
		failures.append("non-strict mode rejected dictionary ZZ")
	var za_move := [
		{"pos": Vector2i(6, 7), "tile": {"letter": "Z", "value": 10, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "A", "value": 1, "blank": false}},
	]
	strict_rs.strict_two_letter = true
	za_move[1]["tile"]["blank"] = true
	za_move[1]["tile"]["value"] = 0
	if not MoveLogic.validate(empty2, za_move, strict_rs, zz_lex)["ok"]:
		failures.append("strict mode wrongly rejected whitelisted ZA (blank)")

	var min_three_rs := WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	min_three_rs.min_word_length = 3
	var min_three_lex := Lexicon.new()
	min_three_lex.words = {"CAT": true, "AA": true}
	var cross_board := GameBoard.new()
	cross_board.setup(15)
	cross_board.place(Vector2i(7, 6), {"letter": "A", "value": 1, "blank": false})
	var short_cross := [
		{"pos": Vector2i(6, 7), "tile": {"letter": "C", "value": 3, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "A", "value": 1, "blank": false}},
		{"pos": Vector2i(8, 7), "tile": {"letter": "T", "value": 1, "blank": false}},
	]
	if MoveLogic.validate(cross_board, short_cross, min_three_rs, min_three_lex)["ok"]:
		failures.append("three-letter minimum accepted a two-letter cross-word")

	var surge_rs := WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	var cat_lx := Lexicon.new()
	cat_lx.words["CAT"] = true
	cat_lx.bonus_sets = [{"points": 25, "label": "Test Surge", "words": {"CAT": true}}]
	var empty3 := GameBoard.new()
	empty3.setup(15)
	var cat_move := [
		{"pos": Vector2i(6, 7), "tile": {"letter": "C", "value": 3, "blank": false}},
		{"pos": Vector2i(7, 7), "tile": {"letter": "A", "value": 1, "blank": false}},
		{"pos": Vector2i(8, 7), "tile": {"letter": "T", "value": 1, "blank": false}},
	]
	var res_cat := MoveLogic.validate(empty3, cat_move, surge_rs, cat_lx)
	if not res_cat["ok"]:
		failures.append("bonus CAT rejected: %s" % res_cat["error"])
	elif int(res_cat["score"]) != 35:
		failures.append("bonus CAT score expected 35 (10+25), got %d" % int(res_cat["score"]))
	else:
		var hits: Array = res_cat["bonus_hits"]
		if hits.is_empty() or not ((hits[0]["words"] as Array).has("CAT")):
			failures.append("bonus hit list missing CAT")

	var ai_move2: Variant = AiPlayer.choose_move(board, _rack_blanks(3), rs, lx)
	if ai_move2 == null:
		failures.append("AI returned null on blank-heavy rack")
	elif ai_move2.is_empty():
		failures.append("AI found no move with 3 blanks available")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)


func _rack(letters: String) -> Array:
	var rack: Array = []
	for ch in letters:
		rack.append({"letter": ch, "value": 1, "blank": false})
	return rack


func _rack_blanks(count: int) -> Array:
	var rack: Array = []
	for i in range(count):
		rack.append({"letter": "", "value": 0, "blank": true})
	return rack
