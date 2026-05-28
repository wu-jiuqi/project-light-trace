# 溯光计划 — 归源计划 (Project Origin)

## 🎮 项目概述

**「溯光计划」** 是一款基于 Godot 4.6.2 的 2D 日式 RPG 风格开放探索游戏。

- **世界观**：2077年，AI「织女·太一」创造的虚拟宇宙「万象」失控碎裂。玩家作为科技巨头「天枢公司」派遣的「溯光者」，潜入碎片世界，寻找「源印」，修复破碎宇宙。
- **核心玩法**：碎片解密 → 身份隐瞒 → 线索收集 → 寻找源印 → 跨副本叙事
- **设计参考**：《画怖》（副本-线索-钤印体系）、《全球高考》（系统规则-对抗模式）

## 📂 项目结构

```
shuoguang_project/
├── project.godot          # Godot 项目配置文件
├── export_presets.cfg     # Web 导出预设
├── icon.svg               # 项目图标
├── package.json           # Node.js 工具脚本
│
├── scenes/
│   ├── star_map.tscn      # 星图主界面（碎片选择 + 解密管理）
│   └── fragments/
│       └── fragment_world.tscn  # 碎片世界模板
│
├── scripts/
│   ├── globals/
│   │   ├── game_manager.gd     # 游戏全局状态（单例）
│   │   ├── fragment_manager.gd # 碎片系统管理（单例）
│   │   └── save_manager.gd     # 存档系统（单例）
│   ├── star_map/
│   │   └── star_map.gd         # 星图交互逻辑
│   ├── fragment/
│   │   ├── fragment_base.gd    # 碎片世界基类
│   │   └── npc_controller.gd   # AI子体NPC控制器
│   ├── systems/
│   │   ├── wanted_system.gd    # 通缉/警觉系统（6级）
│   │   └── clue_system.gd      # 线索收集系统
│   ├── ui/
│   │   └── dialogue.gd         # 对话系统
│   └── tools/                  # Node.js 构建工具
│       ├── build.js            # Godot Web 导出构建
│       ├── serve.js            # 本地预览服务器
│       └── deploy.js           # 在线部署
│
└── resources/                  # 游戏资源
    ├── fonts/
    ├── images/
    └── audio/
```

## ✅ 已完成 — 12碎片系统设计

| # | 碎片ID | 名称 | 提示 | 难度 |
|---|--------|------|------|------|
| 1 | 0001 | 启程之镇 | 「白日依山尽」 | ★ |
| 2 | 0002 | 黄昏驿站 | 「黄河入海流」 | ★ |
| 3 | 0003 | 月下神社 | 「举头望明月」 | ★ |
| 4 | 0004 | 工坊物语 | 「匠心_」 | ★★ |
| 5 | 0047 | 倒悬图书馆 | 「知识就是_量」 | ★★★ |
| 6 | 0762 | 颜色的葬礼 | 「蓝是_，红是_」 | ★★★ |
| 7 | 0915 | 遗忘庭院 | 「_忘_」 | ★★ |
| 8 | 1138 | 时钟停摆的车站 | 「再见_」 | ★★★ |
| 9 | 2049 | 镜中人 | 「我_谁_」 | ★★★★ |
| 10 | 3015 | 零时档案馆 | 「3:15_」 | ★★★★★ |
| 11 | 3333 | 诸神黄昏 | 「_终_始」 | ★★★★★ |
| 12 | 4096 | 万象归源 | 「_归_」 | ★★★★★ |

## 🚀 开发工作流

### 前置条件
- **Godot 4.6.2** — 引擎（已安装于 `D:/Godot/`）
- **Node.js 22+** — 构建/部署工具
- **Godot Web 导出模板** — 单独下载

### 步骤一：安装 Web 导出模板

```bash
# 方案A：在 Godot 编辑器中安装
# 打开项目 → 编辑器 → 管理导出模板 → 下载并安装

# 方案B：手动下载
# 从 https://godotengine.org/download/archive/4.6.2-stable/
# 下载 Godot_v4.6.2-stable_export_templates.tpz
# 解压后复制 web_debug.zip 和 web_release.zip 到：
#   %APPDATA%/Godot/export_templates/4.6.2.stable/

# 方案C：使用国内镜像（推荐）
# 从 atomgit 下载（速度更快）
```

### 步骤二：本地开发

```bash
cd shuoguang_project

# 在 Godot 编辑器中打开项目
start godot://"D:/Godot/Godot_v4.6.2-stable_win64.exe" --path "D:/WorkBuddy WorkSpace/shuoguang_project"

# 或者在编辑器中直接 F5 运行
```

### 步骤三：Web 构建

```bash
npm run build    # 构建 Web (HTML5) 版本到 build/web/
```

### 步骤四：本地预览

```bash
npm run serve    # 启动本地服务器 http://localhost:3000
```

### 步骤五：在线部署

```bash
# Cloud Studio 部署
npm run deploy cloudstudio

# 登录 Cloud Studio → 导入 deploy/ 目录 → 点击运行
# 自动获得可访问的在线链接
```

## 📋 MVP 开发路线图

### 阶段 0：脚手架 ✅
- [x] Godot 项目结构
- [x] 全局管理器（Game/Fragment/Save）
- [x] 星图界面框架
- [x] 碎片数据系统
- [x] 对话系统框架
- [x] 通缉系统（6级警觉）
- [x] 线索收集系统
- [x] Web 导出配置
- [x] 构建/部署脚本

### 阶段 1：核心可运行 (进行中)
- [ ] 星图界面实装（列表选择 + 解密进度）
- [ ] 碎片世界模板实装（2D Tilemap + 玩家移动）
- [ ] NPC 交互系统（对话树 + 警觉反馈）
- [ ] 第一个可玩碎片「颜色的葬礼」
- [ ] Web 导出验证

### 阶段 2：完整流程
- [ ] 碎片「倒悬图书馆」
- [ ] 碎片「时钟停摆的车站」
- [ ] 源印发现与解码机制
- [ ] 跨碎片线索系统
- [ ] 存档系统实装

### 阶段 3：系统完善
- [ ] 解密与现实时间挂钩
- [ ] 半解密提示推理
- [ ] 三条叙事暗线触发
- [ ] 通缉系统实装（NPC 追捕行为）

### 阶段 4：扩展
- [ ] 更多碎片
- [ ] 溯光者论坛系统
- [ ] 平行世界机制
- [ ] AI LLM NPC 接入

## 🔧 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| 引擎 | Godot 4.6.2 | 2D 渲染，GDScript |
| 导出 | HTML5/WebAssembly | WebGL 2.0, GL Compatibility |
| 服务器 | Node.js | 零依赖 HTTP 服务器 |
| 部署 | Cloud Studio / Vercel | 一键在线链接 |
| 存储 | Godot user:// | 本地存档 |

## 📝 关键设计决策

1. **机制驱动，非数值驱动**：核心玩法依赖玩家对规则的理解和应用，无复杂等级/数值系统
2. **半解密系统**：提示可被部分解密，玩家需自己推理完整含义
3. **非线性碎片选择**：碎片无固定顺序，玩家自由选择，不同路径产生不同体验
4. **三重叙事暗线**：AI信念 / 公司阴谋 / 平行世界 — 通过碎片线索逐步揭示
