extends SceneTree

# Converts a baked pale-neutral preview matte into real transparency while
# decontaminating partially transparent edge colors. Intended for generated
# sprite sheets whose artwork is saturated or dark and whose matte is white or
# light gray.


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Usage: -- <source image> <destination png>")
		quit(2)
		return
	var source_path := ProjectSettings.globalize_path(args[0])
	var destination_path := ProjectSettings.globalize_path(args[1])
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Could not load source image: %s" % source_path)
		quit(2)
		return
	source.convert(Image.FORMAT_RGBA8)
	var output := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			output.set_pixel(x, y, _extract_pixel(source.get_pixel(x, y)))
	var error := output.save_png(destination_path)
	if error != OK:
		push_error("Could not save transparent image: %s" % destination_path)
		quit(2)
		return
	print("RESULT: WROTE %s" % destination_path)
	quit(0)


func _extract_pixel(color: Color) -> Color:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	var chroma := brightest - darkest
	var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	var color_alpha := smoothstep(0.035, 0.15, chroma)
	var dark_alpha := 1.0 - smoothstep(0.72, 0.92, luminance)
	var alpha := maxf(color_alpha, dark_alpha)
	if alpha < 0.08:
		return Color(0, 0, 0, 0)
	if alpha > 0.985:
		return Color(color.r, color.g, color.b, 1.0)
	# Unmix the pale checker from antialiased edge pixels. This prevents the
	# familiar white fringe when the result is drawn over a dark board.
	const MATTE := 0.976
	var recovered := Color(
		clampf((color.r - (1.0 - alpha) * MATTE) / alpha, 0.0, 1.0),
		clampf((color.g - (1.0 - alpha) * MATTE) / alpha, 0.0, 1.0),
		clampf((color.b - (1.0 - alpha) * MATTE) / alpha, 0.0, 1.0),
		alpha
	)
	return recovered
