extends Node
## 背包/物品管理系统 — Autoload
## 管理玩家收集的物品，提供背包UI数据

enum ItemID {
	NONE = -1,
}

const ITEM_META: Dictionary = {}

# 当前拥有的物品
var _items: Array[int] = []

# 信号
signal item_added(item_id: int)
signal item_removed(item_id: int)
signal backpack_toggled(is_open: bool)

# 背包UI状态
var backpack_open: bool = false


func _ready() -> void:
	_items.clear()
	print("[Inventory] 背包系统就绪 | %d 种可收集物品" % ITEM_META.size())


# ============================================================
# 物品操作
# ============================================================

func add_item(item_id: int) -> bool:
	if not ITEM_META.has(item_id):
		printerr("[Inventory] 无效物品: %d" % item_id)
		return false
	
	if has_item(item_id):
		return false  # 已有
	
	_items.append(item_id)
	var meta = ITEM_META[item_id]
	print("[Inventory] 获得 %s %s" % [meta["icon"], meta["name"]])
	item_added.emit(item_id)
	return true


func remove_item(item_id: int) -> bool:
	var idx = _items.find(item_id)
	if idx == -1:
		return false
	_items.remove_at(idx)
	item_removed.emit(item_id)
	return true


func has_item(item_id: int) -> bool:
	return item_id in _items


func get_all_items() -> Array[int]:
	return _items.duplicate()


func get_item_count() -> int:
	return _items.size()


func get_item_meta(item_id: int) -> Dictionary:
	return ITEM_META.get(item_id, {})


# ============================================================
# 序列化接口 — 供 SaveManager 调用
# ============================================================

func to_dict() -> Dictionary:
	## 将背包物品序列化为字典
	return {"inventory": _items.duplicate()}


func from_dict(data: Dictionary) -> void:
	## 从字典恢复背包物品
	_items.clear()
	var raw_inv = data.get("inventory", [])
	if raw_inv is Array:
		for item_id in raw_inv:
			var parsed_id := int(item_id)
			if ITEM_META.has(parsed_id):
				_items.append(parsed_id)
