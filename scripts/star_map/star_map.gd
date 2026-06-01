extends CanvasLayer
## 星图主界面：点击散落玻璃碎片查看详情，已修复碎片归位成四芒星。

const UITheme = preload("res://scripts/ui/ui_theme.gd")

@onready var shard_canvas: StarShardCanvas = $FragmentContainer/ShardCanvas
@onready var detail_card: Panel = $UI/DetailCard
@onready var detail_title: Label = $UI/DetailCard/TitleLabel
@onready var detail_body: Label = $UI/DetailCard/BodyLabel
@onready var enter_btn: Button = $UI/DetailCard/EnterBtn
@onready var close_btn: Button = $UI/DetailCard/CloseBtn

var selected_fragment: FragmentManager.FragmentData = null
var _card_open := false


func _ready() -> void:
	_apply_skin()
	shard_canvas.fragment_selected.connect(_on_fragment_selected)
	shard_canvas.empty_clicked.connect(_close_detail_card)
	enter_btn.pressed.connect(_on_enter_btn_pressed)
	close_btn.pressed.connect(_close_detail_card)
	var animate_id = FragmentManager.consume_completion_animation_id()
	shard_canvas.configure(FragmentManager.fragments, animate_id)
	_close_detail_card(false)
	print("[StarMap] 玻璃星图界面加载完成")


func _apply_skin() -> void:
	$TitleBar.add_theme_stylebox_override("panel", UITheme.panel_style(true))
	detail_card.add_theme_stylebox_override("panel", UITheme.panel_style())
	UITheme.apply_button(enter_btn, true)
	UITheme.apply_button(close_btn)


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
	detail_title.text = "碎片 #%s  %s" % [fragment.id, fragment.name]
	var state_text = "已修复 · 已归位" if fragment.completed else "尚未修复 · 漂流中"
	var importance = "关键剧情碎片" if fragment.is_story_critical else "普通碎片"
	detail_body.text = "世界：%s\n难度：%d / 5\n类型：%s\n状态：%s\n\n线索：%s" % [
		fragment.world_name,
		fragment.difficulty,
		importance,
		state_text,
		fragment.hint,
	]
	if fragment.completed:
		detail_body.text += "\n\n源印：%s" % fragment.source_mark_name
	if fragment.implemented:
		enter_btn.text = "再次进入" if fragment.completed else "进入碎片"
		enter_btn.visible = true
	else:
		detail_body.text += "\n\n该碎片尚未开放。"
		enter_btn.visible = false


func _open_detail_card() -> void:
	_card_open = true
	detail_card.visible = true
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(detail_card, "position:x", 830.0, 0.24)


func _close_detail_card(animated: bool = true) -> void:
	selected_fragment = null
	_card_open = false
	if not animated:
		detail_card.position.x = 1280.0
		detail_card.visible = false
		return
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(detail_card, "position:x", 1280.0, 0.2)
	tween.tween_callback(func() -> void: detail_card.visible = false)


func _on_enter_btn_pressed() -> void:
	if selected_fragment == null:
		return
	if not FragmentManager.enter_fragment(selected_fragment):
		return
	if selected_fragment.scene_path and ResourceLoader.exists(selected_fragment.scene_path):
		get_tree().change_scene_to_file(selected_fragment.scene_path)
	else:
		printerr("[StarMap] 碎片场景不存在: %s" % selected_fragment.scene_path)
