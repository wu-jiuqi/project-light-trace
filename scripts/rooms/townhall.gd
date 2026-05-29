extends "res://scripts/rooms/room_base.gd"
## 镇公所 — 档案室与铸造日志
## 出口：左→广场 / 上→画室


func _setup_exits() -> void:
	_exit("left", "Square")
	_exit("top",  "Studio")

	_spawn("left", "Square")
	_spawn("top",  "Studio")
