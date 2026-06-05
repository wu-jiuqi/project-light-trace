extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fragment_scene = load("res://scenes/fragments/fragment_0001.tscn").instantiate()
	root.add_child(fragment_scene)
	current_scene = fragment_scene
	await process_frame

	_check(fragment_scene.has_node("Player"), "0001 creates a playable Player")
	_check(fragment_scene.get_observed_count_for_test() == 0, "0001 starts with no sundial observations")
	for id in ["A", "B", "C", "D", "E"]:
		fragment_scene.observe_sundial_for_test(id)
		await process_frame

	_check(fragment_scene.get_observed_count_for_test() == 5, "0001 records all five sundial observations")
	_check(not fragment_scene.is_source_mark_revealed_for_test(), "0001 source mark stays hidden before clock validation")
	fragment_scene.set_clock_angle_for_test(60)
	_check(not fragment_scene.submit_clock_angle_for_test(), "0001 rejects a near miss angle")
	_check(fragment_scene.get_compliance_for_test() == 96, "0001 near miss reduces compliance lightly")
	fragment_scene.set_clock_angle_for_test(66)
	_check(fragment_scene.submit_clock_angle_for_test(), "0001 accepts the inferred 66 degree answer")
	_check(fragment_scene.is_source_mark_revealed_for_test(), "0001 reveals the dawn source mark after validation")

	if _failures == 0:
		print("[SUMMARY] 0001 sundial puzzle smoke test passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
