# 开场动画漫画版 — Godot 节点创建指南

> **关联文档**：`comic_panel_prompts.md`（13格分镜提示词）、`comic_layout_preview.html`（布局色块图）
> **前提**：13张漫画格已用 ImageGen 生成，保存至 `assets/cutscenes/opening/`

---

## 一、总体思路：从 Node2D 改为 Control

当前 `opening_cinematic.tscn` 是一个空 `Node2D`。漫画分格本质是 **UI 排版**（格子位置/大小/顺序），不是 2D 世界坐标。用 `Control` 根节点更适合。

```
漫画实现 = 6个翻页（每页 = 1 个 Control 容器, 内部若干 TextureRect 格子）
         + 旁白叠加层（Label）
         + 翻页控制器脚本
```

---

## 二、场景树结构（完整）

```
OpeningCinematic (Control)                          ← 根节点（改类型）
├── PageContainer (Control)                         ← 当前可见页容器
│   ├── Page1_Wanxiang (Control)                    ← 第1页
│   │   ├── Panel_01 (TextureRect)                  ← 格1 身份确认
│   │   ├── Panel_02 (TextureRect)                  ← 格2 万象全景
│   │   └── Narration (Label)                       ← 旁白文字（可选，见第五节）
│   │
│   ├── Page2_Lives (Control)
│   │   ├── Panel_03 (TextureRect)                  ← 格3 咖啡手
│   │   ├── Panel_04 (TextureRect)                  ← 格4 秋千
│   │   ├── Panel_05 (TextureRect)                  ← 格5 老人手
│   │   └── Narration (Label)
│   │
│   ├── Page3_Shatter (Control)
│   │   ├── Panel_06 (TextureRect)                  ← 格6 碎裂
│   │   └── Panel_07 (TextureRect)                  ← 格7 碎片分离
│   │
│   ├── Page4_Mission (Control)
│   │   ├── Panel_08 (TextureRect)                  ← 格8 0001高亮
│   │   ├── Panel_09 (TextureRect)                  ← 格9 档案夹
│   │   └── Narration (Label)
│   │
│   ├── Page5_Warning (Control)
│   │   ├── Panel_10 (TextureRect)                  ← 格10 红色印章
│   │   └── Panel_11 (TextureRect)                  ← 格11 老顾闪现
│   │
│   └── Page6_Lies (Control)
│       ├── Panel_12 (TextureRect)                  ← 格12 Logo+冥府
│       └── Panel_13 (TextureRect)                  ← 格13 星图过渡
│
├── NarrationOverlay (Control)                      ← 全局旁白叠加层（方案B）
│   └── NarrationLabel (Label)
│
└── ClickCatcher (ColorRect)                        ← 全屏透明，捕获点击翻页
```

**为什么不用 6 个独立场景**：6 页之间的视觉连续性很重要（第1页全景→第3页同一全景碎裂），放在一个场景里可以复用同一个 `SceneFader` 过渡，保持页间切换的流畅感。

---

## 三、逐节点创建步骤（在 Godot 编辑器中操作）

### 步骤 1：改根节点类型

1. 右键 `OpeningCinematic` 节点 → **Change Type** → 搜索 `Control`
2. 在 Inspector 中设置：
   - `Layout` → **Full Rect**（铺满整个屏幕）
   - `Anchors Preset` → **Full Rect**（让所有子节点用锚点定位）

### 步骤 2：创建 PageContainer

1. 右键 `OpeningCinematic` → **Add Child Node** → `Control`
2. 命名为 `PageContainer`
3. Layout → Full Rect

> 这个节点是"当前页"的容器。翻页时用代码将旧页移出、新页移入。

### 步骤 3：创建第1页（示例——其他5页同理）

1. 右键 `PageContainer` → Add Child → `Control`
2. 命名为 `Page1_Wanxiang`
3. Layout → Full Rect
4. 右键 `Page1_Wanxiang` → Add Child → `TextureRect`
5. 命名为 `Panel_01`
6. 在 Inspector 中设置 Panel_01：
   ```
   Layout → 选 Anchors Preset → Custom
   anchor_left = 0.02
   anchor_top = 0.05
   anchor_right = 0.20
   anchor_bottom = 0.95
   offset 全为 0
   expand_mode = FitWidthProportionally（如果图片比例和格子比例不完全一致）
   stretch_mode = KeepAspectCovered
   ```

7. 右键 `Page1_Wanxiang` → Add Child → `TextureRect`
8. 命名为 `Panel_02`
9. 设置 Panel_02：
   ```
   anchor_left = 0.22
   anchor_top = 0.05
   anchor_right = 0.98
   anchor_bottom = 0.95
   ```

> **锚点定位原则**：每个格的 anchor 值对应 `comic_layout_preview.html` 中的格比例。第1页格1占左15%，anchor_right=0.20（留2%边距）；格2占右78%，anchor_left=0.22。

### 步骤 4：为每个格挂载纹理

在脚本中动态加载（推荐）或在编辑器中手动拖入：

**脚本方式**（`_ready()` 中）：
```gdscript
$PageContainer/Page1_Wanxiang/Panel_01.texture = load("res://assets/cutscenes/opening/comic_panel_01_identity.png")
$PageContainer/Page1_Wanxiang/Panel_02.texture = load("res://assets/cutscenes/opening/comic_panel_02_panorama.png")
```

---

## 四、各页格子锚点参数速查表

所有值基于 `comic_layout_preview.html` 的布局比例换算。

```
┌───────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│  页   │   格     │ anchor_L │ anchor_T │ anchor_R │ anchor_B │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│       │ Panel_01 │   0.03   │   0.04   │   0.18   │   0.96   │
│  1    │ Panel_02 │   0.21   │   0.04   │   0.97   │   0.96   │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│       │ Panel_03 │   0.04   │   0.20   │   0.33   │   0.80   │
│  2    │ Panel_04 │   0.35   │   0.20   │   0.64   │   0.80   │
│       │ Panel_05 │   0.66   │   0.20   │   0.95   │   0.80   │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│  3    │ Panel_06 │   0.03   │   0.04   │   0.97   │   0.55   │
│       │ Panel_07 │   0.10   │   0.60   │   0.90   │   0.96   │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│  4    │ Panel_08 │   0.04   │   0.08   │   0.35   │   0.92   │
│       │ Panel_09 │   0.38   │   0.04   │   0.96   │   0.96   │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│  5    │ Panel_10 │   0.03   │   0.04   │   0.97   │   0.58   │
│       │ Panel_11 │   0.72   │   0.64   │   0.96   │   0.96   │
├───────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│  6    │ Panel_12 │   0.04   │   0.08   │   0.35   │   0.92   │
│       │ Panel_13 │   0.38   │   0.04   │   0.96   │   0.96   │
└───────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

> **注意**：格11（老顾闪现）占页面右下角约 24% 宽 × 32% 高 —— 是全场最小的可见区域。

---

## 五、旁白文字叠加（两种方案）

### 方案A：每页独立旁白（推荐首版）

每个 Page Control 下挂一个 `Label`，和该页格子绑定：

1. 右键 `Page1_Wanxiang` → Add Child → `Label`
2. 命名为 `Narration`
3. 设置锚点（建议放在页面上方或格子间隙中）
4. 在 Theme Overrides 中设置字体大小和颜色

```
Page1 → Narration 放在页面底部中央
  anchor_L=0.10  anchor_T=0.85  anchor_R=0.90  anchor_B=0.96
  text = "编号 TP-2077-03-溯光者。身份确认。"
```

优点：旁白和格子一起淡入淡出，切换页面时自然更换。

### 方案B：全局旁白叠加层

在根节点下创建一个独立 Layer，翻页时只换文字：

1. 右键 `OpeningCinematic` → Add Child → `Control` → 命名 `NarrationOverlay`
2. Layout → Full Rect（始终覆盖在所有页面上方）
3. 右键 `NarrationOverlay` → Add Child → `Label` → 命名 `NarrationLabel`
4. 锚点居中偏下

优点：旁白位置固定，切换页面时不会跳动。

---

## 六、全屏点击捕捉

1. 右键 `OpeningCinematic` → Add Child → `ColorRect` → 命名 `ClickCatcher`
2. 设置：
   ```
   Layout → Full Rect
   Color → #00000000（完全透明）
   Mouse → Filter → Ignore（如果只是键盘翻页）或 Stop（如果点击翻页）
   ```
3. 在根脚本中连接 `gui_input` 信号实现点击翻页

---

## 七、脚本逻辑（核心骨架）

创建 `scripts/cinematic/opening_cinematic.gd`，挂载到根 `OpeningCinematic` Control 上：

```gdscript
extends Control

# ============================================
# 开场动画漫画版 — 页控制器
# ============================================

## 当前页索引（0-5）
var current_page: int = 0

## 所有页面节点引用
var pages: Array[Control] = []

## 是否正在翻页动画中
var is_transitioning: bool = false


func _ready() -> void:
	# 收集所有 Page*_* 子节点
	_gather_pages()
	# 加载所有格子的纹理
	_load_all_textures()
	# 显示第 1 页，隐藏其余
	_show_page(0)


func _gather_pages() -> void:
	var container = $PageContainer
	for child in container.get_children():
		if child is Control and child.name.begins_with("Page"):
			pages.append(child)
	pages.sort_custom(func(a, b): return a.name < b.name)


func _load_all_textures() -> void:
	# 第1页
	$PageContainer/Page1_Wanxiang/Panel_01.texture = \
		load("res://assets/cutscenes/opening/comic_panel_01_identity.png")
	$PageContainer/Page1_Wanxiang/Panel_02.texture = \
		load("res://assets/cutscenes/opening/comic_panel_02_panorama.png")
	# ... 其余 11 格同理


func _show_page(idx: int) -> void:
	for i in pages.size():
		pages[i].visible = (i == idx)
	current_page = idx


func _input(event: InputEvent) -> void:
	if is_transitioning:
		return

	# 任意键或鼠标点击 → 翻到下一页
	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_next_page()


func _next_page() -> void:
	if current_page >= pages.size() - 1:
		# 最后一页 → 过渡到星图
		_go_to_star_map()
		return

	is_transitioning = true

	# 翻页动画：当前页淡出，新页淡入
	var old_page = pages[current_page]
	var new_page = pages[current_page + 1]

	new_page.modulate.a = 0.0
	new_page.visible = true

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_page, "modulate:a", 0.0, 0.4)
	tween.tween_property(new_page, "modulate:a", 1.0, 0.4)
	tween.chain().tween_callback(func():
		old_page.visible = false
		old_page.modulate.a = 1.0
		current_page += 1
		is_transitioning = false
	)


func _go_to_star_map() -> void:
	# 使用项目已有的 SceneFader 过渡到星图
	SceneFader.change_scene("res://scenes/world/star_map.tscn")
```

---

## 八、翻页过渡效果选项

上面用的是简单的淡入淡出。如果需要更漫画感的翻页，可以用以下替代方案：

### 选项1：滑动翻页（新页从右滑入）

```gdscript
# 新页初始位置在屏幕右侧外
new_page.position.x = get_viewport_rect().size.x
new_page.visible = true

var tween = create_tween()
tween.set_parallel(true)
tween.tween_property(old_page, "position:x", -get_viewport_rect().size.x, 0.3)
tween.tween_property(new_page, "position:x", 0.0, 0.3)
```

### 选项2：缩放翻页（新页从中心放大）

```gdscript
new_page.scale = Vector2(0.8, 0.8)
new_page.modulate.a = 0.0
new_page.visible = true

var tween = create_tween()
tween.set_parallel(true)
tween.tween_property(old_page, "scale", Vector2(1.1, 1.1), 0.25)
tween.tween_property(old_page, "modulate:a", 0.0, 0.25)
tween.tween_property(new_page, "scale", Vector2(1.0, 1.0), 0.3)
tween.tween_property(new_page, "modulate:a", 1.0, 0.3)
```

### 选项3：分步展示（同一页内的格逐个出现）

第2页（三联画）可以三格逐个出现，而不是同时显示：

```gdscript
func _show_page_2_sequentially() -> void:
	# 隐藏三格
	p03.visible = false; p04.visible = false; p05.visible = false
	page2.visible = true

	# 格3 延迟0.3s后淡入
	await get_tree().create_timer(0.3).timeout
	p03.visible = true
	var t1 = create_tween()
	t1.tween_property(p03, "modulate:a", 1.0, 0.2).from(0.0)

	# 格4 再延迟0.4s
	await get_tree().create_timer(0.4).timeout
	p04.visible = true
	var t2 = create_tween()
	t2.tween_property(p04, "modulate:a", 1.0, 0.2).from(0.0)

	# 格5 再延迟0.4s
	await get_tree().create_timer(0.4).timeout
	p05.visible = true
	var t3 = create_tween()
	t3.tween_property(p05, "modulate:a", 1.0, 0.2).from(0.0)
```

---

## 九、项目入口连接

在 `project.godot` 中设置运行入口（如果还没设）：

```ini
[application]
run/main_scene="res://scenes/cinematic/opening_cinematic.tscn"
```

或者在 title_screen.tscn 的"新游戏"按钮中跳转：

```gdscript
# title_screen.gd — 新游戏按钮回调
func _on_new_game_pressed() -> void:
	SceneFader.change_scene("res://scenes/cinematic/opening_cinematic.tscn")
```

---

## 十、与现有 autoload 的集成点

| Autoload | 用途 |
|----------|------|
| `GameManager` | 动画结束后设置 `GameManager.current_scene = "star_map"` |
| `SceneFader` | 最后一页过渡到 `star_map.tscn` |
| `SaveManager` | 首次观看标记：`SaveManager.set_data("intro_watched", true)` — 下次跳过直接进星图 |

---

## 十一、改根节点类型的操作（Godot 编辑器）

如果当前场景是 `Node2D` 且已经有子节点，改 `Control` 后子节点会保留。当前场景是空的，直接改即可。

实际步骤：
1. 打开 `scenes/cinematic/opening_cinematic.tscn`
2. 选中 `OpeningCinematic` 节点
3. 在 Inspector 顶部可以看到节点类型 `Node2D`
4. 右键节点 → **Change Type** → 输入 `Control` → 选中 `Control`
5. 现在 Inspector 中会出现 `Layout` 和 `Anchors` 区域
6. 点击 `Layout` 旁边的下拉 → **Full Rect**（使 Control 铺满整个视口）

---

*此文件为漫画分格在 Godot 中的完整节点创建指南。应在 13 张漫画格素材生成前先将场景树搭建好并验证翻页逻辑。*
