extends Node2D
## 碎片 #0762「颜色的葬礼」点击推进漫画过场。

const COMIC_PAGES: Array[Texture2D] = [
	preload("res://assets/cutscenes/id0762/comic_01_descent.png"),
	preload("res://assets/cutscenes/id0762/comic_02_threads.png"),
	preload("res://assets/cutscenes/id0762/comic_03_market.png"),
]
const CAPTIONS: Array[String] = [
	"裂隙张开时，你听见玻璃坠落的声音。\n每一块碎片，都映着一个不再完整的世界。",
	"灰雾深处，有细线仍在编织。\n一个模糊的影子隔着无数断裂的光，安静地等待。",
	"石板路、旧街灯、沉默的旅店。\n当最后一片微光落下，你已经站在灰白小镇的门前。",
]

var page_texture: TextureRect
var caption_label: Label
var page_label: Label
var fade_rect: ColorRect
var current_page := 0
var _transitioning := false
var _entered_game := false


func _ready() -> void:
	print("[Fragment0762] 漫画过场: 颜色的葬礼 — 灰白小镇")
	_create_ui()
	_show_page(0)


func _create_ui() -> void:
	var ui = $UILayer

	page_texture = TextureRect.new()
	page_texture.name = "ComicPage"
	page_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	page_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ui.add_child(page_texture)

	var caption_bg = ColorRect.new()
	caption_bg.name = "CaptionBG"
	caption_bg.position = Vector2(0, 548)
	caption_bg.size = Vector2(1280, 172)
	caption_bg.color = Color(0.01, 0.02, 0.05, 0.82)
	ui.add_child(caption_bg)

	caption_label = Label.new()
	caption_label.name = "Caption"
	caption_label.position = Vector2(88, 574)
	caption_label.size = Vector2(1040, 82)
	caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption_label.add_theme_color_override("font_color", Color(0.84, 0.91, 0.96, 1))
	caption_label.add_theme_font_size_override("font_size", 20)
	ui.add_child(caption_label)

	page_label = Label.new()
	page_label.name = "PageIndicator"
	page_label.position = Vector2(1030, 662)
	page_label.size = Vector2(190, 28)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	page_label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.45, 0.9))
	page_label.add_theme_font_size_override("font_size", 15)
	ui.add_child(page_label)

	var continue_label = Label.new()
	continue_label.name = "ContinueLabel"
	continue_label.position = Vector2(88, 668)
	continue_label.size = Vector2(360, 26)
	continue_label.text = "点击继续   |   Esc 跳过"
	continue_label.add_theme_color_override("font_color", Color(0.58, 0.82, 0.94, 0.9))
	continue_label.add_theme_font_size_override("font_size", 14)
	ui.add_child(continue_label)

	fade_rect = ColorRect.new()
	fade_rect.name = "Fade"
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.color = Color(0, 0, 0, 0)
	ui.add_child(fade_rect)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_enter_game()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		advance_page()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		advance_page()
		get_viewport().set_input_as_handled()


func advance_page() -> void:
	if _transitioning or _entered_game:
		return
	if current_page >= COMIC_PAGES.size() - 1:
		_enter_game()
		return
	_transitioning = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.72, 0.16)
	await tween.finished
	_show_page(current_page + 1)
	var reveal = create_tween()
	reveal.tween_property(fade_rect, "color:a", 0.0, 0.2)
	await reveal.finished
	_transitioning = false


func _show_page(index: int) -> void:
	current_page = index
	page_texture.texture = COMIC_PAGES[index]
	caption_label.text = CAPTIONS[index]
	page_label.text = "%d / %d" % [index + 1, COMIC_PAGES.size()]


func _enter_game() -> void:
	if _entered_game:
		return
	_entered_game = true
	print("[Fragment0762] 漫画结束，进入市集街旅店门口")
	SceneManager.change_scene("res://scenes/rooms/id0762/Market.tscn", "from_cutscene")
