extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node("SaveManager")
	save_manager._stop_auto_save()
	save_manager.set("_current_slot", -1)
	save_manager.save_data = {}
	SaveConstants.set_save_dir("user://test_title_flow_saves/")
	save_manager._ensure_save_dir()

	var fader = root.get_node("SceneFader")
	fader.ensure_black()

	var opening_scene := load("res://scenes/cinematic/opening_cinematic.tscn") as PackedScene
	var opening = opening_scene.instantiate()
	root.add_child(opening)
	current_scene = opening
	await process_frame
	await create_timer(0.45).timeout

	var fade_rect := fader.get_child(0) as ColorRect
	_check(fade_rect != null and fade_rect.color.a < 0.2, "opening cinematic fades in after title transition")
	_check(opening.get_node("PageContainer/Page1_Wanxiang").visible, "opening cinematic first page is visible")

	opening._skip_cinematic()
	await create_timer(0.8).timeout
	await process_frame

	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/star_map.tscn", "opening cinematic skip routes to star map")
	_check(root.get_node("SceneManager").pending_spawn_point == "", "star map consumes the cutscene spawn marker")

	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	root.get_node("AudioManager").stop_all()
	SaveConstants.reset_save_dir()
	root.get_node("ChatDatabase").clear_memory_only()
	await process_frame
	await create_timer(0.2).timeout

	if _failures == 0:
		print("[SUMMARY] title-to-star-map flow checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
