extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene_paths: Array[String] = [] as Array[String]
	_collect_scenes("res://scenes", scene_paths)
	scene_paths.sort()
	_check(scene_paths.size() == 46, "expected 46 project scenes")

	for scene_path in scene_paths:
		var resource = load(scene_path)
		_check(resource is PackedScene, "loads %s" % scene_path)
		if resource is not PackedScene:
			continue
		var instance = resource.instantiate()
		_check(instance != null, "instantiates %s" % scene_path)
		if instance != null:
			instance.free()

	if _failures == 0:
		print("[SUMMARY] all %d scenes load and instantiate" % scene_paths.size())
	quit(_failures)


func _collect_scenes(directory_path: String, scene_paths: Array[String]) -> void:
	var directory = DirAccess.open(directory_path)
	if directory == null:
		_check(false, "opens %s" % directory_path)
		return

	directory.list_dir_begin()
	var entry = directory.get_next()
	while not entry.is_empty():
		if directory.current_is_dir():
			_collect_scenes("%s/%s" % [directory_path, entry], scene_paths)
		elif entry.ends_with(".tscn"):
			scene_paths.append("%s/%s" % [directory_path, entry])
		entry = directory.get_next()
	directory.list_dir_end()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
