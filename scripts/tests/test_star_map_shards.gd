extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager = root.get_node("FragmentManager")
	manager.reset_all_fragments()
	var star_map = load("res://scenes/star_map.tscn").instantiate()
	root.add_child(star_map)
	current_scene = star_map
	await process_frame

	var canvas = star_map.get_node("FragmentContainer/ShardCanvas")
	var card = star_map.get_node("UI/DetailCard")
	_check(canvas.shard_count() == 12, "star map renders exactly 12 shards")
	var center_uv: Vector2 = canvas._uv_for(Vector2(360, 225))
	_check(center_uv.x > 0.0 and center_uv.x < 1.0 and center_uv.y > 0.0 and center_uv.y < 1.0, "glass shard UVs stay normalized")
	_check(center_uv.distance_to(Vector2(0.5, 0.5)) < 0.01, "glass shard UVs sample the star texture center")
	_check(not card.visible, "detail card starts hidden")
	_check(not star_map.has_node("UI/FragmentList"), "fragment list is removed")
	_check(not star_map.has_node("UI/ProgressBar"), "repair progress bar is removed")
	_check(not star_map.has_node("UI/DecryptBtn"), "decrypt button is removed")

	canvas.select_fragment(5)
	await process_frame
	_check(card.visible, "clicking a shard reveals its detail card")
	_check(star_map.get_node("UI/DetailCard/TitleLabel").text.contains("#0762"), "0762 detail card is selected")
	_check(star_map.get_node("UI/DetailCard/EnterBtn").visible, "implemented fragment exposes enter button")

	var fragment = manager.get_fragment_by_id("0762")
	_check(manager.complete_fragment(fragment), "0762 completion succeeds")
	var animation_id = manager.consume_completion_animation_id()
	canvas.configure(manager.fragments, animation_id)
	_check(not canvas.is_fragment_home(5), "completed shard begins its return animation from scatter position")
	await create_timer(1.4).timeout
	_check(canvas.is_fragment_home(5), "completed shard finishes at its four-point-star position")

	manager.reset_all_fragments()
	if _failures == 0:
		print("[SUMMARY] star-map shard interaction checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
