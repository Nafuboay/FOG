# 【战斗系统】
class_name 战斗系统 extends Node
# 父节点引用（关卡节点），通过此属性访问关卡的数据和方法
var guan_qia: Node2D
# BOSS特殊技能处理器脚本（技能逻辑集中在特殊技能.gd，主线与诛邪通用）
const 特殊技能_SCRIPT = preload("res://关卡/特殊技能.gd")
# 血条飘字处理器脚本（血条与飘字显示集中在血条飘字.gd）
const 血条飘字_SCRIPT = preload("res://关卡/血条飘字.gd")
# 死亡处理器脚本（人物/怪物死亡、BOSS宝箱、胜利结算集中在死亡处理.gd）
const 死亡处理_SCRIPT = preload("res://关卡/死亡处理.gd")
var ji_neng
# 血条飘字处理器（血条与飘字显示逻辑）
var xue_tiao_qi
# 死亡处理器（人物/怪物死亡与胜利结算逻辑）
var si_wang
# 战斗秒杀倍率
var zhan_dou_ming: float = 1.0
# 战斗进行中状态
var zhan_dou_ing: bool = false
# 战斗开始时间（毫秒）
var zhan_dou_time: int = 0
# 战败状态
var zhan_bai: bool = false
# 当前战斗的怪物节点
var guai_wu_ing: Node = null
# 当前战斗怪物的X坐标
var guai_wu_x: int = -1
# 当前战斗怪物的Y坐标
var guai_wu_y: int = -1
# 人物当前回合数（攻击次数）
var helo_hui: int = 0
# 是否正在撤退
var che_tui_ing: bool = false
# 撤退时的回合数
var che_tui_hui: int = 0
# 撤退待机计时
var che_tui_t: float = 0.0
# 与怪物战斗中是否反转过
var fan1: bool = false
# 撤退时是否反转过
var fan2: bool = false
# 与BOSS战斗是否需要反转
var fan3: bool = false
# 是否找到BOSS战斗位置的标记
var is_BOSS_xy: bool = false
# 各等级恢复符的单个回血量（下标0未使用，1-6对应1-6级恢复符）
const hui_fu_zhi_biao: Array[int] = [0, 1, 3, 7, 20, 55, 148]

# 获取父节点，如果父节点是容器则继续往上找真正的关卡节点
func _ready() -> void:
	var parent = get_parent()
	if parent.name != "关卡":
		parent = parent.get_parent()
	guan_qia = parent
	# 创建BOSS特殊技能处理器（用preload路径引用，不依赖全局class_name注册）
	ji_neng = 特殊技能_SCRIPT.new(guan_qia, self)
	# 创建血条飘字处理器（血条与飘字显示逻辑在血条飘字.gd）
	xue_tiao_qi = 血条飘字_SCRIPT.new(guan_qia, self)
	# 创建死亡处理器（人物/怪物死亡与胜利结算逻辑在死亡处理.gd）
	si_wang = 死亡处理_SCRIPT.new(guan_qia, self)

# 常规伤害
# is_zhen_shang=true时使用灰色真伤飘字（荆棘反伤、流血等无视防御的伤害）
func shang_hai(x: int, y: int, zhi: int, is_helo: bool, is_zhen_shang: bool = false) -> void:
	if zhi < 0: # 伤害异常
		return
	if is_helo: # 是人物
		guan_qia.helo_hp -= zhi
		if guan_qia.helo_hp < 0:
			guan_qia.helo_hp = 0
		xue_tiao_qi.xue_tiao_upd_1() # 刷新人物血条
		# 人物伤害飘字（真伤时使用30-39灰色飘字）
		xue_tiao_qi.piao_zi(guan_qia.helo_x - 1, guan_qia.helo_y - 1, zhi, false, false, is_zhen_shang)
	else: # 是怪物
		var GZ1 = guan_qia.GZ[y][x]
		GZ1["hp"] -= zhi
		if GZ1["hp"] < 0:
			GZ1["hp"] = 0
		xue_tiao_qi.xue_tiao_upd_2(x, y) # 刷新怪物血条
		# 怪物伤害飘字（真伤时使用30-39灰色飘字）
		xue_tiao_qi.piao_zi(x, y, zhi, false, true, is_zhen_shang)

# 常规恢复
func hui_fu(x: int, y: int, zhi: int, is_helo: bool) -> void:
	if zhi < 1: # 恢复异常
		return
	if is_helo: # 是人物
		guan_qia.helo_hp += zhi
		if guan_qia.helo_hp > guan_qia.helo_shp:
			guan_qia.helo_hp = guan_qia.helo_shp
		xue_tiao_qi.xue_tiao_upd_1() # 刷新人物血条
		# 恢复使用10-19图片（从1开始计数）
		xue_tiao_qi.piao_zi(guan_qia.helo_x - 1, guan_qia.helo_y - 1, zhi, true, false)
	else: # 是怪物
		var GZ1 = guan_qia.GZ[y][x]
		GZ1["hp"] += zhi
		if GZ1["hp"] > GZ1["shp"]:
			GZ1["hp"] = GZ1["shp"]
		xue_tiao_qi.xue_tiao_upd_2(x, y) # 刷新怪物血条
		# 恢复使用10-19图片
		xue_tiao_qi.piao_zi(x, y, zhi, true, false)

# 查找对战怪物
func find_guai_wu(x: int, y: int) -> Node:
	var guai_wu = guan_qia.guai_wu
	for guai in guai_wu:
		if guai != null and is_instance_valid(guai):
			var gx = guai.get_meta("grid_x", -1)
			var gy = guai.get_meta("grid_y", -1)
			if gx == x and gy == y:
				return guai
	return null

# 计算BOSS战斗时的人物位置（12个可选位置，按指定顺序查找）
func move_xy_BOSS(x: int, y: int) -> Vector2:
	var GZ = guan_qia.GZ
	var BOSS_xy = guan_qia.BOSS_xy
	var GZ_x = guan_qia.GZ_x
	var GZ_y = guan_qia.GZ_y
	var helo_x = guan_qia.helo_x
	var helo_y = guan_qia.helo_y
	# 重置找到位置标记
	is_BOSS_xy = false
	# 找到BOSS主格位置
	var boss_x = x
	var boss_y = y
	for boss_xy in BOSS_xy:
		var bx = int(boss_xy.x)
		var by = int(boss_xy.y)
		if x >= bx and x < bx + 2 and y >= by and y < by + 2:
			boss_x = bx
			boss_y = by
			break
	# BOSS 12个可选位置顺序（按优先级）
	var BOSS_order = [
		{"dx": -1, "dy": 1, "need_flip": false},   # 左中下
		{"dx": -1, "dy": 0, "need_flip": false},  # 左中上
		{"dx": 2, "dy": 1, "need_flip": true},     # 右中下
		{"dx": 2, "dy": 0, "need_flip": true},    # 右中上
		{"dx": -1, "dy": 2, "need_flip": false},   # 左下
		{"dx": 2, "dy": 2, "need_flip": true},      # 右下
		{"dx": -1, "dy": -1, "need_flip": false},  # 左上
		{"dx": 2, "dy": -1, "need_flip": true},    # 右上
		{"dx": 0, "dy": 2, "need_flip": false},    # 下中左
		{"dx": 1, "dy": 2, "need_flip": true},     # 下中右
		{"dx": 0, "dy": -1, "need_flip": false},   # 上中左
		{"dx": 1, "dy": -1, "need_flip": true}     # 上中右
	]
	# 按顺序查找第一个满足条件的格子
	for pos in BOSS_order:
		var nx = boss_x + pos["dx"]
		var ny = boss_y + pos["dy"]
		# 检查是否在网格范围内
		if nx < 0 or nx >= GZ_x or ny < 0 or ny >= GZ_y:
			continue
		# 检查该格子是否已翻开且是数字或空白
		var GZ2 = GZ[ny][nx]
		if GZ2["fan_kai"] == true and (GZ2["shu_zi"] == true or GZ2["kong_bai"] == true) and GZ2.get("NPC", false) == false:
			# 设置找到位置标记
			is_BOSS_xy = true
			# 设置BOSS战斗是否需要反转
			fan3 = pos["need_flip"]
			return Vector2(nx, ny)
	# 没有找到满足条件的格子，返回原位置
	return Vector2(helo_x - 1, helo_y - 1)

# 计算普通怪物战斗时的人物位置（8个可选位置，按指定顺序查找）
func move_xy(x: int, y: int, GZ_fan_kai: bool, GZ_shu_zi: bool, GZ_kong_bai: bool) -> Vector2:
	var GZ = guan_qia.GZ
	var GZ_x = guan_qia.GZ_x
	var GZ_y = guan_qia.GZ_y
	var helo_x = guan_qia.helo_x
	var helo_y = guan_qia.helo_y
	# 已翻开且是数字或空白，直接移动到该格
	if GZ_fan_kai and (GZ_shu_zi == true or GZ_kong_bai == true):
		return Vector2(x, y)
	# 不可进格，移动到周围数字或空白的已翻开格
	if GZ_shu_zi == false and GZ_kong_bai == false:
		# 不可进格，按顺序查找周围已翻开格子（只找空白/数字）
		var order = [
			Vector2(-1, 0),   # 左
			Vector2(1, 0),    # 右
			Vector2(-1, 1),   # 左下
			Vector2(1, 1),    # 右下
			Vector2(-1, -1),  # 左上
			Vector2(1, -1),  # 右上
			Vector2(0, 1),   # 下
			Vector2(0, -1)   # 上
		]
		for GZ_pian_yi in order:
			var nx = x + int(GZ_pian_yi.x)
			var ny = y + int(GZ_pian_yi.y)
			if nx >= 0 and nx < GZ_x and ny >= 0 and ny < GZ_y:
				var GZ2 = GZ[ny][nx]
				# 已翻开且是数字或空白，且不是NPC所在格
				if GZ2["fan_kai"] == true and (GZ2["shu_zi"] == true or GZ2["kong_bai"] == true) and GZ2.get("NPC", false) == false:
					return Vector2(nx, ny)
		# 没有数字或空白已翻开格，返回原位置
		return Vector2(helo_x - 1, helo_y - 1)
	else:
		# 空白或数字格，移动到该格
		return Vector2(x, y)

# 触发战斗
func zhan_dou(x: int, y: int) -> void:
	var GZ = guan_qia.GZ
	var GZ1 = GZ[y][x]
	# 检查该位置是否已翻开，未翻开则无法战斗
	if GZ1["fan_kai"] == false:
		return
	# 检查该位置是否有怪物或BOSS
	if GZ1["guai_wu"] == false and GZ1["BOSS"] == false:
		return
	# 获取BOSS主格位置（点击的可能是任意一格）
	var boss_x = x
	var boss_y = y
	if GZ1["BOSS"] == true:
		# 获取关卡中所有BOSS的位置数组
		var BOSS_xy = guan_qia.BOSS_xy
		# 遍历BOSS位置数组，找到当前点击格子所属的BOSS主格
		for boss_xy in BOSS_xy:
			var bx = int(boss_xy.x)
			var by = int(boss_xy.y)
			# 检查点击位置是否在BOSS的2x2区域范围内
			if x >= bx and x < bx + 2 and y >= by and y < by + 2:
				boss_x = bx
				boss_y = by
				break
		# 调用move_xy_BOSS检查是否有可进入的位置，同时设置fan3
		move_xy_BOSS(boss_x, boss_y)
		# 如果没有找到合适的战斗位置，禁止进入战斗
		if not is_BOSS_xy:
			return
	# 如果已有战斗进行中，不再触发新战斗
	if zhan_dou_ing:
		return
	# 查找该位置的怪物节点
	var guai_wu1 = find_guai_wu(boss_x, boss_y)
	# 没找到怪物则返回
	if guai_wu1 == null:
		return
	# 设置战斗状态为进行中
	zhan_dou_ing = true
	# 延迟显示撤退按钮
	get_tree().create_timer(0.05).timeout.connect(func():
		guan_qia.guan_ui.che_tui.visible = true
		guan_qia.guan_ui.che_tui_upd()
	)
	# 记录当前战斗的怪物对象和坐标
	guai_wu_ing = guai_wu1
	guai_wu_x = boss_x
	guai_wu_y = boss_y
	# 如果是BOSS战斗，根据fan3设置fan1
	if fan3:
		fan1 = true
	# 战斗时显示怪物血条
	xue_tiao_qi.xue_tiao_upd_2(boss_x, boss_y)
	# 战斗时怪物面板自动显示当前怪物
	guan_qia.XX.look(false, boss_x, boss_y)
	# 战斗时显示人物面板
	if guan_qia.helo != null:
		guan_qia.look_helo.visible = true
		guan_qia.kuai_1.visible = true
		guan_qia.XX.look_helo_upd()
	# 重置人物攻击回合计数（从第1回合开始）
	helo_hui = 0
	# 重置秒杀倍率
	zhan_dou_ming = 1.0
	var helo = guan_qia.helo
	if helo != null and is_instance_valid(helo):
		# 先断开之前的信号连接，避免重复连接
		if helo.attack_xin_hao.is_connected(zhan_dou_hui):
			helo.attack_xin_hao.disconnect(zhan_dou_hui)
		# 连接攻击触发信号（基类每次攻击动画开始时发出）
		helo.attack_xin_hao.connect(zhan_dou_hui)
		# 进入战斗状态（基类方法）
		helo.zhan_dou_ing()
	if guai_wu1 != null and is_instance_valid(guai_wu1):
		guai_wu1.zhan_dou_ing()
	# 开始攻击
	attack_1()

# 计算朝向
func chao_xiang(is_hui_fu: bool = false, dan_du: bool = false, che_tui: bool = false) -> void:
	var helo = guan_qia.helo
	var role_pian_yi_x = guan_qia.role_pian_yi_x
	# 检查人物是否有效
	if helo == null or not is_instance_valid(helo):
		return
	if che_tui:
		# 撤退模式：反转人物
		if helo.has_node("AnimatedSprite2D"):
			helo.get_node("AnimatedSprite2D").flip_h = not helo.get_node("AnimatedSprite2D").flip_h
		if fan1:
			helo.position.x += 2 * role_pian_yi_x
		else:
			helo.position.x -= 2 * role_pian_yi_x
		fan2 = true
	elif is_hui_fu:
		# 恢复模式
		if fan1 and fan2:
			# 位置不对且撤退过，只恢复怪物，人物位置也要恢复
			helo.position.x += 4 * role_pian_yi_x
			if not dan_du and guai_wu_ing != null and is_instance_valid(guai_wu_ing):
				if guai_wu_ing.has_node("AnimatedSprite2D"):
					guai_wu_ing.get_node("AnimatedSprite2D").flip_h = not guai_wu_ing.get_node("AnimatedSprite2D").flip_h
				guai_wu_ing.position.x -= 2 * role_pian_yi_x * guai_wu_ing.scale.x
		elif fan1:
			# 战斗中反转过，人物和怪物都恢复
			if helo.has_node("AnimatedSprite2D"):
				helo.get_node("AnimatedSprite2D").flip_h = not helo.get_node("AnimatedSprite2D").flip_h
			helo.position.x -= 2 * role_pian_yi_x
			if not dan_du and guai_wu_ing != null and is_instance_valid(guai_wu_ing):
				if guai_wu_ing.has_node("AnimatedSprite2D"):
					guai_wu_ing.get_node("AnimatedSprite2D").flip_h = not guai_wu_ing.get_node("AnimatedSprite2D").flip_h
				guai_wu_ing.position.x -= 2 * role_pian_yi_x * guai_wu_ing.scale.x
		elif fan2:
			# 战斗中没反转但撤退过，只恢复人物
			if helo.has_node("AnimatedSprite2D"):
				helo.get_node("AnimatedSprite2D").flip_h = not helo.get_node("AnimatedSprite2D").flip_h
			helo.position.x -= 2 * role_pian_yi_x
	else:
		# 反转模式
		var helo_x = guan_qia.helo_x
		if helo_x - 1 > guai_wu_x:
			if helo.has_node("AnimatedSprite2D"):
				helo.get_node("AnimatedSprite2D").flip_h = not helo.get_node("AnimatedSprite2D").flip_h
			helo.position.x -= 2 * role_pian_yi_x
			if not dan_du and guai_wu_ing != null and is_instance_valid(guai_wu_ing):
				if guai_wu_ing.has_node("AnimatedSprite2D"):
					guai_wu_ing.get_node("AnimatedSprite2D").flip_h = not guai_wu_ing.get_node("AnimatedSprite2D").flip_h
				guai_wu_ing.position.x += 2 * role_pian_yi_x * guai_wu_ing.scale.x
			fan1 = true

# 执行攻击
func attack_1() -> void:
	var helo = guan_qia.helo
	# 检查人物和怪物是否有效
	if helo == null or not is_instance_valid(helo):
		return
	# 检查怪物是否有效（可能已被击败）
	if guai_wu_ing == null or not is_instance_valid(guai_wu_ing):
		zhan_dou_end()
		return
	# 战斗开始时检查血量，自动使用恢复符
	hui_fu_n()
	# 先设置朝向
	chao_xiang()
	# 断开人物攻击信号（避免重复连接）
	if helo.attack_xin_hao.is_connected(helo_shang_hai_0):
		helo.attack_xin_hao.disconnect(helo_shang_hai_0)
	# 连接人物攻击信号
	helo.attack_xin_hao.connect(helo_shang_hai_0)
	# 先记录战斗开始时间并打印（首次攻击信号在play_attack内同步发出，回合开始的生命打印依赖此时间戳）
	zhan_dou_time = Time.get_ticks_msec()
	print("\n战斗开始")
	helo.play_attack()
	guai_wu_ing.play_attack()

# 计算人物对怪物的伤害
func helo_shang_hai_0() -> void:
	if guan_qia.helo == null:
		return
	var helo_attack_n: int = guan_qia.helo.attack_n
	var time_interval: float = 0.2 / helo_attack_n
	for i in range(helo_attack_n):
		await get_tree().create_timer(time_interval).timeout
		# 场景已切换/释放中时终止协程
		if not is_inside_tree():
			return
		# 检查战斗是否还在进行
		if not zhan_dou_ing:
			return
		# 计时器启动时检查是否已过撤退回合
		if che_tui_hui > 0 and helo_hui > che_tui_hui:
			# 撤退时怪物单独攻击一次
			if guai_wu_ing != null and is_instance_valid(guai_wu_ing):
				# 计算剩余攻击需要的时间，等待最后一次攻击完成后再触发怪物攻击
				var yan_chi = time_interval * (helo_attack_n - i - 1)
				await get_tree().create_timer(yan_chi).timeout
				# 场景已切换/释放中时不再触发怪物攻击
				if not is_inside_tree():
					return
				guai_wu_shang_hai_0(0)
			return
		# 检查怪物是否有效
		if guai_wu_ing == null or not is_instance_valid(guai_wu_ing):
			return
		var GZ = guan_qia.GZ
		# 获取怪物属性
		var guai_wu_fy: float = GZ[guai_wu_y][guai_wu_x]["fy"]
		var guai_wu_lv: float = GZ[guai_wu_y][guai_wu_x]["lv"]
		var guai_wu_hp: float = GZ[guai_wu_y][guai_wu_x]["hp"]
		# 获取人物属性
		var helo_lv = guan_qia.helo_lv
		var helo_ll = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ll, "ll")
		var helo_ct = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ct, "ct")
		# 计算伤害：人物力量×人物穿透÷怪物防御÷max(怪物等级÷人物等级,1)÷攻击次数
		var shang_hai_zhi:float=helo_ll*helo_ct/guai_wu_fy/max(guai_wu_lv/helo_lv,1.0)/helo_attack_n
		# 计算秒杀倍率：伤害（取整前）/怪物血量上限
		var ming: float = shang_hai_zhi / guai_wu_hp
		zhan_dou_ming = ming
		# 伤害值取整（概率取整：小数部分决定额外1伤害的概率）
		var ji_shu: int = int(shang_hai_zhi)
		var gai_Lv: float = shang_hai_zhi - ji_shu
		if randf() < gai_Lv:
			ji_shu += 1
		# 应用伤害到怪物
		helo_shang_hai_1(ji_shu)
	# 人物攻击循环结束后，立即触发怪物攻击
	if zhan_dou_ing and guai_wu_x >= 0 and guai_wu_y >= 0:
		guai_wu_shang_hai_0(0)

# 应用人物对怪物的伤害
func helo_shang_hai_1(ji_shu: int) -> void:
	# 获取人物属性用于打印
	var helo_lv = guan_qia.helo_lv
	var helo_ll = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ll, "ll")
	var helo_ct = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ct, "ct")
	var helo_attack_n = guan_qia.helo.attack_n
	# 打印伤害信息
	var time_1 = (Time.get_ticks_msec() - zhan_dou_time) / 1000.0
	print("%.2f秒 英雄造成伤害：%d=%d×%d÷%d÷max(%d÷%d,1)÷%d"%[time_1,ji_shu,helo_ll,helo_ct,guan_qia.GZ[guai_wu_y][guai_wu_x]["fy"],guan_qia.GZ[guai_wu_y][guai_wu_x]["lv"],helo_lv, helo_attack_n])
	# 使用统一函数处理伤害（包含血条更新和飘字显示）
	shang_hai(guai_wu_x, guai_wu_y, ji_shu, false)
	# BOSS受击类技能（猛犸王重甲/蠃虫王硬化/邪花王反伤）
	# 返回true表示人物已被反伤击杀，战斗已结束
	if await ji_neng.shou_ji_ji_neng(guai_wu_x, guai_wu_y):
		return
	# 场景切换或人物死亡时跳过后续流程（反伤延迟期间可能触发怪物死亡→场景切换）
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	# 发出伤害信号刷新面板
	guan_qia.shu_wu_upd.emit()
	# 伤害后处理（玄戈力量加成：角色文件通过has_method多态实现，与zhan_dou_end_ji_neng同模式；传入关卡节点以读取自身等级）
	if guan_qia.helo != null and is_instance_valid(guan_qia.helo) and guan_qia.helo.has_method("shang_hai_hou"):
		guan_qia.helo.shang_hai_hou(guan_qia)
		# 力量加成后再刷新一次面板
		guan_qia.shu_wu_upd.emit()
	# 检查怪物是否死亡
	if guan_qia.GZ[guai_wu_y][guai_wu_x]["hp"] <= 0:
		# 如果没有死亡标签，则添加并执行死亡
		if guan_qia.GZ[guai_wu_y][guai_wu_x].get("si_wang", false) != true:
			guan_qia.GZ[guai_wu_y][guai_wu_x]["si_wang"] = true
			si_wang.guai_wu_die()

# 计算怪物对人物的伤害
func guai_wu_shang_hai_0(yan_chi: float = 0.2) -> void:
	await get_tree().create_timer(yan_chi).timeout
	# 场景已切换/释放中时终止协程
	if not is_inside_tree():
		return
	# 检查战斗是否还在进行
	if not zhan_dou_ing:
		return
	# 检查怪物坐标是否仍然是当前战斗的怪物
	if guai_wu_x < 0 or guai_wu_y < 0:
		return
	var helo = guan_qia.helo
	# 检查人物是否有效
	if helo == null or not is_instance_valid(helo):
		return
	var GZ = guan_qia.GZ
	# 获取怪物攻击属性
	var guai_wu_ll: float = GZ[guai_wu_y][guai_wu_x]["ll"]
	var guai_wu_ct: float = GZ[guai_wu_y][guai_wu_x]["ct"]
	var guai_wu_lv: float = GZ[guai_wu_y][guai_wu_x]["lv"]
	# 获取人物防御属性
	var helo_fy = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_fy, "fy")
	var helo_lv = guan_qia.helo_lv
	# 计算伤害：怪物力量×怪物穿透÷人物防御÷max(人物等级÷怪物等级,1)÷max(秒杀倍率,1)
	var shang_hai_zhi:float=guai_wu_ll*guai_wu_ct/helo_fy/max(helo_lv/guai_wu_lv,1.0)/max(zhan_dou_ming,1.0)
	# 伤害值取整（概率取整：小数部分决定额外1伤害的概率）
	var ji_shu: int = int(shang_hai_zhi)
	var gai_Lv: float = shang_hai_zhi - ji_shu
	if randf() < gai_Lv:
		ji_shu += 1
	# 应用伤害到人物
	guai_wu_shang_hai_1(ji_shu)

# 应用怪物对人物的伤害
func guai_wu_shang_hai_1(ji_shu: int) -> void:
	# 打印伤害信息
	var GZ = guan_qia.GZ
	var guai_wu_ll = GZ[guai_wu_y][guai_wu_x]["ll"]
	var guai_wu_ct = GZ[guai_wu_y][guai_wu_x]["ct"]
	var guai_wu_lv = GZ[guai_wu_y][guai_wu_x]["lv"]
	var helo_fy = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_fy, "fy")
	var helo_lv = guan_qia.helo_lv
	var shi_jian = (Time.get_ticks_msec() - zhan_dou_time) / 1000.0
	print("%.2f秒 怪物造成伤害：%d=%d×%d÷%d÷max(%d÷%d,1)÷max(%.2f,1)"%[shi_jian,ji_shu,guai_wu_ll,guai_wu_ct,helo_fy,helo_lv,guai_wu_lv,zhan_dou_ming])
	# 使用统一函数处理伤害（包含血条更新和飘字显示）
	shang_hai(0, 0, ji_shu, true)
	# 发出伤害信号刷新面板
	guan_qia.shu_wu_upd.emit()
	# BOSS攻击类技能（葵花王向阳/双狼王流血）
	ji_neng.gong_ji_ji_neng(guai_wu_x, guai_wu_y)
	# 检查人物是否死亡
	if guan_qia.helo_hp <= 0:
		guan_qia.helo_hp = 0
		# 统一处理人物死亡（含失败弹窗与结束战斗，逻辑在死亡处理.gd）
		si_wang.helo_si_wang()
	else:
		# 受常规伤害后启动角色受击特有技能（爱丽丝涅槃：0.2秒后概率回满血；真伤不走本函数故不触发）
		if guan_qia.helo != null and is_instance_valid(guan_qia.helo) and guan_qia.helo.has_method("nie_pan_pan_ding"):
			guan_qia.helo.nie_pan_pan_ding(self, ji_shu)
		# 场景已切换/释放中时不再使用恢复符
		if not is_inside_tree():
			return
		# 人物未死亡，延迟0.5秒后尝试使用恢复符
		await get_tree().create_timer(0.5).timeout
		# 检查战斗是否还在进行中
		if zhan_dou_ing:
			hui_fu_fu()

# 获取指定等级恢复符的单个回血量
func get_hui_fu_zhi(lv: int) -> int:
	# 等级超出1-6范围时返回0
	if lv < 1 or lv > hui_fu_zhi_biao.size() - 1:
		return 0
	return hui_fu_zhi_biao[lv]

# 战斗开始时自动使用恢复符（血量不足时）
func hui_fu_n() -> void:
	# 获取当前选定的恢复符等级
	var lv = guan_qia.guan_ui.hui_fu_lv
	if lv <= 0:
		return
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 检查恢复符数量
	var wu_ming = str(lv) + "级恢复符"
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		return
	# 获取恢复符回血量
	var hui_fu_zhi = get_hui_fu_zhi(lv)
	# 等级无效时不使用恢复符
	if hui_fu_zhi <= 0:
		return
	# 计算需要使用的恢复符数量
	var hp_que_que = guan_qia.helo_shp - guan_qia.helo_hp
	if hp_que_que <= 0:
		return
	# 计算需要多少个恢复符（向下取整，避免浪费）
	var shu_liang = int(floor(float(hp_que_que) / float(hui_fu_zhi)))
	# 获取当前拥有的恢复符数量
	var you_shu_liang = int(wu_pin[wu_ming])
	# 实际使用数量取两者最小值
	var shi_ji_shu_liang = min(shu_liang, you_shu_liang)
	if shi_ji_shu_liang <= 0:
		return
	# 计算总恢复量
	var zong_hui_fu = shi_ji_shu_liang * hui_fu_zhi
	# 使用恢复符
	wu_pin[wu_ming] = you_shu_liang - shi_ji_shu_liang
	# 如果数量变为0，删除该物品字段
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 恢复人物血量（使用总恢复量）
	hui_fu(0, 0, zong_hui_fu, true)
	# 打印恢复信息
	print("战斗开始 英雄使用%d个%s恢复生命：%d" % [shi_ji_shu_liang, wu_ming, zong_hui_fu])
	# 刷新面板
	guan_qia.shu_wu_upd.emit()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()
	# 如果用完了当前等级的恢复符，取消选定
	if not wu_pin.has(wu_ming):
		guan_qia.guan_ui.hui_fu_lv = 0
		guan_qia.guan_ui.dao_ju_upd()

# 执行恢复符效果
func hui_fu_fu() -> void:
	# 获取当前选定的恢复符等级
	var lv = guan_qia.guan_ui.hui_fu_lv
	if lv <= 0:
		return
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 检查恢复符数量
	var wu_ming = str(lv) + "级恢复符"
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		return
	# 获取恢复符回血量
	var hui_fu_zhi = get_hui_fu_zhi(lv)
	# 等级无效时不使用恢复符
	if hui_fu_zhi <= 0:
		return
	# 检查是否值得使用恢复符
	if (guan_qia.helo_shp - guan_qia.helo_hp) < hui_fu_zhi:
		return
	# 恢复
	var shi_ji_hui_fu = hui_fu_zhi
	# 使用恢复符
	wu_pin[wu_ming] = int(wu_pin[wu_ming]) - 1
	# 如果数量变为0，删除该物品字段
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 恢复人物血量
	hui_fu(0, 0, shi_ji_hui_fu, true)
	# 打印恢复信息
	var shi_jian = (Time.get_ticks_msec() - zhan_dou_time) / 1000.0
	print("%.2f秒 英雄恢复生命：%d" % [shi_jian, shi_ji_hui_fu])
	# 刷新面板
	guan_qia.shu_wu_upd.emit()
	# 刷新道具显示
	guan_qia.guan_ui.dao_ju_upd()
	# 如果用完了当前等级的恢复符，取消选定
	if not wu_pin.has(wu_ming):
		guan_qia.guan_ui.hui_fu_lv = 0
		guan_qia.guan_ui.dao_ju_upd()

# 开始撤退
func che_tui_0() -> void:
	# 只能在战斗中进行撤退
	if not zhan_dou_ing:
		return
	# 记录撤退时的回合数
	if che_tui_hui == 0:
		che_tui_hui = helo_hui
	# 设置撤退标记
	che_tui_ing = true
	print("%.2f秒 准备撤退" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0])

# 战斗回合
func zhan_dou_hui() -> void:
	helo_hui += 1
	# 每回合开始后台打印轮次与双方当前生命（怪物取BOSS/怪物主格数据）
	var GZ = guan_qia.GZ
	print("第%d轮" % helo_hui)
	print("%.2f秒 英雄当前生命：%d 怪物当前生命：%d" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0, guan_qia.helo_hp, GZ[guai_wu_y][guai_wu_x]["hp"]])
	# 判断条件：已点击撤退 且 记录过回合数 且 当前回合等于撤退回合+1
	if che_tui_ing and che_tui_hui > 0 and helo_hui == che_tui_hui + 1:
		print("%.2f秒 开始撤退" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0])
		# 开始人物待机计时
		che_tui_t = 0
		# 立即让人物进入待机状态
		var helo = guan_qia.helo
		if helo != null and is_instance_valid(helo):
			helo.attack = false
			helo.id += 1
			if helo.has_node("AnimatedSprite2D"):
				helo.get_node("AnimatedSprite2D").stop()
			helo.play_idle()
		# 开始撤退时反转人物方向
		chao_xiang(false, false, true)
		if che_tui_ing and helo_hui > che_tui_hui:
			# 1秒后执行撤退
			await get_tree().create_timer(1.0).timeout
			# 场景已切换/释放中时不再执行撤退
			if not is_inside_tree():
				return
			che_tui_1()

# 完成撤退
func che_tui_1() -> void:
	# 撤退成功，隐藏怪物血条
	xue_tiao_qi.xue_tiao_3.visible = false
	print("%.2f秒 撤退成功\n" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0])
	# 怪物待机
	if guai_wu_ing != null and is_instance_valid(guai_wu_ing):
		var GZ = guan_qia.GZ
		# 停止怪物攻击状态
		guai_wu_ing.attack = false
		# 刷新动画ID，避免播放相同动画
		guai_wu_ing.id += 1
		# 停止当前动画
		if guai_wu_ing.has_node("AnimatedSprite2D"):
			guai_wu_ing.get_node("AnimatedSprite2D").stop()
		# 播放待机动画
		guai_wu_ing.play_idle()
		# 恢复怪物方向
		chao_xiang(true)
		# 计算回血量并使用统一函数恢复
		var hui_fu_zhi = GZ[guai_wu_y][guai_wu_x]["shp"] - GZ[guai_wu_y][guai_wu_x]["hp"]
		hui_fu(guai_wu_x, guai_wu_y, hui_fu_zhi, false)
		xue_tiao_qi.xue_tiao_3.visible = false
	# 怪物死亡处理清除朝向标记
	fan1 = false
	fan2 = false
	# 人物回到初始位置
	guan_qia.helo_move(0, 0)
	# 清除撤退状态
	che_tui_ing = false
	che_tui_hui = 0
	# 调用通用结束战斗底层
	zhan_dou_end()

# 通用结束战斗底层
func zhan_dou_end() -> void:
	# 恢复朝向
	chao_xiang(true)
	# 清除战斗状态
	zhan_dou_ing = false
	guai_wu_ing = null
	guai_wu_x = -1
	guai_wu_y = -1
	guan_qia.guai_wu_x_ing = -1
	guan_qia.guai_wu_y_ing = -1
	# 清除BOSS战斗反转标记
	fan3 = false
	# 恢复撤退按钮图片
	guan_qia.guan_ui.che_tui.texture = guan_qia.guan_ui.che_tui_1
	# 隐藏撤退按钮
	guan_qia.guan_ui.che_tui.visible = false
	# 隐藏人物面板
	if guan_qia.look_helo:
		guan_qia.look_helo.visible = false
	if guan_qia.kuai_1:
		guan_qia.kuai_1.visible = false
	# 删除怪物面板
	if guan_qia.look_guai_wu != null:
		guan_qia.look_guai_wu.queue_free()
		guan_qia.look_guai_wu = null
	if guan_qia.kuai_2 != null:
		guan_qia.kuai_2.queue_free()
		guan_qia.kuai_2 = null
	var helo = guan_qia.helo
	if helo != null and is_instance_valid(helo):
		helo.play_idle()
		# 英雄战斗结束特殊技能（在角色文件中实现：爱丽丝回满血、玄戈重置战斗临时力量等）
		if helo.has_method("zhan_dou_end_ji_neng"):
			helo.zhan_dou_end_ji_neng(self)
