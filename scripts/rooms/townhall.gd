extends "res://scripts/rooms/room_base.gd"
## 镇公所 — 档案室与铸造日志
## 出口：左→广场 / 上→画室


func _setup_exits() -> void:
	_exit("left", "Square")
	_exit("top",  "Studio")

	_spawn("left", "Square")
	_spawn("top",  "Studio")


func _setup_pickups() -> void:
	# 已拾取（在背包中）或已消耗（交给NPC后）→ 不再生成
	if InventoryManager.has_item(InventoryManager.ItemID.FORGE_LOG):
		return
	if GameManager.is_item_used("forge_log"):
		return
	var p = preload("res://scenes/items/id0762/forge_log.tscn").instantiate()
	p.position = Vector2(320, 380)
	add_child(p)
	print("[Townhall] 铸造日志 就绪")
