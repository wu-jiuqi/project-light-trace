extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = load("res://scripts/globals/fragment_manager.gd").new()
	root.add_child(manager)

	var fragment = manager.get_fragment_by_id("0762")
	_check(fragment != null and fragment.implemented, "0762 is the playable MVP fragment")

	var placeholder = manager.get_fragment_by_id("0001")
	_check(placeholder != null and not placeholder.implemented, "placeholder fragment is marked unimplemented")
	manager.start_decrypt(placeholder)
	_check(placeholder.decrypt_state == manager.DecryptState.LOCKED, "placeholder fragment cannot start decrypting")

	fragment.decrypt_duration = 100
	manager.start_decrypt(fragment)
	_check(fragment.decrypt_state == manager.DecryptState.DECRYPTING, "LOCKED -> DECRYPTING")

	fragment.decrypt_start_time = Time.get_unix_time_from_system() - 50
	manager.check_decrypt_progress(fragment)
	_check(fragment.decrypt_state == manager.DecryptState.PARTIAL, "DECRYPTING -> PARTIAL")
	_check(
		fragment.hint_visible.to_utf8_buffer().get_string_from_utf8() == fragment.hint_visible,
		"partial hint remains valid UTF-8"
	)

	fragment.decrypt_start_time = Time.get_unix_time_from_system() - 100
	manager.check_decrypt_progress(fragment)
	_check(fragment.decrypt_state == manager.DecryptState.FULL, "PARTIAL -> FULL")

	manager.complete_fragment(fragment)
	_check(fragment.decrypt_state == manager.DecryptState.COMPLETED, "FULL -> COMPLETED")

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
