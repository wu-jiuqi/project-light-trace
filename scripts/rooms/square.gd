extends "res://scripts/rooms/room_base.gd"
## 广场 — 小镇中心枢纽
## 出口：左→市集街 / 下→铁匠铺 / 右→镇公所
## 入境：市集街右→广场左 / 铁匠铺上→广场下 / 镇公所左→广场右


func _setup_exits() -> void:
	_exit("left",   "Market")
	_exit("bottom", "Smithy")
	_exit("right",  "Townhall")

	_spawn("left",   "Market")    # 市集街右出 → 广场左入
	_spawn("bottom", "Smithy")    # 铁匠铺上出 → 广场下入
	_spawn("right",  "Townhall")  # 镇公所左出 → 广场右入

	var m = Marker2D.new()
	m.name = "from_cutscene"
	m.position = Vector2(416, 256)
	$SpawnPoints.add_child(m)
