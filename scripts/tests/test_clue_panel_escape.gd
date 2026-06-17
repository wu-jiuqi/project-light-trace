extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame

	var panel = load("res://scenes/ui/CluePanel.tscn").instantiate()
	root.add_child(panel)
	panel.open()
	await process_frame

	_check(panel.is_open, "clue panel opens")
	_check(panel.is_in_group("esc_close_before_pause"), "open clue panel registers as an Esc priority panel")

	var pause_menu := root.get_node_or_null("PauseMenu")
	_check(pause_menu != null, "pause menu autoload is available")
	if pause_menu != null:
		pause_menu.call("_input", _cancel_event("escape"))
		await process_frame
		_check(not panel.is_open, "Esc closes the open clue panel through its close action")
		_check(not bool(pause_menu.get("is_open")), "Esc does not open pause menu while clue panel is open")
		_check(not paused, "closing clue panel does not pause the tree")

	panel.open()
	await process_frame
	panel.call("_input", _cancel_event("ui_cancel"))
	await process_frame
	_check(not panel.is_open, "clue panel handles ui_cancel directly")

	panel.queue_free()
	await process_frame

	if _failures == 0:
		print("[SUMMARY] clue panel Esc regression checks passed")
	quit(_failures)


func _cancel_event(action_name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] ", message)
	else:
		_failures += 1
		push_error("[FAIL] " + message)
