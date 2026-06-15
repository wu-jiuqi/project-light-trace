extends Node2D
class_name Sundial
## 日晷交互脚本 — E 键观测、线索记录、状态管理
## PlayerController 通过 interact() 方法触发

## 日晷唯一标识 A/B/C/D/E
@export var sundial_id: String = "A"
## 阴影角度（度）
@export var angle: int = 12
## 位置描述
@export var place_name: String = ""
## 观测描述文本
@export var description: String = ""
## 日晷显示名称
@export var display_name: String = ""

## 该日晷是否已被观测
var is_observed: bool = false


func interact() -> void:
	## E 键交互入口 — PlayerController 调用
	# 向上查找 fragment 场景节点，委托其处理交互逻辑
	var fragment = _find_fragment_scene()
	if fragment and fragment.has_method("on_sundial_interact"):
		fragment.on_sundial_interact(self)
	else:
		# 降级：本地默认观测
		print("[Sundial] 未找到 fragment 处理节点，使用默认逻辑")
		_default_observe()


func mark_observed() -> void:
	is_observed = true


## 向上遍历父节点，查找场景根节点（fragment_0001）
func _find_fragment_scene() -> Node:
	var current: Node = self
	while current:
		# 检查当前节点是否有 on_sundial_interact 方法
		if current.has_method("on_sundial_interact"):
			return current
		# 也检查是否在 fragment_state 组中
		if current.is_in_group("fragment_state"):
			return current
		current = current.get_parent()
	return null


## 默认观测逻辑（无 fragment 时的降级处理）
func _default_observe() -> void:
	if is_observed:
		print("[Sundial] 日晷%s 已观测: %d°" % [sundial_id, angle])
		return
	is_observed = true
	# 尝试查找并通知 ClueSystem
	var parent_scene = get_tree().current_scene
	if parent_scene:
		var clue_sys = parent_scene.find_child("ClueSystem0001", true, false)
		if clue_sys and clue_sys.has_method("discover_clue"):
			clue_sys.discover_clue(
				display_name, "observation",
				"%s：%d°" % [place_name, angle], place_name
			)
	print("[Sundial] 日晷%s 首次观测: %d° — %s" % [sundial_id, angle, description])
