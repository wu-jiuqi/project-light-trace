const fs = require('fs');

const GATE_STYLE = `
<style id="shuoguang-audio-gate-style">
#audio-start-gate {
	position: fixed;
	inset: 0;
	z-index: 20;
	display: flex;
	align-items: center;
	justify-content: center;
	background: #0d0d1f;
	color: #f4ead8;
	font-family: "Noto Serif SC", "Source Han Serif SC", "Microsoft YaHei", serif;
	cursor: pointer;
	user-select: none;
}

#audio-start-gate.hidden {
	display: none;
}

#audio-start-gate .audio-start-panel {
	display: flex;
	flex-direction: column;
	gap: 16px;
	align-items: center;
	padding: 28px 36px;
	border: 1px solid rgba(220, 186, 116, 0.5);
	background: rgba(16, 14, 28, 0.84);
	box-shadow: 0 18px 60px rgba(0, 0, 0, 0.35);
}

#audio-start-gate .audio-start-title {
	font-size: 24px;
	line-height: 1.3;
}

#audio-start-gate .audio-start-hint {
	color: #c9bda6;
	font-size: 14px;
	line-height: 1.5;
}

#shuoguang-tv-video {
	position: fixed;
	z-index: 15;
	display: none;
	margin: 0;
	padding: 0;
	border: 0;
	background: #000;
	object-fit: fill;
	pointer-events: none;
}
</style>`;

const GATE_MARKUP = `
		<div id="audio-start-gate" role="button" tabindex="0" aria-disabled="false" aria-label="开始游戏">
			<div class="audio-start-panel">
				<div class="audio-start-title">点击开始游戏</div>
				<div class="audio-start-hint">浏览器需要一次操作来启用游戏声音</div>
			</div>
		</div>`;

const AUTO_START_SNIPPET = `\t} else {
\t\tsetStatusMode('progress');
\t\tengine.startGame({
\t\t\t'onProgress': function (current, total) {
\t\t\t\tif (current > 0 && total > 0) {
\t\t\t\t\tstatusProgress.value = current;
\t\t\t\t\tstatusProgress.max = total;
\t\t\t\t} else {
\t\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t\t}
\t\t\t},
\t\t}).then(() => {
\t\t\tsetStatusMode('hidden');
\t\t}, displayFailureNotice);
\t}`;

const GATED_START_SNIPPET = `\t} else {
\t\tconst audioStartGate = document.getElementById('audio-start-gate');
\t\tconst audioStartTitle = audioStartGate?.querySelector('.audio-start-title');
\t\tconst audioStartHint = audioStartGate?.querySelector('.audio-start-hint');
\t\tlet gameStarted = false;
\t\tlet gameReady = false;
\t\tlet audioResumePending = false;

\t\tfunction createNativeAudioBridge() {
\t\t\tconst SILENT_WAV = 'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=';
\t\t\tconst volumes = { master: 1, bgm: 1, sfx: 1, ambience: 1, voice: 1 };
\t\t\tconst bgm = new Audio();
\t\t\tconst voice = new Audio();
\t\t\tconst ambiences = new Map();
\t\t\tconst sfxPlayers = new Set();
\t\t\tlet unlocked = false;
\t\t\tlet unlockPromise = null;
\t\t\tlet bgmId = '';
\t\t\tlet bgmDb = 0;
\t\t\tlet bgmDuckDb = 0;

\t\t\tbgm.preload = 'auto';
\t\t\tvoice.preload = 'auto';

\t\t\tfunction clamp(value, min, max) {
\t\t\t\treturn Math.min(max, Math.max(min, value));
\t\t\t}

\t\t\tfunction dbToLinear(db) {
\t\t\t\treturn Math.pow(10, Number(db || 0) / 20);
\t\t\t}

\t\t\tfunction assetUrl(resourcePath) {
\t\t\t\tconst relative = String(resourcePath || '').replace(/^res:\\/\\//, '');
\t\t\t\treturn new URL(relative, document.baseURI).href;
\t\t\t}

\t\t\tfunction setPlayerVolume(player, channel, db, extraDb = 0) {
\t\t\t\tplayer.__shuoguangChannel = channel;
\t\t\t\tplayer.__shuoguangDb = Number(db || 0);
\t\t\t\tplayer.__shuoguangExtraDb = Number(extraDb || 0);
\t\t\t\tplayer.volume = clamp(
\t\t\t\t\tvolumes.master * volumes[channel] * dbToLinear(player.__shuoguangDb + player.__shuoguangExtraDb),
\t\t\t\t\t0,
\t\t\t\t\t1
\t\t\t\t);
\t\t\t}

\t\t\tfunction refreshPlayerVolume(player) {
\t\t\t\tsetPlayerVolume(
\t\t\t\t\tplayer,
\t\t\t\t\tplayer.__shuoguangChannel || 'sfx',
\t\t\t\t\tplayer.__shuoguangDb || 0,
\t\t\t\t\tplayer.__shuoguangExtraDb || 0
\t\t\t\t);
\t\t\t}

\t\t\tfunction handlePlaybackFailure(error) {
\t\t\t\tunlocked = false;
\t\t\t\twindow.__shuoguangUserActivatedAudio = false;
\t\t\t\tconsole.warn('[NativeAudio] playback failed:', error);
\t\t\t\tif (gameReady) showAudioResumeGate('浏览器阻止了声音播放，请再次点击');
\t\t\t}

\t\t\tfunction safePlay(player) {
\t\t\t\tconst promise = player.play();
\t\t\t\tif (promise && typeof promise.catch === 'function') {
\t\t\t\t\tpromise.catch(handlePlaybackFailure);
\t\t\t\t}
\t\t\t}

\t\t\tfunction unlock() {
\t\t\t\tif (unlocked) return Promise.resolve(true);
\t\t\t\tif (unlockPromise) return unlockPromise;
\t\t\t\tconst primer = new Audio(SILENT_WAV);
\t\t\t\tprimer.volume = 0;
\t\t\t\tunlockPromise = primer.play().then(() => {
\t\t\t\t\tprimer.pause();
\t\t\t\t\tunlocked = true;
\t\t\t\t\twindow.__shuoguangUserActivatedAudio = true;
\t\t\t\t\tconsole.info('[NativeAudio] browser media playback unlocked');
\t\t\t\t\treturn true;
\t\t\t\t}).catch((error) => {
\t\t\t\t\thandlePlaybackFailure(error);
\t\t\t\t\treturn false;
\t\t\t\t}).finally(() => {
\t\t\t\t\tunlockPromise = null;
\t\t\t\t});
\t\t\t\treturn unlockPromise;
\t\t\t}

\t\t\tfunction stopPlayer(player) {
\t\t\t\tplayer.pause();
\t\t\t\ttry { player.currentTime = 0; } catch (_) { /* Metadata may not be loaded yet. */ }
\t\t\t}

\t\t\tfunction handle(request) {
\t\t\t\tif (!request || typeof request.method !== 'string') return false;
\t\t\t\tswitch (request.method) {
\t\t\t\t\tcase 'set_volumes':
\t\t\t\t\t\tfor (const key of Object.keys(volumes)) {
\t\t\t\t\t\t\tif (request[key] != null) volumes[key] = clamp(Number(request[key]), 0, 1);
\t\t\t\t\t\t}
\t\t\t\t\t\trefreshPlayerVolume(bgm);
\t\t\t\t\t\trefreshPlayerVolume(voice);
\t\t\t\t\t\tfor (const player of ambiences.values()) refreshPlayerVolume(player);
\t\t\t\t\t\tfor (const player of sfxPlayers) refreshPlayerVolume(player);
\t\t\t\t\t\treturn true;
\t\t\t\t\tcase 'play_bgm': {
\t\t\t\t\t\tconst url = assetUrl(request.path);
\t\t\t\t\t\tif (bgmId !== request.id || bgm.src !== url) {
\t\t\t\t\t\t\tstopPlayer(bgm);
\t\t\t\t\t\t\tbgm.src = url;
\t\t\t\t\t\t\tbgmId = String(request.id || request.path || '');
\t\t\t\t\t\t}
\t\t\t\t\t\tbgm.loop = request.loop !== false;
\t\t\t\t\t\tbgmDb = Number(request.volume_db || 0);
\t\t\t\t\t\tsetPlayerVolume(bgm, 'bgm', bgmDb, bgmDuckDb);
\t\t\t\t\t\tsafePlay(bgm);
\t\t\t\t\t\treturn true;
\t\t\t\t\t}
\t\t\t\t\tcase 'stop_bgm':
\t\t\t\t\t\tstopPlayer(bgm);
\t\t\t\t\t\tbgmId = '';
\t\t\t\t\t\treturn true;
\t\t\t\t\tcase 'duck_bgm':
\t\t\t\t\t\tbgmDuckDb = Number(request.duck_db || 0);
\t\t\t\t\t\tsetPlayerVolume(bgm, 'bgm', bgmDb, bgmDuckDb);
\t\t\t\t\t\treturn true;
\t\t\t\t\tcase 'play_sfx': {
\t\t\t\t\t\tconst player = new Audio(assetUrl(request.path));
\t\t\t\t\t\tplayer.preload = 'auto';
\t\t\t\t\t\tsetPlayerVolume(player, 'sfx', request.volume_db);
\t\t\t\t\t\tsfxPlayers.add(player);
\t\t\t\t\t\tplayer.addEventListener('ended', () => sfxPlayers.delete(player), { once: true });
\t\t\t\t\t\tsafePlay(player);
\t\t\t\t\t\treturn true;
\t\t\t\t\t}
\t\t\t\t\tcase 'play_voice':
\t\t\t\t\t\tstopPlayer(voice);
\t\t\t\t\t\tvoice.src = assetUrl(request.path);
\t\t\t\t\t\tvoice.loop = false;
\t\t\t\t\t\tsetPlayerVolume(voice, 'voice', request.volume_db);
\t\t\t\t\t\tsafePlay(voice);
\t\t\t\t\t\treturn true;
\t\t\t\t\tcase 'stop_voice':
\t\t\t\t\t\tstopPlayer(voice);
\t\t\t\t\t\treturn true;
\t\t\t\t\tcase 'play_ambience': {
\t\t\t\t\t\tlet player = ambiences.get(request.id);
\t\t\t\t\t\tif (!player) {
\t\t\t\t\t\t\tplayer = new Audio();
\t\t\t\t\t\t\tplayer.preload = 'auto';
\t\t\t\t\t\t\tambiences.set(request.id, player);
\t\t\t\t\t\t}
\t\t\t\t\t\tconst url = assetUrl(request.path);
\t\t\t\t\t\tif (player.src !== url) player.src = url;
\t\t\t\t\t\tplayer.loop = request.loop !== false;
\t\t\t\t\t\tsetPlayerVolume(player, 'ambience', request.volume_db);
\t\t\t\t\t\tsafePlay(player);
\t\t\t\t\t\treturn true;
\t\t\t\t\t}
\t\t\t\t\tcase 'stop_ambience': {
\t\t\t\t\t\tconst player = ambiences.get(request.id);
\t\t\t\t\t\tif (player) stopPlayer(player);
\t\t\t\t\t\tambiences.delete(request.id);
\t\t\t\t\t\treturn true;
\t\t\t\t\t}
\t\t\t\t\tcase 'stop_all':
\t\t\t\t\t\tstopPlayer(bgm);
\t\t\t\t\t\tstopPlayer(voice);
\t\t\t\t\t\tfor (const player of ambiences.values()) stopPlayer(player);
\t\t\t\t\t\tfor (const player of sfxPlayers) stopPlayer(player);
\t\t\t\t\t\tambiences.clear();
\t\t\t\t\t\tsfxPlayers.clear();
\t\t\t\t\t\tbgmId = '';
\t\t\t\t\t\treturn true;
\t\t\t\t}
\t\t\t\treturn false;
\t\t\t}

\t\t\tfunction getDebugState() {
\t\t\t\treturn {
\t\t\t\t\tunlocked,
\t\t\t\t\tbgmId,
\t\t\t\t\tbgmPaused: bgm.paused,
\t\t\t\t\tbgmCurrentTime: bgm.currentTime,
\t\t\t\t\tbgmReadyState: bgm.readyState,
\t\t\t\t\tbgmSrc: bgm.currentSrc || bgm.src,
\t\t\t\t\tbgmVolume: bgm.volume,
\t\t\t\t\tbgmError: bgm.error ? { code: bgm.error.code, message: bgm.error.message } : null,
\t\t\t\t};
\t\t\t}

\t\t\treturn { handle, unlock, isUnlocked: () => unlocked, getDebugState };
\t\t}

\t\tconst nativeAudio = createNativeAudioBridge();
\t\twindow.__shuoguangNativeAudio = nativeAudio;

\t\tfunction getTvVideo() {
\t\t\tlet video = document.getElementById('shuoguang-tv-video');
\t\t\tif (video) return video;
\t\t\tvideo = document.createElement('video');
\t\t\tvideo.id = 'shuoguang-tv-video';
\t\t\tvideo.src = 'fragment-0001-tv.mp4';
\t\t\tvideo.preload = 'metadata';
\t\t\tvideo.playsInline = true;
\t\t\tvideo.controls = false;
\t\t\tdocument.body.appendChild(video);
\t\t\treturn video;
\t\t}

\t\twindow.__shuoguangPlayTvVideo = function (x, y, width, height, viewportWidth, viewportHeight) {
\t\t\tconst canvas = document.getElementById('canvas');
\t\t\tif (!canvas || viewportWidth <= 0 || viewportHeight <= 0) return;
\t\t\tconst canvasRect = canvas.getBoundingClientRect();
\t\t\tconst video = getTvVideo();
\t\t\tvideo.style.left = (canvasRect.left + x * canvasRect.width / viewportWidth) + 'px';
\t\t\tvideo.style.top = (canvasRect.top + y * canvasRect.height / viewportHeight) + 'px';
\t\t\tvideo.style.width = (width * canvasRect.width / viewportWidth) + 'px';
\t\t\tvideo.style.height = (height * canvasRect.height / viewportHeight) + 'px';
\t\t\tvideo.style.display = 'block';
\t\t\tvideo.style.pointerEvents = 'none';
\t\t\tvideo.controls = false;
\t\t\tvideo.muted = false;
\t\t\tvideo.volume = 1;
\t\t\tvideo.currentTime = 0;
\t\t\tvideo.play().catch((error) => {
\t\t\t\tconsole.warn('[TVVideo] autoplay with sound was rejected:', error);
\t\t\t\tvideo.controls = true;
\t\t\t\tvideo.style.pointerEvents = 'auto';
\t\t\t});
\t\t};

\t\twindow.__shuoguangStopTvVideo = function () {
\t\t\tconst video = document.getElementById('shuoguang-tv-video');
\t\t\tif (!video) return;
\t\t\tvideo.pause();
\t\t\tvideo.style.display = 'none';
\t\t\tvideo.controls = false;
\t\t\tvideo.style.pointerEvents = 'none';
\t\t};
\t\twindow.addEventListener('pagehide', window.__shuoguangStopTvVideo);

\t\tfunction captureGodotAudioContext() {
\t\t\tconst NativeAudioContext = window.AudioContext || window.webkitAudioContext;
\t\t\tif (!NativeAudioContext || NativeAudioContext.__shuoguangCaptureInstalled) {
\t\t\t\treturn;
\t\t\t}
\t\t\tfunction CapturedAudioContext(...args) {
\t\t\t\tconst context = new NativeAudioContext(...args);
\t\t\t\twindow.__godotAudioContext = context;
\t\t\t\tcontext.addEventListener('statechange', () => {
\t\t\t\t\tif (context.state === 'running') {
\t\t\t\t\t\twindow.__shuoguangUserActivatedAudio = true;
\t\t\t\t\t\treturn;
\t\t\t\t\t}
\t\t\t\t\tif (window.__shuoguangUserActivatedAudio) {
\t\t\t\t\t\twindow.__shuoguangUserActivatedAudio = false;
\t\t\t\t\t\tif (gameReady) showAudioResumeGate('浏览器暂停了音频，请再次点击');
\t\t\t\t\t}
\t\t\t\t});
\t\t\t\tconsole.info('[AudioGate] captured Godot AudioContext:', context.state);
\t\t\t\treturn context;
\t\t\t}
\t\t\tCapturedAudioContext.prototype = NativeAudioContext.prototype;
\t\t\tObject.setPrototypeOf(CapturedAudioContext, NativeAudioContext);
\t\t\tCapturedAudioContext.__shuoguangCaptureInstalled = true;
\t\t\twindow.AudioContext = CapturedAudioContext;
\t\t\tif (window.webkitAudioContext === NativeAudioContext) {
\t\t\t\twindow.webkitAudioContext = CapturedAudioContext;
\t\t\t}
\t\t}

\t\tfunction primeAudioContext(context) {
\t\t\tconst source = context.createBufferSource();
\t\t\tsource.buffer = context.createBuffer(1, 1, context.sampleRate);
\t\t\tsource.connect(context.destination);
\t\t\tsource.start(0);
\t\t\tsource.disconnect();
\t\t}

\t\tfunction showAudioResumeGate(hint) {
\t\t\taudioStartGate?.classList.remove('hidden');
\t\t\taudioStartGate?.setAttribute('aria-disabled', 'false');
\t\t\tif (audioStartTitle) audioStartTitle.textContent = '点击启用声音';
\t\t\tif (audioStartHint) audioStartHint.textContent = hint;
\t\t\taudioStartGate?.focus();
\t\t}

\t\tfunction markAudioRunning(context) {
\t\t\twindow.__shuoguangUserActivatedAudio = true;
\t\t\taudioStartGate?.classList.add('hidden');
\t\t\tconsole.info('[AudioGate] Godot AudioContext running:', context.state);
\t\t\tdocument.getElementById('canvas')?.focus();
\t\t}

\t\tfunction unlockGodotAudio() {
\t\t\tnativeAudio.unlock();
\t\t\tif (audioResumePending) return;
\t\t\tconst context = window.__godotAudioContext;
\t\t\tif (!context || typeof context.resume !== 'function') {
\t\t\t\tif (gameReady) showAudioResumeGate('音频尚未就绪，请再次点击');
\t\t\t\treturn;
\t\t\t}
\t\t\tif (context.state === 'running') {
\t\t\t\tmarkAudioRunning(context);
\t\t\t\treturn;
\t\t\t}
\t\t\taudioResumePending = true;
\t\t\tprimeAudioContext(context);
\t\t\tcontext.resume().then(() => {
\t\t\t\tif (context.state !== 'running') {
\t\t\t\t\tthrow new Error('Godot AudioContext did not enter the running state.');
\t\t\t\t}
\t\t\t\tmarkAudioRunning(context);
\t\t\t}).catch((err) => {
\t\t\t\tconsole.warn('Unable to resume Godot WebAudio:', err);
\t\t\t\tif (gameReady) showAudioResumeGate('声音启用失败，请再次点击');
\t\t\t}).finally(() => {
\t\t\t\taudioResumePending = false;
\t\t\t});
\t\t}

\t\tfunction updateLoadProgress(current, total) {
\t\t\tif (current > 0 && total > 0) {
\t\t\t\tstatusProgress.value = current;
\t\t\t\tstatusProgress.max = total;
\t\t\t} else {
\t\t\t\tstatusProgress.removeAttribute('value');
\t\t\t\tstatusProgress.removeAttribute('max');
\t\t\t}
\t\t}

\t\tfunction beginGameAfterAudioGesture() {
\t\t\tnativeAudio.unlock();
\t\t\tif (gameStarted) {
\t\t\t\tunlockGodotAudio();
\t\t\t\treturn;
\t\t\t}
\t\t\tgameStarted = true;
\t\t\taudioStartGate?.classList.add('hidden');
\t\t\taudioStartGate?.setAttribute('aria-disabled', 'true');
\t\t\tsetStatusMode('progress');
\t\t\tengine.startGame({ 'onProgress': updateLoadProgress }).then(() => {
\t\t\t\tsetStatusMode('hidden');
\t\t\t\tgameReady = true;
\t\t\t\tconst context = window.__godotAudioContext;
\t\t\t\tif (context?.state === 'running') {
\t\t\t\t\tmarkAudioRunning(context);
\t\t\t\t} else {
\t\t\t\t\t// A sticky browser activation is often enough here. If it is not,
\t\t\t\t\t// the gate is restored and the next click resumes the existing context.
\t\t\t\t\tunlockGodotAudio();
\t\t\t\t\tif (context?.state !== 'running') {
\t\t\t\t\t\tshowAudioResumeGate('浏览器需要再次点击来启用游戏声音');
\t\t\t\t\t}
\t\t\t\t}
\t\t\t}, displayFailureNotice);
\t\t}

		window.__shuoguangResumeGodotAudio = unlockGodotAudio;

\t\tcaptureGodotAudioContext();
\t\tif (audioStartGate) {
\t\t\taudioStartGate.addEventListener('pointerdown', beginGameAfterAudioGesture);
\t\t\taudioStartGate.addEventListener('keydown', (event) => {
\t\t\t\tif (event.key === 'Enter' || event.key === ' ') {
\t\t\t\t\tevent.preventDefault();
\t\t\t\t\tbeginGameAfterAudioGesture();
\t\t\t\t}
\t\t\t});
\t\t\taudioStartGate.focus();
\t\t}
\t}`;

const WAITING_GATE_REMOVES_STATUS = `\t\t} else {
\t\t\tsetStatusMode('hidden');
\t\t\taudioStartGate.addEventListener('pointerdown', beginGameAfterAudioGesture, { once: true });`;

const WAITING_GATE_KEEPS_STATUS = `\t\t} else {
\t\t\taudioStartGate.addEventListener('pointerdown', beginGameAfterAudioGesture, { once: true });`;

function applyWebAudioGate(htmlPath) {
	let html = fs.readFileSync(htmlPath, 'utf8').replace(/\r\n/g, '\n');
	let changed = false;

	if (!html.includes('id="shuoguang-audio-gate-style"')) {
		html = html.replace('</style>', `</style>${GATE_STYLE}`);
		changed = true;
	}

	if (!html.includes('id="audio-start-gate"')) {
		html = html.replace('\n\n\t\t<noscript>', `${GATE_MARKUP}\n\n\t\t<noscript>`);
		changed = true;
	}

	if (html.includes(AUTO_START_SNIPPET)) {
		html = html.replace(AUTO_START_SNIPPET, GATED_START_SNIPPET);
		changed = true;
	} else if (!html.includes('captureGodotAudioContext')) {
		throw new Error(`Could not locate Godot auto-start block in ${htmlPath}`);
	}

	if (html.includes(WAITING_GATE_REMOVES_STATUS)) {
		html = html.replace(WAITING_GATE_REMOVES_STATUS, WAITING_GATE_KEEPS_STATUS);
		changed = true;
	}

	if (changed) {
		fs.writeFileSync(htmlPath, html, 'utf8');
	}
	return changed;
}

module.exports = { applyWebAudioGate };
