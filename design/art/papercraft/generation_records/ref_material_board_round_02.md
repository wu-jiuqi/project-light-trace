# Image2 生成记录：ref_material_board Round 02

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_material_board` |
| 日期 | `2026-06-02` |
| 生成方式 | `reference_edit`，内置 `image_gen` 交互编辑 |
| 编辑目标 | `assets/papercraft/core/references/candidates/ref_material_board_round_01/ref_material_board_r01_v08.png` |
| 材质参考 | `assets/papercraft/core/references/candidates/ref_material_board_round_01/ref_material_board_r01_v09.png` |
| 输出文件 | `assets/papercraft/core/references/candidates/ref_material_board_round_02/ref_material_board_r02_v01.png` |
| 对照图 | `assets/papercraft/core/references/candidates/ref_material_board_round_02/ref_material_board_r02_comparison.png` |
| 正式路径 | `assets/papercraft/core/references/ref_material_board.png` |
| 冻结状态 | 已由用户确认 `R02 FUSION`，正式入库 |

## 用户选择

```text
以 08 为底，加入 09 的旧纸磨损氛围和边缘。
```

## Prompt

```text
Edit the first visible image as the target material board.
Use the second visible image only as a material-aging reference.
Preserve the target image's exact bright scrapbook-style composition, square canvas,
3-by-2 arrangement of six large unlabeled paper swatches, bottom fastener strip,
lower-right layered-paper edge test, generous spacing, top-left lighting, and bottom-right shadows.
Keep the target's lighter overall exposure and clean thumbnail readability.
Change only the paper aging treatment and edge character:
add the second image's restrained old-paper wear, slightly darker narrow cardstock edges,
subtle weathering around the outer backing sheet, and more tactile but evenly controlled irregular hand-cut edges.
The result should feel older and more atmospheric than the target but remain brighter,
cleaner, and less distressed than the reference.
Keep the six paper material families clearly distinct:
kraft paper, gray-white cardstock, blank aged book-page paper, coarse fiber paper,
translucent tracing paper, restrained silver foil.
Preserve tape, thread, rivets, and the stacked edge test.
No characters, no people, no faces, no buildings, no scene illustration, no tools,
no readable words, no letters, no symbols, no watermark, no plastic, no rubber,
no glossy toy look, no photorealistic 3D render.
```

## QA

- [x] 保留 `v08` 的明亮剪贴簿构图、六格材质板、固定件条和层叠边缘测试。
- [x] 引入 `v09` 的旧纸磨损、较深窄暗边和均匀手工裁切氛围。
- [x] 没有同步引入 `v09` 的整体暗背景强度。
- [x] 六类纸材仍然可区分，缩略图可读性良好。
- [x] 已写入正式资产路径，并将 manifest 状态更新为 `ready`。
- [x] 已运行 `npm run validate:papercraft`。
- [x] 已由用户确认冻结。
