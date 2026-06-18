extends SceneTree

var _failures := 0
var _saw_loading_screen := false
var _saw_target_scene := false
var _saw_skipped_loading_screen := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_manager = root.get_node("SaveManager")
	save_manager._stop_auto_save()
	save_manager.set("_current_slot", -1)
	save_manager.save_data = {}

	var scene_manager = root.get_node("SceneManager")
	scene_manager.scene_changed.connect(_on_scene_changed)
	scene_manager.change_scene("res://scenes/ui/title_screen.tscn")

	for i in range(90):
		if _saw_loading_screen:
			break
		await process_frame
	await process_frame
	var loading_screen_visible := root.get_node_or_null("LoadingScreen") != null

	await create_timer(3.2).timeout
	await process_frame
	_check(_saw_loading_screen, "SceneManager emitted loading-screen transition")
	_check(loading_screen_visible, "SceneManager shows LoadingScreen before target scene")
	_check(_saw_target_scene, "SceneManager emitted final target transition")
	_check(
		current_scene != null and current_scene.scene_file_path == "res://scenes/ui/title_screen.tscn",
		"SceneManager completes threaded load to target scene"
	)

	_saw_loading_screen = false
	_saw_target_scene = false
	_saw_skipped_loading_screen = false
	scene_manager.change_scene("res://scenes/star_map.tscn")
	await create_timer(0.9).timeout
	await process_frame
	_check(not _saw_skipped_loading_screen, "title screen to star map skips LoadingScreen")
	_check(
		current_scene != null and current_scene.scene_file_path == "res://scenes/star_map.tscn",
		"title screen to star map still reaches star map"
	)

	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	root.get_node("AudioManager").stop_bgm(0.0)
	await process_frame
	await create_timer(0.2).timeout
	root.get_node("ChatDatabase").clear_memory_only()

	if _failures == 0:
		print("[SUMMARY] SceneManager loading-screen checks passed")
	quit(_failures)


func _on_scene_changed(path: String) -> void:
	if path == "res://scenes/ui/LoadingScreen.tscn":
		_saw_loading_screen = true
		_saw_skipped_loading_screen = true
	elif path == "res://scenes/ui/title_screen.tscn" or path == "res://scenes/star_map.tscn":
		_saw_target_scene = true


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
