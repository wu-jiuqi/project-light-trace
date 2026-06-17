extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("FragmentManager")
	manager.reset_all_fragments()

	_check(manager.get_fragment_by_id("0001").unlocked, "new game unlocks 0001")
	_check(not manager.get_fragment_by_id("0002").unlocked, "new game locks 0002")
	_check(manager.enter_fragment(manager.get_fragment_by_id("0001")), "0001 can be entered")
	_check(not manager.enter_fragment(manager.get_fragment_by_id("0002")), "locked 0002 cannot be entered")

	manager.reset_all_fragments()
	_check(manager.complete_fragment(manager.get_fragment_by_id("0001")), "completing 0001 succeeds")
	_check(manager.get_fragment_by_id("0002").unlocked, "0001 unlocks 0002")
	_check(not manager.get_fragment_by_id("0003").unlocked, "0001 does not unlock 0003")
	_check(manager.consume_pending_unlocked_fragment_id() == "0002", "pending unlock records 0002")

	_check(manager.complete_fragment(manager.get_fragment_by_id("0002")), "completing 0002 succeeds")
	_check(manager.get_fragment_by_id("0003").unlocked, "0002 unlocks 0003")
	_check(not manager.get_fragment_by_id("0004").unlocked, "0002 does not unlock 0004")

	manager.reset_all_fragments()
	manager.get_fragment_by_id("0001").completed = true
	manager.get_fragment_by_id("0002").completed = true
	manager.ensure_linear_unlocks_from_completed()
	_check(manager.get_fragment_by_id("0001").unlocked, "migration keeps 0001 unlocked")
	_check(manager.get_fragment_by_id("0002").unlocked, "migration keeps 0002 unlocked")
	_check(manager.get_fragment_by_id("0003").unlocked, "migration unlocks next incomplete fragment")
	_check(not manager.get_fragment_by_id("0004").unlocked, "migration does not skip ahead")

	manager.reset_all_fragments()
	if _failures == 0:
		print("[SUMMARY] linear unlock checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
