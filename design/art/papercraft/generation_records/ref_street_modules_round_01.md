# Image2 生成记录：ref_street_modules Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_street_modules` |
| 日期 | `2026-06-04` |
| 生成方式 | 内置 `image_gen` 交互生成 |
| 参考图 | `assets/papercraft/core/references/ref_material_board.png`、`assets/papercraft/core/references/ref_character_standard.png`、`assets/papercraft/core/references/ref_inn_facade.png`、`assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_street_modules_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_street_modules_round_01/ref_street_modules_r01_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_street_modules.png` |
| 冻结状态 | 用户确认选择 `v02`，已正式入库 |

## 用户选择

```text
选择02, 你可以根据我们这一版对道路、石板、人行道模块要求的变化对文档进行一定修改
```

执行结果：

- 已将 `ref_street_modules_r01_v02.png` 复制为 `assets/papercraft/core/references/ref_street_modules.png`。
- 已将 `assets/papercraft/manifests/core.json` 中 `ref_street_modules` 状态更新为 `ready`。
- 已同步更新 `style_bible.md`、`image2_workflow.md` 和 #0762 地图美术规格，使道路标准收束为“灰卡碎石道路 + 抬高人行道 + 中心深色排水暗沟 + 清晰拼接接口”的方向。

## 本轮目标

为黄金参考组的 `ref_street_modules` 探索 10 个方向。重点不是完整街景，而是验证市集街道路模块的可拼装性：5 tile 宽道路、左右抬高人行道、中间 1 tile 排水暗沟、直线段、边缘段、转角和 T 字接口。

外部参考只吸收高层方法：纸片剪贴、异质纹理、绘本感与暗面并置、不合理但可读的纸板舞台空间、由场所身份或情绪主题长出的道路结构。不复刻任何既有 IP 的角色、符号、场景或构图。

## 公共约束

```text
modular hand-cut papercraft market street road module set for a top-down 2D RPG,
layered cardstock, old book page paper, gray-white card, kraft paper,
visible paper fibers, irregular scissor-cut edges, subtle cardboard thickness,
single top-left light source, restrained lower-right paper shadow,
orthographic top-down asset board, isolated modules with clear connection edges,
5-tile-wide street logic: raised sidewalks and a central drainage gutter,
designed to connect cleanly to a 16px logical grid rendered at 4x scale,
muted full-color source suitable for runtime grayscale shader,
no full scene, no buildings, no characters, no readable words, no letters,
no numbers, no symbols, no watermark, no glossy 3D, no plastic toy look,
no smooth vector edges.
```

## 候选记录

| 候选 | 变化方向 | 文件 |
|---|---|---|
| `v01` | 旧书页道路：展开书页与书脊暗沟作为街道框架 | `ref_street_modules_r01_v01.png` |
| `v02` | 灰卡碎石：最接近常规市集街，粗糙纸石路与中心排水沟 | `ref_street_modules_r01_v02.png` |
| `v03` | 纸板剧场：折叠舞台翼片和幕框成为道路边界 | `ref_street_modules_r01_v03.png` |
| `v04` | 票据账本道路：空白收据、账本边栏和墨色折线形成街面 | `ref_street_modules_r01_v04.png` |
| `v05` | 花店压花路：矢车菊压花、花盆环痕和泥线暗沟 | `ref_street_modules_r01_v05.png` |
| `v06` | 面包房食谱路：空白食谱纸、面粉尘和面团压痕 | `ref_street_modules_r01_v06.png` |
| `v07` | 铁匠铁件夹路：暗铁纸带、铆钉和焦痕夹住道路 | `ref_street_modules_r01_v07.png` |
| `v08` | 墓园裂石路：墓园邻近感的裂石、描图纸细裂缝和干草 | `ref_street_modules_r01_v08.png` |
| `v09` | 钥匙线绳路：线绳装订、钥匙形边夹和暗缝排水沟 | `ref_street_modules_r01_v09.png` |
| `v10` | 异常卷页路：卷曲书页、描图纸水痕和错位石片，接口仍保持直线 | `ref_street_modules_r01_v10.png` |

## 初步 QA

- [x] 10 张候选均为道路模块参考板，而非完整地图或街景。
- [x] 10 张候选均包含直线、边缘、转角或 T 字拼接语汇。
- [x] 候选均保留左上光源和右下纸片投影。
- [x] 候选均避免可读文字、角色、水印和明确 IP 符号。
- [x] 已复制到项目候选目录。
- [x] 已生成本地编号总览图。
- [x] 用户已选择 `v02`。
- [x] 已冻结为正式 `ref_street_modules.png`。
- [x] 已更新 manifest 状态为 `ready`。
- [x] 已运行 `npm run validate:papercraft`。
