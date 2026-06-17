# 溯光计划项目概览

## 当前状态

这是一个 Godot 4 项目，核心循环包括标题界面、星图、线性碎片解锁、碎片场景探索、NPC 对话、存档与 Web 导出。

当前设计默认采用线性解锁：

1. 初始开放碎片 `0001`。
2. 完成 `0001` 后开放 `0002`。
3. 完成 `0002` 后开放 `0003`。
4. 占位或未实现碎片即使被标记为 unlocked，也不应允许进入。

## 关键系统

| 系统 | 说明 |
| --- | --- |
| `SaveManager` / `SaveConstants` | 存档槽、最后使用槽位、测试存档目录切换 |
| `FragmentManager` | 碎片状态、线性解锁、进入碎片、显式重置片段运行 |
| `SceneManager` / `SceneFader` | 统一场景切换和淡入淡出 |
| `ChatDatabase` | 按存档槽隔离的 NPC 聊天历史 |
| `LLMClient` | 同源代理或自定义 OpenAI-compatible API 的流式请求 |
| `scripts/tools/*.js` | Web 构建、预览服务、安全和资源检查 |

## Web 发布约束

Web 版继续启用线程，因此部署服务必须返回：

- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

构建后的 `index.pck` 会执行体积阈值检查：超过 250 MB 警告，超过 400 MB 失败。

## 回归测试入口

常用检查：

```powershell
npm test
& "D:\Godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/test_save_slots.gd
& "D:\Godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/test_fragment_manager.gd
& "D:\Godot\Godot_v4.6.2-stable_win64_console.exe" --headless --path . --script res://scripts/tests/test_linear_unlock.gd
```
