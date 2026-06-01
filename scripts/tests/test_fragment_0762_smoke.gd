extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fragment_scene = load("res://scenes/fragments/fragment_0762.tscn").instantiate()
	root.add_child(fragment_scene)
	current_scene = fragment_scene

	await create_timer(5.0).timeout

	_check(current_scene != null, "0762 cutscene leaves an active scene")
	if current_scene != null:
		_check(current_scene.name == "Market", "0762 cutscene enters Market")
		_check(current_scene.has_node("Player"), "Market creates Player")
		_check(current_scene.has_node("NPC_Fengshen"), "Market initializes innkeeper NPC")
		_check(current_scene.has_node("NPC_Laotang"), "Market initializes baker NPC")
		_check(current_scene.has_node("NPC_Alian"), "Market initializes florist NPC")

	if _failures == 0:
		print("[SUMMARY] 0762 cutscene and Market initialization passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
