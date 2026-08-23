class_name UiFactory
extends RefCounted

const COLOR_GOLD := Color("e8b23a")
const COLOR_TEXT := Color("f3ead7")
const COLOR_CAPTION := Color("b9a8e0")


static func make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", COLOR_GOLD)
	return label


static func make_caption(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_CAPTION)
	label.add_theme_font_size_override("font_size", 14)
	return label


static func make_body(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", 16)
	return label


static func make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("4a3585")
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 12.0
	normal.content_margin_right = 12.0
	normal.content_margin_top = 6.0
	normal.content_margin_bottom = 6.0
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("5d46a5")
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("3a2a6b")
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	return button


static func load_texture_any(path: String) -> Texture2D:
	var texture: Variant = load(path)
	if texture != null and texture is Texture2D:
		return texture
	if FileAccess.file_exists(path):
		var image := Image.load_from_file(path)
		if image != null:
			return ImageTexture.create_from_image(image)
	return null


static func list_files(dir_path: String, extensions: Array) -> PackedStringArray:
	var files := PackedStringArray()
	var directory := DirAccess.open(dir_path)
	if directory == null:
		return files
	directory.list_dir_begin()
	var filename := directory.get_next()
	while filename != "":
		if not directory.current_is_dir():
			for extension in extensions:
				if filename.get_extension().to_lower() == extension:
					files.append(filename)
					break
		filename = directory.get_next()
	directory.list_dir_end()
	files.sort()
	return files
