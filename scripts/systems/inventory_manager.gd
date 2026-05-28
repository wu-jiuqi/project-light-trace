extends Node
## 背包/物品管理系统 — Autoload
## 管理玩家收集的物品，提供背包UI数据

# 物品定义
enum ItemID {
	NONE = -1,
	FORGE_LOG = 0,    # 铸造日志（镇公所地下室）
	CORNFLOWER = 1,   # 矢车菊（花店后巷）
	FIRE_SEED = 2,    # 火种（红色觉醒后老霍给）
}

# 物品元数据
const ITEM_META: Dictionary = {
	ItemID.FORGE_LOG: {
		"name": "铸造日志",
		"icon": "📜",
		"color": Color(0.9, 0.3, 0.3, 1),  # 红色
		"desc": "铁匠铺的日志，记载零时前火特别旺——老霍锻造了一把刀但没交给任何人。"
	},
	ItemID.CORNFLOWER: {
		"name": "不太一样的矢车菊",
		"icon": "🪻",
		"color": Color(0.3, 0.4, 0.9, 1),  # 蓝色
		"desc": "花店后巷最早的颜色残留——它在这个灰色世界里带着一丝蓝。"
	},
	ItemID.FIRE_SEED: {
		"name": "火种",
		"icon": "🔥",
		"color": Color(0.9, 0.7, 0.2, 1),  # 黄色
		"desc": "老霍给你的火种——锻造台恢复真火后留下的。他说：'拿去吧，也许有用。'"
	}
}

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
	if item_id < 0 or item_id >= ITEM_META.size():
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
	var meta = ITEM_META[item_id]
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
