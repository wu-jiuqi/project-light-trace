extends "res://scripts/rooms/room_base.gd"
## 废弃画室 — 老画家的住所
## 出口：下→镇公所 / 左→墓园


func _setup_exits() -> void:
	_exit("bottom", "Townhall")
	_exit("left",   "Graveyard")

	_spawn("bottom", "Townhall")
	_spawn("left",   "Graveyard")


func _setup_npcs() -> void:
	var npc = preload("res://scenes/characters/id0762/npc_laogu.tscn").instantiate()
	npc.position = Vector2(475, 239)
	add_child(npc)
	print("[Studio] 老顾(475,239) 已登场")
