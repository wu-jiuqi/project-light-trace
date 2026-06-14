# 碎片#0002「黄昏驿站」— 四座车厢座位表纸雕提示词

> **设计基准**：`papercraft-item-gen` 技能模板 + `fragment_0002.md` NPC座位分配逻辑
> **设计原则**：座位表是平面图表（diagram），非座位实体图（3D rendering）。一张张贴在车厢内/站台墙上的纸雕公告——展示座位排布的空间逻辑。
> **与已有物品的关系**：已有 `0002_env_seat_map_board` 为**五座展示牌**（3A-3B-3C-3D-3E，蓝灰渐变，供玩家解密3B备用票矛盾）。本文件设计的是**四座布局**（左2-过道-右2），可适用于其他车厢或第零号车次的独立车厢。
> **最后更新**：2026-06-14

---

## 设计理念：四座布局的叙事含义

「黄昏驿站」的世界中，第三排车厢有五座（3A-3E）——五个人、五个等。但检票员独白中提到的"第零号车次"是一辆不同的列车。它只有四座：左边两位靠窗，中间过道，右边两位靠走廊。

四座意味着"少一个人"——每一排都有一个缺席。这不是设计缺陷——这是叙事。四个座位，四个能被填上的位置，但总有一个留下的。座位表上的空白不是你数的第四个座位——是你需要决定"留下谁"之后，所有剩下的座位。

**与五座展示牌的关系**：

| 特征 | 五座展示牌 `0002_env_seat_map_board` | 四座座位表（本文件） |
|------|--------------------------------------|---------------------|
| 座位数 | 5（3A→3E） | 4（A B \| 过道 \| C D） |
| 布局 | 横向连续排列，蓝→灰渐变 | 左2/右2分区，中间过道明确分隔 |
| 设计目的 | 揭示3B"备用"标记 → 推动解密逻辑 | 展示"归途之印"列车（第零号车次）的座位结构 |
| 视觉重心 | 3B黄色纸条 + 渐变 | 过道折痕 + 左右对称结构 |
| 叙事层级 | Surface（解密道具） | Deep（暗线A——"四个座位的列车，少一个人"） |

---

## 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Railway Carriage Seating Chart — Dusk Express Carriage No.0 Row 3, Four-Seat Layout with Central Aisle, Seats A and B at Left Windowside, Seats C and D at Right Aisleside, Window and Aisle Designations Stamped Beside Each Seat |
| 主题物 | aged railway notice paper with a folded crease running down the center as the aisle dividing left from right, four rectangular seat zones cut from slightly darker paper labeled A B C D in stamped serif typewriter ink, small window icon stamps embossed beside seats A and D with the character 窗 (window) printed in faded dark blue ink, corridor-side markers with 过道 (aisle) printed beside seats B and C, the official railway emblem—a departing steam locomotive silhouette—stamped in dark blue ink at the top of the chart, the conductor's handwritten annotation in faint pencil at the bottom margin reading "第零号车次·第三排·四座.", torn and irregular edges from being posted on the station wall and torn down and posted again, a single faint red 已检 verification stamp in the top right corner, the paper surface bears water stain rings from condensation on the carriage window |
| 主色 | aged parchment (泛黄铁路文档纸——黄棕调，与检票员旅客名单同质感) |
| 辅色 | deep blue (深蓝印章墨色——检票员制服色调) |
| 点缀色 | dark ink black (黑色打印墨迹——座位标号与网格线，构成座位表的核心信息层) |

---

## 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Railway Carriage Seating Chart,
Dusk Express Carriage No.0 Row 3,
Four-Seat Layout with Center Aisle,
Seats A and B at Left Windowside,
Seats C and D at Right Aisleside,
Departure: Dusk Platform to Nowhere,
Carriage: 第零号车次,

constructed from multiple aged railway notice paper with a folded crease running down the center as the aisle dividing left from right,
four rectangular seat zones cut from slightly darker paper labeled A B C D in stamped serif typewriter ink,
small window icon stamps embossed beside seats A and D with the character 窗 printed in faded dark blue ink,
corridor-side markers with 过道 printed beside seats B and C,
the official railway emblem — a departing steam locomotive silhouette — stamped in dark blue ink at the top of the chart,
the conductor's handwritten annotation in faint pencil at the bottom margin reading words in tiny script,
torn and irregular edges from being posted and torn down and posted again,
a single faint red verification stamp in the top right corner,
the paper surface bears water stain rings from condensation on the carriage window,

each component clearly visible,
assembled from layered paper-cut shapes,
the center aisle crease is the dominant structural element — a vertical fold that splits the chart into two equal halves,
the left half contains seats A and B stacked vertically with a thin window icon connector strip running along the left edge,
the right half contains seats C and D stacked vertically with a thin corridor icon connector strip running along the right edge,
the four seat zones are equal-sized rectangles — identical in shape but labeled differently,
seats A and D are marked with window symbols — small rectangles with an outward light stripe,
seats B and C are marked with aisle symbols — small rectangles with a dotted center line,
the grid lines connecting seat boxes are thin dark ink lines suggesting the carriage floor plan,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,
the center crease is a real fold — the paper was folded in half and then unfolded, leaving a permanent ridge,
the torn edges are irregular — not clean-cut scissors but torn by hand against a ruler edge,

flat graphic symbols,
storybook prop design,
railway notice format,
the chart reads like a diagram — not a photograph, not a 3D model,
it communicates layout, not realism,
each element is symbolic — the window icon, the aisle marker, the seat label — all are graphic signs,

handcrafted paper texture,
aged paper surface,
water stain rings visible at the edges — darker where the paper absorbed moisture longer,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming — a seating chart for a train that may never arrive,

limited color palette,
aged parchment,
deep blue,
dark ink black,

front view,
the chart is flat — no perspective distortion, no depth,
this is unequivocally a 2D diagram — a flat paper notice,
the viewer looks at it straight on, as if reading a posted document,

2D game prop design,
indie RPG environment asset,
train carriage interior detail,

paper-cut illustration,
paper collage art,
flat layered shapes,
flat diagram,
flat chart,
flat notice,
flat document,
seating plan,
seat layout diagram,
train seat map,
railway chart,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,
NO 3D rendering,
NO isometric view,
NO oblique angle,
NO tilted view,
NO orthographic perspective,
NO seat models,
NO physical chairs,
NO dimensional seating,
NO carriage interior rendering,

plain background
```

---

## 设计决策记录

### 1. "座位表≠座位实体图"的实现策略

这是本设计最核心的要求。在提示词中通过三层机制确保：

| 层级 | 机制 | 提示词中的体现 |
|------|------|-------------|
| **正向引导** | 大量使用 diagram/chart/plan 等词 | `seating plan`, `seat layout diagram`, `train seat map`, `railway chart`, `flat diagram`, `flat chart`, `flat notice`, `flat document` |
| **负向排除** | 强化的 negative prompts | `NO seat models`, `NO physical chairs`, `NO dimensional seating`, `NO carriage interior rendering`, `NO 3D rendering`, `NO isometric view`, `NO oblique angle` |
| **视觉锚定** | 折痕、符号、网格线→强调"这是一张纸上的图" | 中央过道折痕将纸张分为两半——这是一张被折叠过的公告，不是从某个角度拍摄的车厢照片 |

### 2. 过道的视觉表现

过道不在图的"内容"里——它是图本身的**结构**：

- 纸张中央有一条纵向折痕（真实折叠展开后的痕迹）
- 左右两半以折痕为界——左侧是A/B座区，右侧是C/D座区
- 折痕在纸雕中表现为一条凹陷的脊线——纸艺折叠-展开后的永久压痕
- 折痕的叙事功能：不仅是结构分隔——也是"分开"的隐喻。左侧靠窗、右侧靠走廊——两个世界被一条不可能被填满的过道永远隔开

### 3. 窗侧与走廊侧的视觉区分

| 座位 | 位置 | 图标 | 含义 |
|------|------|------|------|
| A | 左·窗侧 | 小矩形 + 向外光条纹 | `窗` — Window Side |
| B | 左·走廊侧 | 小矩形 + 中央虚线 | `过道` — Aisle Side |
| C | 右·走廊侧 | 小矩形 + 中央虚线 | `过道` — Aisle Side |
| D | 右·窗侧 | 小矩形 + 向外光条纹 | `窗` — Window Side |

窗侧图标的光条纹方向均向外（A向左、D向右）——暗示"窗外有光"。

### 4. 纸雕分层结构（从底到顶）

1. **票基纸层**：泛黄铁路公告纸（aged parchment 底色 + 水渍环纹理）
2. **折痕层**：中央纵向折痕（半透明压痕凹印——不是画上去的线，是纸被折过的物理痕迹）
3. **网格线层**：深墨色细线——座位区域边框 + 左窗边连接条 + 右走廊连接条
4. **座位标号层**：A B C D 四个字母——深墨色打字机字体纸片
5. **图标层**：窗图标（2个）+ 走廊图标（2个）——深蓝印章色
6. **徽章/印章层**：铁路徽章（顶部中央）+ 已检红章（右上角）
7. **手写注释层**：铅笔字——检票员手写"第零号车次·第三排·四座."（底边）

### 5. 与NPC座位系统的关联

在现有碎片#0002设计中，第三排五座的车票分配为：

| NPC | 票 | 座位 | 位置 |
|-----|---|------|------|
| 老教师 | 3A | A | 左·窗侧 |
| 商人 | 3B(备用) | B | 左·窗侧 |
| 卖花女 | 3C | C | 中间 |
| 年轻士兵 | 3D | D | 右·走廊侧 |
| 小女孩 | 3E | E | 右·走廊侧 |
| 检票员 | 3B(真) | B | — |

四座座位表的'缺席'意味着：如果这个座位表用于"第零号车次"——那个检票员等了无数年的列车——它只有四个座位。五个等车的人中，至少有一个**必然不能上车**。这不是技术限制——这是**织女·太一的原初设计**：她创造车站时就知道——不是所有人都能走。但她不知道该怎么选择——所以她把选择权交给了玩家。

---

> *四座车厢座位表提示词设计文档 — 结束 | 配套文件：`0002_物品清单.md`、`0002_env_seat_map_board`（五座展示牌）、`fragment_0002.md`*
