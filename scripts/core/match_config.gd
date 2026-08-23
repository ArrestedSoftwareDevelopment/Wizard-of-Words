class_name MatchConfig
extends RefCounted

const SCHEMA_VERSION := 1

var ruleset_path := ""
var lexicon_files: Array[String] = []
var players: Array[Dictionary] = []
var ai_difficulty := "adept"
var fog_of_war := false
var tile_path := ""
var frame_path := ""
var seed := 0


func to_dict() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"ruleset_path": ruleset_path,
		"lexicon_files": lexicon_files.duplicate(),
		"players": players.duplicate(true),
		"ai_difficulty": ai_difficulty,
		"fog_of_war": fog_of_war,
		"tile_path": tile_path,
		"frame_path": frame_path,
		"seed": seed,
	}


static func from_dict(data: Dictionary) -> MatchConfig:
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return null
	var config := MatchConfig.new()
	config.ruleset_path = str(data.get("ruleset_path", ""))
	for filename in data.get("lexicon_files", []):
		config.lexicon_files.append(str(filename))
	for player in data.get("players", []):
		if player is Dictionary:
			config.players.append(player.duplicate(true))
	config.ai_difficulty = str(data.get("ai_difficulty", "adept"))
	config.fog_of_war = bool(data.get("fog_of_war", false))
	config.tile_path = str(data.get("tile_path", ""))
	config.frame_path = str(data.get("frame_path", ""))
	config.seed = int(data.get("seed", 0))
	return config
