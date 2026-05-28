extends CanvasLayer
## 星图主界面
## 玩家在此选择碎片、查看解密状态、观察修复进度

@onready var bg_panel: ColorRect = $BG
@onready var fragment_container: Control = $FragmentContainer
@onready var progress_bar: ProgressBar = $UI/ProgressBar
@onready var progress_label: Label = $UI/ProgressLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var decrypt_btn: Button = $UI/DecryptBtn
@onready var enter_btn: Button = $UI/EnterBtn
@onready var title_label: Label = $UI/TitleLabel
@onready var fragment_list: ItemList = $UI/FragmentList

var selected_fragment: FragmentManager.FragmentData = null

func _ready() -> void:
	setup_star_map()
	update_fragment_list()
	_connect_signals()
	print("[StarMap] 星图界面加载完成")

func _connect_signals() -> void:
	FragmentManager.fragment_decrypted.connect(_on_fragment_decrypted)
	FragmentManager.fragment_entered.connect(_on_fragment_entered)
	GameManager.progress_updated.connect(_on_progress_updated)

func setup_star_map() -> void:
	# 在星图上散布碎片节点
	# MVP：简化为列表形式，后续版本改为3D星图
	update_fragment_list()

func update_fragment_list() -> void:
	fragment_list.clear()
	for f in FragmentManager.fragments:
		var state_text = _get_state_text(f.decrypt_state)
		var item_text = "[%s] 碎片#%s %s - %s" % [state_text, f.id, f.name, f.world_name]
		if f.is_story_critical:
			item_text += " ★"
		fragment_list.add_item(item_text)
	
	_update_ui()

func _get_state_text(state: int) -> String:
	match state:
		FragmentManager.DecryptState.LOCKED:
			return "🔒"
		FragmentManager.DecryptState.DECRYPTING:
			return "⏳"
		FragmentManager.DecryptState.PARTIAL:
			return "🔍"
		FragmentManager.DecryptState.FULL:
			return "✅"
		FragmentManager.DecryptState.COMPLETED:
			return "💎"
	return "?"

func _on_fragment_list_selected(index: int) -> void:
	if index < 0 or index >= FragmentManager.fragments.size():
		return
	
	selected_fragment = FragmentManager.fragments[index]
	_update_detail_panel()

func _update_detail_panel() -> void:
	if not selected_fragment:
		hint_label.text = "选择一个碎片查看详情..."
		decrypt_btn.disabled = true
		enter_btn.disabled = true
		return
	
	var f = selected_fragment
	title_label.text = "碎片 #%s: %s" % [f.id, f.name]
	
	match f.decrypt_state:
		FragmentManager.DecryptState.LOCKED:
			hint_label.text = "🔒 碎片加密中 - 表面流动着乱码...\n点击「提交解密」请求天枢公司科研团队解密"
			decrypt_btn.disabled = false
			enter_btn.disabled = true
		FragmentManager.DecryptState.DECRYPTING:
			var pct = int(f.decrypt_progress * 100)
			hint_label.text = "⏳ 解密中... (%d%%)\n预计剩余时间: %s" % [pct, _format_time_remaining(f)]
			decrypt_btn.disabled = true
			enter_btn.disabled = true
		FragmentManager.DecryptState.PARTIAL:
			hint_label.text = "🔍 半解密提示:\n「%s」\n\n提示不完整，需要自己推理..." % f.hint_visible
			decrypt_btn.disabled = true
			enter_btn.disabled = false
		FragmentManager.DecryptState.FULL:
			hint_label.text = "✅ 解密完成!\n提示: 「%s」\n难度: %d/5  世界: %s" % [f.hint_full, f.difficulty, f.world_name]
			decrypt_btn.disabled = true
			enter_btn.disabled = false
		FragmentManager.DecryptState.COMPLETED:
			hint_label.text = "💎 透明碎片 - 已修复（可重游）\n源印: %s\n\n再次进入可重玩，但不再增加修复进度" % f.source_mark_name
			decrypt_btn.disabled = true
			enter_btn.disabled = false
	
	if f.is_story_critical:
		hint_label.text += "\n\n⚠ 此碎片承载关键剧情信息"

func _format_time_remaining(f: FragmentManager.FragmentData) -> String:
	var remaining = f.decrypt_duration - (Time.get_unix_time_from_system() - f.decrypt_start_time)
	if remaining <= 0:
		return "即将完成..."
	remaining = maxi(0, remaining)
	var mins = remaining / 60
	var secs = remaining % 60
	return "%d分%d秒" % [mins, secs]

func _on_decrypt_btn_pressed() -> void:
	if selected_fragment and selected_fragment.decrypt_state == FragmentManager.DecryptState.LOCKED:
		FragmentManager.start_decrypt(selected_fragment)
		_update_detail_panel()
		SaveManager.save_game()

func _on_enter_btn_pressed() -> void:
	if selected_fragment and selected_fragment.decrypt_state in [
		FragmentManager.DecryptState.PARTIAL, FragmentManager.DecryptState.FULL,
		FragmentManager.DecryptState.COMPLETED
	]:
		FragmentManager.enter_fragment(selected_fragment)
		# 场景切换由 scene manager 处理
		if selected_fragment.scene_path and ResourceLoader.exists(selected_fragment.scene_path):
			get_tree().change_scene_to_file(selected_fragment.scene_path)
		else:
			# 跳转到通用碎片世界
			get_tree().change_scene_to_file("res://scenes/fragments/fragment_world.tscn")

func _on_fragment_decrypted(_fragment_id: String) -> void:
	update_fragment_list()
	_update_detail_panel()
	SaveManager.save_game()

func _on_fragment_entered(_fragment_id: String) -> void:
	pass

func _on_progress_updated(progress: float) -> void:
	progress_bar.value = progress * 100
	progress_label.text = "万象修复进度: %d%%" % int(progress * 100)

func _update_ui() -> void:
	progress_bar.value = GameManager.repair_progress * 100
	progress_label.text = "万象修复进度: %d%%" % int(GameManager.repair_progress * 100)

func _process(_delta: float) -> void:
	# 定时检查解密进度
	for f in FragmentManager.fragments:
		if f.decrypt_state == FragmentManager.DecryptState.DECRYPTING:
			FragmentManager.check_decrypt_progress(f)
			if f.decrypt_state != FragmentManager.DecryptState.DECRYPTING:
				update_fragment_list()
				if selected_fragment and selected_fragment.id == f.id:
					_update_detail_panel()
