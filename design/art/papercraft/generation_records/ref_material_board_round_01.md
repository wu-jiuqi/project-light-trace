# Image2 生成记录：ref_material_board Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_material_board` |
| 清单路径 | `assets/papercraft/manifests/core.json` |
| 日期 | `2026-06-02` |
| 生成方式 | `reference_board`，内置 `image_gen` 交互生成 |
| 参考图 | `assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_material_board_round_01/` |
| 正式路径 | `assets/papercraft/core/references/ref_material_board.png`，本轮不写入 |

## Prompt

公共 Prompt：

```text
Create a square high-resolution stylized-concept material reference board for a handcrafted papercraft 2D RPG.
Use a top-down flat-lay presentation on a neutral gray-white cardstock backing.
Arrange exactly six clearly separated large unlabeled paper swatches in a tidy 3-by-2 grid:
natural kraft paper, gray-white cardstock, aged blank book-page paper with absolutely no readable text
and no letter-like marks, coarse fiber paper, translucent tracing paper, and restrained silver foil paper.
Add a narrow unlabeled fastener strip along the bottom containing small pieces of matte paper tape,
simple thread, and a few metal rivets.
Add one compact layered-paper edge test in a corner showing several stacked hand-cut paper layers.
Irregular hand-cut scissor edges, narrow dark paper thickness edges,
single soft top-left light source, restrained warm-gray or cool-gray shadows cast to the bottom-right.
Clean reusable production material board readable at thumbnail size, with clear spacing and no labels.
No characters, no people, no faces, no buildings, no scene illustration, no tools,
no readable words, no letters, no symbols, no watermark, no smooth vector edges,
no plastic, no rubber, no glossy toy look, no photorealistic 3D render.
```

每次生成在公共 Prompt 前半段加入一个受控变化项：

| 候选 | 受控变化 |
|---|---|
| `v01` | Restrained production baseline, clean low-noise surfaces, subtle paper fibers, minimal wear, calm neutral balance. |
| `v02` | Gentle storybook papercraft, softer and slightly warmer, lightly visible natural fibers, friendly handmade feel. |
| `v03` | Archival paper direction, lightly aged and curated, blank book-page paper and gentle pressed creases more prominent. |
| `v04` | Tabletop paper-puppet theater direction, slightly clearer cardstock thickness, small fasteners and cast-shadow separation. |
| `v05` | Handmade workshop direction, stronger kraft and coarse-fiber presence, modest irregularity and restrained wear. |
| `v06` | Gray-card sculpture direction for modular architecture, cooler and more restrained, quiet shadow discipline. |
| `v07` | UI-friendly baseline, quietest low-noise textures, generous separation and strong thumbnail readability. |
| `v08` | Boundary exploration: lighter scrapbook direction, restrained playful layering and limited torn-edge variation. |
| `v09` | Boundary exploration: older paper wear and charcoal-gray accents inherited lightly from the inn mood anchor. |
| `v10` | Boundary exploration: tracing paper and silver foil compatibility emphasized for a future papercraft star-map UI. |

## 允许变化

- 纸纹粗细、磨损程度、冷暖灰倾向。
- 层叠厚度和投影克制度。
- 固定件存在感。
- 边界探索候选中的少量撕边、旧纸磨损、描图纸和银箔强调。

## 禁止变化

- 不生成角色、人物、脸、建筑、场景插画或工具。
- 不生成可读文字、字母、标签、水印或不可控伪文字。
- 不使用塑料、橡胶、写实 3D 玩具或光滑矢量质感。
- 不改变左上光源和右下投影方向。
- 不写入正式 `ref_material_board.png`，不更新 manifest 状态。

## 候选记录

| 候选 | 文件 | 初步结论 |
|---|---|---|
| `v01` | `ref_material_board_r01_v01.png` | 可比较 |
| `v02` | `ref_material_board_r01_v02.png` | 可比较 |
| `v03` | `ref_material_board_r01_v03.png` | 可比较 |
| `v04` | `ref_material_board_r01_v04.png` | 可比较 |
| `v05` | `ref_material_board_r01_v05.png` | 可比较 |
| `v06` | `ref_material_board_r01_v06.png` | 可比较 |
| `v07` | `ref_material_board_r01_v07.png` | 可比较 |
| `v08` | `ref_material_board_r01_v08.png` | 边界候选，可比较 |
| `v09` | `ref_material_board_r01_v09.png` | 边界候选；从两张输出中选用背景更干净、磨损更均匀的一张 |
| `v10` | `ref_material_board_r01_v10.png` | 边界候选；描图纸和银箔更适合后续星图验证 |
| 总览 | `ref_material_board_r01_contact_sheet.png` | 本地合成 `5 x 2` 编号总览，编号不是 AI 生成内容 |

## QA

- [x] 已按 `qa_checklist.md` 做首轮候选目视检查。
- [x] 六类纸材、固定件条和层叠边缘测试在十张候选中均可辨认。
- [x] 候选保持左上光源和右下投影。
- [x] 未写入正式资产路径，未更新清单状态。
- [x] 已运行 `npm run validate:papercraft`。
- [ ] 等待人工选定参考方向后，再做局部拼合、正式冻结和独立材质纹理拆分。
