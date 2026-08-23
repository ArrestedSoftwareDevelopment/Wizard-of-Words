extends SceneTree


func _initialize() -> void:
	var failures: Array[String] = []
	var ruleset := WordRuleset.load_from("res://data/rulesets/classic_grimoire.json")
	if ruleset == null:
		print("RESULT: FAIL [ruleset failed to load]")
		quit(1)
		return

	var config := MatchConfig.new()
	config.ruleset_path = "res://data/rulesets/classic_grimoire.json"
	config.lexicon_files = ["enable1.txt"]
	config.players = [
		{"id": "p1", "name": "One", "is_ai": false},
		{"id": "p2", "name": "Two", "is_ai": false},
	]
	config.seed = 424242

	var state := MatchEngine.start_match(config, ruleset)
	var twin := MatchEngine.start_match(config, ruleset)
	if state.bag != twin.bag or state.players != twin.players:
		failures.append("fixed seed did not produce a deterministic deal")
	var initial_tile_count := _tile_count(state)
	if initial_tile_count != _ruleset_tile_count(ruleset):
		failures.append("initial tile conservation failed")

	var config_copy := MatchConfig.from_dict(JSON.parse_string(JSON.stringify(config.to_dict())))
	if config_copy == null or config_copy.seed != config.seed or config_copy.players != config.players:
		failures.append("match config round trip failed")
	var state_copy := MatchState.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	if state_copy == null or state_copy.checksum() != state.checksum():
		failures.append("match state round trip/checksum failed")

	var move_state := MatchEngine.start_match(config, ruleset)
	move_state.players[0]["rack"] = [
		{"letter": "C", "value": 3, "blank": false},
		{"letter": "A", "value": 1, "blank": false},
		{"letter": "T", "value": 1, "blank": false},
	]
	var lexicon := Lexicon.load_from("res://data/dictionaries/enable1.txt")
	for placement in [
		{"position": {"x": 6, "y": 7}, "rack_index": 0},
		{"position": {"x": 7, "y": 7}, "rack_index": 0},
		{"position": {"x": 8, "y": 7}, "rack_index": 0},
	]:
		var place_command := MatchCommand.create(MatchEngine.COMMAND_PLACE, placement, 0, move_state.sequence, "place-%d" % move_state.sequence)
		var place_events := MatchEngine.apply_command(move_state, place_command, ruleset, lexicon)
		if place_events[0].type != "tile_placed":
			failures.append("authoritative tile placement failed")
	var commit := MatchCommand.create(MatchEngine.COMMAND_COMMIT, {}, 0, move_state.sequence, "commit-cat")
	var commit_events := MatchEngine.apply_command(move_state, commit, ruleset, lexicon)
	if commit_events[0].type != "move_committed" or move_state.board.tile_count() != 3:
		failures.append("authoritative CAT commit failed")
	elif int(commit_events[0].payload.get("score", 0)) != 10 or move_state.current_player != 1:
		failures.append("authoritative CAT score/turn was incorrect")
	var moved_copy := MatchState.from_dict(JSON.parse_string(JSON.stringify(move_state.to_dict())))
	if moved_copy == null or moved_copy.checksum() != move_state.checksum():
		failures.append("command-bearing state round trip failed")

	var stale := MatchCommand.create(MatchEngine.COMMAND_PASS, {}, 0, 99, "stale")
	var stale_events := MatchEngine.apply_command(state, stale, ruleset)
	if stale_events[0].type != "command_rejected" or stale_events[0].payload.get("reason") != "stale_sequence":
		failures.append("stale sequence was not rejected")
	if state.sequence != 0 or state.current_player != 0:
		failures.append("rejected command mutated state")

	var pass_command := MatchCommand.create(MatchEngine.COMMAND_PASS, {}, 0, 0, "pass-0")
	var command_copy := MatchCommand.from_dict(JSON.parse_string(JSON.stringify(pass_command.to_dict())))
	if command_copy == null or command_copy.idempotency_key != "pass-0":
		failures.append("command envelope round trip failed")
	var pass_events := MatchEngine.apply_command(state, pass_command, ruleset)
	if state.sequence != 1 or state.current_player != 1 or state.passes_in_a_row != 1:
		failures.append("pass command did not advance authoritative state")
	var event_copy := MatchEvent.from_dict(JSON.parse_string(JSON.stringify(pass_events[0].to_dict())))
	if event_copy == null or event_copy.type != "turn_passed" or event_copy.sequence != 1:
		failures.append("event envelope round trip failed")
	MatchEngine.apply_command(state, pass_command, ruleset)
	if state.sequence != 1 or state.current_player != 1:
		failures.append("idempotent retry applied twice")

	var trade_command := MatchCommand.create(MatchEngine.COMMAND_TRADE, {"indices": [0, 1]}, 1, 1, "trade-1")
	var trade_events := MatchEngine.apply_command(state, trade_command, ruleset)
	if trade_events[0].type != "tiles_traded" or state.sequence != 2 or state.current_player != 0:
		failures.append("trade command did not apply")
	if _tile_count(state) != initial_tile_count:
		failures.append("trade violated tile conservation")

	while not state.game_over:
		var key := "pass-%d" % state.sequence
		var command := MatchCommand.create(MatchEngine.COMMAND_PASS, {}, state.current_player, state.sequence, key)
		MatchEngine.apply_command(state, command, ruleset)
	if state.result.get("reason") != "consecutive_passes" or state.result.get("winners", []).is_empty():
		failures.append("pass limit did not produce a match result")
	if _tile_count(state) != initial_tile_count:
		failures.append("end-game adjustment violated tile conservation")

	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)


func _tile_count(state: MatchState) -> int:
	var count := state.bag.size()
	for player in state.players:
		count += player["rack"].size()
	count += state.board.tile_count()
	return count


func _ruleset_tile_count(ruleset: WordRuleset) -> int:
	var count := ruleset.blank_count
	for letter in ruleset.letters:
		count += int(ruleset.letters[letter]["count"])
	return count
