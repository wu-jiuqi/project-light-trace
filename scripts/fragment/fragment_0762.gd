extends Node2D
## 碎片 #0762「颜色的葬礼」过场动画
## 所有 UI 在代码中动态创建，避免 tscn 解析兼容问题

var title_label: Label
var subtitle_label: Label
var fade_rect: ColorRect

func _ready() -> void:
	print("[Fragment0762] 过场动画: 颜色的葬礼 — 灰白小镇")
	_create_ui()
	_play_cutscene()

func _create_ui() -> void:
	var ui = $UILayer

	title_label = Label.new()
	title_label.text = "碎 片 #0762"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.85, 1))
	title_label.position = Vector2(340, 240)
	title_label.size = Vector2(600, 50)
	ui.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "<颜色的葬礼> 灰白小镇"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 1))
	subtitle_label.position = Vector2(290, 300)
	subtitle_label.size = Vector2(700, 40)
	ui.add_child(subtitle_label)

	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_rect.position = Vector2(0, 0)
	fade_rect.size = Vector2(1280, 720)
	ui.add_child(fade_rect)

func _play_cutscene() -> void:
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 0.7, 1.0)
	tween.tween_property(subtitle_label, "modulate:a", 0.5, 1.2)

	await get_tree().create_timer(2.5).timeout

	var fade_out = create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(title_label, "modulate:a", 0.0, 0.8)
	fade_out.tween_property(subtitle_label, "modulate:a", 0.0, 0.8)
	fade_out.tween_property(fade_rect, "color:a", 1.0, 1.0)

	await get_tree().create_timer(1.2).timeout
	_enter_game()

func _enter_game() -> void:
	print("[Fragment0762] 进入市集街")
	SceneManager.change_scene("res://scenes/rooms/id0762/Market.tscn", "from_cutscene")
