# Image2 生成记录：core material textures from ref_material_board

## 基本信息

| 字段 | 内容 |
|---|---|
| 日期 | `2026-06-05` |
| 生成方式 | `reference_edit` / 本地分离裁切 |
| 参考图 | `assets/papercraft/core/references/ref_material_board.png` |
| 输出目录 | `assets/papercraft/core/materials/` |
| 输出尺寸 | `1024x1024` PNG |
| 冻结状态 | 已写入 `core.json`，6 个材质条目均为 `ready` |

## 输出文件

| 资产 ID | 输出文件 | 来源区域 |
|---|---|---|
| `material_kraft` | `assets/papercraft/core/materials/kraft.png` | 左上：牛皮纸内部纹理 |
| `material_gray_card` | `assets/papercraft/core/materials/gray_card.png` | 上中：灰白卡纸内部纹理 |
| `material_book_page` | `assets/papercraft/core/materials/book_page.png` | 右上：旧书页内部纹理 |
| `material_fiber_paper` | `assets/papercraft/core/materials/fiber_paper.png` | 左下：粗纤维纸内部纹理 |
| `material_tracing_paper` | `assets/papercraft/core/materials/tracing_paper.png` | 下中：描图纸内部纹理 |
| `material_foil` | `assets/papercraft/core/materials/foil.png` | 右下：银箔纸内部纹理 |

## 处理说明

- 从已经冻结的 `ref_material_board` 六宫格中分离材质。
- 裁切区域刻意避开撕边、投影、背板、固定件和右下角层叠测试纸片。
- 输出保持参考图的纸张纤维、旧化、褶皱和银箔反光信息；仅做轻微亮度、对比度与锐化恢复。
- 未重新生成新风格，避免偏离已确认的核心材质基准。

## QA

- [x] 6 张材质 PNG 均已输出到正式目录。
- [x] 每张尺寸为 `1024x1024`。
- [x] 每张为 `RGB` PNG。
- [x] 未包含参考板边缘、阴影、固定件或文字。
- [x] 已运行 `npm run validate:papercraft`。
