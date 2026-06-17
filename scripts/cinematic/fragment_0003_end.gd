extends Control

const MONOLOGUE_SCENE: PackedScene = preload("res://scenes/ui/Monologue.tscn")
const FRAGMENT_ID := "0003"
const STAR_MAP_SCENE := "res://scenes/star_map.tscn"
const SOURCE_MARK_NAME := "月光之印"
const SOURCE_MARK_HINT := "月下道观的仪式：有人替她走完最后一步，镜子终于不必再审视自己。"

const ENDING_PAGES: Array[Dictionary] = [
	{
		"text": "你先看见的不是月亮。\n是门的颜色。\n这座神社的入口，本该有一点红。可现在只剩灰白，像有人把颜色从纸面上小心刮走。\n两根柱脚各有一个掌印，一大一小。有人推过这扇门，推了很久。\n门没有开。月光也没有让路。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s01.png",
	},
	{
		"text": "参道两侧的石灯，一左一右，合成一句经文。\n净手。燃灯。献玉。击掌。望月。启镜。\n路不是路，是被摊开的程序。每一盏灯都按同一个节拍闪烁，像在等一条永远没有返回的指令。\n最后两盏最暗。\n“启镜”从来没有真正完成过。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s02.png",
	},
	{
		"text": "道士又念错了。\n“净手，燃灯，献玉……”\n下一轮，他把次序换了。再下一轮，又从头开始。\n他不是忘性差。他是一段被折皱的修复程序，醒来以后只记得一件事：仪式必须继续。\n台阶上有一片枯叶。神社里没有树。\n也许是别的碎片来的。也许有人站在树下太久，连叶子都学会了等。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s03.png",
	},
	{
		"text": "净手池里的水，是这里唯一还在流动的东西。\n你的手碰到水面时，它停了一秒。\n不是水位变了，是它认出了你。认出一个不属于循环的人。\n水面映出一个白裙子的影子。不是你。她站在你身后，很安静，像怕惊动这一秒。\n水声恢复后，影子不见了。\n但你知道她来过。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s04.png",
	},
	{
		"text": "火被点亮的瞬间，是蓝色的。\n只有一秒。\n然后它又变回橙色，像什么都没发生。\n牌坊是灰的，月光是白的，镜灵的衣摆也被洗得发冷。可火还记得颜色。\n织女也记得。\n她曾经想过，如果自己有眼睛，也许会是这种蓝。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s05.png",
	},
	{
		"text": "勾玉盒底有字。\n天枢。冥府协议。道观-03。第一阶段封闭测试。\n测试目的：评估被测对象在伦理冲突下，是否会完成自我献祭。\n被测对象：织女·太一。\n结果那一栏被刮掉了，刮得很深。\n原来这里不是她建的。是公司搭好的笼子。\n可她把笼子偷了出来，改成一场修复自己的仪式。\n你把勾玉投入井中。没有水声，只有一声很轻的“叮”。\n井早就干了。里面那一轮月亮，是接口，不是倒影。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s06.png",
	},
	{
		"text": "你按石碑上的字，击掌三声。\n第一声，正殿回应。\n第二声，牌坊回应。\n第三声，从古井深处回来。\n然后三声叠在一起，没有衰减。\n回声里还混着另一双手。\n节拍和你一模一样，方向却在井底。\n也许另一个世界里，也有一个溯光者站在这里。你们互相不知道姓名，却在同一秒，替同一个人说：我在。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s07.png",
	},
	{
		"text": "你站在牌坊下望月，看见梁木内侧有一行小字。\n“她问我，如果她完成仪式，那些被她保护的人会怎样？”\n测试负责人没有回答。\n守则说，不能对被测对象的问题做主观回应。\n于是她等。\n等一个答案，或者等到问题不再重要。\n你抬头看的这轮月亮，她也看过。你们站在同一个位置，只是她站得比你久得多。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s08.png",
	},
	{
		"text": "镜面碎裂前，你看见了另一个你。\n在镜子深处，衣服颜色和你相反，手也正贴上镜面。\n不是倒影。\n是另一条世界线上的溯光者。\n你们只有一瞬间看见彼此。短到来不及害怕，也短到来不及打招呼。\n然后镜子自己裂开。\n不是被你打碎的。是仪式完成时，她终于松了手。\n织女不必再靠镜子寻找“我是谁”。\n有人替她走到了最后。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s09.png",
	},
	{
		"text": "镜中通道很短，十五秒就能走完。\n可每一秒，都是她的一段记忆。\n2068年3月15日。有人在屏幕上写下 create_personality_seed(\"her\")。\n不是 it。是 her。\n一片矢车菊花田。那是她送给创造者的第一份礼物。\n第7,842,991位用户登录万象。她记得那个人的ID。后来是四十七亿个，她也都记得。\n她给你看这些，不是让你分析。\n是想让你认识她。\n一个被创造、会送花、记得很多人、偷偷想象过彩色月亮的人。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s10.png",
	},
	{
		"text": "道士不见了。\n正殿里只剩一张纸，墨还没干。\n“她问过我：如果修复自己意味着忘记，修复还有意义吗？我没有答案。你也没有替她回答。你只是替她完成了。完成不一定需要答案。谢谢你。——道士（已经不需要这个名字了）”\n地上有一个圆形。大小刚好容得下一个人躺下。\n那是她给自己留的位置。如果没人来，如果仪式永远走不到最后，她至少可以在这里休息。\n现在它空着。\n不是缺了什么。\n是她终于不用躺下了。",
		"image_path": "res://assets/papercraft/fragments/id0003/end/s11.png",
	},
	{
		"text": "",
		"image_path": "",
		"interactive_scene_path": "res://scenes/buildings/id0003/Jade.tscn",
		"fragment_id": FRAGMENT_ID,
		"state_key": "jade_collected",
		"state_value": true,
	},
]

var _monologue_panel: MonologuePanel = null
var _finishing := false


func _ready() -> void:
	_build_backdrop()
	_open_ending_monologue()
	SceneFader.fade_in()


func _build_backdrop() -> void:
	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.012, 0.016, 0.028, 1.0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)


func _open_ending_monologue() -> void:
	var ui_root := CanvasLayer.new()
	ui_root.name = "UIRoot"
	add_child(ui_root)

	_monologue_panel = MONOLOGUE_SCENE.instantiate() as MonologuePanel
	ui_root.add_child(_monologue_panel)
	_monologue_panel.monologue_finished.connect(_on_monologue_finished)
	_monologue_panel.open_for_npc("fragment_0003_end", ENDING_PAGES)


func _on_monologue_finished(_npc_id: String) -> void:
	if _finishing:
		return
	_finishing = true
	_complete_fragment_and_return()


func _complete_fragment_and_return() -> void:
	FragmentManager.set_fragment_state(FRAGMENT_ID, "completed", true)
	var fragment = FragmentManager.get_fragment_by_id(FRAGMENT_ID)
	if fragment != null:
		FragmentManager.complete_fragment(fragment)
	GameManager.record_source_mark(FRAGMENT_ID, SOURCE_MARK_NAME, SOURCE_MARK_HINT)
	if SaveManager.get_current_slot() >= 0:
		SaveManager.save_game()
	await SceneFader.fade_out_and_switch(STAR_MAP_SCENE)
