extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame

	_check(_has_texture_panel(root.get_node("ChatDialogue").get("_panel")), "chat panel uses texture skin")
	_check(_has_texture_panel(root.get_node("BackpackUI").get("_panel")), "backpack panel uses texture skin")
	_check(_has_texture_panel(root.get_node("PauseMenu").get("_panel")), "pause panel uses texture skin")

	var title_scene = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title_scene)
	current_scene = title_scene
	await process_frame
	_check(title_scene.get_node("BG") is TextureRect, "title screen uses generated background")
	_check(_has_texture_panel(title_scene.get_node("MenuPanel")), "title menu uses texture skin")
	_check(title_scene.get_node("MenuVBox").get_child_count() == 4, "title menu builds four buttons")
	_check(
		title_scene.get_node("MenuVBox").get_child(0).get_theme_stylebox("normal") is StyleBoxTexture,
		"title buttons use texture skin"
	)

	title_scene.queue_free()
	await process_frame

	var star_map = load("res://scenes/star_map.tscn").instantiate()
	root.add_child(star_map)
	current_scene = star_map
	await process_frame
	_check(star_map.get_node("BG") is TextureRect, "star map uses generated background")
	_check(_has_texture_panel(star_map.get_node("UI/DetailPanel")), "star map detail panel uses texture skin")
	_check(
		star_map.get_node("UI/DecryptBtn").get_theme_stylebox("normal") is StyleBoxTexture,
		"star map buttons use texture skin"
	)
	_check(
		star_map.get_node("UI/ProgressBar").get_theme_stylebox("fill") is StyleBoxTexture,
		"star map progress bar uses texture skin"
	)

	if _failures == 0:
		print("[SUMMARY] UI skin regression checks passed")
	quit(_failures)


func _has_texture_panel(panel: Panel) -> bool:
	return panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
