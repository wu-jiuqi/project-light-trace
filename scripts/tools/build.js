/**
 * 溯光计划 - 构建脚本
 * 
 * 调用 Godot 引擎执行 Web (HTML5) 导出
 * 用法：node scripts/build.js [debug|release]
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const GODOT_EXE = 'D:/Godot/Godot_v4.6.2-stable_win64_console.exe';
const PROJECT_DIR = 'D:/WorkBuddy WorkSpace/shuoguang_project';
const EXPORT_PRESET = process.argv[2] === 'debug' ? 'Web (HTML5)' : 'Web (HTML5)';
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');

console.log('='.repeat(50));
console.log('  溯光计划 - 构建脚本');
console.log('  目标平台: Web (HTML5)');
console.log('='.repeat(50));

// Check Godot executable
if (!fs.existsSync(GODOT_EXE)) {
    console.error('[ERROR] Godot executable not found:', GODOT_EXE);
    console.log('[INFO] 请确保 Godot 4.6.2 已安装到: D:/Godot/');
    process.exit(1);
}

// Check export templates
const templatesDir = path.join(
    process.env.APPDATA || path.join(process.env.HOME, 'AppData', 'Roaming'),
    'Godot', 'export_templates', '4.6.2.stable'
);
const webDebug = path.join(templatesDir, 'web_debug.zip');
const webRelease = path.join(templatesDir, 'web_release.zip');

if (!fs.existsSync(webDebug) && !fs.existsSync(webRelease)) {
    console.error('[ERROR] Web export templates not found!');
    console.log('[INFO] 请在 Godot 编辑器中通过 编辑器 > 管理导出模板 下载');
    console.log('[INFO] 或手动放置 web_debug.zip 和 web_release.zip 到:');
    console.log('       ' + templatesDir);
    console.log('[INFO] 下载地址: https://godotengine.org/download/archive/4.6.2-stable/');
    process.exit(1);
}

// Ensure build directory
if (!fs.existsSync(BUILD_DIR)) {
    fs.mkdirSync(BUILD_DIR, { recursive: true });
}

try {
    console.log('[INFO] 开始构建...');
    console.log('[INFO] Godot:', GODOT_EXE);
    console.log('[INFO] 项目:', PROJECT_DIR);
    console.log('[INFO] 输出:', BUILD_DIR);

    const cmd = `"${GODOT_EXE}" --headless --path "${PROJECT_DIR}" --export-release "${EXPORT_PRESET}" "${BUILD_DIR}/index.html"`;
    console.log('[CMD]', cmd);
    
    execSync(cmd, { 
        stdio: 'inherit',
        cwd: PROJECT_DIR,
        timeout: 300000 // 5 minutes
    });

    console.log('[SUCCESS] 构建完成!');
    console.log('[INFO] 输出目录:', BUILD_DIR);
    
    // List output files
    const files = fs.readdirSync(BUILD_DIR);
    console.log('[INFO] 输出文件:', files.join(', '));

} catch (err) {
    console.error('[ERROR] 构建失败:', err.message);
    process.exit(1);
}
