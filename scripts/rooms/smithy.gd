extends "res://scripts/rooms/room_base.gd"
## 铁匠铺 — 老霍的铁砧
## 传送：上→广场


func _setup_exits() -> void:
	_exit("top", "Square")
	_spawn("top", "Square")


func _setup_npcs() -> void:
	var npc = preload("res://scenes/characters/id0762/npc_laohuo.tscn").instantiate()
	npc.position = Vector2(426, 290)
	add_child(npc)
	print("[Smithy] 老霍(426,290) 已登场")
