# 关卡信息数据
class_name 关卡数据 extends Node

const guan_qia = [
	{"id":"1","x":9,"y":8,"guai_wu":["紫蠃"],"guai_wu_n":[9],"zhang_ai_n":0},
	{"id":"2","x":9,"y":9,"guai_wu":["紫蠃"],"guai_wu_n":[10],"zhang_ai_n":1},
	{"id":"3","x":10,"y":9,"guai_wu":["邪嘴唇花"],"guai_wu_n":[11],"zhang_ai_n":1},
	{"id":"4","x":10,"y":10,"guai_wu":["紫蠃贤者"],"guai_wu_n":[13],"zhang_ai_n":2},
	{"id":"5","x":11,"y":10,"guai_wu":["红巨蟹"],"guai_wu_n":[14],"zhang_ai_n":2},
	{"id":"6","x":11,"y":11,"guai_wu":["褐巨蟹"],"guai_wu_n":[16],"zhang_ai_n":3},
	{"id":"7","x":12,"y":11,"guai_wu":["橙食人花"],"guai_wu_n":[18],"zhang_ai_n":3},
	{"id":"8","x":12,"y":12,"guai_wu":["紫食人花"],"guai_wu_n":[20],"zhang_ai_n":4},
	{"id":"9","x":13,"y":12,"guai_wu":["青巨蟹"],"guai_wu_n":[22],"zhang_ai_n":4},
	{"id":"10","x":13,"y":13,"guai_wu":["紫巨蟹"],"guai_wu_n":[24],"zhang_ai_n":5},
	{"id":"11","x":14,"y":13,"guai_wu":["蓝巨蟹"],"guai_wu_n":[26],"zhang_ai_n":5},
	{"id":"12","x":14,"y":14,"guai_wu":["蓝蠃勇者"],"guai_wu_n":[29],"zhang_ai_n":6},
	{"id":"13","x":15,"y":14,"guai_wu":["紫蠃贤者","白鬣野猪"],"guai_wu_n":[10,21],"zhang_ai_n":6},
	{
		"id":"14","x":15,"y":15,"guai_wu":["紫蠃","红巨蟹","白鬣赤猪"],
		"guai_wu_n":[1,12,21],"zhang_ai_n":7
	},
	{"id":"15","x":16,"y":15,"guai_wu":["邪嘴唇花","紫蠃勇者"],"guai_wu_n":[8,29],"zhang_ai_n":7},
	{
		"id":"16","x":16,"y":16,"guai_wu":["紫蠃","褐巨蟹","茶鬣野猪"],
		"guai_wu_n":[10,10,20],"zhang_ai_n":8
	},
	{
		"id":"17","x":17,"y":16,"guai_wu":["紫蠃","紫蠃贤者","蓝蠃勇者","褐蠃长老"],
		"guai_wu_n":[7,5,3,28],"zhang_ai_n":8
	},
	{"id":"18","x":18,"y":16,"guai_wu":["紫蠃","绿鬣野猪"],"guai_wu_n":[28,19],"zhang_ai_n":9},
	{"id":"19","x":19,"y":16,"guai_wu":["紫蠃贤者","黄斑野猪"],"guai_wu_n":[32,19],"zhang_ai_n":9},
	{"id":"20","x":20,"y":16,"guai_wu":["紫蠃","黯灰狼"],"guai_wu_n":[49,6],"zhang_ai_n":10},
	{"id":"21","x":21,"y":16,"guai_wu":["紫蠃","靛苍狼"],"guai_wu_n":[54,5],"zhang_ai_n":10},
	{"id":"22","x":22,"y":16,"guai_wu":["紫蠃贤者","粉褐狼"],"guai_wu_n":[58,5],"zhang_ai_n":11},
	{
		"id":"23","x":23,"y":16,"guai_wu":["邪嘴唇花","橙食人花","紫食人花","冰河狼"],
		"guai_wu_n":[50,8,5,4],"zhang_ai_n":12
	},
	{
		"id":"24","x":24,"y":16,"guai_wu":["邪嘴唇花","橙食人花","紫食人花"],
		"guai_wu_n":[41,15,15],"zhang_ai_n":12,"BOSS":["邪花王·荆冠"],"BOSS_n":[1]
	},
	{
		"id":"25","x":25,"y":16,"guai_wu":["邪嘴唇花","橙食人花","紫食人花"],
		"guai_wu_n":[43,16,16],"zhang_ai_n":13,"BOSS":["葵花王·槐昂"],"BOSS_n":[1]
	},
	{
		"id":"26","x":26,"y":16,"guai_wu":["白鬣野猪","白鬣赤猪","茶鬣野猪","绿鬣野猪","黄斑野猪"],
		"guai_wu_n":[17,17,16,15,15],"zhang_ai_n":14,"BOSS":["野猪王·冕笑"],"BOSS_n":[1]
	},
	{
		"id":"27","x":27,"y":16,
		"guai_wu":["紫蠃","紫蠃贤者","蓝蠃勇者","紫蠃勇者","褐蠃长老"],
		"guai_wu_n":[38,26,7,7,6],"zhang_ai_n":15,"BOSS":["蠃虫王·犄眦"],"BOSS_n":[1]
	},
	{
		"id":"28","x":28,"y":16,"guai_wu":["黯灰狼","靛苍狼","粉褐狼","冰河狼"],
		"guai_wu_n":[24,23,21,21],"zhang_ai_n":16,"BOSS":["双狼王·睚狈"],"BOSS_n":[1]
	},
	{	"id":"29","x":29,"y":16,"guai_wu":["红巨蟹","褐巨蟹","青巨蟹","紫巨蟹","蓝巨蟹","猛犸"],
		"guai_wu_n":[29,27,16,14,7,1],"zhang_ai_n":18
	},
	{
	"id":"30","x":30,"y":16,"guai_wu":["红巨蟹","褐巨蟹","青巨蟹","紫巨蟹","蓝巨蟹","猛犸"],
	"guai_wu_n":[25,24,17,16,15,2],"zhang_ai_n":13,
	"BOSS":["邪花王·荆冠","葵花王·槐昂","野猪王·冕笑","蠃虫王·犄眦","双狼王·睚狈","猛犸王·犽翡"],
	"BOSS_n":[1,1,1,1,1,1]
	}
]

# 怪物名称到场景路径的映射
const guai_wu_tscn = {
	"红巨蟹": "res://角色/怪物/11红巨蟹/红巨蟹.tscn",
	"褐巨蟹": "res://角色/怪物/12褐巨蟹/褐巨蟹.tscn",
	"青巨蟹": "res://角色/怪物/13青巨蟹/青巨蟹.tscn",
	"紫巨蟹": "res://角色/怪物/14紫巨蟹/紫巨蟹.tscn",
	"蓝巨蟹": "res://角色/怪物/15蓝巨蟹/蓝巨蟹.tscn",
	"邪嘴唇花": "res://角色/怪物/21邪嘴唇花/邪嘴唇花.tscn",
	"橙食人花": "res://角色/怪物/22橙食人花/橙食人花.tscn",
	"紫食人花": "res://角色/怪物/23紫食人花/紫食人花.tscn",
	"邪花王·荆冠": "res://角色/怪物/24邪花王·荆冠/邪花王.tscn",
	"葵花王·槐昂": "res://角色/怪物/25葵花王·槐昂/葵花王.tscn",
	"白鬣野猪": "res://角色/怪物/31白鬣野猪/白鬣野猪.tscn",
	"白鬣赤猪": "res://角色/怪物/32白鬣赤猪/白鬣赤猪.tscn",
	"茶鬣野猪": "res://角色/怪物/33茶鬣野猪/茶鬣野猪.tscn",
	"绿鬣野猪": "res://角色/怪物/34绿鬣野猪/绿鬣野猪.tscn",
	"黄斑野猪": "res://角色/怪物/35黄斑野猪/黄斑野猪.tscn",
	"野猪王·冕笑": "res://角色/怪物/36野猪王·冕笑/野猪王.tscn",
	"紫蠃": "res://角色/怪物/41紫蠃/紫蠃.tscn",
	"紫蠃贤者": "res://角色/怪物/42紫蠃贤者/紫蠃贤者.tscn",
	"蓝蠃勇者": "res://角色/怪物/43蓝蠃勇者/蓝蠃勇者.tscn",
	"紫蠃勇者": "res://角色/怪物/44紫蠃勇者/紫蠃勇者.tscn",
	"褐蠃长老": "res://角色/怪物/45褐蠃长老/褐蠃长老.tscn",
	"蠃虫王·犄眦": "res://角色/怪物/46蠃虫王·犄眦/蠃虫王.tscn",
	"黯灰狼": "res://角色/怪物/51黯灰狼/黯灰狼.tscn",
	"靛苍狼": "res://角色/怪物/52靛苍狼/靛苍狼.tscn",
	"粉褐狼": "res://角色/怪物/53粉褐狼/粉褐狼.tscn",
	"冰河狼": "res://角色/怪物/54冰河狼/冰河狼.tscn",
	"双狼王·睚狈": "res://角色/怪物/55双狼王·睚狈/双狼王.tscn",
	"猛犸": "res://角色/怪物/61猛犸/猛犸.tscn",
	"猛犸王·犽翡": "res://角色/怪物/62猛犸王·犽翡/猛犸王.tscn",
}

const npc_tscn = {
	"花精灵·沙华": "res://角色/NPC/3花精灵·沙华/沙华.tscn",
}

static func guan_kia(guan_kia_id: int) -> Dictionary:
	if guan_kia_id >= 0 and guan_kia_id < guan_qia.size():
		return guan_qia[guan_kia_id]
	return {}

static func guan_kia_n() -> int:
	return guan_qia.size()

# 根据怪物名称获取场景路径
static func get_tscn(ming_cheng: String) -> String:
	return guai_wu_tscn.get(ming_cheng, "res://角色/怪物/11红巨蟹/红巨蟹.tscn")

static func get_npc_tscn(ming_cheng: String) -> String:
	return npc_tscn.get(ming_cheng, "")

# 加载地图资源图片，返回字典包含所有纹理
static func load_zi_yuan(guan_kia_id: int = 0) -> Dictionary:
	var zi_yuan = {}
	# 判断使用草地还是紫地资源
	var di_xing = "草地" if guan_kia_id < 23 else "紫地"
	zi_yuan["tile_fan_kai"] = load("res://关卡/" + di_xing + "/0.png")
	zi_yuan["tile_shu_zi"] = [
		load("res://关卡/" + di_xing + "/1.png"),
		load("res://关卡/" + di_xing + "/2.png"),
		load("res://关卡/" + di_xing + "/3.png"),
		load("res://关卡/" + di_xing + "/4.png"),
		load("res://关卡/" + di_xing + "/5.png"),
		load("res://关卡/" + di_xing + "/6.png"),
		load("res://关卡/" + di_xing + "/7.png"),
		load("res://关卡/" + di_xing + "/8.png")
	]
	zi_yuan["tile_wei_fan_kai"] = load("res://关卡/" + di_xing + "/9.png")
	zi_yuan["tile_biao_ji"] = load("res://关卡/" + di_xing + "/10.png")
	zi_yuan["tile_zhang_ai"] = load("res://关卡/草地/树.png")
	# 障碍格子固定使用紫地版本的图片
	zi_yuan["tile_fan_kai_zi"] = load("res://关卡/紫地/0.png")
	zi_yuan["tile_wei_fan_kai_zi"] = load("res://关卡/紫地/9.png")
	zi_yuan["tile_biao_ji_zi"] = load("res://关卡/紫地/10.png")
	return zi_yuan
