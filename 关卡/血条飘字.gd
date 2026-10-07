# 【血条飘字】战斗画面上的血条与飘字显示模块（主线与诛邪通用）
# 从战斗系统剥离的纯显示逻辑：人物血条、怪物血条、伤害/恢复飘字动画
# 与特殊技能.gd同模式：RefCounted持有关卡与战斗系统引用，通过preload路径使用
extends RefCounted

# 关卡节点引用（访问GZ网格数据、格子中心GZ_zhong、人物属性、游戏容器rong_qi等）
var guan_qia: Node2D
# 战斗系统引用（用于create_tween创建飘字动画）
var zhan_dou: Node

# 条框纹理（血条背景框）
var tiao_kuang: Texture2D
# 血条纹理（完整的HP条图片，用于AtlasTexture裁剪）
var xue_tiao: Texture2D
# 人物血条背景框节点
var xue_tiao_0: TextureRect
# 人物血条显示节点（通过改变宽度显示左边部分）
var xue_tiao_1: TextureRect
# 人物血条裁剪纹理
var xue_tiao_2: AtlasTexture
# 血条尺寸（普通单位）
var xue_tiao_x: int = 35
var xue_tiao_y: int = 4
# 血条尺寸（BOSS更大）
var xue_tiao_x_BOSS: int = 70
var xue_tiao_y_BOSS: int = 8
# 怪物血条背景框节点（战斗时显示在怪物头顶）
var xue_tiao_3: TextureRect
# 怪物血条显示节点
var xue_tiao_4: TextureRect
# 怪物血条裁剪纹理
var xue_tiao_5: AtlasTexture
# 飘字数字图片数组（0-9怪物伤害、10-19恢复、20-29人物伤害、30-39真伤）
var piao_zi_s: Array[Texture2D] = []

# 初始化：传入关卡节点和战斗系统
func _init(gq: Node2D, zd: Node) -> void:
	guan_qia = gq
	zhan_dou = zd

# 加载血条资源
func load_xue_tiao_zi_yuan() -> void:
	tiao_kuang = load("res://关卡/信息/条框.png")
	xue_tiao = load("res://关卡/信息/HP1.png")
	for i in range(40):
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

# 飘字显示
# is_zhen_shang=true时使用30-39灰色真伤飘字（优先级高于恢复/人物伤害）
func piao_zi(x: int, y: int, zhi: int, is_hui_fu: bool, is_helo: bool, is_zhen_shang: bool = false) -> void:
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
		# 图片索引：真伤用30-39，恢复用10-19，人物伤害用20-29，怪物伤害用0-9
		var id = shu
		if is_zhen_shang:
			id += 30
		elif is_hui_fu:
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
		# 创建飘字动画（RefCounted没有create_tween，通过战斗系统节点创建）
		var tween = zhan_dou.create_tween()
		tween.tween_property(tu_pian,"position:y",tu_pian.position.y-300,2.5)
		tween.parallel().tween_property(tu_pian, "modulate:a", 0.0, 2.5)
		tween.tween_callback(tu_pian.queue_free)
