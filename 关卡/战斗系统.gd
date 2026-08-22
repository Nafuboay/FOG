# 【战斗系统】
class_name 战斗系统 extends Node
# 父节点引用（关卡节点），通过此属性访问关卡的数据和方法
var guan_qia: Node2D
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
# 信息相关
var tiao_kuang: Texture2D
var xue_tiao: Texture2D
var xue_tiao_0: TextureRect
var xue_tiao_1: TextureRect
var xue_tiao_2: AtlasTexture
var xue_tiao_x: int = 35
var xue_tiao_y: int = 4
var xue_tiao_x_BOSS: int = 70
var xue_tiao_y_BOSS: int = 8
var xue_tiao_3: TextureRect
var xue_tiao_4: TextureRect
var xue_tiao_5: AtlasTexture
var piao_zi_s: Array[Texture2D] = []
# 是否找到BOSS战斗位置的标记
var is_BOSS_xy: bool = false

# 获取父节点，如果父节点是容器则继续往上找真正的关卡节点
func _ready() -> void:
	var parent = get_parent()
	if parent.name != "关卡":
		parent = parent.get_parent()
	guan_qia = parent

# 加载血条资源
func load_xue_tiao_zi_yuan() -> void:
	tiao_kuang = load("res://关卡/信息/条框.png")
	xue_tiao = load("res://关卡/信息/HP1.png")
	for i in range(30):
		piao_zi_s.append(load("res://关卡/飘字/%02d.png" % i))

# 创建人物血条
func C_xue_tiao_1() -> void:
	# 创建血条背景框
	xue_tiao_0 = TextureRect.new()
	xue_tiao_0.texture = tiao_kuang
	xue_tiao_0.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xue_tiao_0.size = Vector2(xue_tiao_x, xue_tiao_y)
	# 添加到游戏容器
	guan_qia.rong_qi.add_child(xue_tiao_0)
	# 条框位置（基于人物所在格子，从1开始）
	var helo_x0 = guan_qia.helo_x - 1
	var helo_y0 = guan_qia.helo_y - 1
	var GZ_z = guan_qia.GZ_zhong(helo_x0, helo_y0)
	xue_tiao_0.position = Vector2(GZ_z.x-xue_tiao_0.size.x/2,GZ_z.y-74)
	# 设置血条层级为人物所在格的层级
	xue_tiao_0.z_index = (guan_qia.GZ_x - helo_x0) + helo_y0 * guan_qia.GZ_y
	# 创建满的血条显示节点
	xue_tiao_2 = AtlasTexture.new()
	xue_tiao_2.atlas = xue_tiao  # 原始血条图片
	xue_tiao_2.region = Rect2(0, 0, xue_tiao.get_width(), xue_tiao.get_height())
	# 使用裁剪后的纹理
	xue_tiao_1 = TextureRect.new()
	xue_tiao_1.texture = xue_tiao_2
	xue_tiao_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xue_tiao_1.size = Vector2(xue_tiao_x, xue_tiao_y)
	# 添加到血条容器中
	xue_tiao_0.add_child(xue_tiao_1)
	# 初始更新血条显示
	xue_tiao_upd_1()

# 更新人物血条显示
func xue_tiao_upd_1() -> void:
	if xue_tiao_1 == null or xue_tiao_0 == null:
		return
	# 人物死亡时隐藏血条
	if guan_qia.helo_hp <= 0:
		xue_tiao_0.visible = false
		return
	xue_tiao_0.visible = true
	# 计算HP百分比
	var hp_pct: float = 0.0
	if guan_qia.helo_shp > 0:
		hp_pct = float(guan_qia.helo_hp) / float(guan_qia.helo_shp)
	# 限制范围在0-1之间
	hp_pct = clamp(hp_pct, 0.0, 1.0)
	# 根据百分比计算显示宽度
	# 通过改变宽度来显示左边的部分
	xue_tiao_1.size = Vector2(xue_tiao_x * hp_pct, xue_tiao_y)

# 创建怪物血条
func C_xue_tiao_2() -> void:
	# 创建血条背景框（条框纹理）
	xue_tiao_3 = TextureRect.new()
	xue_tiao_3.texture = tiao_kuang
	xue_tiao_3.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xue_tiao_3.size = Vector2(xue_tiao_x, xue_tiao_y)
	# 默认隐藏，战斗开始时再显示
	xue_tiao_3.visible = false
	# 添加到游戏容器中
	guan_qia.rong_qi.add_child(xue_tiao_3)
	# 创建血条裁剪纹理（从完整血条图片中裁剪显示区域）
	xue_tiao_5 = AtlasTexture.new()
	xue_tiao_5.atlas = xue_tiao
	xue_tiao_5.region = Rect2(0, 0, xue_tiao.get_width(), xue_tiao.get_height())
	# 创建血条显示节点（实际的红色血条）
	xue_tiao_4 = TextureRect.new()
	xue_tiao_4.texture = xue_tiao_5
	xue_tiao_4.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xue_tiao_4.size = Vector2(xue_tiao_x, xue_tiao_y)
	# 将血条添加到背景框容器中
	xue_tiao_3.add_child(xue_tiao_4)

# 更新怪物血条位置和显示
func xue_tiao_upd_2(x: int, y: int) -> void:
	# 检查节点是否有效
	if xue_tiao_4 == null or xue_tiao_3 == null:
		return
	# 计算怪物所在格子的屏幕中心位置
	var GZ_z = guan_qia.GZ_zhong(x, y)
	# 获取怪物数据，判断是否是BOSS
	var GZ1 = guan_qia.GZ[y][x]
	var is_boss = GZ1.get("BOSS", false)
	# 根据是否是BOSS选择对应的尺寸
	var tiao_x = xue_tiao_x
	var tiao_y = xue_tiao_y
	if is_boss:
		tiao_x = xue_tiao_x_BOSS
		tiao_y = xue_tiao_y_BOSS
	# 设置血条尺寸
	xue_tiao_3.size = Vector2(tiao_x, tiao_y)
	# 设置血条位置（位于怪物头顶）
	if is_boss:
		xue_tiao_3.position = Vector2(GZ_z.x-17,GZ_z.y-76)
	else:
		xue_tiao_3.position = Vector2(GZ_z.x-17.5,GZ_z.y-74)
	# 设置血条层级（与怪物层级一致，确保显示在怪物上方）
	xue_tiao_3.z_index = (guan_qia.GZ_x - x) + y * guan_qia.GZ_y
	# 获取怪物的最大HP和当前HP
	var shp = GZ1.get("shp", 1)  # 最大HP
	var hp = GZ1.get("hp", 1)    # 当前HP
	# 如果怪物已死亡，隐藏血条
	if hp <= 0:
		xue_tiao_3.visible = false
		return
	# 显示血条
	xue_tiao_3.visible = true
	# 计算HP百分比
	var hp_pct = float(hp) / float(shp)
	# 限制范围在0-1之间
	hp_pct = clamp(hp_pct, 0.0, 1.0)
	# 根据百分比调整血条显示宽度（从左到右递减）
	xue_tiao_4.size = Vector2(tiao_x * hp_pct, tiao_y)

# 常规伤害
func shang_hai(x: int, y: int, zhi: int, is_helo: bool) -> void:
	if zhi < 0: # 伤害异常
		return
	if is_helo: # 是人物
		guan_qia.helo_hp -= zhi
		if guan_qia.helo_hp < 0:
			guan_qia.helo_hp = 0
		xue_tiao_upd_1() # 刷新人物血条
		# 人物伤害使用30-39图片（从1开始计数）
		piao_zi(guan_qia.helo_x - 1, guan_qia.helo_y - 1, zhi, false, false)
	else: # 是怪物
		var GZ1 = guan_qia.GZ[y][x]
		GZ1["hp"] -= zhi
		if GZ1["hp"] < 0:
			GZ1["hp"] = 0
		xue_tiao_upd_2(x, y) # 刷新怪物血条
		# 怪物伤害使用0-9图片
		piao_zi(x, y, zhi, false, true)

# 常规恢复
func hui_fu(x: int, y: int, zhi: int, is_helo: bool) -> void:
	if zhi < 1: # 恢复异常
		return
	if is_helo: # 是人物
		guan_qia.helo_hp += zhi
		if guan_qia.helo_hp > guan_qia.helo_shp:
			guan_qia.helo_hp = guan_qia.helo_shp
		xue_tiao_upd_1() # 刷新人物血条
		# 恢复使用10-19图片（从1开始计数）
		piao_zi(guan_qia.helo_x - 1, guan_qia.helo_y - 1, zhi, true, false)
	else: # 是怪物
		var GZ1 = guan_qia.GZ[y][x]
		GZ1["hp"] += zhi
		if GZ1["hp"] > GZ1["shp"]:
			GZ1["hp"] = GZ1["shp"]
		xue_tiao_upd_2(x, y) # 刷新怪物血条
		# 恢复使用10-19图片
		piao_zi(x, y, zhi, true, false)

# 飘字显示
func piao_zi(x: int, y: int, zhi: int, is_hui_fu: bool, is_helo: bool) -> void:
	# 将数值转换为字符串，便于逐个提取数字
	var zi_fu = str(zhi)
	# 是否已处理第一个数字（用于计算起始X坐标）
	var xy = false
	# 第一个数字图的左边缘位置
	var x_1 = 0
	# 遍历数值的每一位数字
	for i in zi_fu:
		# 将字符转换为数字
		var shu = int(i)
		# 图片索引：恢复用10-19，人物伤害用20-29，怪物伤害用0-9
		var id = shu
		if is_hui_fu:
			id += 10
		elif is_helo:
			id += 20
		# 创建TextureRect显示数字图片
		var tu_pian = TextureRect.new()
		tu_pian.texture = piao_zi_s[id]
		tu_pian.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# 设置飘字大小和间距
		tu_pian.size = Vector2(14,14)
		var n = 11
		# 计算格子中心位置
		var GZ_z = guan_qia.GZ_zhong(x, y)
		if not xy:
			x_1 = GZ_z.x-(n*(zi_fu.length()-1)+tu_pian.size.x)/2.0
			xy = true
		# 设置飘字位置和层级
		tu_pian.position = Vector2(x_1,GZ_z.y-72-tu_pian.size.y/2.0)
		tu_pian.z_index = (guan_qia.GZ_x - x) + y * guan_qia.GZ_y
		# 添加到游戏容器
		guan_qia.rong_qi.add_child(tu_pian)
		x_1 += n
		# 创建飘字动画
		var tween = create_tween()
		tween.tween_property(tu_pian,"position:y",tu_pian.position.y-300,2.5)
		tween.parallel().tween_property(tu_pian, "modulate:a", 0.0, 2.5)
		tween.tween_callback(tu_pian.queue_free)

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
	xue_tiao_upd_2(boss_x, boss_y)
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
	helo.play_attack()
	guai_wu_ing.play_attack()
	zhan_dou_time = Time.get_ticks_msec()
	print("\n战斗开始")

# 计算人物对怪物的伤害
func helo_shang_hai_0() -> void:
	if guan_qia.helo == null:
		return
	var helo_attack_n: int = guan_qia.helo.attack_n
	var time_interval: float = 0.2 / helo_attack_n
	for i in range(helo_attack_n):
		await get_tree().create_timer(time_interval).timeout
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

# 玄戈专用：每次伤害后力量+1
func shang_hai_hou() -> void:
	if guan_qia.helo.has_method("shang_hai_hou"):
		guan_qia.helo.shang_hai_hou()

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
	# 猛犸王【重甲】技能：受击减少防御
	var GZ = guan_qia.GZ
	# 检查当前攻击的怪物是否是猛犸王
	if GZ[guai_wu_y][guai_wu_x].get("guai_wu_id", "") == "猛犸王·犽翡":
		# 获取当前重甲防御加成
		var fy_add_4 = GZ[guai_wu_y][guai_wu_x].get("fy_add_4", 0)
		# 如果还有重甲加成
		if fy_add_4 > 0:
			# 获取BOSS等级
			var boss_lv = GZ[guai_wu_y][guai_wu_x].get("lv", 1)
			# 减少防御加成，最低为0
			fy_add_4 = max(0, fy_add_4 - boss_lv)
			# 获取BOSS左上角坐标
			var boss_x = int(GZ[guai_wu_y][guai_wu_x].get("BOSS_x", guai_wu_x))
			var boss_y = int(GZ[guai_wu_y][guai_wu_x].get("BOSS_y", guai_wu_y))
			# 更新猛犸王4个格子的防御加成和实际防御值
			for by in range(boss_y, boss_y + 2):
				for bx in range(boss_x, boss_x + 2):
					GZ[by][bx]["fy_add_4"] = fy_add_4  # 更新重甲加成
					GZ[by][bx]["fy"] -= boss_lv  # 减少实际防御
	# 蠃虫王【硬化】技能：受击增加防御
	if GZ[guai_wu_y][guai_wu_x].get("guai_wu_id", "") == "蠃虫王·犄眦":
		# 获取BOSS等级
		var boss_lv = GZ[guai_wu_y][guai_wu_x].get("lv", 1)
		# 获取当前硬化防御加成
		var fy_add_5 = GZ[guai_wu_y][guai_wu_x].get("fy_add_5", 0)
		# 增加防御加成
		fy_add_5 += boss_lv
		# 获取BOSS左上角坐标（BOSS占用2x2区域）
		var boss_x = int(GZ[guai_wu_y][guai_wu_x].get("BOSS_x", guai_wu_x))
		var boss_y = int(GZ[guai_wu_y][guai_wu_x].get("BOSS_y", guai_wu_y))
		# 更新蠃虫王4个格子的防御加成和实际防御值
		for by in range(boss_y, boss_y + 2):
			for bx in range(boss_x, boss_x + 2):
				GZ[by][bx]["fy_add_5"] = fy_add_5  # 更新石肤加成
				GZ[by][bx]["fy"] += boss_lv  # 增加实际防御
	# 邪花王【荆棘】技能：受击造成固定反伤
	if GZ[guai_wu_y][guai_wu_x].get("guai_wu_id", "") == "邪花王·荆冠":
		# 获取BOSS等级作为反伤伤害
		var fan_shang = GZ[guai_wu_y][guai_wu_x].get("lv", 1)
		# 延后执行反伤
		await get_tree().create_timer(0.05).timeout
		# 检查战斗是否还在进行
		if not zhan_dou_ing:
			return
		# 检查人物是否有效
		if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
			return
		# 打印反伤信息
		var time_2 = (Time.get_ticks_msec() - zhan_dou_time) / 1000.0
		print("%.2f秒 怪物造成反伤：%d" % [time_2, fan_shang])
		# 对人物造成反伤
		shang_hai(0, 0, fan_shang, true)
		# 发出伤害信号刷新面板
		guan_qia.shu_wu_upd.emit()
	# 发出伤害信号刷新面板
	guan_qia.shu_wu_upd.emit()
	# 调用伤害后处理（玄戈力量加成）
	shang_hai_hou()
	# 伤害后处理（玄戈力量加成）后再刷新一次面板
	if guan_qia.helo.has_method("shang_hai_hou"):
		guan_qia.shu_wu_upd.emit()
	# 检查怪物是否死亡
	if guan_qia.GZ[guai_wu_y][guai_wu_x]["hp"] <= 0:
		# 如果没有死亡标签，则添加并执行死亡
		if guan_qia.GZ[guai_wu_y][guai_wu_x].get("si_wang", false) != true:
			guan_qia.GZ[guai_wu_y][guai_wu_x]["si_wang"] = true
			guai_wu_die()

# 计算怪物对人物的伤害
func guai_wu_shang_hai_0(yan_chi: float = 0.2) -> void:
	await get_tree().create_timer(yan_chi).timeout
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
	if GZ[guai_wu_y][guai_wu_x].get("guai_wu_id", "") == "葵花王·槐昂":
		hp_add(guai_wu_x, guai_wu_y)
	if GZ[guai_wu_y][guai_wu_x].get("guai_wu_id", "") == "双狼王·睚狈":
		liu_xue()
	# 检查人物是否死亡
	if guan_qia.helo_hp <= 0:
		guan_qia.helo_hp = 0
		print("%.2f秒 英雄死亡\n" % shi_jian)
		# 人物死亡时添加破损稻草人到永久背包
		var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
		if json != null:
			var data = json.du_qu(guan_qia.json_id)
			var bei_bao = data.get("背包", {})
			if bei_bao.has("破损稻草人"):
				bei_bao["破损稻草人"] += 1
			else:
				bei_bao["破损稻草人"] = 1
			data["背包"] = bei_bao
			json.bao_cun(guan_qia.json_id, data)
		var helo = guan_qia.helo
		if helo != null:
			helo.queue_free()
			# 立即清除人物引用
			guan_qia.helo = null
		# 画面变暗并显示失败图片
		guan_qia.modulate = Color(0.5, 0.5, 0.5)
		for c in guan_qia.get_children():
			if c is CanvasLayer:
				for yun in c.get_children():
					yun.modulate = Color(0.5, 0.5, 0.5)
		var shi_bai = TextureRect.new()
		shi_bai.texture = load("res://关卡/信息/失败.png")
		shi_bai.position = Vector2(384, 104)
		shi_bai.z_index = 1000
		guan_qia.add_child(shi_bai)
		# 调用通用结束战斗底层
		zhan_dou_end()
	else:
		# 人物未死亡，延迟0.5秒后尝试使用恢复符
		await get_tree().create_timer(0.5).timeout
		# 检查战斗是否还在进行中
		if zhan_dou_ing:
			hui_fu_fu()

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
	var hui_fu_zhi = 0
	match lv:
		1:
			hui_fu_zhi = 1
		2:
			hui_fu_zhi = 3
		3:
			hui_fu_zhi = 7
		4:
			hui_fu_zhi = 20
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
	var hui_fu_zhi = 0
	match lv:
		1:
			hui_fu_zhi = 1
		2:
			hui_fu_zhi = 3
		3:
			hui_fu_zhi = 7
		4:
			hui_fu_zhi = 20
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
			che_tui_1()

# 完成撤退
func che_tui_1() -> void:
	# 撤退成功，隐藏怪物血条
	xue_tiao_3.visible = false
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
		xue_tiao_3.visible = false
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

# 怪物死亡处理
func guai_wu_die() -> void:
	# 记录怪物位置
	var die_x = guai_wu_x
	var die_y = guai_wu_y
	# 获取关卡数据引用
	var GZ = guan_qia.GZ
	var GZs = guan_qia.GZs
	var tile_fan_kai = guan_qia.tile_fan_kai
	var tile_shu_zi = guan_qia.tile_shu_zi
	# 打印怪物死亡时间
	var shi_jian = (Time.get_ticks_msec() - zhan_dou_time) / 1000.0
	print("%.2f秒 怪物死亡" % shi_jian)
	# 计算掉落并显示弹幕
	var diao_luo_ing = 掉落物.diao_luo_wu(guan_qia, die_x, die_y)
	# 在背包中显示掉落的物品（诛邪模式下可能不存在背包节点）
	var bao_bei = guan_qia.get_node_or_null("背包")
	if bao_bei != null:
		bao_bei.xian_shi_wu_pin(guan_qia.BB_ls)
	for wu_ming in diao_luo_ing:
		var n = diao_luo_ing[wu_ming]
		提示弹幕.wen_ben("获得【" + wu_ming + "】×" + str(n) + "！", 0)
	# 移除怪物节点
	if guai_wu_ing != null and is_instance_valid(guai_wu_ing):
		guai_wu_ing.queue_free()
		await get_tree().create_timer(0.05).timeout
	# 移除格子怪物数据
	GZ[die_y][die_x]["guai_wu"] = false
	# 如果是BOSS，同步属性到其他3个格子，然后清除BOSS标记
	if GZ[die_y][die_x]["BOSS"] == true:
		var boss_hp = GZ[die_y][die_x]["hp"]
		var boss_shp = GZ[die_y][die_x]["shp"]
		for ny in range(die_y, die_y + 2):
			for nx in range(die_x, die_x + 2):
				if ny == die_y and nx == die_x:
					continue
				GZ[ny][nx]["hp"] = boss_hp
				GZ[ny][nx]["shp"] = boss_shp
		# 清除BOSS标记
		for ny in range(die_y, die_y + 2):
			for nx in range(die_x, die_x + 2):
				GZ[ny][nx]["BOSS"] = false
		# BOSS宝箱
		C_BX(die_x, die_y)
	# 刷新格子
	guan_qia.shu_zi_n()
	for ny in range(max(0, die_y - 1), min(guan_qia.GZ_y, die_y + 2)):
		for nx in range(max(0, die_x - 1), min(guan_qia.GZ_x, die_x + 2)):
			var GZ2 = GZ[ny][nx]
			if GZ2["fan_kai"] == true:
				if GZ2["shu_zi"] == true:
					GZs[ny][nx].texture = tile_shu_zi[GZ2["number"] - 1]
				elif GZ2["kong_bai"] == true:
					GZs[ny][nx].texture = tile_fan_kai
					guan_qia.fan_kai.flood_fill(nx, ny)
	# 自动排雷、和弦
	guan_qia.fan_kai.pai_lei()
	guan_qia.fan_kai.he_xian()
	# 更新怪物数量
	var n_1 = 0
	var n_4 = 0
	for y in range(guan_qia.GZ_y):
		for x in range(guan_qia.GZ_x):
			var GZ1 = guan_qia.GZ[y][x]
			if GZ1.get("guai_wu", false) == true:
				n_1 += 1
			if GZ1.get("BOSS", false) == true:
				n_4 += 1
	guan_qia.guai_wu_xian = n_1 + int(n_4 / 4.0)
	# 更新怪物数量标签（诛邪模式下可能不存在）
	if guan_qia.guai_wu_lbl != null:
		guan_qia.guai_wu_lbl.text = "怪物数量：" + str(guan_qia.guai_wu_xian) + "/" + str(guan_qia.guai_wu_zong)
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
	# 检查胜利条件：人物存活且怪物数量为0
	if guan_qia.helo_hp > 0 and guan_qia.guai_wu_xian == 0:
		# 诛邪模式下：保存等级并重新进入关卡
		if guan_qia.has_method("_zhu_xie_win"):
			guan_qia._zhu_xie_win()
			return  # 不执行后续的helo_move等
		# 主线模式：显示胜利UI
		if guan_qia.guan_ui != null:
			guan_qia.guan_ui.C_sheng_li()
	# 怪物死亡特殊：先结束战斗，再清除朝向标记，最后人物移动到该格
	zhan_dou_end()
	fan1 = false
	fan2 = false
	guan_qia.helo_move(die_x, die_y)
	print("%.2f秒 战斗胜利\n" % ((Time.get_ticks_msec() - zhan_dou_time) / 1000.0))

# 葵花王【向阳】技能协程：战斗时回血
func hp_add(x: int, y: int) -> void:
	await get_tree().create_timer(0.5).timeout
	# 检查战斗是否还在进行
	if not zhan_dou_ing:
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
		print("%.2f秒 怪物恢复生命：%d" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0, hui_fu_liang])
		# 恢复怪物生命
		hui_fu(x, y, hui_fu_liang, false)
		# 发出伤害信号刷新面板
		guan_qia.shu_wu_upd.emit()

# 双狼王【流血】技能：攻击造成流血，可叠加
func liu_xue() -> void:
	await get_tree().create_timer(0.7).timeout
	# 检查战斗是否还在进行
	if not zhan_dou_ing:
		return
	# 检查人物是否有效
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	var GZ = guan_qia.GZ
	# 获取当前流血层数（使用get_meta支持默认值）
	var liu_xue_n = guan_qia.helo.get_meta("liu_xue_n", 0)
	# 获取怪物等级作为最高叠加次数
	var zui_gao_ceng_shu = GZ[guai_wu_y][guai_wu_x]["lv"]
	# 增加流血层数（不超过最高层数）
	liu_xue_n = min(liu_xue_n + 1, zui_gao_ceng_shu)
	# 更新流血层数（使用set_meta存储自定义属性）
	guan_qia.helo.set_meta("liu_xue_n", liu_xue_n)
	# 计算流血伤害：2 × 层数
	var shui_xue_shang_hai = 2 * liu_xue_n
	# 打印流血信息
	print("%.2f秒 怪物造成流血：%d（层数：%d）" % [(Time.get_ticks_msec() - zhan_dou_time) / 1000.0, shui_xue_shang_hai, liu_xue_n])
	# 对人物造成流血伤害
	shang_hai(0, 0, shui_xue_shang_hai, true)
	# 发出伤害信号刷新面板
	guan_qia.shu_wu_upd.emit()

# BOSS死亡后生成宝箱
func C_BX(boss_x: int, boss_y: int) -> void:
	var n_x = boss_x
	var n_y = boss_y + 1
	# 检查目标格子是否有效
	if n_x < 0 or n_x >= guan_qia.GZ_x or n_y < 0 or n_y >= guan_qia.GZ_y:
		return
	# 获取BOSS名称
	var boss_ming = guan_qia.GZ[boss_y][boss_x].get("名字", "")
	# 创建宝箱节点
	var n = Sprite2D.new()
	n.name = "BOSS宝箱"
	# 加载宝箱图片
	n.texture = load("res://关卡/信息/宝箱.png")
	# 计算宝箱位置（格子中心往上偏10像素）
	var GZ_z = guan_qia.GZ_zhong(n_x,n_y)
	n.position = GZ_z - Vector2(0, 10)
	# 设置层级：与该格子层级一致
	n.z_index = (guan_qia.GZ_x - n_x) + n_y * guan_qia.GZ_y
	# 添加到游戏容器
	guan_qia.rong_qi.add_child(n)
	# 在格子数据中标记有宝箱、宝箱名称和开启次数
	guan_qia.GZ[n_y][n_x]["BX"] = true
	guan_qia.GZ[n_y][n_x]["BX_id"] = boss_ming
	guan_qia.GZ[n_y][n_x]["BX_n"] = 0

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
		# 如果是爱丽丝，战斗结束后生命回满
		if helo.name == "爱丽丝":
			var hui_fu_zhi = guan_qia.helo_shp - guan_qia.helo_hp
			hui_fu(0, 0, hui_fu_zhi, true)
			guan_qia.shu_wu_upd.emit()
		# 如果是玄戈，战斗结束后重置战斗临时力量加成
		if helo.name == "玄戈":
			guan_qia.helo.ll_add_1 = 0
			guan_qia.shu_wu_upd.emit()
