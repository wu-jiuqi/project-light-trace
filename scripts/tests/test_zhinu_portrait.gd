extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_manager = root.get_node("GameManager")
	var studio = Node2D.new()
	studio.name = "Studio"
	root.add_child(studio)
	var state = load("res://scripts/fragment/fragment_0762_state.gd").new()
	studio.add_child(state)
	await process_frame

	for index in range(game_manager.get_awakened_colors().size()):
		game_manager.awaken_color(index)
	state._create_gray_cloth()
	_check(studio.has_node("PortraitNode/ZhinuPortrait"), "studio creates the Zhinu portrait texture")
	_check(studio.has_node("GrayCloth"), "studio covers the portrait with gray cloth")

	state._uncover_gray_cloth()
	await create_timer(1.2).timeout
	_check(root.get_node("FragmentManager").get_fragment_state("0762", "gray_cloth_uncovered"), "uncover state keeps the legacy save key")
	_check(not studio.has_node("GrayCloth"), "gray cloth is removed after uncovering")
	_check(studio.has_node("SourceMark/MarkVisual"), "emotion source mark appears over the Zhinu portrait")

	studio.queue_free()
	game_manager.reset_fragment()
	if _failures == 0:
		print("[SUMMARY] Zhinu portrait reveal checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
