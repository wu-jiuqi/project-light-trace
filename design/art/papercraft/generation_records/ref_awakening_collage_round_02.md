# Image2 生成记录：ref_awakening_collage Round 02

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_awakening_collage` |
| 日期 | `2026-06-04` |
| 本轮状态 | 按用户反馈重做逻辑，仍待确认冻结 |
| 生成方式 | 基于既有小镇例图的本地后处理 |
| 参考图 | `assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_awakening_collage_round_02/` |
| 当前输出 | `assets/papercraft/core/references/ref_awakening_collage.png` |

## 用户反馈

上一轮方向不成立。正确生成逻辑应为：

1. 先生成一张正常的小镇图。
2. 小镇建筑、道路沿用之前例图的纸板表现手法。
3. 色彩可以更鲜艳。
4. 完成正常小镇后，再表现灰白侵蚀。
5. 侵蚀逻辑是将小镇一半变为灰度图。
6. 过渡处使用不规则锯齿边界。

## 本轮执行

- 先从既有小镇例图裁出完整小镇画面，保留旅店、两侧建筑、街道与纸板质感。
- 对底图进行自然色彩增强：天空、屋顶、墙面、街道分别做区域性色彩处理，避免加入漂浮色块或额外符号。
- 保存彩色底图：`ref_awakening_collage_r02_v03_normal_town_color_first.png`。
- 在彩色底图基础上做后处理，将右半边转换为冷灰度。
- 在彩色与灰度交界处加入干净的不规则锯齿纸边。
- 当前最终图：`ref_awakening_collage_r02_v04_clean_half_gray_jagged.png`，并复制到 `assets/papercraft/core/references/ref_awakening_collage.png`。

## 候选记录

| 候选 | 方向 | 文件 |
|---|---|---|
| `normal_base` | 第一版彩色小镇底图，裁切过近，道路不足 | `ref_awakening_collage_r02_normal_town_base.png` |
| `gray_jagged` | 第一版灰度侵蚀，边界黑色三角过重 | `ref_awakening_collage_r02_gray_invasion_jagged.png` |
| `v03_normal` | 改用更低更宽裁切，保留道路与建筑；去掉漂浮色块 | `ref_awakening_collage_r02_v03_normal_town_color_first.png` |
| `v03_gray` | 干净灰度侵蚀，但仍有楔形咬痕和字幕条 | `ref_awakening_collage_r02_v03_gray_invasion_clean_jagged.png` |
| `v04` | 当前版本：只保留半边灰度和锯齿分界 | `ref_awakening_collage_r02_v04_clean_half_gray_jagged.png` |

## QA

- [x] 先存在完整彩色小镇底图。
- [x] 灰白侵蚀是基于彩色底图的后处理，而非重新生成抽象构图。
- [x] 建筑、屋顶、街道和纸板质感来自既有项目例图。
- [x] 灰度侧与彩色侧是同一画面的一半转换。
- [x] 过渡处使用不规则锯齿边。
- [ ] 色彩鲜艳度、灰度占比和锯齿幅度待用户继续确认。
