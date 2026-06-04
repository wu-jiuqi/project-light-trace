# Image2 生成记录：ref_awakening_collage Round 03

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_awakening_collage` |
| 日期 | `2026-06-04` |
| 本轮状态 | 按用户第二轮反馈重做，待确认冻结 |
| 生成方式 | 基于既有小镇例图的对象级上色 + 本地灰度侵蚀后处理 |
| 参考图 | `assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_awakening_collage_round_03/` |
| 当前输出 | `assets/papercraft/core/references/ref_awakening_collage.png` |

## 用户反馈

1. 彩色表达不应是颜色色块，而应落在具体物件上：例如屋顶瓦片变红、左上天空为蓝色加白云、植物变绿，其他物件也按同样逻辑上色。
2. 灰色与彩色的边界需要模糊，不要用明显线条分开。

## 本轮执行

- 保持 Round 02 的完整小镇底图逻辑。
- 改为对象级上色：
  - 天空：蓝色。
  - 云：偏白纸色。
  - 远山：蓝绿色。
  - 主建筑瓦片：红色陶瓦。
  - 建筑墙面：暖米黄纸墙。
  - 木门、招牌、梁架、箱子：棕色木材。
  - 门环：暖金属色。
  - 植物、花店周边、路灯旁植被：绿色。
  - 街道石板：暖灰石色。
- 去掉漂浮色块、黑色三角和硬分界线。
- 灰白侵蚀改用大半径模糊的不规则蒙版，让右半边逐渐褪成灰度。

## 候选记录

| 候选 | 方向 | 文件 |
|---|---|---|
| `normal_object_color` | 先完成物件级彩色小镇 | `ref_awakening_collage_r03_normal_town_object_color.png` |
| `soft_gray_invasion` | 在彩色小镇上用模糊灰度蒙版做侵蚀 | `ref_awakening_collage_r03_soft_gray_invasion.png` |

## QA

- [x] 彩色不再以漂浮色块表达。
- [x] 屋顶、天空、云、植物、木材、墙面、道路均按物件上色。
- [x] 灰白侵蚀为后处理，基于同一张彩色小镇。
- [x] 灰色和彩色边界已经模糊化，没有明显线条。
- [ ] 灰色占比、侵蚀方向和整体饱和度待用户继续确认。
