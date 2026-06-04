# Image2 生成记录：ref_ui_components Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_ui_components` |
| 清单路径 | `assets/papercraft/manifests/core.json` |
| 日期 | `2026-06-04` |
| 生成方式 | `ui_component`，内置 `image_gen` 交互生成 |
| 项目参考图 | `ref_material_board`、`ref_character_standard`、`ref_inn_facade`、`ref_street_modules`、`paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 外部研究 | 《魔法少女小圆》魔女结界的高层方法参考：剪纸剧场、混合媒介拼贴、非现实透视与符号层叠；不复刻具体角色、符号或构图 |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_ui_components_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_ui_components_round_01/ref_ui_components_r01_contact_sheet.png` |
| 选定图 | `assets/papercraft/core/references/candidates/ref_ui_components_round_01/ref_ui_components_r01_selected_top_row_04.png` |
| 正式预览路径 | `assets/papercraft/core/references/ref_ui_components.png` |
| 当前状态 | 用户确认选择上排 04，已冻结为 `ready` |

## 本轮目标

生成一张 `2 x 5` 的 UI 风格候选板。每个候选面板都必须包含：

- 对话框与胶带/线绳固定的姓名条。
- `normal`、`hover`、`pressed`、`disabled` 四种按钮状态。
- 背包/剪贴簿卡槽。
- 星图碎片或详情卡 motif。
- 少量图标/装饰 swatch。

所有候选必须保留稳定正文负空间，避免纸纹、裂缝和装饰压过文本区。

## 候选记录

| 位置 | 方向 | 初步结论 |
|---|---|---|
| 上排 1 | 撕边素描本 / 旧纸页 | 最克制，适合默认对话框基线 |
| 上排 2 | 深色纸板剧场 | 适合标题页、星图或高对比弹窗 |
| 上排 3 | 铃铛花眼睛 / 钥匙异常 UI | 角色标准图连续性强，适合特殊 NPC 对话 |
| 上排 4 | 登记簿旅店 / 书脊装订 | 适合旅店、存档、日志、背包剪贴簿 |
| 上排 5 | 灰卡石板 / 镇公所档案 | 最接近地图模块语言，适合系统菜单 |
| 下排 1 | 描图纸星图 / 银箔裂纹 | 适合星图、碎片修复、源印提示 |
| 下排 2 | 锻炉焦痕 / 铁件固定 | 适合警告、确认、危险状态 |
| 下排 3 | 蓝灰花店 / 压花标签 | 适合温和支线、物品详情、情绪线索 |
| 下排 4 | 墓园裂缝 / 钥匙孔标签 | 适合锁定、未知、恐惧、规则破裂 |
| 下排 5 | 觉醒混合拼贴 | 最狂野，适合颜色觉醒、源印解码和异常演出 |

## 用户选择

```text
选用上排4, 星图界面是我下一轮的事, 和这一轮无关
```

执行结果：

- 已将上排 04 裁切为 `ref_ui_components_r01_selected_top_row_04.png`。
- 已将该选定图复制为 `assets/papercraft/core/references/ref_ui_components.png`。
- 已将 `assets/papercraft/manifests/core.json` 中 `ref_ui_components` 状态更新为 `ready`。
- 已更新 `style_bible.md`、`image2_workflow.md` 和 `assets/papercraft/core/ui/README.md`，明确本轮只冻结按钮、对话框、背包剪贴簿和卡槽模块，星图界面后续独立探索。

本轮冻结语言：

- 旧登记簿展开页作为对话框主面板。
- 书脊、装订环、折页、铜钉和线绳作为固定结构。
- 按钮使用小型登记标签或账册索引条，并以纸层高度、阴影、色差和压痕区分四态。
- 背包与卡槽使用剪贴簿 / 登记簿混合语言，包含折角纸页、浅网格、空白票据和卡纸收纳袋。
- 所有文字仍由 Godot 渲染，AI 图只提供空白安全区和结构。

## Prompt 摘要

```text
Create one wide contact-sheet image containing 10 distinct UI component style directions for Project Shuoguang.
Use the provided papercraft project references as style anchors: material board, abnormal full-sheet paper-doll character, registration-book inn facade, gray-card cobblestone street modules, and gray-eaves inn concept.
Extract kraft paper, gray card, old book pages, fiber paper, tracing paper, silver foil, string, tape, rivets, left-top light, right-bottom shadows, irregular scissor-cut and occasional torn edges.

Show in every panel: a dialogue panel with a blank safe text area, a name strip, four button states, an inventory/scrapbook slot, a star-map shard/detail motif, and ornament swatches.
No readable text, no numbers, no letters, no faux glyphs, no watermark, no anime characters, no franchise elements, no smooth vector UI, no glossy plastic, no 3D toy look.
UI must clearly separate from future gray papercraft gameplay scenes through stronger silhouettes, higher contrast backing, thicker shadows, or distinct material framing.
```

## QA

- [x] 已按 `qa_checklist.md` 做首轮目视检查。
- [x] 十个候选均包含对话框、按钮四态、卡槽/详情卡和装饰 swatch。
- [x] 大部分正文区留白充足，纸纹未压过未来文本安全区。
- [x] 未生成需要阅读的正式文字；少量装饰线仅作为空白占位。
- [x] 已写入正式路径，manifest 状态更新为 `ready`。
- [x] 已运行 `npm run validate:papercraft`。
- [x] 用户已选择上排 04。
- [x] 已裁切并冻结为正式 `ref_ui_components.png`。
