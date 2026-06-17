extends Node
## Global scene transition coordinator.

var pending_spawn_point: String = ""

signal scene_changing(target_scene: String, spawn_point: String)
signal scene_changed(target_scene: String)


func change_scene(target_scene_path: String, spawn_point_name: String = "", use_fade: bool = true) -> void:
	if target_scene_path.is_empty():
		printerr("[SceneManager] change_scene failed: empty target_scene_path")
		return

	pending_spawn_point = spawn_point_name
	scene_changing.emit(target_scene_path, spawn_point_name)
	print("[SceneManager] changing scene: %s (spawn: %s)" % [target_scene_path, spawn_point_name])

	if use_fade:
		SceneFader.fade_out_and_switch(target_scene_path)
	else:
		_raw_switch(target_scene_path)


func _raw_switch(target_scene_path: String) -> void:
	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		printerr("[SceneManager] scene load failed: %s (code %d)" % [target_scene_path, err])
		pending_spawn_point = ""
		return
	scene_changed.emit(target_scene_path)
