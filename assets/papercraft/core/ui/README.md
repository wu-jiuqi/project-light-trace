# Core UI

存放纸工化标题页、按钮、对话框、背包、暂停菜单、详情卡和星图相关基础 UI 组件。正式组件不包含 AI 生成文字，所有可读文字由 Godot 运行时渲染。

## 生产基线

常规 UI 基线参考 `assets/papercraft/core/references/ref_ui_components.png`：登记簿旅店 / 书脊装订方向。按钮、对话框、背包剪贴簿和卡槽优先使用旧住客登记簿、折页、书脊、铜钉、线绳、空白票据和浅网格收纳袋。

星图背景与描图纸碎片参考 `assets/papercraft/core/references/ref_star_map.png` 单独生产，不套用本轮登记簿卡槽样式。后续正式星图碎片仍需从完整星图母图本地切割生成。

## Ready Assets

- `title_background.png`：标题页多层纸板舞台，使用旧铜 / 暗金属外框和装订件，保留标题安全区。
- `title_menu_panel.png`：标题页菜单承托面，旧书页底、金属夹边、低对比书写线。
- `dialogue_panel.png`：横向展开旧登记簿对话框，含书脊、装订环、姓名条和正文留白。
- `button_normal.png` / `button_hover.png` / `button_pressed.png` / `button_disabled.png`：四态按钮，纸面中心配金属导轨和铜钉，中央留空给运行时文字。
- `backpack_notebook.png`：背包剪贴簿卡槽，含浅网格、票据口袋、折角和四角铜钉。
- `detail_card.png`：详情卡 motif，灰卡纸浅网格与旅店线稿装饰。
- `pause_tabs.png`：暂停菜单纸质标签页组。
- `star_map_background.png`：星图深色纸板底与描图纸星场。
- `star_shard_tracing_paper.png`：星图描图纸碎片装饰。

## QA Notes

- 所有 PNG 为透明背景，四角 alpha 已清理。
- 中央文字区保留低纹理安全区，不放置可读字符、数字或伪文字。
- 纸片光源统一来自左上，投影向右下。
- 文件名使用小写英文、数字和下划线。
