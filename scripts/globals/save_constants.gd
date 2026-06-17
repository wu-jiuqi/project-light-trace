extends RefCounted
## Save system constants and path helpers.
class_name SaveConstants

const SAVE_VERSION: String = "1.0.0"

const DEFAULT_SAVE_DIR: String = "user://saves/"
const SAVE_DIR: String = DEFAULT_SAVE_DIR
const LAST_SLOT_PATH: String = DEFAULT_SAVE_DIR + "last_slot.json"

const MAX_SLOTS: int = 3
const AUTO_SAVE_INTERVAL: float = 30.0
const TMP_SUFFIX: String = ".tmp"
const BAK_SUFFIX: String = ".bak"

static var _save_dir: String = DEFAULT_SAVE_DIR


static func set_save_dir(path: String) -> void:
	var normalized := path.strip_edges()
	if normalized.is_empty():
		normalized = DEFAULT_SAVE_DIR
	if not normalized.ends_with("/"):
		normalized += "/"
	_save_dir = normalized


static func reset_save_dir() -> void:
	_save_dir = DEFAULT_SAVE_DIR


static func save_dir() -> String:
	return _save_dir


static func last_slot_path() -> String:
	return _save_dir + "last_slot.json"


static func slot_path(slot: int) -> String:
	return _save_dir + "save_" + str(slot) + ".json"


static func chat_path(slot: int) -> String:
	return _save_dir + "chat_" + str(slot) + ".json"


static func tmp_path(slot: int) -> String:
	return _save_dir + "save_" + str(slot) + TMP_SUFFIX


static func bak_path(slot: int) -> String:
	return _save_dir + "save_" + str(slot) + BAK_SUFFIX
