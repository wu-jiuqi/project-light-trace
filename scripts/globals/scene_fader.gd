extends CanvasLayer
## 场景过渡黑屏淡入/淡出 — 方案一
## 挂载为 Autoload，跨场景持久

var _fader: ColorRect
var is_fading := false
var _changing := false


func _ready() -> void:
	layer = 256
	_fader = ColorRect.new()
	_fader.color = Color(0, 0, 0, 0)
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fader)


## 强制全黑（新场景加载后立即调用，防止闪现）
func ensure_black() -> void:
	_fader.color.a = 1.0


## 淡出至黑 → 切换场景（由 SceneManager.change_scene 调用）
func fade_out_and_switch(scene: String) -> void:
	if _changing:
		return
	_changing = true
	is_fading = true

	var t = create_tween()
	t.tween_property(_fader, "color:a", 1.0, 0.25)
	await t.finished

	SceneManager._raw_switch(scene)


## 淡入（新场景 ready 后调用）
func fade_in() -> void:
	_changing = false
	var t = create_tween()
	t.tween_property(_fader, "color:a", 0.0, 0.35)
	await t.finished
	is_fading = false
