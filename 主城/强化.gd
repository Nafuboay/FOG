extends Control

# 强化界面容器
var QH_n: Control
# 格子数组
var GZ: Array[TextureRect] = []
# 强化界面是否打开
var QH_on: bool = false
# 格子行数
var y: int = 7
# 格子列数
var x: int = 7
# 格子大小
var GZ_size: int = 64
# 普通格子图片
var GZ_png1: Texture2D
# 选中格子图片
var GZ_png2: Texture2D
# 背景图片
var bg_png: Texture2D
# 标题图片
var wen_ben_png: Texture2D
# 模块背景
var kuai: Texture2D
# 当前选中的格子索引
var GZ_ing: int = -1
# 物品信息面板
var wu_pin_kuai: Control = null
# 物品信息背景
var kuai_9: NinePatchRect = null
# 当前显示的物品字典
var wu_pin_ing: Dictionary = {}
# 3~4行放置区的物品列表（不堆叠，按顺序）
var fang_zhi_qu: Array = []
# 窗口大小
var win_size: Vector2
# 背包引用
var BB: Control = null
# 强化NPC引用
var npc2: Node2D = null
# 商店引用
var shop: Control = null
# 当前角色的装备列表
var ZB_ing: Array = []
# 银币显示标签
var S_lbl: Label = null
# 银币图标
var S: TextureRect = null
# 强化等级上限
const QH_MAX = 40
# 低级强化值数组
var QH_m = [1,3,6,11,18,29,44,64,93,132,185]
# 当前选中的装备索引
var ZB_idx: int = -1
# 强化按钮
var QH_btn: TextureRect = null
# 成功率显示标签
var SR_lbl: Label = null
# 消耗银币显示标签
var S_add_lbl: Label = null

func _ready() -> void:
	# 初始化窗口大小
	win_size = get_viewport_rect().size
	# 加载格子图片
	GZ_png1 = load("res://全局/图片/空间格子.png")
	GZ_png2 = load("res://全局/图片/闪光格子.png")
	# 加载背景图片
	bg_png = load("res://全局/图片/背包背景.png")
	# 加载标题图片
	wen_ben_png = load("res://主城/图片/装备强化文本.png")
	# 加载模块背景
	kuai = load("res://关卡/信息/模块背景.png")
	# 创建强化界面容器
	QH_n = Control.new()
	QH_n.name = "强化界面容器"
	QH_n.visible = false
	add_child(QH_n)
	# 创建银币显示
	C_S()
	# 创建背景
	Bg()
	# 加载角色装备
	load_helo_ZB()

# 根据等级获取m值
func get_m(n: int) -> int:
	if n < QH_m.size():
		return QH_m[n]
	var n_float = float(n + 1)
	return round((pow(n_float, 4) - pow(n_float - 1, 4)) / 25.0)

# 从存档加载角色装备
func load_helo_ZB() -> void:
	ZB_ing = []
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	var data = json.du_qu(json.id)
	var helo = data.get("英雄", "爱丽丝")
	ZB_ing = 装备信息.get_helo(helo)

# 创建银币显示
func C_S() -> void:
	var S_png = load("res://全局/图片/银币.png")
	# 创建银币显示标签
	S_lbl = Label.new()
	S_lbl.text = "0"
	S_lbl.add_theme_font_size_override("font_size", 32)
	S_lbl.add_theme_color_override("font_color", Color("eeeeee"))
	# 设置楷体字体
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		S_lbl.add_theme_font_override("font", kai_ti)
	S_lbl.z_index = 1
	S_lbl.visible = false
	QH_n.add_child(S_lbl)
	# 创建银币图标
	S = TextureRect.new()
	S.texture = S_png
	S.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	S.size = Vector2(50, 50)
	S.z_index = 1
	S.visible = false
	QH_n.add_child(S)
	# 创建强化按钮
	C_QH_btn()
	# 创建成功率显示
	C_SR_lbl()
	# 创建消耗银币显示
	C_S_add_lbl()

# 创建强化按钮
func C_QH_btn() -> void:
	QH_btn = TextureRect.new()
	QH_btn.texture = load("res://主城/图片/强化0.png")
	QH_btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	QH_btn.size = Vector2(140, 48)
	QH_btn.visible = false
	QH_btn.mouse_entered.connect(_on_QH_btn_mouse_entered)
	QH_btn.mouse_exited.connect(_on_QH_btn_mouse_exited)
	QH_btn.gui_input.connect(_on_QH_btn_clicked)
	add_child(QH_btn)

# 强化按钮鼠标悬停
func _on_QH_btn_mouse_entered() -> void:
	QH_btn.texture = load("res://主城/图片/强化1.png")

# 强化按钮鼠标移出
func _on_QH_btn_mouse_exited() -> void:
	QH_btn.texture = load("res://主城/图片/强化0.png")

# 强化按钮点击
func _on_QH_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		QH_zhi_xing()

# 创建成功率显示标签
func C_SR_lbl() -> void:
	SR_lbl = Label.new()
	SR_lbl.text = "成功率: 0%"
	SR_lbl.add_theme_font_size_override("font_size", 32)
	SR_lbl.add_theme_color_override("font_color", Color("eeeeee"))
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		SR_lbl.add_theme_font_override("font", kai_ti)
	SR_lbl.z_index = 1
	SR_lbl.visible = false
	QH_n.add_child(SR_lbl)

# 创建消耗银币显示标签
func C_S_add_lbl() -> void:
	S_add_lbl = Label.new()
	S_add_lbl.text = "消耗: 0银币"
	S_add_lbl.add_theme_font_size_override("font_size", 32)
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		S_add_lbl.add_theme_font_override("font", kai_ti)
	S_add_lbl.z_index = 1
	S_add_lbl.visible = false
	QH_n.add_child(S_add_lbl)

# 更新银币显示
func S_upd() -> void:
	if S_lbl == null:
		return
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		S_lbl.text = "0"
		return
	var data = json.du_qu(json.id)
	var S_n = int(data.get("银币", 0))
	var text = ""
	if S_n >= 1000000000000:
		text = "富可敌国"
	elif S_n >= 10000:
		var is_yi = S_n >= 100000000
		var unit = "亿" if is_yi else "万"
		var wei_4 = 100000000 if is_yi else 10000
		var d_1 = int(S_n / float(wei_4))
		var f_1 = S_n % wei_4
		var f_2 = ""
		if d_1 < 10:
			var f_3 = int(f_1 * 1000 / float(wei_4))
			f_2 = ".%03d" % f_3
		elif d_1 < 100:
			var f_3 = int(f_1 * 100 / float(wei_4))
			f_2 = ".%02d" % f_3
		elif d_1 < 1000:
			var f_3 = int(f_1 * 10 / float(wei_4))
			f_2 = ".%01d" % f_3
		text = "%d%s%s" % [d_1, f_2, unit]
	else:
		text = str(S_n)
	S_lbl.text = text

# 创建背景
func Bg() -> void:
	# 创建背景图片
	var bg = TextureRect.new()
	bg.texture = bg_png
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = Vector2(500, 526)
	bg.position = win_size / 2.0 - bg.size / 2.0 - Vector2(0, 13)
	QH_n.add_child(bg)
	# 创建标题图片
	if wen_ben_png != null:
		var wen_ben = TextureRect.new()
		wen_ben.texture = wen_ben_png
		wen_ben.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wen_ben.size = Vector2(117,52)
		wen_ben.position = Vector2(581.5,84)
		QH_n.add_child(wen_ben)
	# 创建格子容器
	C_GZ_1()

# 创建7x7格子容器
func C_GZ_1() -> void:
	var GZ_49 = Control.new()
	GZ_49.name = "强化格子"
	QH_n.add_child(GZ_49)
	for i in range(y * x):
		var h = int(i / float(x))
		var l = i % x
		# 根据布局规则决定是否显示格子
		if not is_GZ_visible(i):
			continue
		var ge = TextureRect.new()
		ge.texture = GZ_png1
		ge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ge.size = Vector2(GZ_size, GZ_size)
		ge.position = Vector2(l * GZ_size, h * GZ_size)
		ge.gui_input.connect(func(event): GZ_LMB(event, i))
		GZ_49.add_child(ge)
		GZ.append(ge)
	GZ_49.position = win_size / 2.0 - Vector2(x * GZ_size, y * GZ_size) / 2.0

# 判断格子是否需要显示
func is_GZ_visible(idx: int) -> bool:
	# 布局矩阵（7行7列）
	var layout = [
		[1, 0, 1, 0, 1, 0, 1],  # 第0行
		[0, 0, 0, 0, 0, 0, 0],  # 第1行
		[1, 1, 1, 1, 1, 1, 1],  # 第2行
		[1, 1, 1, 1, 1, 1, 1],  # 第3行
		[0, 0, 0, 0, 0, 0, 0],  # 第4行
		[1, 1, 1, 1, 1, 1, 1],  # 第5行
		[1, 1, 1, 1, 1, 1, 1],  # 第6行
	]
	var h = int(idx / float(x))
	var l = idx % x
	if h >= 0 and h < y and l >= 0 and l < x:
		return layout[h][l] == 1
	return false

# 获取格子在显示数组中的实际索引
func get_GZ_index(idx: int) -> int:
	var count = 0
	for i in range(idx):
		if is_GZ_visible(i):
			count += 1
	return count

# 强化NPC点击事件（打开/关闭强化界面）
func QH_On1() -> void:
	QH_on = !QH_on
	QH_n.visible = QH_on
	if QH_on:
		# 更新银币显示
		S_upd()
		S_lbl.visible = true
		S.visible = true
		# 重新加载角色装备（以防角色变更）
		load_helo_ZB()
		# 重置放置区
		fang_zhi_qu = []
		# 刷新装备显示
		ZB_upd()
		# 刷新强化材料显示
		QH_CL_upd()
		# 刷新放置区显示
		fang_zhi_qu_upd()
		# 隐藏背包按钮
		if BB != null:
			BB.BB_btn.visible = false
			if BB.S_lbl != null:
				BB.S_lbl.visible = false
			if BB.S != null:
				BB.S.visible = false
		# 关闭商店界面（如果打开）
		if shop != null and shop.BB_on:
			shop.btn_BB()
	if not QH_on:
		# 重置选中状态
		GZ_ing = -1
		for ge in GZ:
			ge.texture = GZ_png1
		wu_pin_XX_0()
		S_lbl.visible = false
		S.visible = false
		# 隐藏强化按钮
		if QH_btn != null:
			QH_btn.visible = false
		# 隐藏成功率和消耗显示
		if SR_lbl != null:
			SR_lbl.visible = false
		if S_add_lbl != null:
			S_add_lbl.visible = false
		# 重置选中的装备索引
		ZB_idx = -1
		# 关闭界面时，将放置区的材料返还到背包
		fang_zhi_qu_back()
		# 重置放置区
		fang_zhi_qu = []
		# 显示背包按钮
		if BB != null:
			BB.BB_btn.visible = true
			if BB.S_lbl != null:
				BB.S_lbl.visible = true
			if BB.S != null:
				BB.S.visible = true
	get_tree().call_group("BB_3", "BB_4", QH_on)
	BB_n_xy()

# 居中界面
func BB_n_xy() -> void:
	var GZ_49 = QH_n.get_node("强化格子")
	if GZ_49 == null:
		return
	var GZ_49_size = Vector2(x * GZ_size, y * GZ_size)
	GZ_49.position = win_size / 2.0 - GZ_49_size / 2.0 # 格子居中
	if S_lbl != null and S != null: # 银币图标文本位置
		S_lbl.position = Vector2(770,93)
		S.position = Vector2(715,85)

# 刷新装备显示（第一行4个装备位）
func ZB_upd() -> void:
	# 第一行的显示位置：索引0, 2, 4, 6（对应布局中第一行的4个1）
	var ZB_1 = [0, 2, 4, 6]
	for i in range(ZB_1.size()):
		var gz_idx = ZB_1[i]
		var idx_1 = get_GZ_index(gz_idx)
		if idx_1 >= GZ.size():
			continue
		var ge = GZ[idx_1]
		# 清除格子内的子节点
		for child in ge.get_children():
			child.queue_free()
		# 显示角色装备
		if i < ZB_ing.size():
			var wu_ming = ZB_ing[i]
			if 装备信息.ZB_png.has(wu_ming):
				var wu_pin_tu = TextureRect.new()
				wu_pin_tu.texture = load(装备信息.ZB_png[wu_ming])
				wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				wu_pin_tu.size = Vector2(GZ_size - 14, GZ_size - 14)
				var offset = (GZ_size - wu_pin_tu.size.x) / 2.0
				wu_pin_tu.position = Vector2(offset, offset)
				ge.add_child(wu_pin_tu)

# 刷新强化材料显示（第6~7行，堆叠显示）
func QH_CL_upd() -> void:
	# 清理材料区域的格子
	var start_idx = 5 * x
	var end_idx = 7 * x
	for i in range(start_idx, end_idx):
		if not is_GZ_visible(i):
			continue
		# 逻辑索引转换
		var idx_1 = get_GZ_index(i)
		if idx_1 < GZ.size():
			for child in GZ[idx_1].get_children():
				child.queue_free()
	# 获取背包中的强化材料（带数量）
	var CL = get_QH_CL()
	# 按物品顺序显示，堆叠显示
	var idx = 0
	for wu_ming in 物品信息.wu_pin:
		if CL.has(wu_ming) and CL[wu_ming] > 0:
			if idx >= 14:  # 最多显示14个格子
				break
			var gz_idx = start_idx + idx
			var idx_1 = get_GZ_index(gz_idx)
			if idx_1 >= GZ.size():
				idx += 1
				continue
			var ge = GZ[idx_1]
			# 创建物品图片
			var wu_pin_tu = TextureRect.new()
			wu_pin_tu.texture = load(物品信息.wu_pin_png[wu_ming])
			wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wu_pin_tu.size = Vector2(GZ_size - 14, GZ_size - 14)
			var offset = (GZ_size - wu_pin_tu.size.x) / 2.0
			wu_pin_tu.position = Vector2(offset, offset)
			ge.add_child(wu_pin_tu)
			# 如果数量大于1，显示数量标签
			var count = CL[wu_ming]
			if count > 1:
				var wu_n = Label.new()
				wu_n.text = str(int(count))
				wu_n.add_theme_color_override("font_color", Color.BLACK)
				ge.add_child(wu_n)
				var wu_n_size = wu_n.get_minimum_size()
				wu_n.position = Vector2(GZ_size - wu_n_size.x - 6, GZ_size - wu_n_size.y - 2)
			idx += 1

# 获取背包中的强化材料字典（物品名:数量）
func get_QH_CL() -> Dictionary:
	var CL = {}
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return CL
	var data = json.du_qu(json.id)
	var BB_wu_pin = data.get("背包", {})
	for wu_ming in 物品信息.wu_pin:
		if BB_wu_pin.has(wu_ming) and 物品信息.shi_fou_QH_CL(wu_ming):
			CL[wu_ming] = BB_wu_pin[wu_ming]
	return CL

# 刷新放置区显示（3~4行）
func fang_zhi_qu_upd() -> void:
	# 清理放置区格子
	var start_idx = 2 * x
	var end_idx = 4 * x
	for i in range(start_idx, end_idx):
		if not is_GZ_visible(i):
			continue
		var idx_1 = get_GZ_index(i)
		if idx_1 < GZ.size():
			for child in GZ[idx_1].get_children():
				child.queue_free()
	# 显示放置区物品（不堆叠，按顺序）
	for i in range(fang_zhi_qu.size()):
		if i >= 14:  # 最多14个
			break
		var gz_idx = start_idx + i
		var idx_1 = get_GZ_index(gz_idx)
		if idx_1 >= GZ.size():
			continue
		var ge = GZ[idx_1]
		var wu_ming = fang_zhi_qu[i]
		if 物品信息.wu_pin_png.has(wu_ming):
			var wu_pin_tu = TextureRect.new()
			wu_pin_tu.texture = load(物品信息.wu_pin_png[wu_ming])
			wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wu_pin_tu.size = Vector2(GZ_size - 14, GZ_size - 14)
			var offset = (GZ_size - wu_pin_tu.size.x) / 2.0
			wu_pin_tu.position = Vector2(offset, offset)
			ge.add_child(wu_pin_tu)

# 判断是否是装备区域（第一行）
func is_zb_qu(idx: int) -> bool:
	var ZB_1 = [0, 2, 4, 6]
	return ZB_1.has(idx)

# 判断是否是放置区（3~4行）
func is_fang_zhi_qu(idx: int) -> bool:
	var h = int(idx / float(x))
	return h == 2 or h == 3

# 判断是否是材料区（6~7行）
func is_CL_qu(idx: int) -> bool:
	var h = int(idx / float(x))
	return h == 5 or h == 6

# 格子点击事件
func GZ_LMB(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 获取显示数组中的实际索引
		var idx_1 = get_GZ_index(idx)
		if idx_1 < 0 or idx_1 >= GZ.size():
			return
		# 点击装备区（第一行）
		if is_zb_qu(idx):
			if GZ_ing == idx_1:
				# 取消选中
				GZ_ing = -1
				for ge in GZ:
					ge.texture = GZ_png1
				wu_pin_XX_0()
				# 隐藏强化按钮和信息
				QH_btn.visible = false
				SR_lbl.visible = false
				S_add_lbl.visible = false
				ZB_idx = -1
			else:
				# 选中新格子
				GZ_ing = idx_1
				for i in range(GZ.size()):
					GZ[i].texture = GZ_png1
				GZ[idx_1].texture = GZ_png2
				# 获取装备索引
				var ZB_1 = [0, 2, 4, 6]
				ZB_idx = ZB_1.find(idx)
				wu_pin_XX(idx)
				# 强化按钮和信息显示及位置
				QH_btn.visible = true
				QH_btn.position = Vector2(570,400)
				SR_lbl.visible = true
				SR_lbl.position = Vector2(410,215)
				S_add_lbl.visible = true
				S_add_lbl.position = Vector2(625,215)
				# 更新成功率和消耗
				QH_upd_1()
			return
		# 点击放置区（3~4行）
		if is_fang_zhi_qu(idx):
			fang_zhi_qu_click(idx)
			# 如果选中了装备，更新强化信息
			if ZB_idx != -1:
				QH_upd_1()
			return
		# 点击材料区（6~7行）
		if is_CL_qu(idx):
			CL_qu_click(idx)
			# 如果选中了装备，更新强化信息
			if ZB_idx != -1:
				QH_upd_1()
			return

# 计算放置区材料的总背包售价
func get_n() -> int:
	var n = 0
	# 遍历放置区中的每个物品
	for wu_ming in fang_zhi_qu:
		# 获取物品信息
		var XX = 物品信息.get_XX(wu_ming)
		# 累加背包售价
		n += XX.get("背包售价", 0)
	return n

# 获取当前装备的强化等级
func get_QH_lv() -> int:
	# 检查是否选中了有效的装备
	if ZB_idx < 0 or ZB_idx >= ZB_ing.size():
		return 0
	# 获取装备名称
	var wu_ming = ZB_ing[ZB_idx]
	# 获取装备对应的属性类型
	var shu_xing = 装备信息.get_shu_xing(wu_ming)
	if shu_xing == "":
		return 0
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return 0
	# 读取存档数据
	var data = json.du_qu(json.id)
	# 获取强化数据，默认值为0级
	var QHs = data.get("强化", {"生命":0, "力量":0, "防御":0, "穿透":0})
	# 返回该属性的强化等级
	return QHs.get(shu_xing, 0)

# 更新强化信息（成功率和消耗）
func QH_upd_1() -> void:
	# 获取当前装备强化等级
	var QH_lv = get_QH_lv()
	# 如果已满级
	if QH_lv >= QH_MAX:
		SR_lbl.text = "强化已满级！"
		S_add_lbl.text = "无需消耗！"
		QH_btn.visible = false
		return
	# 获取当前等级对应的m值
	var m = get_m(QH_lv)
	# 获得n值
	var n = get_n()
	# 成功率=min(1,2n/m)
	var SR = min(1.0, 2.0 * n / float(m))
	# 计算消耗银币
	var add = 0
	if 2 * n < m:
		# 材料不足时，消耗所有材料的总价值
		add = n
	else:
		# 材料充足时，消耗 m-n（可能为负数，即返还银币）
		add = m - n
	# 自然常数e
	var e = 2.718281828459045
	# 更新成功率显示
	SR_lbl.text = "成功率：%d%%" % int(SR * 100)
	# 根据成功率设置颜色
	if SR <= 1.0 / e:
		# 成功率过低
		SR_lbl.add_theme_color_override("font_color", Color("#555555"))
		QH_btn.visible = false
	elif SR >= 1.0:
		# 成功率100%
		SR_lbl.add_theme_color_override("font_color", Color("#00FFFF"))
		QH_btn.visible = true
	else:
		# 成功率适中
		SR_lbl.add_theme_color_override("font_color", Color("#eeeeee"))
		QH_btn.visible = true
	# 区分消耗和返还
	if add >= 0:
		S_add_lbl.text = "消耗银币：%d" % add
		S_add_lbl.add_theme_color_override("font_color", Color("#eeeeee"))
	else:
		S_add_lbl.text = "返还银币：%d" % (-add)
		S_add_lbl.add_theme_color_override("font_color", Color("#00FFFF"))

# 执行强化
func QH_zhi_xing() -> void:
	# 检查是否选中装备
	if ZB_idx < 0 or ZB_idx >= ZB_ing.size():
		return
	var wu_ming = ZB_ing[ZB_idx]
	var shu_xing = 装备信息.get_shu_xing(wu_ming)
	if shu_xing == "":
		return
	# 获取当前强化等级
	var QH_lv = get_QH_lv()
	# 如果已满级
	if QH_lv >= QH_MAX:
		提示弹幕.wen_ben("有BUG，快去找虹！", 0)
		return
	# 获取m值
	var m = get_m(QH_lv)
	# 计算n值
	var n = get_n()
	# 计算成功率
	var SR = min(1.0, 2.0 * n / float(m))
	# 计算消耗银币
	var add = 0
	if 2 * n < m:
		add = n
	else:
		add = m - n
	# 检查银币是否足够
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	var data = json.du_qu(json.id)
	var S_n = int(data.get("银币", 0))
	if add > S_n:
		提示弹幕.wen_ben("银币不足！", 0)
		return
	# 随机判断是否成功
	var sui_ji = randf_range(0.0, 1.0)
	var lv_add = sui_ji <= SR
	# 扣除材料（清空放置区）
	fang_zhi_qu = []
	fang_zhi_qu_upd()
	QH_CL_upd()
	# 扣除/增加银币
	S_n -= add
	data["银币"] = S_n
	# 先保存数据到文件，再更新显示
	json.bao_cun(json.id, data)
	S_upd()
	# 如果成功
	if lv_add:
		QH_lv += 1
		# 更新存档中的强化等级
		var QHs = data.get("强化", {"生命":0, "力量":0, "防御":0, "穿透":0})
		QHs[shu_xing] = QH_lv
		data["强化"] = QHs
		# 保存存档
		json.bao_cun(json.id, data)
		# 显示结果
		提示弹幕.wen_ben("【%s】强化+%d成功！" % [wu_ming, QH_lv], 0)
		# 更新装备信息显示
		wu_pin_XX_0()
		var ZB_1 = [0, 2, 4, 6]
		wu_pin_XX(ZB_1[ZB_idx])
		# 更新强化信息
		QH_upd_1()
	else:
		# 保存存档（银币已扣除）
		json.bao_cun(json.id, data)
		提示弹幕.wen_ben("不够好运，强化失败！", 0)
		# 更新强化信息
		QH_upd_1()

# 将放置区的材料返还到背包
func fang_zhi_qu_back() -> void:
	if fang_zhi_qu.size() == 0:
		return
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	var data = json.du_qu(json.id)
	var BB_wu_pin = data.get("背包", {})
	for wu_ming in fang_zhi_qu:
		BB_wu_pin[wu_ming] = BB_wu_pin.get(wu_ming, 0) + 1
	data["背包"] = BB_wu_pin
	json.bao_cun(json.id, data)

# 放置区点击处理
func fang_zhi_qu_click(idx: int) -> void:
	# 计算在放置区中的索引
	var start_idx = 2 * x
	var fang_zhi_idx = idx - start_idx
	if fang_zhi_idx < 0 or fang_zhi_idx >= fang_zhi_qu.size():
		return
	# 获取卸下的物品
	var wu_ming = fang_zhi_qu[fang_zhi_idx]
	# 从放置区移除
	fang_zhi_qu.remove_at(fang_zhi_idx)
	# 背包中该物品数量+1
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json != null:
		var data = json.du_qu(json.id)
		var BB_wu_pin = data.get("背包", {})
		BB_wu_pin[wu_ming] = BB_wu_pin.get(wu_ming, 0) + 1
		data["背包"] = BB_wu_pin
		json.bao_cun(json.id, data)
	# 刷新显示
	QH_CL_upd()
	fang_zhi_qu_upd()

# 材料区点击处理
func CL_qu_click(idx: int) -> void:
	# 如果放置区已满（14个），无法添加
	if fang_zhi_qu.size() >= 14:
		return
	# 获取材料区显示的物品
	var CL = get_QH_CL()
	var start_idx = 5 * x
	var CL_idx_1 = idx - start_idx
	# 按顺序找到对应的物品
	var wu_ming = ""
	var idx_count = 0
	for item_name in 物品信息.wu_pin:
		if CL.has(item_name) and CL[item_name] > 0:
			if idx_count == CL_idx_1:
				wu_ming = item_name
				break
			idx_count += 1
	if wu_ming == "":
		return
	# 背包中该物品数量-1
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	var data = json.du_qu(json.id)
	var BB_wu_pin = data.get("背包", {})
	if BB_wu_pin.get(wu_ming, 0) <= 0:
		return
	BB_wu_pin[wu_ming] -= 1
	if BB_wu_pin[wu_ming] <= 0:
		BB_wu_pin.erase(wu_ming)
	data["背包"] = BB_wu_pin
	json.bao_cun(json.id, data)
	# 添加到放置区
	fang_zhi_qu.append(wu_ming)
	# 刷新显示
	QH_CL_upd()
	fang_zhi_qu_upd()

# 显示物品信息（仅装备区域）
func wu_pin_XX(idx: int) -> void:
	# 先关闭已有面板
	wu_pin_XX_0()
	# 检查是否是第一行的装备
	var ZB_1 = [0, 2, 4, 6]
	for i in range(ZB_1.size()):
		if ZB_1[i] == idx:
			if i >= ZB_ing.size():
				return
			var wu_ming = ZB_ing[i]
			# 获取实际强化等级
			var shu_xing = 装备信息.get_shu_xing(wu_ming)
			var QH_lv = 0
			if shu_xing != "":
				var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
				if json != null:
					var data = json.du_qu(json.id)
					var QHs = data.get("强化", {"生命":0, "力量":0, "防御":0, "穿透":0})
					QH_lv = QHs.get(shu_xing, 0)
			# 创建面板
			var win_y = int(win_size.y)
			var win_x = int(win_size.x)
			# 创建九宫格背景
			kuai_9 = NinePatchRect.new()
			kuai_9.texture = kuai
			kuai_9.patch_margin_left = 25
			kuai_9.patch_margin_right = 25
			kuai_9.patch_margin_top = 25
			kuai_9.patch_margin_bottom = 25
			kuai_9.position = Vector2(win_x - 256 - 32, int((win_y - 512) / 2.0))
			kuai_9.size = Vector2(256, 512)
			add_child(kuai_9)
			# 创建文字容器
			wu_pin_kuai = Control.new()
			wu_pin_kuai.position = Vector2(win_x - 256 - 32, int((win_y - 512) / 2.0))
			wu_pin_kuai.size = Vector2(256, 512)
			add_child(wu_pin_kuai)
			# 构建文本内容
			var XX = 装备信息.get_XX(wu_ming)
			# 构建强化等级文本
			var QH_text = ""
			var shu_xing_text = "无"
			if QH_lv >= 1:
				# 有强化等级时显示强化信息和属性
				if QH_lv > QH_MAX:
					QH_text = "开了！"
				else:
					QH_text = "+%d" % QH_lv
				# 属性显示"属性名+等级"
				shu_xing_text = "%s+%d" % [shu_xing, QH_lv] if shu_xing != "" else "无"
			else:
				# 0级时显示默认文本
				QH_text = XX.get("强化", "未强化")
				shu_xing_text = "无"
			# 显示
			var text = "\n  【装备】%s\n  【强化】%s\n  【属性】%s\n  【特性】%s\n      %s" % [
				wu_ming, QH_text, shu_xing_text, 
				XX.get("特性", "无"), XX.get("描述", "")
			]
			# 创建文本标签
			var label = Label.new()
			label.text = text
			label.position = Vector2(0,0)
			label.add_theme_color_override("font_color", Color.BLACK)
			# 设置楷体字体
			var kai_ti = 提示弹幕.get_kai_ti_font()
			if kai_ti != null:
				label.add_theme_font_override("font", kai_ti)
			wu_pin_kuai.add_child(label)
			return

# 清除物品信息面板
func wu_pin_XX_0() -> void:
	if kuai_9 != null:
		kuai_9.queue_free()
		kuai_9 = null
	if wu_pin_kuai != null:
		wu_pin_kuai.queue_free()
		wu_pin_kuai = null

# 设置NPC引用
func npc_1(npc: Node2D) -> void:
	npc2 = npc

# 设置背包引用
func BB_2(BB_ref: Control) -> void:
	BB = BB_ref

# 设置商店引用
func shop_2(shop_ref: Control) -> void:
	shop = shop_ref

# 显示NPC
func on_npc() -> void:
	if npc2 != null:
		npc2.visible = true

# 隐藏NPC
func off_npc() -> void:
	if npc2 != null:
		npc2.visible = false
