extends RefCounted
## 存档校验和工具
## SHA-256 校验和计算/验证（纯静态方法）
## 使用 Godot 4.x 内置 HashingContext API
##
## v1.1.0: 校验和改为基于序列化后的 JSON 字符串计算
## 而非基于内存字典的紧凑 JSON，消除 JSON 往返导致的不匹配。

class_name SaveChecksum


## 从原始 JSON 字符串计算 SHA-256 校验和
## 将 JSON 中的 "checksum" 字段值替换为空字符串后计算哈希
## 这样校验和不依赖 JSON 往返后的浮点精度/键序/类型变化
## 返回校验和的前 16 个十六进制字符（SHA-256 的前 8 字节）
static func compute_raw(raw_json: String) -> String:
	# 将 "checksum": "..." 替换为 "checksum": ""（保留可选逗号）
	var checksum_pattern: RegEx = RegEx.new()
	var err: int = checksum_pattern.compile("\"checksum\"\\s*:\\s*\"[^\"]*\"")

	if err != OK:
		printerr("[SaveChecksum] RegEx 编译失败: %d" % err)
		return ""

	var normalized: String = checksum_pattern.sub(raw_json, "\"checksum\": \"\"", true)
	if normalized.is_empty() and not raw_json.is_empty():
		printerr("[SaveChecksum] 规范化 JSON 字符串失败")
		return ""

	return _hash_hex(normalized)


## 验证原始 JSON 字符串的校验和是否正确
## 从 JSON 中提取存储的校验和，用 compute_raw 重新计算并比较
static func verify_raw(raw_json: String) -> bool:
	var checksum_pattern: RegEx = RegEx.new()
	var err: int = checksum_pattern.compile("\"checksum\"\\s*:\\s*\"([^\"]*)\"")

	if err != OK:
		printerr("[SaveChecksum] RegEx 编译失败: %d" % err)
		return false

	var regex_match: RegExMatch = checksum_pattern.search(raw_json)
	if not regex_match:
		printerr("[SaveChecksum] JSON 中未找到 checksum 字段")
		return false

	var stored_checksum: String = regex_match.get_string(1)
	if stored_checksum.is_empty():
		printerr("[SaveChecksum] 存储的校验和为空")
		return false

	var computed_checksum: String = compute_raw(raw_json)
	if computed_checksum.is_empty():
		return false

	var match: bool = stored_checksum == computed_checksum
	if not match:
		printerr("[SaveChecksum] 校验和不匹配: 存储=%s 计算=%s" % [stored_checksum, computed_checksum])
	return match


## 在 JSON 字符串中嵌入校验和
## 将 "checksum": "" 替换为 "checksum": "<checksum>"
static func embed_checksum(raw_json: String, checksum: String) -> String:
	return raw_json.replace("\"checksum\": \"\"", "\"checksum\": \"%s\"" % checksum)


## 从字典计算校验和（旧 API，保持向后兼容）
## 内部转为 JSON 字符串后调用 compute_raw
static func compute(data: Dictionary, exclude_keys: Array = ["checksum"]) -> String:
	var json_str: String = JSON.stringify(data, "\t")
	if json_str.is_empty():
		printerr("[SaveChecksum] JSON.stringify 返回空字符串")
		return ""
	return compute_raw(json_str)


## 验证字典的校验和是否正确（旧 API，保持向后兼容）
static func verify(data: Dictionary, exclude_keys: Array = ["checksum"]) -> bool:
	if not data.has("checksum"):
		printerr("[SaveChecksum] 数据中缺少 checksum 字段")
		return false

	var stored_checksum: String = str(data.get("checksum", ""))
	if stored_checksum.is_empty():
		printerr("[SaveChecksum] 存储的校验和为空")
		return false

	var json_str: String = JSON.stringify(data, "\t")
	if json_str.is_empty():
		printerr("[SaveChecksum] JSON.stringify 返回空字符串")
		return false

	return verify_raw(json_str)


# ============================================================
# 内部工具
# ============================================================

## 对字符串计算 SHA-256，返回前 16 个十六进制字符
static func _hash_hex(text: String) -> String:
	if text.is_empty():
		printerr("[SaveChecksum] 输入字符串为空")
		return ""

	var ctx: HashingContext = HashingContext.new()
	var err: int = ctx.start(HashingContext.HASH_SHA256)
	if err != OK:
		printerr("[SaveChecksum] HashingContext.start() 失败: %d" % err)
		return ""

	err = ctx.update(text.to_utf8_buffer())
	if err != OK:
		printerr("[SaveChecksum] HashingContext.update() 失败: %d" % err)
		return ""

	var hash_bytes: PackedByteArray = ctx.finish()
	if hash_bytes.is_empty():
		printerr("[SaveChecksum] HashingContext.finish() 返回空")
		return ""

	# 取前 16 个十六进制字符（SHA-256 的前 8 字节）
	var result: String = ""
	for i in range(mini(8, hash_bytes.size())):
		result += "%02x" % hash_bytes[i]
	return result
