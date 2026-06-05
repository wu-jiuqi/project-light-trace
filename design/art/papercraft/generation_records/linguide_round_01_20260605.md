# Image2 生成记录

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `id0001_character_linguide_*` / `id0001_prop_linguide_datapad` / `id0001_fx_linguide_datapad_*` |
| 清单路径 | `assets/papercraft/manifests/id0001.json` |
| 日期 | 2026-06-05 |
| 操作者 | Codex |
| 使用参考图 | `assets/papercraft/core/references/ref_character_standard.png`、`assets/papercraft/core/references/ref_material_board.png`、`assets/papercraft/core/materials/*.png` |
| 生成方式 | `isolated_asset` / `effect_composite` |

## Prompt

```text
single full-body hand-cut paper puppet for a top-down 2D RPG,
layered cardstock, visible paper fibers, irregular scissor-cut edges,
subtle cardboard thickness, restrained warm-gray cast shadow,
single top-left light source,
Lin Guide, a 34-year-old Tianshu training department guide,
neat black medium-short hair tucked behind the ear, pale tired face,
deep blue fitted company training uniform, deep gray knee-length skirt,
small gold company badge, pale trainer qualification label,
tiny right-ear earpiece, black low-heel shoes,
holding a glowing dark-gray datapad with pale blue screen,
down view, pose set: idle, walk, talk, pocket_hands, observe_silent, between_scripts, farewell,
feet aligned to the bottom-center anchor,
isolated on transparent background,
no scene, no readable text, no extra characters,
no smooth vector edges, no plastic toy look, no photorealistic 3D render.
```

## 允许变化

- `idle`、`walk`、`talk` 可调整数据板高度和身体倾斜，但身份锚点必须保留。
- `pocket_hands` 和 `farewell` 允许数据板不可见，只保留口袋处微弱蓝光。
- `between_scripts` 允许数据板落地并出现红白乱码块。

## 禁止变化

- 不改变深蓝制服、深灰裙、黑发、右耳耳返、公司徽章和数据板蓝光。
- 不生成可读文字、水印、额外角色或完整场景。
- 不使用平滑矢量边缘、塑料玩具质感或写实3D倒角。

## 候选记录

| 候选 | 文件 | 结论 | 原因 |
|---|---|---|---|
| A | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_01/linguide_r01_contact_sheet.png` | 选定 | 7个姿态身份一致，数据板、徽章、耳返、深蓝制服和白色纸偶描边在全尺寸下清晰。 |
| B | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_01/linguide_r01_runtime_32x48_preview.png` | 通过缩小检查 | 32x48运行时尺寸下仍能读出深蓝制服和蓝白数据板。 |

## 正式输出

- `assets/papercraft/fragments/id0001/characters/linguide_idle_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_walk_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_talk_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_pocket_hands_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_observe_silent_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_between_scripts_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_farewell_down.png`
- `assets/papercraft/fragments/id0001/characters/linguide_shadow_down.png`
- `assets/papercraft/fragments/id0001/props/linguide_datapad.png`
- `assets/papercraft/fragments/id0001/fx/linguide_datapad_drop_spritesheet.png`
- `assets/papercraft/fragments/id0001/fx/linguide_datapad_glitch_spritesheet.png`

## QA

- [x] 已按 `qa_checklist.md` 检查。
- [x] 已更新清单状态。
- [x] 已运行 `npm run validate:papercraft`。
