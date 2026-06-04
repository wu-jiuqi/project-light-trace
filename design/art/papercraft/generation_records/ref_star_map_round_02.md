# Image2 生成记录：ref_star_map Round 02

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_star_map` |
| 日期 | `2026-06-04` |
| 生成方式 | 内置 `image_gen` 生成完整母星 + 本地确定性 12 片切割 |
| 母图目录 | `assets/papercraft/core/references/candidates/ref_star_map_round_02/base_stars/` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_star_map_round_02/split_candidates/` |
| 母图总览 | `assets/papercraft/core/references/candidates/ref_star_map_round_02/ref_star_map_r02_base_contact_sheet.png` |
| 碎片总览 | `assets/papercraft/core/references/candidates/ref_star_map_round_02/ref_star_map_r02_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_star_map.png` |
| 当前状态 | 用户选择母图 `base v02`，已冻结为正式 `ref_star_map.png` |

## Round 01 修正

Round 01 主要依赖 prompt 要求“12 块碎片可拼合”。该方式容易被生成模型理解为“散落碎片围成星图氛围”，不能稳定保证所有碎片都来自同一个母形。

Round 02 改为正确生产逻辑：

1. 先生成一张完整、未破裂的星辉卡纸四芒星母图。
2. 再由本地脚本按固定拓扑切成 12 块。
3. 相邻碎片共用同一条切线，确保 12 块可以合理拼回原来的四芒星。

## 本轮目标

- 星图主体必须是完整四芒星被切开，而不是先生成散碎星图。
- 每个候选保留同一套 12 片拓扑。
- 碎片轻微散开但不旋转，便于评估拼合逻辑。
- 中央保留淡淡的原位轮廓和切线，作为归位参考。
- 材质差异来自母星，不来自碎片后期随机拼贴。

## 母图候选记录

| 候选 | 母图方向 | 母图文件 | 碎片文件 |
|---|---|---|---|
| `v01` | 星辉银卡纸 | `ref_star_map_r02_base_v01.png` | `ref_star_map_r02_v01.png` |
| `v02` | 描图纸 / 烟灰银点 | `ref_star_map_r02_base_v02.png` | `ref_star_map_r02_v02.png` |
| `v03` | 闪光收藏卡纸 | `ref_star_map_r02_base_v03.png` | `ref_star_map_r02_v03.png` |
| `v04` | 空白登记簿旧书页 | `ref_star_map_r02_base_v04.png` | `ref_star_map_r02_v04.png` |
| `v05` | 黑纸板剧场 | `ref_star_map_r02_base_v05.png` | `ref_star_map_r02_v05.png` |
| `v06` | 墓园灰石卡纸 / 绿裂光 | `ref_star_map_r02_base_v06.png` | `ref_star_map_r02_v06.png` |
| `v07` | 蓝紫植物压花星辉卡纸 | `ref_star_map_r02_base_v07.png` | `ref_star_map_r02_v07.png` |
| `v08` | 锻炉焦痕 / 暗锡星点 | `ref_star_map_r02_base_v08.png` | `ref_star_map_r02_v08.png` |
| `v09` | 票据时钟 / 空白机械星盘 | `ref_star_map_r02_base_v09.png` | `ref_star_map_r02_v09.png` |
| `v10` | 源印六色线结 / 深宇宙卡纸 | `ref_star_map_r02_base_v10.png` | `ref_star_map_r02_v10.png` |

## 用户选择

```text
母图选择02, 碎片我后期再做, 你直接将母图冻结为正式ref_star_map.png即可
```

执行结果：

- 已将 `assets/papercraft/core/references/candidates/ref_star_map_round_02/base_stars/ref_star_map_r02_base_v02.png` 复制为 `assets/papercraft/core/references/ref_star_map.png`。
- 已将 `assets/papercraft/manifests/core.json` 中 `ref_star_map` 状态更新为 `ready`。
- 已同步更新 `style_bible.md` 和 `image2_workflow.md`，明确星图模块以完整四芒星母图为正式基准，后续碎片必须从母图本地切割。

## 初步 QA

- [x] 10 张母图均为完整四芒星。
- [x] 10 张碎片图均由对应母图本地切割生成。
- [x] 每张碎片图均使用同一套 12 片拓扑。
- [x] 相邻碎片共享切线，拼合逻辑物理成立。
- [x] 已生成母图总览和碎片总览。
- [x] 已运行 `npm run validate:papercraft`。
- [x] 用户已选择 `base v02`。
- [x] 已将选定母图复制为 `assets/papercraft/core/references/ref_star_map.png`。
- [x] 已更新 `assets/papercraft/manifests/core.json` 中 `ref_star_map` 状态为 `ready`。
