## Wizard of Words - an 8-bit wizardly word duel.
## Code sorcery by ox-alpha, an LLM of undisclosed organization,
## conjured in tandem with its human familiar.
extends Control

const COLOR_BG := Color("241a38")
const COLOR_PANEL := Color("33245c")
const COLOR_GOLD := Color("e8b23a")
const COLOR_TEXT := Color("f3ead7")
const COLOR_TILE := Color("5a3fa0")
const COLOR_TILE_SEL := Color("8a6fd0")
const COLOR_TILE_PEND := Color("d9a13a")
const CELL_SIZE := 44.0

var ruleset: WordRuleset
var lexicon: Lexicon
var board: GameBoard
var bag: Array = []
var players: Array = []
var current := 0
var pending: Dictionary = {}
var revealed: Dictionary = {}
var selected_rack := -1
var passes_in_a_row := 0
var game_over := false

var board_grid: GridContainer
var cell_buttons: Dictionary = {}
var rack_box: HBoxContainer
var score_label: Label
var turn_label: Label
var log_label: Label
var play_btn: Button
var recall_btn: Button
var shuffle_btn: Button
var pass_btn: Button
var trade_btn: Button
var new_game_btn: Button
var ruleset_select: OptionButton
var ruleset_preview: TextureRect
var lexicon_checks: Array = []
var ai_difficulty_select: OptionButton
var fog_check: CheckButton
var tile_select: OptionButton
var frame_select: OptionButton
var ai_difficulty := "adept"
var match_log_path := ""
var trade_popup: PopupPanel
var trade_box: HBoxContainer
var trade_selection: Dictionary = {}
var dict_meta: Dictionary = {}
var _reveal_font: FontFile = null
var _reveal_font_tried := false
var _tile_font: FontFile = null
var _tile_font_tried := false
var _display_font: FontFile = null
var _display_font_tried := false
var title_center: Control
var ai_lexicon: Lexicon = null
var ai_check: CheckButton
var setup_panel: PanelContainer
var game_root: HBoxContainer
var blank_popup: PopupPanel
var blank_target := Vector2i(-1, -1)


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_blank_picker()
	_build_setup()
	_build_title()
	_show_title()


func _load_tile_font() -> void:
	_tile_font_tried = true
	for p in ["res://data/typefaces/Dumbledor-Regular.ttf", "res://data/typefaces/Magehunter.ttf"]:
		if FileAccess.file_exists(p):
			var f := FontFile.new()
			if f.load_dynamic_font(p) == OK:
				_tile_font = f
				return


func _load_display_font() -> void:
	_display_font_tried = true
	for p in ["res://data/typefaces/Mage.ttf", "res://data/typefaces/Dumbledor-Regular.ttf"]:
		if FileAccess.file_exists(p):
			var f := FontFile.new()
			if f.load_dynamic_font(p) == OK:
				_display_font = f
				return


func _load_texture_any(path: String) -> Texture2D:
	var tex: Variant = load(path)
	if tex != null and tex is Texture2D:
		return tex
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null:
			return ImageTexture.create_from_image(img)
	return null


func _build_title() -> void:
	title_center = Control.new()
	title_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(title_center)

	var art_path := "res://data/graphics/title screens/Title Screen 2.png"
	if not FileAccess.file_exists(art_path):
		art_path = "res://data/graphics/title screens/titlescreen1.png"
	var has_art := FileAccess.file_exists(art_path)
	if has_art:
		var tex: Texture2D = _load_texture_any(art_path)
		if tex != null:
			var art := TextureRect.new()
			art.texture = tex
			art.set_anchors_preset(Control.PRESET_FULL_RECT)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_SCALE
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			title_center.add_child(art)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.custom_minimum_size = Vector2(420, 0)
	v.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BEGIN
	v.offset_bottom = -48
	title_center.add_child(v)

	if not has_art:
		var t := Label.new()
		t.text = "WIZARD OF WORDS"
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.add_theme_font_size_override("font_size", 46)
		t.add_theme_color_override("font_color", COLOR_GOLD)
		if _display_font == null and not _display_font_tried:
			_load_display_font()
		if _display_font != null:
			t.add_theme_font_override("font", _display_font)
		v.add_child(t)
		v.add_child(_make_caption("A duel of runes upon a living sigil"))

	var quick := _make_button("Quick Play")
	quick.custom_minimum_size = Vector2(280, 0)
	quick.pressed.connect(_on_quick_play)
	v.add_child(quick)

	var create := _make_button("Create")
	create.custom_minimum_size = Vector2(280, 0)
	create.pressed.connect(_show_create)
	v.add_child(create)

	if not has_art:
		var credit := _make_caption("Code sorcery by ox-alpha, an LLM of undisclosed origin")
		credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(credit)


func _hide_game_and_setup() -> void:
	if game_root != null:
		game_root.queue_free()
		game_root = null
	setup_panel.visible = false
	var holder := setup_panel.get_parent()
	if holder is Control:
		holder.visible = false


func _show_title() -> void:
	_hide_game_and_setup()
	title_center.visible = true


func _show_create() -> void:
	title_center.visible = false
	var holder := setup_panel.get_parent()
	if holder is Control:
		holder.visible = true
	setup_panel.visible = true


func _on_quick_play() -> void:
	var path := "user://prefs.json"
	if not FileAccess.file_exists(path):
		_show_create()
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (data is Dictionary):
		_show_create()
		return
	for i in range(ruleset_select.item_count):
		if ruleset_select.get_item_text(i) == str(data.get("ruleset", "")):
			ruleset_select.select(i)
			break
	var wanted: Array = data.get("grimoires", [])
	for cb in lexicon_checks:
		cb.button_pressed = (cb.get_meta("file") in wanted)
	ai_check.button_pressed = bool(data.get("ai", true))
	ai_difficulty_select.selected = int(data.get("difficulty", 1))
	fog_check.button_pressed = bool(data.get("fog", false))
	if tile_select != null:
		tile_select.selected = clampi(int(data.get("tile", 0)), 0, maxi(0, tile_select.item_count - 1))
	if frame_select != null:
		frame_select.selected = clampi(int(data.get("frame", 0)), 0, maxi(0, frame_select.item_count - 1))
	_update_ruleset_preview()
	_on_new_game()


func _save_prefs(rs_name: String, grimoires: Array) -> void:
	var fa := FileAccess.open("user://prefs.json", FileAccess.WRITE)
	if fa == null:
		return
	fa.store_line(JSON.stringify({
		"ruleset": rs_name,
		"grimoires": grimoires,
		"ai": ai_check.button_pressed,
		"difficulty": ai_difficulty_select.selected,
		"fog": fog_check.button_pressed,
		"tile": tile_select.selected if tile_select != null else 0,
		"frame": frame_select.selected if frame_select != null else 0
	}))
	fa.close()


func _list_files(dir_path: String, exts: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if not dir.current_is_dir():
			for e in exts:
				if f.get_extension().to_lower() == e:
					out.append(f)
					break
		f = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


func _build_setup() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	setup_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 30.0
	style.content_margin_right = 30.0
	style.content_margin_top = 24.0
	style.content_margin_bottom = 24.0
	setup_panel.add_theme_stylebox_override("panel", style)
	center.add_child(setup_panel)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(560, 0)
	vbox.add_theme_constant_override("separation", 14)
	setup_panel.add_child(vbox)

	vbox.add_child(_make_title("WIZARD OF WORDS"))
	vbox.add_child(_make_caption("Forge thy spell from runes and grimoires"))

	vbox.add_child(_make_caption("Ruleset"))
	var rs_row := HBoxContainer.new()
	rs_row.add_theme_constant_override("separation", 10)
	vbox.add_child(rs_row)
	var rs_col := VBoxContainer.new()
	rs_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rs_row.add_child(rs_col)
	ruleset_select = OptionButton.new()
	for f in _list_files("res://data/rulesets", ["json"]):
		ruleset_select.add_item(f)
	ruleset_select.item_selected.connect(func(_i): _update_ruleset_preview())
	rs_col.add_child(ruleset_select)
	ruleset_preview = TextureRect.new()
	ruleset_preview.custom_minimum_size = Vector2(96, 96)
	ruleset_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ruleset_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ruleset_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rs_row.add_child(ruleset_preview)
	_update_ruleset_preview()

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	vbox.add_child(cols)
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 6)
	cols.add_child(left_col)
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	cols.add_child(right_col)

	left_col.add_child(_make_caption("Grimoires"))
	right_col.add_child(_make_caption("Bonus Words"))
	lexicon_checks.clear()
	var meta := {}
	var meta_path := "res://data/dictionaries/index.json"
	if FileAccess.file_exists(meta_path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if parsed is Dictionary:
			meta = parsed
	dict_meta = meta
	for f in _list_files("res://data/dictionaries", ["txt", "json"]):
		if f == "index.json" or f.begins_with("profanity_") or f.begins_with("two_letter_"):
			continue
		var cb := CheckBox.new()
		cb.text = str(f.get_basename().replace("_", " ")).capitalize()
		cb.set_meta("file", f)
		var info: Dictionary = meta.get(f, {})
		if info.is_empty():
			info = meta.get(f.get_basename(), {})
		cb.button_pressed = bool(info.get("default_checked", true))
		if not info.is_empty():
			cb.tooltip_text = str(info.get("title", "")) + "\n" + str(info.get("description", ""))
		lexicon_checks.append(cb)
		if info.has("bonus_points"):
			right_col.add_child(cb)
		else:
			left_col.add_child(cb)

	ai_check = CheckButton.new()
	ai_check.text = "Face the Word Wizard (AI)"
	ai_check.button_pressed = true
	vbox.add_child(ai_check)

	vbox.add_child(_make_caption("Wizard Difficulty"))
	ai_difficulty_select = OptionButton.new()
	for d in ["Apprentice", "Adept", "Archmage"]:
		ai_difficulty_select.add_item(d)
	ai_difficulty_select.selected = 1
	vbox.add_child(ai_difficulty_select)

	fog_check = CheckButton.new()
	fog_check.text = "Fog of War"
	fog_check.tooltip_text = "Bonus squares stay hidden until revealed near recently played tiles."
	vbox.add_child(fog_check)

	vbox.add_child(_make_caption("Tile Set"))
	tile_select = OptionButton.new()
	tile_select.add_item("From Ruleset")
	for f in _list_files("res://data/graphics/raw tiles", ["png"]):
		if f.begins_with("Single"):
			tile_select.add_item(f)
	vbox.add_child(tile_select)

	vbox.add_child(_make_caption("Frame"))
	frame_select = OptionButton.new()
	frame_select.add_item("From Ruleset")
	for f in _list_files("res://data/graphics/frames", ["png"]):
		frame_select.add_item(f)
	vbox.add_child(frame_select)

	new_game_btn = _make_button("Begin the Duel")
	new_game_btn.pressed.connect(_on_new_game)
	vbox.add_child(new_game_btn)

	var back := _make_button("Return to Title")
	back.pressed.connect(_show_title)
	vbox.add_child(back)

	var credit := _make_caption("Code sorcery by ox-alpha, an LLM of undisclosed origin")
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(credit)


func _build_blank_picker() -> void:
	blank_popup = PopupPanel.new()
	blank_popup.title = "Choose a rune for thy blank"
	add_child(blank_popup)
	var v := VBoxContainer.new()
	blank_popup.add_child(v)
	v.add_child(_make_caption("The blank takes which rune's power?"))
	var grid := GridContainer.new()
	grid.columns = 7
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	for i in range(26):
		var ch := char(65 + i)
		var b := Button.new()
		b.text = ch
		b.custom_minimum_size = Vector2(44, 44)
		b.pressed.connect(_on_blank_chosen.bind(ch))
		grid.add_child(b)


func _update_ruleset_preview() -> void:
	if ruleset_preview == null or ruleset_select.item_count == 0 or ruleset_select.selected < 0:
		return
	var path := "res://data/rulesets/" + ruleset_select.get_item_text(ruleset_select.selected)
	var rs := WordRuleset.load_from(path)
	if rs == null:
		return
	var n := rs.board_size
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color("241a38"))
	for y in range(n):
		if y >= rs.layout.size():
			continue
		var row := String(rs.layout[y])
		for x in range(min(row.length(), n)):
			var prem: Dictionary = rs.legend.get(row[x], rs.legend["."])
			img.set_pixel(x, y, prem["color"])
	ruleset_preview.texture = ImageTexture.create_from_image(img)
	if fog_check != null:
		fog_check.button_pressed = rs.fog_of_war


func _build_game_ui() -> void:
	game_root = HBoxContainer.new()
	game_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_root.add_theme_constant_override("separation", 20)
	for c in get_children():
		if c != game_root and not (c is ColorRect) and c != blank_popup:
			c.visible = false
	add_child(game_root)

	var board_panel := PanelContainer.new()
	var bp_style := StyleBoxFlat.new()
	bp_style.bg_color = Color("1c1430")
	bp_style.set_content_margin_all(10.0)
	bp_style.set_corner_radius_all(10)
	var frame_tex: Texture2D = null
	if ruleset.skin.has("frame"):
		frame_tex = _load_texture_any(String(ruleset.skin["frame"]))
	if frame_tex != null:
		var board_container := Control.new()
		board_container.custom_minimum_size = Vector2(760, 760)
		game_root.add_child(board_container)
		var frame_rect := NinePatchRect.new()
		frame_rect.texture = frame_tex
		var bw: int = frame_tex.get_width()
		var bh: int = frame_tex.get_height()
		var m: int = int(min(bw, bh) * 0.22)
		frame_rect.patch_margin_left = m
		frame_rect.patch_margin_right = m
		frame_rect.patch_margin_top = m
		frame_rect.patch_margin_bottom = m
		frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		board_container.add_child(frame_rect)
		board_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		board_panel.offset_left = m
		board_panel.offset_top = m
		board_panel.offset_right = -m
		board_panel.offset_bottom = -m
		if ruleset.skin.has("background"):
			var btex2 := _load_texture_any(String(ruleset.skin["background"]))
			if btex2 != null:
				var sbt2 := StyleBoxTexture.new()
				sbt2.texture = btex2
				sbt2.set_content_margin_all(10.0)
				board_panel.add_theme_stylebox_override("panel", sbt2)
			else:
				board_panel.add_theme_stylebox_override("panel", bp_style)
		else:
			board_panel.add_theme_stylebox_override("panel", bp_style)
		board_container.add_child(board_panel)
	else:
		if ruleset.skin.has("background"):
			var btex := _load_texture_any(String(ruleset.skin["background"]))
			if btex != null:
				var sbt := StyleBoxTexture.new()
				sbt.texture = btex
				sbt.set_content_margin_all(10.0)
				board_panel.add_theme_stylebox_override("panel", sbt)
			else:
				board_panel.add_theme_stylebox_override("panel", bp_style)
		else:
			board_panel.add_theme_stylebox_override("panel", bp_style)
		game_root.add_child(board_panel)

	board_grid = GridContainer.new()
	board_grid.columns = ruleset.board_size
	board_grid.add_theme_constant_override("h_separation", 2)
	board_grid.add_theme_constant_override("v_separation", 2)
	board_panel.add_child(board_grid)

	cell_buttons.clear()
	for y in range(ruleset.board_size):
		for x in range(ruleset.board_size):
			var pos := Vector2i(x, y)
			var b := CellButton.new()
			b.game = self
			b.cell_pos = pos
			b.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			b.focus_mode = Control.FOCUS_NONE
			b.pressed.connect(_on_cell_pressed.bind(pos))
			_apply_prem_style(b, pos)
			board_grid.add_child(b)
			cell_buttons[pos] = b

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(400, 0)
	side.add_theme_constant_override("separation", 10)
	game_root.add_child(side)

	var side_panel := PanelContainer.new()
	var sp_style := StyleBoxFlat.new()
	sp_style.bg_color = COLOR_PANEL
	sp_style.set_content_margin_all(16.0)
	sp_style.set_corner_radius_all(10)
	side_panel.add_theme_stylebox_override("panel", sp_style)
	side.add_child(side_panel)

	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 10)
	side_panel.add_child(sv)

	sv.add_child(_make_title("WIZARD OF WORDS"))

	turn_label = _make_body("")
	turn_label.add_theme_color_override("font_color", COLOR_GOLD)
	sv.add_child(turn_label)

	score_label = _make_body("")
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(score_label)

	sv.add_child(HSeparator.new())
	sv.add_child(_make_caption("Thy rack of runes"))

	rack_box = HBoxContainer.new()
	rack_box.add_theme_constant_override("separation", 6)
	sv.add_child(rack_box)

	var btn_row1 := HBoxContainer.new()
	btn_row1.add_theme_constant_override("separation", 8)
	play_btn = _make_button("Cast Spell")
	play_btn.pressed.connect(_on_play)
	btn_row1.add_child(play_btn)
	recall_btn = _make_button("Recall")
	recall_btn.pressed.connect(_on_recall)
	btn_row1.add_child(recall_btn)
	shuffle_btn = _make_button("Shuffle")
	shuffle_btn.pressed.connect(_on_shuffle)
	btn_row1.add_child(shuffle_btn)
	sv.add_child(btn_row1)

	var btn_row2 := HBoxContainer.new()
	btn_row2.add_theme_constant_override("separation", 8)
	pass_btn = _make_button("Pass Turn")
	pass_btn.pressed.connect(_on_pass)
	btn_row2.add_child(pass_btn)
	trade_btn = _make_button("Trade")
	trade_btn.pressed.connect(_open_trade)
	btn_row2.add_child(trade_btn)
	var menu_btn := _make_button("New Game")
	menu_btn.pressed.connect(_back_to_setup)
	btn_row2.add_child(menu_btn)
	sv.add_child(btn_row2)

	sv.add_child(HSeparator.new())
	log_label = _make_body("The duel begins...")
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(0, 180)
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sv.add_child(log_label)


func _apply_tile_look(b: Button, label: String, value: int, base: Color, letter_size := 22) -> void:
	for c in b.get_children():
		b.remove_child(c)
		c.queue_free()
	var sb := StyleBoxFlat.new()
	sb.bg_color = base
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(2.0)
	sb.border_width_bottom = 3
	sb.border_color = base.darkened(0.35)
	b.add_theme_stylebox_override("normal", sb)
	var hov: StyleBoxFlat = sb.duplicate()
	hov.bg_color = base.lightened(0.15)
	b.add_theme_stylebox_override("hover", hov)
	var prs: StyleBoxFlat = sb.duplicate()
	prs.bg_color = base.darkened(0.15)
	b.add_theme_stylebox_override("pressed", prs)
	b.text = ""
	var main := Label.new()
	main.text = label
	main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main.set_anchors_preset(Control.PRESET_FULL_RECT)
	main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main.add_theme_font_size_override("font_size", letter_size)
	main.add_theme_color_override("font_color", Color("f7f2e6"))
	if _tile_font == null and not _tile_font_tried:
		_load_tile_font()
	if _tile_font != null:
		main.add_theme_font_override("font", _tile_font)
	b.add_child(main)
	b.set_meta("main_label", main)
	if value > 0:
		var vlabel := Label.new()
		vlabel.text = str(value)
		vlabel.add_theme_font_size_override("font_size", 10)
		vlabel.add_theme_color_override("font_color", COLOR_GOLD)
		vlabel.modulate.a = 0.0
		vlabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vlabel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		vlabel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		vlabel.grow_vertical = Control.GROW_DIRECTION_BEGIN
		vlabel.offset_right = -3
		vlabel.offset_bottom = -2
		b.add_child(vlabel)
		b.set_meta("value_label", vlabel)
	if not b.has_meta("hover_connected"):
		_wire_hover_fade(b)


func _wire_hover_fade(b: Button) -> void:
	b.set_meta("hover_connected", true)
	b.mouse_entered.connect(func(): _fade_value(b, 1.0))
	b.mouse_exited.connect(func(): _fade_value(b, 0.0))


func _attach_hover_reveal(b: Button, text: String, font_size := 11) -> void:
	var rlabel := Label.new()
	rlabel.text = text
	rlabel.add_theme_font_size_override("font_size", font_size)
	rlabel.add_theme_color_override("font_color", Color("ffffff"))
	if _reveal_font == null and not _reveal_font_tried:
		_load_reveal_font()
	if _reveal_font != null:
		rlabel.add_theme_font_override("font", _reveal_font)
	rlabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rlabel.clip_text = true
	rlabel.modulate.a = 0.0
	rlabel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rlabel.set_anchors_preset(Control.PRESET_FULL_RECT)
	rlabel.offset_left = 2
	rlabel.offset_right = -2
	rlabel.offset_top = 2
	rlabel.offset_bottom = -2
	b.add_child(rlabel)
	b.set_meta("value_label", rlabel)
	_wire_hover_fade(b)


func _load_reveal_font() -> void:
	_reveal_font_tried = true
	for p in ["res://data/typefaces/Dumbledor-Thin.ttf", "res://data/typefaces/Mage.ttf", "res://data/typefaces/Magehunter.ttf"]:
		if not FileAccess.file_exists(p):
			continue
		var f := FontFile.new()
		if f.load_dynamic_font(p) == OK:
			_reveal_font = f
			return


func _fade_value(b: Button, target: float) -> void:
	if not is_instance_valid(b):
		return
	var v = b.get_meta("value_label") if b.has_meta("value_label") else null
	var m = b.get_meta("main_label") if b.has_meta("main_label") else null
	if not is_instance_valid(v) and not is_instance_valid(m):
		return
	var tw := b.create_tween()
	if is_instance_valid(v):
		tw.tween_property(v, "modulate:a", target, 0.15)
	if is_instance_valid(m):
		tw.parallel().tween_property(m, "modulate:a", 1.0 - target * 0.85, 0.15)


func _apply_prem_style(b: Button, pos: Vector2i) -> void:
	var tooltip := ""
	if pending.has(pos):
		var pt: Dictionary = pending[pos]["tile"]
		_apply_tile_look(b, pt["letter"] if pt["letter"] != "" else "?", pt["value"], COLOR_TILE_PEND, 28)
		_add_skin_texture(b)
		return
	if board.tile_at(pos) != null:
		var t: Dictionary = board.tile_at(pos)
		_apply_tile_look(b, t["letter"], t["value"], COLOR_TILE, 28)
		_add_skin_texture(b)
		return
	if ruleset.fog_of_war and not revealed.has(pos):
		_apply_tile_look(b, "", 0, ruleset.legend["."]["color"])
		b.tooltip_text = ""
		return
	var prem: Dictionary = ruleset.premium_at(pos)
	var col: Color = prem["color"]
	var label := String(prem.get("glyph", ""))
	if label != "":
		tooltip = String(prem["name"])
	_apply_tile_look(b, label, 0, col, 20)
	_add_skin_texture(b)
	if label != "":
		var kind := "WORD" if String(prem["type"]) == "word" else "RUNE"
		var short_name := String(prem["name"]).split("(")[0].strip_edges().to_upper()
		if ruleset.skin.has("tiles"):
			var shade := ColorRect.new()
			shade.color = Color(col.r, col.g, col.b, 0.30)
			shade.set_anchors_preset(Control.PRESET_FULL_RECT)
			shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(shade)
			b.move_child(shade, 1)
		_attach_hover_reveal(b, "%s\n%d × %s" % [short_name, int(prem["mult"]), kind], 9)
	b.tooltip_text = tooltip


func _add_skin_texture(b: Button) -> void:
	var tex: Texture2D = _load_texture_any(String(ruleset.skin.get("tiles", "")))
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.self_modulate = Color(1, 1, 1).darkened(randf_range(0.0, 0.06))
	b.add_child(tr)
	b.move_child(tr, 0)


func refresh_board() -> void:
	for pos in cell_buttons:
		var b: Button = cell_buttons[pos]
		_apply_prem_style(b, pos)


func refresh_rack() -> void:
	for c in rack_box.get_children():
		c.queue_free()
	var rack_player: Dictionary = players[current]
	if rack_player.get("is_ai", false):
		for pl in players:
			if not pl.get("is_ai", false):
				rack_player = pl
				break
	var rack: Array = rack_player["rack"]
	for i in range(rack.size()):
		var t: Dictionary = rack[i]
		var b := RackTileButton.new()
		b.game = self
		b.rack_index = i
		b.custom_minimum_size = Vector2(48, 56)
		b.focus_mode = Control.FOCUS_NONE
		var col: Color = COLOR_TILE_SEL if i == selected_rack else COLOR_TILE
		_apply_tile_look(b, t["letter"] if t["letter"] != "" else "?", t["value"], col, 26)
		if i == selected_rack:
			var sel := StyleBoxFlat.new()
			sel.draw_center = false
			sel.set_corner_radius_all(6)
			sel.set_border_width_all(2)
			sel.border_color = COLOR_GOLD
			b.add_theme_stylebox_override("focus", sel)
			b.add_theme_stylebox_override("hover", sel)
		b.disabled = players[current].get("is_ai", false) or game_over
		b.pressed.connect(_on_rack_pressed.bind(i))
		rack_box.add_child(b)


func refresh_hud() -> void:
	var lines := []
	for pl in players:
		var marker := ">>" if pl == players[current] else "  "
		lines.append("%s %s: %d" % [marker, pl["name"], pl["score"]])
	if bag.size() <= 20:
		lines.append("The bag holds but %d rune%s..." % [bag.size(), "" if bag.size() == 1 else "s"])
	score_label.text = "\n".join(lines)
	if game_over:
		turn_label.text = "The duel is over."
	elif players[current].get("is_ai", false):
		turn_label.text = "%s ponders the arcane..." % players[current]["name"]
	else:
		turn_label.text = "%s, weave thy spell" % players[current]["name"]


func refresh_all() -> void:
	refresh_board()
	refresh_rack()
	refresh_hud()


func _log(msg: String) -> void:
	print("[WoW] ", msg)
	log_label.text = msg + "\n" + log_label.text


func _append_move_log(pl: Dictionary, positions: Array, word_names: Array, score: int) -> void:
	if match_log_path == "":
		return
	var pos_data := []
	for p in positions:
		pos_data.append({"x": p.x, "y": p.y})
	var fa := FileAccess.open(match_log_path, FileAccess.READ_WRITE if FileAccess.file_exists(match_log_path) else FileAccess.WRITE)
	if fa == null:
		return
	fa.seek_end()
	fa.store_line(JSON.stringify({
		"time": Time.get_time_string_from_system(),
		"player": pl["name"],
		"words": word_names,
		"score": score,
		"placements": pos_data,
	}))
	fa.close()


func _on_new_game() -> void:
	if ruleset_select.item_count == 0:
		_log("No rulesets found in res://data/rulesets/.")
		return
	var chosen: Array = []
	for cb in lexicon_checks:
		if cb.button_pressed:
			chosen.append(cb.get_meta("file"))
	if chosen.is_empty():
		_log("Select at least one grimoire.")
		return
	var rs_path := "res://data/rulesets/" + ruleset_select.get_item_text(ruleset_select.selected)
	ruleset = WordRuleset.load_from(rs_path)
	if ruleset == null:
		_log("Failed to load ruleset.")
		return
	lexicon = Lexicon.new()
	var names: Array = []
	for fname in chosen:
		var lx := Lexicon.load_from("res://data/dictionaries/" + str(fname))
		if lx == null:
			continue
		names.append(lx.lexicon_name)
		lexicon.merge_from(lx)
		var info: Dictionary = dict_meta.get(str(fname), {})
		var pts := int(info.get("bonus_points", 0))
		if pts > 0:
			lexicon.bonus_sets.append({
				"label": str(info.get("bonus_flavor", "Magic surges")),
				"points": pts,
				"words": lx.words.duplicate()
			})
	if lexicon.words.is_empty():
		_log("Failed to load grimoires.")
		return
	lexicon.lexicon_name = " + ".join(names)
	ai_difficulty = ["apprentice", "adept", "archmage"][ai_difficulty_select.selected]
	ai_lexicon = null
	_save_prefs(ruleset_select.get_item_text(ruleset_select.selected), chosen)
	var bl_path := "res://data/dictionaries/profanity_blacklist.txt"
	if FileAccess.file_exists(bl_path):
		lexicon.blacklist = Lexicon.load_word_set(bl_path)
	var tl_path := "res://data/dictionaries/two_letter_whitelist.txt"
	if FileAccess.file_exists(tl_path):
		lexicon.trusted_two_letter = Lexicon.load_word_set(tl_path)
	else:
		lexicon.trusted_two_letter = lexicon.words.duplicate()
	var errs := ruleset.validate()
	if not errs.is_empty():
		_log("Ruleset errors: " + "; ".join(errs))
		return
	if fog_check != null:
		ruleset.fog_of_war = fog_check.button_pressed
	if tile_select != null and tile_select.selected > 0:
		ruleset.skin["tiles"] = "res://data/graphics/raw tiles/" + tile_select.get_item_text(tile_select.selected)
	if frame_select != null and frame_select.selected > 0:
		ruleset.skin["frame"] = "res://data/graphics/frames/" + frame_select.get_item_text(frame_select.selected)

	board = GameBoard.new()
	board.setup(ruleset.board_size)
	bag = []
	for letter in ruleset.letters:
		for i in range(int(ruleset.letters[letter]["count"])):
			bag.append({"letter": letter, "value": int(ruleset.letters[letter]["value"]), "blank": false})
	for i in range(ruleset.blank_count):
		bag.append({"letter": "", "value": 0, "blank": true})
	bag.shuffle()

	players = [
		{"name": "Apprentice", "score": 0, "rack": [], "is_ai": false},
	]
	players.append({"name": "Word Wizard", "score": 0, "rack": [], "is_ai": ai_check.button_pressed} if ai_check.button_pressed else {"name": "Rival Apprentice", "score": 0, "rack": [], "is_ai": false})
	for pl in players:
		_refill(pl)
	current = 0
	pending.clear()
	selected_rack = -1
	passes_in_a_row = 0
	game_over = false
	DirAccess.make_dir_recursive_absolute("user://game_logs")
	match_log_path = "user://game_logs/match_%d.jsonl" % Time.get_unix_time_from_system()
	revealed.clear()
	if ruleset.fog_of_war:
		for dy in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
			for dx in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
				var rp: Vector2i = board.center() + Vector2i(dx, dy)
				if board.in_bounds(rp):
					revealed[rp] = true

	if game_root != null:
		game_root.queue_free()
		game_root = null
	_build_game_ui()
	_log("Grimoire loaded: %s (%d words). Ruleset: %s." % [lexicon.lexicon_name, lexicon.size(), ruleset.ruleset_name])
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _refill(pl: Dictionary) -> void:
	while pl["rack"].size() < ruleset.rack_size and bag.size() > 0:
		pl["rack"].append(bag.pop_back())


func _on_rack_pressed(i: int) -> void:
	selected_rack = -1 if selected_rack == i else i
	refresh_rack()


func _on_cell_pressed(pos: Vector2i) -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if pending.has(pos):
		var ptile: Dictionary = pending[pos]["tile"]
		pending.erase(pos)
		players[current]["rack"].append(ptile)
		selected_rack = -1
		refresh_all()
		return
	if board.tile_at(pos) != null:
		return
	if selected_rack < 0:
		_log("Select a rune from thy rack first.")
		return
	var tile: Dictionary = players[current]["rack"][selected_rack]
	if tile["blank"]:
		blank_target = pos
		blank_popup.popup_centered()
		return
	_place_selected(pos, tile)


func _place_selected(pos: Vector2i, tile: Dictionary) -> void:
	var rack: Array = players[current]["rack"]
	rack.remove_at(selected_rack)
	pending[pos] = {"pos": pos, "tile": tile}
	selected_rack = -1
	refresh_all()


func get_rack_drag(index: int) -> Dictionary:
	if game_over or players[current].get("is_ai", false):
		return {}
	if index < 0 or index >= players[current]["rack"].size():
		return {}
	return {"kind": "rack", "index": index}


func get_board_drag(pos: Vector2i) -> Variant:
	if game_over or players[current].get("is_ai", false):
		return null
	if pending.has(pos):
		return {"kind": "board", "pos": pos}
	return null


func can_drop(pos: Vector2i, data: Variant) -> bool:
	if game_over or players[current].get("is_ai", false):
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if board.tile_at(pos) != null or pending.has(pos):
		return false
	var kind := String(data.get("kind", ""))
	return kind == "rack" or kind == "board"


func handle_drop(pos: Vector2i, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	match String(data.get("kind", "")):
		"rack":
			selected_rack = int(data["index"])
			var tile: Dictionary = players[current]["rack"][selected_rack]
			if tile["blank"]:
				blank_target = pos
				blank_popup.popup_centered()
				return
			_place_selected(pos, tile)
		"board":
			var src := Vector2i(data["pos"])
			if not pending.has(src) or pending.has(pos):
				return
			var item: Dictionary = pending[src]
			pending.erase(src)
			item["pos"] = pos
			pending[pos] = item
			refresh_all()


func _on_blank_chosen(ch: String) -> void:
	blank_popup.hide()
	if blank_target.x < 0 or selected_rack < 0:
		return
	var tile: Dictionary = players[current]["rack"][selected_rack]
	tile["letter"] = ch
	tile["chosen_blank_letter"] = ch
	_place_selected(blank_target, tile)
	blank_target = Vector2i(-1, -1)


func _on_recall() -> void:
	if players[current].get("is_ai", false):
		return
	for pos in pending.keys():
		recall_tile(pos)
	selected_rack = -1
	refresh_all()


func recall_tile(pos: Vector2i) -> void:
	if not pending.has(pos):
		return
	var item: Dictionary = pending[pos]
	var t: Dictionary = item["tile"]
	if t["blank"]:
		t["letter"] = ""
		t.erase("chosen_blank_letter")
	pending.erase(pos)
	players[current]["rack"].append(t)
	selected_rack = -1
	refresh_all()


func _on_shuffle() -> void:
	if players[current].get("is_ai", false):
		return
	players[current]["rack"].shuffle()
	selected_rack = -1
	refresh_rack()


func reorder_rack(from_i: int, to_i: int) -> void:
	if game_over or players[current].get("is_ai", false):
		return
	var rack: Array = players[current]["rack"]
	if from_i < 0 or to_i < 0 or from_i >= rack.size() or to_i >= rack.size() or from_i == to_i:
		return
	var t = rack[from_i]
	rack.remove_at(from_i)
	rack.insert(to_i, t)
	selected_rack = -1
	refresh_rack()


func _pending_array() -> Array:
	var arr := []
	for pos in pending:
		arr.append(pending[pos])
	return arr


func _on_play() -> void:
	if game_over or players[current].get("is_ai", false):
		return
	var res := MoveLogic.validate(board, _pending_array(), ruleset, lexicon)
	if not res["ok"]:
		_log(res["error"])
		return
	_commit_move(res)


func _commit_move(res: Dictionary) -> void:
	var pl: Dictionary = players[current]
	var word_names := []
	for w in res["words"]:
		word_names.append(w["word"])
	var placed_positions: Array = []
	for pos in pending:
		board.place(pos, pending[pos]["tile"])
		placed_positions.append(pos)
	pending.clear()
	if ruleset.fog_of_war:
		for p0 in placed_positions:
			for dy in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
				for dx in range(-ruleset.fog_radius, ruleset.fog_radius + 1):
					var rp: Vector2i = Vector2i(p0) + Vector2i(dx, dy)
					if board.in_bounds(rp):
						revealed[rp] = true
	selected_rack = -1
	_refill(pl)
	pl["score"] += res["score"]
	passes_in_a_row = 0
	var who: String = pl["name"]
	_log("%s cast '%s' for %d point%s!" % [who, " ".join(word_names), res["score"], "" if res["score"] == 1 else "s"])
	for bh in res.get("bonus_hits", []):
		var bws: Array = bh["words"]
		_log("%s - '%s' resonate%s (+%d)!" % [bh["label"], " ".join(bws), "s" if bws.size() > 1 else "", int(bws.size()) * int(bh["points"])])
	_append_move_log(pl, placed_positions, word_names, int(res["score"]))
	_check_end()
	if game_over:
		refresh_all()
		return
	current = (current + 1) % players.size()
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _get_ai_lexicon() -> Lexicon:
	if ai_lexicon != null:
		return ai_lexicon
	ai_lexicon = Lexicon.new()
	ai_lexicon.blacklist = lexicon.blacklist
	ai_lexicon.trusted_two_letter = lexicon.trusted_two_letter
	var banned := {}
	for bset in lexicon.bonus_sets:
		for w in bset["words"]:
			banned[w] = true
	for w in lexicon.words:
		if not banned.has(w):
			ai_lexicon.words[w] = true
	return ai_lexicon


func _run_ai_turn() -> void:
	var pl: Dictionary = players[current]
	refresh_hud()
	var think_time := randf_range(1.3, 2.6)
	var elapsed := 0.0
	while elapsed < think_time and not game_over and players[current].get("is_ai", false):
		var dots := ".".repeat(1 + int(elapsed * 3.0) % 3)
		turn_label.text = "%s ponders the arcane%s" % [pl["name"], dots]
		turn_label.modulate.a = 0.65 + 0.35 * absf(sin(elapsed * 5.0))
		await get_tree().create_timer(0.25).timeout
		elapsed += 0.25
	turn_label.modulate.a = 1.0
	if game_over or not players[current].get("is_ai", false):
		return
	var lex_for_ai := lexicon if ai_difficulty == "archmage" else _get_ai_lexicon()
	var move: Variant = AiPlayer.choose_move(board, pl["rack"], ruleset, lex_for_ai, ai_difficulty)
	if move.is_empty():
		if bag.size() > 0 and pl["rack"].size() < ruleset.rack_size:
			_log("%s exchanges runes and passes." % pl["name"])
			for t in pl["rack"]:
				bag.push_front(t)
			pl["rack"].clear()
			_refill(pl)
		else:
			_log("%s cannot find a spell and passes." % pl["name"])
			passes_in_a_row += 1
			if passes_in_a_row >= players.size() * 3:
				_end_game()
				refresh_all()
				return
		current = (current + 1) % players.size()
		refresh_all()
		if players[current].get("is_ai", false):
			_run_ai_turn()
		return
	var res := MoveLogic.validate(board, move, ruleset, lexicon)
	if res["ok"]:
		var rack: Array = pl["rack"]
		for item in move:
			var t: Dictionary = item["tile"]
			for i in range(rack.size()):
				var r: Dictionary = rack[i]
				if bool(r["blank"]) == bool(t["blank"]) and (bool(t["blank"]) or r["letter"] == t["letter"]):
					rack.remove_at(i)
					break
			pending[item["pos"]] = {"pos": item["pos"], "tile": t}
		_commit_move(res)
	else:
		_log("%s fumbled a spell (%s) and passes." % [pl["name"], res["error"]])
		passes_in_a_row += 1
		current = (current + 1) % players.size()
		refresh_all()
		if players[current].get("is_ai", false):
			_run_ai_turn()


func _open_trade() -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if not pending.is_empty():
		_on_recall()
	_ensure_trade_popup()
	trade_selection.clear()
	for c in trade_box.get_children():
		c.queue_free()
	var rack: Array = players[current]["rack"]
	for i in range(rack.size()):
		var idx := i
		var t: Dictionary = rack[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(44, 50)
		b.toggle_mode = true
		b.text = t["letter"] if t["letter"] != "" else "?"
		b.toggled.connect(func(on):
			if on:
				trade_selection[idx] = true
			else:
				trade_selection.erase(idx))
		trade_box.add_child(b)
	trade_popup.popup_centered()


func _ensure_trade_popup() -> void:
	if trade_popup != null:
		return
	trade_popup = PopupPanel.new()
	trade_popup.title = "Trade Runes"
	add_child(trade_popup)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.custom_minimum_size = Vector2(320, 0)
	trade_popup.add_child(v)
	v.add_child(_make_caption("Choose runes to sacrifice to the bag"))
	trade_box = HBoxContainer.new()
	trade_box.add_theme_constant_override("separation", 6)
	v.add_child(trade_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var ok := _make_button("Trade Them")
	ok.pressed.connect(_confirm_trade)
	row.add_child(ok)
	var cancel := _make_button("Never Mind")
	cancel.pressed.connect(func(): trade_popup.hide())
	row.add_child(cancel)
	v.add_child(row)


func _confirm_trade() -> void:
	trade_popup.hide()
	if game_over or players[current].get("is_ai", false) or trade_selection.is_empty():
		return
	if bag.size() < trade_selection.size():
		_log("Too few runes remain in the bag to trade.")
		return
	var rack: Array = players[current]["rack"]
	var indices: Array = trade_selection.keys()
	indices.sort()
	trade_selection.clear()
	var removed: Array = []
	for i in range(indices.size() - 1, -1, -1):
		var ri: int = indices[i]
		if ri >= 0 and ri < rack.size():
			removed.append(rack[ri])
			rack.remove_at(ri)
	for t in removed:
		bag.push_front(t)
	bag.shuffle()
	_refill(players[current])
	passes_in_a_row += 1
	_log("%s trades %d rune%s back to the sigil." % [players[current]["name"], removed.size(), "" if removed.size() == 1 else "s"])
	current = (current + 1) % players.size()
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _on_pass() -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if not pending.is_empty():
		_on_recall()
	passes_in_a_row += 1
	_log("%s passes. The air crackles..." % players[current]["name"])
	if passes_in_a_row >= players.size() * 3:
		_end_game()
		refresh_all()
		return
	current = (current + 1) % players.size()
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _check_end() -> void:
	for pl in players:
		if pl["rack"].is_empty() and bag.is_empty():
			_end_game()
			return


func _end_game() -> void:
	MoveLogic.final_adjustment(players, ruleset)
	game_over = true
	var best_score := -999999
	var winners := []
	for pl in players:
		if pl["score"] > best_score:
			best_score = pl["score"]
			winners = [pl["name"]]
		elif pl["score"] == best_score:
			winners.append(pl["name"])
	_log("The duel ends! Victor: %s with %d points." % [" & ".join(winners), best_score])


func _back_to_setup() -> void:
	_show_title()


func _make_title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", COLOR_GOLD)
	return l


func _make_caption(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color("b9a8e0"))
	l.add_theme_font_size_override("font_size", 14)
	return l


func _make_body(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", COLOR_TEXT)
	l.add_theme_font_size_override("font_size", 16)
	return l


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("4a3585")
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	b.add_theme_stylebox_override("normal", sb)
	var hov: StyleBoxFlat = sb.duplicate()
	hov.bg_color = Color("5d46a5")
	b.add_theme_stylebox_override("hover", hov)
	var prs: StyleBoxFlat = sb.duplicate()
	prs.bg_color = Color("3a2a6b")
	b.add_theme_stylebox_override("pressed", prs)
	b.add_theme_color_override("font_color", COLOR_TEXT)
	return b
