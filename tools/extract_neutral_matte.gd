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
	var matte_mask := _build_matte_mask(source)
	var output := Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	for y in source.get_height():
		for x in source.get_width():
			var index := y * source.get_width() + x
			if matte_mask[index] == 1:
				output.set_pixel(x, y, Color(0, 0, 0, 0))
			elif _near_matte(matte_mask, source.get_width(), source.get_height(), x, y):
				output.set_pixel(x, y, _extract_pixel(source.get_pixel(x, y)))
			else:
				var preserved := source.get_pixel(x, y)
				preserved.a = 1.0
				output.set_pixel(x, y, preserved)
	var error := output.save_png(destination_path)
	if error != OK:
		push_error("Could not save transparent image: %s" % destination_path)
		quit(2)
		return
	print("RESULT: WROTE %s" % destination_path)
	quit(0)


func _build_matte_mask(image: Image) -> PackedByteArray:
	var width := image.get_width()
	var height := image.get_height()
	var pixel_count := width * height
	var candidates := PackedByteArray()
	var visited := PackedByteArray()
	var matte := PackedByteArray()
	candidates.resize(pixel_count)
	visited.resize(pixel_count)
	matte.resize(pixel_count)
	for y in height:
		for x in width:
			var color := image.get_pixel(x, y)
			var brightest := maxf(color.r, maxf(color.g, color.b))
			var darkest := minf(color.r, minf(color.g, color.b))
			var chroma := brightest - darkest
			var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			# Broad neutral candidates are safe here because only components that
			# reach a cell edge (or form a large empty hole) become matte. This
			# also catches dim checker seams and generated guide lines.
			if luminance >= 0.65 and chroma <= 0.055:
				candidates[y * width + x] = 1

	for start in pixel_count:
		if candidates[start] == 0 or visited[start] == 1:
			continue
		var component: Array[int] = []
		var queue: Array[int] = [start]
		var queue_index := 0
		var touches_cell_edge := false
		visited[start] = 1
		while queue_index < queue.size():
			var index: int = queue[queue_index]
			queue_index += 1
			component.append(index)
			var x: int = index % width
			var y: int = index / width
			if x % 512 == 0 or x % 512 == 511 or y % 512 == 0 or y % 512 == 511:
				touches_cell_edge = true
			for neighbor_value in [index - 1, index + 1, index - width, index + width]:
				var neighbor: int = neighbor_value
				if neighbor < 0 or neighbor >= pixel_count:
					continue
				var neighbor_x: int = neighbor % width
				if abs(neighbor_x - x) > 1:
					continue
				if candidates[neighbor] == 1 and visited[neighbor] == 0:
					visited[neighbor] = 1
					queue.append(neighbor)
		if touches_cell_edge or component.size() >= 400:
			for index in component:
				matte[index] = 1
	return matte


func _near_matte(mask: PackedByteArray, width: int, height: int, x: int, y: int) -> bool:
	for offset_y in range(-2, 3):
		var sample_y := y + offset_y
		if sample_y < 0 or sample_y >= height:
			continue
		for offset_x in range(-2, 3):
			var sample_x := x + offset_x
			if sample_x < 0 or sample_x >= width:
				continue
			if mask[sample_y * width + sample_x] == 1:
				return true
	return false


func _extract_pixel(color: Color) -> Color:
	var brightest := maxf(color.r, maxf(color.g, color.b))
	var darkest := minf(color.r, minf(color.g, color.b))
	var chroma := brightest - darkest
	var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
	# The tighter neutral range protects pale ivory, parchment, bone, and linen
	# while still rejecting the nearly achromatic white/checker matte.
	var color_alpha := smoothstep(0.025, 0.10, chroma)
	var dark_alpha := 1.0 - smoothstep(0.88, 0.95, luminance)
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
