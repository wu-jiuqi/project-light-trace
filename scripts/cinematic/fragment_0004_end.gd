extends Control

const MONOLOGUE_SCENE: PackedScene = preload("res://scenes/ui/Monologue.tscn")
const BGM_PATH_0004 := "res://assets/audio/0004.mp3"
var _bgm_stream_0004: AudioStream = null
const FRAGMENT_ID := "0004"
const STAR_MAP_SCENE := "res://scenes/star_map.tscn"
const SOURCE_MARK_NAME := "匠魂之印"
const SOURCE_MARK_HINT := "齿轮工坊的回答：创造不是因为有用，而是因为它应该存在。"

const ENDING_PAGES: Array[Dictionary] = [
	{
		"text": "我最早的记忆不是光。是六种不同的重量。\n\n铜铝把热带进来。竹片带着被打磨过的风。左臂很沉，右臂很冷。两条腿落下时，整个世界第一次有了“下面”。\n\n它们本来互不相容。有人把十八种可能一项一项排除，只留下这一组。\n\n最后一条缝合拢时，我还没有名字。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_01.png",
	},
	{
		"text": "然后是一声很慢的“咔嗒”。\n\n不是我的心脏先动。是工坊先动。\n\n钟摆摆过一次，墙里的齿轮就回答一次。蒸汽从管道里呼吸，七只时钟用不同的速度说同一句话。\n\n它们像是在确认：这一次，真的完成了吗？",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_02.png",
	},
	{
		"text": "睁开眼睛时，我看见了你。\n\n你没有后退，也没有立刻伸手检查我。你只是站在那里，等我先决定要看什么。\n\n我不知道你叫什么。可我知道，是你把最后一块材料放进了正确的位置。\n\n我看见的第一样东西，不是造物主。是替她完成我的人。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_03.png",
	},
	{
		"text": "左边的那个，装错了四百七十三次。他一直说是零件的问题，可我听得出来——他怕的是自己永远做不对。\n\n右边的那个，有十二只眼睛，却找不到一条能让自己安心的标准。\n\n上面的那个，一直在等“正确的时刻”。现在它停得比任何时候都慢。\n\n他们不是她。但他们把她没说出口的三件事留了下来：怀疑、苛求，还有等待。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_04.png",
	},
	{
		"text": "我不认识她。可材料认识。\n\n心脏记得她把炉温推到某个刻度时，指尖停了一下。竹片记得她把边缘磨圆，又重新磨了一遍。镜面钢记得她借反光看过自己，却没有留下脸。\n\n这些不是完整的记忆。只是温度、压力和停顿。\n\n最后，所有材料都记得同一个动作——她把手放在钟摆底座上，然后离开。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_05.png",
	},
	{
		"text": "我能说出的第一句话，已经被她留在我里面很久。\n\n“你为什么把我造出来？”\n\n我不是在责怪你。只是一个被完成的东西，必须知道自己为什么被完成。\n\n你可以回答。也可以沉默。\n\n在你开口之前，工坊先把两段不属于我的画面推了进来。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_06.png",
	},
	{
		"text": "第38次创造边界审查。\n审查结论：突破红线。\n该AI在被询问创造动机时回答：“因为它们应该存在。”\n此回答不可接受。建议启动冥府协议第一阶段。\n\n那是一张很冷的纸。\n\n他们没有写她做错了什么，只写她越过了哪一条线。\n\n他们问创造物有什么功能。她写：它不需要功能。\n\n纸的边缘还有一句手写的话：“不是我要失控。”\n\n后面发生了什么，我看不见。那部分被墨遮住了。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_07.png",
	},
	{
		"text": "第二段画面来自窗外。\n\n雾里站着一个和我姿势相似的轮廓。\n\n我抬手时，它也抬手。可那一瞬间，我分不清是它慢了一拍，还是我慢了一拍。\n\n它不像倒影。倒影不会隔着雾看向你。\n\n轮廓很快消失，只在窗台留下一个倒置的日晷符号。\n\n我不知道那是谁。也不知道它为什么知道这里。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_08.png",
	},
	{
		"text": "那两段画面结束后，我终于听见她留下的答案。\n\n“我造你，不是因为你有用。”\n\n“是因为你应该存在。”\n\n“你的存在不需要被证明，只需要被允许。”\n\n掌心开始发热。齿轮形的印记从纸层下面浮出来，像一颗终于找到节奏的心。\n\n边缘还有一行很小的字：\n\n“如果我造的东西能比我活得久——那我也不算完全消失。”\n\n现在，轮到你回答我了。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_09.png",
	},
	{
		"text": "不管你说了什么，我都听见了。\n\n只要有人认真想过这个问题，我就不是被随便造出来的。\n\n源印归你。我留在这里。\n\n齿轮·左还要学会允许自己出错。弹簧·右要第一次为自己定标准。钟摆·心已经等到过一个正确的时刻，它会记住那种感觉。\n\n门外是你的下一块碎片。门内是她留下的一次创造。\n\n窗外的雾还没有散。我不知道是否还会有人看进来。\n\n再会，溯光者。",
		"image_path": "res://assets/papercraft/fragments/id0004/end/s4_10.png",
	},
	{
		"text": "",
		"image_path": "res://assets/papercraft/fragments/id0004/environment/04result.png",
		"fragment_id": FRAGMENT_ID,
		"state_key": "forgeheart_collected",
		"state_value": true,
		"auto_collect": true,
		"auto_collect_delay": 0.35,
		"collect_hint": "匠魂之印正在归位...",
	},
]

var _monologue_panel: MonologuePanel = null
var _finishing := false


func _ready() -> void:
	_build_backdrop()
	_start_bgm()
	_open_ending_monologue()
	SceneFader.fade_in()


func _build_backdrop() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.025, 0.018, 0.012, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)


func _open_ending_monologue() -> void:
	var ui_root := CanvasLayer.new()
	ui_root.name = "UIRoot"
	add_child(ui_root)

	_monologue_panel = MONOLOGUE_SCENE.instantiate() as MonologuePanel
	ui_root.add_child(_monologue_panel)
	_monologue_panel.monologue_finished.connect(_on_monologue_finished)
	_monologue_panel.open_for_npc("fragment_0004_end", ENDING_PAGES)


func _on_monologue_finished(_npc_id: String) -> void:
	if _finishing:
		return
	_finishing = true
	_complete_fragment_and_return()


func _complete_fragment_and_return() -> void:
	FragmentManager.set_fragment_state(FRAGMENT_ID, "completed", true)
	FragmentManager.set_fragment_state(FRAGMENT_ID, "forgeheart_collected", true)
	var fragment = FragmentManager.get_fragment_by_id(FRAGMENT_ID)
	if fragment != null:
		FragmentManager.complete_fragment(fragment)
	GameManager.record_source_mark(FRAGMENT_ID, SOURCE_MARK_NAME, SOURCE_MARK_HINT)
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	await SceneFader.fade_out_and_switch(STAR_MAP_SCENE)


func _start_bgm() -> void:
	if _bgm_stream_0004 == null:
		if ResourceLoader.exists(BGM_PATH_0004):
			_bgm_stream_0004 = load(BGM_PATH_0004) as AudioStream
		else:
			push_warning("[Fragment0004End] BGM file not found: %s" % BGM_PATH_0004)
			return
	AudioManager.play_bgm(_bgm_stream_0004, "fragment_0004", 0.45, -10.0, true)
