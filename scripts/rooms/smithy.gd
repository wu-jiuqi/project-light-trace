extends "res://scripts/rooms/room_base.gd"
## 铁匠铺 — 老霍的铁砧
## 出口：上→广场
## 入境：广场下→铁匠铺上


func _setup_exits() -> void:
	_exit("top", "Square")
	_spawn("top", "Square")    # 广场下出 → 铁匠铺上入
