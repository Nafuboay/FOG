# 道具选择界面（进关前配置关卡内携带的道具种类与顺序）
extends Control

# 界面关闭信号（通知主城重新显示选关面板）
signal guan_bi

var rong_qi: Control = null # 弹窗容器
var hou_xuan: Control = null # 候选道具网格容器
var xie_dai: Control = null # 携带栏容器
var xuan_ze: Array = [] # 当前选择的道具名（顺序=携带顺序，最多10个）
var GZ_png1: Texture2D = null # 普通格子贴图
var GZ_png2: Texture2D = null # 已选格子贴图

const ZUI_DUO: int = 10 # 携带栏位上限
const H_LIE: int = 5 # 候选网格每行列数
const H_DA: int = 64 # 候选格子边长（格子间不留缝隙）
const X_DA: int = 48 # 携带格子边长（格子间不留缝隙）

# 初始化：隐藏并构建弹窗
func _ready() -> void:
	visible = false
	z_index = 1000
	# 全屏拦截点击（父节点主城是Node2D，锚点不生效，直接用视口尺寸）
	position = Vector2.ZERO
	size = get_viewport_rect().size
	GZ_png1 = load("res://全局/图片/空间格子.png")
	GZ_png2 = load("res://全局/图片/闪光格子.png")
	C_mian_ban()

# 创建弹窗面板与所有固定元素
func C_mian_ban() -> void:
	# 弹窗容器：与背包/商店同款深棕色背景、同尺寸500×526、同居中偏移
	rong_qi = Control.new()
	rong_qi.size = Vector2(500, 526)
	rong_qi.position = get_viewport_rect().size / 2.0 - rong_qi.size / 2.0 - Vector2(0, 13)
	add_child(rong_qi)
	# 深棕色背景（背包/商店同款）
	var bg = TextureRect.new()
	bg.texture = load("res://全局/图片/背包背景.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = rong_qi.size
	rong_qi.add_child(bg)
	# 标题
	var biao_ti = C_label("道具栏", 32, Color.BLACK)
	biao_ti.size = Vector2(500, 34)
	biao_ti.position = Vector2(0, 20)
	biao_ti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rong_qi.add_child(biao_ti)
	# 候选网格容器（5列×2行，64格无缝，共320宽，居中起点90）
	hou_xuan = Control.new()
	hou_xuan.position = Vector2(90, 100)
	rong_qi.add_child(hou_xuan)
	# 携带栏容器（10格48无缝，共480宽，起点10）
	xie_dai = Control.new()
	xie_dai.position = Vector2(10, 288)
	rong_qi.add_child(xie_dai)

# 创建楷体文字标签（统一字体入口）
func C_label(wen: String, da_xiao: int, yan_se: Color) -> Label:
	var lbl = Label.new()
	lbl.text = wen
	lbl.add_theme_color_override("font_color", yan_se)
	lbl.add_theme_font_size_override("font_size", da_xiao)
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		lbl.add_theme_font_override("font", kai_ti)
	return lbl

# 打开界面：读取存档配置并刷新
func open() -> void:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		xuan_ze = []
	else:
		xuan_ze = json.get_dao_ju_xz()
	visible = true
	upd()

# 关闭界面并发出信号
func guan_bi_zk() -> void:
	visible = false
	guan_bi.emit()

# 读取当前存档的背包数量字典
func du_qu_bei_bao() -> Dictionary:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		return {}
	return json.du_qu(json.id).get("背包", {})

# 保存当前选择配置到存档
func bao_cun() -> void:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		return
	json.bao_cun_dao_ju_xz(xuan_ze)

# 点击道具：已选则取消（后面的自动前移），未选则追加到末尾，满10个给提示
# 取消最后一个后自动恢复默认顺序，实现"一个都没选=默认携带"
func qie_huan(wu_ming: String) -> void:
	var idx = xuan_ze.find(wu_ming)
	if idx >= 0:
		xuan_ze.remove_at(idx)
		# 全取消后视为默认携带
		if xuan_ze.is_empty():
			xuan_ze = 物品信息.guan_kia_dao_ju.duplicate()
	elif xuan_ze.size() >= ZUI_DUO:
		提示弹幕.wen_ben("最多只能携带%d个道具！" % ZUI_DUO, 0)
		return
	else:
		xuan_ze.append(wu_ming)
	bao_cun()
	upd()

# 刷新候选网格与携带栏
func upd() -> void:
	var bag = du_qu_bei_bao()
	upd_hou_xuan(bag)
	upd_xie_dai(bag)

# 刷新候选道具网格（全部关卡可用道具，已选用闪光格子高亮）
func upd_hou_xuan(bag: Dictionary) -> void:
	for c in hou_xuan.get_children():
		c.queue_free()
	for i in range(物品信息.guan_kia_dao_ju.size()):
		var wu_ming = 物品信息.guan_kia_dao_ju[i]
		var h = int(i / float(H_LIE))
		var l = i % H_LIE
		# 格子底图：已选用闪光格子
		var ge = TextureRect.new()
		ge.texture = GZ_png2 if xuan_ze.has(wu_ming) else GZ_png1
		ge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ge.size = Vector2(H_DA, H_DA)
		ge.position = Vector2(l * H_DA, h * H_DA)
		ge.gui_input.connect(func(event, ming=wu_ming):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				qie_huan(ming)
		)
		hou_xuan.add_child(ge)
		var n = int(bag.get(wu_ming, 0))
		# 道具图标（数量为0也正常显示，便于预选）
		if 物品信息.wu_pin_png.has(wu_ming):
			var tu = TextureRect.new()
			tu.texture = load(物品信息.wu_pin_png[wu_ming])
			tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tu.size = Vector2(50, 50)
			tu.position = Vector2((H_DA - 50) / 2.0, (H_DA - 50) / 2.0)
			tu.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ge.add_child(tu)
		# 拥有数量角标（右下角，与背包一致仅数量>1时显示）
		if n > 1:
			var shu = C_label(str(n), 16, Color.BLACK)
			shu.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ge.add_child(shu)
			var shu_ju = shu.get_minimum_size()
			shu.position = Vector2(H_DA - shu_ju.x - 4, H_DA - shu_ju.y - 2)

# 刷新携带栏（固定10格，按选择顺序排列；空格只显示底框；点击已放置道具=取消）
func upd_xie_dai(bag: Dictionary) -> void:
	for c in xie_dai.get_children():
		c.queue_free()
	for i in range(ZUI_DUO):
		var ge_x = i * X_DA
		# 格子底图
		var ge = TextureRect.new()
		ge.texture = GZ_png1
		ge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ge.size = Vector2(X_DA, X_DA)
		ge.position = Vector2(ge_x, 0)
		xie_dai.add_child(ge)
		# 格子编号（格子下方居中）
		var bian_hao = C_label(str(i + 1), 14, Color.BLACK)
		bian_hao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		xie_dai.add_child(bian_hao)
		var bian_ju = bian_hao.get_minimum_size()
		bian_hao.position = Vector2(ge_x + (X_DA - bian_ju.x) / 2.0, X_DA + 2)
		# 未占用的格子保持空白
		if i >= xuan_ze.size():
			continue
		var wu_ming = xuan_ze[i]
		var n = int(bag.get(wu_ming, 0))
		# 点击已放置道具=取消选择
		ge.gui_input.connect(func(event, ming=wu_ming):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				qie_huan(ming)
		)
		# 道具图标（数量为0也正常显示）
		if 物品信息.wu_pin_png.has(wu_ming):
			var tu = TextureRect.new()
			tu.texture = load(物品信息.wu_pin_png[wu_ming])
			tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tu.size = Vector2(40, 40)
			tu.position = Vector2((X_DA - 40) / 2.0, (X_DA - 40) / 2.0)
			tu.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ge.add_child(tu)
		# 拥有数量角标（与背包一致仅数量>1时显示）
		if n > 1:
			var shu = C_label(str(n), 14, Color.BLACK)
			shu.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ge.add_child(shu)
			var shu_ju = shu.get_minimum_size()
			shu.position = Vector2(X_DA - shu_ju.x - 3, X_DA - shu_ju.y - 1)
