extends Control
## 对话系统
## 支持两种模式：
##   1. 静态对话树（旧版，start_dialogue）
##   2. RAG动态对话（新版，start_rag_dialogue）
## 自动创建UI子节点，无需在场景中预置

signal dialogue_started(npc_name: String)
signal dialogue_ended(npc_name: String)
signal option_selected(option_index: int)

# UI 子节点（动态创建）
var panel: Panel
var name_label: Label
var text_label: RichTextLabel
var options_container: VBoxContainer
var continue_indicator: Label
var rag_mode_label: Label  # [RAG] 标签

var current_dialogue: Dictionary = {}
var dialogue_index: int = 0
var is_active: bool = false
var current_npc_name: String = ""

# RAG 模式专用
var _rag_mode: bool = false
var _npc_controller: Node = null
var _last_player_input: String = ""


func _ready() -> void:
	add_to_group("dialogue_ui")
	_setup_ui()
	hide_dialogue()


func _setup_ui() -> void:
	## 动态创建对话UI子节点
	# 背景面板
	panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.position = Vector2(40, -200)
	panel.size = Vector2(800, 180)
	panel.custom_minimum_size = Vector2(800, 180)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# NPC名称标签
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(56, -190)
	name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1, 1))
	name_label.add_theme_font_size_override("font_size", 16)
	add_child(name_label)

	# RAG 模式标签
	rag_mode_label = Label.new()
	rag_mode_label.name = "RagModeLabel"
	rag_mode_label.position = Vector2(700, -190)
	rag_mode_label.text = "[RAG]"
	rag_mode_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 0.7))
	rag_mode_label.add_theme_font_size_override("font_size", 11)
	rag_mode_label.hide()
	add_child(rag_mode_label)

	# 对话文本区域
	text_label = RichTextLabel.new()
	text_label.name = "TextLabel"
	text_label.position = Vector2(56, -160)
	text_label.size = Vector2(768, 90)
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.add_theme_font_size_override("normal_font_size", 14)
	text_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95, 1))
	add_child(text_label)

	# 选项容器
	options_container = VBoxContainer.new()
	options_container.name = "OptionsContainer"
	options_container.position = Vector2(56, -60)
	options_container.custom_minimum_size = Vector2(768, 0)
	options_container.add_theme_constant_override("separation", 4)
	add_child(options_container)

	# 继续提示
	continue_indicator = Label.new()
	continue_indicator.name = "ContinueIndicator"
	continue_indicator.position = Vector2(56, -25)
	continue_indicator.text = "按 E 继续"
	continue_indicator.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
	continue_indicator.add_theme_font_size_override("font_size", 12)
	continue_indicator.hide()
	add_child(continue_indicator)


# ============================================================
# 静态对话树模式（旧版）
# ============================================================

func start_dialogue(npc_name: String, dialogues: Array[Dictionary]) -> void:
	_rag_mode = false
	_npc_controller = null
	current_npc_name = npc_name
	current_dialogue = {"npc_name": npc_name, "lines": dialogues}
	dialogue_index = 0
	is_active = true
	rag_mode_label.hide()
	show()
	show_dialogue()
	dialogue_started.emit(npc_name)
	print("[Dialogue] 静态对话: %s (%d 条)" % [npc_name, dialogues.size()])


# ============================================================
# RAG 动态对话模式
# ============================================================

func start_rag_dialogue(npc_controller: Node) -> void:
	## 启动RAG动态对话模式
	_rag_mode = true
	_npc_controller = npc_controller
	current_npc_name = npc_controller.npc_name
	dialogue_index = 0
	is_active = true
	rag_mode_label.show()
	show()
	dialogue_started.emit(current_npc_name)
	
	# 显示NPC的第一句话（使用降级模板或从RAG生成初始问候）
	_show_npc_greeting()
	print("[Dialogue] RAG对话: %s (kb=%s)" % [current_npc_name, npc_controller.npc_kb_id])


func _show_npc_greeting() -> void:
	## 显示NPC初始问候
	panel.show()
	name_label.text = current_npc_name
	
	# 尝试从RAG获取初始问候
	if _npc_controller and _npc_controller.has_method("get_fallback_response"):
		text_label.text = _npc_controller.get_fallback_response()
	else:
		text_label.text = "……"
	
	continue_indicator.show()
	_clear_options()


func _generate_npc_response(player_input: String) -> void:
	## 通过RAG检索器生成NPC回应
	if not _npc_controller:
		text_label.text = "……"
		return
	
	# 1. 获取RAG组装的System Prompt
	var prompt = _npc_controller.get_rag_prompt(player_input)
	
	# 2. 打印拼接的完整prompt到控制台
	print("")
	print("╔" + "═".repeat(58) + "╗")
	print("║  [RAG] 组装Prompt — %s" % current_npc_name)
	print("║  输入: \"%s\"" % player_input)
	print("║  Token估算: ~%d" % prompt.length())
	print("╠" + "═".repeat(58) + "╣")
	# 分行打印prompt（每行最多80字符）
	var lines = prompt.split("\n")
	for line in lines:
		if line.length() <= 78:
			print("║ %s" % line)
		else:
			for i in range(0, line.length(), 76):
				print("║ %s" % line.substr(i, 76))
	print("╚" + "═".repeat(58) + "╝")
	print("")
	
	# 3. TODO: 将prompt发送给LLM API获取回复
	#    var llm_response = await LLMApi.chat(prompt, player_input)
	#    text_label.text = llm_response
	
	# 4. 降级：显示降级模板回复
	var fallback = _npc_controller.get_fallback_response()
	text_label.text = fallback
	print("[Dialogue] 对话触发成功 → 回复: \"%s\"" % fallback)


# ============================================================
# 通用方法
# ============================================================

func show_dialogue() -> void:
	panel.show()
	if not is_active or dialogue_index >= current_dialogue.get("lines", []).size():
		end_dialogue()
		return

	var line = current_dialogue["lines"][dialogue_index]
	name_label.text = line.get("speaker", current_npc_name)

	# 显示文本
	var full_text = line.get("text", "")
	text_label.text = full_text

	# 清除旧选项
	_clear_options()

	# 检查是否有选项
	var options = line.get("options", [])
	if options.size() > 0:
		_add_options(options)
		continue_indicator.hide()
	else:
		continue_indicator.show()


func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _add_options(options: Array) -> void:
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i].get("text", "选项 %d" % i)
		btn.custom_minimum_size = Vector2(400, 36)
		var btn_index = i
		var btn_data = options[i]
		btn.pressed.connect(func(): _on_option_selected(btn_index, btn_data))
		options_container.add_child(btn)


func _on_option_selected(index: int, option_data: Dictionary) -> void:
	option_selected.emit(index)

	# 检查选项对警觉度的影响
	if option_data.has("suspicion_delta"):
		var delta = option_data["suspicion_delta"]
		print("[Dialogue] 选项%d 对话警觉度变化: %+d" % [index, delta])

	# 检查是否有跳转
	if option_data.has("goto") and option_data["goto"] >= 0:
		dialogue_index = option_data["goto"]
	else:
		dialogue_index += 1

	show_dialogue()


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	# ESC 退出对话
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		end_dialogue()
		return

	# 继续对话
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if options_container.get_child_count() > 0:
			return  # 有选项时不自动推进

		if _rag_mode:
			# RAG模式：推进就是"玩家空输入继续"
			_generate_npc_response("")
		else:
			# 静态模式：推进到下一行
			dialogue_index += 1
			show_dialogue()


func end_dialogue() -> void:
	is_active = false
	_rag_mode = false
	_npc_controller = null
	hide_dialogue()
	dialogue_ended.emit(current_npc_name)
	print("[Dialogue] 与 %s 对话结束" % current_npc_name)


func hide_dialogue() -> void:
	panel.hide()
	rag_mode_label.hide()
	name_label.text = ""
	text_label.text = ""
	_clear_options()
	continue_indicator.hide()
	hide()


## 检查是否在RAG模式
func is_rag_mode() -> bool:
	return _rag_mode
