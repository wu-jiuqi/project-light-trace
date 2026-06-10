# 溯光计划 — BGM 使用位置说明

> 处理日期：2026-06-10
> 源文件：`assets/audio/Tracing_the_Paper_Seam.mp3`
> 原始规格：169.5秒 / 44100Hz / 立体声 / 192kbps / 输入响度 -11.22 LUFS

---

## 处理概览

| 项目 | 值 |
|------|-----|
| 响度标准化 | -18 LUFS（Integrated），-1.0 dBTP（True Peak） |
| 输出格式 | OGG Vorbis，44100Hz，立体声，q5 |
| 输出目录 | `assets/audio/bgm/` |

---

## 三个输出版本及其使用位置

### 1. `bgm_main_theme.ogg` — 标题画面

| 属性 | 值 |
|------|-----|
| 时长 | 2:49.5（全曲） |
| 淡入/淡出 | 无（保留原始完整结构） |
| 播放场景 | `title_screen.tscn` |
| 触发时机 | 标题画面加载完成后自动播放 |
| 停止时机 | 玩家点击「开始游戏」/「继续游戏」/「加载存档」切换场景时 |
| 脚本位置 | `scripts/ui/title_screen.gd` — `_start_bgm()` / `_stop_bgm()` |
| 音量 | -6 dB（Master bus，为 SFX 留余量） |

**设计意图**：全曲的情感弧线「神秘→温暖→断裂→希望」是游戏的听觉签名。玩家在标题画面停留时听到的是完整叙事，在点击按钮前就已经被植入游戏的核心情感基调。

---

### 2. `bgm_opening_cinematic.ogg` — 开场动画

| 属性 | 值 |
|------|-----|
| 时长 | 0:55（提取前 55 秒） |
| 淡出 | 2 秒（53s→55s） |
| 播放场景 | `opening_cinematic.tscn` |
| 触发时机 | 开场动画面板逐格推进开始时 |
| 停止时机 | 动画结束、跳转星图前 |
| 脚本位置 | `scripts/cinematic/opening_cinematic.gd` — `_start_bgm()` / `_stop_bgm()` |
| 音量 | -6 dB |

**与开场动画时间轴的对应**：

| 动画时间 | 旁白内容 | BGM 状态 |
|---------|---------|---------|
| 0-3s | 编号确认 | 淡入 + 神秘 intro |
| 3-15s | 万象全景描述 | 安静建立，纸纹理可闻 |
| 15-17s | 时间日期 | 第一峰值前夕的紧张感 |
| 17-25s | 碎裂描述 | 音频第一段高潮，与"碎裂"同步 |
| 25-30s | 碎片特写 | 极静段落（30-35s），对应碎片悬浮 |
| 30-40s | 任务简报 | 重建气氛，对应打字机节奏 |
| 40-45s | 警告页 | 45s 的强烈峰值对应"注意——" |
| 45-55s | 老顾闪现+logo | 高潮余波，2s 淡出到星图过渡 |

---

### 3. `bgm_star_map_loop.ogg` — 星图界面

| 属性 | 值 |
|------|-----|
| 时长 | 2:45（裁剪尾部极端淡出，整体缩短约 4.5 秒） |
| 淡入 | 2 秒 |
| 淡出 | 3 秒（162s→165s） |
| 播放场景 | `star_map.tscn` |
| 触发时机 | 星图界面加载完成（含 SceneFader 淡入后） |
| 停止时机 | 玩家选择碎片并进入碎片世界时 |
| 脚本位置 | `scripts/star_map/star_map.gd` — `_start_bgm()` / `_stop_bgm()` |
| 音量 | -8 dB（比标题画面和动画更低，星图是 UI 界面，不应压倒 UI 音效） |

**设计意图**：星图 BGM 更安静（-8 dB），因为星图有大量 UI 交互和音效（碎片高光闪烁、详情卡弹出等）。BGM 在此处扮演氛围角色，而非叙事主角。

---

## 场景切换 BGM 流程

```
标题画面                    开场动画                    星图界面
bgm_main_theme.ogg         bgm_opening_cinematic.ogg   bgm_star_map_loop.ogg
      │                          │                          │
      │  新游戏 →                │                          │
      │  _stop_bgm()             │  _start_bgm()            │
      │  change_scene ──────────→│                          │
      │                          │  动画结束 →              │
      │                          │  _stop_bgm()             │
      │                          │  change_scene ──────────→│
      │                          │                          │  _start_bgm()
      │                          │                          │
      │                          │                          │  进入碎片 →
      │                          │                          │  _stop_bgm()
      │                          │                          │  change_scene→ 碎片世界
      │                                                      （碎片暂无BGM）
      │  继续游戏/加载存档 →                                  │
      │  _stop_bgm()                                         │
      │  change_scene ──────────────────────────────────────→│
```

---

## 技术备注

- 所有 BGM 使用 `AudioStreamPlayer` 节点，以代码方式创建并添加为场景子节点（未在 .tscn 中硬编码，避免场景编辑冲突）
- 每个场景都有自己的 `_bgm_player` 实例，场景切换时自动销毁，无需全局管理器
- BGM 与 SFX（`assets/audio/sfx/`）共享 `Master` bus，通过 `volume_db` 差异（BGM -6~-8 dB，SFX 通常 -0~-3 dB）实现自然分层
- 如后续需要全局 BGM 管理（如跨场景淡入淡出），可考虑创建 `AudioManager` autoload
