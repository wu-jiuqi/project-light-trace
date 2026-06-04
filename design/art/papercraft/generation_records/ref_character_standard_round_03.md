# Image2 生成记录：ref_character_standard Round 03

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_character_standard` 固定方向微调 |
| 日期 | `2026-06-03` |
| 生成方式 | 内置 `image_gen` 交互生成 |
| 固定主体 | `assets/papercraft/core/references/candidates/ref_character_standard_round_02/ref_character_standard_r02_v06.png` |
| 新风格参考 | 用户在对话中提供的《欢迎光临 Beastro》截图，仅借鉴高层视觉语言 |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_character_standard_round_03/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_character_standard_round_03/ref_character_standard_r03_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_character_standard.png` |
| 冻结状态 | 用户确认选择 `v04`，已正式入库 |

## 用户选择

```text
选择04, 你可以根据我们这一版对人物形象要求的变化对文档进行一定修改
```

执行结果：

- 已将 `ref_character_standard_r03_v04.png` 复制为 `assets/papercraft/core/references/ref_character_standard.png`。
- 已将 `assets/papercraft/manifests/core.json` 中 `ref_character_standard` 状态更新为 `ready`。
- 已同步更新 `style_bible.md`、`image2_workflow.md` 和 #0762 角色美术规格，使角色标准图从常规冯婶纸偶转为植物接待员式异常纸偶。

## 本轮目标

根据用户确认，角色标准图方向固定为 Round 02 的 `v06`：铃铛花接待员，花朵内嵌睡眼，围裙、铅笔、钥匙和空白登记簿作为旅店意象。

本轮微调吸收新参考图的以下高层特征：

- 粗白色纸牌 / 贴纸式外描边。
- 更干净的独立立牌剪影。
- 深蓝紫衣片和更清楚的色块分区。
- 细长腿、细长袖子和略带披风感的大外轮廓。
- 更少的内部杂讯，更强的缩略图可读性。

不复刻新参考图中的具体帽子、披风、角色比例、姿势或构图。

## 候选记录

| 候选 | 变化方向 | 文件 | 初步判断 |
|---|---|---|---|
| `v01` | 轻度吸收白描边，保留 Round 02 v06 的密集植物感 | `ref_character_standard_r03_v01.png` | 与原 06 连续性最好，但略复杂 |
| `v02` | 加强立牌、长腿和深蓝紫披风形 | `ref_character_standard_r03_v02.png` | 新参考味道更明显，仍有不少装饰 |
| `v03` | 干净图形化，三朵主花、钥匙减少、剪影稳定 | `ref_character_standard_r03_v03.png` | 最适合作为标准图候选 |
| `v04` | 戏剧化外轮廓，花冠更宽，披风感最强 | `ref_character_standard_r03_v04.png` | 用户确认冻结为正式 `ref_character_standard` |

## 公共约束

```text
Use Round 02 v06 as the structural base:
bellflower heads with sleepy eyes, apron body, pocket pencil,
blank guest ledger, dangling keys, dark sweater sleeves and plant stems.

Use the Beastro reference only for high-level visual cues:
bold off-white cutout border, clean standee readability,
lanky posture, deep navy-purple clothing panels and graphic silhouette.

Do not copy the reference character, hat, cloak, pose or composition.
No readable text, no letters, no symbols, no watermark, no full scene,
no photorealism, no glossy 3D, no plastic toy look, no pixel art.
```

## QA

- [x] 四张候选均保留 Round 02 v06 的核心植物接待员方向。
- [x] 四张候选均加入新参考的白色立牌边、深蓝紫色块和更干净剪影。
- [x] 候选无可读文字、水印、完整场景或额外角色。
- [x] 已生成本地编号总览图。
- [x] 已运行 `npm run validate:papercraft`。
- [x] 用户已选择 `v04`。
- [x] 已冻结为正式 `ref_character_standard.png`。
- [x] 已更新 manifest 状态为 `ready`。
