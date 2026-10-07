# 【诛邪模式】关卡逻辑
# 继承关卡基类，覆盖网格生成和怪物生成等方法
extends 关卡基类
# 诛邪模式特有变量
var zx_lv: int = 1  # 诛邪模式下当前关卡的等级
var zx_monster_name: String = ""  # 诛邪模式下该关的怪物名称
# 每关对应的新怪物名称（与选关面板guai_wu_dong_hua数组顺序一致）
# 索引0=第1关，索引1=第2关（禁用），以此类推
const ZX_GUAI_WU_MING = [
	"紫蠃", "", "邪嘴唇花", "紫蠃贤者", "红巨蟹",
	"褐巨蟹", "橙食人花", "紫食人花", "青巨蟹", "紫巨蟹",
	"蓝巨蟹", "蓝蠃勇者", "白鬣野猪", "白鬣赤猪", "紫蠃勇者",
	"茶鬣野猪", "褐蠃长老", "绿鬣野猪", "黄斑野猪", "黯灰狼",
	"靛苍狼", "粉褐狼", "冰河狼", "邪花王·荆冠", "葵花王·槐昂",
	"野猪王·冕笑", "蠃虫王·犄眦", "双狼王·睚狈", "猛犸", "猛犸王·犽翡"
]

# 重写_ready()：诛邪模式使用5×3网格
func _ready() -> void:
	# 检查是否为诛邪模式
	var is_zx = false
	if has_node("/root/数据管理"):
		is_zx = get_node("/root/数据管理").mode == 1
	if is_zx:
		# 诛邪模式：手动加载关卡数据（跳过主线剧情弹幕）
		_zx_du_qu_guan_kia()
		# 诛邪模式：设置固定网格（7×7）
		GZ_x = 7
		GZ_y = 7
		# 英雄初始位置：(2,4)，1-based所以直接设为2和4
		helo_x = 2
		helo_y = 4
		# 清空怪物数量配置
		guai_wu_n = []
		# 获取诛邪等级（从场景树获取已有的游戏存档节点）
		var json = get_node_or_null("/root/游戏存档")
		if json == null:
			json = load("res://主界面/游戏存档.gd").new()
			json.name = "游戏存档"
			get_tree().root.add_child(json)
		json.get_dang_wei()
		zx_lv = json.get_zx_lv(guan_kia_id + 1)
		# 从映射表获取该关的新怪物（每关首次解锁的怪物）
		if guan_kia_id >= 0 and guan_kia_id < ZX_GUAI_WU_MING.size():
			zx_monster_name = ZX_GUAI_WU_MING[guan_kia_id]
		else:
			zx_monster_name = "紫蠃"
	else:
		# 主线模式：正常调用基类方法
		du_qu_guan_kia()
	# 调用后续逻辑
	_zhu_xie_ready()

# 诛邪模式专用的数据读取（跳过主线剧情弹幕）
func _zx_du_qu_guan_kia() -> void:
	# 检查并创建存档文件夹
	var json = load("res://主界面/游戏存档.gd").new()
	json.wen_jian_jia()
	json.free()
	# 从数据管理节点读取关卡ID
	if has_node("/root/数据管理"):
		guan_kia_id = get_node("/root/数据管理").stg
	# 获取关卡数据
	guan_kia = 关卡数据.guan_kia(guan_kia_id)
	# 设置网格大小
	GZ_x = guan_kia.get("x", 9)
	GZ_y = guan_kia.get("y", 9)
	# 获取怪物生成数量
	guai_wu_n = guan_kia.get("guai_wu_n", [10])
	# 获取障碍物数量
	zhang_ai_n0 = guan_kia.get("zhang_ai_n", 0)
	# 获取BOSS生成数量
	BOSS = guan_kia.get("BOSS", [])
	BOSS_n = guan_kia.get("BOSS_n", [0])

# 诛邪模式的_ready()后续逻辑（复制关卡基类_ready()的剩余部分）
func _zhu_xie_ready() -> void:
	# 获取视口尺寸
	var viewport_size = get_viewport_rect().size
	# 计算网格居中偏移
	WG_pian_yi_x = -GZ_x * GZ_size / 2.0
	WG_pian_yi_y = -GZ_y * GZ_size / 2.0
	# 加载背景图片
	var canvas = CanvasLayer.new()
	canvas.layer = -1
	add_child(canvas)
	var yun_hai = TextureRect.new()
	yun_hai.texture = load("res://关卡/云海.png")
	yun_hai.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(yun_hai)
	# 创建游戏内容容器
	rong_qi = Node2D.new()
	rong_qi.name = "GameContainer"
	rong_qi.position = viewport_size / 2
	add_child(rong_qi)
	# 加载图片资源
	load_zi_yuan()
	# 实例化战斗系统
	zhan_dou = 战斗系统.new()
	rong_qi.add_child(zhan_dou)
	# 实例化翻开系统
	fan_kai = 翻开系统.new()
	rong_qi.add_child(fan_kai)
	# 实例化关卡UI
	guan_ui = 关卡UI.new()
	add_child(guan_ui)
	# 实例化信息面板
	XX = 信息面板.new()
	add_child(XX)
	# 加载输入处理模块
	var pc_input = load("res://关卡/PC输入.gd").new()
	pc_input.name = "PC输入"
	add_child(pc_input)
	# 诛邪模式特殊初始化：显示提示
	var ti_shi = "诛邪·%d级" % [zx_lv]
	提示弹幕.wen_ben(ti_shi, 0)
	# 创建游戏数据网格（使用重写的C_GZ）
	C_GZ()
	# 连接伤害信号到面板刷新
	shu_wu_upd.connect(XX.on_shu_wu_upd)
	# 创建格子可视化对象
	C_GZ1()
	# 刷新所有格子贴图为已翻开（消除迷雾）
	shu_xing_tie_tu()
	# 创建人物
	C_helo()
	# 创建人物面板
	XX.C_look_helo()
	# 创建缩放按钮
	guan_ui.C_rong_qi()
	# 创建重新挑战按钮
	guan_ui.C_again()
	# 诛邪模式：地图默认缩放为317%档位
	var zx_suo_fang = pow(2.0, 5.0 / 3.0)
	rong_qi.scale = Vector2(zx_suo_fang, zx_suo_fang)
	suo_fang_lal.text = "画面比例：%d%%" % round(zx_suo_fang * 100)
	# 诛邪模式：按等级比例调整人物和怪物大小
	_zhu_xie_scale()

# 重写C_GZ()：诛邪模式下只生成1只怪物
func C_GZ() -> void:
	# 清空现有数据
	GZ.clear()
	guai_wu_xy.clear()
	guai_wu.clear()
	zhang_ai_xy.clear()
	BOSS_xy.clear()
	# 遍历每一行
	for y in range(GZ_y):
		var row = []
		for x in range(GZ_x):
			row.append({
				"number": 0,
				"fan_kai": true,
				"shu_zi": false,
				"kong_bai": true,
				"guai_wu": false,
				"NPC": false,
				"biao_ji": false,
				"da": false,
				"xiao": false,
				"zhang_ai": false,
				"BOSS": false,
				"BX": false,
				"lv": 1,
				"shp": 1,
				"hp": 1,
				"ll": 1,
				"fy": 1,
				"ct": 1
			})
		GZ.append(row)
	# 诛邪模式：只生成1只特殊怪物
	_zhu_xie_guai_wu()
	# 诛邪模式：四角固定生成魔法树
	_zhu_xie_shu()
	# 怪物总数量
	guai_wu_zong = guai_wu_xy.size()
	guai_wu_xian = guai_wu_zong
	# 创建关卡标签
	guan_ui.C_guan_kia_lbl()

# 刷新所有格子贴图为已翻开（消除迷雾）
func shu_xing_tie_tu() -> void:
	for y in range(GZ_y):
		for x in range(GZ_x):
			if GZs[y][x] != null:
				# 魔法树格子使用紫地版本的已翻开图片
				if GZ[y][x].get("zhang_ai", false) and tile_fan_kai_zi != null:
					GZs[y][x].texture = tile_fan_kai_zi
				else:
					GZs[y][x].texture = tile_fan_kai
	# 显示四角魔法树贴图（只有主格显示树精灵）
	for shu in zhang_ai_xy:
		var sx = int(shu.x)
		var sy = int(shu.y)
		if zhang_ai[sy][sx] != null:
			zhang_ai[sy][sx].visible = true

# 诛邪模式的怪物生成（只生成1只特殊怪物）
func _zhu_xie_guai_wu() -> void:
	# 怪物位置固定在中心(4,4) → 网格索引(3,3)
	var monster_x = 3
	var monster_y = 3
	# 标记该格子为怪物，并设置相关属性
	GZ[monster_y][monster_x]["guai_wu"] = true
	GZ[monster_y][monster_x]["guai_wu_id"] = zx_monster_name
	GZ[monster_y][monster_x]["名字"] = zx_monster_name  # 信息面板读取此字段
	GZ[monster_y][monster_x]["kong_bai"] = false  # 怪物格不可直接进入
	guai_wu_xy.append(Vector2(monster_x, monster_y))
	# 读取怪物基础属性
	var lu_jing = 关卡数据.get_tscn(zx_monster_name)
	var guai_wu1 = load(lu_jing).instantiate()
	# 存储网格坐标到怪物节点（战斗系统通过此查找怪物）
	guai_wu1.set_meta("grid_x", monster_x)
	guai_wu1.set_meta("grid_y", monster_y)
	# 诛邪模式下怪物等级 = 基础等级 × 诛邪等级
	GZ[monster_y][monster_x]["lv"] = guai_wu1.LV * zx_lv
	GZ[monster_y][monster_x]["shp"] = guai_wu1.HP * zx_lv
	GZ[monster_y][monster_x]["hp"] = guai_wu1.HP * zx_lv
	GZ[monster_y][monster_x]["ll"] = guai_wu1.LL * zx_lv
	GZ[monster_y][monster_x]["fy"] = guai_wu1.FY * zx_lv
	GZ[monster_y][monster_x]["ct"] = guai_wu1.CT * zx_lv
	# BOSS技能初始化（主线与诛邪通用，逻辑在特殊技能.gd：猛犸王【重甲】等依赖初始字段的技能）
	特殊技能_SCRIPT.BOSS_ji_neng_chu_shi(GZ[monster_y][monster_x], zx_monster_name, GZ[monster_y][monster_x]["lv"])
	# 计算怪物显示位置
	var GZ_z = GZ_zhong(monster_x, monster_y)
	var suo_fang = 1.0
	var pian_yi_x1 = role_pian_yi_x * suo_fang
	var pian_yi_y1 = role_pian_yi_y * suo_fang
	guai_wu1.position = Vector2(GZ_z.x - pian_yi_x1, GZ_z.y - pian_yi_y1)
	guai_wu1.z_index = (GZ_x - monster_x) + monster_y * GZ_y
	guai_wu1.scale = Vector2(suo_fang, suo_fang)
	rong_qi.add_child(guai_wu1)
	guai_wu.append(guai_wu1)
	if guai_wu1.has_node("AnimatedSprite2D"):
		var dong_hua = guai_wu1.get_node("AnimatedSprite2D")
		if dong_hua.sprite_frames and dong_hua.sprite_frames.has_animation("idle"):
			dong_hua.play("idle")

# 诛邪模式：四角固定生成魔法树（每颗占2×2共4格）
func _zhu_xie_shu() -> void:
	# 四角主格坐标（0-based网格索引，主格为左上角，向右下扩展2×2）
	var jiao = [Vector2(0, 0), Vector2(5, 0), Vector2(0, 5), Vector2(5, 5)]
	for shu in jiao:
		var sx = int(shu.x)
		var sy = int(shu.y)
		# 标记2×2区域为障碍（kong_bai必须为false，否则move_xy会把树格当作可走格）
		for ny in range(sy, sy + 2):
			for nx in range(sx, sx + 2):
				GZ[ny][nx]["zhang_ai"] = true
				GZ[ny][nx]["kong_bai"] = false
		# 记录主格位置（树贴图显示与信息面板使用）
		zhang_ai_xy.append(shu)

# 诛邪模式：按等级比例调整人物和怪物大小
func _zhu_xie_scale() -> void:
	# 怪物等级（从网格数据读取）
	var monster_lv = 1
	if guai_wu_xy.size() > 0:
		var xy = guai_wu_xy[0]
		monster_lv = GZ[int(xy.y)][int(xy.x)].get("lv", 1)
	# 人物等级
	var helo_lv_now = helo_lv
	# 计算等级比例：大等级 = 1倍，小等级 = m/n倍
	if monster_lv > helo_lv_now:
		# 怪物等级大：人物缩小，同步调整偏移量
		var bi_li = helo_lv_now / float(monster_lv)
		helo.scale = helo.scale * bi_li
		role_pian_yi_x = 17 * bi_li
		role_pian_yi_y = 46 * bi_li
		# 重设人物初始位置（用调整后的偏移量）
		var helo_x0 = helo_x - 1
		var helo_y0 = helo_y - 1
		var GZ_z = GZ_zhong(helo_x0, helo_y0)
		helo.position = Vector2(GZ_z.x + role_pian_yi_x, GZ_z.y - role_pian_yi_y)
	else:
		# 人物等级大或相等：怪物缩小，同步重设位置
		var bi_li = monster_lv / float(helo_lv_now)
		if guai_wu.size() > 0:
			# 先按新缩放计算位置（与主线创建逻辑一致）
			var xy = guai_wu_xy[0]
			var GZ_z = GZ_zhong(int(xy.x), int(xy.y))
			var pian_yi_x1 = role_pian_yi_x * bi_li
			var pian_yi_y1 = role_pian_yi_y * bi_li
			guai_wu[0].position = Vector2(GZ_z.x - pian_yi_x1, GZ_z.y - pian_yi_y1)
			# 再设置缩放
			guai_wu[0].scale = Vector2(bi_li, bi_li)

# 击败怪物后提升等级并保存
func _zhu_xie_win() -> void:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		json = load("res://主界面/游戏存档.gd").new()
		json.name = "游戏存档"
		get_tree().root.add_child(json)
	json.get_dang_wei()
	json.upd_zx_lv(guan_kia_id + 1)
	# 将临时背包掉落物合并写入存档（重进关卡前保存，防止掉落丢失）
	if not BB_ls.is_empty():
		var data = json.du_qu(json.id)
		var wu_pin = data.get("背包", {})
		for wu_ming in BB_ls:
			var n = int(BB_ls[wu_ming])
			# 已有该物品则累加，没有则新增
			if wu_pin.has(wu_ming):
				wu_pin[wu_ming] = int(wu_pin[wu_ming]) + n
			else:
				wu_pin[wu_ming] = n
		data["背包"] = wu_pin
		json.bao_cun(json.id, data)
	zx_lv += 1
	# 刷新显示（重新进入关卡）
	get_tree().change_scene_to_file("res://关卡/诛邪.tscn")
