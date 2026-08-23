class_name MatchState
extends RefCounted

const SCHEMA_VERSION := 1

var config: Dictionary = {}
var board: GameBoard
var bag: Array = []
var players: Array = []
var pending: Dictionary = {}
var current_player := 0
var passes_in_a_row := 0
var revealed: Dictionary = {}
var sequence := 0
var seed := 0
var rng_state := 0
var game_over := false
var result: Dictionary = {}
var processed_commands: Dictionary = {}


func to_dict() -> Dictionary:
	var board_cells: Array = []
	if board != null:
		for position in board.cells:
			var pos: Vector2i = position
			board_cells.append({
				"x": pos.x,
				"y": pos.y,
				"tile": board.cells[position].duplicate(true),
			})
	board_cells.sort_custom(func(a: Dictionary, b: Dictionary):
		return int(a["y"]) < int(b["y"]) or (int(a["y"]) == int(b["y"]) and int(a["x"]) < int(b["x"])))
	var revealed_cells: Array = []
	for position in revealed:
		var pos: Vector2i = position
		revealed_cells.append({"x": pos.x, "y": pos.y})
	revealed_cells.sort_custom(func(a: Dictionary, b: Dictionary):
		return int(a["y"]) < int(b["y"]) or (int(a["y"]) == int(b["y"]) and int(a["x"]) < int(b["x"])))
	var pending_tiles: Array = []
	for position in pending:
		var pos: Vector2i = position
		pending_tiles.append({"x": pos.x, "y": pos.y, "tile": pending[position]["tile"].duplicate(true)})
	pending_tiles.sort_custom(func(a: Dictionary, b: Dictionary):
		return int(a["y"]) < int(b["y"]) or (int(a["y"]) == int(b["y"]) and int(a["x"]) < int(b["x"])))
	return {
		"schema_version": SCHEMA_VERSION,
		"config": config.duplicate(true),
		"board_size": board.size if board != null else 0,
		"board_cells": board_cells,
		"bag": bag.duplicate(true),
		"players": players.duplicate(true),
		"pending": pending_tiles,
		"current_player": current_player,
		"passes_in_a_row": passes_in_a_row,
		"revealed": revealed_cells,
		"sequence": sequence,
		"seed": seed,
		"rng_state": str(rng_state),
		"game_over": game_over,
		"result": result.duplicate(true),
		"processed_commands": processed_commands.duplicate(true),
	}


static func from_dict(data: Dictionary) -> MatchState:
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return null
	var state := MatchState.new()
	var raw_config: Variant = data.get("config", {})
	if raw_config is Dictionary:
		var parsed_config := MatchConfig.from_dict(raw_config)
		if parsed_config != null:
			state.config = parsed_config.to_dict()
	state.board = GameBoard.new()
	state.board.setup(int(data.get("board_size", 15)))
	for cell in data.get("board_cells", []):
		if cell is Dictionary and cell.get("tile", null) is Dictionary:
			state.board.place(Vector2i(int(cell.get("x", -1)), int(cell.get("y", -1))), _normalized_tile(cell["tile"]))
	for tile in data.get("bag", []):
		if tile is Dictionary:
			state.bag.append(_normalized_tile(tile))
	for raw_player in data.get("players", []):
		if not raw_player is Dictionary:
			continue
		var player := {
			"id": str(raw_player.get("id", "")),
			"name": str(raw_player.get("name", "")),
			"score": int(raw_player.get("score", 0)),
			"rack": [],
			"is_ai": bool(raw_player.get("is_ai", false)),
		}
		for tile in raw_player.get("rack", []):
			if tile is Dictionary:
				player["rack"].append(_normalized_tile(tile))
		state.players.append(player)
	for item in data.get("pending", []):
		if item is Dictionary and item.get("tile", null) is Dictionary:
			var position := Vector2i(int(item.get("x", -1)), int(item.get("y", -1)))
			state.pending[position] = {"pos": position, "tile": _normalized_tile(item["tile"])}
	state.current_player = int(data.get("current_player", 0))
	state.passes_in_a_row = int(data.get("passes_in_a_row", 0))
	for cell in data.get("revealed", []):
		if cell is Dictionary:
			state.revealed[Vector2i(int(cell.get("x", -1)), int(cell.get("y", -1)))] = true
	state.sequence = int(data.get("sequence", 0))
	state.seed = int(data.get("seed", 0))
	state.rng_state = str(data.get("rng_state", "0")).to_int()
	state.game_over = bool(data.get("game_over", false))
	var raw_result: Variant = data.get("result", {})
	if raw_result is Dictionary and not raw_result.is_empty():
		state.result = {
			"reason": str(raw_result.get("reason", "")),
			"winners": raw_result.get("winners", []).duplicate(),
			"score": int(raw_result.get("score", 0)),
		}
	var raw_processed: Variant = data.get("processed_commands", {})
	if raw_processed is Dictionary:
		for key in raw_processed:
			var normalized_events: Array = []
			for raw_event in raw_processed[key]:
				if raw_event is Dictionary:
					var event := MatchEvent.from_dict(raw_event)
					if event != null:
						normalized_events.append(event.to_dict())
			state.processed_commands[str(key)] = normalized_events
	return state


func checksum() -> String:
	return JSON.stringify(to_dict()).sha256_text()


static func _normalized_tile(tile: Dictionary) -> Dictionary:
	var normalized := {
		"letter": str(tile.get("letter", "")),
		"value": int(tile.get("value", 0)),
		"blank": bool(tile.get("blank", false)),
	}
	if tile.has("chosen_blank_letter"):
		normalized["chosen_blank_letter"] = str(tile["chosen_blank_letter"])
	return normalized
