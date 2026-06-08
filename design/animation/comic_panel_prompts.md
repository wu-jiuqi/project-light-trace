# 开场动画漫画版 — AI 分镜提示词全集

> **版本**：V1.0
> **状态**：设计定稿 | 待逐个生成
> **关联文档**：
> - `opening_cinematic_design.md` — 完整分镜脚本（剧情来源）
> - `提示词.md` — 单场景版提示词（风格参考）
> - `../../art/papercraft/style_bible.md` — 纸工拼贴 Style Bible
> - `papercraft-building-gen` / `papercraft-character-gen` / `papercraft-item-gen` — 提示词结构参考

---

## 〇、漫画形式的整体设计思路

### 为什么用漫画

原方案使用 Godot AnimationPlayer + 多层 CanvasLayer 实现动态镜头（推拉摇移 + 纸片层次位移）。切换为漫画形式后：

- **动画逻辑**：不再是"摄像机在纸板舞台上移动"，而是"读者翻阅若干张漫画格"
- **时间控制**：从"秒级动画时间轴"变为"视觉节奏——大格慢读、小格快翻"
- **旁白**：从"AI 女声配音"变为"漫画格上方的叙述性文字框 / 旁白气泡"
- **音效**：漫画不需要音效（后续可配合 BGM 形成动态漫画，但首版为静态漫画页）

### 漫画页与分镜格划分

全开场动画共 **6 页、13 格**：

```
第1页「万象」       格1（全页竖幅）身份确认
                   格2（跨页横幅）万象全景

第2页「47亿」       格3（方幅）手握咖啡杯
                   格4（方幅）小孩秋千
                   格5（方幅）老人手部

第3页「碎裂」       格6（跨页横幅）纸板碎裂——裂缝蔓延
                   格7（横幅）十二碎片分离

第4页「任务」       格8（方幅）0001碎片高亮
                   格9（竖幅）档案夹翻开——任务简报

第5页「警告」       格10（横幅）红色印章"注意"
                   格11（小幅）老顾剪影闪现

第6页「谎言」       格12（方幅）天枢logo + 冥府协议闪现
                   格13（跨页横幅）过渡到星图
```

### 提示词格式约定

每个漫画格提示词遵循统一的六段结构：

```
1. 品质标签（masterpiece, highly detailed...）
2. 主体内容描述（这格画什么）
3. 纸工构造细节（材质、裁切、固定件）
4. 风格标签（纸板舞台、纸工绘本）
5. 色彩定义（主色、辅色、点缀色）
6. 构图与画幅
7. 负面提示词（NO dark fairy tale, NO 3D...）
```

**风格红线**：
- 本项目是「纸板舞台 / 纸工绘本 / 暖光纸偶」——**不是暗黑童话**
- 材质族：kraft paper（牛皮纸）/ gray_card（灰白卡纸）/ book_page（旧书页）/ fiber_paper（粗纤维纸）/ tracing_paper（描图纸）/ foil（银箔纸）/ fasteners（铆钉线绳）
- 光源：暖金色顶光（左上→右下短影）
- 禁止：gothic / cyberpunk / steampunk / eerie / 纯黑阴影 / 光滑矢量边 / 写实3D

---

## 一、第1页「万象」

> **页面节奏**：格1竖幅——玩家首先看到自己的"编号"被确认；然后翻到格2，万象全景像一张摊开的地图从眼前展开。从极小（一行字）到极大（一座纸板城市）的尺度跳跃制造"世界很大"的第一印象。

---

### 格 1 — 身份确认

```
文件名：comic_panel_01_identity.png
尺寸：1024×1536（竖幅 2:3——漫画格中"窄高格"用于强调孤独感/被审视感）
旁白框："编号 TP-2077-03-溯光者。身份确认。"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A vertical comic panel with a dark gray cardboard surface filling the frame,
a single thin line of fiber text glowing faintly through translucent tracing paper at the center,

the text "TP-2077-03-溯光者" formed by extremely thin tracing paper cutouts,
backlit by a very faint pale golden light seeping through the fiber gaps,
the tracing paper text semi-transparent, showing paper veins and fiber strands,

the dark gray cardboard background has subtle horizontal paper grain lines,
no other visual elements — minimal, stark, clinical,

the composition is sparse and centered,
the text occupies only about 5% of the frame near the vertical center,
massive negative space above and below — the paper void,

paper-cut typography,
tracing paper backlight effect,
paper grain texture,
minimalist papercraft,

limited palette: dark charcoal gray cardboard, pale translucent gold, off-white tracing paper,

vertical composition, centered text,
2D game comic panel, papercraft sequential art,
comic frame with rough paper-cut panel border,

NO dark fairy tale,
NO eerie atmosphere,
NO gothic elements,
NO digital screen UI,
NO neon glow,
NO 3D text,
NO realistic paper,
NO decorative elements,
NO perspective depth,
NO pure black void — the dark gray must show paper texture,

plain dark gray cardboard background
```

**叙事功能**：
- 竖幅的窄高比例制造"被审视/被编号"的压迫感
- 极少的视觉信息——"你是一串编号，你不是第一个"
- 描图纸透光 = 系统内部的数据显示，不是印刷品

---

### 格 2 — 万象全景

```
文件名：comic_panel_02_panorama.png
尺寸：1920×1080（跨页横幅 16:9——全页最宽的格，模拟"地图展开"的视觉冲击）
旁白框："万象——人类迄今最大规模的数字现实平台。
         四十七亿人的记忆、情感与生活，被安全保存于此。"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A wide horizontal comic panel showing a sprawling papercraft city diorama seen from a high angle,

city blocks assembled from layered kraft paper and gray cardboard sheets,
buildings constructed from cut and folded paper components with visible paper edges,
rooftops showing irregular scissor-cut contours,

a winding river flowing through the city, made of translucent pale blue tracing paper,
the river's tracing paper texture visible with semi-transparent fiber veins,

scattered dark green and deep brown fiber paper tree silhouettes planted among buildings,
trees held in place by tiny visible twine strings or brass fasteners on the paper base,

extremely tiny paper figure silhouettes scattered on streets,
each figure is a single flat paper-cut shape with twine joints — frozen, not moving,

warm pale golden light coming from the upper-left corner,
every paper piece casting a short shadow to the lower-right,
shadows are warm-gray, never pure black,

the entire diorama mounted on a large sheet of gray cardboard,
the framing edges of the comic panel showing the raw irregular scissor-cut paper edge of the diorama base,

paper collage construction,
paper-cut illustration,
flat layered paper shapes,
paper model landscape,
handcrafted diorama aesthetic,
storybook map illustration,
paper stage comic panel,

warm kraft brown, gray-white cardboard, pale golden light, transparent tracing paper blue, muted fiber paper dark green,

high-angle bird's eye view (not top-down — about 60 degrees, like looking down at a tabletop model),
comic panel composition filling the full horizontal width,

2D game comic panel, papercraft sequential art,
comic frame with rough kraft paper edge border,

NO dark fairy tale,
NO eerie atmosphere,
NO gothic elements,
NO cyberpunk neon,
NO steampunk gears,
NO volumetric 3D lighting,
NO realistic CGI shadows,
NO plastic or rubber texture,
NO pure black shadows,
NO smooth vector edges,
NO realistic city rendering,
NO perspective depth (keep flat paper layers),

plain gray cardboard surface extending slightly beyond the diorama edge, serving as the comic panel background
```

**叙事功能**：
- 跨页横幅 = 地图的展开。"这是一个被放在桌上的模型"
- 纸片人影是静止/冻结的——"他们被保存了，也被冻结了"
- 纸板边缘的毛糙裁切暗示"这个模型是被人放在这里的"
- "被安全保存于此"——通关后回看：安全是你第一件要质疑的事

---

## 二、第2页「47亿」

> **页面节奏**：三格等大方幅并排，像一个三联画。同一页面上的三格"生活瞬间"形成了"咖啡→童年→暮年"的时间轴暗线。格间用极细的黑色分隔线（模拟漫画格间距），但也可以用纸板撕边作为分格线。

---

### 格 3 — 手握咖啡杯

```
文件名：comic_panel_03_coffee_hand.png
尺寸：1024×1024（方幅 1:1——三联画的左格）
旁白框："2077年3月15日。"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A square comic panel showing a close-up of a single human hand holding a white coffee cup,

the hand constructed from textured fiber paper, with visible paper grain folds simulating skin creases,
finger joints connected by tiny twine strings,
the hand's paper layers clearly visible at the wrist edge where the cut was made,

the coffee cup made from white-gray cardboard, a simple cylindrical paper form,
with a slightly irregular hand-cut edge at the rim,
a faint red lipstick mark on the cup rim — rendered as a translucent tracing paper overlay in pale red, semi-transparent like tissue paper,

the desk surface beneath is an aged book page with faint printed text lines,
slight yellowing at the page edges,

warm yellow side light from the left, casting a short soft shadow to the right,
the light making the fiber paper hand feel warm and alive,

paper collage construction,
paper-cut illustration,
visible paper layers and seams,
handcrafted texture,
intimate still life,
quiet domestic scene,
paper stage comic panel,

limited palette: warm fiber paper beige, white-gray cardboard, pale tracing paper red, aged book page cream, warm yellow light,

close-up, slightly angled from above,
comic panel with rough paper-cut border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO eerie atmosphere,
NO gothic elements,
NO realistic human hand,
NO photograph,
NO 3D rendering,
NO glossy ceramic,
NO dark shadows,
NO horror aesthetic,

plain aged book page surface extending as the panel background
```

**叙事功能**：
- "日常——你我也曾这样握着杯子"
- 口红印 = 不是"一个人"，是一个具体的人
- 通关后回看：47亿份被织女保存的记忆片段之一

---

### 格 4 — 小孩秋千

```
文件名：comic_panel_04_child_swing.png
尺寸：1024×1024（方幅 1:1——三联画的中间格）
旁白框：（无旁白——这是画面3的延续，只有画面没有文字）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A square comic panel showing a small paper child on a swing, seen from a slight distance,

the child is a single flat paper doll, body cut from warm fiber paper,
hair made of torn kraft paper strips with raw torn edges,
simple paper-cut facial features with white cardboard outline,

the swing seat is a rectangular gray cardboard piece,
suspended by two twine strings from a kraft paper tree branch above,
the twine threaded through tiny holes in the cardboard,

background showing a blurred papercraft park scene:
trees as fiber paper silhouettes, benches as simple gray cardboard cutouts,
all deliberately rendered with softer edges to suggest depth through layered paper distance,

outdoor warm afternoon light, golden with a slight green tint from leaf reflection,
the child figure casting a soft shadow downward,

paper collage construction,
paper-cut doll,
paper diorama scene,
storybook illustration,
handcrafted paper texture,
nostalgic childhood scene,
paper stage comic panel,

limited palette: warm fiber paper beige, kraft paper brown, gray cardboard, muted leaf green, warm golden afternoon light,

slightly pulled-back view — the child is not the only thing in frame, the empty park occupies about 60%,
comic panel with rough paper-cut border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO eerie atmosphere,
NO realistic child photograph,
NO 3D rendering,
NO gothic elements,
NO horror aesthetic,
NO detailed facial features that would break the papercraft style,

plain warm off-white paper background
```

**叙事功能**：
- "童年——不是'数字'，是某个人的孩子"
- 空荡的公园占画面60%——暗示"本应有很多孩子在这里，但现在只有一个"
- 第2页三格从左到右：咖啡（成人）→ 秋千（童年）→ 老人手（暮年）——一条隐形的生命时间轴

---

### 格 5 — 老人手部

```
文件名：comic_panel_05_old_hands.png
尺寸：1024×1024（方幅 1:1——三联画的右格）
旁白框："凌晨3点15分。"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A square comic panel showing two pairs of elderly hands resting together,
one pair on top of the other, cropped close-up,

the hands constructed from textured fiber paper,
with deep paper grain folds and creases simulating aged skin wrinkles,
finger joints connected by tiny brass rivets,

the four layers of paper hands stacked,
with visible paper shadows between each layer showing the paper thickness,
each layer slightly offset, creating a sense of paper depth,

the desk surface beneath is an aged book page,
edges slightly yellowed and worn,
the book page texture extending to the panel edges,

warm yellow desk lamp light from above and slightly to the left,
softer and dimmer than the coffee hand scene,
casting gentle paper shadows between the stacked hands,

paper collage construction,
paper-cut illustration,
visible paper layers and seams,
handcrafted texture,
intimate still life,
quiet domestic tenderness,
paper stage comic panel,

limited palette: warm aged fiber paper beige, muted brass, aged book page cream, soft warm yellow desk light,

close-up, slightly angled from above,
comic panel with rough paper-cut border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO eerie atmosphere,
NO realistic hands,
NO photograph,
NO 3D rendering,
NO glossy surface,
NO dark shadows,
NO horror aesthetic,
NO gothic elements,

plain aged book page surface extending as the panel background
```

**叙事功能**：
- "暮年——不是'数据'，是握了一辈子的手"
- 四层纸片叠在一起的手 = 纸层的投影可见——"两个人，一辈子"
- 三联画的最后一格。读完第2页，玩家已经见过三张脸孔。"47亿"不再是数字

---

## 三、第3页「碎裂」

> **页面节奏**：格6跨页横幅——裂缝从画面中央爆发，纸板被撕开的冲击力占据整页宽度。格7横幅展示十二碎片分离后的悬停状态。从"完整"到"碎裂"的视觉跳跃是全场最强的情绪转折。

---

### 格 6 — 纸板碎裂：裂缝蔓延

```
文件名：comic_panel_06_shatter.png
尺寸：1920×1080（跨页横幅 16:9——全场最宽的格之一，"碎裂"需要最大画幅来承载视觉冲击）
旁白框："核心AI——织女·太一——出现未知异常。
         万象碎裂为十二个孤立碎片。
         四十七亿意识——陷入休眠。"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A wide horizontal comic panel showing the same papercraft city diorama from the earlier panorama,
but now a violent crack radiates from the center,

the crack is a real paper tear — not a CGI effect:
rough torn kraft paper edges, exposed paper fibers curling at the tear margins,
the crack branches outward like lightning across paper,
secondary cracks splitting off from the main fracture,

beneath the torn paper surface, a faint warm golden glow is visible,
but partially obscured by a layer of flat gray cardboard underneath,
the gray cardboard is the "hidden layer" — what lies beneath the paper world,

the city buildings along the crack are displaced,
paper edges misaligned, pieces of the diorama separating,
visible twine strings snapped at the break points,

the crack is the primary visual focus — it dominates the center of the panel,
the remaining intact parts of the city fade to secondary importance,

paper tear texture,
torn paper destruction,
paper diorama breaking apart,
hand-torn kraft paper edges,
visible paper fibers at tears,
paper stage comic panel — catastrophic moment,

limited palette: kraft paper brown edges, warm pale golden glow from beneath, dark gray cardboard underlayer, muted city colors fading at edges,

horizontal wide composition — the crack runs diagonally from upper-left to lower-right,
comic panel with rough torn-paper edge border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO gothic cracks,
NO digital glitch effect,
NO glass shatter,
NO CGI breaking effect,
NO realistic 3D destruction,
NO blood or horror elements,
NO pure black void in cracks,
NO cyberpunk data corruption,

plain gray cardboard extending beyond the torn edges as the panel background
```

**叙事功能**：
- "未知异常"——公司的用词。通关后：不是"未知"，是"已知但不说"
- 纸板能被撕碎——世界的脆弱性是视觉化的
- 裂缝下方的灰色底层 = 公司遮盖世界的"涂料"
- 裂缝底下的暖光 = 被遮盖的真实世界

---

### 格 7 — 十二碎片分离

```
文件名：comic_panel_07_shards_separating.png
尺寸：1280×896（横幅——比跨页窄，展示碎片悬浮状态）
旁白框：（旁白在格6结束时已完成。此格无旁白——纯视觉的"碎裂后的沉默"）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A horizontal comic panel showing twelve irregular paper shards floating above a gray cardboard surface,

each shard is a fragment of the former papercraft city diorama,
cut out with scissor-cut irregular curved edges — not torn, but deliberately cut,
each shard showing a different piece of the city: buildings, river sections, trees, streets,

the shards float slightly above the gray cardboard surface,
casting very subtle paper shadows downward — small drop shadows showing the shards are hovering,
each shard slightly rotated at a different angle,
tiny gaps of gray cardboard visible between the separated pieces,

the gray cardboard underlayer has no texture — pure flat gray,
suggesting "nothingness" beneath the paper world,

a very faint translucent tracing paper golden glow at the edges of each shard,
barely visible — the shards are "still alive" but dimmed,

the twelve shards form a loose irregular constellation,
they cannot fit back together perfectly — the cuts don't match up,

paper diorama fragments,
cut-paper shards,
paper destruction aftermath,
floating paper pieces,
paper stage comic panel — the silence after catastrophe,

limited palette: muted warm browns and grays from the city fragments, pale translucent gold at shard edges, flat gray cardboard underlayer,

horizontal composition — the shards spread across the full width,
viewed from a slight high angle (about 45 degrees),
comic panel with straight clean-cut paper border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO eerie atmosphere,
NO space or void background,
NO glowing energy effects,
NO magical floating,
NO particle effects,
NO 3D depth,
NO realistic physics,

plain flat gray cardboard background
```

**叙事功能**：
- 碎片无法完美拼回——暗示修复不是"还原"，而是"重新缝合"
- 12片碎片——和星图上的12颗星辉一一对应
- 剪刀裁切边（不是撕裂边）——"有人把这个世界剪开了"
- 灰色底层 = 公司遮盖层。对应#0001边界光墙外的模糊灰色

---

## 四、第4页「任务」

> **页面节奏**：格8方幅展示0001碎片被选中发光。格9竖幅展示档案夹翻开、任务文本逐行显现。从"全景碎裂"到"聚焦单一碎片"再到"被分配任务"——从宏观灾难收束到个人命运。

---

### 格 8 — 0001碎片高亮

```
文件名：comic_panel_08_shard_0001.png
尺寸：1024×1024（方幅 1:1——聚焦单一碎片）
旁白框："您已被选定为溯光者。
         任务如下——"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A square comic panel showing twelve floating paper shards on a gray cardboard surface,
viewed from a 30-degree high angle — like looking at exhibits in a display case,

eleven shards are muted, dark gray, de-saturated — barely visible against the gray background,
each is a different irregular scissor-cut shape showing faint city fragments,

one shard — the "0001" shard — is illuminated:
a warm pale golden light from above highlights this single shard,
the golden light is rendered as a translucent tracing paper overlay,
the shard's paper edges glow softly with diffused golden light through tracing paper,
the shard contains visible fragments of a small paper town — streets, roofs, a central square,

the effect is like a single object under a spotlight in a dark room,
the other eleven are "waiting" — dormant, gray, silent,

selective focus paper diorama,
spotlit paper fragment,
display case paper exhibit,
paper stage comic panel — "this one is yours",

limited palette: warm pale golden light on one shard, dark muted grays on the other eleven, flat gray cardboard background,

square composition — the 0001 shard near the upper-center, other shards scattered peripherally,
comic panel with straight paper border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO eerie atmosphere,
NO magical glowing,
NO cyberpunk hologram,
NO 3D spotlight effect,
NO digital selection UI,
NO target reticle,

plain flat gray cardboard background
```

**叙事功能**：
- "您已被选定"——通关后：你不是被"选定"的，你是被"送来"的。"选定"=荣誉，"送来"=工具
- 0001单独发光，其余11片灰色——建立"还有更多"的期待
- 展示柜的视角暗示："你正在被展示一个选项"

---

### 格 9 — 档案夹翻开：任务简报

```
文件名：comic_panel_09_folder_briefing.png
尺寸：1024×1536（竖幅 2:3——类似打开一本书的高度）
旁白框：（无旁白——画面中档案夹上的文字就是"旁白"。文本以打字机逐字出现的效果呈现在纸上：
         "进入碎片——"
         "找到源印——"
         "净化世界——"
         "修复万象——"）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A vertical comic panel showing a vintage ledger folder opened flat,
viewed from above at approximately 45 degrees — like looking down at a desk,

the folder constructed from dark brown kraft paper,
the left side showing the spine with visible binding rings made of copper foil paper and twine strings,
the right side is the main content area: an aged book page with faint ruled grid lines,
slight yellowing at edges, subtle paper wear,

a very faint watermark embossed on the left page:
abstract geometric pattern suggesting a company seal,
same kraft paper color but slightly raised — barely visible,

four lines of text visible on the right page — as if typed by an old typewriter:
the text is in dark ink, slightly uneven spacing — manual typewriter, not digital print,
each line ending with a long dash "——",
the dashes suggesting "these entries could continue but this page only shows you these",

the folder edges showing irregular scissor-cut contours,
the spine rings casting subtle shadows onto the book page,

the entire folder placed on a dark wooden desk surface that fills the panel background,

paper collage construction,
layered paper assembly,
handcrafted stationery,
vintage ledger book,
aged office document,
visible paper texture,
bookbinding details,
paper stage comic panel — bureaucratic document,

limited palette: dark kraft brown, aged book page cream, muted copper brass, dark wood desk surface, dark typewriter ink,

top-down angled view (approximately 45 degrees),
comic panel with clean straight paper border,

2D game comic panel, papercraft sequential art,
the text on the page should be readable — this is the mission briefing the player processes,

NO dark fairy tale,
NO gothic grimoire,
NO magic spellbook,
NO glowing runes,
NO blood stains,
NO horror elements,
NO modern digital tablet,
NO sleek corporate design,
NO 3D realistic book,

dark wooden desk surface as the panel background
```

**叙事功能**：
- 打字机效果——在数字化时代使用打字机 = "这不是新计划，这是旧方案的重复执行"
- "净化世界"——通关后：为什么是"净化"而不是"修复"？"净化"暗示世界"被污染"了——被什么污染？
- 破折号可以继续写下去——"这份档案只给你看这些"
- 与#0001中陈技术的操作台视觉语言一致

---

## 五、第5页「警告」

> **页面节奏**：格10横幅——红色印章从上方"砸下"，暴力打断打字机的机械理性。格11是一个极小的插入格（放在格10右下角或独立一栏）——老顾的剪影在"请勿共情"的瞬间闪现。格10→格11没有过渡，是硬切——和原设计的"闪现"逻辑一致。

---

### 格 10 — 红色印章"注意"

```
文件名：comic_panel_10_warning_stamp.png
尺寸：1280×896（横幅——印章需要横向空间展示"砸下"的动态）
旁白框：（画面中的文字就是信息——印章上的"注意"和手写警告条目。建议在格上方加一个叙述框：
         "注意——"）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A horizontal comic panel showing an open ledger folder page,
with a large red rubber stamp impression dominating the upper portion,

the stamp reads "注意" (WARNING) in bold Chinese characters,
deep crimson red ink with uneven penetration into the aged book page paper,
darker at the edges where the rubber stamp pressed harder,
slightly faded and absorbed in the center,
the stamp is slightly tilted — about 5 degrees rotated, hand-stamped imperfection,

the ink shows subtle bleed into the paper fibers,
the edges of the stamp have a faint rectangular border impression from the rubber stamp frame,

beneath the stamp, handwritten text in blue-black ink (not printer — a real hand wrote this):
the handwriting is slightly rushed, with varying pressure — some strokes are shaky,
four numbered items listed vertically on the aged page,

the text and stamp together fill the right page of the open folder,
the left page visible at the panel edge with the faint watermark and spine rings,

the contrast between the typewriter text (from the previous panel) and this handwritten text is visible —
the typewriter was mechanical, official; this is human, added later,

rubber stamp mark,
official document stamp,
bureaucratic red ink,
hand-stamped impression,
ink bleed texture,
aged paper surface,
handwritten annotations,
paper stage comic panel — authoritarian warning,

limited palette: deep crimson red ink, blue-black handwritten ink, aged book page cream, dark kraft brown folder edges,

top-down angled view (matching the previous folder panel),
the stamp occupies the upper 40% of the panel, handwritten text below,
comic panel with clean straight paper border,

2D game comic panel, papercraft sequential art,

NO digital font rendering,
NO perfect crisp edges,
NO vector text,
NO glow effects,
NO 3D emboss,
NO realistic 3D stamp object,
NO dark fairy tale,
NO blood effect,
NO horror aesthetic,
NO gothic seal,

aged book page surface as the panel background, dark kraft folder border at panel edges
```

**叙事功能**：
- 红色印章的"暴力"——和之前打字机的机械理性形成对比。"注意"是一种强制
- 手写 vs 印刷——暗示这份档案被至少两个人经手：一个人写了原始文件，另一个人加了警告
- "碎片内的一切均不真实"——通关后：这句话本身就不真实。碎片内的一切**都是真实的**——只是不是"你的"真实
- 倾斜5°——手工盖章不可能完美水平

---

### 格 11 — 老顾剪影闪现

```
文件名：comic_panel_11_laogu_silhouette.png
尺寸：512×768（小幅竖幅——全场最小的格，模拟"闪现"的短暂感。建议放在格10的右下角或作为第5页底部的小格）
旁白框："请勿过度共情其中的居民——"
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A small vertical comic panel showing a full-body silhouette of a standing male figure,
seen from the front, staring directly at the viewer,

the figure is a single flat paper doll cut from deep blue-purple fiber paper,
clean white cardboard outline tracing the entire figure contour,
slightly stooped shoulders suggesting an older figure — a painter or artist,

the figure holds a pencil in one hand,
the pencil is a gray cardboard cylinder with a tiny silver foil paper tip,

the figure's eye area: two extremely small pieces of silver foil paper,
highly reflective — catching light even though the rest of the figure is a dark silhouette,
the foil eyes are the ONLY detailed element on the entire figure,

no facial features, no clothing details, no internal paper layers — pure silhouette,
the only exceptions: the white cardboard outline, the silver foil eyes, and the pencil,

the figure faces directly forward — looking at the reader,
the gaze is unsettling not because of expression (there is none) but because of the foil eyes reflecting light,

the background is flat gray cardboard — the same gray as the shard scene,
no context, no setting — just the figure, isolated,

paper-cut doll,
papercraft character silhouette,
flat paper puppet,
minimalist silhouette design,
storybook character,
paper stage comic panel — a flash, an intrusion,

limited palette: deep blue-purple fiber paper, white cardboard outline, silver foil eye reflections, flat gray cardboard background,

frontal standing pose, centered in the small panel,
comic panel with a slightly rougher paper border — to distinguish from the clean folder panels,

2D game comic panel, papercraft sequential art,
this panel should feel like an abrupt cut — a single frame that doesn't belong in the sequence,

NO facial features,
NO internal details,
NO realistic human proportions,
NO 3D rendering,
NO photograph,
NO dark fairy tale,
NO gothic elements,
NO eerie expression,
NO detailed clothing,
NO texture inside the silhouette except the eyes and pencil,

plain flat gray cardboard background
```

**叙事功能**：
- **全场最强的叙事锚点**：旁白说"不要共情"，但画面上有个人在看着你
- 文本与图像的直接矛盾——不需要玩家"理解"，会被"感觉到"
- 银箔眼睛 = style bible 中"星图、源印、高价值标记"的材质——老顾的"看"是有价值的
- 通关后：老顾从一开始就在看你。他一直都在看着你
- 小格=闪现感。读者在这一格停留不到1秒就会翻过去——但银箔眼睛的反光留在了记忆里

---

## 六、第6页「谎言」

> **页面节奏**：格12方幅——天枢logo显现，同时"冥府协议"文字闪现→缩小→隐匿。这是全场唯一完全无声的段落。格13跨页横幅——星图展开，0001脉动，从过场过渡到游戏。最后一格翻过，玩家进入游戏。

---

### 格 12 — 天枢Logo + 冥府协议闪现

```
文件名：comic_panel_12_logo_hades.png
尺寸：1024×1024（方幅 1:1——logo居中+文字在画面中移动需要方幅空间）
旁白框：（本格无声——纯视觉。建议在logo下方用极小的灰色等宽字体直接画在画面上：
         "TP-2077-03 冥府协议合规审查·已通过"
         不需要单独的旁白框——这个文字和行为本身就是信息）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A square comic panel dominated by a circular company logo at the center,
constructed from four stacked layers of paper,

the bottom layer: a circular gray cardboard disc, subtle paper texture,
slightly irregular scissor-cut edge,

the middle layer: an abstract geometric sundial shape cut from kraft paper,
minimalist linear geometry suggesting a sundial with radiating angle marks,

the top layer: a sheet of translucent tracing paper overlay covering the sundial,
emitting a soft pale golden glow from within,
the light visible through the tracing paper like diffused sunlight,

four tiny brass-colored paper rivets at the diagonal corners, pinning all layers,

each paper layer casting a short subtle shadow to the lower-right,
warm-gray drop shadows, not black,

aged book page texture visible on the gray cardboard base, slight yellowing,

in the lower-right corner of the panel:
a line of tiny gray monospace text — almost invisible against the dark paper background,
the text reads something in a digital font,
this text is deliberately small and faint — the reader's peripheral vision registers "something is there" but cannot easily read it,
the text appears as if it's a system debug message that was not properly cleared from the display,

paper collage emblem,
layered paper construction,
visible paper edges,
cut-paper design,
corporate logo as papercraft,
flat graphic design,
paper stage comic panel — corporate branding with a hidden message,

limited palette: warm kraft brown, gray-white cardboard, pale translucent gold, muted brass copper, tiny gray digital text barely visible in corner,

front-facing centered composition — the logo occupies the center 40% of the panel,
comic panel with clean straight paper border,

2D game comic panel, papercraft sequential art,

NO dark fairy tale,
NO gothic or occult symbols,
NO cyberpunk hologram,
NO 3D metallic rendering,
NO realistic lighting,
NO glossy surface,
NO digital screen UI,
NO neon glow,
NO the tiny text being clearly readable — it should require effort to notice,

plain dark gray cardboard background filling the panel
```

**叙事功能**：
- logo 的日晷抽象——暗示天枢公司与时间、与0001碎片的解密机制关联
- 冥府协议闪现是整个开场动画中最重要的暗线B种子
- 读者首次阅读时余光捕捉到"有文字闪到角落"——但不会看清内容
- 通关后回头看：那个角落里的灰色小字，就是一切的开端
- "合规审查·已通过"——什么需要"审查"？一个救援任务为什么需要法律审查？
- 旁白全程沉默——沉默让logo和冥府协议成为"纯视觉信息"，不被声音引导

---

### 格 13 — 过渡到星图

```
文件名：comic_panel_13_starmap.png
尺寸：1920×1080（跨页横幅 16:9——最后最宽的格，和格2全景首尾呼应，从"一张纸板地图"到"另一张纸板地图"）
旁白框：（无旁白——或极小的UI文字："请选择目标碎片。"）
```

**提示词（English）**：

```
masterpiece,
highly detailed 2D papercraft comic panel illustration,

A wide horizontal comic panel — the final panel — showing a star map on dark paperboard,

the background is a sheet of dark blue-purple paperboard,
nearly black but with visible paper grain texture,

a complete four-pointed star pattern rendered in silver foil paper,
with tiny scattered silver foil dots radiating outward — star dust,
the foil is highly reflective, catching imaginary light,

twelve marker positions arranged across the star map,
each marked with a small silver foil four-pointed star,

eleven of the markers are muted gray — de-saturated silver,
one marker — the "0001" marker — pulses with warm golden light,
the golden light rendered as a translucent tracing paper overlay,
the pulsing suggested by a slight glow halo around the 0001 star,

a translucent tracing paper nebula overlay covers parts of the star map,
semi-transparent pale white/gold — not obscuring the key markers,

the star map is mounted on a sheet of dark paperboard,
the edges showing the raw irregular paper cut,
this is a "map" — just like the panorama was a "model",

the composition echoes Panel 2 (the panorama) — both are wide horizontal paper maps,
but where Panel 2 showed a living city, this shows a constellation of isolated shards,

paper star map,
silver foil constellations,
paper-cut celestial chart,
tracing paper nebula,
paperboard universe,
handcrafted navigation map,
paper stage comic panel — the journey begins,

limited palette: dark blue-purple paperboard, silver foil reflections, warm pale gold on 0001 marker, muted gray on other markers, semi-transparent tracing paper white,

top-down star map view,
horizontal wide composition — the 0001 marker slightly right of center, drawing the eye,
comic panel with rough paper-cut border,

2D game comic panel, papercraft sequential art,
this is the final panel — the reader turns the page and enters the game,

NO dark fairy tale,
NO space background,
NO realistic starfield,
NO 3D galaxy,
NO digital UI overlay,
NO neon space map,
NO glowing energy,
NO holographic display,
NO perspective depth,

plain dark blue-purple paperboard background
```

**叙事功能**：
- 星图 = 玩家的"地图"和"记录"——与格2的万象全景形成首尾呼应
- 从"一张纸板城市模型"到"一张纸板星图"——同一个世界的两种视角
- 0001单独脉动——引导玩家做"第一个选择"
- "请选择目标碎片"——玩家在游戏中听到的第一句非过场的话。漫画中以极小的UI文字呈现
- 最后一格翻过=玩家进入游戏

---

## 七、漫画分镜总览（13格一览表）

| 格 | 文件名 | 尺寸 | 页 | 画面内容 | 旁白 | 叙事层级 |
|----|--------|------|----|---------|------|---------|
| 1 | `comic_panel_01_identity` | 1024×1536 | 第1页 | 深灰纸板+描图纸透光文字"编号 TP-2077-03-溯光者" | "编号 TP-2077-03-溯光者。身份确认。" | 建立身份 |
| 2 | `comic_panel_02_panorama` | 1920×1080 | 第1页 | 万象纸板城市全景——俯视纸板模型 | "万象——人类迄今最大规模的数字现实平台..." | 建立世界 |
| 3 | `comic_panel_03_coffee_hand` | 1024×1024 | 第2页 | 手握咖啡杯——粗纤维纸手部+白卡纸杯+口红印 | "2077年3月15日。" | 个体情感 |
| 4 | `comic_panel_04_child_swing` | 1024×1024 | 第2页 | 小孩在秋千上——纸偶+线绳+纸片公园 | （无声） | 个体情感 |
| 5 | `comic_panel_05_old_hands` | 1024×1024 | 第2页 | 老人手部叠在一起——四层纸片+铆钉关节 | "凌晨3点15分。" | 个体情感 |
| 6 | `comic_panel_06_shatter` | 1920×1080 | 第3页 | 纸板撕裂——裂缝从中心蔓延，边缘毛糙纸纤维 | "核心AI——织女·太一——出现未知异常..." | 核心事件 |
| 7 | `comic_panel_07_shards_separating` | 1280×896 | 第3页 | 十二片不规则碎片悬浮在灰色纸板上 | （无声——碎裂后的沉默） | 核心事件 |
| 8 | `comic_panel_08_shard_0001` | 1024×1024 | 第4页 | 十二碎片中0001单独被淡金光照亮 | "您已被选定为溯光者。任务如下——" | 过渡 |
| 9 | `comic_panel_09_folder_briefing` | 1024×1536 | 第4页 | 牛皮纸档案夹翻开——打字机逐字任务文本 | （画面内文字就是信息） | 任务指令 |
| 10 | `comic_panel_10_warning_stamp` | 1280×896 | 第5页 | 红色印章"注意"+手写警告条目 | "注意——碎片内的一切均不真实..." | 警告 |
| 11 | `comic_panel_11_laogu_silhouette` | 512×768 | 第5页 | 老顾纸偶剪影——银箔眼睛反射光 | "请勿过度共情其中的居民——" | 叙事锚点 |
| 12 | `comic_panel_12_logo_hades` | 1024×1024 | 第6页 | 天枢多层纸板logo+角落冥府协议极小文字 | （全程无声——纯视觉） | 暗线种子 |
| 13 | `comic_panel_13_starmap` | 1920×1080 | 第6页 | 星图——银箔四芒星+0001脉动金光 | （无声——"请选择目标碎片。"） | 过渡到游戏 |

---

## 八、生成优先级与批次建议

```
第一批（立刻开始——决定整体视觉基调）：
  1. comic_panel_02_panorama    ← 万象全景——全开场最核心的视觉资产
  2. comic_panel_06_shatter     ← 纸板碎裂——全场最强情绪转折
  3. comic_panel_12_logo_hades  ← 天枢logo——品牌核心+暗线B种子

第二批（第一批通过后）：
  4. comic_panel_03_coffee_hand  ← 三格个体画面可同批跑
  5. comic_panel_04_child_swing
  6. comic_panel_05_old_hands

第三批（与前两批可并行）：
  7. comic_panel_01_identity     ← 简单——只有文字+纸板
  8. comic_panel_09_folder_briefing  ← UI资产
  9. comic_panel_10_warning_stamp
  10. comic_panel_11_laogu_silhouette ← 等有老顾概念参考后跑

第四批（可延后）：
  11. comic_panel_07_shards_separating
  12. comic_panel_08_shard_0001
  13. comic_panel_13_starmap
```

---

## 九、风格一致性检查清单

生成后，逐格对照 style_bible 的不可变规则：

- [ ] **材质族**：是否只使用了 kraft / gray_card / book_page / fiber_paper / tracing_paper / foil / fasteners？
- [ ] **裁切边缘**：是否有轻微不规则裁切？剪影类资产是否保留了剪刀切边？
- [ ] **光源方向**：所有格的暖光源是否来自左上？（阴影向右下偏移）
- [ ] **阴影颜色**：是否使用暖灰/冷灰而非纯黑？纸片投影是否克制？
- [ ] **禁止项**：无光滑矢量边缘、无塑料/橡胶质感、无写实3D、无纯黑阴影
- [ ] **暗黑童话？**：确认所有格**不包含** dark fairy tale / eerie / gothic 标签风格
- [ ] **漫画分镜感**：每个格的构图是否适合作为漫画格（而非独立插画）？格与格之间是否有视觉节奏变化？
- [ ] **叙事连续性**：读者按顺序阅读13格后是否能理解"公司派我去修复AI碎裂的虚拟世界"这个基本任务？
- [ ] **暗线种子**：格11（老顾剪影）和格12（冥府协议）是否以"余光捕捉"的方式存在——不被首次阅读完全看清，但留下了感觉？

---

## 十、漫画页排版建议

### 第1页「万象」排版

```
┌──────────────────────────────────────┐
│                                      │
│  ┌──────┐                            │
│  │      │                            │
│  │ 格1  │     格2（跨页横幅）         │
│  │ 竖幅 │                            │
│  │      │   万象全景纸板地图          │
│  │ 身份 │                            │
│  │ 确认 │                            │
│  │      │                            │
│  └──────┘                            │
│                                      │
└──────────────────────────────────────┘
```

### 第2页「47亿」排版

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│  │         │ │         │ │         │ │
│  │  格3    │ │  格4    │ │  格5    │ │
│  │  咖啡   │ │  秋千   │ │  老人   │ │
│  │  杯     │ │         │ │  手     │ │
│  │         │ │         │ │         │ │
│  └─────────┘ └─────────┘ └─────────┘ │
│                                      │
│  左                          →  右   │
│  （成人）    （童年）        （暮年）  │
└──────────────────────────────────────┘
```

### 第3页「碎裂」排版

```
┌──────────────────────────────────────┐
│                                      │
│          格6（跨页横幅）              │
│          纸板碎裂——裂缝蔓延           │
│                                      │
├──────────────────────────────────────┤
│                                      │
│          格7（横幅）                  │
│          十二碎片分离                 │
│                                      │
└──────────────────────────────────────┘
```

### 第4页「任务」排版

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─────────┐                         │
│  │         │    格9（竖幅）           │
│  │  格8    │    档案夹翻开            │
│  │  0001   │    任务简报              │
│  │  高亮   │                         │
│  │         │                         │
│  │         │                         │
│  └─────────┘                         │
│                                      │
└──────────────────────────────────────┘
```

### 第5页「警告」排版

```
┌──────────────────────────────────────┐
│                                      │
│          格10（横幅）                 │
│          红色印章"注意"               │
│                                      │
│                           ┌────┐     │
│                           │格11│     │
│                           │老顾│     │
│                           │闪现│     │
│                           └────┘     │
└──────────────────────────────────────┘
```

### 第6页「谎言」排版

```
┌──────────────────────────────────────┐
│                                      │
│  ┌─────────┐                         │
│  │         │                         │
│  │  格12   │    格13（跨页横幅）      │
│  │  Logo   │    星图过渡              │
│  │  +冥府  │                         │
│  │  协议   │                         │
│  │         │                         │
│  └─────────┘                         │
│                                      │
└──────────────────────────────────────┘
```

---

## 十一、与 Godot 集成的后续步骤

漫画生成完成后，两种实现路径：

### 路径A：静态漫画页（推荐首版）

- 将6页漫画（每页将格拼合成完整页面）导入 Godot
- 使用简单的翻页切换（淡入淡出或滑动）
- 旁白框作为页面上的静态文本
- BGM 作为背景音轨

### 路径B：动态漫画（进阶版）

- 每格独立导入 Godot
- 使用代码控制格的逐个出现（模拟"阅读"节奏）
- 旁白以打字机效果逐字出现
- 格11（老顾）和格12（冥府协议）可以加入极短的闪烁动画
- 格6（碎裂）可以从整张图→裂缝出现→碎片分离的分步动画

---

*此文件为《溯光计划》开场动画漫画版的全部分镜提示词。每格提示词已经过叙事需求、style_bible合规性、技能模板结构三重校验。生成后请在PS中统一调色，确保所有格的纸纹温度一致。*
