extends RefCounted
## Shared sci-fi archive UI skin.

const PANEL_FRAME = preload("res://assets/ui/panel_frame.svg")
const PANEL_FRAME_SOFT = preload("res://assets/ui/panel_frame_soft.svg")
const BUTTON_NORMAL = preload("res://assets/ui/button_normal.svg")
const BUTTON_HOVER = preload("res://assets/ui/button_hover.svg")
const BUTTON_PRESSED = preload("res://assets/ui/button_pressed.svg")
const BUTTON_DISABLED = preload("res://assets/ui/button_disabled.svg")
const INPUT_FRAME = preload("res://assets/ui/input_frame.svg")
const PROGRESS_FRAME = preload("res://assets/ui/progress_frame.svg")
const PROGRESS_FILL = preload("res://assets/ui/progress_fill.svg")

const CYAN := Color(0.55, 0.9, 1.0, 1.0)
const GOLD := Color(0.94, 0.78, 0.45, 1.0)
const TEXT := Color(0.86, 0.91, 0.96, 1.0)
const MUTED := Color(0.52, 0.62, 0.72, 1.0)


static func texture_style(texture: Texture2D, margin: float = 16.0, tint := Color.WHITE) -> StyleBoxTexture:
	var style = StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = margin
	style.texture_margin_top = margin
	style.texture_margin_right = margin
	style.texture_margin_bottom = margin
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	style.modulate_color = tint
	return style


static func panel_style(soft := false, tint := Color.WHITE) -> StyleBoxTexture:
	return texture_style(PANEL_FRAME_SOFT if soft else PANEL_FRAME, 20.0, tint)


static func apply_button(button: Button, gold := false) -> void:
	button.add_theme_stylebox_override("normal", texture_style(BUTTON_NORMAL, 10.0))
	button.add_theme_stylebox_override("hover", texture_style(BUTTON_HOVER, 10.0))
	button.add_theme_stylebox_override("focus", texture_style(BUTTON_HOVER, 10.0))
	button.add_theme_stylebox_override("pressed", texture_style(BUTTON_PRESSED, 10.0))
	button.add_theme_stylebox_override("disabled", texture_style(BUTTON_DISABLED, 10.0))
	button.add_theme_color_override("font_color", GOLD if gold else TEXT)
	button.add_theme_color_override("font_hover_color", GOLD)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_pressed_color", CYAN)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58, 0.7))


static func apply_line_edit(line_edit: LineEdit) -> void:
	line_edit.add_theme_stylebox_override("normal", texture_style(INPUT_FRAME, 10.0))
	line_edit.add_theme_stylebox_override("focus", texture_style(BUTTON_HOVER, 10.0))
	line_edit.add_theme_color_override("font_color", TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.5, 0.6, 0.7, 0.7))


static func apply_progress(progress_bar: ProgressBar) -> void:
	progress_bar.add_theme_stylebox_override("background", texture_style(PROGRESS_FRAME, 6.0))
	progress_bar.add_theme_stylebox_override("fill", texture_style(PROGRESS_FILL, 6.0))


static func apply_item_list(item_list: ItemList) -> void:
	item_list.add_theme_stylebox_override("panel", panel_style(true))
	item_list.add_theme_stylebox_override("focus", texture_style(BUTTON_HOVER, 10.0))
	item_list.add_theme_color_override("font_color", TEXT)
	item_list.add_theme_color_override("font_selected_color", GOLD)
	item_list.add_theme_color_override("guide_color", Color(0.25, 0.55, 0.7, 0.28))
	item_list.add_theme_constant_override("line_separation", 5)
