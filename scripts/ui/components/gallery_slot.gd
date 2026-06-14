class_name GallerySlot
extends Control

signal selected(item: Dictionary, unlocked: bool)

@onready var _button: TextureButton = $TextureButton
@onready var _preview_root: Control = $TextureButton/PreviewRoot
@onready var _thumbnail: TextureRect = $TextureButton/PreviewRoot/Thumbnail
@onready var _lock_overlay: ColorRect = $TextureButton/PreviewRoot/LockOverlay
@onready var _lock_label: Label = $TextureButton/PreviewRoot/LockOverlay/LockLabel
@onready var _empty_texture: TextureRect = $TextureButton/EmptyTexture

var _item: Dictionary = {}
var _unlocked: bool = false


func _ready() -> void:
	_button.pressed.connect(_on_pressed)
	_set_empty()


func bind_item(item: Dictionary, unlocked: bool) -> void:
	_item = item.duplicate(true)
	_unlocked = unlocked

	var texture := load(str(_item.get("thumbnail", ""))) as Texture2D
	_thumbnail.texture = texture
	_thumbnail.visible = texture != null
	_preview_root.visible = true
	_empty_texture.visible = false
	_button.disabled = false
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_lock_overlay.visible = not _unlocked
	_lock_label.visible = not _unlocked
	modulate.a = 1.0


func bind_empty() -> void:
	_set_empty()


func _set_empty() -> void:
	_item = {}
	_unlocked = false
	_preview_root.visible = false
	_thumbnail.texture = null
	_lock_overlay.visible = false
	_lock_label.visible = false
	_empty_texture.visible = true
	_button.disabled = true
	_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	modulate.a = 0.55


func _on_pressed() -> void:
	if _item.is_empty():
		return
	selected.emit(_item, _unlocked)
