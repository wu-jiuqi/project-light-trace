extends Node

signal pack_download_progress(pack_id: String, downloaded_bytes: int, total_bytes: int)
signal pack_loaded(pack_id: String)
signal pack_failed(pack_id: String, message: String)
signal pack_state_changed(pack_id: String, success: bool)

const PACK_SAVE_DIR := "user://packs"
const PACKS := {
	"0002": {
		"url": "packs/fragment_0002.pck",
		"local": "user://packs/fragment_0002.pck",
		"scenes": [
			"res://scenes/cinematic/fragment_0002_transition.tscn",
			"res://scenes/fragments/fragment_0002.tscn",
			"res://scenes/rooms/id0002/ticket_check.tscn",
		],
	},
	"0003": {
		"url": "packs/fragment_0003.pck",
		"local": "user://packs/fragment_0003.pck",
		"scenes": [
			"res://scenes/cinematic/fragment_0003_transition.tscn",
			"res://scenes/cinematic/fragment_0003_end.tscn",
			"res://scenes/fragments/fragment_0003.tscn",
			"res://scenes/rooms/id0003/loft.tscn",
		],
	},
	"0004": {
		"url": "packs/fragment_0004.pck",
		"local": "user://packs/fragment_0004.pck",
		"scenes": [
			"res://scenes/cinematic/fragment_0004_transition.tscn",
			"res://scenes/cinematic/fragment_0004_end.tscn",
			"res://scenes/fragments/fragment_0004.tscn",
			"res://scenes/rooms/id0004/passage.tscn",
		],
	},
}

var _loaded_packs: Dictionary = {}
var _loading_packs: Dictionary = {}
var _active_requests: Dictionary = {}


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	for pack_id in _active_requests.keys():
		var request := _active_requests[pack_id] as HTTPRequest
		if request == null:
			continue
		pack_download_progress.emit(
			str(pack_id),
			request.get_downloaded_bytes(),
			request.get_body_size()
		)


func has_pack_for_scene(scene_path: String) -> bool:
	return not get_pack_id_for_scene(scene_path).is_empty()


func is_pack_loaded_for_scene(scene_path: String) -> bool:
	var pack_id := get_pack_id_for_scene(scene_path)
	return pack_id.is_empty() or bool(_loaded_packs.get(pack_id, false))


func get_pack_id_for_scene(scene_path: String) -> String:
	for pack_id in PACKS.keys():
		var pack_info: Dictionary = PACKS[pack_id]
		var scenes: Array = pack_info.get("scenes", [])
		if scene_path in scenes:
			return str(pack_id)
	return ""


func ensure_pack_for_scene(scene_path: String) -> bool:
	var pack_id := get_pack_id_for_scene(scene_path)
	if pack_id.is_empty():
		return true
	return await ensure_pack(pack_id)


func ensure_pack(pack_id: String) -> bool:
	if pack_id.is_empty() or not PACKS.has(pack_id):
		return true
	if not OS.has_feature("web"):
		return true
	if bool(_loaded_packs.get(pack_id, false)):
		return true
	if bool(_loading_packs.get(pack_id, false)):
		return await _wait_for_pack(pack_id)

	_loading_packs[pack_id] = true
	var pack_info: Dictionary = PACKS[pack_id]
	var local_path := str(pack_info.get("local", ""))

	if FileAccess.file_exists(local_path) and _load_pack_file(pack_id, local_path):
		return true

	var ok := await _download_pack(pack_id, str(pack_info.get("url", "")), local_path)
	if not ok:
		return false
	ok = _load_pack_file(pack_id, local_path)
	if not ok:
		_finish_pack_request(pack_id, false, "resource pack mount failed")
	return ok


func prefetch_pack(pack_id: String) -> void:
	if pack_id.is_empty() or not PACKS.has(pack_id):
		return
	if not OS.has_feature("web"):
		return
	if bool(_loaded_packs.get(pack_id, false)) or bool(_loading_packs.get(pack_id, false)):
		return
	ensure_pack(pack_id)


func prefetch_next_after(fragment_id: String) -> void:
	match fragment_id:
		"0001":
			prefetch_pack("0002")
		"0002":
			prefetch_pack("0003")
		"0003":
			prefetch_pack("0004")


func _wait_for_pack(pack_id: String) -> bool:
	while bool(_loading_packs.get(pack_id, false)):
		var result: Array = await pack_state_changed
		if str(result[0]) == pack_id:
			return bool(result[1])
	return bool(_loaded_packs.get(pack_id, false))


func _download_pack(pack_id: String, url: String, local_path: String) -> bool:
	if url.is_empty() or local_path.is_empty():
		_finish_pack_request(pack_id, false, "pack url or local path is empty")
		return false

	_ensure_pack_save_dir()
	var request := HTTPRequest.new()
	request.name = "PackRequest_%s" % pack_id
	request.download_file = local_path
	add_child(request)
	_active_requests[pack_id] = request
	set_process(true)

	var resolved_url := _resolve_pack_url(url)
	var err := request.request(resolved_url)
	if err != OK:
		request.queue_free()
		_active_requests.erase(pack_id)
		_finish_pack_request(pack_id, false, "request failed with code %d" % err)
		return false

	var response: Array = await request.request_completed
	_active_requests.erase(pack_id)
	request.queue_free()
	set_process(not _active_requests.is_empty())

	var result := int(response[0])
	var response_code := int(response[1])
	if result != HTTPRequest.RESULT_SUCCESS:
		_finish_pack_request(pack_id, false, "download failed with result %d" % result)
		return false
	if response_code < 200 or response_code >= 300:
		_finish_pack_request(pack_id, false, "download http status %d" % response_code)
		return false
	return true


func _load_pack_file(pack_id: String, local_path: String) -> bool:
	var ok := ProjectSettings.load_resource_pack(local_path)
	if ok:
		_loaded_packs[pack_id] = true
		_loading_packs.erase(pack_id)
		pack_loaded.emit(pack_id)
		pack_state_changed.emit(pack_id, true)
	else:
		_loaded_packs.erase(pack_id)
	return ok


func _finish_pack_request(pack_id: String, success: bool, message: String) -> void:
	_loading_packs.erase(pack_id)
	if success:
		_loaded_packs[pack_id] = true
		pack_loaded.emit(pack_id)
	else:
		_loaded_packs.erase(pack_id)
		pack_failed.emit(pack_id, message)
	pack_state_changed.emit(pack_id, success)


func _ensure_pack_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PACK_SAVE_DIR))


func _resolve_pack_url(relative_or_absolute_url: String) -> String:
	if relative_or_absolute_url.begins_with("http://") or relative_or_absolute_url.begins_with("https://"):
		return relative_or_absolute_url
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge = Engine.get_singleton("JavaScriptBridge")
		var script := "new URL(%s, window.location.href).href" % JSON.stringify(relative_or_absolute_url)
		return str(bridge.eval(script, true))
	return relative_or_absolute_url
