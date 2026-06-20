/**
 * Shuoguang Project - static Web preview and same-origin LLM proxy.
 *
 * Server env:
 *   HOST                         Optional, defaults to 127.0.0.1. Docker/CNB uses 0.0.0.0.
 *   PORT                         Optional, defaults to 3000.
 *   SHUOGUANG_WEB_ROOT           Optional static file root.
 *   LLM_PROVIDER                 cnb | deepseek. Defaults to cnb when CNB_TOKEN exists, else deepseek.
 *   CORP_POLICY                  Optional Cross-Origin-Resource-Policy value, defaults to same-origin.
 *   LLM_ALLOWED_ORIGINS          Optional comma separated production origins.
 *   LLM_RATE_LIMIT_WINDOW_MS     Optional rate limit window, defaults to 60000.
 *   LLM_RATE_LIMIT_MAX           Optional max proxy requests per window, defaults to 30.
 */

const fs = require('fs');
const http = require('http');
const https = require('https');
const path = require('path');

const PROJECT_OR_PACKAGE_DIR = path.resolve(__dirname, '..', '..');
const DEFAULT_BUILD_DIR = path.join(PROJECT_OR_PACKAGE_DIR, 'build', 'web');
const BUILD_DIR = path.resolve(
    process.env.SHUOGUANG_WEB_ROOT ||
    (fs.existsSync(path.join(PROJECT_OR_PACKAGE_DIR, 'index.html'))
        ? PROJECT_OR_PACKAGE_DIR
        : DEFAULT_BUILD_DIR)
);
const DEFAULT_HOST = process.env.HOST || '127.0.0.1';
const DEFAULT_PORT = parseInt(process.env.PORT, 10) || 3000;
const MAX_REQUEST_BYTES = 256 * 1024;
const MAX_MESSAGES = 18;
const MAX_MESSAGE_CHARS = 12000;
const MAX_TOTAL_MESSAGE_CHARS = 60000;
const API_PATH = '/api/chat/completions';
const PROVIDER = (process.env.LLM_PROVIDER || (process.env.CNB_TOKEN ? 'cnb' : 'deepseek')).toLowerCase();
const PROVIDER_MODEL = process.env.MODEL_ID || process.env.DEEPSEEK_MODEL || 'deepseek-v4-flash';
const RATE_LIMIT_WINDOW_MS = parseInt(process.env.LLM_RATE_LIMIT_WINDOW_MS, 10) || 60000;
const RATE_LIMIT_MAX = parseInt(process.env.LLM_RATE_LIMIT_MAX, 10) || 30;
const IS_PRODUCTION = process.env.NODE_ENV === 'production';

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript',
    '.wasm': 'application/wasm',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.css': 'text/css; charset=utf-8',
    '.json': 'application/json',
    '.pck': 'application/octet-stream',
    '.ico': 'image/x-icon',
    '.ttf': 'font/ttf',
    '.ogg': 'audio/ogg',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.mp4': 'video/mp4',
};

const WEB_HEADERS = {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Resource-Policy': process.env.CORP_POLICY || 'same-origin',
};

const rateBuckets = new Map();

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
                reject(new Error('request body too large'));
                req.destroy();
                return;
            }
            chunks.push(chunk);
        });
        req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
        req.on('error', reject);
    });
}

function getClientIp(req) {
    const forwarded = String(req.headers['x-forwarded-for'] || '').split(',')[0].trim();
    return forwarded || req.socket.remoteAddress || 'unknown';
}

function isRateLimited(req) {
    const key = getClientIp(req);
    const now = Date.now();
    const bucket = rateBuckets.get(key) || { count: 0, resetAt: now + RATE_LIMIT_WINDOW_MS };
    if (now > bucket.resetAt) {
        bucket.count = 0;
        bucket.resetAt = now + RATE_LIMIT_WINDOW_MS;
    }
    bucket.count += 1;
    rateBuckets.set(key, bucket);
    return bucket.count > RATE_LIMIT_MAX;
}

function allowedOrigins(req) {
    const configured = (process.env.LLM_ALLOWED_ORIGINS || '')
        .split(',')
        .map(value => value.trim())
        .filter(Boolean);
    if (configured.length > 0) return configured;

    const host = req.headers['x-forwarded-host'] || req.headers.host;
    const proto = req.headers['x-forwarded-proto'] || (req.socket.encrypted ? 'https' : 'http');
    return host ? [`${proto}://${host}`] : [];
}

function assertSameOriginRequest(req) {
    if (!IS_PRODUCTION) return;

    const fetchSite = String(req.headers['sec-fetch-site'] || '').toLowerCase();
    if (fetchSite === 'cross-site') {
        throw Object.assign(new Error('cross-site requests are not allowed'), { statusCode: 403 });
    }

    // When the browser confirms same-origin via Sec-Fetch-Site, allow the
    // request even without an Origin header. Programmatic HTTP clients
    // (e.g. Godot's Emscripten HTTPClient via XMLHttpRequest/fetch) may not
    // send Origin for same-origin requests.
    if (fetchSite === 'same-origin') return;

    const origin = req.headers.origin || req.headers.referer;
    if (!origin) {
        throw Object.assign(new Error('missing origin'), { statusCode: 403 });
    }

    let requestOrigin;
    try {
        requestOrigin = new URL(origin).origin;
    } catch {
        throw Object.assign(new Error('invalid origin'), { statusCode: 403 });
    }

    if (!allowedOrigins(req).includes(requestOrigin)) {
        throw Object.assign(new Error('origin is not allowed'), { statusCode: 403 });
    }
}

function sanitizeMessages(payload) {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        throw Object.assign(new Error('payload must be an object'), { statusCode: 400 });
    }
    if (payload.stream !== true) {
        throw Object.assign(new Error('stream must be true'), { statusCode: 400 });
    }
    if (typeof payload.npc_id !== 'string' || payload.npc_id.length > 64) {
        throw Object.assign(new Error('npc_id is required'), { statusCode: 400 });
    }
    if (!Array.isArray(payload.messages) || payload.messages.length === 0 || payload.messages.length > MAX_MESSAGES) {
        throw Object.assign(new Error('messages shape is invalid'), { statusCode: 400 });
    }

    let totalChars = 0;
    const allowedRoles = new Set(['system', 'user', 'assistant']);
    const messages = payload.messages.map(message => {
        if (!message || typeof message !== 'object' || Array.isArray(message)) {
            throw Object.assign(new Error('message must be an object'), { statusCode: 400 });
        }
        if (!allowedRoles.has(message.role) || typeof message.content !== 'string') {
            throw Object.assign(new Error('message role/content is invalid'), { statusCode: 400 });
        }
        if (message.content.length > MAX_MESSAGE_CHARS) {
            throw Object.assign(new Error('message is too long'), { statusCode: 400 });
        }
        totalChars += message.content.length;
        return { role: message.role, content: message.content };
    });
    if (totalChars > MAX_TOTAL_MESSAGE_CHARS) {
        throw Object.assign(new Error('messages are too long'), { statusCode: 400 });
    }
    if (messages[0].role !== 'system') {
        throw Object.assign(new Error('first message must be system'), { statusCode: 400 });
    }
    return messages;
}

function getProviderConfig() {
    if (PROVIDER === 'cnb') {
        const apiKey = process.env.API_KEY || process.env.CNB_TOKEN;
        const baseUrl = (process.env.BASE_URL || (
            process.env.CNB_REPO_SLUG
                ? `${process.env.CNB_API_ENDPOINT || 'https://api.cnb.cool'}/${process.env.CNB_REPO_SLUG}/-/ai-ide/v2`
                : ''
        )).replace(/\/+$/, '');
        if (!apiKey || !baseUrl) {
            throw Object.assign(new Error('CNB LLM credentials are not configured'), { statusCode: 503 });
        }
        return { apiKey, url: new URL(`${baseUrl}/chat/completions`), label: 'CNB' };
    }

    if (PROVIDER === 'deepseek') {
        const apiKey = process.env.DEEPSEEK_API_KEY;
        if (!apiKey) {
            throw Object.assign(new Error('DEEPSEEK_API_KEY is not configured'), { statusCode: 503 });
        }
        const host = process.env.DEEPSEEK_API_HOST || 'api.deepseek.com';
        const providerPath = process.env.DEEPSEEK_API_PATH || '/v1/chat/completions';
        return { apiKey, url: new URL(`https://${host}${providerPath}`), label: 'DeepSeek' };
    }

    throw Object.assign(new Error(`unknown LLM_PROVIDER: ${PROVIDER}`), { statusCode: 503 });
}

function requestProviderStream(messages, res) {
    return new Promise((resolve, reject) => {
        const provider = getProviderConfig();
        const body = JSON.stringify({
            model: PROVIDER_MODEL,
            messages,
            max_tokens: 512,
            temperature: 0.8,
            stream: true,
        });
        const upstream = https.request({
            hostname: provider.url.hostname,
            port: provider.url.port || 443,
            path: provider.url.pathname + provider.url.search,
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${provider.apiKey}`,
                'Content-Type': 'application/json',
                'Accept': 'text/event-stream',
                'Content-Length': Buffer.byteLength(body),
            },
            timeout: 60000,
        }, response => {
            if (response.statusCode !== 200) {
                const chunks = [];
                response.on('data', chunk => chunks.push(chunk));
                response.on('end', () => {
                    const text = Buffer.concat(chunks).toString('utf8');
                    reject(new Error(`${provider.label} HTTP ${response.statusCode}: ${text.slice(0, 200)}`));
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
        upstream.on('timeout', () => upstream.destroy(new Error(`${provider.label} request timeout`)));
        upstream.on('error', reject);
        upstream.end(body);
    });
}

async function handleChatProxy(req, res) {
    if (req.method !== 'POST') {
        sendJson(res, 405, { error: 'Method Not Allowed' });
        return;
    }
    try {
        assertSameOriginRequest(req);
        if (isRateLimited(req)) {
            sendJson(res, 429, { error: 'Too Many Requests' });
            return;
        }
        const payload = JSON.parse(await collectBody(req));
        const messages = sanitizeMessages(payload);
        await requestProviderStream(messages, res);
    } catch (error) {
        if (res.headersSent) {
            res.end();
            return;
        }
        sendJson(res, error.statusCode || 502, { error: error.message });
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
    fs.stat(filePath, (statError, stat) => {
        if (statError || !stat.isFile()) {
            send(res, 404, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Not Found');
            return;
        }
        const ext = path.extname(filePath).toLowerCase();
        const range = req.headers.range;
        if (ext === '.mp4' && range) {
            const match = /^bytes=(\d*)-(\d*)$/.exec(range);
            if (!match) {
                send(res, 416, { 'Content-Range': `bytes */${stat.size}` });
                return;
            }
            const suffixLength = match[1] === '' ? Number(match[2]) : 0;
            const start = suffixLength > 0 ? Math.max(stat.size - suffixLength, 0) : Number(match[1]);
            const requestedEnd = match[1] === '' || match[2] === '' ? stat.size - 1 : Number(match[2]);
            const end = Math.min(requestedEnd, stat.size - 1);
            if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start < 0 || start > end) {
                send(res, 416, { 'Content-Range': `bytes */${stat.size}` });
                return;
            }
            const headers = {
                ...WEB_HEADERS,
                'Cache-Control': 'no-cache',
                'Content-Type': MIME[ext],
                'Accept-Ranges': 'bytes',
                'Content-Range': `bytes ${start}-${end}/${stat.size}`,
                'Content-Length': end - start + 1,
            };
            res.writeHead(206, headers);
            if (req.method === 'HEAD') {
                res.end();
                return;
            }
            fs.createReadStream(filePath, { start, end }).pipe(res);
            return;
        }
        fs.readFile(filePath, (error, data) => {
            if (error) {
                send(res, 404, { 'Content-Type': 'text/plain; charset=utf-8' }, 'Not Found');
                return;
            }
            const headers = { 'Content-Type': MIME[ext] || 'application/octet-stream' };
            if (ext === '.mp4') headers['Accept-Ranges'] = 'bytes';
            send(res, 200, headers, data);
        });
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
    createServer().listen(port, DEFAULT_HOST, () => {
        console.log('='.repeat(50));
        console.log('  Shuoguang Project - Web preview and LLM proxy');
        console.log(`  http://${DEFAULT_HOST}:${port}`);
        console.log('='.repeat(50));
        console.log('[INFO] Static root:', BUILD_DIR);
        console.log('[INFO] LLM provider:', PROVIDER);
    });
}

module.exports = {
    BUILD_DIR,
    DEFAULT_HOST,
    createServer,
    resolveStaticPath,
    sanitizeMessages,
    getProviderConfig,
};
