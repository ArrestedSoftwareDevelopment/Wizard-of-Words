extends SceneTree

const ATLAS_PATH := "res://data/graphics/glyphs/generated/velvet_leather/Velvet and Leather Pictograph Atlas v3.png"
const CELL_SIZE := Vector2i(512, 512)
const OCCUPIED_CELLS := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1),
]
const EMPTY_CELL := Vector2i(2, 1)
const CENTER_TOLERANCE := 18.0


func _initialize() -> void:
	var failures: Array[String] = []
	var texture := load(ATLAS_PATH) as Texture2D
	if texture == null:
		failures.append("pictograph atlas could not be loaded")
		_finish(failures)
		return
	var image := texture.get_image()
	if image == null or image.get_size() != Vector2i(1536, 1024):
		failures.append("pictograph atlas must import at 1536x1024")
		_finish(failures)
		return
	image.save_png("res://.godot/velvet-pictograph-atlas-v3.png")
	var actual_size_preview := image.duplicate()
	actual_size_preview.resize(144, 96, Image.INTERPOLATE_LANCZOS)
	actual_size_preview.save_png("res://.godot/velvet-pictograph-atlas-v3-at-48px.png")

	for cell in OCCUPIED_CELLS:
		var bounds := _alpha_bounds(image, cell)
		if bounds.size == Vector2i.ZERO:
			failures.append("occupied cell %s is transparent" % cell)
			continue
		var local_center := Vector2(bounds.position + bounds.size / 2 - cell * CELL_SIZE)
		var offset := local_center - Vector2(CELL_SIZE) / 2.0
		if absf(offset.x) > CENTER_TOLERANCE or absf(offset.y) > CENTER_TOLERANCE:
			failures.append("cell %s visual center is offset by %s" % [cell, offset])

	if _alpha_bounds(image, EMPTY_CELL).size != Vector2i.ZERO:
		failures.append("bottom-right atlas cell must remain transparent")
	_finish(failures)


func _alpha_bounds(image: Image, cell: Vector2i) -> Rect2i:
	var origin := cell * CELL_SIZE
	var minimum := origin + CELL_SIZE
	var maximum := origin - Vector2i.ONE
	for y in range(origin.y, origin.y + CELL_SIZE.y):
		for x in range(origin.x, origin.x + CELL_SIZE.x):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _finish(failures: Array[String]) -> void:
	if failures.is_empty():
		print("RESULT: ALL PASS")
		quit(0)
	else:
		print("RESULT: FAIL ", failures)
		quit(1)
