class_name MoveLogic
extends RefCounted

const DIRS := [Vector2i(1, 0), Vector2i(0, 1)]


static func _err(reason: String) -> Dictionary:
	return {"ok": false, "error": reason, "score": 0, "words": []}


static func validate(board: GameBoard, pending: Array, ruleset: WordRuleset, lexicon: Lexicon) -> Dictionary:
	if pending.is_empty():
		return _err("Place at least one rune.")
	var pend_map: Dictionary = {}
	for item in pending:
		var p: Vector2i = item["pos"]
		if not board.in_bounds(p):
			return _err("That rune falls outside the sigil.")
		if board.tile_at(p) != null:
			return _err("That cell is already occupied.")
		if pend_map.has(p):
			return _err("Duplicate rune placement.")
		pend_map[p] = item["tile"]

	var rows_set := {}
	var cols_set := {}
	for p in pend_map:
		rows_set[p.y] = true
		cols_set[p.x] = true
	var horiz: bool = rows_set.size() == 1
	var vert: bool = cols_set.size() == 1
	if not horiz and not vert:
		return _err("Runes must lie in a single line.")

	var sorted_positions := pend_map.keys()
	sorted_positions.sort_custom(func(a, b):
		if horiz:
			return a.x < b.x
		return a.y < b.y)
	for i in range(sorted_positions.size() - 1):
		var a: Vector2i = sorted_positions[i]
		var b: Vector2i = sorted_positions[i + 1]
		var gap: int = (b.x - a.x) if horiz else (b.y - a.y)
		for step in range(1, gap):
			var mid := Vector2i(a.x + step, a.y) if horiz else Vector2i(a.x, a.y + step)
			if board.tile_at(mid) == null:
				return _err("Runes must be contiguous - no gaps.")

	var first_move := board.tile_count() == 0
	if first_move and not pend_map.has(board.center()):
		return _err("The first spell must cross the center star.")
	if not first_move and not _connected(board, pend_map):
		return _err("New runes must touch existing runes.")

	var word_cells := _find_words(board, pend_map)
	var playable: Array = []
	for cells in word_cells:
		if cells.size() < ruleset.min_word_length:
			return _err("Every spell formed must contain %d+ runes." % ruleset.min_word_length)
		playable.append(cells)
	if playable.is_empty():
		return _err("A spell must form a word of %d+ runes." % ruleset.min_word_length)
	var words: Array = []
	for cells in playable:
		var text := ""
		for c in cells:
			text += _tile_for(board, pend_map, c)["letter"]
		if ruleset.profanity_filter and lexicon.blacklist.has(text):
			return _err("'%s' is forbidden by the censors." % text.to_lower())
		var freebie: bool = cells.size() == 2 and ruleset.allow_any_two_letter
		if not freebie and cells.size() == 2 and ruleset.strict_two_letter and not lexicon.trusted_two_letter.has(text):
			return _err("'%s' - two-letter jargon is forbidden here." % text.to_lower())
		if not freebie and not lexicon.has_word(text):
			return _err("'%s' is not in the grimoire." % text.to_lower())
		words.append({"word": text, "cells": cells})
	var total := _score_words(board, pend_map, playable, ruleset)
	if pending.size() >= ruleset.rack_size:
		total += ruleset.bingo_bonus
	var bonus_hits: Array = []
	for bset in lexicon.bonus_sets:
		var bwords: Dictionary = bset["words"]
		var pts := int(bset["points"])
		if pts <= 0 or bwords.is_empty():
			continue
		var hits: Array = []
		for w in words:
			if bwords.has(w["word"]):
				hits.append(w["word"])
				total += pts
		if not hits.is_empty():
			bonus_hits.append({"label": bset["label"], "points": pts, "words": hits})
	return {"ok": true, "error": "", "score": total, "words": words, "bonus_hits": bonus_hits}


static func _connected(board: GameBoard, pend_map: Dictionary) -> bool:
	var all := {}
	for p in board.cells:
		all[p] = true
	for p in pend_map:
		all[p] = true
	if all.is_empty():
		return false
	var start: Variant = null
	for p in all:
		start = p
		break
	var seen := {start: true}
	var queue: Array = [start]
	while not queue.is_empty():
		var q: Vector2i = queue.pop_back()
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = q + d
			if all.has(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return seen.size() == all.size()


static func _has(board: GameBoard, pend_map: Dictionary, p: Vector2i) -> bool:
	return board.tile_at(p) != null or pend_map.has(p)


static func _tile_for(board: GameBoard, pend_map: Dictionary, p: Vector2i) -> Dictionary:
	if pend_map.has(p):
		return pend_map[p]
	return board.tile_at(p)


static func _find_words(board: GameBoard, pend_map: Dictionary) -> Array:
	var result: Array = []
	for dir in DIRS:
		var seen_starts := {}
		for p in pend_map:
			var start: Vector2i = p
			while _has(board, pend_map, start - dir):
				start -= dir
			if seen_starts.has(start):
				continue
			seen_starts[start] = true
			var cells: Array = []
			var cur: Vector2i = start
			while _has(board, pend_map, cur):
				cells.append(cur)
				cur += dir
			if cells.size() > 1:
				result.append(cells)
	return result


static func _score_words(board: GameBoard, pend_map: Dictionary, word_cells: Array, ruleset: WordRuleset) -> int:
	var total := 0
	for cells in word_cells:
		var wscore := 0
		var word_mult := 1
		for c in cells:
			var tile: Dictionary = _tile_for(board, pend_map, c)
			var v := int(tile["value"])
			if pend_map.has(c):
				var prem: Dictionary = ruleset.premium_at(c)
				if prem["type"] == "letter":
					v *= int(prem["mult"])
				elif prem["type"] == "word":
					word_mult *= int(prem["mult"])
			wscore += v
		total += wscore * word_mult
	return total


static func final_adjustment(players: Array, ruleset: WordRuleset) -> void:
	if not ruleset.end_penalty:
		return
	for pl in players:
		var rack_sum := 0
		for t in pl["rack"]:
			rack_sum += int(t["value"])
		pl["score"] -= rack_sum
