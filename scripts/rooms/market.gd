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
	var alian = preload("res://scenes/characters/id0762/npc_alian.tscn").instantiate()
	alian.position = Vector2(180, 350)
	add_child(alian)

	var laotang = preload("res://scenes/characters/id0762/npc_laotang.tscn").instantiate()
	laotang.position = Vector2(620, 350)
	add_child(laotang)

	print("[Market] 阿莲(花店) 老唐(面包房) 已登场")


func _setup_pickups() -> void:
	pass


func _add_spawn_marker(spawn_name: String, position: Vector2) -> void:
	var m = Marker2D.new()
	m.name = spawn_name
	m.position = position
	$SpawnPoints.add_child(m)
