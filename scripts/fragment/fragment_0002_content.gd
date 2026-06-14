extends RefCounted
class_name Fragment0002Content

const NPC_IDS: Array[String] = [
	"oldteacher",
	"youngsoldier",
	"flowergirl",
	"merchant",
	"littlegirl",
]

const NPC_DISPLAY_NAMES: Dictionary = {
	"oldteacher": "老教师",
	"youngsoldier": "年轻士兵",
	"flowergirl": "卖花女",
	"merchant": "商人",
	"littlegirl": "小女孩",
	"conductor": "检票员",
	"player": "源印",
}


# 独白资源接口：
# 每页可填 text / image_path。
# 如需预置交互背景，额外填 interactive_scene_path / state_key / state_value。
const MONOLOGUE_PAGES: Dictionary = {
	"oldteacher": [
		{
			"text": "（长时间沉默。她的手指在书页上轻轻划过。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_01.png",
		},
		{
			"text": "我教了一辈子语文。\n教学生读'离别'，也教他们写'月台'。\n朱自清写父亲翻过月台买橘子。\n那一课讲的是送别：\n看着一个人走远，心里有话，\n却喊不出来。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_02.png",
		},
		{
			"text": "可课本从来没教过一个字：\n'等'。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_03.png",
		},
		{
			"text": "离别有方向。\n有人走，有人送。\n等不一样。\n等的人站在原地，\n走的人去了哪里，你不知道。\n所以你只能等。\n等着，就像自己还在做一件事。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_04.png",
		},
		{
			"text": "（她翻了一页。空白的。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_05.png",
		},
		{
			"text": "这本书，每一页我都读过。\n第一页是'他五岁'。\n第二页是'他第一次自己坐火车'。\n第三页写着：妈，明年回来。\n第四页还是那两个字：明年。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_06.png",
		},
		{
			"text": "读到后来，\n我把字都擦掉了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_07.png",
		},
		{
			"text": "不是不记得。\n只是写在纸上太重。\n放在这里，\n（她把手放到心口）\n就刚刚好。\n不重，也不轻。\n还能带着我往前走。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_08.png",
		},
		{
			"text": "（她把书抱在怀里。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_09.png",
		},
		{
			"text": "在这个车站，分钟不是分钟。\n你看那个钟，17:47。\n它不是坏了。\n只是走不走，\n对这里来说都一样。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_10.png",
		},
		{
			"text": "（她把书放在长椅上，放在你和她中间。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_11.png",
		},
		{
			"text": "如果有一天你要离开，别回头。\n等车的人最怕看见别人回头。\n那会让车显得更远。\n这本书你可以拿走。\n别用眼睛看，用回忆看。\n想一想，\n你曾经等过谁。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_12.png",
		},
		{
			"text": "（她闭上眼睛。手指停在书封上，没有再翻页。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_1/c1_13.png",
		},
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/book.tscn",
			"state_key": "book_collected",
			"state_value": true,
		},
	],
	"youngsoldier": [
		{
			"text": "（他从行军袋里拿出那个空弹夹。\n金属碰到布料，轻轻响了一声。\n他把它放在膝盖上，\n拇指自然搭在卡口处。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_01.png",
		},
		{
			"text": "报告。\n我是说，你知道弹夹空了是什么感觉吗？\n不是轻。\n空弹夹比满弹夹更重。\n满的时候你知道里面有什么。\n空了以后，\n要填进去的东西就全靠自己。\n可我填不进去。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_02.png",
		},
		{
			"text": "六年前，我上了火车。\n边境的风里有沙子味。\n那时我还不知道那叫边境，\n以为全世界的风都是这样。\n到了部队，班长说：\n'记住这个味道。\n这是家。'",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_03.png",
		},
		{
			"text": "现在这里没有沙子味。\n站台太干净了。\n干净得不像给人呼吸，\n倒像是要人忘记自己是谁。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_04.png",
		},
		{
			"text": "（他把弹夹放在长椅上，在你和他之间。\n手指还悬在弹夹上方，没有完全离开。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_05.png",
		},
		{
			"text": "0530。闹钟每天都响。\n可闹钟不是号声。\n号声有重量。\n它从操场的墙上弹回来，\n像是在告诉你：\n你在这里，你有位置。\n你有一个班。\n闹钟只是声音，按掉以后就没了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_06.png",
		},
		{
			"text": "（远方汽笛响了一声。\n他抬头看向铁轨，又低头看自己的手。\n手指还并拢着，像立正时那样。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_07.png",
		},
		{
			"text": "我守了六年边境。\n六年，都在同一个哨位上。\n门牌写着'C-11安全通道'。\n那扇门一次也没开过。\n直到最后一班岗，\n它开了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_08.png",
		},
		{
			"text": "我不需要知道门里面是什么。\n我只需要有一扇门，\n有一个哨位，\n有个地方等我回去。\n明天早上六点之前，不能迟到。\n（他把弹夹推到你面前。）\n你拿着。\n帮我拿着。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_09.png",
		},
		{
			"text": "如果有一天你到了第七边防连，\n把它放在哨位旁边就好。\n不用敬礼。\n我已经不在那个哨位上了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_10.png",
		},
		{
			"text": "也许以后会有人站在那里。\n他闻到风里的沙子味，\n就会知道：\n有人在这里站过六年。\n六年里什么都没发生。\n但站过了，就是站过了。\n（他把手放回膝盖，掌心朝下。\n弹夹留在你们中间。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_2/c2_11.png",
		},
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/box.tscn",
			"state_key": "box_collected",
			"state_value": true,
		},
	],
	"flowergirl": [
		{
			"text": "（她蹲在篮子旁，把花一朵朵拿出来，\n又重新排好。\n不像整理，\n更像在找什么。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_01.png",
		},
		{
			"text": "矢车菊，蓝色最正。\n别的颜色我不卖。\n也不是不想卖，\n是没这个品种好。\n（她把一朵花翻过来，看花瓣背面。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_02.png",
		},
		{
			"text": "其实不是不卖，是不会种。\n我只会种矢车菊。\n种了很多年。\n从一个站走到另一个站，\n篮子里一直是同一种花。\n也试过别的。\n可加了别的，花就不开。\n像在提醒我：你不是种那个的人。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_03.png",
		},
		{
			"text": "（她找到了篮子最底下那朵。\n花瓣被压得有点变形，\n蓝色却比上面的花都深。）\n你看，它叶子歪了，花瓣卷了。\n可蓝得最深。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_04.png",
		},
		{
			"text": "你知道为什么吗？\n花和人不一样。\n人被压久了，颜色会淡。\n花被压久了，颜色反而更深。\n因为它不逃。\n它把力气都用在'蓝'上，\n不拿去挣扎。\n（她用拇指轻轻抚平卷边。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_05.png",
		},
		{
			"text": "我一直走。\n下一站叫什么，早就不记得了。\n反正还有下一站。\n不是我闲不住，\n是不能停。\n花要跟着人走，才像在路上。\n人一停，花就只是篮子里的花。\n那和花盆有什么区别呢。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_06.png",
		},
		{
			"text": "（她把那朵最深的花举到眼前，对着光看。）\n这朵有一个缺。\n你看，花瓣上空了一点。\n不是坏了，\n只是光从那里穿过去，\n颜色就漏掉了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_07.png",
		},
		{
			"text": "我也有一个缺。\n不是坏了，是空着。\n我的缺，是不知道要去哪。\n花不纠结。\n它有缺，也照样开。\n蓝还是蓝，缺还是缺。\n两件事可以同时是真的。\n花比我聪明。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_08.png",
		},
		{
			"text": "我一直走，\n不是因为下一站花好卖。\n是我怕这一站没有风。\n你注意到了吗？这个车站没有风。\n花明明靠风授粉，\n可它们还是开了。\n不靠风，也不靠时间。\n花能做到的事，我还不敢。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_09.png",
		},
		{
			"text": "（她把花放在你们中间的地面上，花柄朝你。）\n这一朵，你拿走吧。\n如果有一天到了你的下一站，\n看见有人卖矢车菊，\n就把花还给她。\n告诉她：'你没来，花替你来了。'\n别担心我。\n花等的不是人，是风。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_10.png",
		},
		{
			"text": "（她站起来，把手搭在空花篮的提手上。）\n篮子轻一点也好。\n轻了，走起来快。\n快一点，\n说不定下一站风就来了。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_11.png",
		},
		{
			"text": "哪怕没有下一站，\n我也知道。\n可花不知道。\n花以为我只是站累了，蹲一会儿。\n所以别告诉花。\n（她没有笑。\n但她的眼睛比刚才亮了一点。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_3/c3_12.png",
		},
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/flower.tscn",
			"state_key": "flower_collected",
			"state_value": true,
		},
	],
	"merchant": [
		{
			"text": "（他从公文包里抽出一张合同。\n举到眼前，像是在读。\n两秒后翻到下一张，\n又翻回来。\n他找不到刚才读的是哪一张，\n因为每张都一样。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_01.png",
		},
		{
			"text": "不妨告诉你，我做生意二十年了。\n二十年能签多少合同？\n不记得了。\n不是记性差，\n是太多。\n太多的东西，最后都长得一样。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_02.png",
		},
		{
			"text": "（他短促地笑了一声。\n笑到第三下卡住了，\n像机器咬住了不该咬的东西。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_03.png",
		},
		{
			"text": "刚才那位老太太，你注意到她的书没有？\n布封皮，自己包的。\n自己包书皮，说明那本书很重要。\n哪怕是空白的，也重要。\n我的合同没有书皮。\n（他低头看手里的白纸。\n纸很白，白得刺眼。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_04.png",
		},
		{
			"text": "时间就是金钱。\n金钱就是……\n（他看表。表停在17:47。\n他知道表坏了，还是看了一眼。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_05.png",
		},
		{
			"text": "哈哈，不谈利润。\n谈钱伤感情。\n跟您透露一下，这个季度流水……嗯。\n（他的语速越来越快，\n却在'流水'两个字后断住。）\n流水，流水。\n（他停下。招牌笑声填不住那道裂缝。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_06.png",
		},
		{
			"text": "那个检票员从来没查过我的票。\n不是忘了，是没必要。\n我的票是3B，备用。\n备用的意思是有人没来。\n也可能从来就没有那个人。\n从来没有那个客户。\n那个……",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_07.png",
		},
		{
			"text": "（他的手在公文包里翻找。\n不是找合同，\n是在找一个并不存在的东西。\n他越翻越快，然后停住。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_08.png",
		},
		{
			"text": "不妨告诉你，这趟车，\n我不确定自己该不该上。\n不是怕上错，\n是怕上去以后车厢是空的。\n车对，票对，\n可没有客户，没有合同，\n没有我要签的东西。\n那我就不能再假装自己是在出差。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_09.png",
		},
		{
			"text": "（他把公文包合上。\n这个动作比打开更费劲。\n金属扣压下去时，\n他的手在抖。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_10.png",
		},
		{
			"text": "你知道最怕的是什么吗？\n不是合同是空的。\n空合同我可以一直装作有字。\n最怕的是有一天，\n我坐在3B，旁边也是空的。\n没有人需要我签字，\n没有人欠我尾款。\n那时我就必须承认……",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_11.png",
		},
		{
			"text": "（他把公文包放在长椅上，放在你和他中间。\n不是护着，\n是终于放下。）\n我不是商人。\n二十年了。\n从来不是。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_12.png",
		},
		{
			"text": "（他没有看表。\n远方汽笛响了一声，\n他也没有抬头。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_13.png",
		},
		{
			"text": "这张3B的票，也许是我自己买的。\n我给自己买了一张票，\n又编了一个客户，\n编了一个签合同的故事，\n一编就是二十年。\n可如果故事是我编的，\n（他第一次直视你，像一个人在问。）\n那二十年前，我是谁？",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_14.png",
		},
		{
			"text": "（他转回头，看着铁轨方向。\n公文包还在长椅上，他没有拿回来。）\n反正车还没来。\n等车的时候，不怕说实话。\n车一来，我就又要变成商人。\n……不了，今天不了。\n今天就在这里坐一会儿。\n不用装，也不用看表。\n17:47，挺好的。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_4/c4_15.png",
		},
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/briefcase.tscn",
			"state_key": "briefcase_collected",
			"state_value": true,
		},
	],
	"littlegirl": [
		{
			"text": "（她站在黄线后面，脚尖踮起，放下，又踮起。\n有一根鞋带散着，\n她没有系。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_01.png",
		},
		{
			"text": "你来啦。\n我就知道你会来。\n不是脑子里的那种知道。\n是踮起脚尖时，\n这里会先知道。\n（她按了按心口。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_02.png",
		},
		{
			"text": "（她蹲下来，从背包里掏出半截粉笔，\n在地上画了一道歪线。）\n你看，铁轨不是直的。\n蹲下来看的时候，它会歪。\n站着有站着的铁轨，\n蹲着有蹲着的铁轨。\n光也是这样。\n蹲下来看的光，像在说话。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_03.png",
		},
		{
			"text": "（她用脚在枕木上踩了几下：滴，滴，滴答滴答。）\n它在问：'你是谁？'\n问了好多遍。\n从我来这里，它就一直问。\n也许它记性不好，\n也许它只是想再听一次。\n可我还没想好怎么回答。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_04.png",
		},
		{
			"text": "（她把粉笔放回背包，又掏出那颗糖。\n糖纸是红、蓝、黄，整个车站都没有这种颜色。）\n妈妈在下一个站台。\n她说去买点东西，很快回来。\n可'很快'是多久呢？\n太阳不知道，铁轨不知道，光也不知道。\n我只知道糖还没化。\n糖没化，就还没过很快。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_05.png",
		},
		{
			"text": "我有时候会想，妈妈会不会也是光。\n想出来的时候就闪，\n不想出来的时候就不闪。\n如果妈妈是光，\n她会不会也有不想闪的时候？\n不对。\n我不问了。\n这个问题到这里就停。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_06.png",
		},
		{
			"text": "（她把糖攥紧，放在心口。\n脚尖的节奏刚好和它重在一起。）\n不问了，因为糖还在。\n糖还在，妈妈就在来的路上。\n路长一点，糖就甜一点。\n这是补偿。\n也许是我想到的，\n也许是光悄悄告诉我的。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_07.png",
		},
		{
			"text": "（她把糖放回背包，拿起地上的纸飞机。\n那其实是被折起来的车票。）\n票太大，手太小，\n握着不舒服。\n折一下就刚刚好。\n像妈妈的手，\n不大，正好能握住我。\n还有橙子味。你闻……",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_08.png",
		},
		{
			"text": "（她把纸飞机递近，又收回去。）\n不对，你闻不到了。\n味道不在，不是妈妈不在。\n是橙子不在。\n橙子会淡，\n妈妈不会。\n等一下，我刚才说了'不会'。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_09.png",
		},
		{
			"text": "（她沉默，然后踮起脚尖。\n这一次久到小腿微微发抖，才放下。）\n光又在问：'你是谁？'\n（她转过身，面对你。）\n你说我叫'追光的人'。\n这个名字，光一定听得懂。\n下次它问，我就这样回答。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_10.png",
		},
		{
			"text": "（她展开纸飞机。\n车票背面画着大人牵小孩，\n大人没有脸。）\n其实光问了三遍。\n第一遍问你是谁，\n第二遍问你还在吗，\n第三遍问你在等谁。\n我在等妈妈。\n妈妈的脸我画不下来，因为它一直在变。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_11.png",
		},
		{
			"text": "（她站起来，最后一次踮脚尖。\n又从背包里捧出那颗糖。）\n糖给你。\n妈妈说上车了再吃。\n可我不上车了。\n我要是走了，光就没人看了。\n你替我吃。\n甜不甜，我就知道。\n糖纸留着，别让颜色褪掉。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_12.png",
		},
		{
			"text": "（她捡起半截粉笔，塞到你手里。）\n如果路上有人问'你是谁'，\n不是用嘴问，\n是用光问，\n你就用这个回答。\n点点短，杠杠长，\n可都算回答。\n回答不一定要对。\n回答本身就是：'我在'。",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_13.png",
		},
		{
			"text": "（她转过身，面朝铁轨尽头，背对着你。\n双马尾在夕阳下垂着。\n她抬起脚后跟，稳稳停住。\n这一次，\n她没有再放下来。）",
			"image_path": "res://assets/papercraft/fragments/id0002/monologue/npc_5/c5_14.png",
		},
		{
			"text": "",
			"image_path": "",
			"interactive_scene_path": "res://scenes/buildings/id0002/candy.tscn",
			"state_key": "candy_collected",
			"state_value": true,
		},
	],
}

const CONDUCTOR_OPENING := "你来了, 车也就要来了......我知道你不是这里的人, 但我想你也许也在等, 去检票口里看看吧, 四个座位五个人, 由你决定谁留下, 想好了就告诉我'我想好了', 我会给你座位表"
const CONDUCTOR_ASK_REASON := "为什么这样选"
const CONDUCTOR_REVEAL := "你知道为什么车一直不来吗？因为开车的人——她在犹豫。她不想撞到轨道上的任何一个人。但轨道上站满了人。唯一的方法是不开车。可不开车——所有人都会死在轨道上。她选了第三条路——把这辆车粉碎，让碎片轻到不会压死人。但车就是她自己。车碎了之后, 车上的人还能在碎片里活着——她也还在，却不是原来那个她了。"
const CONDUCTOR_FINAL := "走吧。车还在等你——只是你等的不是它。你等的——在下一站。"

const SOURCE_MARK_NAME := "归途之印"
const SOURCE_MARK_HINT := "黄昏驿站的车票：四个座位五个人，留下的人也被记住了。"
