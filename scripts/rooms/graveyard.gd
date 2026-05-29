extends "res://scripts/rooms/room_base.gd"
## 墓园 — 守墓人小屋，拱形通道连接画室
## 出口：右→画室 / 下→市集街


func _setup_exits() -> void:
	_exit("right",  "Studio")
	_exit("bottom", "Market")

	_spawn("right",  "Studio")
	_spawn("bottom", "Market")


func _setup_npcs() -> void:
	var npc = preload("res://scenes/characters/id0762/npc_laocui.tscn").instantiate()
	npc.position = Vector2(66, 168)
	add_child(npc)
	print("[Graveyard] 老崔(66,168) 已登场")


func _setup_pickups() -> void:
	# 已拾取（在背包中）或已消耗（交给NPC后）→ 不再生成
	if InventoryManager.has_item(InventoryManager.ItemID.CORNFLOWER):
		return
	if GameManager.is_item_used("cornflower"):
		return
	var p = preload("res://scenes/items/id0762/cornflower.tscn").instantiate()
	p.position = Vector2(740, 70)
	add_child(p)
	print("[Graveyard] 矢车菊 就绪")
