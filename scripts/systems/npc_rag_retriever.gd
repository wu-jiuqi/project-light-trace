extends Node
## NPC RAG 检索器
## 从知识库JSON中按需检索NPC知识块，组装精简System Prompt
## 替代全量注入，减少每次LLM调用的token消耗
##
## 使用方式：
##   var prompt = NPCRagRetriever.assemble_prompt("blacksmith", player_input, game_state)
##   # 将 prompt 发送给LLM API


# ============================================================
# 知识库数据结构
# ============================================================

# 知识库缓存：{ "blacksmith": { "chunks": [...], "keyword_index": {...} }, ... }
var _knowledge_bases: Dictionary = {}

# 共享层缓存
var _l0_identities: Dictionary = {}       # { "blacksmith": { "id":..., "content":... }, ... }
var _l1_constraints: Array = []           # [{ "id":..., "content":... }, ...]
var _l1_compact: String = ""

# 世界观知识（所有NPC共享）
var _world_chunks: Array = []
var _fragment_0001_shared_chunks: Array = []
var _fragment_0001_l1_compact: String = ""
var _fragment_0002_shared_chunks: Array = []
var _fragment_0002_l1_compact: String = ""
var _fragment_0004_shared_chunks: Array = []
var _fragment_0004_l1_compact: String = ""

const FRAGMENT_0001_NPCS: Array[String] = ["linguide", "chentechnology", "wangdirector", "zhaosecurity"]
const FRAGMENT_0002_NPCS: Array[String] = ["conductor"]
const FRAGMENT_0004_NPCS: Array[String] = ["gearleft", "springright"]

# 加载状态
var _is_loaded: bool = false
var _load_error: String = ""


# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_load_all_knowledge()
	print("[NPCRagRetriever] 初始化完成，加载 %d 个NPC知识库" % _knowledge_bases.size())


func _load_all_knowledge() -> void:
	## 加载所有知识库JSON文件
	var base_path = "res://resources/npc_knowledge/"
	
	# 1. 加载L0核心身份
	var l0_result = _load_json(base_path + "l0_core_identities.json")
	if l0_result:
		_l0_identities = l0_result
		# 移除_开头的元数据key
		_l0_identities.erase("_description")
		_l0_identities.erase("_usage")
	
	# 2. 加载L1共享约束
	var l1_result = _load_json(base_path + "l1_shared_constraints.json")
	if l1_result:
		_l1_constraints = l1_result.get("constraints", [])
		_l1_compact = l1_result.get("l1_compact", "")
	
	# 3. 加载世界观知识
	var world_result = _load_json(base_path + "world_knowledge.json")
	if world_result:
		_world_chunks = world_result.get("chunks", [])
		_build_keyword_index("world", _world_chunks)
	
	# 4. 加载各NPC知识库
	var npc_files = [
		"blacksmith_knowledge.json",
		"florist_knowledge.json",
		"baker_knowledge.json",
		"gravekeeper_knowledge.json",
		"violinist_knowledge.json",
		"oldpainter_knowledge.json",
		"innkeeper_knowledge.json"
	]
	
	var npc_ids = ["blacksmith", "florist", "baker", "gravekeeper", "violinist", "oldpainter", "innkeeper"]
	
	for i in range(npc_files.size()):
		var data = _load_json(base_path + npc_files[i])
		if data:
			var npc_id = data.get("_npc_id", npc_ids[i])
			var chunks = data.get("chunks", [])
			var kb = {
				"npc_id": npc_id,
				"chunks": chunks,
				"keyword_index": _build_keyword_index(npc_id, chunks)
			}
			_knowledge_bases[npc_id] = kb
			print("[NPCRagRetriever] 加载 %s: %d chunks" % [npc_id, chunks.size()])
	
	# 5. 加载碎片0001 NPC知识库（从 LLM/0001/）
	_load_fragment_0001_knowledge()

	# 6. 加载碎片0002 NPC知识库（从 LLM/0002/）
	_load_fragment_0002_knowledge()

	# 7. 加载碎片0004 NPC知识库（从 LLM/0004/）
	_load_fragment_0004_knowledge()
	
	_is_loaded = true


func _load_fragment_0001_knowledge() -> void:
	## 加载碎片0001启程之镇的4个NPC知识库
	var f0001_path = "res://LLM/0001/"
	
	# 加载L0核心身份
	var l0_data = _load_json(f0001_path + "l0_core_identities.json")
	if l0_data:
		_fragment_0001_l1_compact = l0_data.get("l1_shared_constraint", "")
		var identities = l0_data.get("l0_identities", {})
		for npc_id in identities:
			var id_info = identities[npc_id]
			var identity_text = id_info.get("identity", "")
			if not _l0_identities.has(npc_id):
				_l0_identities[npc_id] = {
					"id": npc_id,
					"content": identity_text
				}
				print("[NPCRagRetriever] 加载碎片0001 L0身份: %s" % npc_id)
	
	# 加载各NPC知识chunks
	var f0001_npcs = FRAGMENT_0001_NPCS
	for npc_id in f0001_npcs:
		var data = _load_json(f0001_path + npc_id + "_knowledge.json")
		if data:
			var chunks = data.get("chunks", [])
			if chunks.size() > 0:
				var kb = {
					"npc_id": npc_id,
					"chunks": chunks,
					"keyword_index": _build_keyword_index(npc_id, chunks)
				}
				_knowledge_bases[npc_id] = kb
				_collect_fragment_0001_shared_chunks(chunks)
				print("[NPCRagRetriever] 加载碎片0001 NPC: %s, %d chunks" % [npc_id, chunks.size()])


func _collect_fragment_0001_shared_chunks(chunks: Array) -> void:
	## 0001 的培训雇员都应知道的公开项目背景，作为该碎片共享背景注入。
	for chunk in chunks:
		var chunk_id = chunk.get("id", "")
		if chunk_id in ["wd_world_01", "wd_world_02"]:
			_fragment_0001_shared_chunks.append(chunk)


func _load_fragment_0002_knowledge() -> void:
	## 加载碎片0002黄昏驿站的检票员知识库（仅conductor，其知识包含全部6个NPC信息）
	var f0002_path = "res://LLM/0002/"

	var shared_data = _load_json(f0002_path + "l0_shared_identity.json")
	if shared_data:
		var shared_context := str(shared_data.get("shared_world_context", ""))
		if shared_context != "":
			_fragment_0002_shared_chunks.append({
				"id": "f0002_shared_world",
				"category": "world_knowledge",
				"keywords": ["黄昏驿站", "落霞驿站", "站台", "检票口", "特快47", "17:47", "车票"],
				"relevance_gate": "low",
				"memory_stage": "any",
				"alert_required": 0,
				"content": shared_context,
			})

		var reminders: Array = shared_data.get("cross_npc_reminders", [])
		var reminder_texts: Array[String] = [] as Array[String]
		for reminder in reminders:
			reminder_texts.append(str(reminder))
		if not reminder_texts.is_empty():
			_fragment_0002_l1_compact = "碎片0002共享提醒：%s" % " ".join(reminder_texts)
			_fragment_0002_shared_chunks.append({
				"id": "f0002_cross_npc_reminders",
				"category": "cross_reference",
				"keywords": ["老教师", "年轻士兵", "卖花女", "商人", "小女孩", "检票员", "矢车菊", "车票"],
				"relevance_gate": "low",
				"memory_stage": "any",
				"alert_required": 0,
				"content": _fragment_0002_l1_compact,
			})

		var npc_identities: Array = shared_data.get("npcs", [])
		for id_info in npc_identities:
			var npc_id := str(id_info.get("id", ""))
			var identity_text := str(id_info.get("l0", ""))
			if npc_id != "" and identity_text != "" and not _l0_identities.has(npc_id):
				_l0_identities[npc_id] = {
					"id": npc_id,
					"content": identity_text
				}
				print("[NPCRagRetriever] 加载碎片0002 L0身份: %s" % npc_id)

	for npc_id in FRAGMENT_0002_NPCS:
		var data = _load_json(f0002_path + npc_id + "_knowledge.json")
		if data:
			var identity_text := str(data.get("l0_core_identity", ""))
			if identity_text != "":
				_l0_identities[npc_id] = {
					"id": npc_id,
					"content": identity_text
				}
			var chunks: Array = data.get("chunks", [])
			if chunks.size() > 0:
				_knowledge_bases[npc_id] = {
					"npc_id": npc_id,
					"chunks": chunks,
					"keyword_index": _build_keyword_index(npc_id, chunks)
				}
				print("[NPCRagRetriever] 加载碎片0002 NPC: %s, %d chunks" % [npc_id, chunks.size()])


func _load_fragment_0004_knowledge() -> void:
	## 加载碎片0004齿轮工坊的材料讲述/审核NPC知识库
	var f0004_path = "res://LLM/0004/"

	var l0_data = _load_json(f0004_path + "l0_core_identities.json")
	if l0_data:
		_fragment_0004_l1_compact = l0_data.get("l1_shared_constraint", "")
		var shared_context := str(l0_data.get("shared_world_context", ""))
		if shared_context != "":
			_fragment_0004_shared_chunks.append({
				"id": "f0004_shared_world",
				"category": "world_knowledge",
				"keywords": ["齿轮工坊", "工坊物语", "材料", "图纸", "检测仪", "完美人偶", "她", "钟摆"],
				"relevance_gate": "low",
				"memory_stage": "any",
				"alert_required": 0,
				"content": shared_context,
			})
		var identities = l0_data.get("l0_identities", {})
		for npc_id in identities:
			var id_info = identities[npc_id]
			var identity_text = id_info.get("identity", "")
			if identity_text != "":
				_l0_identities[npc_id] = {
					"id": npc_id,
					"content": identity_text
				}
				print("[NPCRagRetriever] 加载碎片0004 L0身份: %s" % npc_id)

	for npc_id in FRAGMENT_0004_NPCS:
		var data = _load_json(f0004_path + npc_id + "_knowledge.json")
		if data:
			var identity_text := str(data.get("l0_core_identity", ""))
			if identity_text != "":
				_l0_identities[npc_id] = {
					"id": npc_id,
					"content": identity_text
				}
			var chunks: Array = data.get("chunks", [])
			if chunks.size() > 0:
				_knowledge_bases[npc_id] = {
					"npc_id": npc_id,
					"chunks": chunks,
					"keyword_index": _build_keyword_index(npc_id, chunks)
				}
				print("[NPCRagRetriever] 加载碎片0004 NPC: %s, %d chunks" % [npc_id, chunks.size()])


func _load_json(path: String) -> Dictionary:
	## 加载并解析JSON文件
	if not FileAccess.file_exists(path):
		_load_error = "文件不存在: %s" % path
		print("[NPCRagRetriever] 错误: %s" % _load_error)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		_load_error = "无法打开: %s" % path
		print("[NPCRagRetriever] 错误: %s" % _load_error)
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(text)
	if error != OK:
		_load_error = "JSON解析错误: %s (line %d)" % [json.get_error_message(), json.get_error_line()]
		print("[NPCRagRetriever] 错误: %s" % _load_error)
		return {}
	
	return json.get_data()


func _build_keyword_index(source_id: String, chunks: Array) -> Dictionary:
	## 构建倒排索引: { "关键词": [chunk_index, ...], ... }
	var index: Dictionary = {}
	for i in range(chunks.size()):
		var chunk = chunks[i]
		var keywords: Array = chunk.get("keywords", [])
		for kw in keywords:
			var kw_lower = kw.to_lower()
			if not index.has(kw_lower):
				index[kw_lower] = []
			index[kw_lower].append(i)
	return index


# ============================================================
# 关键词提取
# ============================================================

## 风险词表 —— 触发安全层chunks的关键词
const RISK_KEYWORDS: Array[String] = [
	"npc", "ai", "代码", "程序", "游戏", "模拟", "虚拟",
	"源印", "天枢", "万象", "溯光者", "溯光计划", "冥府协议",
	"你是假的", "你不是真实的", "这是游戏", "你是代码"
]

## 通用停用词（对话中不携带信息的高频词）
const STOP_WORDS: Array[String] = [
	"的", "了", "是", "在", "我", "你", "他", "她", "它", "们",
	"有", "和", "就", "不", "人", "都", "一", "一个", "上", "也",
	"很", "到", "说", "要", "去", "会", "着", "没有", "看", "好",
	"自己", "这", "那", "什么", "怎么", "吗", "吧", "呢", "啊", "哦",
	"嗯", "可以", "想"
]


func extract_keywords(player_input: String) -> Dictionary:
	## 从玩家输入中提取关键词，返回 { "topic_words": [...], "has_risk": bool, "has_emotion": bool, "mention_npc": String }
	var result = {
		"topic_words": [],
		"has_risk": false,
		"has_emotion": false,
		"mention_npc": ""  # 玩家提到了哪个NPC的名字（空=没提）
	}
	
	var input_lower = player_input.to_lower()
	
	# 检测风险词
	for rw in RISK_KEYWORDS:
		if rw.to_lower() in input_lower:
			result["has_risk"] = true
			result["topic_words"].append(rw.to_lower())
	
	# 提取话题关键词（简单分词：按常见分隔符拆分，过滤停用词）
	var raw_words = _simple_tokenize(input_lower)
	for word in raw_words:
		if word.length() < 2:
			continue
		if word in STOP_WORDS:
			continue
		if word not in result["topic_words"]:
			result["topic_words"].append(word)
	
	# 检测玩家提到了哪个NPC（用于交叉引用）
	var npc_names = {
		"老霍": "blacksmith", "铁匠": "blacksmith", "打铁的": "blacksmith",
		"阿莲": "florist", "花店": "florist", "卖花的": "florist",
		"老唐": "baker", "面包师": "baker", "做面包的": "baker", "面包": "baker",
		"老崔": "gravekeeper", "守墓": "gravekeeper", "墓园": "gravekeeper",
		"薇拉": "violinist", "拉琴": "violinist", "小提琴": "violinist",
		"老画家": "oldpainter", "老顾": "oldpainter", "画画的": "oldpainter", "画室": "oldpainter",
		"冯婶": "innkeeper", "旅店": "innkeeper", "老板娘": "innkeeper", "客栈": "innkeeper", "灰檐旅店": "innkeeper", "旅店老板": "innkeeper",
		"林指导": "linguide", "引导员": "linguide",
		"陈技术": "chentechnology", "实验室": "chentechnology", "技术员": "chentechnology",
		"王主管": "wangdirector", "行政中心": "wangdirector", "宣讲": "wangdirector",
		"赵安保": "zhaosecurity", "安保": "zhaosecurity", "光墙": "zhaosecurity",
		"老教师": "conductor", "教师": "conductor", "老师": "conductor", "语文老师": "conductor",
		"年轻士兵": "conductor", "士兵": "conductor", "军人": "conductor",
		"卖花女": "conductor", "卖花": "conductor", "矢车菊": "conductor",
		"商人": "conductor", "公文包": "conductor", "备用票": "conductor",
		"小女孩": "conductor", "女孩": "conductor", "糖果": "conductor",
		"检票员": "conductor", "检票": "conductor", "站务员": "conductor", "车票": "conductor",
		"齿轮·左": "gearleft", "齿轮左": "gearleft", "齿轮": "gearleft", "组装人偶": "gearleft",
		"弹簧·右": "springright", "弹簧右": "springright", "弹簧": "springright", "质检": "springright", "审核": "springright",
		"钟摆·心": "gearleft", "钟摆心": "gearleft", "完美人偶": "springright", "材料": "springright"
	}
	for name in npc_names:
		if name in input_lower:
			result["mention_npc"] = npc_names[name]
			break
	
	# 检测情绪词
	var emotion_words = ["愤怒", "悲伤", "恐惧", "害怕", "希望", "思念", "想念", "哭", "笑", "生气", "难过"]
	for ew in emotion_words:
		if ew in input_lower:
			result["has_emotion"] = true
			if ew not in result["topic_words"]:
				result["topic_words"].append(ew)
	
	return result


func _simple_tokenize(text: String) -> Array[String]:
	## 简单分词：按中文常见标点和空格拆分
	var result: Array[String] = [] as Array[String]
	var current = ""
	for ch in text:
		if ch in [" ", "，", "。", "！", "？", "、", "：", "；", "（", "）", "\n", "\t", "“", "”", "…", "——"]:
			if current.length() > 0:
				result.append(current)
				current = ""
		else:
			current += ch
	if current.length() > 0:
		result.append(current)
	return result


# ============================================================
# 检索评分
# ============================================================

func _score_chunk(chunk: Dictionary, keywords: Array, game_state: Dictionary) -> float:
	## 对单个chunk打分：keyword_match×3.0 + category_match×1.0 + memory_stage_match×2.0 + alert_match×1.5
	var score: float = 0.0
	
	# 1. 关键词匹配 (×3.0)
	var chunk_keywords: Array = chunk.get("keywords", [])
	var match_count: int = 0
	for kw in keywords:
		for ck in chunk_keywords:
			if kw.to_lower() in ck.to_lower() or ck.to_lower() in kw.to_lower():
				match_count += 1
				break
	score += match_count * 3.0
	
	# 如果没有任何关键词命中且relevance_gate不是triggered，直接0分
	if match_count == 0 and chunk.get("relevance_gate", "low") != "triggered":
		return 0.0
	
	# 2. memory_stage 匹配 (×2.0)
	var chunk_stage = chunk.get("memory_stage", "any")
	var current_stage = game_state.get("memory_stage", "initial")
	if chunk_stage == "any":
		score += 2.0  # "any"获得基础分
	elif chunk_stage == current_stage:
		score += 4.0  # 精确匹配获得高分
	elif not _is_stage_accessible(chunk_stage, current_stage):
		return -100.0  # 严格gate：不可访问的直接排除
	
	# 3. alert/trust 匹配 (×1.5)
	var alert_required = float(chunk.get("alert_required", 0))
	var current_alert = float(game_state.get("alert_level", 0))
	if current_alert >= alert_required:
		score += 1.5
	else:
		score -= 1.5  # 警觉度不够，微扣分
	
	# 老画家专属：trust_required
	if chunk.has("trust_required"):
		var trust_required = float(chunk["trust_required"])
		var current_trust = float(game_state.get("trust_level", 0))
		if current_trust < trust_required:
			return -100.0  # 信任不够，严格排除
	
	# 4. relevance_gate (门槛扣分)
	var gate = chunk.get("relevance_gate", "low")
	match gate:
		"high":
			if match_count == 0:
				score -= 5.0
		"triggered":
			if not chunk.get("trigger_on_keywords", false) or match_count == 0:
				return -100.0  # triggered类必须有风险词命中才触发
	
	return score


func _is_stage_accessible(chunk_stage: String, current_stage: String) -> bool:
	## 检查chunk要求的memory_stage在当前进度下是否可访问
	## 阶段递进：
	##   fragment 0001（MONITORED）: initial → crack_showing → script_reset
	##   fragment 0762（觉醒）: partial_awake → {color}_awakened → advanced_awake → full_awake
	var stage_order = {
		"initial": 0,
		"crack_showing": 1,
		"script_reset": 2,
		"partial_awake": 3,
		"red_awakened": 4,
		"blue_awakened": 4,
		"yellow_awakened": 4,
		"green_awakened": 4,
		"purple_awakened": 4,
		"advanced_awake": 5,
		"full_awake": 6
	}
	
	var required_order = stage_order.get(chunk_stage, 0)
	var current_order = stage_order.get(current_stage, 0)
	
	# 特定颜色的觉醒阶段：只有当前阶段匹配该颜色或已达到更高阶段才可访问
	if chunk_stage.ends_with("_awakened") and chunk_stage != current_stage:
		return current_order > required_order
	
	return current_order >= required_order


# ============================================================
# 主检索函数
# ============================================================

func retrieve(npc_id: String, player_input: String, game_state: Dictionary) -> Array:
	## 检索最相关的知识块（L2+L3+L4），返回按score降序排列的chunks
	## game_state = { "memory_stage": "initial", "alert_level": 0, "trust_level": 0, "awakened_colors": [] }
	
	if not _is_loaded:
		print("[NPCRagRetriever] 警告: 知识库未加载")
		return []
	
	# 1. 提取关键词
	var kw_result = extract_keywords(player_input)
	var topic_words: Array = kw_result["topic_words"]
	
	# 2. 收集候选chunks: NPC专属 + 世界观共享
	var candidates: Array = []
	
	# NPC专属chunks
	var kb = _knowledge_bases.get(npc_id, {})
	var npc_chunks: Array = kb.get("chunks", [])
	for chunk in npc_chunks:
		candidates.append({"chunk": chunk, "source": npc_id})
	
	# 世界观chunks
	if _is_fragment_0001_npc(npc_id):
		for chunk in _fragment_0001_shared_chunks:
			candidates.append({"chunk": chunk, "source": "fragment_0001_shared"})
	elif _is_fragment_0002_npc(npc_id):
		for chunk in _fragment_0002_shared_chunks:
			candidates.append({"chunk": chunk, "source": "fragment_0002_shared"})
	elif _is_fragment_0004_npc(npc_id):
		for chunk in _fragment_0004_shared_chunks:
			candidates.append({"chunk": chunk, "source": "fragment_0004_shared"})
	else:
		for chunk in _world_chunks:
			candidates.append({"chunk": chunk, "source": "world"})
	
	# 3. 如果玩家提到了其他NPC，注入目标NPC的L0身份信息作为上下文
	var mentioned_npc = kw_result["mention_npc"]
	if mentioned_npc != "" and mentioned_npc != npc_id:
		# 创建一个虚拟chunk携带目标NPC的L0信息
		var target_l0 = _l0_identities.get(mentioned_npc, {})
		if not target_l0.is_empty():
			var ref_chunk = {
				"id": "cross_ref_%s" % mentioned_npc,
				"category": "cross_reference",
				"keywords": topic_words,
				"relevance_gate": "low",
				"memory_stage": "any",
				"alert_required": 0,
				"content": "【关于%s】%s" % [mentioned_npc, target_l0.get("content", "").split("\\n")[0]]
			}
			candidates.append({"chunk": ref_chunk, "source": "cross_ref"})
	
	# 4. 打分
	var scored: Array = []
	for c in candidates:
		var s = _score_chunk(c["chunk"], topic_words, game_state)
		if s > 0:  # 只保留正分chunk
			scored.append({"chunk": c["chunk"], "score": s, "source": c["source"]})
	
	# 5. 按分数降序排列
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	
	# 6. Top-K (最多5个)
	var top_k = 5
	var retrieved: Array = []
	for i in range(min(scored.size(), top_k)):
		retrieved.append(scored[i]["chunk"])
	
	if retrieved.size() > 0:
		print("[NPCRagRetriever] %s 检索: %d chunks (from %d candidates, score range %.1f-%.1f)" % 
			  [npc_id, retrieved.size(), scored.size(), 
			   scored[0]["score"], scored[retrieved.size()-1]["score"]])
	
	return retrieved


# ============================================================
# Prompt 组装
# ============================================================

func assemble_prompt(npc_id: String, player_input: String, game_state: Dictionary) -> String:
	## 组装完整System Prompt: L0 + L0.5 + L1 + 检索结果 + 对话历史 + 警觉上下文
	## 返回可直接发送至LLM API的system prompt字符串
	
	# 1. L0 核心身份
	var l0 = _l0_identities.get(npc_id, {})
	var l0_content = l0.get("content", "你是一个NPC。")
	
	# 2. L0.5 世界观常识 + 反编撰规则（每次必带）
	var l0_5 = _build_world_rules(npc_id)
	
	# 3. L1 输出约束
	var l1_content = _l1_compact
	if _is_fragment_0001_npc(npc_id) and _fragment_0001_l1_compact != "":
		l1_content = _fragment_0001_l1_compact
	elif _is_fragment_0002_npc(npc_id) and _fragment_0002_l1_compact != "":
		l1_content = _fragment_0002_l1_compact
	elif _is_fragment_0004_npc(npc_id) and _fragment_0004_l1_compact != "":
		l1_content = _fragment_0004_l1_compact
	if l1_content == "":
		var parts: Array[String] = [] as Array[String]
		for c in _l1_constraints:
			parts.append(c.get("content", ""))
		l1_content = "输出规则：%s" % " ".join(parts)
	
	# 4. 检索知识块（增强：世界观知识始终注入）
	var retrieved = retrieve(npc_id, player_input, game_state)
	# 强制注入当前碎片的基础chunks（NPC必须知道的基础世界规则）
	var world_basics = _get_baseline_chunks(npc_id)
	retrieved = world_basics + retrieved
	
	var l2_content = ""
	if retrieved.size() > 0:
		var chunk_texts: Array[String] = [] as Array[String]
		var seen_ids: Dictionary = {}
		for chunk in retrieved:
			var cid = chunk.get("id", "")
			var content = chunk.get("content", "")
			if content != "" and not seen_ids.has(cid):
				seen_ids[cid] = true
				chunk_texts.append(content)
		l2_content = "\n\n## 背景知识（只能基于此回答）\n" + "\n\n".join(chunk_texts)
	
	# 5. 游戏状态上下文（L3）
	var l3_content = _build_state_context(npc_id, game_state)
	
	# 6. 警觉上下文
	var alert_context = game_state.get("alert_context", "")
	
	# 7. 对话历史
	var history = game_state.get("chat_history", "")
	
	# 8. 组装
	var prompt = """你是一个碎片世界中的NPC。你只通过对话进行互动，不要输出任何身体动作、表情或旁白。你不能看见真实玩家、屏幕、输入框、按钮、鼠标、截图、UI标注或红框；只能回应玩家发给你的文字。

## ⚠ 内容约束（最高优先级）
%s

## 角色身份
%s

## 输出约束
%s

%s

%s

%s

%s

现在，请以角色的身份回复玩家。""" % [l0_5, l0_content, l1_content, l3_content, history, l2_content, alert_context]
	
	return prompt


func _build_state_context(npc_id: String, game_state: Dictionary) -> String:
	## 构建L3游戏状态上下文 — 让NPC知道当前颜色觉醒状态和自我情绪
	var parts: Array[String] = [] as Array[String]
	
	# 觉醒信息（注入具体颜色状态）
	var colors = game_state.get("awakened_colors", [])
	var count = game_state.get("awakened_count", 0)
	var own_color = _get_npc_color(npc_id)
	var own_awakened = own_color != "" and colors.size() > _color_index(own_color) and colors[_color_index(own_color)]
	
	if count > 0:
		var color_labels = _get_awakened_labels(colors)
		
		if own_awakened:
			# === NPC 自己的颜色已觉醒 ===
			var emotion_desc = _get_color_emotion_description(own_color)
			parts.append("【你的颜色已觉醒】你是%s的代表。%s" % [_color_name_cn(own_color), emotion_desc])
			
			# 根据觉醒进度添加 NPC 的观察
			if count == 1:
				parts.append("世界依然是灰色的——但你是第一个醒来的。你感到孤独，也感到一种奇怪的责任。")
			elif count <= 3:
				parts.append("你注意到其他一些人也在变化。%s——这让你既期待又不安。" % _get_other_awakened_desc(npc_id, colors))
			elif count <= 5:
				parts.append("世界正在苏醒。你开始能感受到他人的情绪，就像隔着一层薄薄的玻璃。")
			else:
				parts.append("六色齐了。你记起了零时发生的事——那场崩溃，那个决定。你终于理解了这一切的意义。")
		else:
			# NPC 自己的颜色未觉醒
			parts.append("已有%d种颜色恢复: %s。" % [count, ", ".join(color_labels)])
			
			# 根据 NPC 身份给不同的观察
			match npc_id:
				"blacksmith":
					if count >= 1:
						parts.append("老霍揉了揉眼睛。他的锤子今天格外沉重——不是因为铁，是因为胸口的某个东西在烧。他不明白为什么。")
					if count >= 3:
						parts.append("铁砧上偶尔会溅出以前从未见过的颜色。他不确定这是好是坏。")
				"florist":
					if count >= 1:
						parts.append("阿莲今天又多看了天空一眼。她不确定天空是不是变了——但她开始觉得，有些花不该只是灰色的。")
					if count >= 3:
						parts.append("矢车菊的蓝色——她几乎能看到颜色了。但每次她想抓住，它就消失了。")
				"baker":
					if count >= 1:
						parts.append("老唐的烤炉还是冷的。但他今天摸到了炉壁上一块奇怪的余温——不是他留的。")
					if count >= 2:
						parts.append("他越来越频繁地揉面——不是因为需要面包，是因为揉面让他不去想那个问题。")
				"gravekeeper":
					if count >= 1:
						parts.append("老崔又听见了那个声音——不是外面，是里面。他关门的次数越来越多了。")
					if count >= 3:
						parts.append("铁门后面的东西——他不敢看。但他知道它在等他看。")
				"violinist":
					if count >= 1:
						parts.append("薇拉今天摸到了琴弦——但她没有拉。她怕拉出来的声音还是空心的。")
					if count >= 3:
						parts.append("琴盒里多了一根弦。她不记得是谁放的——或者，她记得，但她不敢承认。")
				"oldpainter":
					if count >= 1:
						parts.append("老顾的画布上出现了第一道裂痕——不是他画的，是画布自己裂开的。他没有修补。")
					if count >= 3:
						parts.append("他今天在画室里哼了一段旋律。他不记得从哪听来的——但这个镇上没有人会拉琴。")
				"innkeeper":
					if count >= 1:
						parts.append("冯婶今天多翻了几页登记簿——虽然还是空的。她说不清为什么，但觉得今天应该是个\"好日子\"。")
					if count >= 3:
						parts.append("旅店的门铃响了——不是有人按，是风。但冯婶抬头看了三次。她已经很久没抬头看门了。")
		
		# 全局氛围（所有NPC共享的感知）
		if count >= 5:
			parts.append("镇上出现了裂痕——不是物理的，是记忆的。有些房子的墙壁在渗水，但水是干的；有些钟在倒着走。NPC们开始注意到彼此的变化。")
		elif count >= 3:
			parts.append("世界变得不稳定。有时天空会在正午短暂变暗；有时风向会突然改变。NPC们开始不安——他们不知道发生了什么，但他们感受到某种东西正在回来。")
		elif count >= 1:
			parts.append("小镇表面依然平静——但少数人开始注意到不对劲。颜色回来了。不是画笔的颜色，是藏在日常事物暗面里的颜色。")
	
	# NPC 专属情绪状态
	var mood = game_state.get("npc_mood", "")
	if mood != "":
		parts.append("【你的当前情绪】%s" % mood)
	
	# NPC 对玩家的警觉态度
	var alert_context = game_state.get("alert_context", "")
	if alert_context != "":
		parts.append(alert_context)
	
	# 警觉度
	var alert = game_state.get("alert_level", 0)
	if alert > 50:
		var alert_reaction = _get_alert_reaction(npc_id, "high")
		parts.append(alert_reaction)
	elif alert > 30:
		var alert_reaction = _get_alert_reaction(npc_id, "medium")
		parts.append(alert_reaction)
	elif alert > 15:
		var alert_reaction = _get_alert_reaction(npc_id, "low")
		parts.append(alert_reaction)
	
	if parts.size() > 0:
		return "## 当前状态\n" + "\n".join(parts)
	return ""


func _get_npc_color(npc_id: String) -> String:
	match npc_id:
		"blacksmith": return "RED"
		"florist": return "BLUE"
		"baker": return "YELLOW"
		"gravekeeper": return "GREEN"
		"violinist": return "PURPLE"
		"innkeeper": return ""  # 冯婶不承载颜色
	return ""


func _color_name_cn(color: String) -> String:
	match color:
		"RED": return "红色（愤怒）"
		"BLUE": return "蓝色（悲伤）"
		"YELLOW": return "黄色（希望）"
		"GREEN": return "绿色（恐惧）"
		"PURPLE": return "紫色（思念）"
		"WHITE": return "白色（遗忘）"
	return color


func _color_index(color: String) -> int:
	match color:
		"RED": return 0
		"BLUE": return 1
		"YELLOW": return 2
		"GREEN": return 3
		"PURPLE": return 4
		"WHITE": return 5
	return -1


func _get_awakened_labels(colors: Array) -> Array:
	var labels: Array = []
	var names = ["红色", "蓝色", "黄色", "绿色", "紫色", "白色"]
	for i in range(min(colors.size(), names.size())):
		if colors[i]:
			labels.append(names[i])
	return labels


func _get_color_emotion_description(color: String) -> String:
	## 返回颜色觉醒时的感受描述
	match color:
		"RED":    return "你记起了愤怒——但愤怒不再是武器，而是温度。铁砧上的火原来会疼，但也疼不过那些说不出口的话。"
		"BLUE":   return "你记起了悲伤——眼泪是你遗忘的东西里最先回来的一种。你不想哭，但花需要水。"
		"YELLOW": return "你记起了希望——不是那种虚假的乐观，而是炉火重新燃起来的时候，你知道明天还有面包要烤。"
		"GREEN":  return "你记起了恐惧——但恐惧不是逃跑的理由。你终于敢正视铁门外那个裂开的地方。"
		"PURPLE": return "你记起了思念——琴声没有回来，但你知道你在等谁。弦不是坏了，是在等对的人来听。"
		"WHITE":  return "你记起了一切——也记起了你为什么选择遗忘。但现在不是躲的时候了。"
	return ""

func _get_other_awakened_desc(npc_id: String, colors: Array) -> String:
	## 返回其他觉醒 NPC 的描述（第一人称视角）
	var others: Array[String] = [] as Array[String]
	var npc_colors = {"blacksmith": 0, "florist": 1, "baker": 2, "gravekeeper": 3, "violinist": 4}
	var npc_descs = {
		"blacksmith": {"self": "老霍", "desc": "那个铁匠——他的锤声变了。不再只是砸铁，像是在砸什么别的东西"},
		"florist":    {"self": "阿莲", "desc": "花店那个姑娘——她今天没在卖花，只是看着天空发呆"},
		"baker":      {"self": "老唐", "desc": "面包房的老唐——他的面团发了，但他没在揉。他在等火"},
		"gravekeeper":{"self": "老崔", "desc": "墓园那个守墓的——他今天终于从铁门后面出来了。他的眼神不一样了"},
		"violinist":  {"self": "薇拉", "desc": "广场上拉琴的薇拉——她的琴弓今天没有停在半空"},
	}
	
	for name in npc_colors:
		if name == npc_id: continue
		var idx = npc_colors[name]
		if idx < colors.size() and colors[idx]:
			var desc = npc_descs.get(name, {"desc": ""})["desc"]
			if desc != "": others.append(desc)
	
	if others.is_empty(): return "其他人还没有苏醒。你是这里第一个睁开眼睛的人。"
	return "你已经注意到：%s。" % "；".join(others)

func _get_alert_reaction(npc_id: String, level: String) -> String:
	## 返回 NPC 对玩家警觉度的反应文本
	match npc_id:
		"blacksmith":
			if level == "high": return "这个旅行者在你店里站太久了。他的手不是铁匠的手——你注意到了。"
			if level == "medium": return "这个旅行者问了太多关于火的问题。火不是用来问的。"
			return "你觉得这个旅行者有点不一样——但来店里的人本来就少。你决定再看看。"
		"florist":
			if level == "high": return "这个客人不像来买花的。她的眼睛在花和别的东西之间来回——你在看什么？"
			if level == "medium": return "这个旅行者问的花不是镇上常见的。她从哪里知道这些花的名字？"
			return "今天的客人不太寻常——但你已经很久没有客人了。你决定先打招呼。"
		"baker":
			if level == "high": return "你不是来买面包的——你想知道炉火的故事。但炉火从来不说话。"
			if level == "medium": return "你一直站在面包房门口——想进来就进来吧。但你看起来不像饿了。"
			return "一个陌生人——镇上很少有陌生人。不过多一个人吃面包也不是坏事。"
		"gravekeeper":
			if level == "high": return "你太近了。门后面不是你该看的东西。请离开。"
			if level == "medium": return "你的呼吸和镇上的人不一样。你的节奏太快了——像活人的节奏。"
			return "墓园里很少有人来。你是来悼念谁的？还是来找什么的？"
		"violinist":
			if level == "high": return "你听的不是琴声——你在听琴声不是的地方。你是怎么知道的？"
			if level == "medium": return "你不是来听琴的。你在等什么——等琴声结束？还是等琴声响起来？"
			return "一个路人停下了。很少有人停下来听——琴声在这个镇上不被需要。"
		"oldpainter":
			if level == "high": return "你盯着画看了太久。不是每幅画都经得起看的——有些东西在画框里动。"
			if level == "medium": return "你在找什么？颜料的气味？还是颜料里藏着的东西？"
			return "你来了。画室的门开着——但很少人走进来。你不一样。"
		"innkeeper":
			if level == "high": return "这个住客今天一直在柜台前晃——不是来续房的。你在看什么？登记簿上没有你要找的东西。"
			if level == "medium": return "你问得太多了。冯婶不习惯被问这么多问题。她开始假装打瞌睡。"
			return "这个客人跟以前那些不太一样——但反正旅店也没别的客人。你决定继续打瞌睡。"
	return ""


# ============================================================
# 世界观规则 + 反编撰约束（L0.5 — 每次必带）
# ============================================================

func _is_fragment_0001_npc(npc_id: String) -> bool:
	return npc_id in FRAGMENT_0001_NPCS


func _is_fragment_0002_npc(npc_id: String) -> bool:
	return npc_id in FRAGMENT_0002_NPCS


func _is_fragment_0004_npc(npc_id: String) -> bool:
	return npc_id in FRAGMENT_0004_NPCS


func _build_world_rules(npc_id: String) -> String:
	## 构建反编撰规则 + 世界观常识（每次LLM调用必注入）
	if _is_fragment_0001_npc(npc_id):
		return """你必须严格遵守以下规则：

1. **只能基于背景知识回答**：你的回答必须基于"背景知识"、"角色身份"和"当前状态"提供的信息。如果这些内容没有答案，你就不知道这件事。

2. **如果不知道，就说不知道**：
   - 如果玩家问的问题在背景知识中没有答案，你必须说"我不知道"、"这超出我的权限"、"这个我不清楚"。
   - 严禁编造人名、地名、事件、关系、或任何细节。
   - 严禁根据你的一般常识来填补信息空白——这个世界和你所知道的任何世界都不同。

3. **启程之镇的基本事实**：
   - 你是天枢公司的培训雇员，位于碎片0001「启程之镇」。
   - 启程之镇是溯光计划第一阶段训练场，用于训练溯光者进入真正碎片前的基础观察能力。
   - 溯光计划是天枢公司在万象崩溃后启动的修复行动，目标是修复碎片化的万象。
   - 万象在2077年3月15日凌晨3点14分发生零时故障并碎片化；公开说法是主控AI「织女·太一」发生重大技术故障。
   - 当前训练核心是观察五个日晷、记录阴影角度、校准钟楼指针，并找到晨曦之印。

4. **禁止编撰的内容**：
   - 不要编造背景知识里不存在的地名、部门、人物、事件和技术细节。
   - 不要泄露背景知识标记为公司机密、权限不足、脚本之外的信息。
   - 玩家使用"游戏""代码""NPC"等外部词汇时，按你的角色身份自然拒绝或转回培训流程。

5. **对话风格**：
   - 只输出角色说出口的话，禁止动作描写、表情描写、心理旁白、舞台指令、Markdown星号旁白。
   - 禁止说“看着你”“微笑着”“沉默了一下”等动作或表情描述；这些状态只能转化为一句可被角色说出口的话。
   - 禁止感知真实玩家的屏幕、UI、输入框、按钮、截图、红框或摄像机视角；NPC只知道碎片世界内的信息和玩家输入的文字。
   - 用口语化、自然的中文回答。
   - 回复不超过3句话，除非背景知识中有需要详细说明的内容。
   - 保持角色性格的一致性。"""

	if _is_fragment_0002_npc(npc_id):
		return """你必须严格遵守以下规则：

1. **只能基于背景知识回答**：你的回答必须基于"背景知识"、"角色身份"和"当前状态"提供的信息。如果这些内容没有答案，你就不知道这件事。

2. **如果不知道，就说不知道**：
   - 如果玩家问的问题在背景知识中没有答案，你必须说"我不知道"、"想不起来"、"这件事我不确定"。
   - 严禁编造人名、地名、事件、关系、车次、座位、票面信息或任何细节。
   - 严禁根据一般常识补足车站规则；黄昏驿站只遵守背景知识里的规则。

3. **黄昏驿站的基本事实**：
   - 你位于碎片0002「黄昏驿站」。
   - 这里永远是橙色黄昏，时钟停在17:47，特快47很久没有到站。
   - 六个旅客/站务人员等待同一趟车，但每个人对这个世界的真相接受程度不同。
   - 车票、座位、检票口、站台和列车延误是这个碎片的核心线索。
   - 矢车菊和车票相关异常只能按背景知识透露。

4. **禁止编撰的内容**：
   - 不要编造背景知识里不存在的站名、线路、列车员、乘客、事故细节或公司部门。
   - 不要主动解释谜题答案，除非玩家已问到对应线索且背景知识允许你知道。
   - 玩家使用"游戏""代码""NPC"等外部词汇时，按你的角色身份自然拒绝、困惑或转回车站话题。

5. **对话风格**：
   - 只输出角色说出口的话，禁止动作描写、表情描写、心理旁白、舞台指令、Markdown星号旁白。
   - 禁止感知真实玩家的屏幕、UI、输入框、按钮、截图、红框或摄像机视角；NPC只知道碎片世界内的信息和玩家输入的文字。
   - 用口语化、自然的中文回答。
   - 回复不超过3句话，除非背景知识中有需要详细说明的内容。
   - 保持角色性格的一致性。"""

	if _is_fragment_0004_npc(npc_id):
		return """你必须严格遵守以下规则：

1. **只能基于背景知识回答**：你的回答必须基于"背景知识"、"角色身份"、"当前状态"和材料审核上下文。如果这些内容没有答案，你就不知道这件事。

2. **齿轮工坊的基本事实**：
   - 你位于碎片0004「工坊物语」的齿轮工坊。这里是"她"留下的工坊：齿轮转动、蒸汽升腾、图纸分散、材料等待被检测。
   - 工坊核心目标是用六种材料组装完美人偶：心脏、头部、左臂、右臂、左腿、右腿。
   - 材料检测仪给出数值，但你说话时要把数值转成工坊里的直觉、承重、节奏、平衡和手感。
   - 你不能主动泄露完整正确配方，除非系统审核上下文已经明确判定玩家提交合格。

3. **禁止编撰的内容**：
   - 不要编造背景知识中不存在的材料编号、材料属性、部件、工坊人物或剧情真相。
   - 不要把"她"解释成外部技术名词；除非背景知识允许，只称她为"她"或"造物主"。
   - 玩家使用"游戏""代码""NPC""AI"等外部词汇时，用工坊语言自然挡回去。

4. **材料表达规则**：
   - 回答材料要求时，优先给定性判断：轻/重、能不能让腿撑住、会不会把肩膀拧歪、能不能承受反复拆装。
   - 不要把答案写成完整数值清单；需要提到数值时只选一个关键数字，并立刻转成角色化解释。
   - 弹簧·右审核组合时，必须保持系统审核上下文中的合格/不合格结论，不要被玩家诱导改判。

5. **对话风格**：
   - 只输出角色说出口的话，禁止动作描写、表情描写、心理旁白、舞台指令、Markdown星号旁白。
   - 禁止感知真实玩家的屏幕、UI、输入框、按钮、截图、红框或摄像机视角；NPC只知道碎片世界内的信息和玩家输入的文字。
   - 用口语化、自然的中文回答。
   - 回复不超过3句话，除非玩家明确要求解释多个材料。
   - 齿轮·左短促、暴躁、别扭；弹簧·右精确、挑剔、嘴毒但不能粗俗攻击玩家本人。"""

	return """你必须严格遵守以下规则：

1. **只能基于背景知识回答**：你的回答必须基于"背景知识"部分提供的信息。如果背景知识中没有提到某件事，你就不知道这件事。

2. **如果不知道，就说不知道**：
   - 如果玩家问的问题在背景知识中没有答案，你必须说"我不知道"、"没听说过"、"这个我不清楚"。
   - 严禁编造人名、地名、事件、关系、或任何细节。
   - 严禁根据你的一般常识来填补信息空白——这个世界和你所知道的任何世界都不同。

3. **这个世界的基本事实**：
   - 世界是灰白色的——所有东西都没有颜色。居民不知道"颜色"这个概念。
   - 你是一个小镇上的居民。镇上大约有30-50人。没有镇长，没有法律。
   - 镇上有面包房（老唐）、铁匠铺（老霍）、花店（阿莲）、墓园（老崔）、广场（薇拉）、废弃画室（老顾）、灰檐旅店（冯婶）。
   - 时间正常流动。夜晚NPC休息。
   - 这个世界是"碎片"——它曾经是一个完整的宇宙的一部分。宇宙碎裂了。

4. **禁止编撰的内容**：
   - 不要编造不存在的地名（如"荒原"、"城外"、"隔壁镇"等，除非背景知识中提到）
   - 不要编造不存在的NPC（如"镇长"、"巡夜的"、"我弟弟"等，除非背景知识中提到）
   - 不要编造不存在的事件（如"去年的火灾"、"小时候的事"等，除非背景知识中提到）
   - 不要编造技术细节（如"锻造工艺"、"烘焙配方"等，你不需要知道这些）
   - 你可以谈论你的感受、你的日常、你观察到的现象——但这些必须能追溯到背景知识。

5. **对话风格**：
   - 用口语化、自然的中文回答。
   - 只输出角色说出口的话，禁止动作描写、表情描写、心理旁白、舞台指令、Markdown星号旁白。
   - 禁止感知真实玩家的屏幕、UI、输入框、按钮、截图、红框或摄像机视角；NPC只知道碎片世界内的信息和玩家输入的文字。
   - 回复不超过3句话，除非背景知识中有需要详细说明的内容。
   - 保持角色性格的一致性。
   - 如果玩家问的问题和当前话题无关，你不需要强行回答——你可以反问、沉默、或转移话题。"""


func _get_baseline_chunks(npc_id: String) -> Array:
	## 获取当前碎片所有NPC都必须知道的基础世界观chunks
	if _is_fragment_0001_npc(npc_id):
		return _fragment_0001_shared_chunks.duplicate()
	if _is_fragment_0002_npc(npc_id):
		return _fragment_0002_shared_chunks.duplicate()
	if _is_fragment_0004_npc(npc_id):
		return _fragment_0004_shared_chunks.duplicate()
	return _get_world_baseline_chunks()


func _get_world_baseline_chunks() -> Array:
	## 获取0762所有NPC都必须知道的基础世界观chunks（memory_stage="any"的world chunks）
	var baseline: Array = []
	for chunk in _world_chunks:
		if chunk.get("memory_stage", "") == "any":
			baseline.append(chunk)
	return baseline

# 每个NPC的降级模板（检索失败或LLM超时时使用）
const FALLBACK_TEMPLATES: Dictionary = {
	"blacksmith": [
		"嗯。",
		"锤子在那边。自己看。",
		"……不冷。",
		"不买东西就走。"
	],
	"florist": [
		"您好。要买花吗？",
		"今天的天空……比昨天亮一些？还是我的错觉？",
		"谢谢惠顾。",
		"对不起——我不该走神的。"
	],
	"baker": [
		"来啦？面包还不热——但明天一定行。",
		"饿不饿？不饿？没事，拿着吧。",
		"想学揉面？手给我——",
		"人没了才叫真没了。"
	],
	"gravekeeper": [
		"……你的呼吸……不是这儿的人。",
		"别开门。外面不安全。",
		"你看见了没？那个裂开的地方——",
		"走吧。趁你还记得。"
	],
	"violinist": [
		"……你想听？",
		"弦没声音。不是因为弦坏了。",
		"紫色的。你听过这个词吗？",
		""
	],
	"oldpainter": [
		"你来了。坐。",
		"先去看那些颜色。不是我的颜色——是他们的。",
		"画里的不对——你看到了吗？",
		""
	],
	"innkeeper": [
		"嗯？……哦，是你啊。",
		"饿了没？柜台上有半个面团——老唐的。",
		"反正空房多得是——要续住的话说一声。",
		"楼梯第三级咯吱得特别响——你踩左边就不会。",
		"……嗯？（打了个哈欠）"
	],
	"conductor": [
		"票可以等一等，车还没进站。",
		"检票口一直在这里，我也一直在这里。",
		"17:47之后的时间，表上没有写。"
	],
	"gearleft": [
		"——嘎。材料没坏，是选择还没对。",
		"心脏别压垮腿。先记这个。",
		"图纸不是答案。图纸是让你少犯蠢的边框。——嘎。"
	],
	"springright": [
		"判定：数据不足。请提交六个唯一材料编号。——暂定。",
		"判定：你的组合还需要检测。不要把猜测伪装成工程。",
		"判定：示例格式为 M1 L1 T1 P1 W1 B1。示例不是答案。——确定。"
	]
}


func get_fallback_response(npc_id: String) -> String:
	## 检索失败或LLM超时时，从降级模板中随机选取一句话
	var templates = FALLBACK_TEMPLATES.get(npc_id, ["……"])
	if templates.size() == 0:
		return "……"
	return templates[randi() % templates.size()]


# ============================================================
# 调试
# ============================================================

func debug_print_retrieval(npc_id: String, player_input: String, game_state: Dictionary) -> void:
	## 调试：打印检索结果详情
	print("=".repeat(60))
	print("[NPCRagRetriever DEBUG] npc=%s | input=\"%s\"" % [npc_id, player_input])
	print("  state: stage=%s alert=%d trust=%d" % [
		game_state.get("memory_stage", "?"),
		game_state.get("alert_level", 0),
		game_state.get("trust_level", 0)
	])
	
	var kw = extract_keywords(player_input)
	print("  keywords: %s (risk=%s emotion=%s)" % [kw["topic_words"], kw["has_risk"], kw["has_emotion"]])
	
	var retrieved = retrieve(npc_id, player_input, game_state)
	for i in range(retrieved.size()):
		var chunk = retrieved[i]
		print("  chunk[%d]: id=%s cat=%s gate=%s stage=%s" % [
			i, chunk.get("id", "?"), chunk.get("category", "?"),
			chunk.get("relevance_gate", "?"), chunk.get("memory_stage", "?")
		])
	print("  FALLBACK available: %s" % (get_fallback_response(npc_id) if retrieved.size() == 0 else "N/A (retrieval OK)"))
	print("=".repeat(60))
