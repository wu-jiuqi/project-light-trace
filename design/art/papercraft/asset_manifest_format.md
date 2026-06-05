# 纸工资产清单格式

正式清单位于：

```text
assets/papercraft/manifests/core.json
assets/papercraft/manifests/id0001.json
assets/papercraft/manifests/id0762.json
```

当前生产阶段只在清单中推进人物立绘条目。walk、talk、方向变体、独立阴影、道具、FX、UI、环境模块和星图碎片暂不列为新生产目标。

## 顶层字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `schemaVersion` | number | 当前固定为 `1` |
| `scope` | string | `core` 或碎片 ID |
| `assets` | array | 资产条目 |

## 资产字段

| 字段 | 必填 | 说明 |
|---|---|---|
| `id` | 是 | 全库唯一的小写英文 ID |
| `path` | 是 | `assets/papercraft/` 下的目标路径 |
| `category` | 是 | 资产分类 |
| `role` | 是 | 该资产的生产用途 |
| `status` | 是 | `planned`、`candidate`、`review` 或 `ready` |
| `generation` | 是 | Image2 生产方式 |
| `requiredFor` | 是 | 首次需要该资产的里程碑 |
| `notes` | 否 | 视觉锚点和限制 |
| `variants` | 否 | 同类变体 |
| `maskFor` | 否 | `_sp_mask` 对应的基础资产 ID |

## 枚举

`category`：

```text
reference
material
ui
environment
character
prop
fx
mask
```

当前阶段新生产条目只使用 `character`。其他分类保留为后续阶段或既有参考资产使用。

`generation`：

```text
reference_board
reference_edit
isolated_asset
ui_component
effect_composite
manual_mask
```

`requiredFor`：

```text
golden_reference
vertical_slice
id0762_full
global_ui
```

## 状态流转

```text
planned -> candidate -> review -> ready
```

- `planned`：仅存在于清单中，可以没有 PNG。
- `candidate`：已生成候选文件，尚未完成检查。
- `review`：已完成初步清理，等待最终验收。
- `ready`：正式入库，可以接入 Godot。

`candidate`、`review` 和 `ready` 状态的条目必须存在对应文件。
