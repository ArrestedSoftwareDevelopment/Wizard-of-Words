class_name MatchEngine
extends RefCounted

const COMMAND_PASS := "pass_turn"
const COMMAND_TRADE := "trade_tiles"
const COMMAND_PLACE := "place_tile"
const COMMAND_MOVE_PENDING := "move_pending_tile"
const COMMAND_RECALL := "recall_tile"
const COMMAND_RECALL_ALL := "recall_all_tiles"
const COMMAND_COMMIT := "commit_move"
const COMMAND_SHUFFLE_RACK := "shuffle_rack"
const COMMAND_REORDER_RACK := "reorder_rack"


static func start_match(config: MatchConfig, ruleset: WordRuleset) -> MatchState:
	var state := MatchState.new()
	state.config = config.to_dict()
	state.seed = config.seed
	state.board = GameBoard.new()
	state.board.setup(ruleset.board_size)
	var bag_result := TileBag.build(ruleset, config.seed)
	state.bag = bag_result["tiles"]
	state.rng_state = int(bag_result["rng_state"])
	var player_configs: Array = config.players
	if player_configs.is_empty():
		player_configs = [
			{"id": "player-1", "name": "Apprentice", "is_ai": false},
			{"id": "player-2", "name": "Rival Apprentice", "is_ai": false},
		]
	for index in range(player_configs.size()):
		var player_config: Dictionary = player_configs[index]
		state.players.append({
			"id": str(player_config.get("id", "player-%d" % (index + 1))),
			"name": str(player_config.get("name", "Player %d" % (index + 1))),
			"score": 0,
			"rack": [],
			"is_ai": bool(player_config.get("is_ai", false)),
		})
	for player in state.players:
		TileBag.refill(player["rack"], state.bag, ruleset.rack_size)
	if config.fog_of_war:
		for delta_y in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
			for delta_x in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
				var position := state.board.center() + Vector2i(delta_x, delta_y)
				if state.board.in_bounds(position):
					state.revealed[position] = true
	return state


static func apply_command(state: MatchState, command: MatchCommand, ruleset: WordRuleset, lexicon: Lexicon = null) -> Array[MatchEvent]:
	if not command.idempotency_key.is_empty() and state.processed_commands.has(command.idempotency_key):
		return _events_from_data(state.processed_commands[command.idempotency_key])
	var rejection := _validate_envelope(state, command)
	if not rejection.is_empty():
		return [MatchEvent.create("command_rejected", {"reason": rejection, "command_type": command.type}, state.sequence)]
	var events: Array[MatchEvent] = []
	match command.type:
		COMMAND_PLACE:
			events = _place_tile(state, command.payload)
		COMMAND_MOVE_PENDING:
			events = _move_pending_tile(state, command.payload)
		COMMAND_RECALL:
			events = _recall_tile(state, command.payload)
		COMMAND_RECALL_ALL:
			events = _recall_all(state)
		COMMAND_COMMIT:
			events = _commit_move(state, ruleset, lexicon)
		COMMAND_SHUFFLE_RACK:
			events = _shuffle_rack(state)
		COMMAND_REORDER_RACK:
			events = _reorder_rack(state, command.payload)
		COMMAND_PASS:
			events = _pass_turn(state, ruleset)
		COMMAND_TRADE:
			events = _trade_tiles(state, command.payload, ruleset)
		_:
			return [MatchEvent.create("command_rejected", {"reason": "unknown_command", "command_type": command.type}, state.sequence)]
	if not events.is_empty() and events[0].type != "command_rejected":
		state.sequence += 1
		for event in events:
			event.sequence = state.sequence
		if not command.idempotency_key.is_empty():
			var event_data: Array = []
			for event in events:
				event_data.append(event.to_dict())
			state.processed_commands[command.idempotency_key] = event_data
	return events


static func _validate_envelope(state: MatchState, command: MatchCommand) -> String:
	if state == null or state.board == null:
		return "match_not_started"
	if state.game_over:
		return "match_over"
	if command.expected_sequence != state.sequence:
		return "stale_sequence"
	if command.player_index != state.current_player:
		return "not_your_turn"
	if command.player_index < 0 or command.player_index >= state.players.size():
		return "unknown_player"
	return ""


static func _pass_turn(state: MatchState, ruleset: WordRuleset) -> Array[MatchEvent]:
	if not state.pending.is_empty():
		return [MatchEvent.create("command_rejected", {"reason": "pending_tiles", "command_type": COMMAND_PASS}, state.sequence)]
	var actor := state.current_player
	state.passes_in_a_row += 1
	var events: Array[MatchEvent] = [MatchEvent.create("turn_passed", {"player_index": actor}, state.sequence)]
	if state.passes_in_a_row >= state.players.size() * 3:
		_finish_match(state, ruleset, "consecutive_passes")
		events.append(MatchEvent.create("match_ended", state.result, state.sequence))
		return events
	state.current_player = (state.current_player + 1) % state.players.size()
	events.append(MatchEvent.create("turn_advanced", {"player_index": state.current_player}, state.sequence))
	return events


static func _trade_tiles(state: MatchState, payload: Dictionary, ruleset: WordRuleset) -> Array[MatchEvent]:
	if not state.pending.is_empty():
		return [MatchEvent.create("command_rejected", {"reason": "pending_tiles", "command_type": COMMAND_TRADE}, state.sequence)]
	var raw_indices: Variant = payload.get("indices", [])
	if not raw_indices is Array or raw_indices.is_empty():
		return [MatchEvent.create("command_rejected", {"reason": "no_tiles_selected", "command_type": COMMAND_TRADE}, state.sequence)]
	var unique_indices: Dictionary = {}
	for raw_index in raw_indices:
		var index := int(raw_index)
		if unique_indices.has(index):
			return [MatchEvent.create("command_rejected", {"reason": "duplicate_tile_index", "command_type": COMMAND_TRADE}, state.sequence)]
		unique_indices[index] = true
	var indices: Array = unique_indices.keys()
	indices.sort()
	var rack: Array = state.players[state.current_player]["rack"]
	for index in indices:
		if int(index) < 0 or int(index) >= rack.size():
			return [MatchEvent.create("command_rejected", {"reason": "invalid_tile_index", "command_type": COMMAND_TRADE}, state.sequence)]
	if state.bag.size() < indices.size():
		return [MatchEvent.create("command_rejected", {"reason": "insufficient_bag_tiles", "command_type": COMMAND_TRADE}, state.sequence)]
	var actor := state.current_player
	var removed: Array = []
	for reverse_index in range(indices.size() - 1, -1, -1):
		var rack_index := int(indices[reverse_index])
		removed.append(rack[rack_index])
		rack.remove_at(rack_index)
	for tile in removed:
		state.bag.push_front(tile)
	var random := RandomNumberGenerator.new()
	random.state = state.rng_state
	TileBag.shuffle(state.bag, random)
	state.rng_state = random.state
	TileBag.refill(rack, state.bag, ruleset.rack_size)
	state.passes_in_a_row += 1
	state.current_player = (state.current_player + 1) % state.players.size()
	return [
		MatchEvent.create("tiles_traded", {"player_index": actor, "count": removed.size()}, state.sequence),
		MatchEvent.create("turn_advanced", {"player_index": state.current_player}, state.sequence),
	]


static func _place_tile(state: MatchState, payload: Dictionary) -> Array[MatchEvent]:
	var position := _payload_position(payload, "position")
	var rack_index := int(payload.get("rack_index", -1))
	var rack: Array = state.players[state.current_player]["rack"]
	if not state.board.in_bounds(position) or state.board.tile_at(position) != null or state.pending.has(position):
		return [MatchEvent.create("command_rejected", {"reason": "invalid_position", "command_type": COMMAND_PLACE}, state.sequence)]
	if rack_index < 0 or rack_index >= rack.size():
		return [MatchEvent.create("command_rejected", {"reason": "invalid_rack_index", "command_type": COMMAND_PLACE}, state.sequence)]
	var tile: Dictionary = rack[rack_index].duplicate(true)
	if bool(tile.get("blank", false)):
		var chosen_letter := str(payload.get("blank_letter", "")).to_upper()
		if chosen_letter.length() != 1 or chosen_letter < "A" or chosen_letter > "Z":
			return [MatchEvent.create("command_rejected", {"reason": "blank_letter_required", "command_type": COMMAND_PLACE}, state.sequence)]
		tile["letter"] = chosen_letter
		tile["chosen_blank_letter"] = chosen_letter
	rack.remove_at(rack_index)
	state.pending[position] = {"pos": position, "tile": tile}
	return [MatchEvent.create("tile_placed", {"player_index": state.current_player, "x": position.x, "y": position.y}, state.sequence)]


static func _move_pending_tile(state: MatchState, payload: Dictionary) -> Array[MatchEvent]:
	var source := _payload_position(payload, "source")
	var destination := _payload_position(payload, "destination")
	if not state.pending.has(source):
		return [MatchEvent.create("command_rejected", {"reason": "pending_tile_not_found", "command_type": COMMAND_MOVE_PENDING}, state.sequence)]
	if not state.board.in_bounds(destination) or state.board.tile_at(destination) != null or state.pending.has(destination):
		return [MatchEvent.create("command_rejected", {"reason": "invalid_position", "command_type": COMMAND_MOVE_PENDING}, state.sequence)]
	var item: Dictionary = state.pending[source]
	state.pending.erase(source)
	item["pos"] = destination
	state.pending[destination] = item
	return [MatchEvent.create("pending_tile_moved", {"from_x": source.x, "from_y": source.y, "x": destination.x, "y": destination.y}, state.sequence)]


static func _recall_tile(state: MatchState, payload: Dictionary) -> Array[MatchEvent]:
	var position := _payload_position(payload, "position")
	if not state.pending.has(position):
		return [MatchEvent.create("command_rejected", {"reason": "pending_tile_not_found", "command_type": COMMAND_RECALL}, state.sequence)]
	var tile: Dictionary = state.pending[position]["tile"]
	if bool(tile.get("blank", false)):
		tile["letter"] = ""
		tile.erase("chosen_blank_letter")
	state.pending.erase(position)
	state.players[state.current_player]["rack"].append(tile)
	return [MatchEvent.create("tile_recalled", {"player_index": state.current_player, "x": position.x, "y": position.y}, state.sequence)]


static func _recall_all(state: MatchState) -> Array[MatchEvent]:
	var count := state.pending.size()
	for position in state.pending.keys():
		var tile: Dictionary = state.pending[position]["tile"]
		if bool(tile.get("blank", false)):
			tile["letter"] = ""
			tile.erase("chosen_blank_letter")
		state.players[state.current_player]["rack"].append(tile)
	state.pending.clear()
	return [MatchEvent.create("tiles_recalled", {"player_index": state.current_player, "count": count}, state.sequence)]


static func _commit_move(state: MatchState, ruleset: WordRuleset, lexicon: Lexicon) -> Array[MatchEvent]:
	if lexicon == null:
		return [MatchEvent.create("command_rejected", {"reason": "lexicon_unavailable", "command_type": COMMAND_COMMIT}, state.sequence)]
	var placements: Array = []
	for position in state.pending:
		placements.append(state.pending[position])
	var validation := MoveLogic.validate(state.board, placements, ruleset, lexicon)
	if not bool(validation.get("ok", false)):
		return [MatchEvent.create("command_rejected", {"reason": str(validation.get("error", "invalid move")), "command_type": COMMAND_COMMIT}, state.sequence)]
	var actor := state.current_player
	var placed_positions: Array = []
	for position in state.pending:
		state.board.place(position, state.pending[position]["tile"])
		placed_positions.append(position)
	state.pending.clear()
	if ruleset.fog_of_war:
		for origin in placed_positions:
			for delta_y in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
				for delta_x in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
					var revealed_position: Vector2i = Vector2i(origin) + Vector2i(delta_x, delta_y)
					if state.board.in_bounds(revealed_position):
						state.revealed[revealed_position] = true
	TileBag.refill(state.players[actor]["rack"], state.bag, ruleset.rack_size)
	state.players[actor]["score"] += int(validation["score"])
	state.passes_in_a_row = 0
	var word_names: Array[String] = []
	for word in validation["words"]:
		word_names.append(str(word["word"]))
	var position_data: Array = []
	for position in placed_positions:
		position_data.append({"x": position.x, "y": position.y})
	var payload := {
		"player_index": actor,
		"score": int(validation["score"]),
		"words": word_names,
		"positions": position_data,
		"bonus_hits": validation.get("bonus_hits", []).duplicate(true),
	}
	var events: Array[MatchEvent] = [MatchEvent.create("move_committed", payload, state.sequence)]
	if state.players[actor]["rack"].is_empty() and state.bag.is_empty():
		_finish_match(state, ruleset, "rack_emptied")
		events.append(MatchEvent.create("match_ended", state.result, state.sequence))
		return events
	state.current_player = (state.current_player + 1) % state.players.size()
	events.append(MatchEvent.create("turn_advanced", {"player_index": state.current_player}, state.sequence))
	return events


static func _shuffle_rack(state: MatchState) -> Array[MatchEvent]:
	var random := RandomNumberGenerator.new()
	random.state = state.rng_state
	TileBag.shuffle(state.players[state.current_player]["rack"], random)
	state.rng_state = random.state
	return [MatchEvent.create("rack_shuffled", {"player_index": state.current_player}, state.sequence)]


static func _reorder_rack(state: MatchState, payload: Dictionary) -> Array[MatchEvent]:
	var from_index := int(payload.get("from_index", -1))
	var to_index := int(payload.get("to_index", -1))
	var rack: Array = state.players[state.current_player]["rack"]
	if from_index < 0 or to_index < 0 or from_index >= rack.size() or to_index >= rack.size() or from_index == to_index:
		return [MatchEvent.create("command_rejected", {"reason": "invalid_rack_order", "command_type": COMMAND_REORDER_RACK}, state.sequence)]
	var tile: Variant = rack[from_index]
	rack.remove_at(from_index)
	rack.insert(to_index, tile)
	return [MatchEvent.create("rack_reordered", {"player_index": state.current_player, "from_index": from_index, "to_index": to_index}, state.sequence)]


static func _payload_position(payload: Dictionary, key: String) -> Vector2i:
	var raw: Variant = payload.get(key, {})
	if raw is Dictionary:
		return Vector2i(int(raw.get("x", -1)), int(raw.get("y", -1)))
	return Vector2i(-1, -1)


static func _finish_match(state: MatchState, ruleset: WordRuleset, reason: String) -> void:
	MoveLogic.final_adjustment(state.players, ruleset)
	state.game_over = true
	var best_score := -999999
	var winners: Array[String] = []
	for player in state.players:
		var score := int(player["score"])
		if score > best_score:
			best_score = score
			winners = [str(player["name"])]
		elif score == best_score:
			winners.append(str(player["name"]))
	state.result = {"reason": reason, "winners": winners, "score": best_score}


static func _events_from_data(data: Array) -> Array[MatchEvent]:
	var events: Array[MatchEvent] = []
	for item in data:
		if item is Dictionary:
			var event := MatchEvent.from_dict(item)
			if event != null:
				events.append(event)
	return events
