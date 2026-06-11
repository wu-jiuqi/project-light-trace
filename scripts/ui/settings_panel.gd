class_name SettingsPanel
extends BasePanel

@onready var master_slider: HSlider = $"Stage/SettingsContainer/ContentArea/VolumeSection/MasterRow/MasterSlider"
@onready var bgm_slider: HSlider = $"Stage/SettingsContainer/ContentArea/VolumeSection/BgmRow/BgmSlider"
@onready var sfx_slider: HSlider = $"Stage/SettingsContainer/ContentArea/VolumeSection/SfxRow/SfxSlider"
@onready var master_value: Label = $"Stage/SettingsContainer/ContentArea/VolumeSection/MasterRow/MasterValue"
@onready var bgm_value: Label = $"Stage/SettingsContainer/ContentArea/VolumeSection/BgmRow/BgmValue"
@onready var sfx_value: Label = $"Stage/SettingsContainer/ContentArea/VolumeSection/SfxRow/SfxValue"
@onready var fullscreen_check: CheckButton = $"Stage/SettingsContainer/ContentArea/DisplaySection/FullscreenRow/FullscreenCheck"
@onready var countdown_label: Label = $"Stage/SettingsContainer/ContentArea/DisplaySection/FullscreenRow/CountdownLabel"
@onready var resolution_timer: Timer = $"Stage/SettingsContainer/ButtonRow/ResolutionTimer"
@onready var save_button: Button = $"Stage/SettingsContainer/ButtonRow/SaveButton"
@onready var cancel_button: Button = $"Stage/SettingsContainer/ButtonRow/CancelButton"

# 缓存打开时的初始值，用于"取消"恢复
var _cached_values: Dictionary = {}


func _on_ready() -> void:
	save_button.pressed.connect(save_settings)
	cancel_button.pressed.connect(cancel)
	master_slider.value_changed.connect(_on_slider_changed.bind("master", master_slider, master_value))
	bgm_slider.value_changed.connect(_on_slider_changed.bind("bgm", bgm_slider, bgm_value))
	sfx_slider.value_changed.connect(_on_slider_changed.bind("sfx", sfx_slider, sfx_value))
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	resolution_timer.timeout.connect(_on_resolution_timeout)


func _on_open() -> void:
	load_settings()
	_cache_snapshot()


func load_settings() -> void:
	SettingsManager.load()
	master_slider.value = SettingsManager.master_volume * 100
	bgm_slider.value = SettingsManager.bgm_volume * 100
	sfx_slider.value = SettingsManager.sfx_volume * 100
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	_update_value_labels()


func save_settings() -> void:
	SettingsManager.master_volume = master_slider.value / 100.0
	SettingsManager.bgm_volume = bgm_slider.value / 100.0
	SettingsManager.sfx_volume = sfx_slider.value / 100.0
	SettingsManager.fullscreen = fullscreen_check.button_pressed
	SettingsManager.save()
	SettingsManager.apply()
	close()


func cancel() -> void:
	cancel_resolution_timer()
	# 恢复缓存值
	master_slider.value = _cached_values.get("master", 100)
	bgm_slider.value = _cached_values.get("bgm", 100)
	sfx_slider.value = _cached_values.get("sfx", 100)
	fullscreen_check.button_pressed = _cached_values.get("fullscreen", false)
	_update_value_labels()
	close()


func start_resolution_timer() -> void:
	resolution_timer.stop()
	resolution_timer.start()
	countdown_label.text = "15s 后确认"


func cancel_resolution_timer() -> void:
	resolution_timer.stop()
	countdown_label.text = ""


func _on_slider_changed(_value: float, bus: String, slider: HSlider, label: Label) -> void:
	label.text = "%d%%" % int(slider.value)
	var vol: float = slider.value / 100.0
	var bus_map: Dictionary = {"master": "Master", "bgm": "BGM", "sfx": "SFX"}
	# 实时预览音量
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_map[bus]), linear_to_db(vol))


func _on_fullscreen_toggled(_pressed: bool) -> void:
	start_resolution_timer()


func _on_resolution_timeout() -> void:
	countdown_label.text = "已确认"
	var fs: bool = fullscreen_check.button_pressed
	if fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _cache_snapshot() -> void:
	_cached_values = {
		"master": master_slider.value,
		"bgm": bgm_slider.value,
		"sfx": sfx_slider.value,
		"fullscreen": fullscreen_check.button_pressed,
	}


func _update_value_labels() -> void:
	master_value.text = "%d%%" % int(master_slider.value)
	bgm_value.text = "%d%%" % int(bgm_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)
