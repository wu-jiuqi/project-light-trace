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

	var star_map = load("res://scenes/star_map.tscn").instantiate()
	root.add_child(star_map)
	current_scene = star_map
	await process_frame
	await create_timer(0.45).timeout

	var canvas = star_map.get_node("FragmentContainer/ShardCanvas")
	canvas.select_fragment(0)
	await process_frame
	star_map.call("_on_enter_btn_pressed")

	await create_timer(0.8).timeout
	await process_frame

	var fader = root.get_node("SceneFader")
	var fade_rect := fader.get_child(0) as ColorRect
	_check(current_scene != null and current_scene.scene_file_path == "res://scenes/cinematic/fragment_0001_transition.tscn", "star map enters fragment transition scene")
	_check(fade_rect != null and fade_rect.color.a < 0.2, "fragment transition reveals itself after star map scene fade")

	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	fragment_manager.reset_all_fragments()
	root.get_node("ChatDatabase").clear_memory_only()

	if _failures == 0:
		print("[SUMMARY] star-map enter transition checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
