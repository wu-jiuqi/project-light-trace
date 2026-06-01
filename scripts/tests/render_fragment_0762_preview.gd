extends SceneTree

const PREVIEW_PATH := "res://generated/fragment_0762_runtime_preview.png"


func _init() -> void:
	call_deferred("_render_preview")


func _render_preview() -> void:
	var packed = load("res://scenes/fragments/fragment_0762.tscn")
	var fragment = packed.instantiate()
	root.add_child(fragment)
	await process_frame
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://generated"))
	var image = root.get_viewport().get_texture().get_image()
	var error = image.save_png(PREVIEW_PATH)
	if error != OK:
		push_error("Failed to save 0762 runtime preview: %s" % error)
		quit(1)
		return
	print("[SUMMARY] 0762 runtime preview saved: %s" % PREVIEW_PATH)
	quit()
