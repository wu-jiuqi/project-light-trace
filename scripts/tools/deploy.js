/**
 * Shuoguang Project - deployment package helper.
 *
 * local:       start the shared local preview server.
 * cloudstudio: generate static assets plus a shared server wrapper.
 * cnb:         generate static assets used by the CNB Docker image.
 */

const fs = require('fs');
const crypto = require('crypto');
const path = require('path');
const { applyWebAudioGate } = require('./web-audio-gate.js');

const PROJECT_DIR = path.resolve(__dirname, '..', '..');
const BUILD_DIR = path.join(PROJECT_DIR, 'build', 'web');
const DEPLOY_DIR = path.join(PROJECT_DIR, 'deploy');
const DEPLOY_STAGING_DIR = path.join(PROJECT_DIR, 'deploy.tmp');
const PLATFORM = process.argv[2] || 'local';
const BUILD_MARKER = '.build-complete.json';

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

function requireBuildOutput() {
    const requiredFiles = [
        'index.html',
        'index.js',
        'index.wasm',
        'index.pck',
        'fragment-0001-tv.mp4',
        BUILD_MARKER,
    ];
    const missingFiles = requiredFiles.filter(file => !fs.existsSync(path.join(BUILD_DIR, file)));
    if (missingFiles.length > 0) {
        console.error('[ERROR] Build output is missing. Run: npm run build');
        process.exit(1);
    }
    let marker;
    try {
        marker = JSON.parse(fs.readFileSync(path.join(BUILD_DIR, BUILD_MARKER), 'utf8'));
    } catch (error) {
        console.error('[ERROR] Build completion marker is invalid. Run: npm run build');
        process.exit(1);
    }
    const pckPath = path.join(BUILD_DIR, 'index.pck');
    const pckSize = fs.statSync(pckPath).size;
    const pckSha256 = sha256File(pckPath);
    if (marker.pck_size !== pckSize || marker.pck_sha256 !== pckSha256) {
        console.error('[ERROR] Build files do not match their completion marker. Run: npm run build');
        process.exit(1);
    }
}

function writeSharedServerWrapper(relativeRequirePath, outputDir = DEPLOY_DIR) {
    fs.writeFileSync(path.join(outputDir, 'server.js'), [
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
    fs.rmSync(DEPLOY_STAGING_DIR, { recursive: true, force: true });
    fs.mkdirSync(DEPLOY_STAGING_DIR, { recursive: true });
    for (const file of fs.readdirSync(BUILD_DIR)) {
        const source = path.join(BUILD_DIR, file);
        const destination = path.join(DEPLOY_STAGING_DIR, file);
        if (fs.statSync(source).isDirectory()) {
            fs.cpSync(source, destination, { recursive: true });
        } else {
            fs.copyFileSync(source, destination);
        }
    }
    applyWebAudioGate(path.join(DEPLOY_STAGING_DIR, 'index.html'));

    const deployToolsDir = path.join(DEPLOY_STAGING_DIR, 'scripts', 'tools');
    fs.mkdirSync(deployToolsDir, { recursive: true });
    fs.copyFileSync(path.join(__dirname, 'serve.js'), path.join(deployToolsDir, 'serve.js'));
    writeSharedServerWrapper('./scripts/tools/serve.js', DEPLOY_STAGING_DIR);

    if (platform === 'cloudstudio') {
        fs.writeFileSync(path.join(DEPLOY_STAGING_DIR, '.cloudstudio.yaml'), JSON.stringify({
            name: 'Shuoguang Project',
            port: 8080,
            command: 'HOST=0.0.0.0 PORT=8080 node server.js',
        }, null, 2));
    }

    fs.rmSync(DEPLOY_DIR, { recursive: true, force: true });
    fs.renameSync(DEPLOY_STAGING_DIR, DEPLOY_DIR);

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
