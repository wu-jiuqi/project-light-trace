/**
 * Shuoguang Project - deployment package helper.
 *
 * local:       start the shared local preview server.
 * cloudstudio: generate static assets plus a shared server wrapper.
 * cnb:         generate static assets used by the CNB Docker image.
 */

const fs = require('fs');
const path = require('path');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');
const DEPLOY_DIR = path.join(PROJECT_DIR, 'deploy');
const PLATFORM = process.argv[2] || 'local';

function requireBuildOutput() {
    if (!fs.existsSync(path.join(BUILD_DIR, 'index.html'))) {
        console.error('[ERROR] Build output is missing. Run: npm run build');
        process.exit(1);
    }
}

function writeSharedServerWrapper(relativeRequirePath) {
    fs.writeFileSync(path.join(DEPLOY_DIR, 'server.js'), [
        `const { DEFAULT_HOST, createServer } = require('${relativeRequirePath}');`,
        "const port = parseInt(process.env.PORT, 10) || 8686;",
        "createServer().listen(port, DEFAULT_HOST, () => {",
        "    console.log(`Shuoguang preview listening on http://${DEFAULT_HOST}:${port}`);",
        "});",
        "",
    ].join('\n'));
}

function copyRecursive(src, dest) {
    const stat = fs.statSync(src);
    if (stat.isDirectory()) {
        fs.mkdirSync(dest, { recursive: true });
        for (const child of fs.readdirSync(src)) {
            copyRecursive(path.join(src, child), path.join(dest, child));
        }
        return;
    }
    fs.copyFileSync(src, dest);
}

function generateDeployPackage(platform) {
    requireBuildOutput();
    fs.rmSync(DEPLOY_DIR, { recursive: true, force: true });
    fs.mkdirSync(DEPLOY_DIR, { recursive: true });
    for (const file of fs.readdirSync(BUILD_DIR)) {
        copyRecursive(path.join(BUILD_DIR, file), path.join(DEPLOY_DIR, file));
    }

    const deployToolsDir = path.join(DEPLOY_DIR, 'scripts', 'tools');
    fs.mkdirSync(deployToolsDir, { recursive: true });
    fs.copyFileSync(path.join(__dirname, 'serve.js'), path.join(deployToolsDir, 'serve.js'));
    writeSharedServerWrapper('./scripts/tools/serve.js');

    if (platform === 'cloudstudio') {
        fs.writeFileSync(path.join(DEPLOY_DIR, '.cloudstudio.yaml'), JSON.stringify({
            name: 'Shuoguang Project',
            port: 8080,
            command: 'HOST=0.0.0.0 PORT=8080 node server.js',
        }, null, 2));
    }

    console.log('[SUCCESS] Deploy package generated:', DEPLOY_DIR);
}

if (PLATFORM === 'local') {
    const { DEFAULT_HOST, createServer } = require('./serve.js');
    const port = parseInt(process.env.PORT, 10) || 3000;
    createServer().listen(port, DEFAULT_HOST, () => {
        console.log(`[SUCCESS] Local preview started: http://${DEFAULT_HOST}:${port}`);
    });
} else if (PLATFORM === 'cloudstudio' || PLATFORM === 'cnb') {
    generateDeployPackage(PLATFORM);
} else {
    console.error('[ERROR] Unknown deploy platform:', PLATFORM);
    process.exit(1);
}
