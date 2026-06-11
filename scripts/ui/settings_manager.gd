class_name SettingsManager
extends RefCounted

const CONFIG_PATH := "user://settings.cfg"

static var master_volume: float = 1.0
static var bgm_volume: float = 1.0
static var sfx_volume: float = 1.0
static var fullscreen: bool = false


static func load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 1.0)
	bgm_volume = cfg.get_value("audio", "bgm_volume", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)
	fullscreen = cfg.get_value("display", "fullscreen", false)


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "bgm_volume", bgm_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.save(CONFIG_PATH)


static func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(bgm_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
