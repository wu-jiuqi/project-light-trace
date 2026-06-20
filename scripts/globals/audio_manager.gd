extends Node

const BUS_MASTER := "Master"
const BUS_BGM := "BGM"
const BUS_AMBIENCE := "Ambience"
const BUS_SFX := "SFX"
const BUS_VOICE := "Voice"

const PRIORITY_LOW := 0
const PRIORITY_NORMAL := 1
const PRIORITY_HIGH := 2
const PRIORITY_CRITICAL := 3

const SILENT_DB := -80.0
const SFX_POOL_SIZE := 12

var _bgm_players: Array[AudioStreamPlayer] = []
var _bgm_active_index: int = 0
var _bgm_tween: Tween = null
var _current_bgm_id: String = ""
var _current_bgm_volume_db: float = 0.0
var _bgm_duck_db: float = 0.0

var _ambience_players: Dictionary = {}
var _ambience_tweens: Dictionary = {}

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_priorities: Array[int] = []
var _sfx_started_at: Array[int] = []

var _voice_player: AudioStreamPlayer = null
var _voice_tween: Tween = null
var _voice_priority: int = PRIORITY_LOW
var _voice_duck_tween: Tween = null
var _web_audio_unlocked: bool = true
var _pending_bgm: Dictionary = {}
var _pending_ambiences: Dictionary = {}
var _pending_voice: Dictionary = {}

var _channel_volumes: Dictionary = {
	"master": 1.0,
	"bgm": 0.55,
	"ambience": 1.0,
	"sfx": 1.0,
	"voice": 1.0,
}


func _ready() -> void:
	_web_audio_unlocked = _read_web_audio_unlocked_state()
	set_process(OS.has_feature("web") and not _web_audio_unlocked)
	print("[AudioManager] ready web=%s unlocked=%s" % [OS.has_feature("web"), _web_audio_unlocked])
	_ensure_audio_buses()
	_create_bgm_players()
	_create_sfx_pool()
	_create_voice_player()


func _process(_delta: float) -> void:
	if not _web_audio_unlocked and _read_web_audio_unlocked_state():
		_unlock_web_audio()


func _input(event: InputEvent) -> void:
	if _web_audio_unlocked:
		return
	if OS.has_feature("web") and _is_audio_unlock_event(event):
		# The browser, not Godot input alone, is the source of truth. Marking the
		# channel unlocked before AudioContext.resume() succeeds drops queued audio.
		JavaScriptBridge.eval(
			"window.__shuoguangResumeGodotAudio && window.__shuoguangResumeGodotAudio();",
			true
		)


func _exit_tree() -> void:
	stop_all()


func stop_all() -> void:
	_pending_bgm.clear()
	_pending_ambiences.clear()
	_pending_voice.clear()
	if _has_web_native_audio():
		_web_audio_call({"method": "stop_all"})
	stop_bgm(0.0)
	_kill_tween(_voice_tween)
	_voice_tween = null
	_kill_tween(_voice_duck_tween)
	_voice_duck_tween = null
	if _voice_player != null:
		_voice_player.stop()
		_voice_player.stream = null
	_voice_priority = PRIORITY_LOW
	_bgm_duck_db = 0.0

	for player in _sfx_players:
		player.stop()
		player.stream = null
	for i in _sfx_priorities.size():
		_sfx_priorities[i] = PRIORITY_LOW
	for i in _sfx_started_at.size():
		_sfx_started_at[i] = 0

	for id in _ambience_tweens.keys():
		_kill_tween(_ambience_tweens[id])
	_ambience_tweens.clear()
	for player in _ambience_players.values():
		if is_instance_valid(player):
			player.stop()
			player.stream = null
			player.queue_free()
	_ambience_players.clear()


func play_bgm(stream: AudioStream, id: String = "", fade: float = 0.5, volume_db: float = 0.0, loop: bool = true) -> void:
	if stream == null:
		return
	if _should_defer_audio_start():
		print("[AudioManager] queued BGM until WebAudio unlock: %s" % id)
		_pending_bgm = {
			"stream": stream,
			"id": id,
			"fade": fade,
			"volume_db": volume_db,
			"loop": loop,
		}
		return
	var next_id := id if not id.is_empty() else stream.resource_path
	if _has_web_native_audio() and not stream.resource_path.is_empty():
		_current_bgm_id = next_id
		_current_bgm_volume_db = volume_db
		_web_audio_call({
			"method": "play_bgm",
			"path": stream.resource_path,
			"id": next_id,
			"volume_db": volume_db,
			"loop": loop,
		})
		print("[AudioManager] native Web BGM started: %s" % next_id)
		return
	var current := _bgm_players[_bgm_active_index]
	if _current_bgm_id == next_id and current.playing:
		_current_bgm_volume_db = volume_db
		current.volume_db = volume_db + _bgm_duck_db
		return

	_kill_tween(_bgm_tween)
	_bgm_tween = null
	var previous := current
	var next_index := 1 - _bgm_active_index
	var next := _bgm_players[next_index]
	_set_stream_loop(stream, loop)
	next.stream = stream
	next.bus = BUS_BGM
	next.volume_db = SILENT_DB
	next.play()
	print("[AudioManager] BGM started: %s" % next_id)
	_bgm_active_index = next_index
	_current_bgm_id = next_id
	_current_bgm_volume_db = volume_db
	var target_db := volume_db + _bgm_duck_db

	if fade <= 0.0:
		if previous.playing:
			previous.stop()
		previous.stream = null
		next.volume_db = target_db
		return

	_bgm_tween = create_tween()
	_bgm_tween.set_parallel(true)
	_bgm_tween.tween_property(next, "volume_db", target_db, fade)
	if previous.playing:
		_bgm_tween.tween_property(previous, "volume_db", SILENT_DB, fade)
		_bgm_tween.chain().tween_callback(func() -> void:
			if previous.playing:
				previous.stop()
			previous.stream = null
		)


func stop_bgm(fade: float = 0.35) -> void:
	_pending_bgm.clear()
	_kill_tween(_bgm_tween)
	_bgm_tween = null
	if _has_web_native_audio():
		_web_audio_call({"method": "stop_bgm", "fade": fade})
		_current_bgm_id = ""
		return
	var current := _bgm_players[_bgm_active_index]
	_current_bgm_id = ""
	for player in _bgm_players:
		if player != current:
			player.stop()
			player.stream = null
	if not current.playing:
		current.stream = null
		return
	if fade <= 0.0:
		current.stop()
		current.stream = null
		current.volume_db = SILENT_DB
		return
	_bgm_tween = create_tween()
	_bgm_tween.tween_property(current, "volume_db", SILENT_DB, fade)
	_bgm_tween.tween_callback(func() -> void:
		if current.playing:
			current.stop()
		current.stream = null
	)


func play_ambience(id: String, stream: AudioStream, fade: float = 0.5, priority: int = PRIORITY_NORMAL, volume_db: float = 0.0, loop: bool = true) -> void:
	if id.is_empty() or stream == null:
		return
	if _should_defer_audio_start():
		_pending_ambiences[id] = {
			"id": id,
			"stream": stream,
			"fade": fade,
			"priority": priority,
			"volume_db": volume_db,
			"loop": loop,
		}
		return
	if _has_web_native_audio() and not stream.resource_path.is_empty():
		_web_audio_call({
			"method": "play_ambience",
			"id": id,
			"path": stream.resource_path,
			"volume_db": volume_db,
			"loop": loop,
		})
		return
	var player := _ambience_players.get(id) as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "Ambience_%s" % id
		player.bus = BUS_AMBIENCE
		player.set_meta("priority", priority)
		add_child(player)
		_ambience_players[id] = player
	_set_stream_loop(stream, loop)
	player.stream = stream
	player.set_meta("priority", priority)
	_kill_tween(_ambience_tweens.get(id))
	_ambience_tweens.erase(id)
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	if fade <= 0.0:
		player.volume_db = volume_db
	else:
		var tween := create_tween()
		tween.tween_property(player, "volume_db", volume_db, fade)
		_ambience_tweens[id] = tween


func stop_ambience(id: String, fade: float = 0.35) -> void:
	_pending_ambiences.erase(id)
	if _has_web_native_audio():
		_web_audio_call({"method": "stop_ambience", "id": id, "fade": fade})
		return
	var player := _ambience_players.get(id) as AudioStreamPlayer
	if player == null:
		return
	_kill_tween(_ambience_tweens.get(id))
	_ambience_tweens.erase(id)
	if fade <= 0.0:
		player.stop()
		player.queue_free()
		_ambience_players.erase(id)
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", SILENT_DB, fade)
	tween.tween_callback(func() -> void:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
		_ambience_players.erase(id)
	)
	_ambience_tweens[id] = tween


func play_sfx(stream: AudioStream, priority: int = PRIORITY_NORMAL, volume_db: float = 0.0) -> void:
	if stream == null or _sfx_players.is_empty():
		return
	if _should_defer_audio_start():
		return
	if _has_web_native_audio() and not stream.resource_path.is_empty():
		_web_audio_call({
			"method": "play_sfx",
			"path": stream.resource_path,
			"volume_db": volume_db,
		})
		return
	var index := _choose_sfx_player(priority)
	if index < 0:
		return
	var player := _sfx_players[index]
	player.stop()
	player.stream = stream
	player.bus = BUS_SFX
	player.volume_db = volume_db
	_sfx_priorities[index] = priority
	_sfx_started_at[index] = Time.get_ticks_msec()
	player.play()


func play_voice(id: String, stream: AudioStream, priority: int = PRIORITY_NORMAL, duck_bgm_db: float = -6.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	if _should_defer_audio_start():
		_pending_voice = {
			"id": id,
			"stream": stream,
			"priority": priority,
			"duck_bgm_db": duck_bgm_db,
			"volume_db": volume_db,
		}
		return
	if _voice_player.playing and priority < _voice_priority:
		return
	if _has_web_native_audio() and not stream.resource_path.is_empty():
		_voice_priority = priority
		_apply_bgm_duck(duck_bgm_db)
		_web_audio_call({
			"method": "play_voice",
			"id": id,
			"path": stream.resource_path,
			"volume_db": volume_db,
		})
		return
	_kill_tween(_voice_tween)
	_voice_tween = null
	_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.bus = BUS_VOICE
	_voice_player.volume_db = volume_db
	_voice_priority = priority
	_voice_player.set_meta("voice_id", id)
	_apply_bgm_duck(duck_bgm_db)
	_voice_player.play()


func stop_voice(fade: float = 0.15) -> void:
	_pending_voice.clear()
	if _has_web_native_audio():
		_web_audio_call({"method": "stop_voice", "fade": fade})
		_voice_priority = PRIORITY_LOW
		_apply_bgm_duck(0.0)
		return
	if not _voice_player.playing:
		_voice_player.stream = null
		_apply_bgm_duck(0.0)
		return
	_kill_tween(_voice_tween)
	_voice_tween = null
	if fade <= 0.0:
		_voice_player.stop()
		_voice_player.stream = null
		_apply_bgm_duck(0.0)
		return
	_voice_tween = create_tween()
	_voice_tween.tween_property(_voice_player, "volume_db", SILENT_DB, fade)
	_voice_tween.tween_callback(func() -> void:
		_voice_player.stop()
		_voice_player.stream = null
		_voice_player.volume_db = 0.0
		_apply_bgm_duck(0.0)
	)


func set_channel_volume(channel: String, linear: float) -> void:
	var key := channel.to_lower()
	var bus_name := _bus_for_channel(key)
	if bus_name.is_empty():
		return
	_channel_volumes[key] = clampf(linear, 0.0, 1.0)
	_set_bus_volume(bus_name, _channel_volumes[key])


func apply_volumes(master: float, bgm: float, sfx: float, ambience: float = 1.0, voice: float = 1.0) -> void:
	print("[AudioManager] volumes master=%.2f bgm=%.2f sfx=%.2f ambience=%.2f voice=%.2f" % [master, bgm, sfx, ambience, voice])
	set_channel_volume("master", master)
	set_channel_volume("bgm", bgm)
	set_channel_volume("sfx", sfx)
	set_channel_volume("ambience", ambience)
	set_channel_volume("voice", voice)
	if _has_web_native_audio():
		_web_audio_call({
			"method": "set_volumes",
			"master": master,
			"bgm": bgm,
			"sfx": sfx,
			"ambience": ambience,
			"voice": voice,
		})


func get_current_bgm_id() -> String:
	return _current_bgm_id


func _ensure_audio_buses() -> void:
	_ensure_bus(BUS_MASTER, "")
	_ensure_bus(BUS_BGM, BUS_MASTER)
	_ensure_bus(BUS_AMBIENCE, BUS_MASTER)
	_ensure_bus(BUS_SFX, BUS_MASTER)
	_ensure_bus(BUS_VOICE, BUS_MASTER)


func _ensure_bus(bus_name: String, send_to: String) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		index = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
	if not send_to.is_empty():
		AudioServer.set_bus_send(index, send_to)


func _create_bgm_players() -> void:
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "BGMPlayer%d" % i
		player.bus = BUS_BGM
		player.volume_db = SILENT_DB
		add_child(player)
		_bgm_players.append(player)


func _create_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = BUS_SFX
		player.finished.connect(func() -> void:
			var idx := _sfx_players.find(player)
			if idx >= 0:
				_sfx_priorities[idx] = PRIORITY_LOW
		)
		add_child(player)
		_sfx_players.append(player)
		_sfx_priorities.append(PRIORITY_LOW)
		_sfx_started_at.append(0)


func _create_voice_player() -> void:
	_voice_player = AudioStreamPlayer.new()
	_voice_player.name = "VoicePlayer"
	_voice_player.bus = BUS_VOICE
	_voice_player.finished.connect(func() -> void:
		_voice_priority = PRIORITY_LOW
		_apply_bgm_duck(0.0)
	)
	add_child(_voice_player)


func _choose_sfx_player(priority: int) -> int:
	for i in _sfx_players.size():
		if not _sfx_players[i].playing:
			return i
	var best_index := -1
	var best_priority := priority
	var oldest := Time.get_ticks_msec()
	for i in _sfx_players.size():
		var p := _sfx_priorities[i]
		if p <= best_priority and _sfx_started_at[i] <= oldest:
			best_index = i
			best_priority = p
			oldest = _sfx_started_at[i]
	return best_index


func _apply_bgm_duck(duck_db: float) -> void:
	_bgm_duck_db = duck_db
	if _has_web_native_audio():
		_web_audio_call({"method": "duck_bgm", "duck_db": duck_db})
		return
	var current := _bgm_players[_bgm_active_index]
	if not current.playing:
		return
	_kill_tween(_voice_duck_tween)
	_voice_duck_tween = null
	_voice_duck_tween = create_tween()
	_voice_duck_tween.tween_property(current, "volume_db", _current_bgm_volume_db + _bgm_duck_db, 0.18)


func _set_stream_loop(stream: AudioStream, loop: bool) -> void:
	for prop in stream.get_property_list():
		if str(prop.get("name", "")) == "loop":
			stream.set("loop", loop)
			return


func _bus_for_channel(channel: String) -> String:
	match channel:
		"master":
			return BUS_MASTER
		"bgm":
			return BUS_BGM
		"ambience", "ambient":
			return BUS_AMBIENCE
		"sfx":
			return BUS_SFX
		"voice":
			return BUS_VOICE
	return ""


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var db := linear_to_db(maxf(linear, 0.0001))
	AudioServer.set_bus_volume_db(bus_index, maxf(db, SILENT_DB))


func _read_web_audio_unlocked_state() -> bool:
	if not OS.has_feature("web"):
		return true
	return bool(JavaScriptBridge.eval(
		"window.__shuoguangNativeAudio ? Boolean(window.__shuoguangNativeAudio.isUnlocked()) : Boolean(window.__shuoguangUserActivatedAudio && window.__godotAudioContext && window.__godotAudioContext.state === 'running')",
		true
	))


func _has_web_native_audio() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("Boolean(window.__shuoguangNativeAudio)", true))


func _web_audio_call(request: Dictionary) -> void:
	if not _has_web_native_audio():
		return
	var payload := JSON.stringify(request)
	JavaScriptBridge.eval(
		"window.__shuoguangNativeAudio && window.__shuoguangNativeAudio.handle(%s);" % payload,
		true
	)


func _should_defer_audio_start() -> bool:
	return OS.has_feature("web") and not _web_audio_unlocked


func _is_audio_unlock_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	return false


func _unlock_web_audio() -> void:
	_web_audio_unlocked = true
	set_process(false)
	print("[AudioManager] WebAudio unlocked; flushing pending playback")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__shuoguangUserActivatedAudio = true;", true)
	call_deferred("_flush_pending_audio")


func _flush_pending_audio() -> void:
	if not _pending_bgm.is_empty():
		var pending_bgm := _pending_bgm.duplicate()
		_pending_bgm.clear()
		play_bgm(
			pending_bgm["stream"],
			str(pending_bgm["id"]),
			float(pending_bgm["fade"]),
			float(pending_bgm["volume_db"]),
			bool(pending_bgm["loop"])
		)

	var ambiences := _pending_ambiences.values()
	_pending_ambiences.clear()
	for pending in ambiences:
		play_ambience(
			str(pending["id"]),
			pending["stream"],
			float(pending["fade"]),
			int(pending["priority"]),
			float(pending["volume_db"]),
			bool(pending["loop"])
		)

	if not _pending_voice.is_empty():
		var pending_voice := _pending_voice.duplicate()
		_pending_voice.clear()
		play_voice(
			str(pending_voice["id"]),
			pending_voice["stream"],
			int(pending_voice["priority"]),
			float(pending_voice["duck_bgm_db"]),
			float(pending_voice["volume_db"])
		)


func _kill_tween(tween) -> void:
	if tween != null and tween is Tween and tween.is_valid():
		tween.kill()
