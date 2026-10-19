# 【道具使用】关卡内主动使用道具的统一处理
#   RefCounted持有关卡与战斗系统引用，通过preload路径使用，不依赖全局class_name注册。
# ---------- 各道具规则速查 ----------
# 恢复符（1-6级）：关卡道具栏点击启用/再点取消，不同等级只能启用其一。
#   战斗中受击后自动消耗1个并恢复对应等级回血量（回血量表见 hui_fu_zhi_biao）。
#   血量缺口不足回血量时不使用；用完该等级时自动取消启用；启用状态本关持续。
# 玄武盾符（1-6级）：关卡道具栏点击启用/再点取消，不同等级只能启用其一。
#   受常规攻击消耗1个，防御加成=同等级恢复符回血量（写入人物基类 fy_add_2）。
#   流血/荆棘反伤等真伤不消耗；取消/切换/用完/数量异常时清空防御加成。
# 探测器（优秀/精良/史诗/神话）：点击即用，以人物为中心探明半径内未翻开区域后消耗1个；
#   周围已无未探明区域时不消耗并提示。
# 朱雀圣像：仅非战斗时可点击使用。恢复生命，按恢复量概率破损；
#   未破损时圣像保留（可继续点击使用），破损时才消耗1个并增加1个「破损朱雀圣像」。
#   已损失生命>1000：恢复1000且必定破损；
#   已损失生命<=1000：恢复全部损失，破损概率=恢复量/1000（期望总恢复量恰为1000）。
#   满血/战斗中不消耗并提示。
extends RefCounted
# 关卡节点引用（访问GZ网格、人物、背包、面板刷新信号、关卡UI等）
var guan_qia: Node2D
# 战斗系统引用（调用恢复接口、读取战斗状态与时间）
var zhan_dou: Node
# 启用的恢复符等级（0表示未启用，1-6对应等级）
var hui_fu_lv: int = 0
# 启用的玄武盾符等级（0表示未启用，1-6对应等级）
var xuan_wu_lv: int = 0
# 各等级恢复符/玄武盾符的单个数值（下标0未使用，1-6对应1-6级）
const hui_fu_zhi_biao: Array[int] = [0, 1, 3, 7, 20, 55, 148]
# 探测器探测半径配置{名称: 半径}，实际边长=半径×2+1
const tan_ce_biao = {"优秀探测器": 1, "精良探测器": 2, "史诗探测器": 4, "神话探测器": 49}

# 初始化：传入关卡节点和战斗系统
func _init(gq: Node2D, zd: Node) -> void:
	guan_qia = gq
	zhan_dou = zd

# 获取指定等级的数值（恢复符回血量，玄武盾符防御加成复用此值）
func get_hui_fu_zhi(lv: int) -> int:
	# 等级超出1-6范围时返回0
	if lv < 1 or lv > hui_fu_zhi_biao.size() - 1:
		return 0
	return hui_fu_zhi_biao[lv]

# 恢复符启用处理（点击已启用等级的恢复符则取消启用）
func hui_fu_ING(lv: int) -> void:
	# 点击已启用等级则取消，点击其他等级则切换
	hui_fu_lv = 0 if hui_fu_lv == lv else lv
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()

# 玄武盾符启用处理（点击已启用等级则取消启用）
func xuan_wu_ING(lv: int) -> void:
	# 点击已启用等级则取消，点击其他等级则切换
	xuan_wu_lv = 0 if xuan_wu_lv == lv else lv
	# 同步防御加成到人物
	xuan_wu_fy_upd()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()

# 按启用状态同步玄武盾符的临时防御加成到人物（取消启用/用完时清零）
func xuan_wu_fy_upd() -> void:
	# 人物无效时跳过
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	# 未启用时清零，否则取对应等级防御加成（数值同恢复符回血量）
	guan_qia.helo.fy_add_2 = 0 if xuan_wu_lv <= 0 else get_hui_fu_zhi(xuan_wu_lv)
	# 刷新人物面板显示
	guan_qia.shu_wu_upd.emit()

# 受常规攻击后消耗1个启用中的玄武盾符（数量用完自动取消启用并清空防御加成）
func xuan_wu_kou_chu() -> void:
	# 未启用玄武盾符时跳过
	if xuan_wu_lv <= 0:
		return
	# 获取存档节点
	var json = guan_qia.get_node("/root/游戏存档") if guan_qia.has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 对应等级玄武盾符名称
	var wu_ming = str(xuan_wu_lv) + "级玄武盾符"
	# 数量异常时兜底取消启用并清空防御
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		xuan_wu_lv = 0
		xuan_wu_fy_upd()
		guan_qia.guan_ui.dao_ju_upd()
		return
	# 消耗1个玄武盾符
	wu_pin[wu_ming] = int(wu_pin[wu_ming]) - 1
	# 数量变为0时删除该物品字段，并取消启用（清空防御加成）
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
		xuan_wu_lv = 0
		xuan_wu_fy_upd()
	# 保存存档
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()

# 受击后自动使用恢复符（血量缺口足够时）
func hui_fu_fu() -> void:
	# 未启用恢复符时跳过
	if hui_fu_lv <= 0:
		return
	# 获取存档节点
	var json = guan_qia.get_node("/root/游戏存档") if guan_qia.has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 对应等级恢复符名称
	var wu_ming = str(hui_fu_lv) + "级恢复符"
	# 检查恢复符数量
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		return
	# 获取恢复符回血量（等级无效时不使用）
	var hui_fu_zhi = get_hui_fu_zhi(hui_fu_lv)
	if hui_fu_zhi <= 0:
		return
	# 血量缺口不足回血量时不使用
	if (guan_qia.helo_shp - guan_qia.helo_hp) < hui_fu_zhi:
		return
	# 消耗1个恢复符
	wu_pin[wu_ming] = int(wu_pin[wu_ming]) - 1
	# 数量变为0时删除该物品字段
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 恢复人物血量（复用战斗系统恢复接口：回血+血条刷新+恢复飘字）
	zhan_dou.hui_fu(0, 0, hui_fu_zhi, true)
	# 打印恢复信息
	var shi_jian = (Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0
	日志.打印("%.2f秒 英雄恢复生命：%d" % [shi_jian, hui_fu_zhi])
	# 刷新面板
	guan_qia.shu_wu_upd.emit()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()
	# 用完当前等级恢复符时取消启用
	if not wu_pin.has(wu_ming):
		hui_fu_lv = 0
		guan_qia.guan_ui.dao_ju_upd()

# 使用探测器（点击即用，以人物为中心探明半径内未翻开区域）
func use_tan_ce_qi(wu_ming: String) -> void:
	# 获取存档节点
	var json = guan_qia.get_node("/root/游戏存档") if guan_qia.has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 检查道具数量
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		return
	# 获取当前探测器的探测半径（神话半径49，超出地图边界遍历时自动截断，等同探明全图）
	var fan_wei = int(tan_ce_biao.get(wu_ming, -1))
	# 非探测器物品直接返回
	if fan_wei < 0:
		return
	# 获取人物当前位置（转换为0开始索引）
	var helo_x = guan_qia.helo_x - 1
	var helo_y = guan_qia.helo_y - 1
	# 检查范围内是否有未翻开的格子
	var you_wei_fan_kai = false
	for y in range(max(0, helo_y - fan_wei), min(guan_qia.GZ_y, helo_y + fan_wei + 1)):
		for x in range(max(0, helo_x - fan_wei), min(guan_qia.GZ_x, helo_x + fan_wei + 1)):
			if not guan_qia.GZ[y][x]["fan_kai"]:
				you_wei_fan_kai = true
				break
		if you_wei_fan_kai:
			break
	# 如果范围内所有格子都已翻开，不使用探测器并提示
	if not you_wei_fan_kai:
		提示弹幕.wen_ben("周围已经没有未探明的区域！", 0)
		return
	# 减少道具数量
	wu_pin[wu_ming] = int(wu_pin[wu_ming]) - 1
	# 如果数量变为0，删除该物品字段
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 遍历范围内的格子并翻开（批量翻开时关闭每格自动排雷/和弦，避免重复全图扫描造成卡顿）
	for y in range(max(0, helo_y - fan_wei), min(guan_qia.GZ_y, helo_y + fan_wei + 1)):
		for x in range(max(0, helo_x - fan_wei), min(guan_qia.GZ_x, helo_x + fan_wei + 1)):
			# 如果格子未翻开，则翻开（空白格的洪水填充仍会立即执行）
			if not guan_qia.GZ[y][x]["fan_kai"]:
				guan_qia.fan_kai.kai_ge_zi(x, y, false, false)
	# 全部翻完后统一执行一次自动排雷与和弦收敛，结果与逐格翻开完全一致
	guan_qia.fan_kai.yi_jian_kai_ping()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()
	# 显示提示弹幕（显示探测器配置的名义边长）
	var shi_ji_fan_wei = fan_wei * 2 + 1
	提示弹幕.wen_ben("使用【" + wu_ming + "】探明了" + str(shi_ji_fan_wei) + "×" + str(shi_ji_fan_wei) + "及周边区域！", 0)

# 使用朱雀圣像（仅非战斗时可用）：恢复生命，按恢复量概率破损
# 破损时消耗1个朱雀圣像并增加1个「破损朱雀圣像」；未破损时圣像保留（可继续点击使用）
func use_zhu_que_sheng_xiang() -> void:
	# 战斗中不可使用（不消耗）
	if zhan_dou != null and zhan_dou.zhan_dou_ing:
		提示弹幕.wen_ben("战斗中无法使用【朱雀圣像】！", 0)
		return
	# 人物无效时跳过
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	# 已损失生命（上限-当前）
	var sun_shi = guan_qia.helo_shp - guan_qia.helo_hp
	# 满血时不消耗并提示
	if sun_shi <= 0:
		提示弹幕.wen_ben("生命已满！", 0)
		return
	# 获取存档节点
	var json = guan_qia.get_node("/root/游戏存档") if guan_qia.has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 检查朱雀圣像数量
	if not wu_pin.has("朱雀圣像") or int(wu_pin["朱雀圣像"]) <= 0:
		return
	# 恢复量与破损概率：损失>1000恢复1000且必破损；损失<=1000恢复全部损失，破损概率=恢复量/1000
	var hui_fu = 1000
	var po_sun_gai_lv = 1.0
	if sun_shi <= 1000:
		hui_fu = sun_shi
		po_sun_gai_lv = float(sun_shi) / 1000.0
	# 破损判定
	var po_sun = randf() < po_sun_gai_lv
	# 仅在破损时消耗圣像并生成破损圣像（未破损则圣像保留，可继续使用）
	if po_sun:
		wu_pin["朱雀圣像"] = int(wu_pin["朱雀圣像"]) - 1
		if int(wu_pin["朱雀圣像"]) <= 0:
			wu_pin.erase("朱雀圣像")
		wu_pin["破损朱雀圣像"] = int(wu_pin.get("破损朱雀圣像", 0)) + 1
		data["背包"] = wu_pin
		json.bao_cun(guan_qia.json_id, data)
	# 恢复生命（复用战斗系统恢复接口：回血+血条刷新+恢复飘字）
	zhan_dou.hui_fu(0, 0, hui_fu, true)
	# 刷新人物面板
	guan_qia.shu_wu_upd.emit()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()
	# 提示弹幕
	if po_sun:
		提示弹幕.wen_ben("使用【朱雀圣像】恢复%d生命，朱雀圣像破损了！" % hui_fu, 0)
	else:
		提示弹幕.wen_ben("使用【朱雀圣像】恢复%d生命！" % hui_fu, 0)
