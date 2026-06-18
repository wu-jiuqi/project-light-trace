extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node("SaveManager")
	save_manager._stop_auto_save()
	save_manager.set("_current_slot", -1)
	save_manager.save_data = {}
	root.get_node("ChatDatabase").clear_memory_only()

	var manager = root.get_node("FragmentManager")
	manager.reset_all_fragments()
	var fragment = manager.get_fragment_by_id("0003")
	_check(fragment != null and fragment.implemented, "0003 is available from the star map")

	manager.reset_fragment_states("0003")
	await _check_main_scene(manager)
	manager.reset_fragment_states("0003")
	await _check_loft_scene(manager)

	if _failures == 0:
		print("[SUMMARY] fragment 0003 smoke test passed")
	quit(_failures)


func _check_main_scene(manager: Node) -> void:
	var scene: Node = load("res://scenes/fragments/fragment_0003.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("has_player_for_test") and scene.has_player_for_test(), "main scene creates a player")
	_check(scene.has_node("UIRoot/DialogueBox"), "main scene provides DialogueBox under UIRoot")
	_check(scene.has_node("UIRoot/CluePanel"), "main scene provides the Tab clue panel")
	var player := scene.get("_player") as CharacterBody2D
	var camera_rig := scene.get_node_or_null("WorldRoot/CameraRig") as Node2D
	var camera := camera_rig.get_node_or_null("Camera2D") as Camera2D if camera_rig != null else null
	_check(camera_rig != null and camera_rig.get_script() != null, "main scene uses CameraRig")
	_check(camera != null, "camera is attached to CameraRig")
	if camera != null:
		_check(camera.offset.is_equal_approx(Vector2.ZERO), "camera offset is reset")
		_check(camera.limit_right == 1280 and camera.limit_bottom == 720, "camera is limited to 1280x720")
		var layer_marker := scene.get_node("WorldRoot/LayerMarker/Layer1_2") as Marker2D
		var feet := player.get_node("FeetMarker Marker2D") as Marker2D
		var depth_layer_1 := scene.get_node("WorldRoot/DepthLayer/DepthLayer_1") as CanvasItem
		player.global_position.y = layer_marker.global_position.y - feet.position.y - 10.0
		scene.call("_update_camera_zoom")
		scene.call("_update_depth_layer_transparency", 999.0)
		_check(camera.zoom.is_equal_approx(Vector2(1.1, 1.1)), "camera zoom matches current 0003 above the layer marker")
		_check(is_equal_approx(depth_layer_1.modulate.a, 0.2), "DepthLayer_1 fades above the layer marker")
		player.global_position.y = layer_marker.global_position.y - feet.position.y + 10.0
		scene.call("_update_camera_zoom")
		scene.call("_update_depth_layer_transparency", 999.0)
		_check(camera.zoom.is_equal_approx(Vector2(0.8, 0.8)), "camera zoom is 0.8 below the layer marker")
		_check(is_equal_approx(depth_layer_1.modulate.a, 1.0), "DepthLayer_1 restores below the layer marker")

	_check(is_equal_approx(scene.get_cover_scale_for_test(Vector2(1600, 900)), 1.25), "0003 uses proportional cover scaling")

	for lamp_index in range(1, 13):
		var lamp := scene.find_child("L%d" % lamp_index, true, false)
		_check(lamp != null and lamp.is_in_group("interactable"), "L%d is interactable" % lamp_index)

	scene.call("_attempt_ritual_step", "wash")
	scene.call("_attempt_ritual_step", "burn")
	for lamp_index in range(1, 13):
		var lamp := scene.find_child("L%d" % lamp_index, true, false)
		var glow := lamp.get_node_or_null("Visual/LanternGlow") as Sprite2D if lamp != null else null
		_check(glow != null and glow.visible, "L%d shows the lit lantern glow" % lamp_index)
	manager.set_fragment_state("0003", "jade_collected", 1)
	scene.call("_attempt_ritual_step", "offer")
	scene.call("_attempt_ritual_step", "clap")
	scene.call("_attempt_ritual_step", "moon")
	_check(scene.get_ritual_progress_for_test() == 5, "correct ritual order reaches five completed steps")
	_check(not bool(manager.get_fragment_state("0003", "ritual_sequence_invalid")), "correct ritual order remains valid")

	manager.reset_fragment_states("0003")
	scene.call("_attempt_ritual_step", "clap")
	_check(bool(manager.get_fragment_state("0003", "ritual_sequence_invalid")), "out-of-order action marks the round invalid")
	scene.call("_reset_ritual_round")
	_check(scene.get_ritual_progress_for_test() == 0, "mirror reset clears ritual progress")
	_check(not bool(manager.get_fragment_state("0003", "ritual_sequence_invalid")), "mirror reset clears invalid state")

	manager.set_fragment_state("0003", "inscription_order", ["L3", "L1", "L2"])
	manager.set_fragment_state("0003", "jade_collected", 1)
	scene.call("_update_clue_panel")
	var clue_panel = scene.get_node("UIRoot/CluePanel")
	_check(clue_panel.clues.size() == 2, "inscriptions and jade appear as two clue entries")
	_check(str(clue_panel.clues[0].get("description", "")) == "燃净手", "inscription clue preserves collection order")
	_check(str(clue_panel.clues[1].get("image", "")).ends_with("jade.png"), "jade clue includes its image")

	scene.queue_free()
	await process_frame


func _check_loft_scene(manager: Node) -> void:
	var scene: Node = load("res://scenes/rooms/id0003/loft.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("has_player_for_test") and scene.has_player_for_test(), "loft creates a player")
	_check(scene.has_node("UIRoot/DialogueBox"), "loft provides DialogueBox under UIRoot")
	_check(scene.get_node("WorldRoot/LoftExit").is_in_group("interactable"), "LoftExit is interactable")
	_check(scene.get_node("WorldRoot/Box").is_in_group("interactable"), "Box is interactable")
	_check(scene.get_node("WorldRoot/StoneTip").is_in_group("interactable"), "StoneTip is interactable")

	for npc_path in ["WorldRoot/NpcTaoist", "WorldRoot/NpcMirrorspirit"]:
		var npc := scene.get_node(npc_path)
		_check(npc.is_in_group("npc"), "%s is configured as an NPC" % npc.name)
		var shadow := npc.get_node_or_null("Visual Node2D/Shadow Sprite2D") as Sprite2D
		_check(shadow != null and shadow.texture != null, "%s receives a soft shadow" % npc.name)

	manager.set_fragment_state("0003", "jade_collected", 1)
	scene.call("_restore_scene_visuals")
	_check(not scene.get_node("WorldRoot/Box").visible, "collected jade keeps the box hidden after returning")

	scene.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)
