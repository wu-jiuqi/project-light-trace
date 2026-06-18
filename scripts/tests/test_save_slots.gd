extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("SaveManager")
	var game_manager = root.get_node("GameManager")
	var fragment_manager = root.get_node("FragmentManager")
	manager._stop_auto_save()
	manager.set("_current_slot", -1)
	manager.save_data = {}
	root.get_node("ChatDatabase").clear_memory_only()
	SaveConstants.set_save_dir("user://test_saves/")
	manager._ensure_save_dir()
	for slot in range(SaveConstants.MAX_SLOTS):
		manager.delete_slot(slot)

	game_manager.repair_progress = 10.0
	manager.set_current_slot(0)
	_check(manager.save_game(), "slot 0 saves through the active slot")
	_check(manager.save_game(0), "save_game with explicit slot works regardless of active slot")

	game_manager.repair_progress = 20.0
	root.get_node("FragmentManager").set_fragment_state("0004", "wrong_combination_count", 2)
	manager.set_current_slot(1)
	_check(manager.save_game(), "slot 1 saves through the active slot")

	game_manager.repair_progress = 30.0
	game_manager.npc_state_cache = {"conductor": {"suspicion": 12.0}}
	manager.set_current_slot(2)
	_check(manager.save_game(), "slot 2 saves through the active slot")

	_check(manager.load_game(0), "slot 0 loads")
	_check(is_equal_approx(game_manager.repair_progress, 10.0), "slot 0 keeps its own progress")

	_check(manager.load_game(1), "slot 1 loads")
	_check(is_equal_approx(game_manager.repair_progress, 20.0), "slot 1 keeps its own progress")
	_check(root.get_node("FragmentManager").get_fragment_state("0004", "wrong_combination_count") == 2, "0004 fragment state persists")

	_check(manager.load_game(2), "slot 2 loads")
	_check(is_equal_approx(game_manager.repair_progress, 30.0), "slot 2 keeps its own progress")
	_check(
		is_equal_approx(game_manager.npc_state_cache["conductor"]["suspicion"], 12.0),
		"NPC suspicion cache persists"
	)

	var previous_scene = current_scene
	var title_scene := Control.new()
	title_scene.name = "TitleScreen"
	root.add_child(title_scene)
	current_scene = title_scene
	game_manager.repair_progress = 40.0
	manager._on_auto_save()
	# 重新加载 slot 2 验证 auto-save 未覆盖（应为 30.0 而非 40.0）
	_check(manager.load_game(2), "slot 2 reloads after auto-save attempt")
	_check(is_equal_approx(game_manager.repair_progress, 30.0), "auto save skips the title screen")
	current_scene = previous_scene
	title_scene.queue_free()

	fragment_manager.reset_all_fragments()
	manager._apply_fragments_list([{"id": "0004", "completed": true}])
	_check(fragment_manager.get_fragment_by_id("0004").completed, "completed fragment state migrates")
	fragment_manager.reset_all_fragments()

	manager.delete_slot(2)
	_check(manager.get_current_slot() == -1, "deleting the active slot clears active state")
	_check(not FileAccess.file_exists(SaveConstants.last_slot_path()), "deleting the active slot clears last slot")
	manager._on_auto_save()
	_check(not FileAccess.file_exists(SaveConstants.slot_path(2)), "auto save does not recreate a deleted slot")
	_check(not manager.save_game(), "saving without an active slot is rejected")

	for slot in range(SaveConstants.MAX_SLOTS):
		manager.delete_slot(slot)
	SaveConstants.reset_save_dir()
	manager._ensure_save_dir()
	root.get_node("ChatDatabase").clear_memory_only()
	if _failures == 0:
		print("[SUMMARY] save slot regression checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
