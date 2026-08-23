class_name AiPlayer
extends RefCounted

const DIFFICULTY_BUDGETS := {
	"apprentice": {"candidates": 60, "checks": 600},
	"adept": {"candidates": 300, "checks": 4000},
	"archmage": {"candidates": 900, "checks": 12000}
}


static func choose_move(board: GameBoard, rack: Array, ruleset: WordRuleset, lexicon: Lexicon, difficulty := "adept") -> Variant:
	var budget: Dictionary = DIFFICULTY_BUDGETS.get(difficulty, DIFFICULTY_BUDGETS["adept"])
	var max_candidates := int(budget["candidates"])
	var max_checks := int(budget["checks"])
	var avail := {}
	var blanks := 0
	for t in rack:
		if t["blank"]:
			blanks += 1
		else:
			avail[t["letter"]] = int(avail.get(t["letter"], 0)) + 1
	var candidates: Array = []
	var scratch: Dictionary = {}
	for w in lexicon.word_list():
		if w.length() < 2 or w.length() > ruleset.board_size:
			continue
		if _formable(w, avail, blanks, scratch):
			candidates.append(w)
	candidates.shuffle()
	var first_move := board.tile_count() == 0
	var valid_moves: Array = []
	var tried := 0
	var checks := 0
	for w in candidates:
		if tried >= max_candidates or checks >= max_checks:
			break
		tried += 1
		for placement in _placements_for(w, board, ruleset, first_move, avail):
			checks += 1
			if checks > max_checks:
				break
			var res := MoveLogic.validate(board, placement, ruleset, lexicon)
			if res["ok"]:
				var blank_count := 0
				for p in placement:
					if p["tile"]["blank"]:
						blank_count += 1
				var blank_pen := 0 if difficulty == "archmage" else 25
				valid_moves.append({
					"move": placement,
					"score": int(res["score"]),
					"rank_score": int(res["score"]) - blank_pen * blank_count
				})
	if valid_moves.is_empty():
		return {}
	if difficulty == "apprentice":
		return valid_moves[randi() % valid_moves.size()]["move"]
	var best: Variant = null
	var best_rank := -9223372036854775808
	for m in valid_moves:
		if int(m["rank_score"]) > best_rank:
			best_rank = int(m["rank_score"])
			best = m["move"]
	if best == null and not valid_moves.is_empty():
		return valid_moves[0]["move"]
	return best


static func _formable(w: String, avail: Dictionary, blanks: int, scratch: Dictionary) -> bool:
	scratch.clear()
	var missing := 0
	for ch in w:
		var used := int(scratch.get(ch, 0)) + 1
		scratch[ch] = used
		if int(avail.get(ch, 0)) < used:
			missing += 1
			if missing > blanks:
				return false
	return true


static func _fits(start: Vector2i, dir: Vector2i, length: int, size: int) -> bool:
	var end: Vector2i = start + dir * (length - 1)
	return start.x >= 0 and start.y >= 0 and end.x < size and end.y < size


static func _placements_for(w: String, board: GameBoard, ruleset: WordRuleset, first_move: bool, avail: Dictionary) -> Array:
	var out: Array = []
	var length := w.length()
	if first_move:
		var c: Vector2i = board.center()
		for dir in MoveLogic.DIRS:
			for i in range(length):
				var start: Vector2i = c - dir * i
				if _fits(start, dir, length, ruleset.board_size):
					var pl := _build(w, start, dir, board, ruleset, avail)
					if not pl.is_empty():
						out.append(pl)
		return out
	for p in board.cells:
		var lt: String = board.cells[p]["letter"]
		for i in range(length):
			if w[i] != lt:
				continue
			for dir in MoveLogic.DIRS:
				var start2: Vector2i = p - dir * i
				if not _fits(start2, dir, length, ruleset.board_size):
					continue
				var pl2 := _build(w, start2, dir, board, ruleset, avail)
				if not pl2.is_empty():
					out.append(pl2)
	out.shuffle()
	return out


static func _build(w: String, start: Vector2i, dir: Vector2i, board: GameBoard, ruleset: WordRuleset, avail: Dictionary) -> Array:
	var used := {}
	var pl: Array = []
	for i in range(w.length()):
		var p: Vector2i = start + dir * i
		var existing = board.tile_at(p)
		if existing != null:
			if existing["letter"] != w[i]:
				return []
			continue
		var ch := w[i]
		var count := int(used.get(ch, 0))
		used[ch] = count + 1
		var is_blank := count >= int(avail.get(ch, 0))
		var value := 0 if is_blank else ruleset.letter_value(ch)
		pl.append({
			"pos": p,
			"tile": {"letter": ch, "value": value, "blank": is_blank}
		})
	if pl.is_empty():
		return []
	return pl
