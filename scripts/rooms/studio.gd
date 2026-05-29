extends "res://scripts/rooms/room_base.gd"
## 废弃画室 — 老画家的住所
## 出口：下→镇公所 / 左→墓园
## 入境：镇公所上→画室下 / 墓园右→画室左


func _setup_exits() -> void:
	_exit("bottom", "Townhall")
	_exit("left",   "Graveyard")

	_spawn("bottom", "Townhall")   # 镇公所上出 → 画室下入
	_spawn("left",   "Graveyard")  # 墓园右出 → 画室左入
