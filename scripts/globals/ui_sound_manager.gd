extends Node
## 全局 UI 音效管理器
## 提供统一的按钮点击音效，通过 pressed 信号自动触发
##
## 使用方式：
##   1. 在每个 _connect_button_pressed 中自动连接 play_click
##   2. 内联 .pressed.connect() 后追加一行 .pressed.connect(UISoundManager.play_click)

const CLICK_SOUND_PATH := "res://assets/audio/ui/click.mp3"
var _click_sound: AudioStream = null

var _players: Array[AudioStreamPlayer] = []
var _player_index: int = 0
## 同时播放的最大实例数（防止快速连点时声音重叠过多）
const MAX_POLYPHONY := 4


func _ready() -> void:
	_ensure_click_sound()
	# 预创建多个 AudioStreamPlayer 支持复音
	for i in MAX_POLYPHONY:
		var player := AudioStreamPlayer.new()
		player.stream = _click_sound
		player.volume_db = -4.0  # 按钮按压音效，清晰可辨
		player.bus = &"Master"
		add_child(player)
		_players.append(player)


func _ensure_click_sound() -> void:
	if _click_sound != null:
		return
	if ResourceLoader.exists(CLICK_SOUND_PATH):
		_click_sound = load(CLICK_SOUND_PATH) as AudioStream
	else:
		push_warning("[UISoundManager] Click sound file not found: %s" % CLICK_SOUND_PATH)


func play_click() -> void:
	"""播放按钮点击音效（支持复音，防止快速连点时声音被截断）"""
	_ensure_click_sound()
	if _click_sound == null:
		return
	if AudioManager and AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx(_click_sound, AudioManager.PRIORITY_NORMAL, -4.0)
		return
	if _players.is_empty():
		return
	var player := _players[_player_index] as AudioStreamPlayer
	_player_index = (_player_index + 1) % _players.size()
	player.stop()
	player.play()
