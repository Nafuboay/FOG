# 【诛邪模式】关卡逻辑
# 继承关卡基类，覆盖网格生成和怪物生成等方法
extends 关卡基类

# 诛邪模式特有变量
var zx_lv: int = 1  # 诛邪模式下当前关卡的等级
var zx_monster_name: String = ""  # 诛邪模式下该关的怪物名称

# 重写_ready()：诛邪模式使用5×3网格
func _ready() -> void:
	# 先调用关卡基类的数据读取方法（加载guan_kia_id, guan_kia等）
	du_qu_guan_kia()
	# 检查是否为诛邪模式
	if has_node("/root/数据管理"):
		var mode = get_node("/root/数据管理").mode
		if mode == 1:
			# 诛邪模式：设置固定网格
			GZ_x = 5
			GZ_y = 3
			# 英雄初始位置：(2,2) → 网格索引(1,1)，1-based所以设为2
			helo_x = 2
			helo_y = 2
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
			# 第一关强行固定为紫蠃，保证不依赖数据加载
			if guan_kia_id == 0:
				zx_monster_name = "紫蠃"
			else:
				# 其他关卡从关卡数据获取第一个怪物
				zx_monster_name = guan_kia.get("guai_wu", ["紫蠃"])[0]
	# 调用诛邪模式的_ready()后续逻辑
	_zhu_xie_ready()

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
	var ti_shi = "诛邪模式 - 第%d关 - 等级%d" % [guan_kia_id + 1, zx_lv]
	提示弹幕.wen_ben(ti_shi, 1)
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
				GZs[y][x].texture = tile_fan_kai

# 诛邪模式的怪物生成（只生成1只特殊怪物）
func _zhu_xie_guai_wu() -> void:
	# 怪物位置固定在(4,2) → 网格索引(3,1)
	var monster_x = 3
	var monster_y = 1
	# 标记该格子为怪物
	GZ[monster_y][monster_x]["guai_wu"] = true
	GZ[monster_y][monster_x]["guai_wu_id"] = zx_monster_name
	guai_wu_xy.append(Vector2(monster_x, monster_y))
	# 读取怪物基础属性
	var lu_jing = 关卡数据.get_tscn(zx_monster_name)
	var guai_wu1 = load(lu_jing).instantiate()
	# 诛邪模式下怪物等级 = 基础等级 × 诛邪等级
	GZ[monster_y][monster_x]["lv"] = guai_wu1.LV * zx_lv
	GZ[monster_y][monster_x]["shp"] = guai_wu1.HP * zx_lv
	GZ[monster_y][monster_x]["hp"] = guai_wu1.HP * zx_lv
	GZ[monster_y][monster_x]["ll"] = guai_wu1.LL * zx_lv
	GZ[monster_y][monster_x]["fy"] = guai_wu1.FY * zx_lv
	GZ[monster_y][monster_x]["ct"] = guai_wu1.CT * zx_lv
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

# 击败怪物后提升等级并保存
func _zhu_xie_win() -> void:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		json = load("res://主界面/游戏存档.gd").new()
		json.name = "游戏存档"
		get_tree().root.add_child(json)
	json.get_dang_wei()
	json.upd_zx_lv(guan_kia_id + 1)
	zx_lv += 1
	# 刷新显示（重新进入关卡）
	get_tree().change_scene_to_file("res://关卡/诛邪.tscn")