extends Node2D
class_name BellTower
## 钟楼交互脚本 — 日晷校准终端
## 玩家收集全部 5 个日晷数据后，在此校准指针角度

## 交互提示显示名称
@export var display_name: String = "钟楼观测台"

## 校准目标：66°（60° + 6°，因钟楼时间 06:12）
const TARGET_ANGLE: int = 66
## 每次调整步长
const ANGLE_STEP: int = 6

var is_source_mark_revealed: bool = false


func interact() -> void:
	## E 键交互入口 — PlayerController 调用
	var fragment = _find_fragment_scene()
	if fragment and fragment.has_method("on_bell_tower_interact"):
		fragment.on_bell_tower_interact(self)
	else:
		print("[BellTower] 未找到 fragment 处理节点")


func mark_source_revealed() -> void:
	is_source_mark_revealed = true


func _find_fragment_scene() -> Node:
	var current: Node = self
	while current:
		if current.has_method("on_bell_tower_interact"):
			return current
		if current.is_in_group("fragment_state"):
			return current
		current = current.get_parent()
	return null
