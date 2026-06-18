extends RefCounted
class_name Fragment0004Data

const FRAGMENT_ID := "0004"
const MAIN_SCENE := "res://scenes/fragments/fragment_0004.tscn"
const PASSAGE_SCENE := "res://scenes/rooms/id0004/passage.tscn"
const END_SCENE := "res://scenes/cinematic/fragment_0004_end.tscn"
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const PLAYER_VISUAL_SCALE := Vector2(1.4, 1.4)

const CABINET_SCENES := {
	"Cabinet_1": "res://scenes/buildings/id0004/Cabinet_1.tscn",
	"Cabinet_2": "res://scenes/buildings/id0004/Cabinet_2.tscn",
	"Cabinet_3": "res://scenes/buildings/id0004/Cabinet_3.tscn",
	"Cabinet_4": "res://scenes/buildings/id0004/Cabinet_4.tscn",
	"Cabinet_5": "res://scenes/buildings/id0004/Cabinet_5.tscn",
}

const CABINET_DISPLAY_NAMES := {
	"Cabinet_1": "材料柜1",
	"Cabinet_2": "材料柜2",
	"Cabinet_3": "材料柜3",
	"Cabinet_4": "材料柜4",
	"Cabinet_5": "材料柜5",
}

const CORRECT_COMBINATION := ["M3", "L3", "T2", "P1", "W2", "B1"]

const GEARLEFT_GUIDANCE := {
	"need_blueprints": "——嘎。任务还没开始，不是因为你慢，是因为图纸不在这儿。图纸在楼上，上楼去看看吧。",
	"partial_blueprints": "——嘎。还缺图纸。六张，六个部件，少一张就会把答案拧歪。",
	"need_materials": "——嘎。这楼里一共有十八种材料，去后面的材料柜里找找看吧。找齐再把它们拖到桌上。",
	"ready_for_judgement": "——嘎。图纸、材料都在了。去问弹簧·右，把六个编号报给它。顺序不重要，别少，也别多。",
	"solved": "——嘎。它说合格了。我第一次觉得这个词不是命令，是结果。",
}

const SPRINGRIGHT_PROMPTS := {
	"default": "请输入六个材料编号。格式示例：M1 L1 T1 P1 W1 B1。示例只演示格式，不代表正确答案。顺序不影响判定。",
	"invalid_count": "判定：不合格。输入项数量不稳定。六个部件，需要六个唯一编号。",
	"unknown": "判定：不合格。存在未登记材料编号。材料柜里只有这十八种。",
	"heart": "判定：不合格。核心太沉，或膨胀节律偏离。腿部会先学会下坠，而不是站立。",
	"head": "判定：不合格。头部的反射和重量没有同时闭合。它能看见光，但留不住方向。",
	"left_arm": "判定：不合格。左臂的摩擦或疲劳余量不足。反复拆装时，它会先松手。",
	"right_arm": "判定：不合格。右臂精度没有进入公差。差一点，也是偏差。",
	"left_leg": "判定：不合格。左腿承重或密度不合。它能撑住一瞬，但撑不住整个身体。",
	"right_leg": "判定：不合格。右腿与左腿不成对。重量差和热胀冷缩会把平衡慢慢撕开。",
	"success": "判定：合格。——确定。",
}

const PENDULUM_BROADCASTS := {
	"intro": "钟摆·心：上方有纸。后方有柜。桌上有答案的位置。",
	"blueprints_ready": "钟摆·心：六张纸已经醒了。现在去听材料的重量。",
	"first_analysis": "钟摆·心：编号不是名字。编号是骨架。",
	"repeated_wrong": "钟摆·心：先让心轻一点，再让腿站稳。",
	"solved": "钟摆·心：这一刻到了。",
}

const MATERIAL_TEXTURES := {
	"M1": "res://assets/papercraft/fragments/id0004/material/m1chitong.png",
	"M2": "res://assets/papercraft/fragments/id0004/material/m2qingtong.png",
	"M3": "res://assets/papercraft/fragments/id0004/material/m3qingtonglv.png",
	"L1": "res://assets/papercraft/fragments/id0004/material/l1baihuamu.png",
	"L2": "res://assets/papercraft/fragments/id0004/material/l2taolvfuhe.png",
	"L3": "res://assets/papercraft/fragments/id0004/material/l3jinghuazu.png",
	"T1": "res://assets/papercraft/fragments/id0004/material/t1tanhuanggang.png",
	"T2": "res://assets/papercraft/fragments/id0004/material/t2tanhuawu.png",
	"T3": "res://assets/papercraft/fragments/id0004/material/t3zugang.png",
	"P1": "res://assets/papercraft/fragments/id0004/material/p1jingmiangang.png",
	"P2": "res://assets/papercraft/fragments/id0004/material/p2taocihejin.png",
	"P3": "res://assets/papercraft/fragments/id0004/material/p3huangtong.png",
	"W1": "res://assets/papercraft/fragments/id0004/material/w1duangang.png",
	"W2": "res://assets/papercraft/fragments/id0004/material/w2taihejin.png",
	"W3": "res://assets/papercraft/fragments/id0004/material/w3yinlv.png",
	"B1": "res://assets/papercraft/fragments/id0004/material/b1jiyihejin.png",
	"B2": "res://assets/papercraft/fragments/id0004/material/b2qingcigujia.png",
	"B3": "res://assets/papercraft/fragments/id0004/material/b3heitie.png",
}

const BLUEPRINT_PAGES := {
	"Head": [
		"res://assets/papercraft/fragments/id0004/material/head1.png",
		"res://assets/papercraft/fragments/id0004/material/head2.png",
	],
	"Heart": [
		"res://assets/papercraft/fragments/id0004/material/heart1.png",
		"res://assets/papercraft/fragments/id0004/material/heart2.png",
	],
	"LeftArm": [
		"res://assets/papercraft/fragments/id0004/material/leftarm1.png",
		"res://assets/papercraft/fragments/id0004/material/leftarm2.png",
	],
	"RightArm": [
		"res://assets/papercraft/fragments/id0004/material/rightarm1.png",
		"res://assets/papercraft/fragments/id0004/material/rightarm2.png",
	],
	"LeftLeg": [
		"res://assets/papercraft/fragments/id0004/material/leftleg1.png",
		"res://assets/papercraft/fragments/id0004/material/leftleg2.png",
	],
	"RightLeg": [
		"res://assets/papercraft/fragments/id0004/material/rightleg1.png",
		"res://assets/papercraft/fragments/id0004/material/rightleg2.png",
	],
}

const MATERIAL_DATA := {
	"M1": {
		"part": "心脏",
		"family": "金属族",
		"name": "赤铜",
		"weight_kg": 1.4,
		"energy_conduction_percent": 92,
		"thermal_expansion_10e6": 14.5,
	},
	"M2": {
		"part": "心脏",
		"family": "金属族",
		"name": "青铜合金",
		"weight_kg": 1.1,
		"energy_conduction_percent": 85,
		"thermal_expansion_10e6": 17.8,
	},
	"M3": {
		"part": "心脏",
		"family": "金属族",
		"name": "轻铜铝",
		"weight_kg": 0.9,
		"energy_conduction_percent": 81,
		"thermal_expansion_10e6": 14.8,
	},
	"L1": {
		"part": "头部",
		"family": "轻质族",
		"name": "白桦木",
		"weight_kg": 0.3,
		"resonance_hz": 42,
		"reflectivity_percent": 45,
	},
	"L2": {
		"part": "头部",
		"family": "轻质族",
		"name": "陶铝复合",
		"weight_kg": 0.45,
		"resonance_hz": 55,
		"reflectivity_percent": 72,
	},
	"L3": {
		"part": "头部",
		"family": "轻质族",
		"name": "晶化竹",
		"weight_kg": 0.35,
		"resonance_hz": 61,
		"reflectivity_percent": 62,
	},
	"T1": {
		"part": "左臂",
		"family": "韧性族",
		"name": "弹簧钢",
		"toughness_mpa": 320,
		"friction_coefficient": 0.35,
		"fatigue_limit_cycles": 5000000,
	},
	"T2": {
		"part": "左臂",
		"family": "韧性族",
		"name": "碳化钨",
		"toughness_mpa": 280,
		"friction_coefficient": 0.55,
		"fatigue_limit_cycles": 10000000,
	},
	"T3": {
		"part": "左臂",
		"family": "韧性族",
		"name": "竹钢",
		"toughness_mpa": 260,
		"friction_coefficient": 0.48,
		"fatigue_limit_cycles": 800000,
	},
	"P1": {
		"part": "右臂",
		"family": "精度族",
		"name": "镜面钢",
		"machining_precision_mm": 0.003,
		"thermal_expansion_10e6": 9.5,
		"elastic_modulus_gpa": 210,
	},
	"P2": {
		"part": "右臂",
		"family": "精度族",
		"name": "陶瓷合金",
		"machining_precision_mm": 0.008,
		"thermal_expansion_10e6": 8.5,
		"elastic_modulus_gpa": 180,
	},
	"P3": {
		"part": "右臂",
		"family": "精度族",
		"name": "精密黄铜",
		"machining_precision_mm": 0.006,
		"thermal_expansion_10e6": 12.0,
		"elastic_modulus_gpa": 195,
	},
	"W1": {
		"part": "左腿",
		"family": "承重族",
		"name": "锻钢",
		"load_kg": 4.5,
		"wear_resistance": 2800,
		"density_kg_m3": 7850,
		"weight_kg": 1.2,
		"thermal_expansion_10e6": 11.5,
	},
	"W2": {
		"part": "左腿",
		"family": "承重族",
		"name": "钛合金",
		"load_kg": 4.2,
		"wear_resistance": 2200,
		"density_kg_m3": 4500,
		"weight_kg": 0.85,
		"thermal_expansion_10e6": 8.8,
	},
	"W3": {
		"part": "左腿",
		"family": "承重族",
		"name": "硬铝",
		"load_kg": 3.2,
		"wear_resistance": 1800,
		"density_kg_m3": 2800,
		"weight_kg": 0.7,
		"thermal_expansion_10e6": 6.5,
	},
	"B1": {
		"part": "右腿",
		"family": "平衡族",
		"name": "钛合金·右",
		"load_kg": 4.1,
		"weight_kg": 0.9,
		"thermal_expansion_10e6": 8.8,
	},
	"B2": {
		"part": "右腿",
		"family": "平衡族",
		"name": "硬铝·右",
		"load_kg": 3.1,
		"weight_kg": 0.7,
		"thermal_expansion_10e6": 6.5,
	},
	"B3": {
		"part": "右腿",
		"family": "平衡族",
		"name": "锻钢·右",
		"load_kg": 4.3,
		"weight_kg": 1.5,
		"thermal_expansion_10e6": 11.2,
	},
}

static func default_state() -> Dictionary:
	return {
		"collected_materials": {},
		"collected_blueprints": {},
		"completed": false,
		"assembly_solved": false,
		"forgeheart_collected": false,
		"wrong_combination_count": 0,
		"pendulum_broadcasts": {},
	}

static func material_label(material_id: String) -> String:
	var data: Dictionary = MATERIAL_DATA.get(material_id, {})
	var material_name := str(data.get("name", material_id))
	var part := str(data.get("part", ""))
	return "%s %s" % [material_id, material_name] if part.is_empty() else "%s %s / %s" % [material_id, material_name, part]

static func material_parameters_text(material_id: String) -> String:
	var data: Dictionary = MATERIAL_DATA.get(material_id, {})
	if data.is_empty():
		return "%s\n参数未登记" % material_id
	var lines: Array[String] = [
		"%s  %s" % [material_id, data.get("name", material_id)],
		"部件: %s / %s" % [data.get("part", ""), data.get("family", "")],
	]
	for key in data.keys():
		if key in ["name", "part", "family", "note"]:
			continue
		lines.append("%s: %s" % [_display_key(key), str(data[key])])
	lines.append("备注: %s" % data.get("note", ""))
	return "\n".join(lines)

static func _display_key(key: String) -> String:
	var names := {
		"weight_kg": "重量(kg)",
		"energy_conduction_percent": "能量传导(%)",
		"thermal_expansion_10e6": "热膨胀(×10⁻⁶)",
		"resonance_hz": "共振(Hz)",
		"reflectivity_percent": "反射率(%)",
		"toughness_mpa": "韧性(MPa)",
		"friction_coefficient": "摩擦系数",
		"fatigue_limit_cycles": "疲劳极限(次)",
		"machining_precision_mm": "加工精度(mm)",
		"elastic_modulus_gpa": "弹性模量(GPa)",
		"load_kg": "承重(kg)",
		"wear_resistance": "耐磨系数",
		"density_kg_m3": "密度(kg/m³)",
	}
	return str(names.get(key, key))
