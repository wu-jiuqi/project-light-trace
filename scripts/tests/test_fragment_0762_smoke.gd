extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fragment_scene = load("res://scenes/fragments/fragment_0762.tscn").instantiate()
	root.add_child(fragment_scene)
	current_scene = fragment_scene
	await process_frame

	_check(fragment_scene.get("current_page") == 0, "0762 comic starts on page 1")
	var comic_page: TextureRect = fragment_scene.get("page_texture")
	_check(comic_page.anchor_right == 1.0 and comic_page.anchor_bottom == 1.0, "0762 comic fills the viewport with full-rect anchors")
	_check(comic_page.offset_right == 0.0 and comic_page.offset_bottom == 0.0, "0762 comic does not double its viewport offsets")
	for expected_page in [1, 2]:
		fragment_scene.advance_page()
		await create_timer(0.5).timeout
		_check(fragment_scene.get("current_page") == expected_page, "0762 comic advances to page %d" % (expected_page + 1))
	fragment_scene.advance_page()
	await create_timer(1.4).timeout

	_check(current_scene != null, "0762 comic leaves an active scene")
	if current_scene != null:
		_check(current_scene.name == "Market", "0762 comic enters Market")
		_check(current_scene.has_node("Player"), "Market creates Player")
		_check(current_scene.get_node("Player").position == Vector2(272, 67), "Market places Player near the inn entrance")
		_check(current_scene.has_node("NPC_Fengshen"), "Market initializes innkeeper NPC")
		_check(current_scene.has_node("NPC_Laotang"), "Market initializes baker NPC")
		_check(current_scene.has_node("NPC_Alian"), "Market initializes florist NPC")

	if _failures == 0:
		print("[SUMMARY] 0762 comic and Market initialization passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
