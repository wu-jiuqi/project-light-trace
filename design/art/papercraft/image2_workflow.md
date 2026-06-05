# Image2 纸工资产生产流程

## 1. 原则

Image2 输出默认进入候选池，不直接视为正式资产。目标是尽量少修整，但每张图仍须通过透明背景、轮廓、材质、尺度和缩小可读性检查。

当前生产范围只包含人物立绘：单张完整角色、透明背景、白色 / 米白立牌描边、脚底锚点居中。暂不生产 walk、talk、方向变体、独立阴影、道具、FX、UI、环境模块或星图碎片。

优先使用交互式多轮编辑锁定风格。只有黄金参考组稳定后，才考虑 API 批量生成。

## 2. 单张资产流程

1. 从 `assets/papercraft/manifests/*.json` 选择一个 `category: "character"` 的人物立绘条目。
2. 选择最接近的黄金参考图。
3. 使用固定模板生成候选。
4. 将候选放入工作区，不要直接标记为 `ready`。
5. 使用 `qa_checklist.md` 检查。
6. 对局部问题进行参考图编辑，不要重新从纯文本生成。
7. 通过检查后复制到清单中的正式路径，并将状态更新为 `ready`。
8. 运行 `npm run validate:papercraft`。

## 3. Prompt 结构

所有 Prompt 使用以下顺序：

```text
[资产类型]
[固定纸工风格]
[镜头和方向]
[主体描述]
[必须保留的视觉锚点]
[透明背景和导出要求]
[禁止项]
```

### 3.1 人物立绘模板

```text
single full-body character portrait, hand-cut paper puppet for a top-down 2D RPG,
layered cardstock, visible paper fibers, irregular scissor-cut edges,
subtle cardboard thickness, restrained warm-gray cast shadow,
single top-left light source,
[character description],
front-facing or slightly top-down standing portrait,
feet aligned to the bottom-center anchor,
isolated on transparent background,
no scene, no text, no extra characters,
no smooth vector edges, no plastic toy look, no photorealistic 3D render
```

### 3.2 角色姿态编辑模板

当前阶段暂缓。不要生产 `walk`、`talk`、方向变体、独立阴影或剧情姿态图。以下模板仅作为后续恢复姿态资产时的存档。

```text
Preserve the exact character identity, paper materials, proportions,
camera angle, colors, asymmetrical details and bottom-center foot anchor.
Change only the pose to [happy / sad / panic / awakened / talk].
Keep the same transparent canvas size and transparent background.
Do not add a scene, text, props or extra characters.
```

### 3.3 环境模块模板

当前阶段暂缓。人物立绘完成并验收前，不生产环境模块。

```text
modular hand-cut papercraft environment asset for a top-down 2D RPG,
layered cardstock, irregular scissor-cut edges, visible paper fibers,
single top-left light source, restrained right-bottom paper shadow,
[asset description],
designed to connect cleanly to a 16px logical grid rendered at 4x scale,
isolated on transparent background,
no full scene, no characters, no text, no watermark,
no smooth vector edges, no plastic miniature look
```

### 3.4 UI 组件模板

当前阶段暂缓。人物立绘完成并验收前，不生产 UI 组件。

```text
papercraft UI component for a 2D RPG, based on the frozen registration-ledger UI direction,
old guest-book pages, book spine hinges, folded page corners, brass rivets, paper tabs,
hand-cut layered cardstock, readable low-texture empty center,
single top-left light source, restrained right-bottom shadow,
[button / dialogue frame / backpack notebook slot / ledger card slot description],
isolated on transparent background,
no words, no letters, no symbols, no watermark,
clear silhouette and strong state readability at small size,
do not include star-map-specific motifs unless producing the later ref_star_map asset
```

### 3.5 异常拼贴模板

当前阶段暂缓。人物立绘完成并验收前，不生产异常拼贴演出。

```text
surreal mixed-media papercraft collage for a 2D RPG awakening sequence,
torn book pages, tracing paper, thread, tape, stamped fragments,
impossible perspective, restrained unsettling repetition,
[event description],
preserve a clear focal point and an empty subtitle-safe area,
no readable generated text, no watermark, no photorealistic gore
```

`ref_awakening_collage` 方向的进入世界 / 觉醒过场使用更具体的叙事模板：

```text
wide 16:9 surreal hand-cut papercraft cutscene for a 2D RPG,
front-facing or slightly elevated paper theater / pop-up book view of the #0762 small town,
about 65% gray lifeless desaturated town invading about 35% colorful living town,
gray invasion edge made from jagged torn paper, ash ink, gray card fragments and soft tracing-paper fog,
include readable town anchors: gray-eaves guest-ledger inn, stone street, central drainage channel, plaza white statue,
color must live on concrete objects: red roof tiles, blue sky and white clouds, green plants, warm yellow bakery light, purple music-note scraps,
preserve a bottom 18% low-contrast subtitle-safe paper band,
strange and theatrical, but the meaning must remain clear: gray oblivion is swallowing a living colorful town,
no readable generated text, no logos, no watermark, no franchise elements
```

### 3.6 星图母图模板

当前阶段暂缓。人物立绘完成并验收前，不生产星图母图或星图碎片。

星图碎片不得直接通过文本生成散落状态。必须先生成完整母图，再本地切割。

```text
one complete unbroken four-point compass star silhouette for a 2D RPG star map,
made from shimmering papercraft cardstock,
dark cardboard backing, tracing-paper star haze, tiny silver pinpoints,
visible paper fibers, irregular scissor-cut outer edge,
single top-left light source, restrained lower-right paper shadow,
[material direction],
intact single four-point star only,
no cracks, no fragments, no seam lines,
no readable text, no letters, no numbers, no symbols, no watermark,
no characters, no franchise elements, no smooth vector edges,
no glossy plastic, no photorealistic 3D render
```

母图冻结后，后续星图碎片使用本地 mask 或编辑工具从母图切出 12 块。相邻碎片必须共享同一条切线，确保可以回拼成完整四芒星。

## 4. 黄金参考组生成

按以下顺序生成：

1. `ref_material_board`：先锁定材质，不包含角色或建筑。
2. `ref_character_standard`：已冻结为 Round 03 v04 的植物接待员式异常整片纸偶。后续角色优先从该图继承粗白立牌描边、深蓝紫大形、铃铛花眼睛、线绳钥匙和空白登记簿等语言；若制作普通居民，可降低非人体强度，但不要回到写实人体插画。
3. `ref_inn_facade`：已冻结为 Round 01 v02 的登记簿旅店。后续建筑优先从该图继承“场所身份锚点转化为建筑结构”的语言：旧书页、书脊、折页、装订带、门窗屋檐和纸层阴影共同构成可玩的建筑立面。制作其他建筑时可以替换身份锚点，但必须保留入口、窗、屋檐、层级、拼装边界和缩小后的剪影可读性。
4. `ref_street_modules`：已冻结为 Round 01 v02 的灰卡碎石道路模块。后续道路、石板和人行道资产优先继承该图的 5 tile 宽街道逻辑、左右 2 tile 抬高人行道、中心 1 tile 深色排水暗沟、直线/边缘/转角/T 字接口、灰白卡纸碎石密度和克制的固定件。
5. `ref_ui_components`：已冻结为 Round 01 上排 04 的登记簿旅店 / 书脊装订方向。本参考只锁定按钮、对话框、背包剪贴簿和卡槽模块：旧住客登记簿展开页、书脊装订、折角纸页、铜钉、浅网格卡槽和空白票据。星图界面不由本参考冻结。
6. `ref_star_map`：已冻结为 Round 02 base v02 的完整描图纸 / 烟灰银点四芒星母图。后续星图碎片必须从该母图本地切割为 12 块，确保碎片能合理拼回同一个四芒星；不得直接生成散落碎片作为正式拼合依据。
7. `ref_awakening_collage`：已冻结为 fresh 20260604 v03。后续演出模块优先继承“完整小镇先可读，再被灰白遗忘侵蚀”的逻辑；彩色必须落在具体物件上，底部保留字幕安全区，异常拼贴服务叙事而不是单独炫技。

黄金参考图一旦冻结：

- 保存原始 Prompt。
- 保存选用的参考图路径。
- 记录允许变化项与禁止变化项。
- 后续资产使用参考图编辑，不重新探索整体风格。

## 5. 常见失败与修复

| 问题 | 拒收原因 | 修复方式 |
|---|---|---|
| 背景不透明或带灰边 | 无法安全叠加 | 明确要求透明背景并重新编辑 |
| 纸片变成塑料模型 | 偏离材质族 | 强调 cardstock、paper fibers、scissor-cut edges |
| 角色左右镜像 | 非对称锚点错误 | 单独生成左右方向并显式描述锚点位置 |
| 建筑生成完整街景 | 不能复用 | 重申 modular、isolated asset、no full scene |
| 出现伪文字 | UI 和线索不可控 | 要求 no words、no letters；文字由 Godot 渲染 |
| 纹理过密 | 缩小后噪声过大 | 降低纤维和撕边强度，重新检查缩略图 |
| 拼贴演出压住字幕 | 影响叙事 | 明确 bottom 18% subtitle-safe area、低对比纸纹和清晰 focal point |
| 彩色变成抽象色块 | 无法传达“颜色回到世界物件” | 指定红瓦、蓝天白云、绿色植物、黄色炉光、紫色音符等具体承载物 |
| 异常拼贴喧宾夺主 | 玩家读不出事件逻辑 | 先描述正常小镇，再描述灰白侵蚀的方向、比例和边界 |

## 6. Image2 能力边界

适合交给 Image2：

- 人物立绘候选。
- 人物立绘的局部参考图编辑。
- 必要时用于人物立绘风格锁定的参考探索。

仍需人工或脚本处理：

- 精确切图、锚点和画布统一。
- 透明边缘检查。
- 缩略可读性审查。
- Godot 导入。
