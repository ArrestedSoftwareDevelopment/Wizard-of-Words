class_name TransientEffectCue
extends Control

var _visual := "pulse"
var _color := Color.WHITE
var _opacity := 0.8
var _points := PackedVector2Array()
var _radius := 30.0
var _line_width := 3.0


func play(cue: Dictionary, local_points: PackedVector2Array) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual = str(cue.get("visual", "pulse"))
	_color = Color(str(cue.get("color", "#ffffff")))
	_opacity = clampf(float(cue.get("opacity", 0.8)), 0.0, 1.0)
	_radius = float(cue.get("radius", 30.0))
	_line_width = float(cue.get("line_width", 3.0))
	var anchor := _centroid(local_points)
	position = anchor
	size = Vector2.ONE
	pivot_offset = Vector2.ZERO
	for point in local_points:
		_points.append(point - anchor)
	if _points.is_empty():
		_points.append(Vector2.ZERO)
	if _visual == "score":
		_add_score_label(int(cue.get("payload", {}).get("score", 0)))
	queue_redraw()
	var duration := maxf(0.08, float(cue.get("duration", 0.5)))
	modulate.a = _opacity
	scale = Vector2.ONE * (0.88 if not bool(cue.get("reduced_motion", false)) else 1.0)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	if not bool(cue.get("reduced_motion", false)):
		tween.tween_property(self, "scale", Vector2.ONE * 1.18, duration)
		if _visual == "score":
			tween.tween_property(self, "position:y", position.y - 34.0, duration)
	tween.finished.connect(queue_free)


func _draw() -> void:
	var draw_color := Color(_color, 1.0)
	match _visual:
		"trace":
			if _points.size() > 1:
				draw_polyline(_points, draw_color, _line_width, true)
			for point in _points:
				draw_circle(point, maxf(2.0, _line_width), draw_color)
		"settle":
			draw_arc(_points[0], _radius, 0.0, TAU, 32, draw_color, _line_width, true)
			draw_circle(_points[0], 3.0, draw_color)
		"bonus":
			draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, draw_color, _line_width, true)
			draw_arc(Vector2.ZERO, _radius * 0.62, 0.0, TAU, 40, draw_color, maxf(1.0, _line_width * 0.5), true)
		"victory":
			for index in range(3):
				draw_arc(Vector2.ZERO, _radius * (1.0 + index * 0.42), 0.0, TAU, 64, draw_color, _line_width, true)
		"score":
			pass
		_:
			draw_circle(Vector2.ZERO, _radius, Color(_color, 0.16))
			draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 40, draw_color, _line_width, true)


func _add_score_label(score: int) -> void:
	var label := Label.new()
	label.text = "+%d" % score
	label.position = Vector2(-70.0, -34.0)
	label.size = Vector2(140.0, 68.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", _color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 34)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)


func _centroid(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())
