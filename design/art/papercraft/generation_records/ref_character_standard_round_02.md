# Image2 生成记录：ref_character_standard Round 02

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_character_standard` 异常语言实验 |
| 日期 | `2026-06-03` |
| 生成方式 | 内置 `image_gen` 交互生成 |
| 用户参考 | 对话中提供的两张《魔法少女小圆》异空间截图，仅借鉴表现语法 |
| 材质参考 | `assets/papercraft/core/references/ref_material_board.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_character_standard_round_02/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_character_standard_round_02/ref_character_standard_r02_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_character_standard.png`，本轮不写入 |

## 本轮目标

用户希望进一步接近《魔法少女小圆》异空间中的纸剪拼贴表现，不再受角色文档中的人物外貌约束。允许角色不是人形，甚至可以像舞台装置、植物、建筑或规则本身。

本轮仅借鉴以下高层视觉语法，不复刻现有作品中的具体角色和构图：

- 童稚、平面、近乎手工课的剪纸轮廓与不安内容并置。
- 笑脸、眼睛、花瓣、鞋、钥匙等简单符号重复出现。
- 器官可以被植物、建筑、纸页、线绳和舞台道具替换。
- 身体可以变成图腾、祭坛、悬挂装置或行走的小型建筑。
- 色彩从克制纸色中局部跳出，使用橙、红、蓝、洋红和暗绿强调。

## 公共约束

```text
Create one original surreal handcrafted papercraft innkeeper entity
for a top-down 2D RPG character-language experiment.

Use the two user-provided visual references only for high-level visual grammar
and mood. Do not reproduce any existing character or composition.

Use layered cardstock, fiber paper, blank aged book pages, tracing paper,
thread, matte tape, sparse brass fasteners, visible scissor-cut edges,
top-left craft lighting and bottom-right paper shadows.

Human anatomy is optional. Preserve only a loose innkeeper symbol set when useful:
blank guest ledger, old room keys, apron pocket, pencil, worn shoes,
dark sweater sleeves and a sleepy or overly polite expression.

Isolate the entity on a plain warm gray-white cardstock backing.
No readable text, no letters, no symbols, no watermark, no full environment,
no exact anime reproduction, no gore, no photorealism, no glossy 3D,
no plastic toy look, no smooth vector polish, no pixel art.
```

## 候选记录

| 候选 | 实验方向 | 文件 | 初步判断 |
|---|---|---|---|
| `v01` | 黑纸笑脸招牌，悬浮式接待员 | `ref_character_standard_r02_v01.png` | 童稚诡异最直接，适合异常 NPC |
| `v02` | 双生仙人掌头，礼仪式钥匙串 | `ref_character_standard_r02_v02.png` | 植物替代器官效果稳定，适合花店或群体 NPC |
| `v03` | 空围裙，无脸眼睛悬吊，鞋子重复 | `ref_character_standard_r02_v03.png` | 留白和缺席感强，适合普通人被抽空后的状态 |
| `v04` | 钥匙孔合唱，门板身体与重复眼睛 | `ref_character_standard_r02_v04.png` | 旅店主题结合最好，可继续作为冯婶异常版底稿 |
| `v05` | 登记簿手风琴身体，多手多鞋接待员 | `ref_character_standard_r02_v05.png` | 重复逻辑清楚，适合表现规则化劳动 |
| `v06` | 铃铛花接待员，花朵内嵌睡眼 | `ref_character_standard_r02_v06.png` | 植物梦境感最好，可沉淀为通用异常语法 |
| `v07` | 行走旅店立面，门中有门，眼睛藏在室内 | `ref_character_standard_r02_v07.png` | 建筑与角色融合最好，适合作为项目特色方向 |
| `v08` | 眼纹接待蛾，钥匙孔翅膀 | `ref_character_standard_r02_v08.png` | 演出感强，适合觉醒或关键 NPC |
| `v09` | 悬挂式接待装置，三张面具轮换 | `ref_character_standard_r02_v09.png` | 舞台装置逻辑完整，适合 Boss 前置或规则崩坏 |
| `v10` | 遗忘旅客祭坛，笑脸、植物、纸页和门混合 | `ref_character_standard_r02_v10.png` | 密度最高，适合作为异常演出上限 |

## 允许变化

- 完全移除人形、脸部、正常头身比和合理四肢结构。
- 将身体替换为植物、建筑、登记簿、围裙、纸花、悬挂装置或祭坛。
- 重复眼睛、鞋、钥匙、门和手等简单符号。
- 增加局部饱和色和彩色纸屑，但维持纸工材质统一。
- 将角色标准图作为异常语法板，而不是立即可运行的单体精灵。

## 禁止变化

- 不复刻参考作品中的具体角色、构图或镜头。
- 不生成可读文字、字母、符号、水印或完整场景。
- 不使用塑料、橡胶、写实 3D 玩具、光滑矢量边缘或写实血腥表现。
- 不写入正式 `ref_character_standard.png`，不更新 manifest 状态。

## QA

- [x] 已生成十张原创异常角色语言候选。
- [x] 候选均保留纸剪拼贴、线绳、旧纸层和手工裁切感。
- [x] 候选均无可读文字、水印和完整场景。
- [x] 已生成本地编号总览图，便于缩略图比较。
- [x] 已运行 `npm run validate:papercraft`。
- [ ] 等待人工选择可沉淀为全项目语法的方向。
- [ ] 选择后再决定 `ref_character_standard` 是冻结常态角色、异常角色，还是常态与异常双板。
