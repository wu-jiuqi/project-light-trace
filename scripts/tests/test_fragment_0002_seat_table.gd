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
