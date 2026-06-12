/**
 * 溯光计划 - Web 预览与同源 LLM 代理服务器
 *
 * 服务端环境变量：
 *   DEEPSEEK_API_KEY       必填，模型供应商密钥
 *   DEEPSEEK_MODEL         可选，默认 deepseek-v4-flash
 *   SHUOGUANG_WEB_ROOT     可选，静态文件目录
 */

const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');

const DEFAULT_BUILD_DIR = path.join(__dirname, '..', '..', 'build', 'web');
const BUILD_DIR = path.resolve(
    process.env.SHUOGUANG_WEB_ROOT ||
    (fs.existsSync(path.join(__dirname, 'index.html')) ? __dirname : DEFAULT_BUILD_DIR)
);
const DEFAULT_PORT = parseInt(process.env.PORT, 10) || 3000;
const MAX_REQUEST_BYTES = 1024 * 1024;
const API_PATH = '/api/chat/completions';
const PROVIDER_HOST = process.env.DEEPSEEK_API_HOST || 'api.deepseek.com';
const PROVIDER_PATH = process.env.DEEPSEEK_API_PATH || '/v1/chat/completions';
const PROVIDER_MODEL = process.env.DEEPSEEK_MODEL || 'deepseek-v4-flash';

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
};

const WEB_HEADERS = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Resource-Policy': 'same-origin',
};

function send(res, status, headers, body = '') {
    res.writeHead(status, { ...WEB_HEADERS, 'Cache-Control': 'no-cache', ...headers });
    if (res.req.method === 'HEAD') {
        res.end();
        return;
    }
    res.end(body);
}

function sendJson(res, status, payload) {
    send(res, status, { 'Content-Type': 'application/json; charset=utf-8' }, JSON.stringify(payload));
}

function collectBody(req) {
    return new Promise((resolve, reject) => {
        let size = 0;
        const chunks = [];
        req.on('data', chunk => {
            size += chunk.length;
            if (size > MAX_REQUEST_BYTES) {
                reject(new Error('请求体过大'));
                req.destroy();
                return;
            }
            chunks.push(chunk);
        });
        req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
        req.on('error', reject);
    });
}

function requestProvider(messages, apiKey) {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify({
            model: PROVIDER_MODEL,
            messages,
            max_tokens: 512,
            temperature: 0.8,
            stream: false,
        });
        const upstream = https.request({
            hostname: PROVIDER_HOST,
            port: 443,
            path: PROVIDER_PATH,
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'Content-Length': Buffer.byteLength(body),
            },
            timeout: 30000,
        }, response => {
            const chunks = [];
            response.on('data', chunk => chunks.push(chunk));
            response.on('end', () => {
                const text = Buffer.concat(chunks).toString('utf8');
                if (response.statusCode !== 200) {
                    reject(new Error(`DeepSeek HTTP ${response.statusCode}: ${text.slice(0, 200)}`));
                    return;
                }
                try {
                    const payload = JSON.parse(text);
                    const content = payload.choices?.[0]?.message?.content;
                    if (typeof content !== 'string' || !content) {
                        reject(new Error('DeepSeek 响应缺少文本'));
                        return;
                    }
                    resolve(content);
                } catch (error) {
                    reject(new Error(`DeepSeek 响应解析失败: ${error.message}`));
                }
            });
        });
        upstream.on('timeout', () => upstream.destroy(new Error('DeepSeek 请求超时')));
        upstream.on('error', reject);
        upstream.end(body);
    });
}

function requestProviderStream(messages, apiKey, res) {
    return new Promise((resolve, reject) => {
        const body = JSON.stringify({
            model: PROVIDER_MODEL,
            messages,
            max_tokens: 512,
            temperature: 0.8,
            stream: true,
        });
        const upstream = https.request({
            hostname: PROVIDER_HOST,
            port: 443,
            path: PROVIDER_PATH,
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream',
                'Content-Length': Buffer.byteLength(body),
            },
            timeout: 30000,
        }, response => {
            if (response.statusCode !== 200) {
                const chunks = [];
                response.on('data', chunk => chunks.push(chunk));
                response.on('end', () => {
                    const text = Buffer.concat(chunks).toString('utf8');
                    reject(new Error(`DeepSeek HTTP ${response.statusCode}: ${text.slice(0, 200)}`));
                });
                return;
            }

            res.writeHead(200, {
                ...WEB_HEADERS,
                'Cache-Control': 'no-cache',
                'Content-Type': 'text/event-stream; charset=utf-8',
                'Connection': 'keep-alive',
                'X-Accel-Buffering': 'no',
            });
            response.on('data', chunk => res.write(chunk));
            response.on('end', () => {
                res.end();
                resolve();
            });
        });
        upstream.on('timeout', () => upstream.destroy(new Error('DeepSeek 请求超时')));
        upstream.on('error', reject);
        upstream.end(body);
    });
}

async function handleChatProxy(req, res) {
    if (req.method !== 'POST') {
        sendJson(res, 405, { error: 'Method Not Allowed' });
        return;
    }
    const apiKey = process.env.DEEPSEEK_API_KEY;
    if (!apiKey) {
        sendJson(res, 503, { error: '服务端未配置 DEEPSEEK_API_KEY' });
        return;
    }
    try {
        const payload = JSON.parse(await collectBody(req));
        if (!Array.isArray(payload.messages) || payload.messages.length === 0) {
            sendJson(res, 400, { error: 'messages 必须是非空数组' });
            return;
        }
        if (payload.stream === true) {
            await requestProviderStream(payload.messages, apiKey, res);
            return;
        }
        const content = await requestProvider(payload.messages, apiKey);
        sendJson(res, 200, { content });
    } catch (error) {
        if (res.headersSent) {
            res.end();
            return;
        }
        sendJson(res, 502, { error: error.message });
    }
}

function resolveStaticPath(pathname) {
    const relativePath = pathname === '/' ? 'index.html' : decodeURIComponent(pathname).replace(/^[/\\]+/, '');
    const filePath = path.resolve(BUILD_DIR, relativePath);
    const relative = path.relative(BUILD_DIR, filePath);
    if (relative.startsWith('..') || path.isAbsolute(relative)) {
        return null;
    }
    return filePath;
}

function handleStatic(req, res, pathname) {
    if (!['GET', 'HEAD'].includes(req.method)) {
        send(res, 405, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Method Not Allowed');
        return;
    }
    let filePath;
    try {
        filePath = resolveStaticPath(pathname);
    } catch {
        send(res, 400, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Bad Request');
        return;
    }
    if (!filePath) {
        send(res, 403, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Forbidden');
        return;
    }
    fs.readFile(filePath, (error, data) => {
        if (error) {
            send(res, 404, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Not Found');
            return;
        }
        const ext = path.extname(filePath).toLowerCase();
        send(res, 200, { 'Content-Type': MIME[ext] || 'application/octet-stream' }, data);
    });
}

function createServer() {
    return http.createServer((req, res) => {
        let pathname;
        try {
            pathname = new URL(req.url, 'http://localhost').pathname;
        } catch {
            send(res, 400, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Bad Request');
            return;
        }
        if (pathname === API_PATH) {
            handleChatProxy(req, res);
            return;
        }
        handleStatic(req, res, pathname);
    });
}

if (require.main === module) {
    const port = parseInt(process.argv[2], 10) || DEFAULT_PORT;
    createServer().listen(port, () => {
        console.log('='.repeat(50));
        console.log('  溯光计划 - Web 预览与同源 LLM 代理');
        console.log(`  http://localhost:${port}`);
        console.log('='.repeat(50));
        console.log('[INFO] 静态目录:', BUILD_DIR);
        console.log('[INFO] DeepSeek Key:', process.env.DEEPSEEK_API_KEY ? '已配置' : '未配置');
    });
}

module.exports = { BUILD_DIR, createServer, resolveStaticPath };
