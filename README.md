# 溯光计划

《溯光计划》是一个 Godot 4.6.2 制作的 2D 纸工拼贴叙事解谜项目。当前版本以 FTUE 和前四个可玩碎片为核心：玩家从标题页进入开场漫画，经星图按线性顺序进入碎片，逐步收集线索、完成源印事件，并解锁下一个碎片。

## 当前流程

```text
title_screen.tscn
  -> opening_cinematic.tscn
  -> star_map.tscn
  -> 0001 -> 0002 -> 0003 -> 0004
  -> 后续规划碎片占位
```

星图保留 12 个碎片位，但当前运行路线已经移除旧版 0762。可进入的现役碎片为：

| 顺序 | ID | 名称 | 状态 | 场景 |
| --- | --- | --- | --- | --- |
| 1 | 0001 | 启程之镇 | 已实现 | `scenes/fragments/fragment_0001.tscn` |
| 2 | 0002 | 黄昏驿站 | 已实现 | `scenes/fragments/fragment_0002.tscn` |
| 3 | 0003 | 月下道观 | 已实现 | `scenes/fragments/fragment_0003.tscn` |
| 4 | 0004 | 工坊物语 | 已实现 | `scenes/fragments/fragment_0004.tscn` |
| 5+ | 0047、0915、1138、2049、3015、3333、4096 | 后续规划 | 未开放 | 占位 |

## 项目结构

```text
project_light_trace/
├── project.godot
├── export_presets.cfg
├── package.json
├── README.md
├── cleanup_removed_manifest_20260619.md
│
├── scenes/
│   ├── ui/                 标题页、对话、背包、线索、菜单
│   ├── cinematic/          开场和碎片转场
│   ├── star_map.tscn       星图入口
│   ├── fragments/          0001-0004 碎片主场景
│   ├── rooms/id000*/       碎片内子场景
│   ├── buildings/id000*/   碎片交互物/场景部件
│   └── characters/id000*/  现役 NPC 场景
│
├── scripts/
│   ├── globals/            Game/Fragment/Save/Scene 等全局单例
│   ├── fragment/           碎片脚本、NPC 控制器、交互件
│   ├── systems/            LLM、RAG、背包、线索等系统
│   ├── ui/                 面板、对话、标题页与组件
│   ├── star_map/           星图与碎片遮罩交互
│   ├── cinematic/          漫画/转场播放逻辑
│   └── tools/              Node 构建、部署、校验脚本
│
├── assets/
│   ├── audio/              BGM、SFX、UI 音效
│   ├── cutscenes/opening/  开场漫画图
│   ├── fonts/              Web 中文字体
│   ├── papercraft/         纸工正式资产与 manifest
│   └── ui/                 当前 UI 位图/SVG
│
└── LLM/
    ├── 0001/
    ├── 0002/
    └── 0004/               现役 NPC RAG 知识库
```

旧版 0762 资源、旧追捕系统、旧房间脚本和确认未使用资源已移到根目录备份：`cleanup_backup_20260619_0762_unused/`。清单见 `cleanup_removed_manifest_20260619.md`。

## 开发环境

- Godot 4.6.2
- Node.js 22+
- Godot Web 导出模板 4.6.2

常用命令：

```powershell
npm test
npm run validate:papercraft
npm run build
npm run serve
```

`npm run serve` 会提供静态 Web 预览和同源 LLM 代理。`DEEPSEEK_API_KEY` 只能放在服务端环境变量或部署平台密钥中，不要写入 Godot 客户端源码。

## CNB 预览部署

CNB 使用分支隔离，避免 `onlyPreview: true` 阻断日常开发入口：

- `dev` 分支：日常开发分支，保留完整云原生开发环境和 Docker service。
- `main` 分支：公开试玩分支，仅用于 CNB 预览和镜像发布。
- 更新 Web 产物时，先运行 `npm run build` 和 `npm run deploy cnb`，确认 `deploy/` 后再合并到 `main`。

`main` 分支 push 会用根目录 `Dockerfile` 构建镜像，并由 `.cnb.yml` 的仅预览模式执行：

```bash
docker run -d --network host -e PORT=8686 -e CNB_API_ENDPOINT -e CNB_REPO_SLUG -e CNB_TOKEN <image>:latest
```

CNB 预览服务必须监听 `0.0.0.0:8686`。官方试玩默认使用 CNB 内置 OpenAI-compatible LLM：`${CNB_API_ENDPOINT}/${CNB_REPO_SLUG}/-/ai-ide/v2/chat/completions`，令牌只通过服务端环境变量 `CNB_TOKEN` 注入。预览环境 `keepAliveTimeout` 为 1 小时；试玩时请及时使用游戏内存档，容器回收会丢失未保存的运行态。

## 当前设计原则

- 线性解锁：完成当前碎片后解锁下一碎片，星图用于进入与回顾。
- 纸工拼贴：正式资产从 `assets/papercraft/` 与 manifest 管理，运行时优先使用当前碎片目录。
- 通用 NPC：NPC 控制器只保留站立/巡逻、对话入口、RAG prompt 与 LLM 流式输出。
- 无旧追捕系统：旧版追捕、六色觉醒与给予物品体系已从现役代码移除。
- 存档隔离：碎片专属状态保存在 `FragmentManager` 的 fragment state 命名空间中，未知旧碎片状态不会重新应用。
