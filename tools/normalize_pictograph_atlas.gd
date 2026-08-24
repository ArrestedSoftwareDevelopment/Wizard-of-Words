extends SceneTree

const CELL_SIZE := Vector2i(512, 512)
const TARGET_EXTENT := 370.0
const OCCUPIED_CELLS := [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1),
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Usage: -- <transparent atlas> <normalized destination png>")
		quit(2)
		return
	var source_path := ProjectSettings.globalize_path(args[0])
	var destination_path := ProjectSettings.globalize_path(args[1])
	var source := Image.load_from_file(source_path)
	if source == null or source.get_size() != Vector2i(1536, 1024):
		push_error("Expected a 1536x1024 atlas: %s" % source_path)
		quit(2)
		return
	source.convert(Image.FORMAT_RGBA8)
	var output := Image.create(1536, 1024, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	for cell in OCCUPIED_CELLS:
		var bounds := _alpha_bounds(source, cell)
		if bounds.size == Vector2i.ZERO:
			push_error("Atlas cell %s has no artwork" % cell)
			quit(2)
			return
		var glyph := source.get_region(bounds)
		var scale := TARGET_EXTENT / float(maxi(glyph.get_width(), glyph.get_height()))
		var normalized_size := Vector2i(
			maxi(1, roundi(glyph.get_width() * scale)),
			maxi(1, roundi(glyph.get_height() * scale))
		)
		glyph.resize(normalized_size.x, normalized_size.y, Image.INTERPOLATE_LANCZOS)
		var destination: Vector2i = cell * CELL_SIZE + (CELL_SIZE - normalized_size) / 2
		output.blend_rect(glyph, Rect2i(Vector2i.ZERO, normalized_size), destination)
	var error := output.save_png(destination_path)
	if error != OK:
		push_error("Could not save normalized atlas: %s" % destination_path)
		quit(2)
		return
	print("RESULT: WROTE %s" % destination_path)
	quit(0)


func _alpha_bounds(image: Image, cell: Vector2i) -> Rect2i:
	var origin := cell * CELL_SIZE
	var minimum := origin + CELL_SIZE
	var maximum := origin - Vector2i.ONE
	for y in range(origin.y, origin.y + CELL_SIZE.y):
		for x in range(origin.x, origin.x + CELL_SIZE.x):
			if image.get_pixel(x, y).a <= 0.08:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
