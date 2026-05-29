extends Node
## 全局场景管理器 (Autoload)
## 负责跨场景切换 — 出生点由 PlayerController._ready() 自行处理
## 切换时通过 SceneFader 实现黑屏过渡

# === 跨场景传递的出生点名称 ===
var pending_spawn_point: String = ""

# === 信号 ===
signal scene_changing(target_scene: String, spawn_point: String)
signal scene_changed(target_scene: String)

func change_scene(target_scene_path: String, spawn_point_name: String) -> void:
	if target_scene_path.is_empty():
		printerr("[SceneManager] change_scene 失败: target_scene_path 为空")
		return

	pending_spawn_point = spawn_point_name
	scene_changing.emit(target_scene_path, spawn_point_name)
	print("[SceneManager] 切换场景: %s (出生点: %s)" % [target_scene_path, spawn_point_name])

	# 通过 SceneFader 淡出后再切场景
	SceneFader.fade_out_and_switch(target_scene_path)


## 由 SceneFader 在淡出完成后调用，执行实际场景加载
func _raw_switch(target_scene_path: String) -> void:
	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		printerr("[SceneManager] 场景加载失败: %s (code %d)" % [target_scene_path, err])
		pending_spawn_point = ""
