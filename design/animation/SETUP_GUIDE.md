# 开场动画 — Godot 场景搭建与集成指南

> **关联文档**：
> - `opening_cinematic_design.md` — 完整设计文档
> - `提示词.md` — 所有美术资源的 AI 提示词
> - `../../scripts/cinematic/opening_cinematic.gd` — 控制脚本
> - `../../scenes/cinematic/opening_cinematic.tscn` — 场景文件

---

## 一、文件清单（哪些是我已经写好的）

| 文件 | 状态 | 说明 |
|------|------|------|
| `opening_cinematic.gd` | ✅ **已完成** | 完整控制脚本——含方案B双阶段碎裂回调、跳过、过渡 |
| `opening_cinematic.tscn` | ✅ **结构已建** | 完整节点树（含 StarGridOverlay + TearOverlay） |
| `star_grid_overlay.gd` | ✅ **已完成** | 轻量网格覆盖层——复用 star_map 的 ROW_POINTS，`_draw()` 绘制分隔线+遮罩+0001高亮 |
| 纹理赋值 | ⚠️ **等待图片** | .tscn 中纹理引用目前是空注释——拿到图后拖入即可 |
| AnimationPlayer 关键帧 | ⚠️ **等待音频** | 14 个回调时间戳已预设，拿到旁白音频后微调 |
| 旁白音频 | ❌ **尚未生成** | 需用 AI TTS 生成 |

---

## 二、你需要给我的（按顺序）

### 第一批：核心图片（P0）

```
放到：assets/papercraft/cinematic/

opening_panorama_wanxiang.png    ← 万象全景（3840×2160）
opening_logo_tianshu.png         ← 天枢 logo（512×512）
opening_tear_overlay.png         ← 纸板撕裂裂缝——简化版（3840×2160，透明背景，3-5条不规则裂缝线）
                                  │ 只显示 3 秒(17-20s)，随后被 StarGridOverlay 网格接管
                                  │ 如果 AI 生成不理想 → PS 中用撕纸笔刷手绘
```

### 第二批：叙事锚点图片（P1）

```
opening_coffee_hand.png          ← 手握咖啡杯（512×512）
opening_child_swing.png          ← 小孩秋千（512×512）
opening_old_hands.png            ← 老人手部（512×512）
opening_laogu_silhouette.png     ← 老顾剪影（256×384）
opening_folder_bg.png            ← 档案夹背景（1920×1080）
opening_folder_stamp.png         ← 红色印章（300×150）
```

### 第三批：氛围图片（P2——可选）

```
opening_clouds.png               ← 手撕纸云层（1920×400）
opening_dark_bg.png              ← 深色纸板背景（1920×1080）
```

### 旁白音频

```
opening_narration.ogg            ← 公司AI女声旁白（约55秒）
opening_ambient.ogg              ← 环境音（可选——纸质摩擦 + 低频地鸣）
```

---

## 三、你跑完图之后的操作步骤

### 步骤 1：导入图片

把所有生成的 PNG 拖入 Godot 的 `assets/papercraft/cinematic/` 目录。

Godot 会自动导入为 Texture2D，并分配 uid。

### 步骤 2：打开场景

在 Godot 编辑器中打开 `scenes/cinematic/opening_cinematic.tscn`。

你应该能看到完整的节点树。

### 步骤 3：给 TextureRect 赋值纹理

每个 TextureRect 节点的 Inspector 面板中有一个 `Texture` 属性——把对应的 PNG 从 FileSystem 面板拖入即可：

| 节点路径 | 拖入的图片 |
|---------|----------|
| `BG_Layer/DarkBG` | → 改为 TextureRect，赋值 `opening_dark_bg.png` |
| `BG_Layer/Sky` | `opening_clouds.png` |
| `World_Layer/Panorama` | `opening_panorama_wanxiang.png` |
| `World_Layer/TearOverlay` | `opening_tear_overlay.png`（简化裂缝版） |
| `World_Layer/StarGridOverlay` | ⚠️ **不需要图片**——由 `star_grid_overlay.gd` 的 `_draw()` 在运行时绘制网格 |
| `Detail_Layer/LaoguSilhouette` | `opening_laogu_silhouette.png` |
| `Flash_Layer/Flash_CoffeeHand` | `opening_coffee_hand.png` |
| `Flash_Layer/Flash_ChildSwing` | `opening_child_swing.png` |
| `Flash_Layer/Flash_OldHands` | `opening_old_hands.png` |
| `Briefing_Layer/FolderBG` | `opening_folder_bg.png` |
| `Briefing_Layer/FolderStamp` | `opening_folder_stamp.png` |
| `UI_Layer/Logo` | `opening_logo_tianshu.png` |
| `UI_Layer/StarmapBG` | `star_map_background.png`（已存在于 `assets/ui/`） |

### 步骤 4：调整全景的尺寸和位置

`opening_panorama_wanxiang.png` 是 3840×2160 的大图。在 Godot 中：
- 将 Panorama 节点的 `offset_left` 设为 `-1920`，`offset_right` 设为 `1920`
- 将 `offset_top` 设为 `-1080`，`offset_bottom` 设为 `1080`
- 这样全景图以屏幕中心 (640, 360) 为锚点居中显示
- 摄像机初始 zoom=(1,1) 时，玩家看到的是全景的中央 1280×720 区域

### 步骤 5：导入并设置旁白音频

将 `opening_narration.ogg` 拖入 `NarrationAudio` 节点的 `Stream` 属性。

播放一下确认：
- 音频能正常播放
- 时长约 55 秒
- 音量合适

### 步骤 6：调 AnimationPlayer 关键帧（最重要的一步）

打开底部的 **Animation** 面板，选择 `full_timeline` 动画。

你将看到两个轨道：
1. **Camera2D:position** — 摄像机位置（12 个关键帧）
2. **Camera2D:zoom** — 摄像机缩放（3 个关键帧）

以及底部的 **call_method** 轨道（14 个回调时间戳）。

**你需要根据旁白音频的实际时间线，调整每个关键帧的时间戳**：

| 回调函数 | 预设时间 | 画面 | 对应的旁白台词 |
|---------|---------|------|-------------|
| `_on_scene_01_identity` | **0s** | 身份确认 | "编号 TP-2077-03-溯光者。身份确认。" |
| `_on_scene_02_panorama` | **3s** | 万象全景 | "万象——人类迄今最大规模的数字现实平台..." |
| `_on_scene_03_individual_flash` | **15s** | 个体画面 | "2077年3月15日。凌晨3点15分。" |
| `_on_scene_04_shatter` | **~17s** | 碎裂：裂缝出现 | "核心AI——织女·太一——出现未知异常..." |
| `_on_scene_04_grid_transition` | **~20s** | 碎裂：裂缝→网格 | 旁白继续中——裂缝淡出，网格接管 |
| `_on_scene_05_shard_detail` | **~25s** | 碎片特写 | "您已被选定为溯光者。任务如下——" |
| `_on_scene_06_briefing` | **~30s** | 任务简报 | "进入碎片——找到源印——净化世界——修复万象——" |
| `_on_scene_07_warning` | **~40s** | 警告页 | "注意——碎片内的一切均不真实..." |
| `_on_scene_08_laogu_flash` | **~45s** | 老顾闪现 | "请勿过度共情其中的居民——" |
| `_on_scene_09_logo` | **~46s** | logo淡入 | （无声） |
| `_on_scene_09_hades_flash` | **~48s** | 冥府协议闪现 | （无声） |
| `_on_scene_10_starmap` | **~52s** | 星图过渡 | （无声） |
| `_on_cinematic_end` | **~55s** | 过渡到游戏 | （无声） |

**调整方法**：
1. 播放 AnimationPlayer 同时听旁白音频
2. 拖动关键帧时间戳，使画面切换和旁白台词精确同步
3. "请勿过度共情其中的居民"这句话和老顾闪现必须在同一瞬间

### 步骤 7：补全摄像机动画（在 Godot 编辑器中做）

当前 .tscn 中的 Camera2D 关键帧都是 `(640, 360)` 占位值。你需要：

**画面 2（3s→15s）**：摄像机从高空缓慢下移
- 在 3s 处：`position = (640, 200)`（俯视）
- 在 15s 处：`position = (640, 360)`（中景）
- 缓动：EaseInOut
- 可选：在 position.x 上增加 ±30px 的微旋转偏移

**画面 4（方案B——双阶段）**：
- 17s→20s：裂缝阶段。摄像机静止，TearOverlay 淡入
- 20s→25s：网格接管。摄像机缓慢后拉（position.y 从 360 到 500），看到网格全貌
- 缓动：EaseOut

**画面 5（25s→30s）**：推近 0001 网格单元
- 在 25s 处：`zoom = (1.0, 1.0)`
- 在 30s 处：`zoom = (0.5, 0.5)`（放大 2x）
- 同时 `position` 移到 0001 网格单元所在位置

**画面 7（40s）**：印章砸下的震屏
- 在 40s 处：`position = (640, 360)`
- 在 40.2s 处：`position = (640, 355)`（快速下移 5px）
- 在 40.5s 处：`position = (640, 360)`（弹回）

**画面 10（52s→55s）**：星图推入
- 在 52s 处：`zoom = (1, 1)`
- 在 55s 处：`zoom = (0.3, 0.3)`（放大进入星图）
- 最后一帧的 zoom 和 position 应该和实际星图场景的初始视角一致

### 步骤 8：补全纸片层动画

在 AnimationPlayer 中为以下节点添加 modulate/position/rotation 轨道：

**个体画面闪现（Flash_Layer 的三个节点）**：
- 画面 3（15s→17s）：
  - 15.0s：`Flash_CoffeeHand.modulate.a = 1.0`
  - 15.5s：`Flash_CoffeeHand.modulate.a = 0.0`
  - 15.5s：`Flash_ChildSwing.modulate.a = 1.0`（黑屏帧之后）
  - 16.0s：`Flash_ChildSwing.modulate.a = 0.0`
  - 16.0s：`Flash_OldHands.modulate.a = 1.0`
  - 16.5s：`Flash_OldHands.modulate.a = 0.0`

**方案B——撕裂→网格双阶段动画（17s→25s）**：

阶段1：裂缝（17s→20s）
- 17s：`TearOverlay.modulate.a = 0.0 → 1.0`（不规则裂缝出现）
- 持续 3 秒——裂缝稳定显示在画面上
- 20s：`TearOverlay.modulate.a = 1.0 → 0.0`（裂缝开始淡出）

阶段2：网格接管（20s→25s）——通过 StarGridOverlay 的 setter 方法
- 在 AnimationPlayer 中为 `World_Layer/StarGridOverlay` 添加轨道：
  ```
  20s→22s: StarGridOverlay.set_darken_alpha(0.0 → 0.38)  ← 各单元变暗
  22s→24s: StarGridOverlay.set_grid_alpha(0.0 → 1.0)      ← 网格线显现
  24s→25s: StarGridOverlay.set_highlight_alpha(0.0 → 1.0)  ← 0001高亮
  ```
- 22s→25s：同时对 Panorama 做 `modulate` 微暗（Color 1,1,1 → 0.85,0.85,0.85）
- 结果：画面5时 = 暗底 + 金色网格线 + 0001区域金色高亮边框——和 star_map.tscn 完全一致

**logo 淡入（46s）**：
- 46s→48s：`Logo.modulate.a = 0.0 → 1.0`，同时 scale 从 0.9→1.0

**冥府协议闪现→缩小→隐匿（48s→52s）**：
- 48.0s：`HadesText.modulate.a = 0.0 → 1.0`，`position = (640, 468)`（画面中央）
- 48.3s：开始缩小动画——`HadesText` 的 position 移动到右下角 `(1100, 680)`
- 48.3s→49.0s：`HadesText.modulate.a = 1.0 → 0.25`，`scale = (1,1) → (0.3, 0.3)`
- 49.0s→52s：保持在右下角极小的灰色文字状态

**画面10：网格→星图过渡（52s→55s）**：
- 52s：`StarmapBG.modulate.a = 0.0 → 1.0`（星图背景淡入）
- 52s→55s：StarGridOverlay 的所有 alpha 参数 → 0（网格淡出，星图接管）
- 52s→55s：Panorama `modulate.a = 1.0 → 0.0`（全景缓缓隐去）
- 因为 StarGridOverlay 和 star_map.tscn 使用完全相同的 ROW_POINTS 数据，过渡时网格线位置像素级不变——只有背景从"全景"变成了"星图"

### 步骤 9：测试运行

按 F6 运行当前场景：
1. 确认所有画面按顺序切换
2. 确认旁白和画面同步
3. 测试跳过功能（按任意键 → 应该直接淡出到 title_screen）
4. 确认过渡到 `title_screen.tscn` 正常

---

## 四、如何让开场动画成为游戏启动的首个场景

当前 `project.godot` 中 `run/main_scene` 指向 `title_screen.tscn`。

**方案 A（推荐——开发期）**：手动切换
- 开发时先在 Godot 编辑器中把 `opening_cinematic.tscn` 设为主场景
- 动画播放完后自动跳转到 `title_screen.tscn`

**方案 B（发布时）**：在 title_screen 中加入逻辑
- 在 `title_screen.gd` 的 `_ready()` 中判断是否首次启动
- 如果是首次启动 → 先加载 `opening_cinematic.tscn` 作为覆盖层
- 动画结束后 → 回到 title_screen

**当前采用的方案 A**：
```
project.godot:
  run/main_scene="res://scenes/cinematic/opening_cinematic.tscn"
```

动画结束后自动调用 `SceneManager.change_scene("res://scenes/ui/title_screen.tscn", "")`，利用已有的 SceneFader 做黑屏过渡。

---

## 五、旁白音频生成参数

使用 AI TTS 生成，参数如下：

```
语言：中文（标准普通话）
音色：女性，中性偏冷
  - 不要温暖、不要甜美、不要"助手音"
  - 参考：Siri（早期冷感版本）或 Alexa（但更少情感波动）
语速：1.1x 正常对话速度
音高稳定性：极高（不要自然的音高起伏——AI在念稿，不是在说话）
断句：严格按标点（不要做语义自然停顿——这是区分"AI在读"和"人在说"的关键）
唯一例外：画面7的"注意"——这个字比其他词重约15%（这是唯一的情感破绽）

如果做了英文版：保持同样的 AI 参数，但语言改为英文。
音色参数（温度/稳定性）应该在所有语言版本中保持完全相同。
```

---

## 六、FAQ

**Q：AnimationPlayer 的关键帧怎么精确和旁白对齐？**
A：在 Godot 编辑器中：
1. 选中 AnimationPlayer，打开 Animation 面板
2. 选中 `full_timeline` 动画
3. 点击播放——同时你会听到旁白音频
4. 拖动关键帧在时间轴上的位置，直到画面切换点和旁白台词对齐
5. 关键帧的"transitions"值设为 1（线性）或 2（EaseIn）或 3（EaseOut）或 4（EaseInOut）

**Q：全景图太大（3840×2160），Godot 能不能处理？**
A：可以。Godot 的 TextureRect 支持任意尺寸。3840×2160 的 PNG 约 8-15MB。如果性能有问题——在导入设置中勾选 `Mipmaps` 降低远处细节的锯齿，但不影响显示质量。

**Q：12 片碎片要分别做动画，工作量是不是很大？**
A：对，12 片分别做。每片需要 3-4 个关键帧（初始位置 + 分离方向 + 微旋转）。可以用脚本来做——在 Godot 编辑器中选中所有 12 个 Shard 节点，用 `Alt+R` 在 AnimationPlayer 中同时插入关键帧。

**Q：如果某张图片一直没跑出来怎么办？**
A：每个 TextureRect 节点在 Inspector 中有 `modulate` 属性。把还没到的节点的 `modulate.a` 设为 0 即可——它们不会显示出来。等图到了再拖入赋值。

---

*此指南在拿到全部图片 + 旁白音频后，按步骤 1→9 执行即可完成开场动画的 Godot 集成。预计操作时间：1-2 小时。*
