extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("SaveManager")
	var game_manager = root.get_node("GameManager")
	var fragment_manager = root.get_node("FragmentManager")
	for slot in range(manager.MAX_SLOTS):
		manager.delete_slot(slot)

	game_manager.repair_progress = 10.0
	manager.set_current_slot(0)
	_check(manager.save_game(), "slot 0 saves through the active slot")

	game_manager.repair_progress = 20.0
	game_manager.oldpainter_trust = 0.75
	manager.set_current_slot(1)
	_check(manager.save_game(), "slot 1 saves through the active slot")
	_check(not manager.save_game(0), "inactive slot cannot be overwritten")

	game_manager.repair_progress = 30.0
	game_manager.npc_state_cache = {"oldpainter": {"suspicion": 12.0}}
	manager.set_current_slot(2)
	_check(manager.save_game(), "slot 2 saves through the active slot")

	_check(manager.load_game(0), "slot 0 loads")
	_check(is_equal_approx(game_manager.repair_progress, 10.0), "slot 0 keeps its own progress")

	_check(manager.load_game(1), "slot 1 loads")
	_check(is_equal_approx(game_manager.repair_progress, 20.0), "slot 1 keeps its own progress")
	_check(is_equal_approx(game_manager.oldpainter_trust, 0.75), "old painter trust persists")

	_check(manager.load_game(2), "slot 2 loads")
	_check(is_equal_approx(game_manager.repair_progress, 30.0), "slot 2 keeps its own progress")
	_check(
		is_equal_approx(game_manager.npc_state_cache["oldpainter"]["suspicion"], 12.0),
		"NPC suspicion cache persists"
	)

	fragment_manager.reset_all_fragments()
	manager._deserialize_fragments([{"id": "0762", "decrypt_state": 4}])
	_check(fragment_manager.get_fragment_by_id("0762").completed, "legacy completed fragment state migrates")
	fragment_manager.reset_all_fragments()

	manager.delete_slot(2)
	_check(manager.get_current_slot() == -1, "deleting the active slot clears active state")
	_check(not FileAccess.file_exists("user://saves/last_slot.json"), "deleting the active slot clears last slot")
	manager._on_auto_save()
	_check(not FileAccess.file_exists("user://saves/save_2.json"), "auto save does not recreate a deleted slot")
	_check(not manager.save_game(), "saving without an active slot is rejected")

	for slot in range(manager.MAX_SLOTS):
		manager.delete_slot(slot)
	if _failures == 0:
		print("[SUMMARY] save slot regression checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
