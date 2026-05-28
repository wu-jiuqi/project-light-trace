extends Area2D
class_name TransitionArea
## 场景切换触发器
## 挂载在 Area2D 节点上，检测 Player 进入后触发 SceneManager 场景切换

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn_point: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	if target_scene.is_empty():
		printerr("[TransitionArea] '%s' 未设置 target_scene!" % name)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		printerr("[TransitionArea] '%s' 无法切换: target_scene 为空" % name)
		return

	var spawn = target_spawn_point
	if spawn.is_empty():
		spawn = name  # fallback: 用自身节点名作为出生点标识
		printerr("[TransitionArea] '%s' target_spawn_point 为空，回退使用节点名 '%s'" % [name, spawn])

	print("[TransitionArea] Player 进入 '%s' → %s (Spawn: %s)" % [name, target_scene, spawn])
	# 延迟切换避免物理回调冲突
	call_deferred("_do_change", target_scene, spawn)


func _do_change(scene: String, spawn: String) -> void:
	SceneManager.change_scene(scene, spawn)
