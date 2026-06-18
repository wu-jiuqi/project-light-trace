extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("FragmentManager")
	var fragment = manager.get_fragment_by_id("0004")
	_check(fragment != null and fragment.implemented, "0004 is available from the star map")

	manager.reset_fragment_states("0004")
	await _check_main_scene(manager)
	manager.reset_fragment_states("0004")
	await _check_passage_scene(manager)

	if _failures == 0:
		print("[SUMMARY] fragment 0004 smoke test passed")
	current_scene = null
	root.get_node("AudioManager").stop_all()
	await process_frame
	await create_timer(0.2).timeout
	quit(_failures)


func _check_main_scene(manager: Node) -> void:
	var scene: Node = load("res://scenes/fragments/fragment_0004.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("has_player_for_test") and scene.has_player_for_test(), "main scene creates a player")
	_check(scene.has_node("UIRoot/DialogueBox"), "main scene provides DialogueBox under UIRoot")
	_check(scene.has_node("UIRoot/InteractHint"), "main scene provides InteractHint")

	var player := scene.get("_player") as CharacterBody2D
	var camera_rig := scene.get_node_or_null("WorldRoot/CameraRig") as Node2D
	var camera := camera_rig.get_node_or_null("Camera2D") as Camera2D if camera_rig != null else null
	_check(camera_rig != null and camera_rig.get_script() != null, "main scene uses CameraRig")
	_check(camera != null, "main scene attaches camera to CameraRig")
	if camera != null:
		_check(camera.offset.is_equal_approx(Vector2.ZERO), "main scene camera offset is reset")
		_check(camera.zoom.is_equal_approx(Vector2(1.9, 1.9)), "main scene camera zoom matches fragment 0001")
		_check(camera.limit_right == 1280 and camera.limit_bottom == 720, "main scene camera is limited to the viewport")
	var visual_root := player.get_node_or_null("Visual Node2D") as Node2D if player != null else null
	_check(visual_root != null and visual_root.scale.is_equal_approx(Vector2(1.4, 1.4)), "player visual scale matches 0004 NPC scale")

	var material_data: Dictionary = scene.call("get_material_data_for_test")
	_check(material_data.size() == 18, "material data contains all 18 materials")
	_check(str(material_data.get("B3", {}).get("name", "")) == "锻钢·右", "material data keeps B3 parameters")

	scene.call("collect_material_for_test", "M1")
	var collected_materials: Dictionary = manager.get_fragment_state("0004", "collected_materials")
	_check(int(collected_materials.get("M1", 0)) == 1, "collecting a material writes collected_materials")

	for cabinet_name in ["Cabinet_1", "Cabinet_2", "Cabinet_3", "Cabinet_4", "Cabinet_5"]:
		_check(str(scene.call("get_cabinet_display_name_for_test", cabinet_name)) == "材料柜%s" % cabinet_name.trim_prefix("Cabinet_"), "%s has a distinct cabinet prompt" % cabinet_name)
		scene.call("open_cabinet_for_test", cabinet_name)
		var viewer := scene.get_node_or_null("UIRoot/CabinetViewer") as Control
		_check(viewer != null and viewer.visible, "%s opens the cabinet viewer" % cabinet_name)
		scene.call("_close_cabinet_viewer")

	manager.set_fragment_state("0004", "collected_blueprints", {"Head": 1, "LeftLeg": 1})
	manager.set_fragment_state("0004", "collected_materials", {"M1": 1, "B3": 1})
	scene.call("open_desktop_for_test")
	_check(scene.has_node("UIRoot/DesktopOverlay/Stage/BlueprintThumb_Head"), "desktop shows collected blueprint thumbnails")
	_check(scene.has_node("UIRoot/DesktopOverlay/Stage/MaterialThumb_M1"), "desktop shows collected material thumbnails")
	scene.call("analyze_material_for_test", "B3")
	_check(str(scene.call("get_analysis_text_for_test")).find("重量(kg): 1.5") >= 0, "analyzer shows dropped material parameters")
	_check(int(scene.call("get_analyzer_font_size_for_test")) >= 24, "analyzer text is readable at the larger size")

	var all_materials := {}
	for material_id in material_data.keys():
		all_materials[str(material_id)] = 1
	manager.set_fragment_state("0004", "collected_materials", all_materials)
	scene.call("open_desktop_for_test")
	var material_layout: Dictionary = scene.call("get_material_thumb_layout_for_test")
	_check(material_layout.size() == 18, "desktop lays out all 18 material thumbnails")
	var material_rows := {}
	var max_material_bottom := 0.0
	for entry in material_layout.values():
		var entry_dict: Dictionary = entry
		var position: Vector2 = entry_dict["position"]
		var visual_size: Vector2 = entry_dict["visual_size"]
		material_rows[roundi(position.y)] = true
		max_material_bottom = maxf(max_material_bottom, position.y + visual_size.y)
	_check(material_rows.size() <= 3, "desktop material thumbnails use no more than three rows")
	_check(max_material_bottom <= 286.0, "desktop material thumbnails stay above the analyzer")

	var wrong_response := str(scene.call("judge_material_combination_for_test", "M3 L3 T2 P1 W2 B3"))
	_check(wrong_response.find("右腿") >= 0 or wrong_response.find("不成对") >= 0, "springright explains the right-leg mismatch")
	_check(int(scene.call("get_fragment_state_value_for_test", "wrong_combination_count")) == 1, "wrong combination increments the failure count")
	var correct_response := str(scene.call("judge_material_combination_for_test", "b1, m3 p1; l3 / w2 t2"))
	_check(correct_response == "判定：合格。——确定。", "springright accepts the correct combination in any order")
	_check(bool(scene.call("get_fragment_state_value_for_test", "assembly_solved")), "correct combination records assembly_solved")
	_check(not bool(scene.call("get_fragment_state_value_for_test", "completed")), "correct combination does not mark the fragment completed yet")

	var layer_marker := scene.get_node("WorldRoot/LayerMarker/Layer1_2") as Marker2D
	var feet := player.get_node("FeetMarker Marker2D") as Marker2D
	player.global_position.y = layer_marker.global_position.y - feet.position.y - 10.0
	scene.call("_update_depth_layer_transparency", 999.0)
	_check(is_equal_approx(float(scene.call("get_depth_layer_alpha_for_test")), 0.25), "DepthLayer_1 fades above Layer1_2")
	player.global_position.y = layer_marker.global_position.y - feet.position.y + 10.0
	scene.call("_update_depth_layer_transparency", 999.0)
	_check(is_equal_approx(float(scene.call("get_depth_layer_alpha_for_test")), 1.0), "DepthLayer_1 restores below Layer1_2")

	for npc_path in ["WorldRoot/DepthLayer/NpcGearleft", "WorldRoot/DepthLayer/NpcSpringright"]:
		var npc := scene.get_node(npc_path)
		_check(npc.is_in_group("npc"), "%s is configured as an NPC" % npc.name)
		_check("npc_kb_id" in npc and not str(npc.npc_kb_id).is_empty(), "%s has a kb id" % npc.name)

	await create_timer(4.2).timeout
	scene.queue_free()
	current_scene = null
	await process_frame


func _check_passage_scene(manager: Node) -> void:
	var scene: Node = load("res://scenes/rooms/id0004/passage.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	_check(scene.has_method("has_player_for_test") and scene.has_player_for_test(), "passage creates a player")
	_check(scene.has_node("UIRoot/DialogueBox"), "passage provides DialogueBox under UIRoot")
	_check(scene.find_child("JumpInteractionAreaProxy", true, false) != null, "passage return area is interactable")

	for blueprint_id in ["Head", "Heart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"]:
		var pages: Array = scene.call("get_blueprint_pages_for_test", blueprint_id)
		_check(pages.size() == 2, "%s has front and back pages" % blueprint_id)
		if pages.size() > 0:
			_check(str(pages[0]).ends_with("1.png"), "%s first page is the front texture" % blueprint_id)
		for page_path in pages:
			_check(ResourceLoader.exists(str(page_path)), "%s page texture exists" % blueprint_id)
		scene.call("collect_blueprint_for_test", blueprint_id)
		var collected_blueprints: Dictionary = manager.get_fragment_state("0004", "collected_blueprints")
		_check(int(collected_blueprints.get(blueprint_id, 0)) == 1, "%s writes collected_blueprints" % blueprint_id)

	await create_timer(4.2).timeout
	scene.queue_free()
	current_scene = null
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)
