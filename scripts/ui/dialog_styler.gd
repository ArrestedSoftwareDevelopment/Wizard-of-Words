class_name DialogStyler
extends RefCounted


static func apply_popup(popup: PopupPanel, theme: Dictionary) -> void:
	var panel_color := Color(str(theme.get("panel_color", "#241a38")))
	panel_color.a = 0.98
	var accent := Color(str(theme.get("accent_color", "#e8b23a")))
	var panel := StyleBoxFlat.new()
	panel.bg_color = panel_color
	panel.set_corner_radius_all(14)
	panel.set_border_width_all(2)
	panel.border_color = accent.darkened(0.18)
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.72)
	panel.shadow_size = 18
	panel.shadow_offset = Vector2(0, 7)
	popup.add_theme_stylebox_override("panel", panel)


static func apply_heading(label: Label, theme: Dictionary) -> void:
	label.add_theme_color_override("font_color", Color(str(theme.get("accent_color", "#e8b23a"))))


static func apply_caption(label: Label, theme: Dictionary) -> void:
	var accent := Color(str(theme.get("accent_color", "#e8b23a")))
	label.add_theme_color_override("font_color", accent.lightened(0.35))


static func apply_button(button: Button, theme: Dictionary) -> void:
	var panel_color := Color(str(theme.get("panel_color", "#241a38")))
	var accent := Color(str(theme.get("accent_color", "#e8b23a")))
	var normal := StyleBoxFlat.new()
	normal.bg_color = panel_color.lightened(0.13)
	normal.set_corner_radius_all(7)
	normal.set_border_width_all(1)
	normal.border_color = accent.darkened(0.32)
	normal.set_content_margin_all(6.0)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = panel_color.lightened(0.24)
	hover.border_color = accent
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = accent.darkened(0.42)
	pressed.border_color = accent.lightened(0.12)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = panel_color.darkened(0.08)
	disabled.border_color = accent.darkened(0.55)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color("f7f2e6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.68, 0.64, 0.55))
	if button.toggle_mode:
		button.add_theme_stylebox_override("pressed", pressed)
