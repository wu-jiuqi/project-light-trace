extends Control


func _ready() -> void:
	_build_screen()
	SceneFader.fade_in()
	await get_tree().create_timer(2.0).timeout
	FragmentManager.set_fragment_state("0003", "completed", true)
	var fragment = FragmentManager.get_fragment_by_id("0003")
	if fragment != null:
		FragmentManager.complete_fragment(fragment)
	get_tree().change_scene_to_file("res://scenes/star_map.tscn")


func _build_screen() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.015, 0.02, 0.04, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.text = "月光穿过镜面，仪式终于结束。"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0))
	add_child(label)
