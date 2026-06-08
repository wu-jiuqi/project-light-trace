extends RefCounted
## 存档系统常量与路径工具
## 静态工具类，提供存档版本号、路径常量、槽位配置

class_name SaveConstants

## 当前存档格式版本（语义化版本号）
const SAVE_VERSION: String = "1.0.0"

## 存档目录
const SAVE_DIR: String = "user://saves/"

## 最大存档槽位数
const MAX_SLOTS: int = 3

## 自动存档间隔（秒）
const AUTO_SAVE_INTERVAL: float = 30.0

## 临时文件后缀
const TMP_SUFFIX: String = ".tmp"

## 备份文件后缀
const BAK_SUFFIX: String = ".bak"

## 最后活动槽位记录路径
const LAST_SLOT_PATH: String = "user://saves/last_slot.json"


## 返回指定槽位的存档文件路径
static func slot_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + ".json"


## 返回指定槽位的聊天记录文件路径
static func chat_path(slot: int) -> String:
	return SAVE_DIR + "chat_" + str(slot) + ".json"


## 返回指定槽位的临时文件路径（原子写入用）
static func tmp_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + TMP_SUFFIX


## 返回指定槽位的备份文件路径
static func bak_path(slot: int) -> String:
	return SAVE_DIR + "save_" + str(slot) + BAK_SUFFIX
