extends SceneTree

const TITLE_REFERENCE_SIZE := Vector2(1280, 720)
const TITLE_BG_SIZE := Vector2(1672, 941)
const TITLE_HIT_RECTS: Array = [
	Rect2(735, 75, 405, 100),
	Rect2(735, 195, 405, 85),
	Rect2(735, 300, 405, 80),
	Rect2(735, 400, 405, 80),
	Rect2(735, 500, 405, 80),
]

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame

	_check_scene_panel("res://scenes/ui/DialogueBox.tscn", "Stage/DialoguePanel", "chat panel uses texture skin")
	_check_scene_panel("res://scenes/ui/DialogueHistory.tscn", "Stage/LargePage", "dialogue history scene uses texture skin")
	_check_scene_panel("res://scenes/ui/CluePanel.tscn", "Stage/MainContainer", "clue panel scene uses texture skin")
	_check_scene_panel("res://scenes/ui/SettingsPanel.tscn", "Stage/LargePage", "settings panel scene uses texture skin")
	_check_scene_panel("res://scenes/ui/PauseMenu.tscn", "Stage/PauseContainer", "pause menu scene uses texture skin")

	var title_scene = load("res://scenes/ui/title_screen.tscn").instantiate()
	root.add_child(title_scene)
	current_scene = title_scene
	await process_frame
	_check(title_scene.get_node("BG") is TextureRect, "title screen uses generated background")
	_check(title_scene.has_node("HitContainer"), "title screen builds hit container")
	_check(title_scene.has_node("SettingsGearButton"), "title screen has settings gear button")
	_check(title_scene.has_node("SettingsPanel"), "title screen has settings panel instance")
	_check_title_hit_layout(title_scene, Vector2(1280, 720), "title hit areas align at reference size")
	_check_title_hit_layout(title_scene, Vector2(1920, 1080), "title hit areas scale at 16:9 fullscreen")
	_check_title_hit_layout(title_scene, Vector2(1280, 800), "title hit areas account for cover crop")

	title_scene.queue_free()
	await process_frame

	var star_map = load("res://scenes/star_map.tscn").instantiate()
	root.add_child(star_map)
	current_scene = star_map
	await process_frame
	_check(star_map.get_node("BG") is TextureRect, "star map uses generated background")
	_check(_has_texture_backed_control(star_map.get_node("UI/DetailCard")), "star map detail card uses texture skin")
	_check(
		star_map.get_node("UI/DetailCard/EnterBtn").get_theme_stylebox("normal") is StyleBoxEmpty,
		"star map buttons use transparent hotspots over texture skin"
	)
	_check(not star_map.has_node("UI/FragmentList"), "star map no longer uses fragment list")
	_check(not star_map.has_node("UI/ProgressBar"), "star map no longer shows progress bar")
	_check(not star_map.has_node("UI/DecryptBtn"), "star map no longer exposes decrypt action")

	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	root.get_node("AudioManager").stop_all()
	await process_frame
	await create_timer(0.2).timeout

	if _failures == 0:
		print("[SUMMARY] UI skin regression checks passed")
	quit(_failures)


func _has_texture_panel(panel: Panel) -> bool:
	return panel != null and panel.get_theme_stylebox("panel") is StyleBoxTexture


func _has_texture_backed_control(control: Control) -> bool:
	if control == null:
		return false
	var background := control.get_node_or_null("DialogBG") as TextureRect
	return background != null and background.texture != null


func _check_scene_panel(scene_path: String, panel_path: String, message: String) -> void:
	var scene = load(scene_path).instantiate()
	root.add_child(scene)
	var surface := scene.get_node_or_null(panel_path) as Control
	_check(_has_texture_surface(surface), message)
	scene.queue_free()


func _has_texture_surface(surface: Control) -> bool:
	if surface is Panel:
		return _has_texture_panel(surface as Panel)
	if surface is TextureRect:
		return (surface as TextureRect).texture != null
	return false


func _check_title_hit_layout(title_scene: Control, layout_size: Vector2, message: String) -> void:
	title_scene.size = layout_size
	title_scene.call("_layout_all")

	var hit_container := title_scene.get_node("HitContainer") as Control
	var hit_areas := _title_hit_areas(hit_container)
	_check(hit_areas.size() == TITLE_HIT_RECTS.size(), "%s: builds five hit areas" % message)
	if hit_areas.size() != TITLE_HIT_RECTS.size():
		return

	for i in hit_areas.size():
		var expected := _expected_title_hit_rect(TITLE_HIT_RECTS[i], layout_size)
		var actual := Rect2(hit_areas[i].position, hit_areas[i].size)
		_check(_rect_approx(actual, expected), "%s: hit area %d matches background" % [message, i + 1])

	var highlight := hit_container.get_node("SelectionHighlight") as ColorRect
	var first_area := hit_areas[0]
	_check(
		_rect_approx(Rect2(highlight.position, highlight.size), Rect2(first_area.position, first_area.size)),
		"%s: highlight follows selected hit area" % message
	)


func _title_hit_areas(hit_container: Control) -> Array[Control]:
	var hit_areas: Array[Control] = []
	for child in hit_container.get_children():
		if child is Control and String(child.name).begins_with("HitArea"):
			hit_areas.append(child)
	return hit_areas


func _expected_title_hit_rect(reference_rect: Rect2, layout_size: Vector2) -> Rect2:
	var reference_bg_rect := _cover_rect(TITLE_REFERENCE_SIZE, TITLE_BG_SIZE)
	var layout_bg_rect := _cover_rect(layout_size, TITLE_BG_SIZE)
	var reference_scale: float = reference_bg_rect.size.x / TITLE_BG_SIZE.x
	var layout_scale: float = layout_bg_rect.size.x / TITLE_BG_SIZE.x
	var texture_position: Vector2 = (reference_rect.position - reference_bg_rect.position) / reference_scale
	var texture_size: Vector2 = reference_rect.size / reference_scale
	return Rect2(
		layout_bg_rect.position + texture_position * layout_scale,
		texture_size * layout_scale
	)


func _cover_rect(container_size: Vector2, texture_size: Vector2) -> Rect2:
	var cover_scale: float = maxf(
		container_size.x / texture_size.x,
		container_size.y / texture_size.y
	)
	var drawn_size: Vector2 = texture_size * cover_scale
	return Rect2((container_size - drawn_size) * 0.5, drawn_size)


func _rect_approx(actual: Rect2, expected: Rect2, tolerance := 0.75) -> bool:
	return actual.position.distance_to(expected.position) <= tolerance \
			and actual.size.distance_to(expected.size) <= tolerance


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
