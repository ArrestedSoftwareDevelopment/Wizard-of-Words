class_name EffectLayer
extends Control

const TRANSIENT_EFFECT_CUE := preload("res://scripts/effects/transient_effect_cue.gd")

@onready var atmosphere_canvas: Control = %AtmosphereCanvas
@onready var board_canvas: Control = %BoardCanvas
@onready var foreground_canvas: Control = %ForegroundCanvas

var _director: Node
var _board_view: BoardView


func bind(director: Node, board_view: BoardView) -> void:
	if _director != null and _director.cue_requested.is_connected(_on_cue_requested):
		_director.cue_requested.disconnect(_on_cue_requested)
	_director = director
	_board_view = board_view
	if _director != null:
		_director.cue_requested.connect(_on_cue_requested)


func clear() -> void:
	for canvas in [atmosphere_canvas, board_canvas, foreground_canvas]:
		for child in canvas.get_children():
			child.queue_free()


func _exit_tree() -> void:
	if _director != null and _director.cue_requested.is_connected(_on_cue_requested):
		_director.cue_requested.disconnect(_on_cue_requested)


func _on_cue_requested(cue: Dictionary) -> void:
	var target := _canvas_for(str(cue.get("layer", "board")))
	var points := _event_points(cue.get("payload", {}), target)
	var transient := TRANSIENT_EFFECT_CUE.new()
	target.add_child(transient)
	transient.play(cue, points)


func _canvas_for(layer_name: String) -> Control:
	match layer_name:
		"atmosphere":
			return atmosphere_canvas
		"foreground":
			return foreground_canvas
		_:
			return board_canvas


func _event_points(payload: Dictionary, canvas: Control) -> PackedVector2Array:
	var positions: Array = payload.get("positions", [])
	if positions.is_empty() and payload.has("x") and payload.has("y"):
		positions = [{"x": payload["x"], "y": payload["y"]}]
	var points := PackedVector2Array()
	if is_instance_valid(_board_view):
		var inverse := canvas.get_global_transform().affine_inverse()
		for position in positions:
			if position is Dictionary:
				var center := _board_view.cell_global_center(Vector2i(int(position.get("x", -1)), int(position.get("y", -1))))
				if center != Vector2.INF:
					points.append(inverse * center)
		if points.is_empty():
			var board_center := _board_view.global_position + _board_view.size * 0.5
			points.append(inverse * board_center)
	if points.is_empty():
		points.append(canvas.size * 0.5)
	return points
