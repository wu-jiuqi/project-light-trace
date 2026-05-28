/**
 * 溯光计划 - 部署脚本
 * 
 * 将 Web 构建产物部署到在线平台
 * 支持: 本地静态服务 / Cloud Studio / 其他CDN
 * 
 * 用法: node scripts/deploy.js [platform]
 *   platform: local | cloudstudio | vercel
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const BUILD_DIR = path.join(__dirname, '..', '..', 'build', 'web');
const DEPLOY_DIR = path.join(__dirname, '..', '..', 'deploy');
const PLATFORM = process.argv[2] || 'local';

console.log('='.repeat(50));
console.log('  溯光计划 - 部署脚本');
console.log(`  部署平台: ${PLATFORM}`);
console.log('='.repeat(50));

// Check build exists
if (!fs.existsSync(path.join(BUILD_DIR, 'index.html'))) {
    console.error('[ERROR] 未找到构建产物！请先运行: npm run build');
    process.exit(1);
}

switch (PLATFORM) {
    case 'local':
        deployLocal();
        break;
    case 'cloudstudio':
        deployCloudStudio();
        break;
    default:
        console.log(`[INFO] 未知部署平台: ${PLATFORM}`);
        console.log('[INFO] 可用选项: local, cloudstudio');
        deployLocal();
}

function deployLocal() {
    console.log('[INFO] 部署到本地预览服务器...');
    console.log('[INFO] 运行: npm run serve');
    console.log('[SUCCESS] 构建产物已就绪，位于:', BUILD_DIR);
    
    // 自动启动本地服务器
    try {
        require('./serve.js');
    } catch (e) {
        console.log('[INFO] 使用以下命令启动本地服务器:');
        console.log('  npm run serve');
    }
}

function deployCloudStudio() {
    console.log('[INFO] 准备部署到 Cloud Studio...');
    
    // 复制到 deploy 目录
    if (!fs.existsSync(DEPLOY_DIR)) {
        fs.mkdirSync(DEPLOY_DIR, { recursive: true });
    }
    
    // 复制构建产物
    const files = fs.readdirSync(BUILD_DIR);
    for (const file of files) {
        fs.copyFileSync(
            path.join(BUILD_DIR, file),
            path.join(DEPLOY_DIR, file)
        );
    }
    
    // 创建 .cloudstudio.yaml 配置文件
    const csConfig = {
        name: '溯光计划',
        port: 8080,
        command: 'npx http-server . -p 8080 --cors -c-1',
    };
    
    fs.writeFileSync(
        path.join(DEPLOY_DIR, '.cloudstudio.yaml'),
        JSON.stringify(csConfig, null, 2)
    );
    
    console.log('[SUCCESS] Cloud Studio 部署包已准备完毕！');
    console.log('[INFO] 部署目录:', DEPLOY_DIR);
    console.log('[INFO] 使用方式:');
    console.log('  1. 登录 Cloud Studio');
    console.log('  2. 导入此目录');
    console.log('  3. 自动识别 .cloudstudio.yaml 配置');
    console.log('  4. 点击"运行"即可获得在线链接');
}
