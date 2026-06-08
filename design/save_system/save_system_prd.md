# 溯光计划 — 存档系统产品需求文档（PRD）

> 版本：v1.0  
> 创建日期：2025-07-01  
> 关联代码：`save_manager.gd`（~482行）、`game_manager.gd`（~197行）、`chat_database.gd`（~271行）

---

## 1. 项目信息

| 项目 | 说明 |
|------|------|
| **语言** | 中文（玩家面向） |
| **引擎/语言** | Godot 4.x / GDScript |
| **项目代号** | `shuoguang_save_system` |
| **原始需求** | 为溯光计划叙事解谜游戏设计正式的存档系统规范，覆盖多槽位存档/读档、跨碎片状态传递、版本兼容与存档完整性 |

---

## 2. 产品定义

### 2.1 产品目标

1. **状态连续性**：玩家在 12 个碎片间任意切换时，已获得的进度（颜色觉醒、物品、NPC信任度、线索等）不丢失，无需重复劳动。
2. **存档可靠性**：存档文件写入过程中即使发生崩溃/断电，已有的存档数据不损坏；存档损坏时可自动检测并提供恢复路径。
3. **版本向前兼容**：游戏迭代（新增状态字段、修改数据结构）后，旧版本存档可自动迁移至新格式，玩家无需手动操作。

### 2.2 用户故事

| # | 用户故事 | 验收标准 |
|---|---------|---------|
| US-01 | 作为玩家，我**在碎片间切换时**，希望已收集的物品、觉醒的颜色、建立的NPC信任度**不丢失**，以便我的探索进度是连续的。 | 在碎片 A 中获得"铸造日志"并觉醒红色，切换到碎片 B 再切回 A 后，背包仍有该物品（或已消耗标记），红色仍觉醒。 |
| US-02 | 作为玩家，我**在游戏更新后**，希望旧存档仍能正常加载，以便我不需要从头开始重玩。 | 使用 v1.0 版本存档在 v1.1 版本游戏中加载，所有旧数据完整保留，新增字段使用默认值。 |
| US-03 | 作为玩家，当**存档文件意外损坏**时，我希望系统能检测到损坏并提供恢复选项（从备份恢复 / 重新开始），以便我不会丢失全部进度。 | 手动破坏 save_0.json 后加载该槽位，系统提示"存档损坏，是否从最近备份恢复？"。 |
| US-04 | 作为玩家，我希望**快速存档/读档操作流畅**（一键存档、标题界面槽位预览清晰），以便我能专注于游戏体验而非操作存档系统。 | 按 F5 后 2 秒内显示"已存档"提示；标题界面 3 个槽位清晰展示进度、时间、玩家名。 |
| US-05 | 作为玩家，我在碎片 A 中**重新挑战**时，希望关卡内进度重置但之前的对话历史可选保留，以便我能回溯之前的互动而不丢失上下文。 | 在碎片 #0762 中选择"重新挑战"，颜色觉醒/物品重置，但聊天历史仍可在对话界面翻看。 |

---

## 3. 技术规范

### 3.1 存档范围定义

#### 3.1.1 持久化状态（跨碎片全局状态）

以下状态需**持久化到存档文件**，在加载任意存档后恢复：

| 分类 | 状态字段 | 当前存储位置 | 说明 |
|------|---------|-------------|------|
| **游戏进度** | `play_time_seconds` | GameManager | 总游玩时间（秒） |
| | `repair_progress` | GameManager | 修复进度 0.0~1.0 |
| | `repaired_fragments` | GameManager | 已修复碎片数（推导值，可由 fragments 列表计算） |
| | `current_phase` | GameManager | 游戏阶段枚举 |
| | `player_name` | GameManager | 玩家名称 |
| **暗线** | `company_trust` | GameManager | 公司信任度 |
| | `darkline_a/b/c` | GameManager | 三条暗线揭示/解锁状态 |
| **线索/源印** | `collected_clues` | GameManager | 已收集的跨碎片线索列表 |
| | `source_mark_log` | GameManager | 已解码的源印记录 |
| **颜色觉醒** | `awakened_colors` | GameManager | 六色觉醒状态数组（#0762 专属，但需跨碎片保留） |
| **NPC状态** | `npc_state_cache` | GameManager | NPC 位置/警觉/怀疑值（跨场景） |
| | `npc_visit_count` | GameManager | NPC 访问计数 |
| | `oldpainter_trust` | GameManager | 老画家信任值 |
| **碎片完成** | `fragments[].completed` | FragmentManager | 每个碎片的完成状态 |
| **碎片进度** | `melody_triggered` | GameManager | #0762 旋律触发 |
| | `source_mark_revealed` | GameManager | #0762 源印显现 |
| | `fragment_completed` | GameManager | #0762 是否已完成 |
| | `white_ready` | GameManager | #0762 五色集齐 |
| | `gray_cloth_uncovered` | GameManager | #0762 灰布揭开 |
| **物品** | `items_used` | GameManager | 已消耗物品标记 |
| | **背包物品** | **InventoryManager** | ⚠️ **当前未持久化！** 玩家当前持有的物品列表 |
| **聊天历史** | 全部 NPC 对话记录 | ChatDatabase | 按槽位独立存储 |

#### 3.1.2 临时状态（碎片内，不存档）

以下状态**仅在当前场景会话期间有效**，不写入存档：

| 分类 | 状态 | 存储位置 | 生命周期 |
|------|------|---------|---------|
| **玩家位置** | `global_position` | PlayerController | 场景加载时由 SpawnPoint 重置 |
| **交互状态** | `_nearby_npcs`, `_closest_npc` | PlayerController | 场景加载时重建 |
| | `_near_source_mark`, `_near_gray_cloth` | Fragment0762State | 场景加载时重建 |
| **场景节点** | GrayCloth, SourceMark 等动态节点 | 场景实例 | 场景卸载时销毁，进入时按全局状态重建 |
| **动画状态** | Tween, 粒子效果 | 场景实例 | 场景卸载时销毁 |
| **UI状态** | 对话面板打开/关闭、背包面板 | UI组件 | 场景切换后重置 |
| **临时RAG缓存** | NPC知识库检索缓存 | NPCRagRetriever | 内存，不持久化 |

#### 3.1.3 状态分类原则

```
判断流程：
  Q1: 切换碎片后，该状态是否仍需保留？
    → 是 → 持久化状态
    → 否 → Q2

  Q2: 退出碎片后重新进入（重玩），该状态是否需要恢复？
    → 是 → 持久化状态（如 NPC 信任度）
    → 否 → Q3

  Q3: 该状态能否由持久化状态 + 场景初始化逻辑完全重建？
    → 是 → 临时状态（如 GrayCloth 由 gray_cloth_uncovered + white_ready 重建）
    → 否 → 考虑持久化
```

### 3.2 跨碎片状态传递方案

#### 3.2.1 现状分析

| 机制 | 当前状态 | 问题 |
|------|---------|------|
| SceneManager.pending_spawn_point | ✅ 已有 | 仅传递出生点名称，不传递其他状态 |
| GameManager 全局 Autoload | ✅ 已有 | 内存常驻，切换场景不丢失 — 但未正式定义哪些是"跨碎片"状态 |
| InventoryManager 背包 | ❌ 缺失 | `_items` 数组从未被持久化，碎片切换后理论上会丢失（但因 Autoload 常驻，实际上同 session 内还在） |
| NPC状态缓存 | ✅ 已有 | 通过 `npc_state_cache` 字典跨场景保留 |

#### 3.2.2 方案设计

**核心机制**：利用 Godot Autoload 单例的内存常驻特性，结合存档系统的序列化/反序列化。

```
进入碎片 A
  ├── FragmentManager.enter_fragment(A)
  │     ├── GameManager.reset_fragment()  ← 重置碎片内临时状态
  │     └── SceneManager.change_scene(...)
  │
  ├── 场景加载，按 GameManager 全局状态重建场景节点
  │     （如：white_ready? → 创建 GrayCloth）
  │
  └── 玩家在碎片 A 中操作，修改 GameManager 全局状态

切换至碎片 B
  ├── 自动存档（保存当前进度）
  │     └── SaveManager.save_game() → 持久化全部全局状态到 JSON
  │
  ├── FragmentManager.enter_fragment(B)
  │     ├── GameManager.reset_fragment()  ← 仅重置碎片内临时状态
  │     └── SceneManager.change_scene(...)
  │
  └── 场景 B 加载，全局状态（颜色觉醒、物品、信任度等）仍在 GameManager 中

退出游戏 → 重进
  └── SaveManager.load_game(slot)
        └── 恢复 GameManager 全部全局状态
```

**传递清单**：以下状态通过 GameManager 常驻内存 + 存档持久化，在碎片间无缝保持：

| 状态 | 传递方式 |
|------|---------|
| 颜色觉醒 (awakened_colors) | GameManager 常驻 |
| 已收集线索 (collected_clues) | GameManager 常驻 |
| 源印记录 (source_mark_log) | GameManager 常驻 |
| NPC 信任度/访问计数 | GameManager 常驻 |
| 物品消耗标记 (items_used) | GameManager 常驻 |
| 背包物品 (InventoryManager._items) | ⚠️ 需新增持久化 |
| 碎片完成状态 | FragmentManager → 存档 → 恢复 |
| 游戏阶段/暗线 | GameManager 常驻 |

**出生点传递**（已有，保持不变）：
- SceneManager.pending_spawn_point 负责同一碎片内场景切换时的出生点定位
- 跨碎片切换时，由 FragmentManager 指定新碎片的入口出生点

### 3.3 存档版本兼容

#### 3.3.1 版本号策略

采用**语义化版本号（SemVer）**：`MAJOR.MINOR.PATCH`

| 版本位 | 含义 | 存档兼容性 |
|--------|------|-----------|
| MAJOR | 重大架构变更（如 JSON → 二进制，文件结构重构） | **不兼容**：旧存档不可用，需提示玩家 |
| MINOR | 新增字段、新增碎片数据 | **向前兼容**：旧存档可加载，新字段用默认值 |
| PATCH | 修复 bug、调整默认值 | **完全兼容**：无需迁移 |

**当前存档版本**：`0.3.0`（硬编码于 SaveManager）。建议正式发布时设为 `1.0.0`。

#### 3.3.2 迁移机制

```gdscript
# 伪代码示例
const SAVE_VERSION = "1.1.0"
const MIGRATIONS = {
    "1.0.0": "_migrate_1_0_0_to_1_1_0",
    # 未来版本...
}

func _load_with_migration(slot: int) -> Dictionary:
    var data = _read_json(slot)
    var version = data.get("version", "0.0.0")
    
    while _version_lt(version, SAVE_VERSION):
        var migrator = MIGRATIONS.get(version)
        if migrator:
            data = call(migrator, data)
            version = data["version"]
        else:
            break  # 无法迁移，跳出
    return data

func _migrate_1_0_0_to_1_1_0(data: Dictionary) -> Dictionary:
    # 示例：新增 inventory 字段
    if not data.has("inventory"):
        data["inventory"] = []  # 旧存档没有背包数据，默认为空
    data["version"] = "1.1.0"
    return data
```

#### 3.3.3 不兼容降级策略

当 MAJOR 版本不匹配时：

| 场景 | 策略 |
|------|------|
| 存档 MAJOR > 游戏支持 | 提示"存档来自较新版本，请更新游戏后重试"，禁止加载 |
| 存档 MAJOR < 游戏支持（无法迁移） | 提示"存档格式过旧，无法加载。是否删除该存档并开始新游戏？" |
| 存档 MAJOR < 游戏支持（可迁移） | 自动迁移，加载成功后覆盖写入新格式 |

### 3.4 存档完整性

#### 3.4.1 损坏检测

**方案**：在每个存档 JSON 中嵌入完整性校验字段。

```json
{
  "version": "1.0.0",
  "slot": 0,
  "timestamp": 1719820800,
  "checksum": "sha256_hex_digest",
  "...game_data..."
}
```

**检测流程**：
1. 读取文件 → JSON 解析
2. JSON 解析失败 → **结构性损坏**（文件不完整/格式错误）
3. JSON 解析成功但缺少 `checksum` → **旧版存档**（按迁移流程处理）
4. JSON 解析成功，`checksum` 不匹配 → **内容损坏**（数据被篡改或磁盘错误）
5. 以上全部通过 → **存档完好**

**恢复策略**：

| 损坏类型 | 恢复策略 |
|---------|---------|
| 结构性损坏 | 尝试从 `.bak` 备份文件恢复；若无备份，提示"存档已损坏"并标记槽位为损坏 |
| 内容损坏 | 同上 |
| 存档完好 | 直接加载 |

#### 3.4.2 原子写入

**当前问题**：`save_game()` 直接用 `FileAccess.WRITE` 覆盖原文件。若写入中途崩溃/断电，原文件和写入中断的新文件均损坏。

**方案**：采用"写临时文件 → 重命名覆盖"策略。

```
写入流程：
1. 序列化存档数据为 JSON 字符串
2. 计算 checksum（SHA-256，取前 16 字符足够）
3. 写入临时文件：save_{slot}.tmp
4. 调用 FileAccess.flush() 确保落盘（若 Godot 不支持 flush，用 FileAccess.close() + 重新 open 验证）
5. 重命名旧文件为备份：save_{slot}.json → save_{slot}.bak
6. 重命名临时文件：save_{slot}.tmp → save_{slot}.json
7. 验证新文件可正确读取（加载 JSON + 校验 checksum）
8. 验证通过 → 删除备份 save_{slot}.bak
9. 验证失败 → 恢复备份 save_{slot}.bak → save_{slot}.json
```

#### 3.4.3 多槽位管理

| 功能 | 当前状态 | 建议 |
|------|---------|------|
| 槽位数 | 3 个（0-2） | 保持，支持扩展至 5 个 |
| 槽位信息 | `list_slots()` 返回摘要 | 增加 `last_played_scene`、`fragment_count` 字段 |
| 自动存档 | 30 秒间隔，仅在活跃槽位有文件时运行 | 保持 |
| 最后活动槽位 | `last_slot.json` | 保持，增加 `last_slot.json` 的原子写入保护 |
| 新游戏 | 选择空槽位或覆盖已有槽位 | 需在 UI 中明确提示"将覆盖该槽位的所有进度" |

### 3.5 需求池

#### P0 — 必须实现（阻塞发布）

| ID | 需求 | 说明 | 验收标准 |
|----|------|------|---------|
| P0-01 | **背包物品持久化** | InventoryManager._items 写入/读取存档 | 碎片 A 中获得的物品在存档→切换碎片→读档后仍存在 |
| P0-02 | **原子写入机制** | 采用 tmp → rename 策略防止写入中断损坏 | 模拟存档写入中途崩溃（kill 进程），重启后旧存档完好 |
| P0-03 | **存档版本号 + 迁移框架** | 存档嵌入语义化版本号，加载时按需迁移 | 用 v1.0 存档在 v1.1 游戏加载，新增字段正确填充默认值 |
| P0-04 | **存档校验和（checksum）** | JSON 嵌入 SHA-256 校验和，加载时验证 | 手动修改存档一个字节后加载，系统报告"存档已损坏" |
| P0-05 | **GameManager 属性访问解耦** | SaveManager 不直接读写 30+ 属性，改为 GameManager 提供 `to_dict()` / `from_dict()` | SaveManager 的 save_game/load_game 不再逐字段硬编码 |

#### P1 — 应该实现（影响体验）

| ID | 需求 | 说明 | 验收标准 |
|----|------|------|---------|
| P1-01 | **聊天数据单一数据源** | 消除 chat_{slot}.json 与 save_{slot}.json 内嵌快照的双副本问题 | 聊天数据仅存储在 chat_{slot}.json，save_{slot}.json 不再内嵌 |
| P1-02 | **存档备份恢复** | 损坏时自动从 .bak 文件恢复 | 模拟损坏后加载，系统自动从备份恢复并提示玩家 |
| P1-03 | **碎片专属状态命名空间** | 将 #0762 专属状态移到 `fragment_states.0762` 子字典，避免 GameManager 顶层膨胀 | 新增碎片时只需扩展 fragment_states 子字典 |
| P1-04 | **重玩模式标记** | 存档中标记当前是否为"重玩已完成碎片"模式 | 重玩碎片时不会意外覆盖真正的首次完成进度 |
| P1-05 | **存档槽位扩展至 5 个** | 当前 3 个槽位对 12 碎片叙事游戏可能不足 | 标题界面显示 5 个槽位 |

#### P2 — 可以后续迭代

| ID | 需求 | 说明 |
|----|------|------|
| P2-01 | 存档加密 | 防止玩家直接修改 JSON 作弊（单机游戏，优先级低） |
| P2-02 | 云存档同步 | 多设备进度同步（需后端支持，MVP 不做） |
| P2-03 | 存档截图 | 每个槽位附带当前场景缩略图 |
| P2-04 | 自动存档可配置间隔 | 玩家可在设置中调整自动存档频率（15s / 30s / 60s / 关闭） |
| P2-05 | 存档导出/导入 | 玩家可导出存档文件用于备份或跨设备迁移 |

---

## 4. 数据架构建议

### 4.1 存档 JSON 结构（目标格式）

```json
{
  "version": "1.0.0",
  "slot": 0,
  "timestamp": 1719820800,
  "timestamp_readable": "2025-07-01 12:00:00",
  "save_name": "溯光档案 01",
  "checksum": "a1b2c3d4e5f6",
  
  "global": {
    "play_time_seconds": 3600.0,
    "repair_progress": 0.25,
    "current_phase": 1,
    "player_name": "溯光者-07",
    "company_trust": 0.85,
    "darkline_a_revealed": false,
    "darkline_b_revealed": false,
    "darkline_c_unlocked": false,
    "collected_clues": ["clue_001"],
    "source_mark_log": [],
    "items_used": {},
    "inventory": [0, 1],
    "npc_state_cache": {},
    "npc_visit_count": {}
  },
  
  "fragments": [
    {"id": "0001", "completed": false},
    {"id": "0762", "completed": true}
  ],
  
  "fragment_states": {
    "0762": {
      "awakened_colors": [true, false, false, false, false, false],
      "melody_triggered": false,
      "source_mark_revealed": true,
      "white_ready": false,
      "gray_cloth_uncovered": true,
      "oldpainter_trust": 25.0,
      "fragment_completed": true
    }
  }
}
```

### 4.2 GameManager 推荐 API

```gdscript
## 序列化：GameManager 将自身可持久化状态导出为字典
func to_dict() -> Dictionary:
    return {
        "play_time_seconds": play_time_seconds,
        "repair_progress": repair_progress,
        # ...
    }

## 反序列化：从字典恢复状态，缺失字段使用默认值
func from_dict(data: Dictionary) -> void:
    play_time_seconds = data.get("play_time_seconds", 0.0)
    repair_progress = data.get("repair_progress", 0.0)
    # ...
```

---

## 5. 待确认问题（Open Questions）

| # | 问题 | 上下文 | 建议决策 |
|---|------|--------|---------|
| Q1 | 背包物品（InventoryManager._items）是否需要持久化？还是每次进入碎片重新拾取？ | 当前代码未持久化背包，但颜色觉醒依赖物品（如 FORGE_LOG），物品丢失意味着颜色无法觉醒。 | **必须持久化**。否则碎片间物品丢失破坏核心玩法。 |
| Q2 | 聊天数据是否保留双副本（chat_{slot}.json + save_{slot}.json 内嵌）？ | 当前双副本可能导致不一致。单一数据源更安全但需要协调 SaveManager 和 ChatDatabase 的加载顺序。 | **采用单一数据源**：聊天数据仅存 chat_{slot}.json。SaveManager 加载时先恢复 GameManager 状态，再调用 ChatDatabase.set_slot()。 |
| Q3 | 碎片专属状态（如 #0762 的六色觉醒）应该作为顶层字段还是嵌套在 fragment_states 子对象中？ | 当前 30+ 顶层属性难以扩展（12 个碎片 x 平均 5 个专属属性 = 60 个顶层字段）。 | **采用嵌套结构**：`fragment_states.<fragment_id>.*`。便于扩展，且各碎片状态互不干扰。 |
| Q4 | 重玩已完成碎片时，如果再次完成，是否再次增加修复进度？ | 当前代码有防护（检查 `fragment_completed`），但存档恢复后该标记可能丢失。 | **以 FragmentManager.fragments[].completed 为准**，不依赖 GameManager.fragment_completed。 |
| Q5 | 存档截图功能是否在 MVP 阶段实现？ | 增加实现复杂度，但对槽位识别体验提升明显。 | **P2**：MVP 不做，后续迭代加入。 |
| Q6 | 自动存档是否应该在切换碎片前触发？ | 当前仅在 30 秒定时器触发。如果玩家在碎片中玩 25 秒后切换，最后 25 秒进度丢失。 | **应该**：在 `FragmentManager.enter_fragment()` 中调用 `SaveManager.save_game()` 作为切换前自动存档。 |
