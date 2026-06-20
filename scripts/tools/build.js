/**
 * Shuoguang Project - Godot Web build helper.
 *
 * Optional env:
 *   GODOT_EXE
 *   GODOT_TEMPLATE_VERSION
 */

const { execFileSync, spawnSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { applyWebAudioGate } = require('./web-audio-gate.js');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');
const EXPORT_PRESET = 'Web (HTML5)';
const PACK_EXPORTS = [
    { preset: 'Web Pack Fragment 0002', file: 'fragment_0002.pck' },
    { preset: 'Web Pack Fragment 0003', file: 'fragment_0003.pck' },
    { preset: 'Web Pack Fragment 0004', file: 'fragment_0004.pck' },
];
const TEMPLATE_VERSION = process.env.GODOT_TEMPLATE_VERSION || '4.6.2.stable';
const PCK_WARN_BYTES = 250 * 1024 * 1024;
const PCK_FAIL_BYTES = 700 * 1024 * 1024;
const BUILD_MARKER = '.build-complete.json';
const WEB_TV_VIDEO_SOURCE = path.join(
    PROJECT_DIR, 'assets', 'web', 'fragment-0001-tv.mp4'
);
const WEB_TV_VIDEO_FILE = 'fragment-0001-tv.mp4';
const WEB_AUDIO_SOURCE = path.join(PROJECT_DIR, 'assets', 'audio');
const WEB_AUDIO_OUTPUT = path.join(BUILD_DIR, 'assets', 'audio');
const GODOT_CANDIDATES = [
    process.env.GODOT_EXE,
    'D:/Godot/Godot_v4.6.2-stable_win64_console.exe',
    'godot4',
    'godot',
].filter(Boolean);

function sha256File(filePath) {
    const hash = crypto.createHash('sha256');
    const buffer = Buffer.allocUnsafe(1024 * 1024);
    const fd = fs.openSync(filePath, 'r');
    try {
        let bytesRead;
        do {
            bytesRead = fs.readSync(fd, buffer, 0, buffer.length, null);
            if (bytesRead > 0) hash.update(buffer.subarray(0, bytesRead));
        } while (bytesRead > 0);
    } finally {
        fs.closeSync(fd);
    }
    return hash.digest('hex');
}

function formatMb(bytes) {
    return (bytes / (1024 * 1024)).toFixed(1);
}

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

function validatePack(godotExe, pckPath) {
    const smoke = spawnSync(godotExe, [
        '--headless',
        '--main-pack', pckPath,
        '--quit-after', '3',
    ], {
        cwd: BUILD_DIR,
        encoding: 'utf8',
        timeout: 30000,
        windowsHide: true,
    });
    const output = `${smoke.stdout || ''}\n${smoke.stderr || ''}`;
    const fatalPattern = /SCRIPT ERROR|Failed to load script|Preload file .* does not exist/i;
    if (smoke.error || smoke.status !== 0 || fatalPattern.test(output)) {
        const relevant = output.split(/\r?\n/)
            .filter(line => fatalPattern.test(line))
            .slice(0, 12)
            .join('\n');
        throw new Error(`PCK startup smoke test failed${relevant ? `:\n${relevant}` : ''}`);
    }
    console.log('[PASS] PCK startup smoke test');
}

// 清理上次构建残留，避免 UID 冲突
if (fs.existsSync(BUILD_DIR)) {
    fs.rmSync(BUILD_DIR, { recursive: true, force: true });
}
fs.mkdirSync(BUILD_DIR, { recursive: true });

const godotExe = findGodot();
if (!godotExe) {
    console.error('[ERROR] 找不到 Godot。请设置 GODOT_EXE 环境变量。');
    process.exit(1);
}

function exportRelease(godotExe) {
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
    applyWebAudioGate(path.join(BUILD_DIR, 'index.html'));
    if (!fs.existsSync(WEB_TV_VIDEO_SOURCE)) {
        throw new Error(`Web TV video is missing: ${WEB_TV_VIDEO_SOURCE}`);
    }
    fs.copyFileSync(WEB_TV_VIDEO_SOURCE, path.join(BUILD_DIR, WEB_TV_VIDEO_FILE));
    if (!fs.existsSync(WEB_AUDIO_SOURCE)) {
        throw new Error(`Web audio source directory is missing: ${WEB_AUDIO_SOURCE}`);
    }
    fs.cpSync(WEB_AUDIO_SOURCE, WEB_AUDIO_OUTPUT, { recursive: true });
    // 复制 papercraft 动画中的 .ogg/.mp4 文件，供 Web 原生音频桥接直接访问
    const PAPERCRAFT_FRAGMENTS_DIR = path.join(PROJECT_DIR, 'assets', 'papercraft', 'fragments');
    if (fs.existsSync(PAPERCRAFT_FRAGMENTS_DIR)) {
        for (const fragId of fs.readdirSync(PAPERCRAFT_FRAGMENTS_DIR)) {
            const animSrc = path.join(PAPERCRAFT_FRAGMENTS_DIR, fragId, 'animation');
            if (!fs.existsSync(animSrc)) continue;
            const animDst = path.join(BUILD_DIR, 'assets', 'papercraft', 'fragments', fragId, 'animation');
            fs.mkdirSync(animDst, { recursive: true });
            for (const file of fs.readdirSync(animSrc)) {
                if (file.endsWith('.ogg') || file.endsWith('.mp4')) {
                    fs.copyFileSync(path.join(animSrc, file), path.join(animDst, file));
                }
            }
        }
    }
    const pckPath = path.join(BUILD_DIR, 'index.pck');
    if (!fs.existsSync(pckPath)) {
        throw new Error('index.pck was not generated');
    }
    validatePack(godotExe, pckPath);
    const pckSize = fs.statSync(pckPath).size;
    if (pckSize > PCK_FAIL_BYTES) {
        throw new Error(`index.pck is ${formatMb(pckSize)} MB, over the 400 MB failure threshold`);
    }
    if (pckSize > PCK_WARN_BYTES) {
        console.warn(`[WARN] index.pck is ${formatMb(pckSize)} MB, over the 250 MB warning threshold`);
    }
    const pckSha256 = sha256File(pckPath);
    fs.writeFileSync(path.join(BUILD_DIR, BUILD_MARKER), JSON.stringify({
        completed_at: new Date().toISOString(),
        pck_file: 'index.pck',
        pck_size: pckSize,
        pck_sha256: pckSha256,
    }, null, 2) + '\n', 'utf8');
    console.log('[SUCCESS] Web 构建完成:', fs.readdirSync(BUILD_DIR).join(', '));
}

try {
    exportRelease(godotExe);
} catch (error) {
    fs.rmSync(BUILD_DIR, { recursive: true, force: true });
    console.error('[ERROR] Web 构建失败:', error.message);
    process.exit(1);
}
