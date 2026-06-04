# Image2 生成记录：ref_awakening_collage Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_awakening_collage` |
| 日期 | `2026-06-04` |
| 本轮状态 | 候选探索，未冻结 |
| 生成方式 | 内置 `image_gen` 尝试失败后，改用本地程序化纸工拼贴草案 |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_awakening_collage_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_awakening_collage_round_01/ref_awakening_collage_r01_contact_sheet.png` |
| 临时选择板 | `assets/papercraft/core/references/ref_awakening_collage.png` |

## 联网参考提炼

外部参考只提炼高层方法，不复刻具体 IP 的角色、符号或构图：

- `Gekidan Inu Curry` / 魔女结界相关资料强调 collage、cut-out、texture、surreal dreamscape 与正常世界的强烈反差。
- 参考重点转译为本项目语言：纸板剧场、撕纸边界、旧书页/描图纸/线绳/胶带、非理性透视、重复纸片、清晰焦点与叙事可读性。

## 本轮目标

为 #0762「颜色的葬礼」的“进入世界 / 颜色觉醒”过场探索 10 个构图方向。每张必须表达：

- 灰白小镇正在被异常吞没，灰色占比高于彩色。
- 彩色代表被唤醒的情感，不是普通装饰。
- 小镇、广场白色雕像、六色旋涡 / 源印之间要有逻辑关系。
- 画面可以怪异，但玩家应能读出“从灰白世界进入 0762，并开始理解颜色回收”的意思。
- 底部保留低干扰区域，便于后续字幕或过场 UI。

## 候选记录

| 候选 | 方向 | 文件 |
|---|---|---|
| `v01` | 彩色小镇被左侧锯齿灰幕侵蚀，源印悬在尚存彩色一侧 | `ref_awakening_collage_r01_v01_split_town_gray_invasion.png` |
| `v02` | 纸板剧场揭幕，灰幕压住舞台左侧，右侧露出局部彩色建筑 | `ref_awakening_collage_r01_v02_paper_theater_reveal.png` |
| `v03` | 登记簿地图式构图，六色情感节点围绕中心源印 | `ref_awakening_collage_r01_v03_ledger_map_six_colors.png` |
| `v04` | 墓园绿色裂缝贯穿画面，灰色世界从裂口外扩 | `ref_awakening_collage_r01_v04_cemetery_green_crack.png` |
| `v05` | 六色纸片环绕广场雕像，表现逐色回收与情感同框 | `ref_awakening_collage_r01_v05_six_color_orbits.png` |
| `v06` | 大面积锯齿灰潮淹没小镇，仅保留一块彩色生机岛 | `ref_awakening_collage_r01_v06_sawtooth_gray_flood.png` |
| `v07` | 织女瞳孔 / 源印视角，小镇被纳入一只巨眼中 | `ref_awakening_collage_r01_v07_pupil_source_mark.png` |
| `v08` | 零时钟面覆盖小镇，强调 3:15 时间锚点与色彩断裂 | `ref_awakening_collage_r01_v08_zero_time_clock.png` |
| `v09` | 多层纸板舞台纵深，彩色纸幕像情感模块一样插入灰镇 | `ref_awakening_collage_r01_v09_parallax_cardboard_stage.png` |
| `v10` | 白色雕像碎裂，六色碎片从中心爆发后又被灰幕压迫 | `ref_awakening_collage_r01_v10_shattered_white_statue.png` |

## 公共约束

```text
surreal mixed-media papercraft collage for a 2D RPG awakening sequence,
hand-cut cardstock, torn book pages, tracing-paper layers, thread, tape,
single top-left light source, lower-right paper shadow,
gray-white town of fragment 0762, white central statue, six emotional colors,
gray invasion larger than the surviving color area,
clear focal point, subtitle-safe lower area,
no readable generated text, no watermark, no photorealistic gore,
do not copy existing anime characters, symbols, or compositions.
```

## QA

- [x] 10 张候选均保留灰白小镇与彩色侵袭/觉醒的对比。
- [x] 10 张候选均保留纸工材质、撕边、层叠和右下投影。
- [x] 10 张候选均为过场 / 气氛板，不混入 TileMap 正式模块目录。
- [x] 底部均预留低干扰字幕安全区。
- [ ] 本轮为程序化草案，细节丰富度未达到正式 Image2 冻结标准。
- [ ] 待用户选择 1-2 个方向后，用参考图编辑继续精修。
