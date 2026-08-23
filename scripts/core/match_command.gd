class_name MatchCommand
extends RefCounted

const PROTOCOL_VERSION := 1

var type := ""
var player_index := -1
var expected_sequence := 0
var idempotency_key := ""
var payload: Dictionary = {}


static func create(command_type: String, command_payload: Dictionary, actor: int, sequence: int, key := "") -> MatchCommand:
	var command := MatchCommand.new()
	command.type = command_type
	command.payload = command_payload.duplicate(true)
	command.player_index = actor
	command.expected_sequence = sequence
	command.idempotency_key = key
	return command


func to_dict() -> Dictionary:
	return {
		"protocol_version": PROTOCOL_VERSION,
		"type": type,
		"player_index": player_index,
		"expected_sequence": expected_sequence,
		"idempotency_key": idempotency_key,
		"payload": payload.duplicate(true),
	}


static func from_dict(data: Dictionary) -> MatchCommand:
	if int(data.get("protocol_version", 0)) != PROTOCOL_VERSION:
		return null
	var command := MatchCommand.new()
	command.type = str(data.get("type", ""))
	command.player_index = int(data.get("player_index", -1))
	command.expected_sequence = int(data.get("expected_sequence", -1))
	command.idempotency_key = str(data.get("idempotency_key", ""))
	var raw_payload: Variant = data.get("payload", {})
	if raw_payload is Dictionary:
		command.payload = _normalized_protocol_value(raw_payload)
	return command


static func _normalized_protocol_value(value: Variant) -> Variant:
	if value is float and is_equal_approx(value, roundf(value)):
		return int(value)
	if value is Array:
		var normalized_array: Array = []
		for item in value:
			normalized_array.append(_normalized_protocol_value(item))
		return normalized_array
	if value is Dictionary:
		var normalized_dictionary: Dictionary = {}
		for key in value:
			normalized_dictionary[key] = _normalized_protocol_value(value[key])
		return normalized_dictionary
	return value
