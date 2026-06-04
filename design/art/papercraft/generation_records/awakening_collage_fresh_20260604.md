# Image2 生成记录

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | ref_awakening_collage |
| 清单路径 | assets/papercraft/manifests/core.json |
| 日期 | 2026-06-04 |
| 操作者 | Codex |
| 使用参考图 | ref_material_board, ref_character_standard, ref_inn_facade, ref_street_modules, paper-cardboard-style-v1-innkeeper-gray-eaves-inn |
| 生成方式 | effect_composite |

## 本轮目标

生成 #0762 进入世界/觉醒演出参考图：小镇作为完整纸工过场画面出现，彩色生命力区域被灰白遗忘区域侵蚀。画面允许超现实拼贴，但必须一眼读出“灰白正在吞没彩色小镇”。

本轮明确不读取旧的 `ref_awakening_collage_round` 生成记录；候选只来自本轮新生成图片。

## Prompt 摘要

```text
Wide 16:9 surreal hand-cut papercraft cutscene for a 2D RPG.
Scene: #0762 small town, front-facing / slightly elevated paper theater stage.
About 35% of town remains colorful and alive; about 65% is gray, lifeless, desaturated.
Gray region invades through a jagged torn-paper or ink-bleed edge softened by translucent tracing-paper fog.
Include readable town logic: old guest-ledger gray-eaves inn, three upper windows, centered door, blank sign;
stone street with raised sidewalks and dark central drainage channel; plaza white statue; hints of bakery, flower shop, blacksmith, graveyard.
Color must be object color, not flat color blocks: red roofs, blue sky, white clouds, green plants, yellow bakery light, purple music-note scraps.
Use layered cardstock, old book pages, kraft paper, gray card, tracing paper, tape, thread, brass fasteners.
Leave bottom 18% subtitle-safe low-contrast paper texture.
No readable text, logos, watermark, gore, smooth vector edges, plastic toy look, or photorealistic 3D.
```

## 允许变化

- 侵蚀边界可以是锯齿撕纸、墨迹扩散、雾幕或纸层塌陷。
- 镜头可在平视纸板舞台、立体书展开页、轻微俯视街景之间变化。
- 异常拼贴强度可变化，但建筑、道路、灰白/彩色关系必须保持可读。

## 禁止变化

- 不得把彩色区域做成抽象色块；必须用房瓦、天空、云、植物、炉光等物件上色。
- 不得生成可读文字、商标、外部作品角色或与项目无关的符号。
- 不得让异常拼贴压过“灰白侵蚀彩色小镇”的核心表达。
- 不得破坏底部字幕安全区。

## 候选记录

| 候选 | 文件 | 结论 | 原因 |
|---|---|---|---|
| v01 | assets/papercraft/core/references/candidates/awakening_collage_fresh_20260604/awakening_collage_fresh_v01.png | 保留 | 侵蚀逻辑清楚，边界雾化明显；舞台边框较弱 |
| v02 | assets/papercraft/core/references/candidates/awakening_collage_fresh_20260604/awakening_collage_fresh_v02.png | 保留 | 彩色/灰白比例和中心雕像关系稳定；纸板舞台感更强 |
| v03 | assets/papercraft/core/references/candidates/awakening_collage_fresh_20260604/awakening_collage_fresh_v03.png | 选定 | 立体书结构、底部留白、灰白占比和小镇可读性最接近本轮目标 |

## 当前文件

- 临时候选板：`assets/papercraft/core/references/candidates/awakening_collage_fresh_20260604/awakening_collage_fresh_contact_sheet_partial.png`
- 已冻结参考：`assets/papercraft/core/references/ref_awakening_collage.png`

## 选定结论

用户选择 v03 作为本轮方向。原计划继续生成 10 张不同风格候选，但在 v03 已被选定后，不再将补齐候选数量作为阻塞项。后续应基于 v03 做局部编辑和演出模块扩展，而不是重新发散整体风格。

## QA

- [x] 已按 `qa_checklist.md` 检查非空、焦点、字幕安全区和核心叙事。
- [x] 已根据用户选择冻结 v03。
- [x] 已更新清单状态。
- [x] 已运行 `npm run validate:papercraft`。
