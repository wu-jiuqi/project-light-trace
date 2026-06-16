extends Control

const TARGET_SCENE := "res://scenes/fragments/fragment_0002.tscn"
const FRAME_DIR := "res://assets/papercraft/fragments/id0002/animation/frames"
const FRAME_RATE := 24.0
const FADE_IN_DURATION := 0.35
const FADE_OUT_DURATION := 0.35

@onready var frame_view: TextureRect = $FrameView
@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var skip_hint: Label = $SkipHint

var is_exiting := false
var _fade_tween: Tween = null
var _frame_paths: PackedStringArray = PackedStringArray()
var _elapsed := 0.0
var _current_frame := -1


func _ready() -> void:
	fade_overlay.color.a = 1.0
	skip_hint.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.55))
	skip_hint.add_theme_constant_override("outline_size", 3)
	skip_hint.add_theme_font_size_override("font_size", 16)
	_load_frame_paths()
	if _frame_paths.is_empty():
		push_error("[Fragment0002Transition] No frames found in %s" % FRAME_DIR)
		_finish_transition()
		return
	_show_frame(0)
	AudioManager.play_voice("fragment_0002_transition", audio_player.stream, AudioManager.PRIORITY_HIGH, -8.0, 0.0)
	_fade_in()


func _process(delta: float) -> void:
	if is_exiting or _frame_paths.is_empty():
		return

	_elapsed += delta
	var target_frame := mini(int(floor(_elapsed * FRAME_RATE)), _frame_paths.size() - 1)
	if target_frame != _current_frame:
		_show_frame(target_frame)

	if _elapsed >= float(_frame_paths.size()) / FRAME_RATE:
		_finish_transition()


func _input(event: InputEvent) -> void:
	if is_exiting:
		return
	if _is_skip_event(event):
		get_viewport().set_input_as_handled()
		_finish_transition()


func _load_frame_paths() -> void:
	var dir := DirAccess.open(FRAME_DIR)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "jpg":
			_frame_paths.append("%s/%s" % [FRAME_DIR, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	_frame_paths.sort()


func _show_frame(frame_index: int) -> void:
	var texture := load(_frame_paths[frame_index]) as Texture2D
	if texture == null:
		return
	frame_view.texture = texture
	_current_frame = frame_index


func _is_skip_event(event: InputEvent) -> bool:
	if not event is InputEventKey:
		return false

	var key_event := event as InputEventKey
	return key_event.pressed \
		and not key_event.echo \
		and (
			key_event.is_action_pressed("escape")
			or key_event.is_action_pressed("ui_cancel")
			or key_event.keycode == KEY_ESCAPE
			or key_event.physical_keycode == KEY_ESCAPE
		)


func _fade_in() -> void:
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_overlay, "color:a", 0.0, FADE_IN_DURATION)


func _finish_transition() -> void:
	if is_exiting:
		return
	is_exiting = true
	skip_hint.visible = false
	AudioManager.stop_voice(0.1)
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_overlay, "color:a", 1.0, FADE_OUT_DURATION)
	await _fade_tween.finished

	SceneFader.ensure_black()
	get_tree().change_scene_to_file(TARGET_SCENE)
