# 掉落物数据
class_name 掉落物 extends Node

# 引用物品信息的物品名称和图片
const wu_pin = 物品信息.wu_pin
const wu_pin_png = 物品信息.wu_pin_png

# 彩虹：从各怪物权重表中拆出，所有怪物（主线/支线/诛邪）每次击杀独立判定一次
# 独立判定 = 不与主掉落互相挤占权重，可与主掉落同时获得；掉率固定0.01%，不随判定次数变化
const DIAO_LUO_CAI_HONG = "彩虹"
const CAI_HONG_FEN_MU = 10000  # 独立判定的分母：命中1次即0.01%
const CAI_HONG_MIAO_SHU = "0.01"  # 描述文字中显示的彩虹掉率（0.01%）

# 统一基础掉落表（1倍/1次判定的初始掉率，主线/支线/诛邪共用同一份）
# 结构 {怪物名: [[掉落物列表], [权重列表]]}，每行权重总和固定为100000（即100%），未中部分用null占位
# 权重 ÷ 100000 = 该物品在「1倍（1次判定）」下的掉率（3600 = 3.6%）
# 实际判定次数由模式决定（见 diao_luo_ci_shu）：
#   主线：小怪1次、BOSS 27次；支线：小怪27次、BOSS 512次；诛邪：怪物等级³次（与各自的经验倍率一致）
# 主线/支线的BOSS不在此处直接掉落，而是死亡后生成宝箱，在「免费开启」时按本表结算（见 diao_luo_wu_2）
const diao_luo_ji_chu = {
	# —— 普通怪物 ——
	"红巨蟹":[["蟹钳",null],[360,9640]],
	"褐巨蟹":[["蟹钳",null],[375,9625]],
	"青巨蟹":[["蟹钳",null],[525,9475]],
	"紫巨蟹":[["蟹钳",null],[540,9460]],
	"蓝巨蟹":[["蟹钳",null],[600,9400]],
	"邪嘴唇花":[["藤蔓",null],[189,9811]],
	"橙食人花":[["藤蔓",null],[504,9496]],
	"紫食人花":[["藤蔓",null],[512,9488]],
	"白鬣野猪":[["野猪皮",null],[768,9232]],
	"白鬣赤猪":[["野猪皮",null],[768,9232]],
	"茶鬣野猪":[["野猪皮",null],[810,9190]],
	"绿鬣野猪":[["野猪皮",null],[840,9160]],
	"黄斑野猪":[["野猪皮",null],[840,9160]],
	"紫蠃":[["魔核",null],[140,9860]],
	"紫蠃贤者":[["魔核",null],[200,9800]],
	"蓝蠃勇者":[["魔核",null],[750,9250]],
	"紫蠃勇者":[["魔核",null],[800,9200]],
	"褐蠃长老":[["魔核",null],[840,9160]],
	"黯灰狼":[["狼尾",null],[960,9040]],
	"靛苍狼":[["狼尾",null],[1050,8950]],
	"粉褐狼":[["狼尾",null],[1120,8880]],
	"冰河狼":[["狼尾",null],[1134,8866]],
	"猛犸":[["象牙",null],[9000,1000]],
	# —— BOSS ——
	"邪花王·荆冠":[["邪藤蔓",null],[1680,98320]],
	"葵花王·槐昂":[["邪藤蔓",null],[1792,98208]],
	"野猪王·冕笑":[["野猪王牙",null],[1944,98056]],
	"蠃虫王·犄眦":[["魔王核",null],[3456,96544]],
	"双狼王·睚狈":[["狼王尾",null],[3645,96355]],
	"猛犸王·犽翡":[["绿象牙",null],[10000,90000]]
}

# BOSS宝箱「钥匙开启」的额外掉落表（固定1次，不含彩虹，与模式无关）
# 结构 {BOSS名: [[掉落物列表], [权重列表]]}，每行权重总和固定为100000（即100%）
const diao_luo_yao_shi = {
	"邪花王·荆冠":[["藤蔓","邪藤蔓"],[9,1]],
	"葵花王·槐昂":[["藤蔓","邪藤蔓"],[9,1]],
	"野猪王·冕笑":[["野猪皮","野猪王牙"],[9,1]],
	"蠃虫王·犄眦":[["魔核","魔王核"],[9,1]],
	"双狼王·睚狈":[["狼尾","狼王尾"],[9,1]],
	"猛犸王·犽翡":[["象牙","绿象牙"],[9,1]]
}

# 怪物描述表（只存「1倍」值 = 1次判定的掉率期望，显示时按当前模式的判定次数倍率相乘）
# 结构 {怪物名: {"物品": 掉落物名, "倍率": 1倍掉率, "特殊": 技能说明（可选）}}
const guai_wu_miao_shu = {
	"红巨蟹":{"物品":"蟹钳","倍率":0.036},
	"褐巨蟹":{"物品":"蟹钳","倍率":0.0375},
	"青巨蟹":{"物品":"蟹钳","倍率":0.0525},
	"紫巨蟹":{"物品":"蟹钳","倍率":0.054},
	"蓝巨蟹":{"物品":"蟹钳","倍率":0.06},
	"邪嘴唇花":{"物品":"藤蔓","倍率":0.0189},
	"橙食人花":{"物品":"藤蔓","倍率":0.0504},
	"紫食人花":{"物品":"藤蔓","倍率":0.0512},
	"白鬣野猪":{"物品":"野猪皮","倍率":0.0768},
	"白鬣赤猪":{"物品":"野猪皮","倍率":0.0768},
	"茶鬣野猪":{"物品":"野猪皮","倍率":0.081},
	"绿鬣野猪":{"物品":"野猪皮","倍率":0.084},
	"黄斑野猪":{"物品":"野猪皮","倍率":0.084},
	"紫蠃":{"物品":"魔核","倍率":0.014},
	"紫蠃贤者":{"物品":"魔核","倍率":0.02},
	"蓝蠃勇者":{"物品":"魔核","倍率":0.075},
	"紫蠃勇者":{"物品":"魔核","倍率":0.08},
	"褐蠃长老":{"物品":"魔核","倍率":0.084},
	"黯灰狼":{"物品":"狼尾","倍率":0.096},
	"靛苍狼":{"物品":"狼尾","倍率":0.105},
	"粉褐狼":{"物品":"狼尾","倍率":0.112},
	"冰河狼":{"物品":"狼尾","倍率":0.1134},
	"猛犸":{"物品":"象牙","倍率":0.9},
	"邪花王·荆冠":{"物品":"邪藤蔓","倍率":0.0168,"特殊":"【荆棘】受击造成固定反伤"},
	"葵花王·槐昂":{"物品":"邪藤蔓","倍率":0.01792,"特殊":"【向阳】战斗时回血"},
	"野猪王·冕笑":{"物品":"野猪王牙","倍率":0.01944,"特殊":"【热血】场上怪物越多生命越高"},
	"蠃虫王·犄眦":{"物品":"魔王核","倍率":0.03456,"特殊":"【硬化】受击防御增加"},
	"双狼王·睚狈":{"物品":"狼王尾","倍率":0.03645,"特殊":"【流血】攻击造成流血，可叠加"},
	"猛犸王·犽翡":{"物品":"绿象牙","倍率":0.1,"特殊":"【重甲】增加防御，受击减少"}
}

# 是否诛邪模式（诛邪关卡有zx_lv变量，主线/支线没有）
static func shi_zhu_xie(guan_qia) -> bool:
	return guan_qia.get("zx_lv") != null

# 获取当前模式的掉落判定次数（与经验倍率一致；诛邪按怪物等级的3次方次）
# is_boss：是否BOSS（主线/支线的BOSS宝箱掉落传true）；lv：怪物等级（仅诛邪使用）
static func diao_luo_ci_shu(guan_qia, is_boss: bool, lv: int) -> int:
	# 诛邪模式：小怪与BOSS统一为「怪物等级³」次
	if shi_zhu_xie(guan_qia):
		return int(pow(float(lv), 3.0))
	# 支线模式：小怪27次、BOSS512次
	if guan_qia.has_method("_zhi_xian_win"):
		return 512 if is_boss else 27
	# 主线模式：小怪1次、BOSS27次
	return 27 if is_boss else 1

# 生成怪物描述文本（1倍值 × 当前模式的判定次数；彩虹为固定0.01%，不乘倍率）
# is_boss：是否BOSS；lv：怪物等级（仅诛邪使用）
static func diao_luo_miao_shu(guan_qia, guai_wu_ming: String, is_boss: bool, lv: int) -> String:
	var miao = guai_wu_miao_shu.get(guai_wu_ming)
	if miao == null:
		return ""
	# 当前模式的判定次数倍率
	var bei = diao_luo_ci_shu(guan_qia, is_boss, lv)
	# 第一行：特殊技能（有才显示）；第二行：主掉落期望；第三行：彩虹掉率（固定0.01%）
	var text = ""
	if miao.has("特殊"):
		text = miao["特殊"]
		text += "\n  %s掉落期望%s" % [miao["物品"], ge_shi_diao_lv(miao["倍率"] * bei)]
	else:
		text = "%s掉落期望%s" % [miao["物品"], ge_shi_diao_lv(miao["倍率"] * bei)]
	text += "\n  %s掉率%s%%" % [DIAO_LUO_CAI_HONG, CAI_HONG_MIAO_SHU]
	return text

# 格式化掉率数值文本（最多6位小数，去掉末尾多余的0）
static func ge_shi_diao_lv(v: float) -> String:
	var s = "%.6f" % v
	s = s.rstrip("0")
	s = s.rstrip(".")
	return s

# 按权重判定掉落：重复ci_shu次，每次从掉落物列表中按权重抽取1个
# 返回本次掉落的物品统计（同时写入关卡临时背包BB_ls）
static func jue_ding(guan_qia, diao_biao: Array, diao_lv: Array, ci_shu: int) -> Dictionary:
	var diao_luo_n = {}
	# 计算总权重（每行固定为100000=100%，未中部分用null占位）
	var zong_diao_lv = 0
	for g in diao_lv:
		zong_diao_lv += g
	# 总权重或次数异常时直接返回空
	if zong_diao_lv <= 0 or ci_shu <= 0:
		return diao_luo_n
	# 根据次数循环计算每次掉落
	for i in range(ci_shu):
		# 生成0到总权重-1的随机数
		var sui_ji = randi() % zong_diao_lv
		var add = 0  # 累计权重
		# 遍历掉落物列表，根据权重随机选择
		for j in range(diao_biao.size()):
			add += diao_lv[j]
			# 如果随机数小于累计权重，则选中该物品
			if sui_ji < add:
				jia_ru(guan_qia, diao_luo_n, diao_biao[j])
				# 选中后退出当前循环
				break
	# 返回本次掉落的物品字典
	return diao_luo_n

# 将单个掉落物加入关卡临时背包并累计到本次掉落统计（null为空掉落，直接忽略）
static func jia_ru(guan_qia, diao_luo_n: Dictionary, wu_ming) -> void:
	if wu_ming == null:
		return
	# 判断临时背包是否已有该物品
	if guan_qia.BB_ls.has(wu_ming):
		guan_qia.BB_ls[wu_ming] += 1  # 已有则数量+1
	else:
		guan_qia.BB_ls[wu_ming] = 1  # 没有则新增
	# 累计本次掉落数量
	if diao_luo_n.has(wu_ming):
		diao_luo_n[wu_ming] += 1
	else:
		diao_luo_n[wu_ming] = 1

# 计算怪物掉落（怪物死亡时调用）
static func diao_luo_wu(guan_qia, die_x: int, die_y: int) -> Dictionary:
	# 获取关卡网格数据
	var GZ = guan_qia.GZ
	var ge_zi = GZ[die_y][die_x]
	# 从网格数据中获取怪物名称
	var guai_wu_ming = ge_zi.get("名字", "")
	# 如果没有怪物名称，直接返回
	if guai_wu_ming == "":
		return {}
	# 主线/支线的BOSS掉落改由宝箱结算（点击宝箱时调diao_luo_wu_2），死亡时不直接掉落
	# 诛邪模式的BOSS是1×1普通怪（BOSS=false），仍走此处正常掉落
	var is_boss = ge_zi.get("BOSS", false)
	if is_boss and not shi_zhu_xie(guan_qia):
		return {}
	# 从统一基础掉落表中查询配置
	var biao = diao_luo_ji_chu.get(guai_wu_ming)
	# 如果该怪物没有掉落配置，直接返回
	if biao == null:
		return {}
	# 判定次数由模式与怪物类型决定
	var ci_shu = diao_luo_ci_shu(guan_qia, is_boss, ge_zi.get("lv", 1))
	# 主掉落判定
	var diao_luo_n = jue_ding(guan_qia, biao[0], biao[1], ci_shu)
	# 彩虹：每次击杀独立判定一次（固定0.01%，与判定次数无关）
	if randi() % CAI_HONG_FEN_MU == 0:
		jia_ru(guan_qia, diao_luo_n, DIAO_LUO_CAI_HONG)
	# 返回本次掉落的物品字典
	return diao_luo_n

# 计算BOSS宝箱掉落（开启宝箱时调用）
# is_first=true：首次免费开启（= BOSS本体掉落），读统一基础表，次数按模式，并判定彩虹
# is_first=false：钥匙开启，读钥匙掉落表，固定1次，不含彩虹
static func diao_luo_wu_2(guan_qia, BX_id: String, is_first: bool) -> Dictionary:
	var diao_luo_n = {}
	if is_first:
		# 首次免费开启：读统一基础掉落表
		var biao = diao_luo_ji_chu.get(BX_id)
		if biao == null:
			return {}
		# 次数按BOSS算（主线27次、支线512次；诛邪无宝箱）
		var ci_shu = diao_luo_ci_shu(guan_qia, true, 1)
		diao_luo_n = jue_ding(guan_qia, biao[0], biao[1], ci_shu)
		# 彩虹：免费开启视为BOSS的击杀掉落，独立判定一次0.01%
		if randi() % CAI_HONG_FEN_MU == 0:
			jia_ru(guan_qia, diao_luo_n, DIAO_LUO_CAI_HONG)
	else:
		# 钥匙开启：读钥匙额外掉落表，固定1次
		var biao = diao_luo_yao_shi.get(BX_id)
		if biao == null:
			return {}
		diao_luo_n = jue_ding(guan_qia, biao[0], biao[1], 1)
	# 返回本次掉落的物品字典
	return diao_luo_n

# 检查是否有钥匙
static func you_yao_shi(guan_qia) -> bool:
	# 获取存档节点（静态函数中使用Engine获取主循环，通过root检查节点）
	var main_loop = Engine.get_main_loop()
	var root = main_loop.get_root()
	var json = root.get_node_or_null("游戏存档")
	if json == null:
		return false
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品（使用BB避免遮蔽wu_pin常量）
	var BB = data.get("背包", {})
	# 检查钥匙数量
	return BB.has("钥匙") and int(BB.get("钥匙", 0)) > 0

# 消耗钥匙
static func add_yao_shi(guan_qia) -> bool:
	# 获取存档节点（静态函数中使用Engine获取主循环，通过root检查节点）
	var main_loop = Engine.get_main_loop()
	var root = main_loop.get_root()
	var json = root.get_node_or_null("游戏存档")
	if json == null:
		return false
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品（使用BB避免遮蔽wu_pin常量）
	var BB = data.get("背包", {})
	# 检查钥匙数量
	if not BB.has("钥匙") or int(BB.get("钥匙", 0)) <= 0:
		return false
	# 消耗钥匙
	BB["钥匙"] = int(BB["钥匙"]) - 1
	# 如果数量变为0，删除该物品字段
	if BB["钥匙"] <= 0:
		BB.erase("钥匙")
	data["背包"] = BB
	json.bao_cun(guan_qia.json_id, data)
	return true
