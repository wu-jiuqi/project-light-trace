extends CanvasLayer
## 星图主界面：点击散落玻璃碎片查看详情，已修复碎片归位成四芒星。

const DETAIL_CARD_SIZE := Vector2(470, 628)
const DETAIL_HIGHLIGHT_COLOR := Color(0.63, 0.42, 0.15, 0.18)
const BGM_STAR_MAP = preload("res://assets/audio/bgm/bgm_star_map_loop.ogg")
const FRAGMENT_TRANSITION_SCENES := {
	"0001": "res://scenes/cinematic/fragment_0001_transition.tscn",
	"0002": "res://scenes/cinematic/fragment_0002_transition.tscn",
	"0003": "res://scenes/cinematic/fragment_0003_transition.tscn",
}

@onready var shard_canvas: StarShardCanvas = $FragmentContainer/ShardCanvas
@onready var detail_card: Control = $UI/DetailCard
@onready var detail_title: Label = $UI/DetailCard/TitleLabel
@onready var detail_body: Label = $UI/DetailCard/BodyLabel

var selected_fragment: FragmentManager.FragmentData = null
var _card_open := false
var _detail_selected: int = 0
var _detail_highlight: ColorRect
var enter_btn: Button
var close_btn: Button
var _bgm_player: AudioStreamPlayer = null


func _ready() -> void:
	_create_detail_interaction_nodes()
	_apply_skin()
	shard_canvas.fragment_selected.connect(_on_fragment_selected)
	shard_canvas.empty_clicked.connect(_close_detail_card)
	enter_btn.pressed.connect(_on_enter_btn_pressed)
	enter_btn.pressed.connect(UISoundManager.play_click)
	close_btn.pressed.connect(_close_detail_card)
	close_btn.pressed.connect(UISoundManager.play_click)
	get_viewport().size_changed.connect(_layout_detail_card)
	var animate_id = FragmentManager.consume_completion_animation_id()
	var unlocked_id = FragmentManager.consume_pending_unlocked_fragment_id()
	shard_canvas.configure(FragmentManager.fragments, animate_id)
	_close_detail_card(false)
	# 在 UI 初始化完成后淡入，恢复 SceneFader 切场景时的全黑状态
	SceneFader.fade_in()
	# 从开场动画跳转过来时，对碎片 0001 播放高光闪烁引导
	if SceneManager.pending_spawn_point == "from_cutscene":
		SceneManager.pending_spawn_point = ""
		await get_tree().create_timer(0.5).timeout
		shard_canvas.flash_fragment("0001", 3, 0.35)
		if TutorialManager and TutorialManager.has_method("show_star_map_guide"):
			TutorialManager.show_star_map_guide()
	elif not unlocked_id.is_empty():
		await get_tree().create_timer(0.5).timeout
		shard_canvas.flash_fragment(unlocked_id, 3, 0.35)
		if TutorialManager and TutorialManager.has_method("show_next_fragment_unlocked"):
			TutorialManager.show_next_fragment_unlocked(unlocked_id)
	print("[StarMap] 玻璃星图界面加载完成")
	# 播放星图界面循环 BGM
	_start_bgm()


func _apply_skin() -> void:
	_apply_transparent_button(enter_btn)
	_apply_transparent_button(close_btn)


func _create_detail_interaction_nodes() -> void:
	_detail_highlight = ColorRect.new()
	_detail_highlight.name = "DialogHighlight"
	_detail_highlight.visible = false
	_detail_highlight.layout_mode = 1
	_detail_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_highlight.color = DETAIL_HIGHLIGHT_COLOR
	detail_card.add_child(_detail_highlight)
	_move_child_after(_detail_highlight, "DialogBG")

	enter_btn = _create_detail_button("EnterBtn", 0.137, 0.805, 0.484, 0.879)
	close_btn = _create_detail_button("CloseBtn", 0.527, 0.805, 0.858, 0.879)
	enter_btn.mouse_entered.connect(_select_detail_button.bind(0))
	close_btn.mouse_entered.connect(_select_detail_button.bind(1))
	enter_btn.focus_entered.connect(_select_detail_button.bind(0))
	close_btn.focus_entered.connect(_select_detail_button.bind(1))


func _create_detail_button(
		node_name: String,
		left: float,
		top: float,
		right: float,
		bottom: float
) -> Button:
	var button := Button.new()
	button.name = node_name
	button.layout_mode = 1
	button.anchors_preset = -1
	button.anchor_left = left
	button.anchor_top = top
	button.anchor_right = right
	button.anchor_bottom = bottom
	button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	button.grow_vertical = Control.GROW_DIRECTION_BOTH
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	detail_card.add_child(button)
	return button


func _move_child_after(child: Node, sibling_name: String) -> void:
	var sibling := detail_card.get_node_or_null(sibling_name)
	if sibling == null:
		return
	detail_card.move_child(child, sibling.get_index() + 1)


func _apply_transparent_button(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.text = ""
	button.flat = true
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("focus", empty)
	button.add_theme_stylebox_override("disabled", empty)


func _on_fragment_selected(index: int) -> void:
	if index < 0 or index >= FragmentManager.fragments.size():
		return
	selected_fragment = FragmentManager.fragments[index]
	_update_detail_card()
	_open_detail_card()


func _update_detail_card() -> void:
	var fragment = selected_fragment
	if fragment == null:
		return
	detail_title.text = "#%s  %s" % [fragment.id, fragment.name]
	var state_text := "已修复 · 已归位" if fragment.completed else "尚未修复 · 漂流中"
	var importance := "关键剧情碎片" if fragment.is_story_critical else "普通碎片"
	detail_body.text = "世界：%s\n难度：%d / 5\n类型：%s\n状态：%s\n\n线索：%s" % [
		fragment.world_name,
		fragment.difficulty,
		importance,
		state_text,
		fragment.hint,
	]
	if fragment.completed:
		detail_body.text += "\n\n源印：%s" % fragment.source_mark_name
	if not fragment.unlocked:
		detail_body.text += "\n\n已锁定：完成当前碎片后解锁。"
		enter_btn.visible = false
		_detail_selected = 1
	elif fragment.implemented:
		enter_btn.visible = true
		_detail_selected = 0
	else:
		detail_body.text += "\n\n该碎片尚未开放。"
		enter_btn.visible = false
		_detail_selected = 1
	_update_detail_highlight()

func _open_detail_card() -> void:
	_card_open = true
	detail_card.visible = true
	_layout_detail_card()
	# Override x to off-screen right so the tween slides the card in.
	detail_card.position.x = _get_detail_closed_x()
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(detail_card, "position:x", _get_detail_open_x(), 0.2)
	tween.tween_callback(_update_detail_highlight)


func _close_detail_card(animated: bool = true) -> void:
	selected_fragment = null
	_card_open = false
	_detail_highlight.visible = false
	if not animated:
		_layout_detail_card()
		detail_card.visible = false
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(detail_card, "position:x", _get_detail_closed_x(), 0.2)
	tween.tween_callback(func() -> void: detail_card.visible = false)


func _layout_detail_card() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	detail_card.size = DETAIL_CARD_SIZE
	detail_card.position.y = maxf(24.0, (viewport_size.y - DETAIL_CARD_SIZE.y) * 0.5)
	detail_card.position.x = _get_detail_open_x() if _card_open else _get_detail_closed_x()
	if _card_open:
		_update_detail_highlight()


func _get_detail_open_x() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.x - DETAIL_CARD_SIZE.x - 34.0


func _get_detail_closed_x() -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.x + 24.0


func _select_detail_button(index: int) -> void:
	if index == 0 and not enter_btn.visible:
		index = 1
	_detail_selected = clampi(index, 0, 1)
	_update_detail_highlight()


func _update_detail_highlight() -> void:
	if not _card_open or not detail_card.visible:
		_detail_highlight.visible = false
		return
	var target := enter_btn if _detail_selected == 0 and enter_btn.visible else close_btn
	_detail_highlight.visible = true
	_detail_highlight.position = target.position
	_detail_highlight.size = target.size
	_detail_highlight.move_to_front()
	target.grab_focus()


func _input(event: InputEvent) -> void:
	if not _card_open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		_close_detail_card()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_select_detail_button(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_select_detail_button(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if _detail_selected == 0 and enter_btn.visible:
			_on_enter_btn_pressed()
		else:
			_close_detail_card()
		get_viewport().set_input_as_handled()


func _on_enter_btn_pressed() -> void:
	if selected_fragment == null:
		return
	if not selected_fragment.unlocked:
		if TutorialManager and TutorialManager.has_method("show_tip"):
			TutorialManager.show_tip("fragment_locked", "这个碎片尚未解锁。先完成当前开放的碎片。", 3.0)
		return
	if not FragmentManager.enter_fragment(selected_fragment):
		return
	var transition_scene_path := String(FRAGMENT_TRANSITION_SCENES.get(selected_fragment.id, ""))
	if not transition_scene_path.is_empty() and ResourceLoader.exists(transition_scene_path):
		_stop_bgm()
		SceneManager.change_scene(transition_scene_path)
		return
	if selected_fragment.scene_path and ResourceLoader.exists(selected_fragment.scene_path):
		_stop_bgm()
		SceneManager.change_scene(selected_fragment.scene_path)
	else:
		printerr("[StarMap] 碎片场景不存在: %s" % selected_fragment.scene_path)


# ============================================================
# BGM 播放
# ============================================================

func _start_bgm() -> void:
	AudioManager.play_bgm(BGM_STAR_MAP, "star_map", 0.45, -8.0, true)

func _stop_bgm() -> void:
	AudioManager.stop_bgm(0.25)
