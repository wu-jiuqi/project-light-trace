# Image2 生成记录：ref_character_standard Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_character_standard` |
| 清单路径 | `assets/papercraft/manifests/core.json` |
| 日期 | `2026-06-02` |
| 生成方式 | `reference_edit`，内置 `image_gen` 交互生成 |
| 材质参考 | `assets/papercraft/core/references/ref_material_board.png` |
| 气氛参考 | `assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_character_standard_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_character_standard_round_01/ref_character_standard_r01_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_character_standard.png`，本轮不写入 |

## 联网参考提炼

本轮只借鉴纸剪拼贴的表现语法，不复刻现有作品中的具体角色或构图。

- Production I.G 对剧团犬咖喱的访谈提到俄式和捷克式动画影响，以及纸剪手工制作带来的身体感：
  `https://www.productionig.com/contents/works_sp/54_/s08_/index.html`
- 剧团犬咖喱资料页可用于确认其在《魔法少女小圆》中承担异空间设计：
  `https://en.wikipedia.org/wiki/Gekidan_Inu_Curry`

可用于本项目的转译：

- 常态角色仍像可游玩的绘本纸偶，保留清楚的职业和动作锚点。
- 怪异感来自比例、材料替换和拼贴逻辑，不依赖写实恐怖。
- 头部可以逐步脱离人体：从纸页、线绳、植物种子到蒲公英球。
- `ref_character_standard` 需要测试常态角色与异常演出的分界线，而不是立刻锁死单一答案。

## 公共 Prompt

```text
Create one centered full-body handcrafted papercraft puppet of Feng Shen,
the elderly innkeeper, as a golden-reference candidate for a top-down 2D RPG.
Use ref_material_board as the strict materials reference and the existing
gray-eaves inn concept board as identity and mood reference.

Preserve these identity anchors:
- elderly Chinese innkeeper woman in her sixties
- sleepy heavy eye bags and rounded shoulders
- dark brown old sweater
- layered white apron with one pocket and a small pencil
- one cheek propped by one hand
- thick completely blank guest ledger
- worn shoes and bottom-center foot anchor

Use layered cardstock, fiber paper, visible paper fibers, irregular hand-cut edges,
narrow dark paper thickness edges, restrained old-paper wear, sparse fasteners,
single soft top-left light source and restrained bottom-right shadow.

Place the isolated character on a plain warm gray-white cardstock backing.
No environment, no counter, no buildings, no readable text, no letters,
no symbols, no watermark, no extra characters, no plastic toy look,
no glossy photorealistic 3D render, no smooth vector edges, no pixel art.
```

每张候选在公共 Prompt 上增加一个受控变化项。

## 受控变化

| 候选 | 变化方向 | 初步观察 |
|---|---|---|
| `v01` | 克制生产基线，常规老妇人比例，纸纹和铆钉清楚 | 与现有气氛板最接近，可直接作为常态候选 |
| `v02` | 温和绘本纸娃娃，头稍大、脚更小、细节简化 | 更亲切，缩小时轮廓干净 |
| `v03` | 桌面纸偶剧场，关节铆钉和厚纸层更明确 | 纸偶性最强，适合验证运行时摆动 |
| `v04` | 民俗剪纸绘本，围裙更宽、比例更平面 | 常态与怪异之间的轻度风格化 |
| `v05` | 旧档案剪贴簿，围裙补丁和纸页层次加强 | 材质叙事更明显，但仍是普通冯婶 |
| `v06` | 蒲公英种子光环，脸仍完整可读 | 植物异质化的温和入口 |
| `v07` | 完整蒲公英球头，仅保留极简眼睛和嘴 | 非人体头部边界测试，辨识度仍由服装和动作维持 |
| `v08` | 登记簿纸页头，页角替代碎发与发髻 | 角色职业和异质材料结合最直接 |
| `v09` | 线绳悬吊木偶，四肢拉长，身体折叠 | 可用于测试日常角色是否允许明显不合比例 |
| `v10` | 蒲公英与登记簿页瓣混合头，身体轻度不对称 | 最接近异常拼贴语法，适合作为上限参照 |

## 允许变化

- 人体比例、头身比、四肢长度和纸偶关节存在感。
- 头部从普通老妇人逐级变化为纸页、植物种子或混合拼贴。
- 纸页补丁、线绳、胶带和铆钉的克制用量。
- 常态绘本感与局部超现实拼贴之间的强度。

## 禁止变化

- 不移除冯婶的白围裙、铅笔、托腮动作、空白登记簿和底部脚锚点。
- 不生成可读文字、字母、符号、水印、额外人物或完整场景。
- 不使用塑料、橡胶、光滑矢量边缘或写实 3D 玩具质感。
- 不写入正式 `ref_character_standard.png`，不更新 manifest 状态。

## 候选记录

| 候选 | 文件 |
|---|---|
| `v01` | `ref_character_standard_r01_v01.png` |
| `v02` | `ref_character_standard_r01_v02.png` |
| `v03` | `ref_character_standard_r01_v03.png` |
| `v04` | `ref_character_standard_r01_v04.png` |
| `v05` | `ref_character_standard_r01_v05.png` |
| `v06` | `ref_character_standard_r01_v06.png` |
| `v07` | `ref_character_standard_r01_v07.png` |
| `v08` | `ref_character_standard_r01_v08.png` |
| `v09` | `ref_character_standard_r01_v09.png` |
| `v10` | `ref_character_standard_r01_v10.png` |
| 总览 | `ref_character_standard_r01_contact_sheet.png` |

## QA

- [x] 十张候选均保留冯婶的职业、服装和动作锚点。
- [x] 候选均使用左上光源和右下投影。
- [x] 候选均无可读文字、水印、额外人物和场景。
- [x] 已生成本地编号总览图，便于按缩略图比较。
- [x] 已运行 `npm run validate:papercraft`。
- [ ] 等待人工选择常态基线、允许的怪异强度和需要融合的候选。
- [ ] 选择后再写入正式 `ref_character_standard.png` 并更新 manifest 状态。
