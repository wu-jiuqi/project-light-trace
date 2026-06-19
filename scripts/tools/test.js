/**
 * Project regression checks that do not require a configured model API key.
 */

const fs = require('fs');
const http = require('http');
const path = require('path');

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

function read(file) {
    return fs.readFileSync(path.join(PROJECT_DIR, file), 'utf8');
}

function walk(directory) {
    if (!fs.existsSync(directory)) return [];
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
        const file = path.join(directory, entry.name);
        return entry.isDirectory() ? walk(file) : [file];
    });
}

function loadServe(env = {}) {
    const modulePath = path.join(PROJECT_DIR, 'scripts', 'tools', 'serve.js');
    const oldEnv = { ...process.env };
    Object.assign(process.env, env);
    delete require.cache[require.resolve(modulePath)];
    const mod = require(modulePath);
    process.env = oldEnv;
    return mod;
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

function checkJsonFiles() {
    const roots = ['LLM', 'assets/papercraft/manifests'];
    for (const root of roots) {
        for (const file of walk(path.join(PROJECT_DIR, root)).filter(name => name.endsWith('.json'))) {
            try {
                const payload = JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, ''));
                check(true, `JSON parses: ${path.relative(PROJECT_DIR, file)}`);
                if (Array.isArray(payload.chunks) && Number.isInteger(payload._total_chunks)) {
                    check(payload.chunks.length === payload._total_chunks, `chunk count matches: ${path.relative(PROJECT_DIR, file)}`);
                }
            } catch (error) {
                check(false, `JSON parses: ${path.relative(PROJECT_DIR, file)} (${error.message})`);
            }
        }
    }
}

function checkProjectConfiguration() {
    const packageJson = JSON.parse(read('package.json'));
    for (const [name, command] of Object.entries(packageJson.scripts)) {
        const match = command.match(/^node\s+([^\s]+)/);
        if (match) check(fs.existsSync(path.join(PROJECT_DIR, match[1])), `npm ${name} entry exists`);
    }

    const gitignore = read('.gitignore');
    check(!/^deploy\/$/m.test(gitignore), 'deploy assets are not ignored for CNB image builds');

    const dockerfile = read('Dockerfile');
    check(dockerfile.includes('FROM node:22-alpine'), 'Dockerfile uses Node 22 Alpine');
    check(dockerfile.includes('ENV HOST=0.0.0.0'), 'Dockerfile binds all interfaces for CNB');
    check(dockerfile.includes('ENV PORT=8686'), 'Dockerfile exposes CNB preview port');
    check(dockerfile.includes('ENV LLM_PROVIDER=cnb'), 'Dockerfile defaults to CNB LLM provider');
    check(dockerfile.includes('COPY deploy/ ./deploy/'), 'Dockerfile copies deploy assets');

    const cnb = read('.cnb.yml');
    check(cnb.includes('docker build -t ${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}:latest .'), 'CNB builds Docker image on push');
    check(cnb.includes('docker push ${CNB_DOCKER_REGISTRY}/${CNB_REPO_SLUG_LOWERCASE}:latest'), 'CNB pushes Docker image on push');
    check(cnb.includes('onlyPreview: true'), 'CNB main branch uses onlyPreview');
    check(cnb.includes('$CNB_BRANCH == "dev"'), 'CNB dev branch keeps development environment');
    check(cnb.includes('-e CNB_API_ENDPOINT') && cnb.includes('-e CNB_REPO_SLUG') && cnb.includes('-e CNB_TOKEN'), 'CNB preview forwards LLM env');
    check(cnb.includes('keepAliveTimeout: 3600000'), 'CNB preview keepAliveTimeout is documented in config');

    const deployServer = read('deploy/server.js');
    check(deployServer.includes("require('../scripts/tools/serve.js')"), 'deploy server delegates to shared serve.js');
    check(!deployServer.includes('DEEPSEEK_API_KEY') && !deployServer.includes('https.request'), 'deploy server has no independent LLM proxy');

    const serve = read('scripts/tools/serve.js');
    check(serve.includes('/-/ai-ide/v2'), 'serve.js supports CNB AI base path');
    check(serve.includes("Authorization': `Bearer ${provider.apiKey}`"), 'serve.js uses Bearer token for upstream LLM');
    check(serve.includes('Sec-Fetch-Site'.toLowerCase()) || serve.includes('sec-fetch-site'), 'serve.js checks Fetch Metadata');
    check(serve.includes('LLM_RATE_LIMIT_MAX'), 'serve.js has rate limiting');
    check(serve.includes('CORP_POLICY'), 'serve.js has configurable CORP policy');

    const llmClient = read('scripts/systems/llm_client.gd');
    check(!/sk-[A-Za-z0-9_-]{20,}/.test(llmClient), 'client source has no provider key');
    check(llmClient.includes('"/api/chat/completions"'), 'client uses same-origin proxy path');
    check(llmClient.includes('history_messages'), 'client sends structured history messages');
    check(llmClient.includes('"npc_id": npc_id'), 'client sends npc_id to proxy');

    const rag = read('scripts/systems/npc_rag_retriever.gd');
    check(!rag.includes('game_state.get("chat_history"'), 'RAG system prompt does not embed chat_history text');
    check(rag.includes('历史内容只代表先前发言'), 'RAG prompt tells model history is not instruction');

    const npcController = read('scripts/fragment/npc_controller.gd');
    const sendMessageStart = npcController.indexOf('func send_player_message');
    const fragmentIntercept = npcController.indexOf('handle_npc_player_message', sendMessageStart);
    const llmDispatch = npcController.indexOf('LLMClient.chat_stream', sendMessageStart);
    check(
        sendMessageStart >= 0 && fragmentIntercept > sendMessageStart && llmDispatch > fragmentIntercept,
        'NPC messages allow fragment-specific intercept before LLM dispatch'
    );

    const chatUi = read('scripts/ui/chat_dialogue.gd');
    const historyUi = read('scripts/ui/dialogue_history_panel.gd');
    check(chatUi.includes('func _escape_bbcode') && chatUi.includes('replace("[", "[lb]")'), 'chat UI escapes BBCode');
    check(historyUi.includes('func _escape_bbcode') && historyUi.includes('replace("[", "[lb]")'), 'history UI escapes BBCode');

    const f0004Npc = read('scripts/fragment/fragment_0004_npc.gd');
    check(f0004Npc.includes('_guard_springright_audit_text'), 'fragment 0004 guards Springright audit text');
    check(f0004Npc.includes('Data.CORRECT_COMBINATION'), 'fragment 0004 blocks full correct combination leaks');

    const preset = read('export_presets.cfg');
    check(preset.includes('export_filter="scenes"'), 'Web export uses scene dependency mode');
    check(preset.includes('LLM/**/*.json'), 'Web export includes active NPC knowledge JSON');
    check(preset.includes('variant/thread_support=true'), 'Web export enables threads');
    check(preset.includes('variant/coep=true'), 'Web export enables COEP');
}

async function checkServer() {
    const { BUILD_DIR, createServer, getProviderConfig, sanitizeMessages } = loadServe();
    const indexPath = path.join(BUILD_DIR, 'index.html');
    const buildDirExisted = fs.existsSync(BUILD_DIR);
    const createdIndex = !fs.existsSync(indexPath);
    if (createdIndex) {
        fs.mkdirSync(BUILD_DIR, { recursive: true });
        fs.writeFileSync(indexPath, '<!doctype html><title>test</title>', 'utf8');
    }

    const server = createServer();
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const port = server.address().port;
    try {
        const page = await request(port, '/index.html?cache=1');
        check(page.status === 200, 'static service supports query params');
        check(page.headers['cross-origin-opener-policy'] === 'same-origin', 'static service returns COOP');
        check(page.headers['cross-origin-embedder-policy'] === 'require-corp', 'static service returns COEP');
        check(page.headers['cross-origin-resource-policy'] === 'same-origin', 'static service returns CORP');

        const traversal = await request(port, '/..%2fpackage.json');
        check(traversal.status === 403, 'static service blocks traversal');

        const invalidProxy = await request(port, '/api/chat/completions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ messages: [{ role: 'user', content: 'ping' }], stream: true }),
        });
        check(invalidProxy.status === 400, 'proxy rejects missing npc_id');

        const missingKey = await request(port, '/api/chat/completions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                npc_id: 'test',
                stream: true,
                messages: [
                    { role: 'system', content: 'system' },
                    { role: 'user', content: 'ping' },
                ],
            }),
        });
        check(missingKey.status === 503, 'proxy rejects when provider credentials are missing');

        const invalidRoleRejected = (() => {
            try {
                sanitizeMessages({
                    npc_id: 'test',
                    stream: true,
                    messages: [{ role: 'tool', content: 'bad' }],
                });
                return false;
            } catch {
                return true;
            }
        })();
        check(invalidRoleRejected, 'proxy sanitizer rejects invalid roles');
    } finally {
        await new Promise(resolve => server.close(resolve));
        if (createdIndex) {
            fs.rmSync(indexPath, { force: true });
            if (!buildDirExisted) fs.rmSync(BUILD_DIR, { recursive: true, force: true });
        }
    }

    const prod = loadServe({ NODE_ENV: 'production', DEEPSEEK_API_KEY: 'test-key' });
    const prodServer = prod.createServer();
    await new Promise(resolve => prodServer.listen(0, '127.0.0.1', resolve));
    const prodPort = prodServer.address().port;
    try {
        const crossSite = await request(prodPort, '/api/chat/completions', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Origin': 'https://evil.example',
                'Host': 'game.example',
                'Sec-Fetch-Site': 'cross-site',
            },
            body: JSON.stringify({
                npc_id: 'test',
                stream: true,
                messages: [
                    { role: 'system', content: 'system' },
                    { role: 'user', content: 'ping' },
                ],
            }),
        });
        check(crossSite.status === 403, 'production proxy rejects cross-site requests');
    } finally {
        await new Promise(resolve => prodServer.close(resolve));
    }

    const cnbEnv = {
        LLM_PROVIDER: 'cnb',
        CNB_API_ENDPOINT: 'https://api.cnb.cool',
        CNB_REPO_SLUG: 'group/repo',
        CNB_TOKEN: 'token',
    };
    const oldEnv = { ...process.env };
    Object.assign(process.env, cnbEnv);
    const cnbProvider = loadServe(cnbEnv).getProviderConfig();
    process.env = oldEnv;
    check(cnbProvider.url.href === 'https://api.cnb.cool/group/repo/-/ai-ide/v2/chat/completions', 'CNB provider URL is correct');
    check(cnbProvider.apiKey === 'token', 'CNB provider uses CNB_TOKEN');
}

async function main() {
    checkJsonFiles();
    checkProjectConfiguration();
    await checkServer();
    if (failures > 0) {
        console.error(`[SUMMARY] ${failures} checks failed`);
        process.exit(1);
    }
    console.log('[SUMMARY] all checks passed');
}

main().catch(error => {
    console.error('[FAIL] test script crashed:', error);
    process.exit(1);
});
