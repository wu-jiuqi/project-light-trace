/**
 * 溯光计划 - Godot Web 构建脚本
 *
 * 可选环境变量：
 *   GODOT_EXE             Godot 控制台程序路径
 *   GODOT_TEMPLATE_VERSION 导出模板版本，默认 4.6.2.stable
 */

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');
const EXPORT_PRESET = 'Web (HTML5)';
const TEMPLATE_VERSION = process.env.GODOT_TEMPLATE_VERSION || '4.6.2.stable';
const PCK_WARN_BYTES = 250 * 1024 * 1024;
const PCK_FAIL_BYTES = 400 * 1024 * 1024;
const GODOT_CANDIDATES = [
    process.env.GODOT_EXE,
    'D:/Godot/Godot_v4.6.2-stable_win64_console.exe',
    'godot4',
    'godot',
].filter(Boolean);

function findGodot() {
    for (const candidate of GODOT_CANDIDATES) {
        if (candidate.includes('/') || candidate.includes('\\')) {
            if (fs.existsSync(candidate)) return candidate;
            continue;
        }
        try {
            execFileSync(candidate, ['--version'], { stdio: 'ignore' });
            return candidate;
        } catch {
            // Try the next candidate.
        }
    }
    return '';
}

const godotExe = findGodot();
if (!godotExe) {
    console.error('[ERROR] 找不到 Godot。请设置 GODOT_EXE 环境变量。');
    process.exit(1);
}

const templatesDir = path.join(
    process.env.APPDATA || path.join(process.env.HOME, 'AppData', 'Roaming'),
    'Godot', 'export_templates', TEMPLATE_VERSION
);
if (!fs.existsSync(path.join(templatesDir, 'web_debug.zip')) &&
    !fs.existsSync(path.join(templatesDir, 'web_release.zip'))) {
    console.error('[ERROR] Web 导出模板不存在:', templatesDir);
    process.exit(1);
}

fs.rmSync(BUILD_DIR, { recursive: true, force: true });
fs.mkdirSync(BUILD_DIR, { recursive: true });

console.log('[INFO] Godot:', godotExe);
console.log('[INFO] 项目:', PROJECT_DIR);
console.log('[INFO] 输出:', BUILD_DIR);

try {
    execFileSync(godotExe, [
        '--headless',
        '--path', PROJECT_DIR,
        '--export-release', EXPORT_PRESET,
        path.join(BUILD_DIR, 'index.html'),
    ], {
        cwd: PROJECT_DIR,
        stdio: 'inherit',
        timeout: 300000,
    });
    const pckPath = path.join(BUILD_DIR, 'index.pck');
    if (!fs.existsSync(pckPath)) {
        throw new Error('index.pck was not generated');
    }
    const pckSize = fs.statSync(pckPath).size;
    const pckSizeMb = (pckSize / 1024 / 1024).toFixed(1);
    if (pckSize > PCK_FAIL_BYTES) {
        throw new Error(`index.pck is ${pckSizeMb} MB, over the 400 MB failure threshold`);
    }
    if (pckSize > PCK_WARN_BYTES) {
        console.warn(`[WARN] index.pck is ${pckSizeMb} MB, over the 250 MB warning threshold`);
    }
    console.log('[SUCCESS] Web 构建完成:', fs.readdirSync(BUILD_DIR).join(', '));
} catch (error) {
    console.error('[ERROR] Web 构建失败:', error.message);
    process.exit(1);
}
