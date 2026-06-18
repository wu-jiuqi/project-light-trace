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
	_check(canvas.shard_count() == 12, "star map renders exactly 12 mask zones")
	_check(not card.visible, "detail card starts hidden")
	_check(not star_map.has_node("UI/FragmentList"), "fragment list is removed")
	_check(not star_map.has_node("UI/ProgressBar"), "repair progress bar is removed")
	_check(not star_map.has_node("UI/DecryptBtn"), "decrypt button is removed")

	canvas.select_fragment(1)
	await process_frame
	_check(card.visible, "clicking the 0002 shard reveals its detail card")
	_check(star_map.get_node("UI/DetailCard/TitleLabel").text.contains("#0002"), "0002 detail card is selected")
	_check(not star_map.get_node("UI/DetailCard/EnterBtn").visible, "0002 starts locked in a new game")

	var first_fragment = manager.get_fragment_by_id("0001")
	_check(manager.complete_fragment(first_fragment), "0001 completion succeeds")
	_check(manager.get_fragment_by_id("0002").unlocked, "0001 completion unlocks 0002")
	canvas.select_fragment(1)
	await process_frame
	_check(star_map.get_node("UI/DetailCard/EnterBtn").visible, "unlocked 0002 exposes enter button")

	canvas.select_fragment(4)
	await process_frame
	_check(card.visible, "clicking a shard reveals its detail card")
	_check(star_map.get_node("UI/DetailCard/TitleLabel").text.contains("#0047"), "0047 detail card is selected")
	_check(not star_map.get_node("UI/DetailCard/EnterBtn").visible, "0047 remains locked until the linear chain reaches it")

	var fragment = manager.get_fragment_by_id("0004")
	fragment.unlocked = true
	_check(manager.complete_fragment(fragment), "0004 completion succeeds")
	var animation_id = manager.consume_completion_animation_id()
	canvas.configure(manager.fragments, animation_id)
	_check(not canvas.is_fragment_revealed(3), "completed mask begins its reveal animation covered")
	await create_timer(1.4).timeout
	_check(canvas.is_fragment_revealed(3), "completed mask fades out to reveal the star map")

	canvas.select_fragment(3)
	await process_frame
	_check(card.visible, "revealed mask zone remains selectable")

	manager.reset_all_fragments()
	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	root.get_node("AudioManager").stop_all()
	await process_frame
	await create_timer(0.2).timeout
	if _failures == 0:
		print("[SUMMARY] star-map shard interaction checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
