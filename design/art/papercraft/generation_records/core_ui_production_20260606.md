# Core UI Production 20260606

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产范围 | `assets/papercraft/core/ui/` |
| 清单路径 | `assets/papercraft/manifests/core.json` |
| 日期 | `2026-06-06` |
| 生产方式 | 本地材质合成；使用已冻结参考图与已批准材质 PNG，不重新发散生成 |
| 主要参考 | `ref_ui_components`：登记簿旅店 / 书脊装订常规 UI |
| 星图参考 | `ref_star_map`：仅用于 `star_map_background` 与 `star_shard_tracing_paper` |

## 产出文件

- `assets/papercraft/core/ui/title_background.png`
- `assets/papercraft/core/ui/title_menu_panel.png`
- `assets/papercraft/core/ui/dialogue_panel.png`
- `assets/papercraft/core/ui/button_normal.png`
- `assets/papercraft/core/ui/button_hover.png`
- `assets/papercraft/core/ui/button_pressed.png`
- `assets/papercraft/core/ui/button_disabled.png`
- `assets/papercraft/core/ui/backpack_notebook.png`
- `assets/papercraft/core/ui/detail_card.png`
- `assets/papercraft/core/ui/pause_tabs.png`
- `assets/papercraft/core/ui/star_map_background.png`
- `assets/papercraft/core/ui/star_shard_tracing_paper.png`

## 风格冻结说明

本批常规 UI 继承 `ref_ui_components` 的旧住客登记簿、书脊、装订环、铜钉、折角、空白票据、浅网格和厚纸板投影。所有文字区都只保留低纹理留白，不包含可读文字、数字或伪文字。

2026-06-06 首页调优追加：标题页外框、装订件、菜单夹边和按钮导轨改为旧铜 / 暗金属质感，按钮文字承托区改为更干净的旧书页底，避免文字悬浮或压在背景装饰线上。

星图背景与描图纸碎片没有套用登记簿卡槽语言，而是从 `ref_star_map` 的深色纸板、描图纸、克制银点和四芒星轮廓中派生。后续正式星图碎片仍需按 Style Bible 要求从完整星图母图本地切割。

## QA

- [x] 透明背景四角 alpha 已清理。
- [x] 使用已批准材质族：牛皮纸、灰卡纸、旧书页、粗纤维纸、描图纸和少量铜钉固定件。
- [x] 光源来自左上，投影向右下。
- [x] `normal`、`hover`、`pressed`、`disabled` 四态差异明确。
- [x] 中央留白足够，不遮挡未来中文运行时文字。
- [x] 无水印、签名、伪文字、额外角色或必须阅读的信息。
- [x] 已将 `assets/papercraft/manifests/core.json` 中对应 UI 条目标记为 `ready`。
- [x] 已完成本地透明角与尺寸检查。
- [x] 已运行 `npm run validate:papercraft`。
