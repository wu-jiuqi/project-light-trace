# Image2 生成记录：ref_inn_facade Round 01

## 基本信息

| 字段 | 内容 |
|---|---|
| 资产 ID | `ref_inn_facade` |
| 日期 | `2026-06-03` |
| 生成方式 | 内置 `image_gen` 交互生成 |
| 参考图 | `assets/papercraft/core/references/ref_material_board.png`、`assets/papercraft/core/references/ref_character_standard.png`、`assets/concept_art/paper-cardboard-style-v1-innkeeper-gray-eaves-inn.png` |
| 候选目录 | `assets/papercraft/core/references/candidates/ref_inn_facade_round_01/` |
| 总览图 | `assets/papercraft/core/references/candidates/ref_inn_facade_round_01/ref_inn_facade_r01_contact_sheet.png` |
| 正式路径 | `assets/papercraft/core/references/ref_inn_facade.png` |
| 冻结状态 | 用户确认选择 `v02`，已正式入库 |

## 用户选择

```text
选择02, 你可以根据我们这一版对建筑形象要求的变化对文档进行一定修改
```

执行结果：

- 已将 `ref_inn_facade_r01_v02.png` 复制为 `assets/papercraft/core/references/ref_inn_facade.png`。
- 已将 `assets/papercraft/manifests/core.json` 中 `ref_inn_facade` 状态更新为 `ready`。
- 已同步更新 `style_bible.md`、`image2_workflow.md` 和 #0762 地图美术规格，使建筑标准从单纯“砖木纸工建筑”扩展为“场所身份锚点转化为建筑结构”的方向。

## 本轮目标

为黄金参考组的 `ref_inn_facade` 探索 10 个方向。基础锚点来自 #0762 地图美术规格中的“灰檐旅店”：两层宽立面、灰瓦坡顶、三扇二楼小窗、半拉窗帘、居中深灰木门、氧化门环、左侧餐厅窗、褪色横向招牌、深灰门垫和一楼雨水泥痕。

外部参考只吸收高层方法：混合媒介拼贴、纸片/舞台布景感、异质纹理和个人化异世界空间。不复刻任何既有 IP 的角色、场景、符号或构图。

## 公共约束

```text
single isolated facade for the Gray Eaves Inn, a two-story wide inn building
for a top-down 2D RPG, hand-cut layered cardstock, visible paper fibers,
irregular scissor-cut edges, subtle white cutout border,
single top-left light source, restrained lower-right paper shadow,
gray tiled sloped roof, deep eaves, blank faded horizontal sign,
three second-floor windows with half-drawn curtains, one left dining-room window,
centered dark gray wooden door with blackened brass rings, woven dark-gray doormat,
rain splash mud stains along the lower wall,
muted full-color source suitable for runtime grayscale shader,
no readable words, no letters, no symbols, no characters, no full scene,
no watermark, no glossy 3D, no plastic toy look, no smooth vector edges.
```

## 候选记录

| 候选 | 变化方向 | 文件 |
|---|---|---|
| `v01` | 鲸骨旅店：鲸鱼肋骨作为外部建筑框架 | `ref_inn_facade_r01_v01.png` |
| `v02` | 登记簿旅店：巨大的住客登记簿展开成建筑 | `ref_inn_facade_r01_v02.png` |
| `v03` | 铃铛花檐：建筑檐口吸收植物接待员语言 | `ref_inn_facade_r01_v03.png` |
| `v04` | 雨槽旅店：不流动的纸板排水系统包围屋檐 | `ref_inn_facade_r01_v04.png` |
| `v05` | 旅箱旅店：展开的旧旅行箱成为立面结构 | `ref_inn_facade_r01_v05.png` |
| `v06` | 蛾翼灰檐：折叠灰卡蛾翼转化为屋檐 | `ref_inn_facade_r01_v06.png` |
| `v07` | 影戏舞台：纸板剧场框架包住旅店立面 | `ref_inn_facade_r01_v07.png` |
| `v08` | 溺水屋顶：冻结的纸浪成为灰瓦檐层 | `ref_inn_facade_r01_v08.png` |
| `v09` | 钥匙骨架：钥匙与铜环作为梁架和吊挂结构 | `ref_inn_facade_r01_v09.png` |
| `v10` | 空洞面具：屋檐形成无五官的剧场面具剪影 | `ref_inn_facade_r01_v10.png` |

最终选择：

- `v02` 登记簿旅店。
- 采用旧书页、书脊、折页和装订带作为旅店主体结构。
- 保留灰檐旅店的可玩锚点：二楼三窗、半拉窗帘、居中大门、门环、门垫、褪色空白招牌和底部雨水泥痕。

## 初步 QA

- [x] 10 张候选均保留两层旅店、二楼三窗、居中大门、门环、招牌和门垫等基础锚点。
- [x] 候选均以灰卡、牛皮纸、旧书页、粗纤维纸和暗铜固定件为主。
- [x] 候选均避免可读文字、角色、水印和完整街景。
- [x] 已复制到项目候选目录。
- [x] 已生成本地编号总览图。
- [x] 用户已选择 `v02`。
- [x] 已冻结为正式 `ref_inn_facade.png`。
- [x] 已更新 manifest 状态为 `ready`。
- [x] 已运行 `npm run validate:papercraft`。
