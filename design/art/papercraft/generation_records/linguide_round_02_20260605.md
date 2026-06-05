# Image2 生成记录

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `id0001_character_linguide_*` / `id0001_prop_linguide_datapad` / `id0001_fx_linguide_datapad_*` |
| 清单路径 | `assets/papercraft/manifests/id0001.json` |
| 日期 | 2026-06-05 |
| 操作者 | Codex |
| 使用参考图 | `assets/papercraft/core/references/ref_character_standard.png`、`assets/papercraft/core/references/ref_material_board.png` |
| 生成方式 | `isolated_asset` / `effect_composite` |

## 变更原因

Round 01 被废弃：虽然满足了林指导文档的服装和道具规格，但视觉语言过于平面、简单，和 `ref_character_standard.png` 的异常纸工角色基线关系不足。

Round 02 重新以 `ref_character_standard` 为主参考：厚白立牌描边、铃铛花式顶冠、深蓝紫大形、线绳、金属挂件、纸层密度和不安的纸偶感优先；林指导设定作为身份约束保留在制服、数据板、耳返、徽章和胸牌上。

## Prompt

```text
Create an original surreal papercraft NPC puppet of "Lin Guide" that strongly follows ref_character_standard style language.
It must look like it belongs in the same art set as the reference: an ornate hand-cut paper-doll entity, not a normal office lady illustration.

Core style match: thick irregular off-white standee backing, dense layered cardstock, dark indigo and blue-purple large silhouette,
scalloped bellflower-like paper layers, dangling cords, brass rings, key-like metal charms, rivets, stitched gold seams,
visible paper fibers, delicate cut edges, tabletop craft lighting, unsettling storybook puppet.

Subject adaptation: Lin Guide is the Tianshu training department guide.
Her corporate identity is transformed into papercraft symbols: deep blue training uniform as a cloak-like layered paper coat,
knee-length gray skirt as a pale gray registration-card apron panel, glowing datapad as a small blue-lit ledger/tablet,
trainer badge as a brass sun/star pin, earpiece as a tiny brass-and-black device near the right side of the head.

No readable text, no letters, no logo text, no extra characters, no full scene, no watermark.
Use a flat #ff00ff chroma-key background for local background removal.
```

## 允许变化

- `walk`、`talk`、`pocket_hands`、`observe_silent`、`between_scripts`、`farewell` 使用同一母版做本地姿态派生，保证身份和风格一致。
- 非脚本姿态允许屏幕变暗、口袋蓝光或脚边掉落数据板表达状态变化。

## 禁止变化

- 不再回到普通公司职员纸片风格。
- 不改变厚白边、铃铛花顶冠、深蓝紫大形、线绳挂件和金属小件。
- 不生成可读文字、水印、额外角色或完整场景。

## 候选记录

| 候选 | 文件 | 结论 | 原因 |
|---|---|---|---|
| Round 01 | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_01/linguide_r01_contact_sheet.png` | 废弃 | 与参考图关系弱，过于平面和普通。 |
| Round 02 idle source | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_02/linguide_r02_idle_source_magenta.png` | 选定母版 | 与参考图的厚白边、铃铛花、深蓝紫纸层和挂件语言一致。 |
| Round 02 contact sheet | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_02/linguide_r02_contact_sheet.png` | 正式入库 | 7个姿态风格统一，身份锚点和小尺寸可读性保留。 |
| Round 02 runtime preview | `assets/papercraft/fragments/id0001/characters/candidates/linguide_round_02/linguide_r02_runtime_32x48_preview.png` | 通过缩小检查 | 32x48下仍能读出蓝白数据板、深色纸偶大形和上方铃铛花轮廓。 |

## QA

- [x] 已按 `qa_checklist.md` 检查。
- [x] 已更新清单状态与说明。
- [x] 已运行 `npm run validate:papercraft`。
