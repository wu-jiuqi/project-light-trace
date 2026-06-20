extends Control

const UITheme = preload("res://scripts/ui/ui_theme.gd")

@export var simulate_in_preview := true
@export_range(0.0, 100.0, 0.1) var initial_progress := 18.0
@export var messages := PackedStringArray([
	"校准星图碎片",
	"缝合光痕路径",
	"读取纸面档案",
	"定位下一段记忆",
])
@export var minimum_display_time := 0.45
@export var minimum_animation_time := 2.2
@export var completion_hold_time := 0.35
@export var minimum_display_frames := 36

@onready var _background: TextureRect = $Background
@onready var _night_wash: ColorRect = $NightWash
@onready var _spinner: Control = $TraceSpinner
@onready var _progress_bar: ProgressBar = $ProgressArea/ProgressBar
@onready var _percent_label: Label = $ProgressArea/PercentLabel
@onready var _status_label: Label = $ProgressArea/StatusLabel
@onready var _hint_label: Label = $ProgressArea/HintLabel
@onready var _progress_glow: ColorRect = $ProgressArea/ProgressGlow

var _elapsed := 0.0
var _display_progress := 0.0
var _target_progress := 0.0
var _message_index := 0
var _loading_target_path := ""
var _loading_elapsed := 0.0
var _loading_started_msec := 0
var _loading_frames := 0
var _completion_started_msec := 0
var _is_loading_scene := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not WebPackManager.pack_download_progress.is_connected(_on_pack_download_progress):
		WebPackManager.pack_download_progress.connect(_on_pack_download_progress)
	_target_progress = clampf(initial_progress, 0.0, 100.0)
	_display_progress = _target_progress
	_apply_skin()
	call_deferred("_try_start_scene_manager_request")
	_update_progress_ui()
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _is_loading_scene:
		_poll_scene_load(delta)
	elif simulate_in_preview:
		_target_progress = fposmod(_elapsed * 14.0, 112.0)
		if _target_progress > 100.0:
			_target_progress = 100.0
		_message_index = int(_elapsed / 2.1) % max(1, messages.size())

	_display_progress = lerpf(_display_progress, _target_progress, 1.0 - exp(-delta * 5.0))
	_animate_surface()
	_update_progress_ui()


func set_loading_progress(value: float, message := "") -> void:
	simulate_in_preview = false
	_is_loading_scene = false
	_target_progress = clampf(value, 0.0, 100.0)
	if not message.is_empty():
		_status_label.text = message


func start_scene_load(target_scene_path: String) -> void:
	if target_scene_path.is_empty():
		printerr("[LoadingScreen] empty target scene path")
		return

	simulate_in_preview = false
	_is_loading_scene = true
	_loading_target_path = target_scene_path
	_loading_elapsed = 0.0
	_loading_started_msec = Time.get_ticks_msec()
	_loading_frames = 0
	_completion_started_msec = 0
	_target_progress = 2.0
	_display_progress = 0.0
	_status_label.text = "读取场景档案"

	if WebPackManager.has_pack_for_scene(_loading_target_path):
		_status_label.text = "正在加载下一段记忆..."
		var pack_ok := await WebPackManager.ensure_pack_for_scene(_loading_target_path)
		if not pack_ok:
			printerr("[LoadingScreen] pack load failed before scene load: %s" % _loading_target_path)
			_is_loading_scene = false
			if SceneManager.has_method("_abort_loading_transition"):
				SceneManager._abort_loading_transition(_loading_target_path)
			return
		_target_progress = maxf(_target_progress, 48.0)
		_status_label.text = "资源包已就绪，读取场景档案"

	var err := ResourceLoader.load_threaded_request(_loading_target_path, "PackedScene")
	if err != OK:
		printerr("[LoadingScreen] threaded load request failed: %s (code %d)" % [_loading_target_path, err])
		if SceneManager.has_method("_complete_loading_transition_with_file"):
			SceneManager._complete_loading_transition_with_file(_loading_target_path)


func reset_preview() -> void:
	simulate_in_preview = true
	_is_loading_scene = false
	_loading_target_path = ""
	_loading_started_msec = 0
	_loading_frames = 0
	_completion_started_msec = 0
	_elapsed = 0.0
	_target_progress = initial_progress


func _apply_skin() -> void:
	UITheme.apply_progress(_progress_bar)
	_status_label.add_theme_color_override("font_color", Color(0.90, 0.81, 0.62, 0.98))
	_status_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.62))
	_status_label.add_theme_constant_override("shadow_offset_x", 1)
	_status_label.add_theme_constant_override("shadow_offset_y", 2)
	_percent_label.add_theme_color_override("font_color", Color(0.70, 0.92, 1.0, 0.96))
	_percent_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	_hint_label.add_theme_color_override("font_color", Color(0.70, 0.64, 0.52, 0.82))
	_hint_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.58))


func _animate_surface() -> void:
	_background.position = Vector2(-12.0, -12.0)
	_background.scale = Vector2.ONE
	_night_wash.color = Color(0.02, 0.04, 0.08, 0.30 + 0.035 * sin(_elapsed * 0.9))
	_spinner.rotation = sin(_elapsed * 0.35) * 0.025
	_spinner.modulate.a = 0.88 + 0.10 * sin(_elapsed * 1.8)


func _update_progress_ui() -> void:
	var value := clampf(_display_progress, 0.0, 100.0)
	_progress_bar.value = value
	_spinner.set("progress", value)
	_percent_label.text = "%02d%%" % roundi(value)
	if simulate_in_preview and messages.size() > 0:
		_status_label.text = messages[_message_index]

	var bar_width := maxf(_progress_bar.size.x, 1.0)
	_progress_glow.visible = value > 1.0
	_progress_glow.size.x = maxf(10.0, bar_width * value / 100.0)
	_progress_glow.modulate.a = 0.23 + 0.18 * sin(_elapsed * 4.0)


func _on_pack_download_progress(_pack_id: String, downloaded_bytes: int, total_bytes: int) -> void:
	if not _is_loading_scene:
		return
	_status_label.text = "正在加载下一段记忆..."
	if total_bytes > 0:
		var ratio := clampf(float(downloaded_bytes) / float(total_bytes), 0.0, 1.0)
		_target_progress = maxf(_target_progress, 2.0 + ratio * 44.0)
	else:
		_target_progress = minf(44.0, _target_progress + 0.25)


func _try_start_scene_manager_request() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if SceneManager.has_method("has_pending_loading_request") \
			and SceneManager.has_pending_loading_request():
		start_scene_load(SceneManager.get_pending_loading_target())


func _poll_scene_load(delta: float) -> void:
	_loading_elapsed += delta
	_loading_frames += 1
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(_loading_target_path, progress)
	if progress.size() > 0:
		_target_progress = maxf(_target_progress, clampf(float(progress[0]) * 96.0, 2.0, 96.0))
	else:
		_target_progress = minf(90.0, _target_progress + delta * 22.0)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_message_index = int(_elapsed / 1.5) % max(1, messages.size())
			if messages.size() > 0:
				_status_label.text = messages[_message_index]
		ResourceLoader.THREAD_LOAD_LOADED:
			_target_progress = 100.0
			_status_label.text = "完成光痕校准"
			var visible_seconds := float(Time.get_ticks_msec() - _loading_started_msec) / 1000.0
			var animation_finished := visible_seconds >= maxf(minimum_display_time, minimum_animation_time) \
					and _loading_frames >= minimum_display_frames \
					and _display_progress >= 99.0
			if animation_finished and _completion_started_msec <= 0:
				_completion_started_msec = Time.get_ticks_msec()
			if _completion_started_msec > 0 \
					and float(Time.get_ticks_msec() - _completion_started_msec) / 1000.0 >= completion_hold_time:
				_is_loading_scene = false
				var packed := ResourceLoader.load_threaded_get(_loading_target_path) as PackedScene
				if SceneManager.has_method("_complete_loading_transition"):
					SceneManager._complete_loading_transition(packed, _loading_target_path)
				else:
					get_tree().change_scene_to_packed(packed)
		ResourceLoader.THREAD_LOAD_FAILED:
			printerr("[LoadingScreen] threaded load failed: %s" % _loading_target_path)
			_is_loading_scene = false
			if SceneManager.has_method("_abort_loading_transition"):
				SceneManager._abort_loading_transition(_loading_target_path)
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			printerr("[LoadingScreen] invalid threaded load resource: %s" % _loading_target_path)
			_is_loading_scene = false
			if SceneManager.has_method("_abort_loading_transition"):
				SceneManager._abort_loading_transition(_loading_target_path)
