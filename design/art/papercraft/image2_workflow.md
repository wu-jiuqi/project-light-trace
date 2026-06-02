# Image2 纸工资产生产流程

## 1. 原则

Image2 输出默认进入候选池，不直接视为正式资产。目标是尽量少修整，但每张图仍须通过透明背景、轮廓、材质、尺度和缩小可读性检查。

优先使用交互式多轮编辑锁定风格。只有黄金参考组稳定后，才考虑 API 批量生成。

## 2. 单张资产流程

1. 从 `assets/papercraft/manifests/*.json` 选择一个 `planned` 条目。
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

### 3.1 角色基础模板

```text
single full-body hand-cut paper puppet for a top-down 2D RPG,
layered cardstock, visible paper fibers, irregular scissor-cut edges,
subtle cardboard thickness, restrained warm-gray cast shadow,
single top-left light source,
[character description],
[direction] view, [pose] pose,
feet aligned to the bottom-center anchor,
isolated on transparent background,
no scene, no text, no extra characters,
no smooth vector edges, no plastic toy look, no photorealistic 3D render
```

### 3.2 角色姿态编辑模板

```text
Preserve the exact character identity, paper materials, proportions,
camera angle, colors, asymmetrical details and bottom-center foot anchor.
Change only the pose to [happy / sad / panic / awakened / talk].
Keep the same transparent canvas size and transparent background.
Do not add a scene, text, props or extra characters.
```

### 3.3 环境模块模板

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

```text
papercraft UI component for a 2D RPG,
hand-cut layered cardstock, subtle torn-paper edge, readable empty center,
single top-left light source, restrained right-bottom shadow,
[button / dialogue frame / notebook slot / paper shard description],
isolated on transparent background,
no words, no letters, no symbols, no watermark,
clear silhouette and strong state readability at small size
```

### 3.5 异常拼贴模板

```text
surreal mixed-media papercraft collage for a 2D RPG awakening sequence,
torn book pages, tracing paper, thread, tape, stamped fragments,
impossible perspective, restrained unsettling repetition,
[event description],
preserve a clear focal point and an empty subtitle-safe area,
no readable generated text, no watermark, no photorealistic gore
```

## 4. 黄金参考组生成

按以下顺序生成：

1. `ref_material_board`：先锁定材质，不包含角色或建筑。
2. `ref_character_standard`：建议使用冯婶，已有气氛板可作参考。
3. `ref_inn_facade`：验证建筑层叠、屋瓦、窗框和阴影。
4. `ref_street_modules`：验证道路模块可拼装性。
5. `ref_ui_components`：验证小尺寸可读性。
6. `ref_star_map`：验证外层 UI 与世界场景属于同一视觉体系。
7. `ref_awakening_collage`：最后增加超现实强度。

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
| 拼贴演出压住字幕 | 影响叙事 | 明确 subtitle-safe area 和 focal point |

## 6. Image2 能力边界

适合交给 Image2：

- 黄金参考探索。
- 独立透明背景资产候选。
- 同一角色的姿态编辑。
- 材质板、气氛板和异常拼贴演出候选。

仍需人工或脚本处理：

- 精确切图、锚点和画布统一。
- 透明边缘检查。
- 运行时碰撞盒。
- Shader Mask 清理。
- Godot 导入、缩放和场景拼装。
