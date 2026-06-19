/**
 * Shuoguang Project - Godot Web build helper.
 *
 * Optional env:
 *   GODOT_EXE
 *   GODOT_TEMPLATE_VERSION
 */

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

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

function assertWebTemplatesInstalled() {
    const templatesDir = path.join(
        process.env.APPDATA || path.join(process.env.HOME, 'AppData', 'Roaming'),
        'Godot', 'export_templates', TEMPLATE_VERSION
    );
    if (!fs.existsSync(path.join(templatesDir, 'web_debug.zip')) &&
        !fs.existsSync(path.join(templatesDir, 'web_release.zip'))) {
        throw new Error(`Web export templates are missing: ${templatesDir}`);
    }
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
}

function exportPack(godotExe, pack) {
    const packPath = path.join(BUILD_DIR, 'packs', pack.file);
    execFileSync(godotExe, [
        '--headless',
        '--path', PROJECT_DIR,
        '--export-pack', pack.preset,
        packPath,
    ], {
        cwd: PROJECT_DIR,
        stdio: 'inherit',
        timeout: 300000,
    });
    if (!fs.existsSync(packPath)) {
        throw new Error(`${pack.file} was not generated`);
    }
    return fs.statSync(packPath).size;
}

function formatMb(bytes) {
    return (bytes / 1024 / 1024).toFixed(1);
}

const godotExe = findGodot();
if (!godotExe) {
    console.error('[ERROR] Godot executable not found. Set GODOT_EXE if needed.');
    process.exit(1);
}

try {
    assertWebTemplatesInstalled();

    fs.rmSync(BUILD_DIR, { recursive: true, force: true });
    fs.mkdirSync(path.join(BUILD_DIR, 'packs'), { recursive: true });

    console.log('[INFO] Godot:', godotExe);
    console.log('[INFO] Project:', PROJECT_DIR);
    console.log('[INFO] Output:', BUILD_DIR);

    exportRelease(godotExe);
    const pckPath = path.join(BUILD_DIR, 'index.pck');
    if (!fs.existsSync(pckPath)) {
        throw new Error('index.pck was not generated');
    }

    const pckSize = fs.statSync(pckPath).size;
    if (pckSize > PCK_FAIL_BYTES) {
        throw new Error(`index.pck is ${formatMb(pckSize)} MB, over the 400 MB failure threshold`);
    }
    if (pckSize > PCK_WARN_BYTES) {
        console.warn(`[WARN] index.pck is ${formatMb(pckSize)} MB, over the 250 MB warning threshold`);
    }
    console.log(`[INFO] index.pck: ${formatMb(pckSize)} MB`);

    for (const pack of PACK_EXPORTS) {
        const packSize = exportPack(godotExe, pack);
        console.log(`[INFO] ${pack.file}: ${formatMb(packSize)} MB`);
    }

    console.log('[SUCCESS] Web build complete:', fs.readdirSync(BUILD_DIR).join(', '));
} catch (error) {
    console.error('[ERROR] Web build failed:', error.message);
    process.exit(1);
}
