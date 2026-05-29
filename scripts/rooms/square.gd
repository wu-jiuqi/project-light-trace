extends "res://scripts/rooms/room_base.gd"
## 广场 — 小镇中心枢纽
## 出口：左→市集街 / 下→铁匠铺 / 右→镇公所


func _setup_exits() -> void:
	_exit("left",   "Market")
	_exit("bottom", "Smithy")
	_exit("right",  "Townhall")

	_spawn("left",   "Market")
	_spawn("bottom", "Smithy")
	_spawn("right",  "Townhall")

	var m = Marker2D.new()
	m.name = "from_cutscene"
	m.position = Vector2(416, 256)
	$SpawnPoints.add_child(m)


func _setup_npcs() -> void:
	var npc = preload("res://scenes/characters/id0762/npc_weila.tscn").instantiate()
	npc.position = Vector2(375, 126)
	add_child(npc)
	print("[Square] 薇拉(375,126) 已登场")
