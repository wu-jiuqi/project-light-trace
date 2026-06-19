extends Node

const FTUEOverlayScript := preload("res://scripts/ui/ftue_overlay.gd")

enum Stage {
	NOT_STARTED,
	INTRO_DONE,
	STAR_MAP_GUIDE,
	FRAGMENT_0001,
	POST_FRAGMENT,
	COMPLETE,
}

var intro_watched: bool = false
var intro_skipped: bool = false
var ftue_stage: int = Stage.NOT_STARTED
var tutorial_completed: bool = false
var movement_hint_seen: bool = false
var star_map_hint_seen: bool = false
var post_fragment_hint_seen: bool = false
var seen_tip_ids: Array[String] = []

var _overlay: CanvasLayer = null
var _observed_distance: float = 0.0


func _ready() -> void:
	_ensure_overlay()


func reset_for_new_game() -> void:
	intro_watched = false
	intro_skipped = false
	ftue_stage = Stage.NOT_STARTED
	tutorial_completed = false
	movement_hint_seen = false
	star_map_hint_seen = false
	post_fragment_hint_seen = false
	seen_tip_ids.clear()
	_observed_distance = 0.0
	if _overlay:
		_overlay.hide_hint(false)
		_overlay.clear_pulse()


func mark_intro_finished(skipped: bool = false) -> void:
	intro_watched = true
	intro_skipped = skipped
	if ftue_stage == Stage.NOT_STARTED:
		ftue_stage = Stage.INTRO_DONE


func should_show_star_map_guide() -> bool:
	return not tutorial_completed and not star_map_hint_seen


func show_star_map_guide() -> void:
	if not should_show_star_map_guide():
		return
	ftue_stage = Stage.STAR_MAP_GUIDE
	star_map_hint_seen = true
	show_tip("star_map_start", "选择碎片 #0001，开始第一次探索。", 4.5)


func show_next_fragment_unlocked(fragment_id: String) -> void:
	if fragment_id.is_empty():
		return
	ftue_stage = Stage.POST_FRAGMENT
	post_fragment_hint_seen = true
	show_tip("next_%s_unlocked" % fragment_id, "下一段碎片 #%s 已解锁。星图正在等待你的下一步。" % fragment_id, 4.5)


func start_fragment_0001() -> void:
	if tutorial_completed:
		return
	ftue_stage = Stage.FRAGMENT_0001
	if not movement_hint_seen:
		show_tip("move_hint", "W A S D 移动。先走向喷泉旁的林指导。", 5.0)


func observe_player_motion(delta_distance: float) -> void:
	if movement_hint_seen or ftue_stage != Stage.FRAGMENT_0001:
		return
	_observed_distance += maxf(delta_distance, 0.0)
	if _observed_distance >= 180.0:
		movement_hint_seen = true
		hide_tip()


func mark_interaction(kind: String, id: String = "") -> void:
	if tutorial_completed:
		return
	match kind:
		"npc":
			show_tip_once("first_npc", "对话会记录重要线索。靠近目标时，按 E 可以再次交谈。", 4.0)
		"interactable":
			show_tip_once("first_interactable", "观察结果会自动记录。线索之间的关系，比单条记录更重要。", 4.0)
		"source_mark":
			tutorial_completed = true
			ftue_stage = Stage.COMPLETE
			show_tip("tutorial_complete", "碎片修复完成。返回星图后，下一段碎片将解锁。", 4.5)


func show_tip_once(id: String, text: String, duration: float = 4.0) -> void:
	if seen_tip_ids.has(id):
		return
	show_tip(id, text, duration)


func show_tip(id: String, text: String, duration: float = 0.0) -> void:
	if not seen_tip_ids.has(id):
		seen_tip_ids.append(id)
	_ensure_overlay()
	if _overlay:
		_overlay.show_hint(text, duration)


func hide_tip() -> void:
	if _overlay:
		_overlay.hide_hint()


func pulse_control(control: Control) -> void:
	_ensure_overlay()
	if _overlay:
		_overlay.pulse_control(control)


func clear_pulse() -> void:
	if _overlay:
		_overlay.clear_pulse()


func to_dict() -> Dictionary:
	return {
		"intro_watched": intro_watched,
		"intro_skipped": intro_skipped,
		"ftue_stage": ftue_stage,
		"tutorial_completed": tutorial_completed,
		"movement_hint_seen": movement_hint_seen,
		"star_map_hint_seen": star_map_hint_seen,
		"post_fragment_hint_seen": post_fragment_hint_seen,
		"seen_tip_ids": seen_tip_ids.duplicate(),
	}


func from_dict(data: Dictionary) -> void:
	intro_watched = bool(data.get("intro_watched", intro_watched))
	intro_skipped = bool(data.get("intro_skipped", false))
	ftue_stage = int(data.get("ftue_stage", ftue_stage))
	tutorial_completed = bool(data.get("tutorial_completed", tutorial_completed))
	movement_hint_seen = bool(data.get("movement_hint_seen", false))
	star_map_hint_seen = bool(data.get("star_map_hint_seen", false))
	post_fragment_hint_seen = bool(data.get("post_fragment_hint_seen", false))
	seen_tip_ids.clear()
	var raw_seen = data.get("seen_tip_ids", [])
	if raw_seen is Array:
		for id in raw_seen:
			seen_tip_ids.append(str(id))


func infer_from_fragments(completed_ids: Array[String], unlocked_ids: Array[String]) -> void:
	if completed_ids.size() > 0:
		intro_watched = true
		star_map_hint_seen = true
	if completed_ids.has("0001"):
		tutorial_completed = true
		ftue_stage = Stage.COMPLETE
		movement_hint_seen = true


func _ensure_overlay() -> void:
	if is_instance_valid(_overlay):
		return
	_overlay = FTUEOverlayScript.new()
	_overlay.name = "FTUEOverlay"
	get_tree().root.call_deferred("add_child", _overlay)
