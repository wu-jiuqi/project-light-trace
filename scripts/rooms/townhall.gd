extends "res://scripts/rooms/room_base.gd"
## 镇公所 — 档案室与铸造日志
## 出口：左→广场 / 上→画室
## 入境：广场右→镇公所左 / 画室下→镇公所上


func _setup_exits() -> void:
	_exit("left", "Square")
	_exit("top",  "Studio")

	_spawn("left", "Square")   # 广场右出 → 镇公所左入
	_spawn("top",  "Studio")   # 画室下出 → 镇公所上入
