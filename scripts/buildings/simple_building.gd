@tool
extends Node2D

## 简单建筑脚本：贴图、Body位置、碰撞体 全部手动控制

@export var building_texture: Texture2D:
	set(value):
		building_texture = value
		_apply_texture()

## Body Sprite2D 位置（手动设置）
@export var body_position: Vector2 = Vector2(0, -624):
	set(value):
		body_position = value
		_apply_body()

## 碰撞体尺寸
@export var collision_size: Vector2 = Vector2(967, 270):
	set(value):
		collision_size = value
		_apply_collision()

## 碰撞体位置
@export var collision_position: Vector2 = Vector2(0, -135):
	set(value):
		collision_position = value
		_apply_collision()


func _ready() -> void:
	_apply_texture()
	_apply_body()
	_apply_collision()


func _apply_texture() -> void:
	var body = get_node_or_null("Body") as Sprite2D
	if body and building_texture:
		body.texture = building_texture


func _apply_body() -> void:
	var body = get_node_or_null("Body") as Sprite2D
	if body:
		body.position = body_position


func _apply_collision() -> void:
	var static_body = get_node_or_null("StaticBody2D") as StaticBody2D
	if not static_body:
		return

	var col = static_body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not col:
		return

	# 每次 new，避免多实例共享同一个 shape 导致相互影响
	var shape = RectangleShape2D.new()
	shape.size = collision_size
	col.shape = shape
	col.position = collision_position
