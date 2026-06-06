extends SceneTree

const FONT_PATH := "res://assets/fonts/SourceHanSerifSC-VF.ttf"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var configured_path = ProjectSettings.get_setting("gui/theme/custom_font", "")
	if configured_path != FONT_PATH:
		printerr("[FAIL] project default font is not configured")
		quit(1)
		return

	var font = load(FONT_PATH)
	if font == null:
		printerr("[FAIL] project default font cannot be loaded")
		quit(1)
		return

	for character in ["溯", "光", "计", "划", "继", "续", "游", "戏"]:
		if not font.has_char(character.unicode_at(0)):
			printerr("[FAIL] font is missing character: %s" % character)
			quit(1)
			return

	print("[SUMMARY] bundled Source Han Serif font covers title screen Chinese characters")
	quit(0)
