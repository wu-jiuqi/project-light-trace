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
	if _failures == 0:
		print("[SUMMARY] monologue UI test passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
