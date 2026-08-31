class_name EffectDirector
extends Node

signal cue_requested(cue: Dictionary)
signal events_presented(events: Array, context: Dictionary)

const PROFILE_SCHEMA_VERSION := 1
const RECENT_CUE_LIMIT := 256
const VALID_MODES := ["off", "subtle", "full"]

var effects_mode := "full"
var reduced_motion := false
var active_theme_id := ""
var _profile: Dictionary = {}
var _recent_cues: Dictionary = {}
var _recent_order: Array[String] = []


func load_theme(theme_id: String) -> bool:
	var path := "res://data/effects/%s.json" % theme_id
	if not FileAccess.file_exists(path):
		_profile = {}
		active_theme_id = ""
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_profile = {}
		active_theme_id = ""
		return false
	if int(parsed.get("schema_version", 0)) != PROFILE_SCHEMA_VERSION:
		_profile = {}
		active_theme_id = ""
		return false
	if str(parsed.get("theme_id", "")) != theme_id or not parsed.get("cues", null) is Dictionary:
		_profile = {}
		active_theme_id = ""
		return false
	_profile = parsed.duplicate(true)
	active_theme_id = theme_id
	return true


func set_effects_mode(mode: String) -> void:
	effects_mode = mode if mode in VALID_MODES else "full"


func present(events: Array, context: Dictionary = {}) -> Array[Dictionary]:
	var normalized_events: Array = []
	var emitted: Array[Dictionary] = []
	var match_id := str(context.get("match_id", "local"))
	for event_index in range(events.size()):
		var event_data := _event_to_dict(events[event_index])
		if event_data.is_empty():
			continue
		normalized_events.append(event_data)
		if str(event_data.get("type", "")) == "command_rejected":
			continue
		var payload: Dictionary = event_data.get("payload", {})
		var cue_specs := _cue_specs(str(event_data.get("type", "")), payload)
		for cue_spec in cue_specs:
			var cue_id := str(cue_spec.get("id", "cue"))
			var identity := "%s:%d:%d:%s" % [match_id, int(event_data.get("sequence", 0)), event_index, cue_id]
			if _recent_cues.has(identity):
				continue
			_remember(identity)
			if effects_mode == "off":
				continue
			var cue: Dictionary = cue_spec.duplicate(true)
			cue["identity"] = identity
			cue["event_type"] = str(event_data.get("type", ""))
			cue["event_index"] = event_index
			cue["sequence"] = int(event_data.get("sequence", 0))
			cue["payload"] = payload.duplicate(true)
			cue["theme_id"] = active_theme_id
			cue["reduced_motion"] = reduced_motion
			if effects_mode == "subtle":
				cue["opacity"] = minf(float(cue.get("opacity", 1.0)), 0.55)
				cue["duration"] = minf(float(cue.get("duration", 0.5)), 0.45)
			if reduced_motion:
				cue["duration"] = minf(float(cue.get("duration", 0.5)), 0.25)
				if str(cue.get("visual", "pulse")) == "trace":
					cue["visual"] = "pulse"
			emitted.append(cue)
			cue_requested.emit(cue)
	events_presented.emit(normalized_events, context.duplicate(true))
	return emitted


func clear_history() -> void:
	_recent_cues.clear()
	_recent_order.clear()


func profile() -> Dictionary:
	return _profile.duplicate(true)


func _cue_specs(event_type: String, payload: Dictionary) -> Array:
	var specs: Array = []
	var cues: Dictionary = _profile.get("cues", {})
	for cue in cues.get(event_type, []):
		if cue is Dictionary:
			specs.append(cue)
	if event_type == "move_committed" and not payload.get("bonus_hits", []).is_empty():
		for cue in cues.get("theme_bonus", []):
			if cue is Dictionary:
				specs.append(cue)
	return specs


func _event_to_dict(event: Variant) -> Dictionary:
	if event is MatchEvent:
		return event.to_dict()
	if event is Dictionary:
		return event.duplicate(true)
	return {}


func _remember(identity: String) -> void:
	_recent_cues[identity] = true
	_recent_order.append(identity)
	while _recent_order.size() > RECENT_CUE_LIMIT:
		_recent_cues.erase(_recent_order.pop_front())
