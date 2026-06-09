extends Node2D
class_name SourceMark
## 源印交互点 — E 键净化源印，完成碎片

func interact() -> void:
	## E 键交互入口 — PlayerController 调用
	var fragment = _find_fragment_scene()
	if fragment and fragment.has_method("on_source_mark_interact"):
		fragment.on_source_mark_interact()
	else:
		print("[SourceMark] 未找到 fragment 处理节点")


func _find_fragment_scene() -> Node:
	var current: Node = self
	while current:
		if current.has_method("on_source_mark_interact"):
			return current
		if current.is_in_group("fragment_state"):
			return current
		current = current.get_parent()
	return null
