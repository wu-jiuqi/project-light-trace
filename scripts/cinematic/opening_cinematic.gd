extends Control
class_name OpeningCinematic

## 开场动画漫画版 — 面板控制器
## 13个面板逐格推进。任意键/点击推进。全部面板结束后过渡到星图。

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

var panels: Array[TextureRect] = []
## 当前已显示的最新面板索引（-1 表示尚未显示任何面板）
var current_panel: int = -1
var is_transitioning: bool = false

# ============================================
# 面板动画参数
# ============================================

const PANEL_FADE_DURATION: float = 0.4
const PANEL_SCALE_START: float = 0.95
const PANEL_SCALE_END: float = 1.0

# ============================================
# 旁白文本（13段，按面板顺序）
# ============================================

const NARRATION: Array[String] = [
	"[center]编号 TP-2077-03-溯光者。身份确认。[/center]",
	"[center]这里是万象——人类迄今最大规模的数字现实平台。\n四十七亿人的记忆、情感与生活，被安全保存于此。[/center]",
	"[center]手握咖啡，平凡的一天。[/center]",
	"[center]孩子们在秋千上欢笑。[/center]",
	"[center]岁月在老人手中留下痕迹。[/center]",
	"[center]2077年3月15日。凌晨3点15分。\n纸板开始碎裂。裂缝在万象中蔓延。[/center]",
	"[center]万象——碎裂为十二个孤立碎片。\n四十七亿意识——陷入休眠。[/center]",
	"[center]碎片 0001。溯光者的第一个目标。[/center]",
	"[center]档案开启。任务简报已解锁。[/center]",
	"[center][color=#c04040]注意——[/color]\n碎片内的一切均不真实。[/center]",
	"[center][color=#c04040]请勿过度共情其中的居民。[/color][/center]",
	"[center]天枢公司通过冥府协议[/center]",
	"[center]星图展开。0001脉动。\n溯光者，你准备好了吗？[/center]",
]

# ============================================
# 生命周期
# ============================================

func _ready() -> void:
	# 开场动画期间禁止自动存档（此时游戏状态未完全初始化，存档校验和会失败）
	if SaveManager.get_current_slot() >= 0:
		SaveManager._stop_auto_save()
	_gather_panels()
	_show_first_panel()


func _gather_panels() -> void:
	## 按页面顺序收集所有 TextureRect 面板，初始全部隐藏
	# 先收集页面容器并按名称排序
	var pages_temp: Array[Control] = []
	for child in page_container.get_children():
		if child is Control and child.name.begins_with("Page"):
			pages_temp.append(child)
	pages_temp.sort_custom(func(a: Node, b: Node): return a.name.naturalnocasecmp_to(b.name) < 0)

	# 遍历每个页面，收集其下的 TextureRect 面板
	for page in pages_temp:
		page.visible = true  # 所有页面容器保持可见，以便面板积累显示
		for child in page.get_children():
			if child is TextureRect:
				child.visible = false
				child.modulate.a = 1.0
				child.scale = Vector2(PANEL_SCALE_END, PANEL_SCALE_END)
				panels.append(child)


# ============================================
# 面板展示
# ============================================

func _show_first_panel() -> void:
	## 显示第一个面板并播放入场动画
	is_transitioning = true
	_advance_to_panel(0)


func _advance_to_panel(idx: int) -> void:
	## 隐藏上一面板
	if current_panel >= 0 and current_panel < panels.size():
		panels[current_panel].visible = false
	## 将第 idx 个面板淡入 + 缩放入场
	var panel: TextureRect = panels[idx]
	panel.visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(PANEL_SCALE_START, PANEL_SCALE_START)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, PANEL_FADE_DURATION)
	tween.tween_property(panel, "scale", Vector2(PANEL_SCALE_END, PANEL_SCALE_END), PANEL_FADE_DURATION).set_ease(Tween.EASE_OUT)

	tween.chain().tween_callback(func() -> void:
		current_panel = idx
		_update_narration(idx)
		_update_page_indicator()
		is_transitioning = false
		_show_hint()
	)


func _update_narration(idx: int) -> void:
	if idx < NARRATION.size():
		narration_text.text = NARRATION[idx]
	else:
		narration_text.text = ""


func _update_page_indicator() -> void:
	page_indicator.text = "面板 %d / %d" % [current_panel + 1, panels.size()]


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
		_next_panel()


# ============================================
# 面板推进
# ============================================

func _next_panel() -> void:
	## 推进到下一个面板；若已是最后一个，则跳转星图
	if current_panel >= panels.size() - 1:
		_go_to_star_map()
		return

	is_transitioning = true
	_hide_hint()
	_advance_to_panel(current_panel + 1)


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
	if current_panel >= panels.size() - 1:
		return
	var t := create_tween()
	t.tween_property(click_hint, "modulate:a", 0.5, 0.3)
