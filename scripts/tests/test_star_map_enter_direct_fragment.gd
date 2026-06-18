extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node("SaveManager")
	save_manager._stop_auto_save()
	save_manager.set("_current_slot", -1)
	save_manager.save_data = {}

	var fragment_manager = root.get_node("FragmentManager")
	fragment_manager.reset_all_fragments()
	var fragment_0004 = fragment_manager.get_fragment_by_id("0004")
	fragment_0004.unlocked = true

	var star_map = load("res://scenes/star_map.tscn").instantiate()
	root.add_child(star_map)
	current_scene = star_map
	await process_frame
	await create_timer(0.45).timeout

	var canvas = star_map.get_node("FragmentContainer/ShardCanvas")
	canvas.select_fragment(3)
	await process_frame
	star_map.call("_on_enter_btn_pressed")

	await create_timer(0.8).timeout
	await process_frame
	_check(
		root.get_node_or_null("LoadingScreen") != null,
		"star map direct fragment entry shows loading screen"
	)

	for i in range(16):
		if current_scene != null and current_scene.scene_file_path == "res://scenes/cinematic/fragment_0004_transition.tscn":
			break
		await create_timer(0.5).timeout
		await process_frame

	var fader = root.get_node("SceneFader")
	var fade_rect := fader.get_child(0) as ColorRect
	for i in range(20):
		if fade_rect != null and fade_rect.color.a < 0.2:
			break
		await create_timer(0.1).timeout
		await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/cinematic/fragment_0004_transition.tscn", "star map enters 0004 transition scene")
	_check(fade_rect != null and fade_rect.color.a < 0.2, "direct fragment reveals itself after star map scene fade")

	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	root.get_node("AudioManager").stop_all()
	fragment_manager.reset_all_fragments()
	root.get_node("ChatDatabase").clear_memory_only()
	await process_frame
	await create_timer(0.2).timeout

	if _failures == 0:
		print("[SUMMARY] star-map direct fragment entry checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
