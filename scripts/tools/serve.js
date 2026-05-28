/**
 * 溯光计划 - 本地预览服务器
 * 
 * 基于 Node.js 零依赖的轻量 HTTP 服务器
 * 为 Godot Web 导出提供正确的 MIME 类型支持
 * 
 * 用法：node scripts/serve.js [port]
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const BUILD_DIR = path.join(__dirname, '..', '..', 'build', 'web');
const PORT = parseInt(process.argv[2]) || 3000;

// MIME 映射表 - 专门为 Godot Web 导出配置
const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript',
    '.wasm': 'application/wasm',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json',
    '.pck': 'application/octet-stream',
    '.ico': 'image/x-icon',
    '.worker.js': 'application/javascript',
    '.audio.worklet.js': 'application/javascript',
};

// 跨域隔离头 - 确保 SharedArrayBuffer 正常工作
const COOP_COEP_HEADERS = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
};

function getMimeType(filePath) {
    const ext = path.extname(filePath).toLowerCase();
    return MIME[ext] || 'application/octet-stream';
}

const server = http.createServer((req, res) => {
    let filePath = path.join(BUILD_DIR, req.url === '/' ? '/index.html' : req.url);
    
    // Security: prevent directory traversal
    filePath = path.normalize(filePath);
    if (!filePath.startsWith(BUILD_DIR)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Not Found');
            return;
        }

        const headers = {
            'Content-Type': getMimeType(filePath),
            ...COOP_COEP_HEADERS,
            'Cache-Control': 'no-cache',
        };

        res.writeHead(200, headers);
        res.end(data);
    });
});

server.listen(PORT, () => {
    console.log('='.repeat(50));
    console.log('  溯光计划 - 本地预览服务器');
    console.log(`  http://localhost:${PORT}`);
    console.log('='.repeat(50));
    console.log('[INFO] 服务目录:', BUILD_DIR);
    console.log('[INFO] 按 Ctrl+C 停止服务器');
});
