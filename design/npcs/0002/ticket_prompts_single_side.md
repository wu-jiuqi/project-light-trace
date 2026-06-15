# 碎片#0002「黄昏驿站」— 车票纸雕提示词（单面设计）

> **设计基准**：`fragment_0002.md §4.2 车票羁印系统` + `papercraft-item-gen` 技能模板
> **设计原则**：将原车票正反两面（票面信息 + 羁印水纹）合并到单面纸雕构图中。羁印以半透明水印/压痕形式叠加于票面文字之上。
> **最后更新**：2026-06-14

---

## 设计理念：为何单面

原设计中车票分正反两面：
- **正面**：离站信息、发车时间、座位号、旅客姓名
- **背面**：羁印水纹（情感重量的物理化印记）

合并到单面的理由是：在纸雕美术风格下，**羁印作为半透明压痕水印直接叠加在票面文字之上**，比"翻转"更直观地传达"这张票承载的情感重量"。玩家看到的不再是"正面是信息-背面是情感"的二分，而是**信息被情感渗透、覆盖、甚至淹没**的完整叙事。这更符合碎片#0002的核心主题：离别不是一件事的两个面，而是一个同时发生的完整状态。

---

## 票面统一字段规范

每张车票单面保留以下文本/视觉元素（纸雕以刻字、印章或手写墨迹呈现）：

| 字段 | 格式 | 呈现方式 |
|------|------|---------|
| 离站 | 「离站」 | 顶部铁路徽标 + 宋体刻字 |
| 发车时间 | `发车时间：17:47 → ∞` | 印章或打字机字体 |
| 座位号 | `座位号：3A / 3B / 3C / 3D / 3E` | 粗体数字 + 窗侧/走廊标记 |
| 旅客 | `旅客：______` | 手写墨迹（各NPC字迹风格不同） |
| 羁印 | 水纹层数/特征 | 半透明压痕水印，叠加在票面上 |
| 特殊标记 | 各NPC独有 | 见各票独立设计 |

灰色-橙色全局色调环境，每张票保留纸雕质感和对应NPC的核心配色。

---

## 一、NPC #01 老教师 — 3A号车票「空白之等」

### 角色特征提炼（源自独白设计）
- 国文教师退休，72岁，一辈子教《背影》
- 等儿子的"等"已从行为变成存在本身
- 空白书——每一页都读过，然后把字擦掉了
- "放在纸上太重了，放在心里刚刚好"
- 羁印最深（4层），最外层泛金——等得太久，涟漪变成了金色

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Aged Train Ticket Seat 3A — Old Teacher's Ticket of Eternal Waiting, Departure Station: Dusk Platform, Time: 17:47 to Infinity, Passenger name in fading calligraphy ink |
| 主题物 | torn rice paper pages from a blank book, four-layer concentric water ripple marks pressed into the paper as translucent embossed watermarks, outermost ripple ring tinged with faint gold, brass-rimmed glasses chain coiled at the ticket corner, a single dried osmanthus flower petal pressed flat, stitched cloth book cover texture at the ticket edges |
| 主色 | aged gray (aged rice paper tone) |
| 辅色 | warm beige (sunlight-bleached paper edge) |
| 点缀色 | antique brass (golden tinge on the outermost ripple + glasses chain) |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Aged Train Ticket Seat 3A,
Old Teacher's Ticket of Eternal Waiting,
Departure Station: Dusk Platform,
Time: 17:47 to Infinity,
Passenger name in fading calligraphy ink,

constructed from multiple torn rice paper pages from a blank book,
four-layer concentric water ripple marks pressed into the paper as translucent embossed watermarks,
outermost ripple ring tinged with faint gold,
brass-rimmed glasses chain coiled at the ticket corner,
a single dried osmanthus flower petal pressed flat,
stitched cloth book cover texture at the ticket edges,

each component clearly visible,
assembled from layered paper-cut shapes,
the water ripples are translucent embossed layers sitting on top of the ticket text,
the ripples grow more spaced apart — first three layers tight, fourth layer stretched open,
the outermost edge catching light like aged gold leaf,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format with railway emblem at top,
seat number 3A printed in large bold type with "WINDOW SIDE" mark,
departure time 17:47 stamped in faded typewriter ink,

handcrafted paper texture,
aged paper surface,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming,

limited color palette,
aged gray,
warm beige,
antique brass,

front view,

2D game prop design,
indie RPG asset,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 二、NPC #02 年轻士兵 — 3D号车票「队列之裂」

### 角色特征提炼（源自独白设计）
- 边防军上等兵，22岁，守C-11门六年
- 空弹夹比满的更重——因为空的你得自己填
- 羁印3层，纹路笔直如队列——但第三层边缘有一处断裂："队列中有人踏错了一步"
- "站过了——就是站过了"
- 羁印够深(3层)，却被排在3D走廊侧——被挤到了不该在的位置

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Military Train Ticket Seat 3D — Young Soldier's Ticket of Broken Formation, Departure Station: Dusk Platform, Time: 17:47 to Infinity, Passenger: 陆██ in rigid disciplined handwriting, rank insignia stamped at corner |
| 主题物 | military duffel bag canvas fabric texture forming the ticket base, three-layer straight parallel water ripple marks with the third layer's edge fractured and broken, empty magazine metal imprint pressed into the paper corner, torn shoulder patch fragment with scraped-off lettering stitched onto the ticket edge, a single grain of border sand embedded in paper fiber, leather strap texture binding the ticket edges |
| 主色 | deep green (military uniform tone) |
| 辅色 | dusty skin (sand-worn paper edge) |
| 点缀色 | brass (uniform button + empty magazine metal shine) |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Military Train Ticket Seat 3D,
Young Soldier's Ticket of Broken Formation,
Departure Station: Dusk Platform,
Time: 17:47 to Infinity,
Passenger 陆██ in rigid disciplined handwriting,
rank insignia stamped at corner,
Note scrawled in margin: "Report back by 0530. Do not be late.",

constructed from multiple military duffel bag canvas fabric texture forming the ticket base,
three-layer straight parallel water ripple marks with the third layer's edge fractured and broken,
empty magazine metal imprint pressed into the paper corner,
torn shoulder patch fragment with scraped-off lettering stitched onto the ticket edge,
a single grain of border sand embedded in paper fiber,
leather strap texture binding the ticket edges,

each component clearly visible,
assembled from layered paper-cut shapes,
the water ripples are straight and evenly spaced like soldiers in formation,
the third ripple has a sharp jagged break — one soldier stepped out of line,
the break catches no light — it absorbs it,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format, seat 3D in bold with "CORRIDOR SIDE" mark,
the torn shoulder patch pinned to the ticket like a field dressing,

handcrafted paper texture,
aged paper surface,
canvas weave texture visible at edges,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming,

limited color palette,
deep green,
dusty skin,
brass,

front view,

2D game prop design,
indie RPG asset,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 三、NPC #03 卖花女 — 3C号车票「花瓣之弧」

### 角色特征提炼（源自独白设计）
- 流动花贩，25岁，只种矢车菊
- "花压久了颜色反而深——因为花不逃"
- "花能做到的事我不敢做——我不敢停在没风的地方等自己开"
- 羁印2层，纹路柔和呈曲线——像花瓣在纸面上展开的轮廓，颜色是极淡的蓝（花粉渗入纸纤维）
- 羁印和座位匹配：2层→3C中座，"刚刚好"

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Floral Train Ticket Seat 3C — Flower Girl's Ticket of Blossom Curves, Departure Station: Dusk Platform, Time: 17:47 to Infinity, Passenger: 花小姐 in flowing cursive handwriting, pale blue cornflower pollen dusted across the ticket surface |
| 主题物 | dried cornflower petals pressed between paper layers, two-layer curved water ripple marks flowing like flower petal outlines with pale blue tint from pollen seepage, copper watering can spout dent pressed into one corner, woven hemp cord texture as the ticket border, a single petal with a natural hole — light passes through leaving a pale spot, copper wire threaded through a punched hole |
| 主色 | cornflower blue (pale blue of pollen-stained ripple) |
| 辅色 | warm beige (sun-bleached basket paper) |
| 点缀色 | copper (watering can + wire) |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Floral Train Ticket Seat 3C,
Flower Girl's Ticket of Blossom Curves,
Departure Station: Dusk Platform,
Time: 17:47 to Infinity,
Passenger 花小姐 in flowing cursive handwriting,
pale blue cornflower pollen dusted across the ticket surface,
Seat 3C marked "MIDDLE — just right.",

constructed from multiple dried cornflower petals pressed between paper layers,
two-layer curved water ripple marks flowing like flower petal outlines with pale blue tint from pollen seepage,
copper watering can spout dent pressed into one corner,
woven hemp cord texture as the ticket border,
a single petal with a natural hole — light passes through leaving a pale spot,
copper wire threaded through a punched ticket validation hole,

each component clearly visible,
assembled from layered paper-cut shapes,
the water ripples are soft curves — not mechanical circles but organic petal contours,
the blue tint is irregular — deeper where pollen accumulated, fainter at the ripple edges,
the hole-petal aligned so that the watermark gap and the actual hole create a continuous empty space,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format, the hemp cord border is slightly frayed at one end,

handcrafted paper texture,
aged paper surface,
delicate petal paper texture visible at edges,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming,

limited color palette,
cornflower blue,
warm beige,
copper,

front view,

2D game prop design,
indie RPG asset,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 四、NPC #04 商人 — 3B号(备用)车票「借来的等」

### 角色特征提炼（源自独白设计）
- 后天枢遣散员工，48岁，编了二十年"商人"剧本
- "我的合同——没有包书皮"
- "如果这个故事是我编的——那二十年前在我开始编之前——我是谁？"
- 羁印仅1层残影，边缘模糊，几乎无法辨认——因为这不是他的票
- 残影深处有褪色水印小字："备用·原票主已注销"
- 羁印最浅，却占了3B靠窗侧——这是借来的位置

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Standby Train Ticket Seat 3B — Merchant's Ticket of Borrowed Waiting, Departure Station: Dusk Platform, Time: 17:47 to Infinity, Passenger: 钱██ in rapid business handwriting then scratched out and rewritten, STANDBY stamp in red ink, faded watermark text reading "备用·原票主已注销" barely visible beneath the ripple |
| 主题物 | blank contract paper with ghost watermark of old corporate insignia torn into ticket shape, single-layer faded water ripple so faint it is almost invisible — just a ghost ring catching light at one angle, leather briefcase strap imprint across the ticket middle, metal buckle mark dented into one edge, a stopped watch face (17:47) printed faintly as a watermark behind the seat number, the words "不妨告诉你" (May as well tell you) scrawled in the margin then crossed out, gold pen nib imprint at the ticket corner |
| 主色 | deep blue (business suit tone) |
| 辅色 | cream white (blank contract paper) |
| 点缀色 | gold (pen nib + faint corporate watermark gleam) |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Standby Train Ticket Seat 3B,
Merchant's Ticket of Borrowed Waiting,
Departure Station: Dusk Platform,
Time: 17:47 to Infinity,
Passenger 钱██ in rapid business handwriting then scratched out and rewritten with a trembling hand,
STANDBY stamp in red ink bleeding slightly at the edges,
faded watermark text reading "备用·原票主已注销" barely visible beneath the ripple,

constructed from multiple blank contract paper with ghost watermark of old corporate insignia torn into ticket shape,
single-layer faded water ripple so faint it is almost invisible — just a ghost ring catching light at one angle,
leather briefcase strap imprint across the ticket middle,
metal buckle mark dented into one edge,
a stopped watch face showing 17:47 printed faintly as a watermark behind the seat number,
the words inked in margin then crossed out heavily,
gold pen nib imprint at the ticket corner,

each component clearly visible,
assembled from layered paper-cut shapes,
the single water ripple is barely there — so close to disappearing,
it catches light only at a specific angle — like a memory that only surfaces when you are not looking,
the STANDBY stamp bleeds red into the paper — the ink was pressed too hard by someone desperate,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format with seat 3B printed boldly with "WINDOW SIDE" — but crossed out and rewritten as "HALF WINDOW — half a view",
the watch face watermark behind the seat number — stopped at the exact moment this ticket stopped belonging to anyone,

handcrafted paper texture,
aged paper surface,
corporate letterhead paper texture visible at edges,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming,

limited color palette,
deep blue,
cream white,
gold,

front view,

2D game prop design,
indie RPG asset,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 五、NPC #05 小女孩 — 3E号车票「光之闪烁」

### 角色特征提炼（源自独白设计）
- 7岁，独自等妈妈，"看光的人"
- "糖还没化——就还没过'很快'"
- "妈妈会不会也是光——不想闪的时候不闪？"
- 把车票折成纸飞机——展开后票背画了大人拉着小孩的手（大人没有脸）
- 羁印1层极薄透明水纹，含极小的闪烁光点——与铁轨尽头的光同步
- "褪不掉的颜色——就是有人在等你的颜色"

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | Child's Train Ticket Seat 3E — Little Girl's Ticket of Light Sparkles, Departure Station: Dusk Platform, Time: 17:47 to Infinity, Passenger: 豆豆 in wobbly pencil handwriting, a crayon drawing of two stick figures holding hands — the taller figure has no face, the ticket has been folded into a paper airplane and unfolded — crease lines visible |
| 主题物 | colored candy wrapper fragments (red, blue, yellow) embedded in the paper, single-layer transparent water ripple so thin it is nearly invisible — but tiny light sparkles dance within the ripple synchronized with some distant signal, chalk dust smeared in the margin, paper airplane fold creases crossing the ticket in an X, crayon drawing of two figures holding hands pressed into the paper — the adult figure has no face, half a pink eraser fragment pressed into one corner, a single unwrapped candy sitting on the ticket surface |
| 主色 | brick red (pinafore dress tone) |
| 辅色 | cream white (child's notebook paper) |
| 点缀色 | multicolor candy wrapper — red, blue, yellow — the only fully saturated colors in a gray-orange world |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

Child's Train Ticket Seat 3E,
Little Girl's Ticket of Light Sparkles,
Departure Station: Dusk Platform,
Time: 17:47 to Infinity,
Passenger 豆豆 in wobbly pencil handwriting — the characters are uneven, written by a child still learning,
a crayon drawing of two stick figures holding hands — the taller figure has no face,
the ticket has been folded into a paper airplane and unfolded — diagonal crease lines cross the surface,
Seat 3E marked "CORRIDOR — closest to the light",

constructed from multiple colored candy wrapper fragments, red blue yellow, embedded in the paper layers,
single-layer transparent water ripple so thin it is nearly invisible,
tiny light sparkles dancing within the ripple — tiny silver foil dots that catch and release light,
chalk dust smeared in the margin where she drew a wobbly Morse code,
paper airplane fold creases crossing the ticket in an X pattern,
crayon drawing of two figures holding hands pressed into the paper — the adult figure has no face,
half a pink eraser fragment pressed into one corner,
a single unwrapped candy sitting on the ticket surface — the wrapper is the only full-color object,

each component clearly visible,
assembled from layered paper-cut shapes,
the water ripple is almost not there — transparent like a film of water that has not yet decided to be seen,
the light sparkles within are tiny dots of silver foil — they wink at the same rhythm as a distant signal light,
the candy wrapper is red, blue, and yellow in a world where everything else is gray-orange — it does NOT fade,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format — but the ticket has been loved and folded and unfolded so many times the edges are soft,
the crease lines from the paper airplane are not damage — they are its shape now,

handcrafted paper texture,
aged paper surface,
notebook paper texture visible at edges,

dark fairy tale,
surreal whimsical object,
slightly eerie but charming — a child's artifact in a world of adults waiting,

limited color palette,
brick red,
cream white,
multicolor candy wrapper — red, blue, yellow,

front view,

2D game prop design,
indie RPG asset,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 六、玩家车票 / 源印 — 真正的3B票「归途之印」

### 角色特征提炼（源自检票员独白 + 碎片终局）
- 这是检票员从腰间掏出的第六张票——真正的3B票
- 不是给坐车的人，是给"理解离别"的人
- 票面：离站→∞ / 发车时间：— / 座位号：3B / 备注：不返回
- 票背：归途之印——暗金色站台徽章，徽章上的列车向远处驶去（而非驶来）
- 羁印完整——因为这张票吸收了检票员对所有旅人的"羁"
- 这是源印（Source Seal），是AI「织女·太一」留在碎片#0002的数字签名

### 提示词字段

| 字段 | 内容 |
|------|------|
| 物品名称 | True Train Ticket Seat 3B — Light Tracer's Ticket of Homecoming Seal, the Source Seal of Fragment 0002, Departure: Departure Station going to Infinity, Time: — (no time — this ticket transcends the frozen 17:47), Seat 3B, Note: 不返回 Does Not Return, Passenger field is blank — waiting for the one who understands parting, the dark gold Homecoming Seal glows on the surface — a train departing into the distance, not arriving |
| 主题物 | conductor's passenger list paper — the sixth entry "检票员·不候车" with no punch hole — torn and embedded as the ticket base, complete multi-layer water ripples absorbing the bond marks of all five travelers — deep and luminous, dark gold metallic foil seal depicting a train departing into the distance, rusted punch tool mark at the ticket edge — the first punch in years, railway ticket stub with "3B" printed in gold, a single hand-drawn tally mark in the margin — the first count of a new cycle, the conductor's pencil mark: "已候. 第零号车次. 3B. 归途." written in a rehearsed but trembling hand |
| 主色 | deep blue (conductor's uniform — the one who kept the ticket) |
| 辅色 | aged parchment (passenger list paper — yellowed from years of waiting) |
| 点缀色 | dark gold (归途之印 metallic foil — the only real metallic surface in the gray-orange world) |

### 完整英文提示词

```
masterpiece,
highly detailed 2D papercraft illustration,

True Train Ticket Seat 3B,
Light Tracer's Ticket of Homecoming Seal,
The Source Seal of Fragment 0002 — Dusk Platform,
Departure: Departure Station going to Infinity,
Time: — (no time — this ticket transcends the frozen 17:47),
Seat 3B — the true 3B, not borrowed, not standby, not waiting,
Note: 不返回 Does Not Return,
Passenger field is blank — waiting for the one who understands parting,

constructed from multiple conductor's passenger list paper — the sixth entry "检票员·不候车" with no punch hole — torn and embedded as the ticket base,
complete multi-layer water ripples absorbing the bond marks of all five travelers — deep and luminous,
dark gold metallic foil seal depicting a train departing into the distance — not arriving, not waiting, finally moving,
rusted punch tool mark at the ticket edge — the first punch in years,
railway ticket stub with "3B" printed in gold,
a single hand-drawn tally mark in the margin — the first count of a new cycle,
the conductor's pencil mark scrawled at the bottom: "已候. 第零号车次. 3B. 归途." — written in a rehearsed but trembling hand,

each component clearly visible,
assembled from layered paper-cut shapes,
the water ripples are complete and luminous — NOT translucent ghost marks like the other tickets,
they have absorbed the waiting of five people and the watching of one conductor,
the ripples glow from within — not with light but with the weight of being seen,
the dark gold seal is a separate layer — real metallic foil paper, the only true metallic surface in this gray-orange world,
the train on the seal faces AWAY — it is not coming to pick anyone up, it is leaving, and that is the point,

paper collage construction,
patchwork assembly,
stitched seams,
decorative folds,
visible paper edges,

flat graphic symbols,
storybook prop design,
ticket stub format — but this ticket has never been folded, never been crumpled, never been held by someone who did not understand,
the passenger list paper beneath is torn not damaged — torn with purpose,

handcrafted paper texture,
aged paper surface,
passenger list paper texture visible at edges — the grid lines of six names with only five punched,

dark fairy tale,
surreal whimsical object,
slightly eerie but deeply meaningful — this is not a ticket, this is a key,

limited color palette,
deep blue,
aged parchment,
dark gold — the gold is metallic, not printed, the only real metal in this world,

front view,
the seal is the focal point — everything else on the ticket recedes behind its glow,

2D game prop design,
indie RPG key item asset,
SOURCE SEAL — this is the most important item in Fragment 0002,

paper-cut illustration,
paper collage art,
flat layered shapes,

NO perspective depth,
NO realistic shadows,
NO volumetric lighting,
NO sculpture,
NO toy,
NO photograph,
NO 3D object,

plain background
```

---

## 七、设计决策记录

### 7.1 羁印与票面的空间关系

| 票 | 羁印位置 | 票面文字与羁印的关系 |
|----|---------|-------------------|
| 老教师 3A | 四层同心涟漪覆盖票面中央 | 涟漪最外层扩展至票面边缘——"离站"和"17:47"被涟漪包围但不被遮盖。文字在涟漪之上（纸雕分层：票面文字层 > 羁印水印层 > 票基纸层） |
| 士兵 3D | 三层直线水纹横向排列 | 水纹与座位号"D"重叠——断裂处正好在"D"字右侧，形成"D（裂）"的视觉 |
| 卖花女 3C | 两层花瓣形曲线从中央展开 | 曲线与"3C"数字交错——数字在花瓣弧线的凹陷处 |
| 商人 3B(备用) | 一层残影环几乎不可见 | 残影环在"3B"字样周围隐约可见——只有在特定角度才能看到，呼应"记忆被删除但水印还记得" |
| 小女孩 3E | 一层透明水纹 + 闪烁光点 | 光点散布在整张票面——包括文字上方。文字和光点不分层——"她相信光在每一个字里" |
| 玩家 3B(真) | 完整多层涟漪 + 归途之印金属箔 | 归途之印覆盖在票面中央——它是主角。文字退居票面边缘 |

### 7.2 NPC配色与车票配色的呼应

每位NPC的车票配色延用其角色提示词配色（来自 `提示词.md`），确保视觉一致性：

| NPC | 角色主色/辅色/点缀色 | 车票主色/辅色/点缀色 | 对应关系 |
|-----|-------------------|-------------------|---------|
| 老教师 | aged gray / warm beige / antique brass | aged gray / warm beige / antique brass | 完全一致 |
| 士兵 | deep green / dusty skin / brass | deep green / dusty skin / brass | 完全一致 |
| 卖花女 | cornflower blue / warm beige / copper | cornflower blue / warm beige / copper | 完全一致 |
| 商人 | deep blue / cream white / gold | deep blue / cream white / gold | 完全一致 |
| 小女孩 | brick red / cream white / multicolor | brick red / cream white / multicolor | 完全一致 |
| 玩家票 | (无对应NPC) | deep blue / aged parchment / dark gold | 检票员配色：deep blue / pale skin → aged parchment / silver → dark gold。deep blue来自检票员制服，dark gold是归途之印专属 |

### 7.3 "单面"的纸雕实现

在纸雕美术风格下，"单面设计"意味着：
- 一张完整的纸雕卡片（类似扑克牌尺寸的扁平矩形）
- 羁印以**半透明压痕层**叠加在票面文字之上（物理上：多层半透明纸叠加，下层是票面文字，上层是水纹压痕）
- 羁印不是"印在背面"——它是**渗透**进票面纸纤维的水渍，文字和情感印在同一张纸上
- 纸雕分层顺序（从底到顶）：
  1. 票基纸层（配色基底色纸 + 磨损纹理）
  2. 羁印水印层（半透明纸 + 压痕/凹印）
  3. 票面文字层（墨水/印章/刻字纸片）
  4. NPC专属物品层（眼镜链/弹夹/花瓣/合同纸/糖纸/归途之印箔片）

---

> *车票提示词设计文档 — 结束 | 配套文件：`fragment_0002.md`、各NPC角色设计文档、`提示词.md`*
