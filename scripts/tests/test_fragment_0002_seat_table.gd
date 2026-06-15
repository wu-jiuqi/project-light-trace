extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var panel: Control = load("res://scenes/buildings/id0002/seat_table.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	_check(panel.has_node("Stage/BoardTexture"), "seat table exposes BoardTexture")
	_check(panel.has_node("Stage/TicketLayer/Ticket_oldteacher/Texture"), "seat table exposes oldteacher ticket texture")
	_check(panel.has_node("Stage/SeatSlots/SeatSlot1"), "seat table exposes seat slots")
	_check(panel.has_node("Stage/SaveButton"), "seat table exposes SaveButton")

	panel.open_table()
	_check(not panel.can_save_for_test(), "save disabled before four seats are filled")
	panel.assign_for_test(["oldteacher", "youngsoldier", "merchant", "littlegirl"])
	_check(panel.can_save_for_test(), "save enabled after four unique NPC tickets are seated")
	var selection: Dictionary = panel.get_selection_for_test()
	_check(selection.get("flowergirl", -1) == 1, "unseated NPC is marked as left behind")
	for npc_id in ["oldteacher", "youngsoldier", "merchant", "littlegirl"]:
		_check(selection.get(npc_id, -1) == 0, "%s is marked as seated" % npc_id)
	_check(panel.get_left_npc_id_for_test() == "flowergirl", "left_npc_id resolves to remaining NPC")

	panel.open_table()
	_drag_ticket_to_slot(panel, Vector2(180, 93), Vector2(609, 303))
	_drag_ticket_to_slot(panel, Vector2(180, 219), Vector2(901, 303))
	_drag_ticket_to_slot(panel, Vector2(180, 471), Vector2(609, 409))
	_drag_ticket_to_slot(panel, Vector2(180, 597), Vector2(901, 409))
	_check(panel.can_save_for_test(), "mouse drag seating enables save after four tickets are dropped on slots")
	var drag_selection: Dictionary = panel.get_selection_for_test()
	_check(drag_selection.get("flowergirl", -1) == 1, "mouse drag leaves the undropped ticket behind")

	panel.open_table()
	_drag_ticket_to_slot_via_input(panel, Vector2(180, 93), Vector2(609, 303))
	_drag_ticket_to_slot_via_input(panel, Vector2(180, 219), Vector2(901, 303))
	_drag_ticket_to_slot_via_input(panel, Vector2(180, 471), Vector2(609, 409))
	_drag_ticket_to_slot_via_input(panel, Vector2(180, 597), Vector2(901, 409))
	_check(panel.can_save_for_test(), "global mouse input drag seating enables save after four drops")
	var global_drag_selection: Dictionary = panel.get_selection_for_test()
	_check(global_drag_selection.get("flowergirl", -1) == 1, "global mouse input drag leaves the undropped ticket behind")

	panel.queue_free()
	await process_frame
	if _failures == 0:
		print("[SUMMARY] fragment 0002 seat table test passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)


func _drag_ticket_to_slot(panel: Control, from_stage: Vector2, to_stage: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _stage_to_panel(panel, from_stage)
	panel._gui_input(press)

	var motion := InputEventMouseMotion.new()
	motion.position = _stage_to_panel(panel, to_stage)
	panel._gui_input(motion)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = _stage_to_panel(panel, to_stage)
	panel._gui_input(release)


func _drag_ticket_to_slot_via_input(panel: Control, from_stage: Vector2, to_stage: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = _stage_to_panel(panel, from_stage)
	panel._input(press)

	var motion := InputEventMouseMotion.new()
	motion.position = _stage_to_panel(panel, to_stage)
	panel._input(motion)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = _stage_to_panel(panel, to_stage)
	panel._input(release)


func _stage_to_panel(panel: Control, stage_position: Vector2) -> Vector2:
	var stage := panel.get_node("Stage") as Control
	return stage.position + stage_position * stage.scale.x
