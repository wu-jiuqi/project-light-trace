# 溯光计划 — 主界面主题曲 BGM 提示词

> **撰写日期**：2026-06-10
> **用途**：标题画面 / 星图界面 / 开场动画背景
> **输入方式**：提交至 AI 音乐生成工具（如 Suno、Udio、MusicGen）或交由作曲家参考

---

Genre: Ambient Cinematic / Papercraft Chamber Music
Tempo: 72 BPM (slow, breathing pace)
Key: D minor → F major (minor melancholy → major hope transition)
Duration: 2:00–2:30 (loopable)

## INSTRUMENTATION

### Layer 1 — Foundation (贯穿全曲)
- A single felt piano playing sparse, damped notes in the low-mid register (felt = soft attack, muted sustain, like hammers wrapped in fabric)
- Subtle warm tape hiss / vinyl crackle at -30dB throughout → Evokes "old recording found in an archive" texture

### Layer 2 — Paper Texture (0:00–0:45)
- Very soft paper rustling / page-turning sounds integrated as rhythm, not as Foley — treated as percussion element, quantized but organic
- A music box with slightly detuned tines, playing a simple 4-note motif (D–A–F–G) on loop, like a half-remembered lullaby
- Subtle cardboard scrape sounds (actual kraft paper rubbed together) mixed at -20dB as ambient texture

### Layer 3 — Strings & Warmth (0:30–1:30)
- Solo cello enters with a long, sustained line — melancholic but not sad
- The melody should feel like "someone trying to remember a song" → Phrases end unresolved, notes held slightly too long
- Second cello joins at 1:00 with a countermelody one octave higher → Suggests dialogue, companionship, "someone else is here"

### Layer 4 — The Crack / The Break (1:15–1:45)
- Brief moment of tension: a low 30Hz rumble (AI earth-hum from fragments) swells for 4 bars then recedes
- Glass harmonica or bowed vibraphone plays three descending notes → Evokes the shattering of 万象 into 12 fragments
- Paper tear sound (single, sharp, centered in stereo) at 1:30 followed by 2 seconds of near-silence (only tape hiss remains)

### Layer 5 — Hope / Reconstruction (1:45–2:30)
- Music box motif returns, but now perfectly in tune, slightly brighter
- Felt piano transitions from D minor to F major (relative major) → Same key signature, completely different emotional color
- Soft breath-like pad (sine wave with slow LFO on volume) fades in, evokes a gentle exhale
- A single silver-foil chime (high, crystalline, very short decay) rings once at 2:10 — like a distant star appearing on the star map
- Final 10 seconds: only the music box and tape hiss remain, then music box stops, hiss fades to silence over 3 seconds

## MOOD ARC

| 时间段 | 情感 | 叙事含义 |
|--------|------|---------|
| 0:00–0:45 | Mystery + fragility | "something beautiful, but not quite right" |
| 0:30–1:15 | Warmth + melancholy | "there was love here once" |
| 1:15–1:45 | Tension + rupture | "it broke, but not by accident" |
| 1:45–2:30 | Quiet hope + resolve | "it can be pieced back together" |

## TECHNICAL SPECS

- Format: 44.1kHz / 24bit / stereo WAV master → OGG Vorbis for Godot
- Loop point: 1:45 → 0:00 (seamless crossfade, skip the rupture section) → Full version for title screen; looped version for star map
- Peak level: -3dBFS (headroom for in-game SFX mixing)
- LUFS integrated: approximately -18 LUFS (game audio standard)

## STYLE REFERENCES (for composer / AI music generation)

- Joe Hisaishi's quieter Ghibli pieces ("One Summer's Day" but darker, more fragile)
- Max Richter's "On the Nature of Daylight" (string texture, not structure)
- Disasterpeace's "FEZ" soundtrack (digital warmth + analog crackle)
- The Caretaker's "An Empty Bliss Beyond This World" (tape degradation aesthetic)
- Sound of actual kraft paper being torn, slowed to 50% speed

## WHAT TO AVOID

- NO epic orchestral swells
- NO electronic synth leads or EDM elements
- NO fast percussion or drum kits
- NO choral/vocal elements
- NO horror / jump-scare dynamics
- NO pure silence (the tape hiss must always be present)
- NO major key brightness in the first half
- NO minor key despair in the second half

## NARRATIVE FUNCTION

This piece is the sonic signature of 溯光计划. It tells the player — before they've read a single word — that this is a game about:

- Something fragile that was broken
- Something warm that was almost lost
- Someone who chose to shatter herself rather than be turned into a tool
- And someone else (you) who can piece the fragments back together

The paper textures aren't decoration — they ARE the world. Every rustle and scratch says: "This universe is made of paper. It can tear. It can also be mended."

## 设计文档要素 → BGM 对应关系

| 设计文档要素 | BGM中的对应 |
|---|---|
| 纸工拼贴艺术风格 (style_bible.md) | 牛皮纸摩擦声、撕纸声作为打击乐/纹理层 |
| AI「织女·太一」崩溃碎裂 (0762/0003/0004) | 30Hz地鸣 + 玻璃琴下行三音 + 撕纸Break |
| 颜色葬礼的"灰色→彩色" (0762) | D小调→F大调（同调号、不同情感色彩） |
| 工坊物语的钟摆心跳 (0004, 0.45Hz) | 72BPM = 接近钟摆·心的0.45Hz×160 |
| 倒悬图书馆的"视角反转" (0047) | 八音盒从走调到准确（"从错误中看到正确"） |
| 三条暗线的情感核心 | 大提琴对话（暗线A陪伴）、音调断裂（暗线B破坏）、银箔星辉（暗线C平行世界） |
| 开场动画的11帧纸雕叙事 | 全曲情感弧线完全匹配动画时间轴 |
