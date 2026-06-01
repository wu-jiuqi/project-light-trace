/**
 * 溯光计划 - 部署包生成脚本
 *
 * local:       启动本地 Web 服务
 * cloudstudio: 生成包含静态资源、同源代理和 COOP/COEP 头的部署包
 */

const fs = require('fs');
const path = require('path');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');
const DEPLOY_DIR = path.join(PROJECT_DIR, 'deploy');
const PLATFORM = process.argv[2] || 'local';

if (!fs.existsSync(path.join(BUILD_DIR, 'index.html'))) {
    console.error('[ERROR] 未找到构建产物，请先运行: npm run build');
    process.exit(1);
}

if (PLATFORM === 'local') {
    require('./serve.js').createServer().listen(parseInt(process.env.PORT, 10) || 3000, () => {
        console.log('[SUCCESS] 本地服务已启动: http://localhost:3000');
    });
} else if (PLATFORM === 'cloudstudio') {
    fs.rmSync(DEPLOY_DIR, { recursive: true, force: true });
    fs.mkdirSync(DEPLOY_DIR, { recursive: true });
    for (const file of fs.readdirSync(BUILD_DIR)) {
        fs.copyFileSync(path.join(BUILD_DIR, file), path.join(DEPLOY_DIR, file));
    }
    fs.copyFileSync(path.join(__dirname, 'serve.js'), path.join(DEPLOY_DIR, 'server.js'));
    fs.writeFileSync(path.join(DEPLOY_DIR, '.cloudstudio.yaml'), JSON.stringify({
        name: '溯光计划',
        port: 8080,
        command: 'PORT=8080 node server.js',
    }, null, 2));
    console.log('[SUCCESS] Cloud Studio 部署包已生成:', DEPLOY_DIR);
    console.log('[INFO] 部署前请在平台密钥管理中设置 DEEPSEEK_API_KEY。');
} else {
    console.error('[ERROR] 未知部署平台:', PLATFORM);
    process.exit(1);
}
