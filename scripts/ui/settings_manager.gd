class_name SettingsManager
extends RefCounted

const CONFIG_PATH := "user://settings.cfg"

const LLM_MODE_BUILTIN := "builtin"
const LLM_MODE_CUSTOM := "custom"
const LEGACY_DEFAULT_LLM_BASE_URL := "https://api.openai.com/v1"
const LEGACY_DEFAULT_LLM_MODEL := "gpt-4.1-mini"
const LOCAL_HTTP_PREFIXES := [
	"http://127.0.0.1",
	"http://localhost",
	"http://[::1]",
]

static var master_volume: float = 1.0
static var bgm_volume: float = 1.0
static var ambience_volume: float = 1.0
static var sfx_volume: float = 1.0
static var voice_volume: float = 1.0
static var fullscreen: bool = false

static var llm_mode: String = LLM_MODE_BUILTIN
static var llm_base_url: String = ""
static var llm_model: String = ""
static var llm_api_key: String = ""


static func load() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return false
	master_volume = clampf(float(cfg.get_value("audio", "master_volume", 1.0)), 0.0, 1.0)
	bgm_volume = clampf(float(cfg.get_value("audio", "bgm_volume", 1.0)), 0.0, 1.0)
	ambience_volume = clampf(float(cfg.get_value("audio", "ambience_volume", 1.0)), 0.0, 1.0)
	sfx_volume = clampf(float(cfg.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0)
	voice_volume = clampf(float(cfg.get_value("audio", "voice_volume", 1.0)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("display", "fullscreen", false))
	llm_mode = str(cfg.get_value("llm", "mode", LLM_MODE_BUILTIN))
	if llm_mode not in [LLM_MODE_BUILTIN, LLM_MODE_CUSTOM]:
		llm_mode = LLM_MODE_BUILTIN
	llm_base_url = str(cfg.get_value("llm", "base_url", "")).strip_edges()
	llm_model = str(cfg.get_value("llm", "model", "")).strip_edges()
	llm_api_key = str(cfg.get_value("llm", "api_key", "")).strip_edges()
	if llm_api_key.strip_edges().is_empty():
		if llm_base_url == LEGACY_DEFAULT_LLM_BASE_URL:
			llm_base_url = ""
		if llm_model == LEGACY_DEFAULT_LLM_MODEL:
			llm_model = ""
	return true


static func load_and_apply() -> void:
	if SettingsManager.load():
		SettingsManager.apply()


static func save() -> void:
	_normalize_llm_fields()
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "bgm_volume", bgm_volume)
	cfg.set_value("audio", "ambience_volume", ambience_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("llm", "mode", llm_mode)
	cfg.set_value("llm", "base_url", llm_base_url)
	cfg.set_value("llm", "model", llm_model)
	cfg.set_value("llm", "api_key", llm_api_key)
	cfg.save(CONFIG_PATH)


static func apply() -> void:
	var audio_manager := _get_audio_manager()
	if audio_manager != null and audio_manager.has_method("apply_volumes"):
		audio_manager.call("apply_volumes", master_volume, bgm_volume, sfx_volume, ambience_volume, voice_volume)
	else:
		_set_bus_volume("Master", master_volume)
		_set_bus_volume("BGM", bgm_volume)
		_set_bus_volume("Ambience", ambience_volume)
		_set_bus_volume("SFX", sfx_volume)
		_set_bus_volume("Voice", voice_volume)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


static func validate_llm_values(mode: String, base_url: String, model: String, api_key: String) -> String:
	if mode != LLM_MODE_CUSTOM:
		return ""
	if base_url.strip_edges().is_empty():
		return "请输入 API Base URL。"
	if not has_llm_base_url_host(base_url):
		return "请输入完整的 API Base URL，例如 https://api.deepseek.com 或 https://api.openai.com/v1。"
	if model.strip_edges().is_empty():
		return "请输入模型名称。"
	if api_key.strip_edges().is_empty():
		return "请输入 API Key。"
	if not is_llm_base_url_allowed(base_url):
		return "为避免泄露 API Key，自定义 API 仅允许 HTTPS；本机 localhost/127.0.0.1 调试可使用 HTTP。"
	return ""


static func validate_llm_settings() -> String:
	return validate_llm_values(llm_mode, llm_base_url, llm_model, llm_api_key)


static func is_custom_llm_ready() -> bool:
	return llm_mode == LLM_MODE_CUSTOM and validate_llm_settings().is_empty()


static func is_llm_base_url_allowed(base_url: String) -> bool:
	var value := base_url.strip_edges().to_lower()
	if value.begins_with("https://"):
		return true
	for prefix in LOCAL_HTTP_PREFIXES:
		if value.begins_with(prefix):
			return true
	return false


static func has_llm_base_url_host(base_url: String) -> bool:
	var value := normalize_llm_base_url(base_url).to_lower()
	if value.begins_with("https://"):
		value = value.substr(8)
	elif value.begins_with("http://"):
		value = value.substr(7)
	else:
		return false
	var slash_index := value.find("/")
	var host_port := value if slash_index < 0 else value.substr(0, slash_index)
	return not host_port.strip_edges().is_empty()


static func normalize_llm_base_url(base_url: String) -> String:
	return base_url.strip_edges().trim_suffix("/")


static func _normalize_llm_fields() -> void:
	if llm_mode not in [LLM_MODE_BUILTIN, LLM_MODE_CUSTOM]:
		llm_mode = LLM_MODE_BUILTIN
	llm_base_url = normalize_llm_base_url(llm_base_url)
	llm_model = llm_model.strip_edges()
	llm_api_key = llm_api_key.strip_edges()


static func _set_bus_volume(bus_name: String, linear: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var db := linear_to_db(maxf(linear, 0.0001))
	AudioServer.set_bus_volume_db(bus_index, maxf(db, -80.0))


static func _get_audio_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AudioManager")
