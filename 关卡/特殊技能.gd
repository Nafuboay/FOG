# 【特殊技能】BOSS特殊技能集中处理（主线与诛邪通用）
# BOSS的状态数据全部存放在关卡网格GZ字典中，怪物节点只负责动画表现，
# 因此技能逻辑集中在本文件，按触发时机提供钩子供战斗系统/关卡基类调用。
# 新增BOSS技能时：依赖初始字段的写进 BOSS_ji_neng_chu_shi（静态），
# 战斗中触发的按时机写进对应钩子，主线与诛邪即同时生效。
class_name 特殊技能 extends RefCounted

# 关卡节点引用（访问GZ网格数据、面板刷新信号、BOSS_xy等）
var guan_qia: Node2D
# 战斗系统引用（调用伤害/恢复/结束战斗等接口）
var zhan_dou: Node

# 初始化：传入关卡节点和战斗系统
func _init(gq: Node2D, zd: Node) -> void:
	guan_qia = gq
	zhan_dou = zd

# ---------- 技能初始化 ----------
# 设置依赖初始字段的BOSS技能数据（主线BOSS_xian_shi与诛邪_zhu_xie_guai_wu通用）
static func BOSS_ji_neng_chu_shi(cell: Dictionary, guai_wu_id: String, boss_lv: int) -> void:
	# 猛犸王【重甲】技能：增加防御，受击减少
	var fy_add_4 = 0
	if guai_wu_id == "猛犸王·犽翡":
		fy_add_4 = 32 * boss_lv
		cell["fy"] += fy_add_4
	# 写入重甲防御加成（供受击减防和信息面板读取）
	cell["fy_add_4"] = fy_add_4

# ---------- 受击类技能：怪物被人物攻击时触发 ----------
# 返回true表示人物已被反伤击杀（战斗已结束），调用方需立即return
func shou_ji_ji_neng(x: int, y: int) -> bool:
	var GZ = guan_qia.GZ
	var guai_wu_id = GZ[y][x].get("guai_wu_id", "")
	# 猛犸王【重甲】技能：受击减少防御
	if guai_wu_id == "猛犸王·犽翡":
		# 获取当前重甲防御加成
		var fy_add_4 = GZ[y][x].get("fy_add_4", 0)
		# 如果还有重甲加成
		if fy_add_4 > 0:
			# 获取BOSS等级
			var boss_lv = GZ[y][x].get("lv", 1)
			# 减少防御加成，最低为0
			fy_add_4 = max(0, fy_add_4 - boss_lv)
			# 根据怪物占位决定更新范围：主线BOSS(2x2)更新4格，诛邪单格只更新当前格
			var is_boss = GZ[y][x].get("BOSS", false)
			var boss_x = int(GZ[y][x].get("BOSS_x", x)) if is_boss else x
			var boss_y = int(GZ[y][x].get("BOSS_y", y)) if is_boss else y
			var range_n = 2 if is_boss else 1
			# 更新猛犸王格子的防御加成和实际防御值
			for by in range(boss_y, boss_y + range_n):
				for bx in range(boss_x, boss_x + range_n):
					GZ[by][bx]["fy_add_4"] = fy_add_4  # 更新重甲加成
					GZ[by][bx]["fy"] -= boss_lv  # 减少实际防御
	# 蠃虫王【硬化】技能：受击增加防御
	elif guai_wu_id == "蠃虫王·犄眦":
		# 获取BOSS等级
		var boss_lv = GZ[y][x].get("lv", 1)
		# 获取当前硬化防御加成
		var fy_add_5 = GZ[y][x].get("fy_add_5", 0)
		# 硬化防御上限为自身等级×32（每次受击+自身等级，叠加32次达到极限后保持）
		var fy_add_5_max = boss_lv * 32
		# 未达上限时才增加防御，达到极限后受击不再变化
		if fy_add_5 < fy_add_5_max:
			# 记录增加前的加成，并钳制在上限内
			var fy_add_5_old = fy_add_5
			fy_add_5 = min(fy_add_5_max, fy_add_5 + boss_lv)
			# 本次实际增加的防御（正常为boss_lv，钳制时取剩余额度）
			var fy_zeng = fy_add_5 - fy_add_5_old
			# 根据怪物占位决定更新范围：主线BOSS(2x2)更新4格，诛邪单格只更新当前格
			var is_boss = GZ[y][x].get("BOSS", false)
			var boss_x = int(GZ[y][x].get("BOSS_x", x)) if is_boss else x
			var boss_y = int(GZ[y][x].get("BOSS_y", y)) if is_boss else y
			var range_n = 2 if is_boss else 1
			# 更新蠃虫王格子的防御加成和实际防御值
			for by in range(boss_y, boss_y + range_n):
				for bx in range(boss_x, boss_x + range_n):
					GZ[by][bx]["fy_add_5"] = fy_add_5  # 更新硬化加成
					GZ[by][bx]["fy"] += fy_zeng  # 增加实际防御
	# 邪花王【荆棘】技能：受击造成固定反伤
	elif guai_wu_id == "邪花王·荆冠":
		# 获取BOSS等级作为反伤伤害
		var fan_shang = GZ[y][x].get("lv", 1)
		# 延后执行反伤
		await zhan_dou.get_tree().create_timer(0.05).timeout
		# 场景已切换/释放中时终止协程
		if not zhan_dou.is_inside_tree():
			return false
		# 检查战斗是否还在进行
		if not zhan_dou.zhan_dou_ing:
			return false
		# 检查人物是否有效
		if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
			return false
		# 打印反伤信息
		var time_2 = (Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0
		print("%.2f秒 怪物造成反伤：%d" % [time_2, fan_shang])
		# 对人物造成反伤（真伤，使用灰色飘字）
		zhan_dou.shang_hai(0, 0, fan_shang, true, true)
		# 检查人物是否被反伤击杀
		if guan_qia.helo_hp <= 0:
			guan_qia.helo_hp = 0
			# 统一处理人物死亡（含失败弹窗与结束战斗，逻辑在死亡处理.gd）
			zhan_dou.si_wang.helo_si_wang()
			# 人物已死亡，通知调用方跳过后续流程
			return true
	return false

# ---------- 攻击类技能：怪物攻击人物后触发 ----------
func gong_ji_ji_neng(x: int, y: int) -> void:
	var GZ = guan_qia.GZ
	var guai_wu_id = GZ[y][x].get("guai_wu_id", "")
	# 葵花王【向阳】技能：战斗时回血
	if guai_wu_id == "葵花王·槐昂":
		hp_add(x, y)
	# 双狼王【流血】技能：攻击造成流血，可叠加
	elif guai_wu_id == "双狼王·睚狈":
		liu_xue()

# 葵花王【向阳】技能协程：战斗时回血
func hp_add(x: int, y: int) -> void:
	await zhan_dou.get_tree().create_timer(0.5).timeout
	# 场景已切换/释放中时终止协程
	if not zhan_dou.is_inside_tree():
		return
	# 检查战斗是否还在进行
	if not zhan_dou.zhan_dou_ing:
		return
	var GZ = guan_qia.GZ
	# 检查怪物是否有效
	if GZ[y][x].get("si_wang", false) == true:
		return
	# 计算恢复量：min(剩余生命上限, 等级×3)
	var hp_sheng_yu = GZ[y][x]["shp"] - GZ[y][x]["hp"]
	var hui_fu_liang = min(hp_sheng_yu, GZ[y][x]["lv"] * 3)
	if hui_fu_liang > 0:
		# 打印恢复信息
		print("%.2f秒 怪物恢复生命：%d" % [(Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0, hui_fu_liang])
		# 恢复怪物生命
		zhan_dou.hui_fu(x, y, hui_fu_liang, false)
		# 发出伤害信号刷新面板
		guan_qia.shu_wu_upd.emit()

# 双狼王【流血】技能：攻击造成流血，可叠加
func liu_xue() -> void:
	await zhan_dou.get_tree().create_timer(0.7).timeout
	# 场景已切换/释放中时终止协程
	if not zhan_dou.is_inside_tree():
		return
	# 检查战斗是否还在进行
	if not zhan_dou.zhan_dou_ing:
		return
	# 检查人物是否有效
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	var GZ = guan_qia.GZ
	# 获取当前流血层数（使用get_meta支持默认值）
	var liu_xue_n = guan_qia.helo.get_meta("liu_xue_n", 0)
	# 获取怪物等级作为最高叠加次数
	var zui_gao_ceng_shu = GZ[zhan_dou.guai_wu_y][zhan_dou.guai_wu_x]["lv"]
	# 增加流血层数（不超过最高层数）
	liu_xue_n = min(liu_xue_n + 1, zui_gao_ceng_shu)
	# 更新流血层数（使用set_meta存储自定义属性）
	guan_qia.helo.set_meta("liu_xue_n", liu_xue_n)
	# 计算流血伤害：3 × 层数
	var shui_xue_shang_hai = 3 * liu_xue_n
	# 打印流血信息
	print("%.2f秒 怪物造成流血：%d（层数：%d）" % [(Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0, shui_xue_shang_hai, liu_xue_n])
	# 对人物造成流血伤害（真伤，使用灰色飘字）
	zhan_dou.shang_hai(0, 0, shui_xue_shang_hai, true, true)
	# 发出伤害信号刷新面板
	guan_qia.shu_wu_upd.emit()
	# 检查人物是否因流血死亡
	if guan_qia.helo_hp <= 0:
		guan_qia.helo_hp = 0
		# 统一处理人物死亡（含失败弹窗与结束战斗，逻辑在死亡处理.gd）
		zhan_dou.si_wang.helo_si_wang()

# ---------- 死亡类技能：任意怪物死亡后触发 ----------
func guai_wu_die_ji_neng() -> void:
	# 野猪王【热血】技能：场上怪物越多生命越高
	for boss_xy in guan_qia.BOSS_xy:
		var x = int(boss_xy.x)
		var y = int(boss_xy.y)
		# 检查是否是野猪王
		if guan_qia.GZ[y][x].get("guai_wu_id", "") == "野猪王·冕笑":
			# 获取基础生命值和BOSS等级
			var shp_1 = guan_qia.GZ[y][x].get("shp_1", 0)
			var boss_lv = guan_qia.GZ[y][x].get("lv", 1)
			# 重新计算生命值 = 基础生命 + (场上怪物数 - 1) × BOSS等级
			var xin_shp = shp_1 + (guan_qia.guai_wu_xian - 1) * boss_lv
			# 当前HP不能超过新的上限（防止血量溢出）
			var xin_hp = min(guan_qia.GZ[y][x]["hp"], xin_shp)
			# 更新野猪王4个格子的生命值（BOSS占用2x2区域）
			for by in range(y, y + 2):
				for bx in range(x, x + 2):
					guan_qia.GZ[by][bx]["shp"] = xin_shp
					guan_qia.GZ[by][bx]["hp"] = xin_hp
			# 如果正在查看野猪王面板，刷新显示
			if guan_qia.guai_wu_x_ing >= x and guan_qia.guai_wu_x_ing < x + 2 and guan_qia.guai_wu_y_ing >= y and guan_qia.guai_wu_y_ing < y + 2:
				guan_qia.XX.look(false, x, y)
			break
