extends Control
## QQ风格聊天UI — autoload
## 底部半透明面板 + 消息气泡 + 输入栏 + 流式输出
## 使用 CanvasLayer 确保渲染在最上层

signal dialogue_opened(npc_name: String)
signal dialogue_closed()
signal player_message_sent(message: String)

# UI
var _canvas: CanvasLayer
var _overlay: ColorRect
var _panel: Panel
var _name_label: Label
var _chat_display: RichTextLabel
var _input_bar: Panel
var _input_box: LineEdit
var _send_btn: Button
var _give_btn: Button
var _history_btn: Button
var _think_label: Label

# 历史模式
var _history_mode: bool = false
var _history_panel: Panel
var _history_display: RichTextLabel
var _history_title: Label
var _history_prev: Button
var _history_next: Button
var _history_close: Button
var _history_page: int = 0
var _history_total_pages: int = 0
var _history_page_info: Label
const HISTORY_PAGE_SIZE: int = 30

# 状态
var is_open: bool = false
var npc_name: String = ""
var _npc: Node = null
var _base_text: String = ""
var _stream_text: String = ""
var _focus_retry_count: int = 0
var _ui_built: bool = false
const FOCUS_MAX_RETRIES: int = 8


func _ready() -> void:
	add_to_group("dialogue_ui")
	
	# 创建 CanvasLayer —— 确保 UI 始终在游戏画面上层
	_canvas = CanvasLayer.new()
	_canvas.layer = 128  # 最高层
	_canvas.name = "ChatDialogueLayer"
	add_child(_canvas)
	
	# 等下一帧视口就绪后构建
	call_deferred("_ensure_ui")
	
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process(true)


func _ensure_ui() -> void:
	if _ui_built:
		return
	_ui_built = true
	_build_ui()
	print("[ChatDialogue] UI就绪 | 视口=%dx%d" % [get_viewport_rect().size.x, get_viewport_rect().size.y])


func _build_ui() -> void:
	# 基于视口尺寸计算布局
	var vs = get_viewport_rect().size
	if vs.x <= 0 or vs.y <= 0:
		vs = Vector2(1280, 720)  # 回退默认值
		print("[ChatDialogue] 视口无效，使用默认 1280x720")
	
	# === 遮罩层（全屏，半透明黑色） ===
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.25)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.visible = false
	_canvas.add_child(_overlay)
	
	# === 对话面板（底部60%） ===
	var panel_h = int(vs.y * 0.6)
	_panel = Panel.new()
	_panel.position = Vector2(0, vs.y - panel_h)  # 从底部向上
	_panel.size = Vector2(vs.x, panel_h)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.2, 0.2, 0.22, 0.65)
	ps.set_corner_radius_all(0)
	ps.border_width_top = 1
	ps.border_color = Color(0.4, 0.4, 0.45, 0.3)
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.visible = false
	_canvas.add_child(_panel)
	
	# --- NPC名字 ---
	_name_label = Label.new()
	_name_label.position = Vector2(20, 12)
	_name_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1, 1))
	_name_label.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_name_label)
	
	# --- 思考中 ---
	_think_label = Label.new()
	_think_label.position = Vector2(vs.x - 120, 12)
	_think_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1, 0.7))
	_think_label.add_theme_font_size_override("font_size", 11)
	_panel.add_child(_think_label)
	
	# --- 聊天区 ---
	var chat_h = panel_h - 36 - 84
	_chat_display = RichTextLabel.new()
	_chat_display.position = Vector2(16, 36)
	_chat_display.size = Vector2(vs.x - 32, chat_h)
	_chat_display.bbcode_enabled = true
	_chat_display.scroll_active = true
	_chat_display.scroll_following = true
	_chat_display.selection_enabled = true
	_chat_display.add_theme_font_size_override("normal_font_size", 13)
	var cds = StyleBoxFlat.new()
	cds.bg_color = Color(0.15, 0.15, 0.17, 0.3)
	cds.set_corner_radius_all(6)
	_chat_display.add_theme_stylebox_override("normal", cds)
	_panel.add_child(_chat_display)
	
	# --- 底部输入栏 ---
	var bar_h = 84
	_input_bar = Panel.new()
	_input_bar.position = Vector2(0, panel_h - bar_h)
	_input_bar.size = Vector2(vs.x, bar_h)
	var ibs = StyleBoxFlat.new()
	ibs.bg_color = Color(0.15, 0.15, 0.17, 0.6)
	ibs.border_width_top = 1
	ibs.border_color = Color(0.25, 0.25, 0.28, 0.4)
	_input_bar.add_theme_stylebox_override("panel", ibs)
	_panel.add_child(_input_bar)
	
	# 输入框
	_input_box = LineEdit.new()
	_input_box.position = Vector2(16, 16)
	_input_box.size = Vector2(vs.x - 32 - 88, 52)
	_input_box.placeholder_text = "输入消息..."
	_input_box.add_theme_font_size_override("font_size", 14)
	var iis = StyleBoxFlat.new()
	iis.bg_color = Color(0.18, 0.18, 0.2, 0.7)
	iis.set_corner_radius_all(8)
	iis.border_width_left = 1; iis.border_width_right = 1
	iis.border_width_top = 1; iis.border_width_bottom = 1
	iis.border_color = Color(0.35, 0.35, 0.4, 0.3)
	_input_box.add_theme_stylebox_override("normal", iis)
	_input_box.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_input_box.text_submitted.connect(_do_send)
	_input_bar.add_child(_input_box)
	
	# 发送按钮
	_send_btn = Button.new()
	_send_btn.position = Vector2(vs.x - 96, 16)
	_send_btn.size = Vector2(80, 52)
	_send_btn.text = "发送"
	_send_btn.add_theme_font_size_override("font_size", 13)
	_send_btn.pressed.connect(_do_send.bind(""))
	_input_bar.add_child(_send_btn)
	
	# 给予按钮
	_give_btn = Button.new()
	_give_btn.position = Vector2(vs.x - 184, 16)
	_give_btn.size = Vector2(80, 52)
	_give_btn.text = "给予"
	_give_btn.add_theme_font_size_override("font_size", 13)
	_give_btn.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4, 1))
	_give_btn.pressed.connect(_do_give)
	_give_btn.visible = false
	_input_bar.add_child(_give_btn)
	
	# 历史按钮
	_history_btn = Button.new()
	_history_btn.position = Vector2(vs.x - 272, 16)
	_history_btn.size = Vector2(80, 52)
	_history_btn.text = "历史"
	_history_btn.add_theme_font_size_override("font_size", 13)
	_history_btn.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	_history_btn.pressed.connect(_show_history)
	_input_bar.add_child(_history_btn)
	
	# === 全屏历史面板 ===
	_build_history_panel(vs)


func _build_history_panel(vs: Vector2) -> void:
	_history_panel = Panel.new()
	_history_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_history_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var hps = StyleBoxFlat.new()
	hps.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	hps.set_corner_radius_all(0)
	_history_panel.add_theme_stylebox_override("panel", hps)
	_history_panel.visible = false
	_canvas.add_child(_history_panel)
	
	# 标题
	_history_title = Label.new()
	_history_title.position = Vector2(20, 16)
	_history_title.text = "对话历史"
	_history_title.add_theme_color_override("font_color", Color(0.5, 0.85, 1, 1))
	_history_title.add_theme_font_size_override("font_size", 18)
	_history_panel.add_child(_history_title)
	
	# 分页信息
	_history_page_info = Label.new()
	_history_page_info.position = Vector2(160, 20)
	_history_page_info.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7, 1))
	_history_page_info.add_theme_font_size_override("font_size", 12)
	_history_panel.add_child(_history_page_info)
	
	# 关闭按钮
	_history_close = Button.new()
	_history_close.position = Vector2(vs.x - 120, 14)
	_history_close.size = Vector2(100, 36)
	_history_close.text = "关闭 (Esc)"
	_history_close.add_theme_font_size_override("font_size", 12)
	_history_close.pressed.connect(_close_history)
	_history_panel.add_child(_history_close)
	
	# 历史内容区
	var content_top = 60
	var content_bottom = 60
	_history_display = RichTextLabel.new()
	_history_display.position = Vector2(20, content_top)
	_history_display.size = Vector2(vs.x - 40, vs.y - content_top - content_bottom)
	_history_display.bbcode_enabled = true
	_history_display.scroll_active = true
	_history_display.selection_enabled = true
	_history_display.add_theme_font_size_override("normal_font_size", 13)
	var hds = StyleBoxFlat.new()
	hds.bg_color = Color(0.12, 0.12, 0.14, 0.5)
	hds.set_corner_radius_all(8)
	_history_display.add_theme_stylebox_override("normal", hds)
	_history_panel.add_child(_history_display)
	
	# 翻页按钮
	var btn_w = 120
	var btn_y = vs.y - 48
	_history_prev = Button.new()
	_history_prev.position = Vector2(vs.x / 2 - btn_w - 20, btn_y)
	_history_prev.size = Vector2(btn_w, 36)
	_history_prev.text = "< 上一页"
	_history_prev.add_theme_font_size_override("font_size", 13)
	_history_prev.pressed.connect(_prev_page)
	_history_panel.add_child(_history_prev)
	
	_history_next = Button.new()
	_history_next.position = Vector2(vs.x / 2 + 20, btn_y)
	_history_next.size = Vector2(btn_w, 36)
	_history_next.text = "下一页 >"
	_history_next.add_theme_font_size_override("font_size", 13)
	_history_next.pressed.connect(_next_page)
	_history_panel.add_child(_history_next)


func _process(_delta: float) -> void:
	if not is_open or _focus_retry_count <= 0:
		return
	_focus_retry_count -= 1
	if _input_box:
		_input_box.grab_focus()
		if _input_box.has_focus():
			_focus_retry_count = 0


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _history_mode:
			_close_history()
		else:
			close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("escape"):
		if _history_mode:
			_close_history()
		else:
			close()
		get_viewport().set_input_as_handled()


func open(npc_ctrl: Node, greeting: String = "") -> void:
	if not npc_ctrl:
		return
	
	# 确保UI已构建
	call_deferred("_ensure_ui")
	
	_npc = npc_ctrl
	npc_name = npc_ctrl.npc_name
	_chat_display.text = ""
	_base_text = ""
	_stream_text = ""
	
	_name_label.text = npc_name
	_think_label.text = ""
	_input_box.text = ""
	_input_box.editable = true
	_send_btn.disabled = false
	
	_overlay.visible = true
	_panel.visible = true
	is_open = true
	
	if greeting != "":
		_add_npc_msg(greeting)
	
	_focus_retry_count = FOCUS_MAX_RETRIES
	call_deferred("_grab_input_focus")
	
	# 检查是否可给予物品
	if _npc.has_method("can_give_item"):
		var givable = _npc.can_give_item()
		if givable:
			var item = _npc.get_givable_item()
			_give_btn.text = "给予 %s" % item.get("icon", "?")
			_give_btn.visible = true
		else:
			_give_btn.visible = false
	else:
		_give_btn.visible = false
	
	dialogue_opened.emit(npc_name)
	print("[Chat] 打开: %s" % npc_name)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_focus_retry_count = 0
	_overlay.visible = false
	_panel.visible = false
	
	if _npc and _npc.has_method("end_dialogue"):
		_npc.end_dialogue()
	
	var name = npc_name
	_npc = null
	npc_name = ""
	_chat_display.text = ""
	print("[Chat] 关闭: %s" % name)
	dialogue_closed.emit()
	_close_history()


# ============================================================
# 历史对话查看
# ============================================================

func _show_history() -> void:
	if not _npc or npc_name == "":
		return
	var kb_id = _npc.npc_kb_id
	if kb_id == "":
		return
	
	_history_page = 0
	_history_mode = true
	
	_panel.visible = false
	_overlay.visible = true
	_history_panel.visible = true
	_history_title.text = "对话历史 —— %s" % npc_name
	
	_load_history_page(kb_id)


func _close_history() -> void:
	if not _history_mode:
		return
	_history_mode = false
	_history_panel.visible = false
	if is_open:
		_panel.visible = true


func _load_history_page(kb_id: String) -> void:
	var result = ChatDatabase.get_page(kb_id, _history_page, HISTORY_PAGE_SIZE)
	_history_total_pages = result["total_pages"]
	_history_page = result["page"]
	var messages: Array = result["messages"]
	var total = result["total"]
	
	_history_page_info.text = "第 %d/%d 页 (共 %d 条)" % [_history_page + 1, _history_total_pages, total]
	_history_prev.disabled = _history_page <= 0
	_history_next.disabled = _history_page >= _history_total_pages - 1
	
	if messages.is_empty():
		_history_display.text = "[center][color=#555555]暂无对话记录[/color][/center]"
		return
	
	var text: String = ""
	for msg in messages:
		var role = msg.get("role", "")
		var content = msg.get("content", "")
		var ts = msg.get("timestamp", 0)
		var time_str = _format_time(ts)
		var phase = msg.get("alert_phase", 0)
		
		if role == "player":
			text += "[right][color=#777777]%s[/color]  [color=#5599cc][ 你 ][/color] %s[/right]\n" % [time_str, content]
		else:
			var phase_tag = _alert_phase_tag(phase)
			text += "[color=#777777]%s[/color]  [color=#88aacc][%s][/color]%s %s\n" % [time_str, npc_name, phase_tag, content]
	
	_history_display.text = text


func _prev_page() -> void:
	if _history_page <= 0 or not _npc:
		return
	_history_page -= 1
	_load_history_page(_npc.npc_kb_id)


func _next_page() -> void:
	if _history_page >= _history_total_pages - 1 or not _npc:
		return
	_history_page += 1
	_load_history_page(_npc.npc_kb_id)


func _format_time(ts: int) -> String:
	var dt = Time.get_datetime_dict_from_unix_time(ts)
	return "%02d:%02d" % [dt["hour"], dt["minute"]]


func _alert_phase_tag(phase: int) -> String:
	match phase:
		1: return "[color=#cccc44](谨慎)[/color] "
		2: return "[color=#cc8822](怀疑)[/color] "
		3: return "[color=#cc4444](警觉)[/color] "
		4: return "[color=#cc2222](敌对)[/color] "
		5: return "[color=#882222](封闭)[/color] "
	return ""


func stream_begin() -> void:
	_stream_text = ""
	_base_text = _chat_display.text
	_think_label.text = "正在输入..."
	_input_box.editable = false
	_send_btn.disabled = true


func stream_add(token: String) -> void:
	_stream_text += token
	_chat_display.text = _base_text + "[color=#88aacc][%s][/color] %s" % [npc_name, _stream_text]


func stream_end(full_text: String) -> void:
	_stream_text = ""
	_chat_display.text = _base_text + "[color=#88aacc][%s][/color] %s\n" % [npc_name, full_text]
	_base_text = _chat_display.text
	_think_label.text = ""
	_input_restore()


func add_npc_msg(text: String) -> void:
	_add_npc_msg(text)
	_input_restore()


func add_player_msg(text: String) -> void:
	_chat_display.text += "[right][color=#5599cc][ 你 ][/color] %s[/right]\n" % text
	_base_text = _chat_display.text


func input_restore() -> void:
	_input_box.editable = true
	_send_btn.disabled = false
	_focus_retry_count = FOCUS_MAX_RETRIES
	call_deferred("_grab_input_focus")


func _grab_input_focus() -> void:
	if _input_box and is_open:
		_input_box.grab_focus()


func _do_send(text: String = "") -> void:
	var msg = text.strip_edges()
	if msg == "":
		msg = _input_box.text.strip_edges()
	if msg == "":
		return
	
	_input_box.text = ""
	_input_box.editable = false
	_send_btn.disabled = true
	
	_chat_display.text += "[right][color=#5599cc][ 你 ][/color] %s[/right]\n" % msg
	_base_text = _chat_display.text
	
	player_message_sent.emit(msg)
	if _npc and _npc.has_method("send_player_message"):
		_npc.send_player_message(msg)
	else:
		printerr("[Chat] NPC 无效或缺少 send_player_message 方法")
		add_npc_msg("[系统] NPC响应模块不可用")


func _do_give() -> void:
	## 玩家点击给予按钮
	if not _npc or not _npc.has_method("send_give_item"):
		return
	var item = _npc.get_givable_item()
	if item.is_empty(): return
	
	_npc.send_give_item(item["item_id"])
	_give_btn.visible = false


func _add_npc_msg(text: String) -> void:
	_chat_display.text += "[color=#88aacc][%s][/color] %s\n" % [npc_name, text]
	_base_text = _chat_display.text


func _input_restore() -> void:
	input_restore()


# ============================================================
# 警觉弹窗通知系统
# ============================================================

func show_alert_popup(amount: float, reason: String, npc_name: String, alert_phase: int, suspicion: float) -> void:
	## 在屏幕上显示警觉变化弹窗
	print("[ChatDialogue] show_alert_popup: amount=%.0f reason=%s npc=%s phase=%d sus=%.0f" % 
		  [amount, reason, npc_name, alert_phase, suspicion])
	
	# 确保库存
	if not _canvas:
		printerr("[ChatDialogue] _canvas为空，弹窗失败")
		return
	
	_ensure_ui()
	
	# 清除旧弹窗（避免叠加遮满屏幕）
	for c in _canvas.get_children():
		if c is ColorRect and c.has_meta("alert_popup"):
			c.queue_free()
	
	# 生成弹窗
	var popup = _build_alert_popup(amount, reason, npc_name, alert_phase, suspicion)
	popup.set_meta("alert_popup", true)
	_canvas.add_child(popup)
	
	# 入场动画：从右侧滑入
	var vs = get_viewport_rect().size
	if vs.x <= 0: vs = Vector2(1280, 720)
	var target_x = vs.x - 340
	
	popup.modulate.a = 0
	popup.position = Vector2(vs.x + 100, 20)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:x", target_x, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "modulate:a", 1.0, 0.25)
	
	# 退场
	tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): if is_instance_valid(popup): popup.queue_free())


func _build_alert_popup(amount: float, reason: String, npc_name: String, alert_phase: int, suspicion: float) -> Control:
	## 构建警觉弹窗——主容器为 ColorRect（确保可见性）
	var container = ColorRect.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.size = Vector2(320, 56)
	
	if amount > 0:
		if amount >= 20:
			container.color = Color(0.85, 0.12, 0.12, 0.82)
		elif amount >= 10:
			container.color = Color(0.88, 0.42, 0.08, 0.78)
		else:
			container.color = Color(0.85, 0.72, 0.08, 0.72)
	else:
		container.color = Color(0.08, 0.6, 0.2, 0.72)
	
	# 警觉条（底部）
	var bar = ColorRect.new()
	bar.position = Vector2(8, 48)
	bar.size = Vector2(304, 4)
	bar.color = Color(0, 0, 0, 0.35)
	container.add_child(bar)
	
	var fill = ColorRect.new()
	fill.position = Vector2(8, 48)
	fill.size = Vector2(304 * suspicion / 100.0, 4)
	if amount > 0:
		fill.color = Color(1, 0.5, 0.2, 0.9)
	else:
		fill.color = Color(0.3, 0.9, 0.3, 0.9)
	container.add_child(fill)
	
	# 主文本
	var phase_names = ["信任", "谨慎", "怀疑", "警觉", "敌对", "封闭"]
	var phase_name = phase_names[min(alert_phase, 5)]
	
	var text = Label.new()
	text.position = Vector2(12, 6)
	text.size = Vector2(296, 26)
	if amount > 0:
		text.text = "[警觉] [%s] %+.0f  ->  %s  (%.0f/100)" % [npc_name, amount, phase_name, suspicion]
	else:
		text.text = "[缓和] [%s] %+.0f  ->  %s  (%.0f/100)" % [npc_name, amount, phase_name, suspicion]
	text.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	text.add_theme_font_size_override("font_size", 12)
	container.add_child(text)
	
	# 原因小字
	var reason_label = Label.new()
	reason_label.position = Vector2(12, 32)
	reason_label.size = Vector2(296, 16)
	reason_label.text = reason
	reason_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	reason_label.add_theme_font_size_override("font_size", 9)
	container.add_child(reason_label)
	
	return container


func show_alert_phase_change(npc_name: String, old_phase: int, new_phase: int, reason: String) -> void:
	## 警觉阶段变化时的特殊弹窗（更大、更醒目）
	if new_phase <= old_phase:
		return  # 只显示升级
	
	_ensure_ui()
	var vs = get_viewport_rect().size
	if vs.x <= 0: vs = Vector2(1280, 720)
	
	var phase_names = ["信任", "谨慎", "怀疑", "警觉", "敌对", "封闭"]
	var phase_colors = [
		Color(0.2, 0.7, 0.3),
		Color(0.7, 0.7, 0.1),
		Color(0.9, 0.5, 0.1),
		Color(0.9, 0.2, 0.1),
		Color(0.8, 0.05, 0.1),
		Color(0.4, 0.05, 0.1),
	]
	
	var popup = Panel.new()
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var popup_w = 380
	var popup_h = 52
	popup.position = Vector2((vs.x - popup_w) / 2, vs.y * 0.15)
	popup.size = Vector2(popup_w, popup_h)
	
	var style = StyleBoxFlat.new()
	style.bg_color = phase_colors[min(new_phase, 5)]
	style.bg_color.a = 0.85
	style.set_corner_radius_all(10)
	style.border_width_left = 2; style.border_width_right = 2
	style.border_width_top = 2; style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.4)
	popup.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.position = Vector2(16, 12)
	label.size = Vector2(popup_w - 32, popup_h - 24)
	label.text = "%s 对你的态度变为：%s" % [npc_name, phase_names[min(new_phase, 5)]]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.add_theme_font_size_override("font_size", 14)
	popup.add_child(label)
	
	_canvas.add_child(popup)
	
	# 入场：缩放+弹跳
	var tween = create_tween()
	popup.modulate.a = 0
	popup.scale = Vector2(0.7, 0.7)
	tween.parallel().tween_property(popup, "scale", Vector2(1, 1), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 1.0, 0.2)
	
	# 震屏效果
	ChatDialogue.shake_screen(6.0)
	
	tween.tween_interval(2.5)
	tween.tween_property(popup, "modulate:a", 0.0, 0.6)
	tween.tween_callback(func(): if is_instance_valid(popup): popup.queue_free())


func shake_screen(intensity: float) -> void:
	## 震屏效果（模拟警觉带来的紧张感）
	if not _canvas: return
	var orig_pos = _canvas.offset
	
	var tween = create_tween()
	for i in range(6):
		tween.tween_property(_canvas, "offset", 
			orig_pos + Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 
			0.04)
	tween.tween_property(_canvas, "offset", orig_pos, 0.08)
