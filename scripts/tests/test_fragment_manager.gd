extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = load("res://scripts/globals/fragment_manager.gd").new()
	root.add_child(manager)

	var fragment_0001 = manager.get_fragment_by_id("0001")
	var fragment_0002 = manager.get_fragment_by_id("0002")
	var fragment_0003 = manager.get_fragment_by_id("0003")
	var fragment_0004 = manager.get_fragment_by_id("0004")
	var placeholder_0047 = manager.get_fragment_by_id("0047")

	_check(fragment_0001 != null and fragment_0001.implemented, "0001 is implemented")
	_check(fragment_0002 != null and fragment_0002.implemented, "0002 is implemented")
	_check(fragment_0003 != null and fragment_0003.implemented, "0003 is implemented")
	_check(fragment_0004 != null and fragment_0004.implemented, "0004 is implemented")
	_check(placeholder_0047 != null and not placeholder_0047.implemented, "0047 is still a placeholder")

	_check(manager.enter_fragment(fragment_0001), "0001 can be entered at game start")
	_check(not manager.enter_fragment(fragment_0002), "locked 0002 cannot be entered at game start")
	_check(not manager.enter_fragment(fragment_0003), "locked 0003 cannot be entered at game start")

	manager.set_fragment_state("0001", "test_progress", 7)
	_check(manager.enter_fragment(fragment_0001), "re-entering without reset succeeds")
	_check(manager.get_fragment_state("0001", "test_progress") == 7, "normal entry preserves fragment state")
	_check(manager.enter_fragment(fragment_0001, true), "explicit reset entry succeeds")
	_check(manager.get_fragment_state("0001", "test_progress") == null, "explicit reset clears fragment state")

	_check(manager.complete_fragment(fragment_0001), "0001 completion changes state")
	_check(fragment_0001.completed, "0001 is marked completed")
	_check(fragment_0002.unlocked, "0001 completion unlocks 0002")
	_check(manager.pending_completion_animation_id == "0001", "completion schedules star-map animation")
	_check(manager.consume_completion_animation_id() == "0001", "star-map animation id is consumed once")
	_check(manager.consume_completion_animation_id() == "", "consumed animation id is cleared")
	_check(not manager.complete_fragment(fragment_0001), "repeat completion is idempotent")

	_check(manager.enter_fragment(fragment_0002), "unlocked 0002 can be entered")
	_check(manager.complete_fragment(fragment_0002), "0002 completion changes state")
	_check(fragment_0003.unlocked, "0002 completion unlocks 0003")
	_check(manager.enter_fragment(fragment_0003), "unlocked 0003 can be entered")
	_check(manager.complete_fragment(fragment_0003), "0003 completion changes state")
	_check(fragment_0004.unlocked, "0003 completion unlocks 0004")
	_check(manager.enter_fragment(fragment_0004), "unlocked 0004 can be entered")
	_check(manager.complete_fragment(fragment_0004), "0004 completion changes state")
	_check(placeholder_0047.unlocked, "0004 completion unlocks 0047")

	_check(not manager.enter_fragment(placeholder_0047), "unimplemented 0047 cannot be entered even when unlocked")

	manager.queue_free()
	if _failures == 0:
		print("[SUMMARY] fragment manager regression checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
