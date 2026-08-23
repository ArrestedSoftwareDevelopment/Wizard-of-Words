class_name MatchEvent
extends RefCounted

const PROTOCOL_VERSION := 1

var type := ""
var sequence := 0
var payload: Dictionary = {}


static func create(event_type: String, event_payload: Dictionary, event_sequence: int) -> MatchEvent:
	var event := MatchEvent.new()
	event.type = event_type
	event.payload = event_payload.duplicate(true)
	event.sequence = event_sequence
	return event


func to_dict() -> Dictionary:
	return {
		"protocol_version": PROTOCOL_VERSION,
		"type": type,
		"sequence": sequence,
		"payload": payload.duplicate(true),
	}


static func from_dict(data: Dictionary) -> MatchEvent:
	if int(data.get("protocol_version", 0)) != PROTOCOL_VERSION:
		return null
	var event := MatchEvent.new()
	event.type = str(data.get("type", ""))
	event.sequence = int(data.get("sequence", 0))
	var raw_payload: Variant = data.get("payload", {})
	if raw_payload is Dictionary:
		event.payload = MatchCommand._normalized_protocol_value(raw_payload)
	return event
