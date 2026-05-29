extends "res://scripts/rooms/room_base.gd"
## 市集街 — 面包房、花店、旅店
## 出口：上→墓园 / 右→广场


func _setup_exits() -> void:
	_exit("top",   "Graveyard")
	_exit("right", "Square")
	_spawn("top",   "Graveyard")
	_spawn("right", "Square")

	_add_spawn_marker("from_cutscene", Vector2(272, 67))


func _setup_npcs() -> void:
	var fengshen = preload("res://scenes/characters/id0762/npc_fengshen.tscn").instantiate()
	fengshen.position = Vector2(230, 77)
	add_child(fengshen)

	var laotang = preload("res://scenes/characters/id0762/npc_laotang.tscn").instantiate()
	laotang.position = Vector2(250, 260)
	add_child(laotang)

	var alian = preload("res://scenes/characters/id0762/npc_alian.tscn").instantiate()
	alian.position = Vector2(573, 107)
	add_child(alian)

	print("[Market] 冯婶(旅店230,77) 老唐(面包房250,260) 阿莲(花店573,107) 已登场")


func _setup_pickups() -> void:
	pass


func _add_spawn_marker(spawn_name: String, position: Vector2) -> void:
	var m = Marker2D.new()
	m.name = spawn_name
	m.position = position
	$SpawnPoints.add_child(m)
