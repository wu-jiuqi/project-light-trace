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
	npc.position = Vector2(400, 320)
	add_child(npc)
	print("[Graveyard] 老崔(守墓人) 已登场")
