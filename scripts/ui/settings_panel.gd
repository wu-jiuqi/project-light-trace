class_name SettingsPanel
extends BasePanel

@onready var master_slider: HSlider = $"Stage/SettingsContainer/ContentArea/AudioSection/MasterRow/MasterSlider"
@onready var bgm_slider: HSlider = $"Stage/SettingsContainer/ContentArea/AudioSection/BgmRow/BgmSlider"
@onready var ambience_slider: HSlider = get_node_or_null("Stage/SettingsContainer/ContentArea/AudioSection/AmbienceRow/AmbienceSlider") as HSlider
@onready var sfx_slider: HSlider = $"Stage/SettingsContainer/ContentArea/AudioSection/SfxRow/SfxSlider"
@onready var voice_slider: HSlider = get_node_or_null("Stage/SettingsContainer/ContentArea/AudioSection/VoiceRow/VoiceSlider") as HSlider
@onready var master_value: Label = $"Stage/SettingsContainer/ContentArea/AudioSection/MasterRow/MasterValue"
@onready var bgm_value: Label = $"Stage/SettingsContainer/ContentArea/AudioSection/BgmRow/BgmValue"
@onready var ambience_value: Label = get_node_or_null("Stage/SettingsContainer/ContentArea/AudioSection/AmbienceRow/AmbienceValue") as Label
@onready var sfx_value: Label = $"Stage/SettingsContainer/ContentArea/AudioSection/SfxRow/SfxValue"
@onready var voice_value: Label = get_node_or_null("Stage/SettingsContainer/ContentArea/AudioSection/VoiceRow/VoiceValue") as Label
@onready var volume_disc: TextureRect = get_node_or_null("Stage/SettingsContainer/ContentArea/AudioSection/VolumeDisc") as TextureRect
@onready var fullscreen_check: CheckButton = $"Stage/SettingsContainer/ContentArea/DisplaySection/FullscreenRow/FullscreenCheck"
@onready var llm_mode_option: OptionButton = $"Stage/SettingsContainer/ContentArea/ApiSection/ModeRow/ModeOption"
@onready var base_url_edit: LineEdit = $"Stage/SettingsContainer/ContentArea/ApiSection/BaseUrlRow/BaseUrlEdit"
@onready var model_edit: LineEdit = $"Stage/SettingsContainer/ContentArea/ApiSection/ModelRow/ModelEdit"
@onready var api_key_edit: LineEdit = $"Stage/SettingsContainer/ContentArea/ApiSection/ApiKeyRow/ApiKeyEdit"
@onready var status_label: Label = $"Stage/SettingsContainer/ContentArea/ApiSection/StatusLabel"
@onready var save_button: BaseButton = $"Stage/SettingsContainer/ButtonRow/SaveButton"
@onready var cancel_button: BaseButton = $"Stage/SettingsContainer/ButtonRow/CancelButton"
@onready var close_button: BaseButton = $"Stage/SettingsContainer/TitleBar/CloseButton"

var _cached_values: Dictionary = {}


func _on_ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	llm_mode_option.clear()
	llm_mode_option.add_item("\u5b98\u65b9\u8bd5\u73a9", 0)
	llm_mode_option.add_item("\u81ea\u5b9a\u4e49 API", 1)
	_connect_button_pressed(save_button, save_settings, "Stage/SettingsContainer/ButtonRow/SaveButton")
	_connect_button_pressed(cancel_button, cancel, "Stage/SettingsContainer/ButtonRow/CancelButton")
	_connect_button_pressed(close_button, cancel, "Stage/SettingsContainer/TitleBar/CloseButton")
	master_slider.value_changed.connect(_on_slider_changed.bind("master"))
	bgm_slider.value_changed.connect(_on_slider_changed.bind("bgm"))
	if ambience_slider:
		ambience_slider.value_changed.connect(_on_slider_changed.bind("ambience"))
	sfx_slider.value_changed.connect(_on_slider_changed.bind("sfx"))
	if voice_slider:
		voice_slider.value_changed.connect(_on_slider_changed.bind("voice"))
	llm_mode_option.item_selected.connect(func(_index: int): _update_api_enabled())
	base_url_edit.text_changed.connect(func(_text: String): _update_api_enabled())
	model_edit.text_changed.connect(func(_text: String): _update_api_enabled())
	api_key_edit.text_changed.connect(func(_text: String): _update_api_enabled())


func _on_open() -> void:
	load_settings()
	_cache_snapshot()


func load_settings() -> void:
	SettingsManager.load()
	master_slider.value = SettingsManager.master_volume * 100.0
	bgm_slider.value = SettingsManager.bgm_volume * 100.0
	if ambience_slider:
		ambience_slider.value = SettingsManager.ambience_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	if voice_slider:
		voice_slider.value = SettingsManager.voice_volume * 100.0
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	llm_mode_option.select(1 if SettingsManager.llm_mode == SettingsManager.LLM_MODE_CUSTOM else 0)
	base_url_edit.text = SettingsManager.llm_base_url
	model_edit.text = SettingsManager.llm_model
	api_key_edit.text = SettingsManager.llm_api_key
	_update_value_labels()
	_update_api_enabled()


func save_settings() -> void:
	var next_llm_mode := SettingsManager.LLM_MODE_CUSTOM if llm_mode_option.get_selected_id() == 1 else SettingsManager.LLM_MODE_BUILTIN
	var next_base_url := SettingsManager.normalize_llm_base_url(base_url_edit.text)
	var next_model := model_edit.text.strip_edges()
	var next_api_key := api_key_edit.text.strip_edges()
	var validation_error := SettingsManager.validate_llm_values(next_llm_mode, next_base_url, next_model, next_api_key)
	if not validation_error.is_empty():
		_show_api_status(validation_error, true)
		return

	SettingsManager.master_volume = master_slider.value / 100.0
	SettingsManager.bgm_volume = bgm_slider.value / 100.0
	SettingsManager.ambience_volume = (ambience_slider.value / 100.0) if ambience_slider else SettingsManager.ambience_volume
	SettingsManager.sfx_volume = sfx_slider.value / 100.0
	SettingsManager.voice_volume = (voice_slider.value / 100.0) if voice_slider else SettingsManager.voice_volume
	SettingsManager.fullscreen = fullscreen_check.button_pressed
	SettingsManager.llm_mode = next_llm_mode
	SettingsManager.llm_base_url = next_base_url
	SettingsManager.llm_model = next_model
	SettingsManager.llm_api_key = next_api_key
	SettingsManager.save()
	SettingsManager.apply()
	if LLMClient and LLMClient.has_method("reload_settings"):
		LLMClient.reload_settings()
	close()


func cancel() -> void:
	master_slider.value = _cached_values.get("master", 100.0)
	bgm_slider.value = _cached_values.get("bgm", 100.0)
	if ambience_slider:
		ambience_slider.value = _cached_values.get("ambience", 100.0)
	sfx_slider.value = _cached_values.get("sfx", 100.0)
	if voice_slider:
		voice_slider.value = _cached_values.get("voice", 100.0)
	fullscreen_check.button_pressed = _cached_values.get("fullscreen", false)
	llm_mode_option.select(_cached_values.get("llm_index", 0))
	base_url_edit.text = _cached_values.get("base_url", "")
	model_edit.text = _cached_values.get("model", "")
	api_key_edit.text = _cached_values.get("api_key", "")
	_update_value_labels()
	close()


func _on_slider_changed(_value: float, bus: String) -> void:
	_update_value_labels()
	var slider: HSlider = master_slider
	match bus:
		"bgm":
			slider = bgm_slider
		"ambience":
			slider = ambience_slider
		"sfx":
			slider = sfx_slider
		"voice":
			slider = voice_slider
	if slider == null:
		return
	if AudioManager and AudioManager.has_method("set_channel_volume"):
		AudioManager.set_channel_volume(bus, slider.value / 100.0)


func _cache_snapshot() -> void:
	_cached_values = {
		"master": master_slider.value,
		"bgm": bgm_slider.value,
		"ambience": ambience_slider.value if ambience_slider else 100.0,
		"sfx": sfx_slider.value,
		"voice": voice_slider.value if voice_slider else 100.0,
		"fullscreen": fullscreen_check.button_pressed,
		"llm_index": llm_mode_option.selected,
		"base_url": base_url_edit.text,
		"model": model_edit.text,
		"api_key": api_key_edit.text,
	}


func _update_value_labels() -> void:
	master_value.text = "%d%%" % int(master_slider.value)
	bgm_value.text = "%d%%" % int(bgm_slider.value)
	if ambience_value and ambience_slider:
		ambience_value.text = "%d%%" % int(ambience_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)
	if voice_value and voice_slider:
		voice_value.text = "%d%%" % int(voice_slider.value)
	if volume_disc:
		volume_disc.rotation_degrees = -135.0 + (master_slider.value / 100.0) * 270.0


func _update_api_enabled() -> void:
	var custom := llm_mode_option.get_selected_id() == 1
	base_url_edit.editable = custom
	model_edit.editable = custom
	api_key_edit.editable = custom
	if custom:
		var validation_error := SettingsManager.validate_llm_values(
			SettingsManager.LLM_MODE_CUSTOM,
			base_url_edit.text,
			model_edit.text,
			api_key_edit.text
		)
		if validation_error.is_empty():
			_show_api_status("自定义 API 将只保存在本机 user://settings.cfg，并仅发送给你填写的兼容接口。", false)
		else:
			_show_api_status(validation_error, true)
	else:
		_show_api_status("官方试玩会使用当前同源代理；自定义 API 使用 OpenAI-compatible /chat/completions。", false)


func _show_api_status(message: String, is_error: bool) -> void:
	status_label.text = message
	status_label.modulate = Color(0.82, 0.18, 0.14, 1.0) if is_error else Color(1.0, 1.0, 1.0, 0.82)
