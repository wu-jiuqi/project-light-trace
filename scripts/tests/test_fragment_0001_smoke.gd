extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fragment_scene = load("res://scenes/fragments/fragment_0001.tscn").instantiate()
	root.add_child(fragment_scene)
	current_scene = fragment_scene
	await process_frame

	_check(fragment_scene.has_method("uses_compliance_mode"), "0001 test uses the production fragment script")
	_check(fragment_scene.get("_player") != null, "0001 creates a playable Player in the depth layer")
	_check(_count_observed_sundials(fragment_scene) == 0, "0001 starts with no sundial observations")
	var observed_after_interaction := 0
	for id in ["A", "B", "C", "D", "E"]:
		var sundial := _find_sundial(fragment_scene, id)
		_check(sundial != null, "0001 has Sundial%s wired in the production scene" % id)
		if sundial != null:
			sundial.interact()
		await process_frame
		if sundial != null and bool(sundial.get("is_observed")):
			observed_after_interaction += 1

	_check(observed_after_interaction == 5, "0001 records all five sundial observations")
	fragment_scene.set_clock_angle_for_test(60)
	_check(not await fragment_scene.submit_clock_angle_for_test(), "0001 rejects a near miss angle")
	var bell_tower := _find_bell_tower(fragment_scene)
	_check(bell_tower != null and str(bell_tower.get("display_name")) != "钟楼暗门", "0001 rejects a near miss angle")
	fragment_scene.set_clock_angle_for_test(66)
	_check(await fragment_scene.submit_clock_angle_for_test(), "0001 accepts the inferred 66 degree answer")
	_check(bell_tower != null and str(bell_tower.get("display_name")) == "钟楼暗门", "0001 accepts the inferred 66 degree answer")

	if _failures == 0:
		print("[SUMMARY] 0001 sundial puzzle smoke test passed")
	quit(_failures)


func _find_sundial(fragment_scene: Node, id: String) -> Node:
	var world_root := fragment_scene.get_node_or_null("WorldRoot")
	var search_root: Node = world_root if world_root else fragment_scene
	var nodes := search_root.find_children("Sundial%s" % id, "Node2D", true, false)
	return nodes[0] if not nodes.is_empty() else null


func _find_bell_tower(fragment_scene: Node) -> Node:
	var world_root := fragment_scene.get_node_or_null("WorldRoot")
	var search_root: Node = world_root if world_root else fragment_scene
	var nodes := search_root.find_children("BellTower", "Node2D", true, false)
	return nodes[0] if not nodes.is_empty() else null


func _count_observed_sundials(fragment_scene: Node) -> int:
	var count := 0
	for id in ["A", "B", "C", "D", "E"]:
		var sundial := _find_sundial(fragment_scene, id)
		if sundial != null and bool(sundial.get("is_observed")):
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		printerr("[FAIL] %s" % message)
