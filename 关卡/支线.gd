# 【支线模式】关卡逻辑
# 与主线共用同一套关卡数据：地图尺寸、怪物配置、BOSS配置全部沿用主线
# 与主线的差异有四类：
#   1. 属性倍率：排雷怪×3、踩雷怪×4（等级/生命/力量/防御/穿透）
#      显示大小：排雷0.75，踩雷1.0
#      BOSS：等级×4、血量 = 基础HP×32×BOSS等级（=×128）、大小2
#   2. 生成逻辑：不生成魔法树，改为生成奇花（每棵原魔法树对应 4 种花各 1 株，
#      总数 = zhang_ai_n0 × 4 朵；摆放顺序 BOSS → 奇花 → 普通怪物）
#   3. 花香加成：普通怪扫周围 8 格，BOSS 扫周围 12 格，分别累加
#   4. 采摘：点花→英雄瞬移到花格→1% 成功（花消失+临时背包+1该花+至多99非致命伤害）
#      99% 失败（花消失+恢复1生命 满血不回）；花消失清除本朵花对周围怪物的加成
# 胜利流程用支线专属 _zhi_xian_win()，经验/进度/存档单独处理

extends 关卡基类

# ---- 夜晚遮罩：以英雄所在格中心为点光源，向外加深至全黑 ----
const 夜晚遮罩_SHADER = preload("res://关卡/夜晚遮罩.gdshader")
# 光圈半径（格）。每帧按当前屏幕格距换算
const 夜晚_半径格数: float = 3.0
# 圆外黑度（1 = 全黑）
const 夜晚_外圈黑度: float = 1.0
# 遮罩节点与材质（用 Sprite2D 而非 Control，避免被 PC输入 的 GUI 点击检测当成控件拦截点击）
var ye_wan_zhe_zhao: Sprite2D = null
var ye_wan_cai_zhi: ShaderMaterial = null
# 当前光圈中心的屏幕坐标（平滑跟随英雄所在格）
var ye_wan_zhong_xin: Vector2 = Vector2.ZERO

# ---- 覆写 _ready：先设支线倍率，再执行基类 _ready（C_GZ 内会调用我们覆写的生成函数）----
func _ready() -> void:
	_zhi_xian_bei_zhi()
	super()
	# 基类初始化完成后再挂夜晚遮罩（此时人物/容器已创建）
	C_ye_wan_zhe_zhao()

# 创建夜晚遮罩：全屏 Sprite2D + 径向暗角 shader
# 层级 500：高于世界内容（格子/怪物 z_index ≤ 约90）、低于关卡UI（1000）
func C_ye_wan_zhe_zhao() -> void:
	ye_wan_zhe_zhao = Sprite2D.new()
	ye_wan_zhe_zhao.centered = false
	ye_wan_zhe_zhao.position = Vector2.ZERO
	# 1×1 纯白纹理靠缩放铺满全屏（shader 直接输出颜色，与纹理无关）
	var bai = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	bai.fill(Color.WHITE)
	ye_wan_zhe_zhao.texture = ImageTexture.create_from_image(bai)
	ye_wan_zhe_zhao.scale = get_viewport_rect().size
	ye_wan_zhe_zhao.z_index = 500
	ye_wan_cai_zhi = ShaderMaterial.new()
	ye_wan_cai_zhi.shader = 夜晚遮罩_SHADER
	ye_wan_cai_zhi.set_shader_parameter("outer_radius", 夜晚_半径格数 * ge_jian_ping_mu())
	ye_wan_cai_zhi.set_shader_parameter("darkness", 夜晚_外圈黑度)
	ye_wan_zhe_zhao.material = ye_wan_cai_zhi
	add_child(ye_wan_zhe_zhao)
	# 初始中心直接对准英雄所在格中心，避免第一帧从屏幕左上角滑入
	ye_wan_zhong_xin = ge_zhong_xin_ping_mu()
	ye_wan_cai_zhi.set_shader_parameter("center", ye_wan_zhong_xin)

# 每帧更新光圈中心与半径：中心平滑跟随英雄格，半径随画面比例换算
func _process(delta: float) -> void:
	if ye_wan_cai_zhi == null:
		return
	var mu_biao = ge_zhong_xin_ping_mu()
	# 与帧率无关的指数平滑
	ye_wan_zhong_xin = ye_wan_zhong_xin.lerp(mu_biao, 1.0 - exp(-12.0 * delta))
	ye_wan_cai_zhi.set_shader_parameter("center", ye_wan_zhong_xin)
	# 按当前格距换算半径：缩小/放大画面时始终保持设定格数
	ye_wan_cai_zhi.set_shader_parameter("outer_radius", 夜晚_半径格数 * ge_jian_ping_mu())

# 英雄所在格中心的屏幕坐标（helo_x/helo_y 从 1 开始，GZ_zhong 用 0 基索引）
func ge_zhong_xin_ping_mu() -> Vector2:
	if helo == null:
		return get_viewport_rect().size / 2.0
	var ju_bu = GZ_zhong(helo_x - 1, helo_y - 1)
	if rong_qi != null:
		ju_bu = rong_qi.to_global(ju_bu)
	return get_viewport().get_canvas_transform() * ju_bu

# 一格在屏幕上的像素宽度（含关卡画面比例缩放与画布变换）
func ge_jian_ping_mu() -> float:
	if rong_qi == null:
		return float(GZ_size)
	var bian_huan = get_viewport().get_canvas_transform()
	var jichu = bian_huan * rong_qi.to_global(GZ_zhong(0, 0))
	var lin = bian_huan * rong_qi.to_global(GZ_zhong(1, 0))
	return (lin - jichu).length()

# ---- 支线专属属性倍率 ----
func _zhi_xian_bei_zhi() -> void:
	pai_lei_bei = 3
	pai_lei_scale = 0.75
	cai_lei_bei = 4
	cai_lei_scale = 1.0
	BOSS_lv_bei = 4
	BOSS_xue_bei = 32.0
	BOSS_scale = 2.0

# ---- 支线覆写：不再生成魔法树，改为由花取代 ----
func zhang_ai_n(_n: int) -> void:
	# 支线没有魔法树，直接返回；花在 sheng_cheng_BOSS() 之后按 zhang_ai_n0×4 生成
	return

# ---- 支线覆写：先生成 BOSS（与主线/诛邪相同），再生成 4×zhang_ai_n0 朵奇花 ----
func sheng_cheng_BOSS() -> void:
	super()
	# 花贴图由奇花系统管理（load_zi_yuan 时已加载）；无花贴图或无树数量就不生成花
	if qi_hua == null or qi_hua.tile_hua.is_empty():
		return
	qi_hua.hua_sheng_cheng(zhang_ai_n0)

# ---- 支线覆写：收集可用位置时跳过已被花占用的格子 ----
func guai_wu_n0() -> void:
	var min_x = helo_x - 1
	var max_x = helo_x
	var min_y = helo_y - 1
	var max_y = helo_y
	var guai_wu_fan_wei = []
	for y in range(GZ_y):
		for x in range(GZ_x):
			if x >= min_x and x <= max_x and y >= min_y and y <= max_y:
				continue
			if GZ[y][x]["BOSS"] == true:
				continue
			if GZ[y][x].get("hua", false) == true:
				continue  # 花先于怪物放置，怪物要避开花格
			guai_wu_fan_wei.append(Vector2(x, y))
	guai_wu_fan_wei.shuffle()
	var n2 = guan_kia.get("guai_wu", ["null"])
	var n0 = 0
	for n1 in range(n2.size()):
		var n3 = n2[n1]
		var n4 = 0
		if n1 < guai_wu_n.size():
			n4 = guai_wu_n[n1]
		else:
			n4 = 0
		for j in range(n4):
			if n0 >= guai_wu_fan_wei.size():
				break
			var xy = guai_wu_fan_wei[n0]
			var x = int(xy.x)
			var y = int(xy.y)
			GZ[y][x]["guai_wu"] = true
			GZ[y][x]["guai_wu_id"] = n3
			guai_wu_xy.append(xy)
			n0 += 1

# ---- 支线胜利流程钩子（供死亡处理.gd 通过 has_method 调用）----
func _zhi_xian_win() -> void:
	if guan_ui != null:
		guan_ui.C_zhi_xian_sheng_li()
