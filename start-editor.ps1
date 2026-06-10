# 溯光计划 — Godot 编辑器启动脚本（直连 DeepSeek API）
#
# 用法：
#   .\start-editor.ps1 -ApiKey "sk-xxxxxxxx"
#
# 或先设置环境变量再启动 Godot：
#   $env:DEEPSEEK_API_KEY="sk-xxxxxxxx"
#   .\start-editor.ps1

param(
    [string]$ApiKey = "",
    [string]$GodotPath = "D:\Godot\Godot_v4.6.2-stable_win64.exe"
)

# 优先使用命令行传入的密钥，其次使用已设置的环境变量
if ($ApiKey) {
    $env:DEEPSEEK_API_KEY = $ApiKey
    Write-Host "[OK] DEEPSEEK_API_KEY 已从命令行参数设置" -ForegroundColor Green
}
elseif ($env:DEEPSEEK_API_KEY) {
    $masked = $env:DEEPSEEK_API_KEY.Substring(0, [Math]::Min(8, $env:DEEPSEEK_API_KEY.Length)) + "..."
    Write-Host "[OK] DEEPSEEK_API_KEY 已从当前环境变量读取 ($masked)" -ForegroundColor Green
}
else {
    Write-Host "[WARN] DEEPSEEK_API_KEY 未设置 — LLM 将尝试使用本地代理 (localhost:3000)" -ForegroundColor Yellow
    Write-Host "       如需直连，请运行: .\start-editor.ps1 -ApiKey `"sk-xxxxxxxx`"" -ForegroundColor Yellow
}

# 启动 Godot 编辑器（自动继承当前环境变量）
Write-Host "[INFO] 启动 Godot 编辑器: $GodotPath" -ForegroundColor Cyan
Write-Host "[INFO] 项目路径: $PSScriptRoot" -ForegroundColor Cyan

$projectPath = Join-Path $PSScriptRoot "project.godot"
if (Test-Path $projectPath) {
    Start-Process -FilePath $GodotPath -ArgumentList "--path `"$PSScriptRoot`"" -Wait
}
else {
    Write-Host "[ERROR] 未找到 project.godot，请确认脚本位于项目根目录" -ForegroundColor Red
    exit 1
}
