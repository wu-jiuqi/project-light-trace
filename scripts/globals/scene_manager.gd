extends Node
## Global scene transition coordinator.

const LOADING_SCREEN_SCENE := "res://scenes/ui/LoadingScreen.tscn"
const STAR_MAP_SCENE := "res://scenes/star_map.tscn"
const TITLE_SCREEN_SCENE := "res://scenes/ui/title_screen.tscn"
const OPENING_CINEMATIC_SCENE := "res://scenes/cinematic/opening_cinematic.tscn"

var pending_spawn_point: String = ""
var _pending_loading_target := ""
var _loading_transition_active := false

signal scene_changing(target_scene: String, spawn_point: String)
signal scene_changed(target_scene: String)


func change_scene(target_scene_path: String, spawn_point_name: String = "", use_fade: bool = true) -> void:
	if target_scene_path.is_empty():
		printerr("[SceneManager] change_scene failed: empty target_scene_path")
		return

	pending_spawn_point = spawn_point_name
	scene_changing.emit(target_scene_path, spawn_point_name)
	print("[SceneManager] changing scene: %s (spawn: %s)" % [target_scene_path, spawn_point_name])

	if _requires_pack_loading(target_scene_path):
		_change_scene_with_loading_screen(target_scene_path)
	elif use_fade and _should_use_loading_screen(target_scene_path):
		_change_scene_with_loading_screen(target_scene_path)
	elif use_fade:
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


func has_pending_loading_request() -> bool:
	return _loading_transition_active and not _pending_loading_target.is_empty()


func get_pending_loading_target() -> String:
	return _pending_loading_target


func _should_use_loading_screen(target_scene_path: String) -> bool:
	if target_scene_path == STAR_MAP_SCENE and _is_title_to_star_map_flow():
		return false
	if _has_pack_for_scene(target_scene_path):
		return ResourceLoader.exists(LOADING_SCREEN_SCENE)
	return target_scene_path != LOADING_SCREEN_SCENE \
			and ResourceLoader.exists(LOADING_SCREEN_SCENE) \
			and ResourceLoader.exists(target_scene_path)


func _requires_pack_loading(target_scene_path: String) -> bool:
	return _has_pack_for_scene(target_scene_path) and not _is_pack_loaded_for_scene(target_scene_path)


func _has_pack_for_scene(target_scene_path: String) -> bool:
	var manager := get_node_or_null("/root/WebPackManager")
	return manager != null \
			and manager.has_method("has_pack_for_scene") \
			and bool(manager.call("has_pack_for_scene", target_scene_path))


func _is_pack_loaded_for_scene(target_scene_path: String) -> bool:
	var manager := get_node_or_null("/root/WebPackManager")
	return manager == null \
			or not manager.has_method("is_pack_loaded_for_scene") \
			or bool(manager.call("is_pack_loaded_for_scene", target_scene_path))


func _is_title_to_star_map_flow() -> bool:
	var current := get_tree().current_scene
	if current == null:
		return false
	var current_path := current.scene_file_path
	return current_path == TITLE_SCREEN_SCENE or current_path == OPENING_CINEMATIC_SCENE


func _change_scene_with_loading_screen(target_scene_path: String) -> void:
	if _loading_transition_active:
		return
	_loading_transition_active = true
	_pending_loading_target = target_scene_path

	await SceneFader.fade_out()
	var err := get_tree().change_scene_to_file(LOADING_SCREEN_SCENE)
	if err != OK:
		printerr("[SceneManager] loading screen failed: %s (code %d)" % [LOADING_SCREEN_SCENE, err])
		_loading_transition_active = false
		_pending_loading_target = ""
		_raw_switch(target_scene_path)
		return
	scene_changed.emit(LOADING_SCREEN_SCENE)
	SceneFader.fade_in()


func _complete_loading_transition(packed_scene: PackedScene, target_scene_path: String) -> void:
	if packed_scene == null:
		_abort_loading_transition(target_scene_path)
		return
	SceneFader.ensure_black()
	var err := get_tree().change_scene_to_packed(packed_scene)
	if err != OK:
		printerr("[SceneManager] loaded scene switch failed: %s (code %d)" % [target_scene_path, err])
		_abort_loading_transition(target_scene_path)
		return
	_loading_transition_active = false
	_pending_loading_target = ""
	scene_changed.emit(target_scene_path)


func _complete_loading_transition_with_file(target_scene_path: String) -> void:
	SceneFader.ensure_black()
	_loading_transition_active = false
	_pending_loading_target = ""
	_raw_switch(target_scene_path)


func _abort_loading_transition(target_scene_path: String) -> void:
	printerr("[SceneManager] loading transition aborted: %s" % target_scene_path)
	_loading_transition_active = false
	_pending_loading_target = ""
	pending_spawn_point = ""
