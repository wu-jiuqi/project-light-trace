class_name BasePanel
extends Control

## 舞台容器（1280x720）
var stage: Control

## 面板是否可见
var is_open: bool = false


func _ready() -> void:
	# 全屏锚点
	anchor_right = 1.0
	anchor_bottom = 1.0
	# 查找 stage 节点
	stage = get_node_or_null("Stage")
	_setup_vignette()
	_on_ready()


## 子类重写此方法进行初始化
func _on_ready() -> void:
	pass


## 自动设置 Vignette 遮罩
func _setup_vignette() -> void:
	var vignette := get_node_or_null("Vignette") as ColorRect
	if vignette:
		vignette.color = UIConstants.VIGNETTE_COLOR
		vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 打开面板
func open() -> void:
	show()
	is_open = true
	_on_open()


## 关闭面板
func close() -> void:
	hide()
	is_open = false
	_on_close()


## 切换面板
func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func _on_open() -> void:
	pass


func _on_close() -> void:
	pass
