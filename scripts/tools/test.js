/**
 * Project regression checks that do not require a configured model API key.
 */

const fs = require('fs');
const http = require('http');
const path = require('path');
const { createServer } = require('./serve.js');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
let failures = 0;

function check(condition, message) {
    if (condition) {
        console.log('[PASS]', message);
    } else {
        failures += 1;
        console.error('[FAIL]', message);
    }
}

function walk(directory) {
    if (!fs.existsSync(directory)) return [];
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
        const file = path.join(directory, entry.name);
        return entry.isDirectory() ? walk(file) : [file];
    });
}

function checkJsonFiles() {
    const roots = ['resources', path.join('design', 'npcs', 'knowledge'), 'AI资源库'];
    for (const root of roots) {
        for (const file of walk(path.join(PROJECT_DIR, root)).filter(name => name.endsWith('.json'))) {
            try {
                const payload = JSON.parse(fs.readFileSync(file, 'utf8'));
                check(true, `JSON 可解析: ${path.relative(PROJECT_DIR, file)}`);
                if (Array.isArray(payload.chunks) && Number.isInteger(payload._total_chunks)) {
                    check(
                        payload.chunks.length === payload._total_chunks,
                        `知识块计数一致: ${path.relative(PROJECT_DIR, file)}`
                    );
                }
            } catch (error) {
                check(false, `JSON 可解析: ${path.relative(PROJECT_DIR, file)} (${error.message})`);
            }
        }
    }
}

function checkProjectConfiguration() {
    const packageJson = JSON.parse(fs.readFileSync(path.join(PROJECT_DIR, 'package.json'), 'utf8'));
    for (const [name, command] of Object.entries(packageJson.scripts)) {
        const match = command.match(/^node\s+([^\s]+)/);
        if (match) {
            check(fs.existsSync(path.join(PROJECT_DIR, match[1])), `npm ${name} 入口存在`);
        }
    }

    const llmClient = fs.readFileSync(path.join(PROJECT_DIR, 'scripts', 'systems', 'llm_client.gd'), 'utf8');
    check(!/sk-[A-Za-z0-9_-]{20,}/.test(llmClient), '客户端源码不包含供应商密钥');
    check(llmClient.includes('"/api/chat/completions"'), '客户端使用同源代理路径');

    const preset = fs.readFileSync(path.join(PROJECT_DIR, 'export_presets.cfg'), 'utf8');
    for (const pattern of [
        'build/**',
        'deploy/**',
        'addons/**',
        'AI资源库/**',
        'generated/**',
        'scripts/tools/**',
        'scripts/tests/**',
        'package.json',
    ]) {
        check(preset.includes(pattern), `Web 导出排除 ${pattern}`);
    }

    const projectSettings = fs.readFileSync(path.join(PROJECT_DIR, 'project.godot'), 'utf8');
    const webFontPath = path.join(PROJECT_DIR, 'assets', 'fonts', 'NotoSansSC-VF.ttf');
    check(fs.existsSync(webFontPath), 'Web 中文字体文件存在');
    check(
        projectSettings.includes('theme/custom_font="res://assets/fonts/NotoSansSC-VF.ttf"'),
        'Godot 全局默认字体已配置'
    );

    const uiAssets = [
        'title_background.png',
        'star_map_background.png',
        'panel_frame.svg',
        'panel_frame_soft.svg',
        'button_normal.svg',
        'button_hover.svg',
        'button_pressed.svg',
        'button_disabled.svg',
        'input_frame.svg',
        'progress_frame.svg',
        'progress_fill.svg',
    ];
    for (const asset of uiAssets) {
        check(fs.existsSync(path.join(PROJECT_DIR, 'assets', 'ui', asset)), `UI 美术资源存在: ${asset}`);
    }

    const webUiFiles = [
        'scenes/star_map.tscn',
        'scripts/star_map/star_map.gd',
        'scripts/ui/title_screen.gd',
        'scripts/ui/pause_menu.gd',
        'scripts/ui/backpack_ui.gd',
        'scripts/ui/chat_dialogue.gd',
        'scripts/ui/dialogue.gd',
        'scripts/systems/inventory_manager.gd',
        'scripts/fragment/fragment_0762_state.gd',
    ];
    const unsupportedWebGlyphs = ['🔒', '🔓', '⏳', '🔍', '✅', '💎', '🚀', '🎒', '❓', '📜', '🪻', '🔥', '🚫', '⚠️', '✦', '▶', '◀', '▼'];
    const webUiSource = webUiFiles
        .map(file => fs.readFileSync(path.join(PROJECT_DIR, file), 'utf8'))
        .join('\n');
    for (const glyph of unsupportedWebGlyphs) {
        check(!webUiSource.includes(glyph), `Web UI 不依赖未打包符号: ${glyph}`);
    }
}

function request(port, requestPath, options = {}) {
    return new Promise((resolve, reject) => {
        const req = http.request({
            host: '127.0.0.1',
            port,
            path: requestPath,
            method: options.method || 'GET',
            headers: options.headers || {},
        }, res => {
            const chunks = [];
            res.on('data', chunk => chunks.push(chunk));
            res.on('end', () => resolve({
                status: res.statusCode,
                headers: res.headers,
                body: Buffer.concat(chunks).toString('utf8'),
            }));
        });
        req.on('error', reject);
        if (options.body) req.write(options.body);
        req.end();
    });
}

async function checkServer() {
    const oldKey = process.env.DEEPSEEK_API_KEY;
    delete process.env.DEEPSEEK_API_KEY;
    const server = createServer();
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const port = server.address().port;
    try {
        const page = await request(port, '/index.html?cache=1');
        check(page.status === 200, '静态服务支持查询参数');
        check(page.headers['cross-origin-opener-policy'] === 'same-origin', '静态服务返回 COOP');
        check(page.headers['cross-origin-embedder-policy'] === 'require-corp', '静态服务返回 COEP');

        const traversal = await request(port, '/..%2fpackage.json');
        check(traversal.status === 403, '静态服务阻止目录穿越');

        const proxy = await request(port, '/api/chat/completions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ messages: [{ role: 'user', content: 'ping' }] }),
        });
        check(proxy.status === 503, '未配置服务端 Key 时代理明确拒绝请求');
    } finally {
        await new Promise(resolve => server.close(resolve));
        if (oldKey === undefined) delete process.env.DEEPSEEK_API_KEY;
        else process.env.DEEPSEEK_API_KEY = oldKey;
    }
}

async function main() {
    checkJsonFiles();
    checkProjectConfiguration();
    await checkServer();
    if (failures > 0) {
        console.error(`[SUMMARY] ${failures} 项检查失败`);
        process.exit(1);
    }
    console.log('[SUMMARY] Node 回归检查全部通过');
}

main().catch(error => {
    console.error('[FAIL] 回归脚本异常:', error);
    process.exit(1);
});
