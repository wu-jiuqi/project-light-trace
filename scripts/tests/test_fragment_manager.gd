extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = load("res://scripts/globals/fragment_manager.gd").new()
	root.add_child(manager)

	var fragment = manager.get_fragment_by_id("0762")
	_check(fragment != null and fragment.implemented, "0762 is the playable MVP fragment")
	_check(not fragment.completed, "0762 starts unrepaired")
	_check(manager.enter_fragment(fragment), "implemented fragment enters directly")

	var fragment_0002 = manager.get_fragment_by_id("0002")
	_check(fragment_0002 != null and fragment_0002.implemented, "0002 is now playable from the star map")
	_check(manager.enter_fragment(fragment_0002), "0002 implemented fragment enters directly")

	var placeholder = manager.get_fragment_by_id("0003")
	_check(placeholder != null and not placeholder.implemented, "placeholder fragment is marked unimplemented")
	_check(not manager.enter_fragment(placeholder), "placeholder fragment cannot be entered")

	_check(manager.complete_fragment(fragment), "first completion changes state")
	_check(fragment.completed, "fragment is marked completed")
	_check(manager.pending_completion_animation_id == "0762", "completion schedules star-map animation")
	_check(manager.consume_completion_animation_id() == "0762", "star-map animation id is consumed once")
	_check(manager.consume_completion_animation_id() == "", "consumed animation id is cleared")
	_check(not manager.complete_fragment(fragment), "repeat completion is idempotent")
	_check(manager.pending_completion_animation_id == "", "repeat completion does not reschedule animation")

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
