extends SceneTree


func _initialize() -> void:
	var n := 15
	var ctr := 7
	var grid: Dictionary = {}
	for y in range(n):
		for x in range(n):
			grid[Vector2i(x, y)] = "."
	grid[Vector2i(7, 7)] = "*"
	for p in [Vector2i(0, 0), Vector2i(14, 14), Vector2i(0, 14), Vector2i(14, 0)]:
		grid[p] = "T"
	var rings: Dictionary = {}
	for k in range(2, 8):
		rings[k] = _ring(k, ctr)
	for k in range(2, 8):
		var ring: Array = rings[k]
		var ln := ring.size()
		var frac := fmod(0.6180339887 * k, 1.0)
		var seg_start := int(frac * ln)
		var seg_len := 2 if k % 2 == 0 else 3
		var g := "d"
		if k == 6:
			g = "D"
		elif k == 7:
			g = "T"
		elif k == 5:
			g = "t"
		elif k == 4:
			g = "D"
		for j in range(seg_len):
			var idx := (seg_start + j) % ln
			var cel: Vector2i = ring[idx]
			if grid[cel] != ".":
				continue
			grid[cel] = g
			var partner := Vector2i(14 - cel.x, 14 - cel.y)
			if grid[partner] == ".":
				grid[partner] = g
	for y in range(n):
		var row := ""
		for x in range(n):
			row += grid[Vector2i(x, y)]
		print('"%s",' % row)
	quit(0)


func _ring(k: int, c: int) -> Array:
	var cells: Array = []
	for x in range(c - k, c + k + 1):
		cells.append(Vector2i(x, c - k))
	for y in range(c - k + 1, c + k + 1):
		cells.append(Vector2i(c + k, y))
	for x in range(c + k - 1, c - k - 1, -1):
		cells.append(Vector2i(x, c + k))
	for y in range(c + k - 1, c - k, -1):
		cells.append(Vector2i(c - k, y))
	return cells
