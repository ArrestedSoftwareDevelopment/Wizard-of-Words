## Wizard of Words - an 8-bit wizardly word duel.
## Code sorcery by ox-alpha, an LLM of undisclosed organization,
## conjured in tandem with its human familiar.
extends Control

const COLOR_BG := Color("241a38")
const COLOR_GOLD := Color("e8b23a")
const COLOR_TILE := Color("5a3fa0")
const COLOR_TILE_SEL := Color("8a6fd0")
const COLOR_TILE_PEND := Color("d9a13a")
const CELL_SIZE := 44.0
const BOARD_SHELL_SCENE := preload("res://scenes/components/board_shell.tscn")
const TITLE_SCREEN_SCENE := preload("res://scenes/screens/title_screen.tscn")
const SETUP_SCREEN_SCENE := preload("res://scenes/screens/setup_screen.tscn")
const GAME_HUD_SCENE := preload("res://scenes/components/game_hud.tscn")
const BLANK_PICKER_SCENE := preload("res://scenes/components/blank_picker.tscn")
const TRADE_DIALOG_SCENE := preload("res://scenes/components/trade_dialog.tscn")

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

var board_shell: BoardShell
var board_view: BoardView
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
var title_center: Control
var ai_lexicon: Lexicon = null
var ai_check: CheckButton
var setup_panel: PanelContainer
var game_root: HBoxContainer
var blank_popup: PopupPanel
var blank_target := Vector2i(-1, -1)
var title_screen: TitleScreen
var setup_screen: SetupScreen
var game_hud: GameHud
var trade_dialog: TradeDialog
var match_config: MatchConfig
var match_state: MatchState


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


func _load_texture_any(path: String) -> Texture2D:
	return UiFactory.load_texture_any(path)


func _build_title() -> void:
	title_screen = TITLE_SCREEN_SCENE.instantiate()
	title_screen.quick_play_requested.connect(_on_quick_play)
	title_screen.create_requested.connect(_show_create)
	add_child(title_screen)
	title_center = title_screen


func _hide_game_and_setup() -> void:
	if game_root != null:
		game_root.queue_free()
		game_root = null
	setup_screen.visible = false


func _show_title() -> void:
	_hide_game_and_setup()
	title_center.visible = true


func _show_create() -> void:
	title_center.visible = false
	setup_screen.visible = true


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


func _build_setup() -> void:
	setup_screen = SETUP_SCREEN_SCENE.instantiate()
	setup_screen.begin_requested.connect(_on_new_game)
	setup_screen.back_requested.connect(_show_title)
	add_child(setup_screen)
	setup_panel = setup_screen.panel
	ruleset_select = setup_screen.ruleset_select
	ruleset_preview = setup_screen.ruleset_preview
	lexicon_checks = setup_screen.lexicon_checks
	ai_check = setup_screen.ai_check
	ai_difficulty_select = setup_screen.ai_difficulty_select
	fog_check = setup_screen.fog_check
	tile_select = setup_screen.tile_select
	frame_select = setup_screen.frame_select
	new_game_btn = setup_screen.begin_button
	dict_meta = setup_screen.dict_meta


func _build_blank_picker() -> void:
	var picker: BlankPicker = BLANK_PICKER_SCENE.instantiate()
	blank_popup = picker
	add_child(blank_popup)
	picker.rune_chosen.connect(_on_blank_chosen)


func _update_ruleset_preview() -> void:
	if setup_screen != null:
		setup_screen.update_ruleset_preview()


func _build_game_ui() -> void:
	game_root = HBoxContainer.new()
	game_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_root.add_theme_constant_override("separation", 20)
	title_screen.visible = false
	setup_screen.visible = false
	add_child(game_root)

	board_shell = BOARD_SHELL_SCENE.instantiate()
	game_root.add_child(board_shell)
	board_shell.configure(ruleset.skin, ruleset.board_size, CELL_SIZE, self)
	board_shell.cell_pressed.connect(_on_cell_pressed)
	board_view = board_shell.board_view
	cell_buttons = board_view.cell_buttons
	refresh_board()

	game_hud = GAME_HUD_SCENE.instantiate()
	game_root.add_child(game_hud)
	game_hud.cast_requested.connect(_on_play)
	game_hud.recall_requested.connect(_on_recall)
	game_hud.shuffle_requested.connect(_on_shuffle)
	game_hud.pass_requested.connect(_on_pass)
	game_hud.trade_requested.connect(_open_trade)
	game_hud.new_game_requested.connect(_back_to_setup)
	rack_box = game_hud.rack_box
	turn_label = game_hud.turn_label
	score_label = game_hud.score_label
	log_label = game_hud.log_label
	play_btn = game_hud.play_button
	recall_btn = game_hud.recall_button
	shuffle_btn = game_hud.shuffle_button
	pass_btn = game_hud.pass_button
	trade_btn = game_hud.trade_button


func _apply_tile_look(b: Button, label: String, value: int, base: Color, letter_size := 22) -> void:
	letter_size = mini(letter_size, maxi(10, int(b.custom_minimum_size.x * 0.64)))
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
	_sync_match_state_from_aliases()
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

	match_config = MatchConfig.new()
	match_config.ruleset_path = rs_path
	for filename in chosen:
		match_config.lexicon_files.append(str(filename))
	match_config.players = [
		{"id": "apprentice", "name": "Apprentice", "is_ai": false},
		{"id": "word-wizard" if ai_check.button_pressed else "rival-apprentice", "name": "Word Wizard" if ai_check.button_pressed else "Rival Apprentice", "is_ai": ai_check.button_pressed},
	]
	match_config.ai_difficulty = ai_difficulty
	match_config.fog_of_war = ruleset.fog_of_war
	match_config.tile_path = str(ruleset.skin.get("tiles", ""))
	match_config.frame_path = str(ruleset.skin.get("frame", ""))
	match_config.seed = int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
	match_state = MatchEngine.start_match(match_config, ruleset)
	_adopt_match_state()
	pending.clear()
	selected_rack = -1
	DirAccess.make_dir_recursive_absolute("user://game_logs")
	match_log_path = "user://game_logs/match_%d.jsonl" % Time.get_unix_time_from_system()

	if game_root != null:
		game_root.queue_free()
		game_root = null
	_build_game_ui()
	_log("Grimoire loaded: %s (%d words). Ruleset: %s." % [lexicon.lexicon_name, lexicon.size(), ruleset.ruleset_name])
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _adopt_match_state() -> void:
	board = match_state.board
	bag = match_state.bag
	players = match_state.players
	pending = match_state.pending
	current = match_state.current_player
	passes_in_a_row = match_state.passes_in_a_row
	revealed = match_state.revealed
	game_over = match_state.game_over


func _sync_match_state_from_aliases() -> void:
	if match_state == null:
		return
	match_state.board = board
	match_state.bag = bag
	match_state.players = players
	match_state.pending = pending
	match_state.current_player = current
	match_state.passes_in_a_row = passes_in_a_row
	match_state.revealed = revealed
	match_state.game_over = game_over


func _on_rack_pressed(i: int) -> void:
	selected_rack = -1 if selected_rack == i else i
	refresh_rack()


func _on_cell_pressed(pos: Vector2i) -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if pending.has(pos):
		recall_tile(pos)
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
	var payload := {
		"rack_index": selected_rack,
		"position": {"x": pos.x, "y": pos.y},
		"blank_letter": str(tile.get("chosen_blank_letter", "")),
	}
	var events := _apply_local_command(MatchEngine.COMMAND_PLACE, payload)
	if not _command_rejection(events).is_empty():
		return
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
			var events := _apply_local_command(MatchEngine.COMMAND_MOVE_PENDING, {
				"source": {"x": src.x, "y": src.y},
				"destination": {"x": pos.x, "y": pos.y},
			})
			if _command_rejection(events).is_empty():
				refresh_all()


func _on_blank_chosen(ch: String) -> void:
	blank_popup.hide()
	if blank_target.x < 0 or selected_rack < 0:
		return
	var tile: Dictionary = players[current]["rack"][selected_rack].duplicate(true)
	tile["chosen_blank_letter"] = ch
	_place_selected(blank_target, tile)
	blank_target = Vector2i(-1, -1)


func _on_recall() -> void:
	if players[current].get("is_ai", false):
		return
	if not pending.is_empty():
		_apply_local_command(MatchEngine.COMMAND_RECALL_ALL, {})
	selected_rack = -1
	refresh_all()


func recall_tile(pos: Vector2i) -> void:
	if not pending.has(pos):
		return
	var events := _apply_local_command(MatchEngine.COMMAND_RECALL, {"position": {"x": pos.x, "y": pos.y}})
	if not _command_rejection(events).is_empty():
		return
	selected_rack = -1
	refresh_all()


func _on_shuffle() -> void:
	if players[current].get("is_ai", false):
		return
	var events := _apply_local_command(MatchEngine.COMMAND_SHUFFLE_RACK, {})
	if not _command_rejection(events).is_empty():
		return
	selected_rack = -1
	refresh_rack()


func reorder_rack(from_i: int, to_i: int) -> void:
	if game_over or players[current].get("is_ai", false):
		return
	var rack: Array = players[current]["rack"]
	if from_i < 0 or to_i < 0 or from_i >= rack.size() or to_i >= rack.size() or from_i == to_i:
		return
	var events := _apply_local_command(MatchEngine.COMMAND_REORDER_RACK, {"from_index": from_i, "to_index": to_i})
	if not _command_rejection(events).is_empty():
		return
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
	_commit_move({})


func _commit_move(_legacy_validation: Dictionary) -> void:
	var actor_name := str(players[current]["name"])
	var events := _apply_local_command(MatchEngine.COMMAND_COMMIT, {})
	var rejection := _command_rejection(events)
	if not rejection.is_empty():
		_log(rejection)
		return
	var committed: MatchEvent = events[0]
	var word_names: Array = committed.payload.get("words", [])
	var placed_positions: Array = []
	for item in committed.payload.get("positions", []):
		placed_positions.append(Vector2i(int(item.get("x", -1)), int(item.get("y", -1))))
	selected_rack = -1
	var score := int(committed.payload.get("score", 0))
	_log("%s cast '%s' for %d point%s!" % [actor_name, " ".join(word_names), score, "" if score == 1 else "s"])
	for bh in committed.payload.get("bonus_hits", []):
		var bws: Array = bh["words"]
		_log("%s - '%s' resonate%s (+%d)!" % [bh["label"], " ".join(bws), "s" if bws.size() > 1 else "", int(bws.size()) * int(bh["points"])])
	var actor: Dictionary = players[int(committed.payload.get("player_index", 0))]
	_append_move_log(actor, placed_positions, word_names, score)
	if game_over:
		_log_match_result()
		refresh_all()
		return
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
		var actor_name := str(pl["name"])
		var pass_events := _apply_local_command(MatchEngine.COMMAND_PASS, {})
		if _command_rejection(pass_events).is_empty():
			_log("%s cannot find a spell and passes." % actor_name)
			if game_over:
				_log_match_result()
		refresh_all()
		if not game_over and players[current].get("is_ai", false):
			_run_ai_turn()
		return
	var res := MoveLogic.validate(board, move, ruleset, lexicon)
	if res["ok"]:
		for item in move:
			var move_tile: Dictionary = item["tile"]
			var rack: Array = players[current]["rack"]
			var rack_index := -1
			for index in range(rack.size()):
				var rack_tile: Dictionary = rack[index]
				if bool(rack_tile["blank"]) == bool(move_tile["blank"]) and (bool(move_tile["blank"]) or rack_tile["letter"] == move_tile["letter"]):
					rack_index = index
					break
			if rack_index < 0:
				_log("%s fumbled a spell (rune missing) and passes." % pl["name"])
				_apply_local_command(MatchEngine.COMMAND_RECALL_ALL, {})
				_apply_local_command(MatchEngine.COMMAND_PASS, {})
				refresh_all()
				return
			var position: Vector2i = item["pos"]
			_apply_local_command(MatchEngine.COMMAND_PLACE, {
				"rack_index": rack_index,
				"position": {"x": position.x, "y": position.y},
				"blank_letter": str(move_tile["letter"]) if bool(move_tile["blank"]) else "",
			})
		_commit_move(res)
	else:
		_log("%s fumbled a spell (%s) and passes." % [pl["name"], res["error"]])
		_apply_local_command(MatchEngine.COMMAND_PASS, {})
		refresh_all()
		if not game_over and players[current].get("is_ai", false):
			_run_ai_turn()


func _open_trade() -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if not pending.is_empty():
		_on_recall()
	_ensure_trade_popup()
	var rack: Array = players[current]["rack"]
	trade_dialog.populate(rack, trade_selection)
	trade_popup.popup_centered()


func _ensure_trade_popup() -> void:
	if trade_popup != null:
		return
	trade_dialog = TRADE_DIALOG_SCENE.instantiate()
	trade_popup = trade_dialog
	add_child(trade_popup)
	trade_box = trade_dialog.trade_box
	trade_dialog.confirmed.connect(_confirm_trade)


func _confirm_trade() -> void:
	trade_popup.hide()
	if game_over or players[current].get("is_ai", false) or trade_selection.is_empty():
		return
	var indices: Array = trade_selection.keys()
	indices.sort()
	_sync_match_state_from_aliases()
	var actor_name := str(players[current]["name"])
	var command := MatchCommand.create(MatchEngine.COMMAND_TRADE, {"indices": indices}, current, match_state.sequence, "local-trade-%d" % match_state.sequence)
	var events := MatchEngine.apply_command(match_state, command, ruleset)
	var rejection := _command_rejection(events)
	if not rejection.is_empty():
		if rejection == "insufficient_bag_tiles":
			_log("Too few runes remain in the bag to trade.")
		else:
			_log("The rune trade was rejected: %s." % rejection.replace("_", " "))
		return
	trade_selection.clear()
	_adopt_match_state()
	_log("%s trades %d rune%s back to the sigil." % [actor_name, indices.size(), "" if indices.size() == 1 else "s"])
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _on_pass() -> void:
	if game_over or players[current].get("is_ai", false):
		return
	if not pending.is_empty():
		_on_recall()
	_sync_match_state_from_aliases()
	var actor_name := str(players[current]["name"])
	var command := MatchCommand.create(MatchEngine.COMMAND_PASS, {}, current, match_state.sequence, "local-pass-%d" % match_state.sequence)
	var events := MatchEngine.apply_command(match_state, command, ruleset)
	var rejection := _command_rejection(events)
	if not rejection.is_empty():
		_log("The pass was rejected: %s." % rejection.replace("_", " "))
		return
	_adopt_match_state()
	_log("%s passes. The air crackles..." % actor_name)
	if game_over:
		_log_match_result()
		refresh_all()
		return
	refresh_all()
	if players[current].get("is_ai", false):
		_run_ai_turn()


func _apply_local_command(command_type: String, payload: Dictionary) -> Array[MatchEvent]:
	_sync_match_state_from_aliases()
	var command_payload := payload.duplicate(true)
	var key := "local-%s-%d" % [command_type, match_state.sequence]
	var command := MatchCommand.create(command_type, command_payload, current, match_state.sequence, key)
	var events := MatchEngine.apply_command(match_state, command, ruleset, lexicon)
	if _command_rejection(events).is_empty():
		_adopt_match_state()
	return events


func _command_rejection(events: Array[MatchEvent]) -> String:
	if events.is_empty() or events[0].type != "command_rejected":
		return ""
	return str(events[0].payload.get("reason", "unknown"))


func _log_match_result() -> void:
	if match_state == null or match_state.result.is_empty():
		return
	var winners: Array = match_state.result.get("winners", [])
	_log("The duel ends! Victor: %s with %d points." % [" & ".join(winners), int(match_state.result.get("score", 0))])


func _back_to_setup() -> void:
	_show_title()
