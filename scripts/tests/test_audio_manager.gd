extends SceneTree

var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var audio_manager = root.get_node("AudioManager")
	_check(AudioServer.get_bus_index("BGM") >= 0, "BGM bus exists")
	_check(AudioServer.get_bus_index("Ambience") >= 0, "Ambience bus exists")
	_check(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")
	_check(AudioServer.get_bus_index("Voice") >= 0, "Voice bus exists")

	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 8000.0
	stream.buffer_length = 0.1
	audio_manager.play_bgm(stream, "test_bgm", 0.0, -12.0, true)
	await process_frame
	_check(audio_manager.get_current_bgm_id() == "test_bgm", "play_bgm stores current id")
	audio_manager.play_sfx(stream, AudioManager.PRIORITY_HIGH, -3.0)
	audio_manager.play_voice("test_voice", stream, AudioManager.PRIORITY_HIGH, -4.0, -5.0)
	await process_frame
	audio_manager.stop_voice(0.0)
	audio_manager.stop_bgm(0.0)
	audio_manager.set_channel_volume("bgm", 0.5)
	_check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")) < 0.0, "channel volume changes bus db")

	if _failures == 0:
		print("[SUMMARY] audio manager checks passed")
	quit(_failures)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		printerr("[FAIL] %s" % message)
