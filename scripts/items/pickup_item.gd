extends Area2D
## 可拾取物品 — 绕过 Godot 4.6.2 Area2D+Label tscn Bug
## Label 在 _ready() 中动态创建

const SFX_PICKUP := preload("res://assets/audio/sfx/ui_item_pickup.wav")
const SFX_PICKUP_VOLUME_DB: float = -4.0

@export var item_id: int = 0
@export var item_name: String = "物品"
@export var item_color: Color = Color(1, 0.5, 0.5, 1)
@export var item_texture: Texture2D
@export var item_texture_path: String = ""
@export var item_pos_x: float = 0.0
@export var item_pos_y: float = 0.0

var _player_nearby: bool = false
var _label: Label
var _is_picked_up: bool = false  # 防止重复拾取


func _ready() -> void:
	add_to_group("pickup")  # 标记为可拾取物品，供玩家 _is_pickup_item() 检测
	if item_pos_x != 0.0 or item_pos_y != 0.0:
		position = Vector2(item_pos_x, item_pos_y)
	collision_layer = 8  # layer 8: 可交互物品，供玩家 InteractionArea 检测
	collision_mask = 1   # 检测 layer 1: 物理体（玩家 CharacterBody2D）
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_visual()


func _create_visual() -> void:
	# 碰撞体（必需！否则 body_entered 不会触发）
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	shape.position = Vector2.ZERO
	add_child(shape)
	
	var texture := item_texture if item_texture else _load_texture(item_texture_path)
	if texture:
		var sprite := Sprite2D.new()
		sprite.name = "ItemSprite"
		sprite.texture = texture
		var size := texture.get_size()
		var max_side = maxf(size.x, size.y)
		if max_side > 0.0:
			sprite.scale = Vector2.ONE * (34.0 / max_side)
		add_child(sprite)
	else:
		var sprite := ColorRect.new()
		sprite.name = "ItemSprite"
		sprite.offset_left = -12; sprite.offset_top = -12
		sprite.offset_right = 12; sprite.offset_bottom = 12
		sprite.color = item_color
		add_child(sprite)
	
	# 标签
	_label = Label.new()
	_label.name = "ItemLabel"
	_label.offset_left = -40; _label.offset_top = -44
	_label.offset_right = 40; _label.offset_bottom = -20
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_constant_override("outline_size", 3)
	_label.text = item_name
	_label.visible = true
	add_child(_label)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		if _label:
			_label.text = "按 E 拾取 %s" % item_name


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if _label:
			_label.text = item_name


func _pickup() -> bool:
	if _is_picked_up:
		return false
	_is_picked_up = true

	if not InventoryManager.has_method("add_item"):
		_is_picked_up = false
		return false
	if InventoryManager.add_item(item_id):
		# 播放拾取 SFX — 纸工世界通用物品交互音效
		if AudioManager and AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx(SFX_PICKUP, AudioManager.PRIORITY_NORMAL, SFX_PICKUP_VOLUME_DB)
		print("[PickupItem] 拾取: %s" % item_name)
		queue_free()
		return true

	_is_picked_up = false
	return false


func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)
