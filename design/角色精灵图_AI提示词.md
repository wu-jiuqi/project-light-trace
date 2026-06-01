# 碎片 #0762「颜色的葬礼」—— 角色像素精灵图 AI 提示词

> **目标平台**：Midjourney / DALL-E / Stable Diffusion / Flux
> **输出格式**：sprite sheet，4方向 × 3帧网格排列
> **单帧尺寸**：32×32 px，网格总计 128×96 px
> **通用规范**：见下方「通用负提示词」和「通用正提示词前缀」

---

## 通用正提示词前缀（所有角色共用）

```
pixel art sprite sheet,
4x3 frame grid, 12 frames total,
4 directions: up down left right, 3 frames per direction,
each frame 32x32 pixels,
retro RPG game character,
top-down view,
clean silhouette, hard pixel edges,
limited 16-color palette, pixel perfect,
Aseprite quality, professional game asset,
single top-left light source,
consistent proportions,
transparent background,
game-ready sprite
```

## 通用负提示词（所有角色共用）

```
no anti-aliasing,
no blur,
no gradients,
no noise,
no texture,
no realistic lighting,
no 3D rendering,
no smooth edges,
no soft shadows,
no HD, no photorealistic,
no detailed background,
no watermark, no signature,
no jpeg artifacts
```

---

## 角色 #1：迷路的旅人（玩家载体）

### 关键视觉锚点
- 左肩斜挎深棕色信使包，包角露出米白色信封一角
- 衣领淡青色领饰（#8AB8C8）
- 肩披深墨绿旅行斗篷（不穿，是披着的）
- 手背有淡淡茧痕

### Midjourney Prompt

```
pixel art sprite sheet of a weary traveler RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- neutral gender, age 25-30, slightly hunched posture, medium-short messy dark brown hair #5A4030, skin #D8C8B8, off-white travel shirt #F0EDE4 with rolled-up sleeves, collar has pale cyan trim #8AB8C8, dark moss green cape #3A4A3A draped over shoulders (not worn), gray-brown travel pants #7A6A5A with square knee patches #8A7A6A, worn short boots #6A5040, leather messenger bag slung left shoulder #6A4030 with white envelope corner peeking out #F0EDE4, tired but alert expression, faint calluses on knuckles -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "The Lost Traveler", a gender-neutral adventurer around 25-30 years old. Medium-short messy dark brown hair, slightly hunched from long travel, tired but alert expression. Wearing an off-white travel shirt with rolled-up sleeves and a pale cyan collar trim, a dark moss green cape draped over shoulders. Gray-brown travel pants with square knee patches, worn short boots. A dark brown leather messenger bag slung across the left shoulder with a white envelope corner visible. Faint calluses on knuckles. Sprite sheet layout: 4 columns (up, down, left, right directions) by 3 rows (idle animation frames), each frame exactly 32x32 pixels, hard pixel edges, limited 16-color palette, single top-left light source, transparent background, game-ready quality.
```

---

## 角色 #2：铁匠·老霍（红色·愤怒）

### 关键视觉锚点
- 焦茶色帆布围裙覆盖胸口到膝盖
- 围裙右下角深酒红色铁水烫痕（#C04040）—— Shader穿透元素
- 右手举锤悬在半空（idle的"锤子不上不下"状态）
- 粗壮手臂满是老茧

### Midjourney Prompt

```
pixel art sprite sheet of a burly blacksmith RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 52, broad shoulders, thick muscular build, short gray-white hair #686868 with coal-dusted streaks, square face with thick brows, horizontal scar across nose bridge, sleeveless dark gray-brown vest #7A6A5A with sweat stains, muscular arms with calloused forearms, heavy canvas apron #8A7A5A covering chest to knees dotted with iron dust and burn marks, dark wine-red scorch mark #C04040 on lower right of apron, gray-brown work pants #6A5A4A, thick-soled blacksmith boots #4A3A2A with iron toe caps #B8B8B8 -- idle pose: right hand holding hammer frozen mid-air, left hand resting on anvil, stern downward mouth -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "Old Huo the Blacksmith", a burly 52-year-old man with broad shoulders and thick build. Short gray-white hair with coal dust streaks, square face, thick brows, horizontal scar across the nose bridge. Wearing a sleeveless dark gray-brown vest with sweat-stained collar, revealing heavily calloused forearms. A dark brown canvas apron from chest to knees covered in iron dust and burn marks, with a distinctive dark wine-red scorch mark (#C04040) on the lower right corner. Gray-brown work pants, thick-soled boots with iron toe caps. Idle pose: right hand holds a hammer frozen in mid-air above an anvil, left hand resting on the anvil, permanent downward frown. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 角色 #3：花店老板娘·阿莲（蓝色·悲伤）

### 关键视觉锚点
- 淡蓝灰色及踝连衣裙，裙摆有矢车菊轮廓刺绣
- 腰间亚麻色短围裙，口袋插淡蓝色柄小剪刀
- 浅栗色长发挽成低髻，米白色发簪
- 微笑只在嘴唇上，到不了眼睛

### Midjourney Prompt

```
pixel art sprite sheet of a slender florist woman RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 35, slim figure with unnaturally upright posture, light chestnut hair #A08070 in a loose low bun with off-white hairpin #E8E0D8, two stray strands covering corners of eyes, delicate features with a hollow smile that never reaches the eyes, slight shadows under eyes, ankle-length pale blue-gray dress #B8C4D4 with faint cornflower embroidery #A8B8C8 along hem, linen apron #B8A890 around waist with small light-blue-handled scissors in pocket, slender fingers -- idle pose: standing by flower rack, holding cornflowers in one hand, trimming stems with scissors in other hand, slow precise movements -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "A-Lian the Florist", a slender 35-year-old woman with unnaturally upright posture. Light chestnut hair in a loose low bun secured by an off-white hairpin, two strands of hair deliberately covering the corners of her eyes. Delicate features, a smile that stays on her lips but never reaches her hollow eyes, faint shadows underneath. Wearing an ankle-length pale blue-gray dress with faint cornflower embroidery along the hem, a linen apron around the waist with small light-blue-handled scissors in the pocket. Idle pose: standing beside a flower rack, holding blue cornflowers, trimming stems with slow precise movements. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 角色 #4：面包师·老唐（黄色·希望）

### 关键视觉锚点
- 眼睛2px（其他NPC为1px）—— "有希望"的视觉标志
- 围裙上密密麻麻的面粉白色掌印
- 围裙左下角金黄色麦穗刺绣
- 右手永远在揉金黄色面团
- 圆脸红光满面，头发上沾着面粉

### Midjourney Prompt

```
pixel art sprite sheet of a round cheerful baker RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 47, short round build, round rosy face #E0D0C0, wide forehead with receding hairline, dark brown curly hair #5A4030 with a tuft sticking up covered in flour #F8F0E0, larger eyes than other NPCs (2px pupils #A08050 with bright highlight dot #F8F0E0), sparse upward-curving brows, off-white chef top #F0EDE0 with gray trim, sleeves rolled to elbows showing flour-dusted forearms, linen canvas apron #C8B890 covered in white flour handprints #F0E8D8, small golden wheat embroidery #D8B040 on lower left corner of apron, light gray-brown pants #B0A090 with slightly darker knees from oven heat -- idle pose: half-turned beside oven, right hand kneading a golden dough ball, warm smile -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "Old Tang the Baker", a cheerful 47-year-old man with a short round build. Round rosy face with a wide forehead and slightly receding hairline, dark brown curly hair with a tuft sticking up covered in white flour. Notably larger eyes than other characters (2-pixel pupils instead of 1-pixel, signifying hope), sparse upward-curving brows. Off-white chef top with gray trim, sleeves rolled to elbows showing flour-dusted forearms. Linen-colored canvas apron covered in white flour handprints overlapping each other, with a small golden wheat ear embroidery on the lower left corner. Idle pose: half-turned beside an oven, right hand constantly kneading a golden dough ball, warm genuine smile. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 角色 #5：守墓人·老崔（绿色·恐惧）

### 关键视觉锚点
- 瞳孔深处极淡绿色荧光（2px，#40A040）—— Shader穿透元素
- 墨绿色破旧大衣，衣领永远竖起来裹住脖子
- 右手永远握着生锈铁钥匙
- 干瘦驼背，蹲在屋角的蜷缩姿态（idle）

### Midjourney Prompt

```
pixel art sprite sheet of a gaunt terrified gravekeeper RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 55, extremely thin skeletal build, severely hunched back curled into a ball, patchy gray-white hair #8A8A8A with bald spots, sunken cheeks with protruding cheekbones, pale skin #D8D0C8 with deep shadows under eyes #B0A098, very faint green glow #40A040 in pupils (2px), dark moss green tattered overcoat #3A4A3A with collar always pulled up wrapping neck, mismatched patches #4A5A4A and #5A6A5A, deep gray-brown pants #5A4A3A with worn-shiny knees, thin bony fingers, rusted iron key #6A5A4A clutched in right hand never letting go, gray-white ring #B0B0B0 on left ring finger -- idle pose: crouching in corner, legs tucked, arms wrapped around knees, eyes peering out from between knees -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "Old Cui the Gravekeeper", a gaunt 55-year-old man with extremely thin skeletal build and a severely hunched back. Patchy gray-white hair with bald spots, sunken cheeks, protruding cheekbones, pale skin with deep eye shadows. A very faint green glow visible in the pupils. Wearing a dark moss green tattered overcoat with the collar always pulled up tightly wrapping the neck, covered in mismatched patches. Deep gray-brown pants with knees worn shiny from crouching. Thin bony fingers, a rusted iron key clutched in the right hand, a gray-white ring on the left ring finger. Idle pose: crouching in a corner, legs pulled tight, arms wrapped around knees, eyes peering out from between the knees — this is his only safe posture. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 角色 #6：小提琴手·薇拉（紫色·思念）

### 关键视觉锚点
- 深紫灰色及膝连衣裙，裙摆右下角亮紫色螺旋音符刺绣（#9060C0）—— Shader穿透元素
- 左肩架红棕色小提琴，琴弓停在弦上方2px——永远不落下
- 左手手指在琴弦上无声按弦
- 深棕色长发一丝不苟地盘成高髻，眼神永远望向远方（东北方向）

### Midjourney Prompt

```
pixel art sprite sheet of an elegant violinist woman RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 28, slender figure with narrow shoulders, unnaturally upright rigid posture, neck slightly elongated as if listening to distant sound, dark brown hair #4A3028 pulled into a tight immaculate high bun with slender off-white bone hairpin #E0D8D0, no stray hairs, delicate oval face with pointed chin, thin slightly furrowed brows, deep purple-gray eyes #584868 gazing into the distance (northeast direction), lips closed with no curve -- neither sad nor smiling, the expression of 'waiting', knee-length dark purple-gray dress #6A5878, neat unwrinkled hem, bright purple spiral note embroidery #9060C0 on lower right of hem, reddish-brown violin #8A5040 resting on left shoulder with semi-transparent white strings #E8E0D8, bow #9A7060 hovering 2px above strings -- idle pose: standing still, left hand fingers silently changing position on strings, bow frozen just above strings, the only movement is her left hand -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "Viola the Violinist", a slender 28-year-old woman with rigidly upright posture and narrow shoulders. Her neck is slightly elongated as if listening to something far away. Dark brown hair pulled into a tight immaculate high bun with a slender off-white bone hairpin, not a single stray hair. Delicate oval face with pointed chin, thin slightly furrowed brows, deep purple-gray eyes gazing permanently into the distance. A knee-length dark purple-gray dress with a perfectly neat unwrinkled hem, a bright purple spiral musical note embroidery (#9060C0) on the lower right. A reddish-brown violin rests on her left shoulder with semi-transparent white strings. The bow hovers exactly 2 pixels above the strings — never landing. Idle pose: standing perfectly still, only her left hand fingers move — silently pressing and releasing positions on the strings in an inaudible performance. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 角色 #7：老画家（源印载体 · 特殊NPC）

### 关键视觉锚点
- 十根手指覆盖多层干涸彩色颜料（六色：红蓝黄绿紫橙）—— **100% Shader穿透**
- 纯白长罩衫上布满六色颜料溅痕
- 白发散乱遮住半边脸，但眼神是碎片中最亮的
- 坐在画架前，左手悬在画布上方1px——永远差一点落笔
- 颧骨极高，极瘦

### Midjourney Prompt

```
pixel art sprite sheet of an ancient painter sage RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age ambiguous (could be 70, could be ageless), extremely thin skeletal frame, pure white long messy hair #E8E8E8 falling over half his face, extremely high cheekbones, sunken cheeks, skin #C8B8A8, the brightest eyes in the entire world #E0E0E0 with deep laugh lines at corners, white smock #F0F0F0 covered in multi-colored paint splatters: red #C04040 blue #6090C0 yellow #E0B040 green #40A040 purple #9060C0 orange #E08030, collar askew revealing collarbone, faded handwritten text on smock hem reading '...not...gray...', loose gray-brown pants #5A4A3A with a hole at the right knee -- most distinctive: all ten fingers covered in layers of dried paint in six different colors stacked upon each other, thick calluses on right index and middle finger from holding palette -- idle pose: seated before an easel, right hand holding palette, left hand hovering 1px above canvas, forever about to paint but never touching -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "The Old Painter", an ageless figure who could be 70 or beyond time itself. Extremely thin skeletal frame, pure white long messy hair falling over half the face. Extremely high cheekbones, sunken cheeks, but the brightest most knowing eyes in the entire world — eyes that make other characters uncomfortable because they feel seen through. Deep laugh lines at the corners of eyes, but he no longer smiles. A pure white long smock covered in colorful paint splatters in six colors (red, blue, yellow, green, purple, orange), like an overturned palette. The collar hangs askew showing the collarbone. Faded handwritten text barely visible on the smock hem. The most distinctive feature: all ten fingers covered in multiple layers of dried paint in six different colors, each finger with different color dominance. Right index and middle fingers have thick calluses from holding a palette too long. Idle pose: seated before an easel, palette in right hand, left hand hovering 1 pixel above the canvas — forever about to paint, forever hesitating. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, carefully managed 16-color palette despite the colorful paint details, single top-left light source, transparent background.
```

---

## 角色 #8：旅店老板·冯婶（非关键NPC）

### 关键视觉锚点
- 坐柜台后打瞌睡（idle：头一点一点往下）
- 花白发髻，旧发夹
- 深棕色旧毛衣外罩白色围裙，围裙口袋插铅笔
- 圆脸，眼袋重

### Midjourney Prompt

```
pixel art sprite sheet of an elderly innkeeper woman RPG character, 4x3 frame grid (up/down/left/right x3 idle frames each), 32x32 pixels per frame, top-down view -- age 60+, slightly plump round build with rounded shoulders from decades behind a counter, graying white hair #C0B0A0 pulled into a bun with old hair clip, loose strands hanging down sides, round face with heavy eye bags #D0C0B0, dark brown old sweater #5A4030 with frayed cuffs, white apron #F0F0F0 over the sweater with a pencil always tucked in the apron pocket, tired sleepy expression -- idle pose: seated behind counter, head bobbing down as she dozes off, then jerking awake, flipping a page of the guest registry, then dozing again -- clean hard pixel edges, limited 16-color palette, no anti-aliasing, single top-left light source, transparent background, Aseprite quality, retro RPG game asset, pixel perfect --no blur, no gradients, no noise, no texture, no 3D, no realistic lighting
```

### DALL-E / Flux Prompt

```
A pixel art sprite sheet for a retro RPG game. The character is "Aunt Feng the Innkeeper", a plump elderly woman in her 60s with rounded shoulders from decades sitting behind the inn counter. Graying white hair pulled into a simple bun with an old hair clip, loose strands hanging down the sides. Round face with heavy drooping eye bags. A dark brown old sweater with frayed cuffs, covered by a white apron with a pencil always tucked in the pocket. Idle pose: seated behind the counter, head nodding down as she dozes off, then suddenly jerking awake, flipping a page of the guest registry, then immediately dozing off again in a loop. Sprite sheet: 4 directions × 3 idle frames, 32x32px each, hard pixel edges, limited 16-color palette, single top-left light source, transparent background.
```

---

## 附录：平台特定参数建议

### Midjourney
```
通用参数追加：
--ar 4:3 --style raw --stylize 50 --quality 2
说明：4:3 适配 128×96 网格；--style raw 保留硬像素边缘；低 stylize 减少AI主观美化
```

### DALL-E
```
分辨率建议：1024×1024（生成后裁切至 128×96）
建议使用 "pixel art, retro video game sprite" 作为固定前缀
```

### Stable Diffusion
```
建议模型：AnyPixel / PixelArtDiffusion / 自训练 LoRA
建议追加采样器：DPM++ 2M Karras, CFG scale: 7, Steps: 20-30
建议加入 Embedding: pixel_art, sprite_sheet
```

### Flux
```
使用自然语言描述即可，无需特殊参数。
建议在 negative prompt 中强调 "no smooth gradients, no photorealistic, no blur"
```

---

> **文档版本**：V1.0
> **关联文档**：`art_spec_角色美术规格.md` V2.0
> **用于**：AI 图像生成工具批量生成角色精灵图资源
