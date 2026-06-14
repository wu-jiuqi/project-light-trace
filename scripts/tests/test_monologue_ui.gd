extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var panel: Control = load("res://scenes/ui/Monologue.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	_check(panel.has_node("Stage/Monologue/Monologue"), "monologue exposes RichTextLabel")
	_check(panel.has_node("Stage/Monologue/MonologueTexture"), "monologue exposes MonologueTexture")
	_check(panel.has_node("Stage/Monologue/Cover"), "monologue exposes Cover")
	_check(panel.has_node("Stage/Monologue/InteractiveHost"), "monologue exposes InteractiveHost")

	panel.open_for_npc("oldteacher", [
		{"text": "第一段测试文字", "image_path": ""},
		{"text": "第二段测试文字", "image_path": ""},
	])
	await create_timer(1.1).timeout
	_check(panel.is_streaming_for_test(), "monologue starts streaming after cover fade")
	panel.finish_current_page_for_test()
	_check(not panel.is_streaming_for_test(), "finish_current_page completes streaming")
	_check(panel.get_page_index_for_test() == 0, "first page index is active")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = false
	panel._input(click)
	await create_timer(1.1).timeout
	_check(panel.get_page_index_for_test() == 1, "click advances to second page after stream finished")

	panel.queue_free()
	await process_frame

	var interactive_panel: Control = load("res://scenes/ui/Monologue.tscn").instantiate()
	root.add_child(interactive_panel)
	await process_frame
	root.get_node("SaveManager").set("_current_slot", -1)
	root.get_node("FragmentManager").set_fragment_state("0002", "book_collected", false)
	interactive_panel.open_for_npc("oldteacher", [
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/book.tscn",
			"state_key": "book_collected",
			"state_value": true,
		},
		{"text": "收集后的下一页", "image_path": ""},
	])
	await create_timer(1.1).timeout
	_check(interactive_panel.is_waiting_for_interactive_collect_for_test(), "interactive page waits for item collection")
	var blocked_click := InputEventMouseButton.new()
	blocked_click.button_index = MOUSE_BUTTON_LEFT
	blocked_click.pressed = false
	interactive_panel._input(blocked_click)
	await process_frame
	_check(interactive_panel.get_page_index_for_test() == 0, "interactive page blocks global click continue before collection")

	var collectible := interactive_panel.get_node("Stage/Monologue/InteractiveHost/Book")
	var polygon := collectible.get_node("Book/CollisionPolygon2D") as CollisionPolygon2D
	var collect_click := InputEventMouseButton.new()
	collect_click.button_index = MOUSE_BUTTON_LEFT
	collect_click.pressed = true
	collect_click.position = polygon.get_global_transform_with_canvas() * Vector2(640, 360)
	collectible._input(collect_click)
	await process_frame
	_check(not interactive_panel.is_waiting_for_interactive_collect_for_test(), "interactive page resumes click continue after collection")
	_check(root.get_node("FragmentManager").get_fragment_state("0002", "book_collected") == true, "interactive collection writes fragment state")
	var collect_release := InputEventMouseButton.new()
	collect_release.button_index = MOUSE_BUTTON_LEFT
	collect_release.pressed = false
	interactive_panel._input(collect_release)
	await process_frame
	_check(interactive_panel.get_page_index_for_test() == 0, "collection click release does not also advance the page")
	var advance_press := InputEventMouseButton.new()
	advance_press.button_index = MOUSE_BUTTON_LEFT
	advance_press.pressed = true
	interactive_panel._input(advance_press)
	var advance_click := InputEventMouseButton.new()
	advance_click.button_index = MOUSE_BUTTON_LEFT
	advance_click.pressed = false
	interactive_panel._input(advance_click)
	await create_timer(1.1).timeout
	_check(interactive_panel.get_page_index_for_test() == 1, "interactive page advances after collection")

	interactive_panel.queue_free()
	await process_frame
	if _failures == 0:
		print("[SUMMARY] monologue UI test passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
