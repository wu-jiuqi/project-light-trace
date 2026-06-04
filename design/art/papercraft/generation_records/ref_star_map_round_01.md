# Image2 生成记录：ref_star_map Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_star_map` |
| 日期 | `2026-06-04` |
| 生成方式 | 内置 `image_gen` 交互生成 |
| 项目参考图 | `ref_material_board`、`ref_character_standard`、`ref_inn_facade`、`ref_street_modules`、`ref_ui_components` |
| 外部研究 | 《魔法少女小圆》魔女结界 / Gekidan Inu Curry 的高层方法参考：剪纸剧场、混合媒介拼贴、非现实透视、童话感与不安感并置；不复刻具体角色、符号或构图 |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_star_map_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_star_map_round_01/ref_star_map_r01_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_star_map.png` |
| 当前状态 | 10 张候选已生成，等待用户选择；尚未冻结正式图 |

## 本轮目标

为黄金参考组的 `ref_star_map` 探索 10 个方向。所有方向必须满足一个核心逻辑：

- 星图由 12 块碎片构成。
- 碎片来自同一个母形，必须能拼回一个完整整体。
- 允许不使用经典星星图标，星星可以由银箔、闪卡、铆钉、针孔、压花、票据孔、焦痕或线结表达。
- 星图界面保持独立计划，不继承 `ref_ui_components` 已冻结的登记簿常规 UI 样式，但可以与项目纸工材质体系一致。

## 公共约束

```text
papercraft star-map reference image for a 2D RPG UI,
deep dark cardboard backing, hand-cut layered cardstock, old book page,
gray card, kraft paper, tracing paper, restrained silver foil, string,
tape, brass rivets, visible paper fibers, irregular scissor-cut and occasional torn edges,
single top-left light source, restrained lower-right paper shadow,
12 irregular fragments cut from one continuous mother sheet,
all fragments must visibly assemble into one coherent whole,
show matching seams and a faint assembled ghost outline,
no readable text, no letters, no numbers, no symbols, no watermark,
no anime characters, no franchise elements, no smooth vector edges,
no glossy plastic, no photorealistic 3D toy look.
```

## 候选记录

| 候选 | 变化方向 | 文件 | 初步判断 |
|---|---|---|---|
| `v01` | 深色纸板 + 银箔修复纹 | `ref_star_map_r01_v01.png` | 稳妥，碎片拼合关系清楚 |
| `v02` | 描图纸天文盘 / 中央四芒星孔 | `ref_star_map_r01_v02.png` | 拼合逻辑最强之一，偏冷静档案感 |
| `v03` | 闪光卡纸星星 / 收藏卡箔片 | `ref_star_map_r01_v03.png` | 最接近用户举例的闪卡方向，氛围更妖异 |
| `v04` | 登记簿天文盘 | `ref_star_map_r01_v04.png` | 与旅店和 UI 语言连续性强，但星图独立性略弱 |
| `v05` | 纸板剧场 / 悬挂碎片 | `ref_star_map_r01_v05.png` | 舞台感强，适合标题页和星图过渡 |
| `v06` | 墓园裂石星图 | `ref_star_map_r01_v06.png` | 碎片可拼合感很强，情绪偏墓园与绿色裂缝 |
| `v07` | 植物压花星图 | `ref_star_map_r01_v07.png` | 与角色标准图和花店线有关联，数量与拼合需二轮收紧 |
| `v08` | 锻炉焦痕 / 铆钉星图 | `ref_star_map_r01_v08.png` | 情绪强，适合红色/铁匠线索，但整体较暗 |
| `v09` | 票据时钟 / 12 分片星盘 | `ref_star_map_r01_v09.png` | 12 块逻辑和系统感都强，可作为工程友好候选 |
| `v10` | 源印旋涡 / 六色线结 | `ref_star_map_r01_v10.png` | 异常上限最高，适合万象归源方向；需防止 UI 过载 |

## 初步 QA

- [x] 已生成 10 张不同方向候选。
- [x] 已复制到项目候选目录，未覆盖正式 `ref_star_map.png`。
- [x] 已生成本地编号总览图。
- [x] 候选整体遵守纸工材质族、左上光源、右下纸片投影和无文字约束。
- [x] 已运行 `npm run validate:papercraft`。
- [ ] 用户选择候选后，将选定图复制为 `assets/papercraft/core/references/ref_star_map.png`。
- [ ] 选定后再更新 `assets/papercraft/manifests/core.json` 中 `ref_star_map` 状态为 `ready`。
