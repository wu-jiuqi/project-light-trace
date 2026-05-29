extends "res://scripts/rooms/room_base.gd"
## 墓园 — 守墓人小屋，拱形通道连接画室
## 出口：右→画室 / 下→市集街
## 入境：画室左→墓园右 / 市集街上→墓园下


func _setup_exits() -> void:
	_exit("right",  "Studio")
	_exit("bottom", "Market")

	_spawn("right",  "Studio")   # 画室左出 → 墓园右入
	_spawn("bottom", "Market")   # 市集街上出 → 墓园下入
