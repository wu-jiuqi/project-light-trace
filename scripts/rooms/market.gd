extends "res://scripts/rooms/room_base.gd"
## 市集街 — 面包房、花店、旅店
## 出口：上→墓园 / 右→广场
## 入境：首次→(272,67) / 墓园下→上边缘 / 广场左→右边缘


func _setup_exits() -> void:
	_exit("top",   "Graveyard")
	_exit("right", "Square")

	# --- 出生点 ---
	# 首次入场（过场动画后）
	_add_spawn_marker("from_cutscene", Vector2(272, 67))

	# 从墓园下进入 → 上边缘中点
	_add_spawn_marker("from_graveyard", SPAWN_TOP)

	# 从广场左进入 → 右边缘中点
	_add_spawn_marker("from_square", SPAWN_RIGHT)

	print("[Market] 出生点: from_cutscene=%s from_graveyard=%s from_square=%s" % [
		Vector2(272, 67), SPAWN_TOP, SPAWN_RIGHT
	])


func _add_spawn_marker(spawn_name: String, position: Vector2) -> void:
	var m = Marker2D.new()
	m.name = spawn_name
	m.position = position
	$SpawnPoints.add_child(m)
