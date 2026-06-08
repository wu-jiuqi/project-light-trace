extends Control
class_name OpeningCinematic

## 开场动画漫画版 — 页控制器
## 6页13格。任意键/点击翻页。最后一页结束后过渡到星图。

# ============================================
# @onready 节点引用
# ============================================

@onready var page_container: Control = $PageContainer
@onready var narration_text: RichTextLabel = $NarrationOverlay/Text
@onready var page_indicator: Label = $PageIndicator
@onready var click_hint: Label = $ClickHint

# ============================================
# 状态
# ============================================

var pages: Array[Control] = []
var current_page: int = 0
var is_transitioning: bool = false

# ============================================
# 旁白文本（每页一条）
# ============================================

const NARRATION: Array[String] = [
	"[center]编号 TP-2077-03-溯光者。身份确认。[/center]",
	"[center]万象——人类迄今最大规模的数字现实平台。\n四十七亿人的记忆、情感与生活，被安全保存于此。[/center]",
	"[center]2077年3月15日。凌晨3点15分。[/center]",
	"[center]核心AI——织女·太一——出现未知异常。\n万象碎裂为十二个孤立碎片。\n四十七亿意识——陷入休眠。[/center]",
	"[center]您已被选定为溯光者。\n任务如下——[/center]",
	"[center][color=#c04040]注意——[/color]\n碎片内的一切均不真实。\n请勿过度共情其中的居民。[/center]",
	""  # 第6页无声
]

# ============================================
# 生命周期
# ============================================

func _ready() -> void:
	# 开场动画期间禁止自动存档（此时游戏状态未完全初始化，存档校验和会失败）
	if SaveManager.get_current_slot() >= 0:
		SaveManager._stop_auto_save()
	_gather_pages()
	_show_page(0)


func _gather_pages() -> void:
	for child in page_container.get_children():
		if child is Control and child.name.begins_with("Page"):
			pages.append(child)
	pages.sort_custom(func(a: Node, b: Node): return a.name.naturalnocasecmp_to(b.name) < 0)


# ============================================
# 页面切换
# ============================================

func _show_page(idx: int) -> void:
	for i: int in pages.size():
		pages[i].visible = (i == idx)
	current_page = idx
	_update_narration(idx)
	_update_page_indicator()


func _update_narration(idx: int) -> void:
	if idx < NARRATION.size():
		narration_text.text = NARRATION[idx]
	else:
		narration_text.text = ""


func _update_page_indicator() -> void:
	page_indicator.text = "%d / %d" % [current_page + 1, pages.size()]


# ============================================
# 输入处理
# ============================================

func _input(event: InputEvent) -> void:
	if is_transitioning:
		return

	var should_advance: bool = false

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			should_advance = true
	elif event is InputEventKey:
		if event.pressed and not event.echo:
			should_advance = true
	elif event is InputEventJoypadButton:
		if event.pressed:
			should_advance = true

	if should_advance:
		get_viewport().set_input_as_handled()
		_next_page()


# ============================================
# 翻页动画
# ============================================

func _next_page() -> void:
	if current_page >= pages.size() - 1:
		_go_to_star_map()
		return

	is_transitioning = true
	_hide_hint()

	var old_page: Control = pages[current_page]
	var new_page: Control = pages[current_page + 1]

	new_page.modulate.a = 0.0
	new_page.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_page, "modulate:a", 0.0, 0.5)
	tween.tween_property(new_page, "modulate:a", 1.0, 0.5)

	tween.chain().tween_callback(func() -> void:
		old_page.visible = false
		old_page.modulate.a = 1.0
		current_page += 1
		_update_page_indicator()
		is_transitioning = false
		_show_hint()
	)


func _go_to_star_map() -> void:
	is_transitioning = true
	SceneManager.change_scene("res://scenes/star_map.tscn", "from_cutscene")


# ============================================
# UI 提示
# ============================================

func _hide_hint() -> void:
	var t := create_tween()
	t.tween_property(click_hint, "modulate:a", 0.0, 0.15)


func _show_hint() -> void:
	if current_page >= pages.size() - 1:
		return
	var t := create_tween()
	t.tween_property(click_hint, "modulate:a", 0.5, 0.3)
