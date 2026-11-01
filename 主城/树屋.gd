extends Control # 树屋-任务/成就界面
# 翻页系统脚本（任务8行/页、成就6行/页，复用全局上一页/下一页按钮）
const 翻页系统_SCRIPT = preload("res://全局/翻页系统.gd")
var is_tsk: bool = true    # 是否选中任务标签
var is_ach: bool = false   # 是否选中成就标签
var shu_wu: Control # 界面容器
var bg: TextureRect # 背景面板
var tsk_btn: TextureRect # 任务标签图片
var ach_btn: TextureRect # 成就标签图片
var tsk: Control # 任务容器
var ach: Control # 成就容器
var tsk_1: Array = [] # 任务项列表
var tsk_lq: Array = [] # 当前存档已领取的任务序号清单
var ach_1: Array = [] # 成就项列表
var ach_lq: Array = [] # 当前存档已领取的成就序号清单
var fan_ye_tsk = null # 任务翻页系统
var fan_ye_ach = null # 成就翻页系统
var ach_data: Array = [ # 成就配置数据: [序号,成就名称,图标名,条件类型,条件值,奖励物品名,奖励数量,条件描述]
	["0001", "救世主Ⅰ", "救世主", 1, 31, "金条", 10, "击败犽翡及其爪牙"],
	["0002", "救世主Ⅱ", "救世主", 1, 61, "金条", 10, "再次击败犽翡及其爪牙"],
	["1000", "不朽者", "不朽者", 0, "破损稻草人", "朱雀圣像", 1, "拥有【破损稻草人】"],
	["1001", "饮虹使", "饮虹使", 0, "彩虹", "彩虹", 10, "拥有【彩虹】"],
	["1004", "采花贼", "采花贼", 2, "", "奇花", 99, "拥有四种奇花"]
]
# 支线任务金条奖励表（支线1~30关，对应总任务31~60）
# 1~6关各3根；7~23关各4根；24~28关各32根；29关12根；30关100根
const ZX_JIN_TIAO: Array = [3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,32,32,32,32,32,12,100]

func _ready() -> void: # 初始化函数
	visible = false
	# 获取屏幕尺寸
	var win_x = get_viewport().get_visible_rect().size.x
	var win_y = get_viewport().get_visible_rect().size.y
	shu_wu = Control.new() # 创建界面容器
	shu_wu.size = Vector2(320,540)
	shu_wu.position = Vector2((win_x-320)/2,(win_y-540)/2)
	add_child(shu_wu)
	bg = TextureRect.new() # 创建背景
	bg.texture = load("res://全局/图片/背包背景.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = Vector2(320,540)
	shu_wu.add_child(bg)
	tsk_btn = TextureRect.new() # 创建任务标签按钮
	tsk_btn.texture = load("res://主城/图片/任务1.png")
	tsk_btn.position = Vector2(35,486) # 任务按钮位置
	tsk_btn.gui_input.connect(tsk_LMB)
	shu_wu.add_child(tsk_btn)
	ach_btn = TextureRect.new() # 创建成就标签按钮
	ach_btn.texture = load("res://主城/图片/成就0.png")
	ach_btn.position = Vector2(195,486) # 成就按钮位置
	ach_btn.gui_input.connect(ach_LMB)
	shu_wu.add_child(ach_btn)
	# 创建任务容器
	tsk = Control.new()
	tsk.size = Vector2(280,472)
	tsk.position = Vector2(20,14)
	shu_wu.add_child(tsk)
	# 创建成就容器
	ach = Control.new()
	ach.size = Vector2(280,472)
	ach.position = Vector2(20,14)
	ach.visible = false
	shu_wu.add_child(ach)
	# 创建任务/成就翻页系统（按钮放面板正下方，相对容器 y=530 即屏幕 y≈634，不挡标签按钮）
	fan_ye_tsk = 翻页系统_SCRIPT.new(8, upd_tsk)
	fan_ye_tsk.chuang_jian(tsk, Vector2(2, 530))
	fan_ye_ach = 翻页系统_SCRIPT.new(6, upd_ach)
	fan_ye_ach.chuang_jian(ach, Vector2(2, 530))

func tsk_LMB(event: InputEvent) -> void: # 任务标签按钮点击处理
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_tsk:
			return
		is_tsk = true
		is_ach = false
		tsk_btn.texture = load("res://主城/图片/任务1.png")
		ach_btn.texture = load("res://主城/图片/成就0.png")
		tsk.visible = true
		ach.visible = false

func ach_LMB(event: InputEvent) -> void: # 成就标签按钮点击处理
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_ach:
			return
		is_tsk = false
		is_ach = true
		tsk_btn.texture = load("res://主城/图片/任务0.png")
		ach_btn.texture = load("res://主城/图片/成就1.png")
		tsk.visible = false
		ach.visible = true
		upd_ach()  # 打开成就界面时刷新成就列表

func open() -> void: # 显示界面
	visible = true
	# 每次打开都回到第一页
	fan_ye_tsk.chong_zhi()
	fan_ye_ach.chong_zhi()
	upd_tsk()

# 从存档读取已领取任务序号清单（旧格式整数/数字数组/字段缺失一律视为空清单）
func get_tsk_lq() -> Array:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return []
	var data = json_1.du_qu(json_1.id)
	var lq = data.get("任务", [])
	var jg: Array = []
	if lq is Array:
		for x in lq:
			if x is String and not x.is_empty() and not jg.has(x):
				jg.append(x)
	return jg

# 任务是否已领取（T_id=任务号1~60）
func tsk_yi_ling(T_id: int) -> bool:
	return tsk_lq.has("%04d" % T_id)

# 任务是否可领取：进度大于任务号（已达成）且未领取
func tsk_ke_ling(T_id: int) -> bool:
	return not tsk_yi_ling(T_id) and get_stg() > T_id

# 刷新任务列表（只显示未领取的任务，按序号升序，每页8行）
func upd_tsk() -> void:
	# 清空现有任务
	for i in tsk_1:
		i.queue_free()
	tsk_1.clear()
	# 读取已领取清单与存档进度
	tsk_lq = get_tsk_lq()
	var stg = get_stg()
	# 组装列表：已领取的任务不显示，其余按序号升序
	var lie_biao: Array = []
	for T_id in range(1, 61):
		if not tsk_lq.has("%04d" % T_id):
			lie_biao.append(T_id)
	# 按动态总数设置分页（全部领完时总数为0，翻页按钮自动置灰）
	fan_ye_tsk.she_zhi(lie_biao.size())
	# 本页第一个任务的偏移与行数
	var qi = fan_ye_tsk.qi_shi()
	var hang_shu = max(0, min(8, lie_biao.size() - qi))
	for j in range(hang_shu):
		var T_id = lie_biao[qi + j]
		# 进度大于任务号即表示该关已通关，可领取
		var ke_ling = stg > T_id
		# 创建任务项
		var tsk_2 = C_tsk(T_id, ke_ling, j)
		tsk.add_child(tsk_2)
		tsk_1.append(tsk_2)

# 创建单个任务项（T_id=任务号，ke_ling=是否可领取，hang=本页行号）
func C_tsk(T_id: int, ke_ling: bool, hang: int) -> Control:
	var tsk_3 = Control.new()
	tsk_3.size = Vector2(280, 54)
	tsk_3.position = Vector2(0,hang*59)
	# 创建任务背景（签名框）
	var tsk_bg = TextureRect.new()
	tsk_bg.texture = load("res://关卡/信息/签名框1.png")
	tsk_3.add_child(tsk_bg)
	# 创建任务文本
	var lbl = Label.new()
	lbl.name = "任务文本"
	# 根据关卡显示不同奖励（关号统一两位补零：01~09、10~30）
	if T_id > 30:
		# 支线任务（31~60关对应支线1~30关）
		var zx_n = T_id - 30
		var zx_jt = ZX_JIN_TIAO[zx_n - 1]
		lbl.text = tr("通过%s·%02d关   奖励：%s×%d") % [tr("支线"), zx_n, tr("金条"), zx_jt]
	elif T_id >= 30:
		lbl.text = tr("通过%s·%02d关   奖励：%s×%d") % [tr("主线"), T_id, tr("金条"), 7]
	elif T_id > 23:
		lbl.text = tr("通过%s·%02d关   奖励：%s×%d") % [tr("主线"), T_id, tr("金条"), 1]
	elif T_id == 23:
		lbl.text = tr("通过%s·%02d关   奖励：%d银币") % [tr("主线"), T_id, 333]
	else:
		# 1~22关：银币按等差数列递增（第n关=10×(n+1)）
		lbl.text = tr("通过%s·%02d关   奖励：%d银币") % [tr("主线"), T_id, 10 * (T_id + 1)]
	lbl.size = Vector2(280,54) # 任务文本范围
	lbl.position = Vector2(24,17) # 任务文本位置
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		lbl.add_theme_font_override("font", kai_ti)
	if ke_ling:
		lbl.add_theme_color_override("font_color", Color("00ff00"))
	else:
		lbl.add_theme_color_override("font_color", Color("000000"))
	tsk_3.add_child(lbl)
	# 如果可领取，添加点击领取功能
	if ke_ling:
		tsk_3.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				get_tsk_R(T_id)
		)
	return tsk_3

# 领取任务奖励
func get_tsk_R(T_id: int) -> void:
	# 只允许领取「已达成且未领取」的任务，重复点击不会二次发奖
	tsk_lq = get_tsk_lq()
	if not tsk_ke_ling(T_id):
		return
	# 给予奖励
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 != null:
		var data = json_1.du_qu(json_1.id)
		# 根据关卡给予不同奖励
		if T_id <= 22:
			# 1~22关：银币按等差数列递增（第n关=10×(n+1)，即20、30……230）
			var S = int(data.get("银币", 0))
			var jiang_li = 10 * (T_id + 1)
			S += jiang_li
			data["银币"] = S
			提示弹幕.wen_ben(tr("获得%d银币！") % jiang_li, 0)
		elif T_id == 23:
			# 第23关：333银币
			var S = int(data.get("银币", 0))
			S += 333
			data["银币"] = S
			提示弹幕.wen_ben(tr("获得%d银币！") % 333, 0)
		elif T_id == 30:
			# 主线第30关：金条×7
			var bag = data.get("背包", {})
			bag["金条"] = int(bag.get("金条", 0)) + 7
			data["背包"] = bag
			提示弹幕.wen_ben(tr("获得%s×%d！") % [tr("金条"), 7], 0)
		elif T_id > 30:
			# 支线任务（31~60关）：按支线金条奖励表发放
			var zx_n = T_id - 30
			var zx_jt = ZX_JIN_TIAO[zx_n - 1]
			var bag = data.get("背包", {})
			bag["金条"] = int(bag.get("金条", 0)) + zx_jt
			data["背包"] = bag
			提示弹幕.wen_ben(tr("获得%s×%d！") % [tr("金条"), zx_jt], 0)
		else:
			# 24~29关：金条×1
			var bag = data.get("背包", {})
			bag["金条"] = int(bag.get("金条", 0)) + 1
			data["背包"] = bag
			提示弹幕.wen_ben(tr("获得%s×%d！") % [tr("金条"), 1], 0)
		# 记录已领取任务序号（4位字符串，保留前导零）
		tsk_lq.append("%04d" % T_id)
		data["任务"] = tsk_lq
		json_1.bao_cun(json_1.id, data)
	# 刷新任务列表
	upd_tsk()

# 获取存档进度
func get_stg() -> int:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return 1
	var data = json_1.du_qu(json_1.id)
	return int(data.get("进度", 1))

# 从存档读取已领取成就序号清单（旧格式/字段缺失一律视为空清单）
func get_ach() -> void:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	ach_lq = [] if json_1 == null else json_1.get_ach_lq()

# 检查背包是否有指定物品
func has_item(item_name: String) -> bool:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return false
	var data = json_1.du_qu(json_1.id)
	var bag = data.get("背包", {})
	return bag.has(item_name) and int(bag.get(item_name, 0)) > 0

# 检查指定成就的达成条件（不看领取状态）
func chk_ach(idx: int) -> bool:
	if idx < 0 or idx >= ach_data.size():
		return false
	var config = ach_data[idx]
	var type_1 = config[3]
	var value = config[4]
	if type_1 == 0:
		# 条件类型0：背包物品检测
		return has_item(value)
	elif type_1 == 1:
		# 条件类型1：进度检测
		return get_stg() >= value
	elif type_1 == 2:
		# 条件类型2：同时拥有四种奇花
		return has_item("百合") and has_item("水仙") and has_item("玫瑰") and has_item("鸢尾")
	return false

# 获取成就状态：0=已完成未领取，1=已领取，2=未完成
func ach_zhuang_tai(idx: int) -> int:
	if ach_lq.has(str(ach_data[idx][0])):
		return 1
	if chk_ach(idx):
		return 0
	return 2

# 创建单个成就项（idx=成就下标，hang=本页行号，state=成就状态）
func C_ach(idx: int, hang: int, state: int) -> Control:
	var ach_3 = Control.new()
	ach_3.size = Vector2(280, 64)
	ach_3.position = Vector2(0, 6 + hang*66)
	# 获取成就配置数据
	var config = ach_data[idx]
	var ach_name = config[1]
	var tu_biao = config[2]       # 图标名（救世主Ⅰ/Ⅱ共用"救世主"图标）
	var jiang_li = config[5]      # 奖励物品名
	var jiang_li_n = config[6]    # 奖励数量
	# 创建成就背景（使用签名框背景）
	var ach_bg = TextureRect.new()
	ach_bg.texture = load("res://关卡/信息/签名框1.png")
	ach_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ach_bg.size = Vector2(280, 64)
	ach_3.add_child(ach_bg)
	# 创建成就图标（已领取用1图，其余用0图）
	var ach_icon = TextureRect.new()
	ach_icon.texture = load("res://主城/图片/" + tu_biao + ("1" if state == 1 else "0") + ".png")
	ach_3.add_child(ach_icon)
	# 创建成就文本标签
	var lbl = Label.new()
	lbl.name = "成就文本"
	lbl.size = Vector2(200,64)
	lbl.position = Vector2(80,0)
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		lbl.add_theme_font_override("font", kai_ti)
	if state == 1:
		lbl.text = tr("\n已获得成就【%s】") % tr(ach_name)
		lbl.add_theme_color_override("font_color", Color("000000"))
	else:
		# 未完成或可领取状态：显示完成条件和奖励
		var cond_text = config[7]  # 使用配置中的条件描述
		lbl.text = tr("\n%s\n奖励：%s×%d") % [tr(cond_text), tr(jiang_li), jiang_li_n]
		if state == 0: # 可领取状态：绿色文本
			lbl.add_theme_color_override("font_color", Color("00ff00"))
		else: # 未完成状态：黑色文本
			lbl.add_theme_color_override("font_color", Color("000000"))
	ach_3.add_child(lbl)
	if state == 0: # 如果可领取，添加点击领取功能
		ach_3.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				get_ach_R(idx)
		)
	return ach_3

# 领取成就奖励
func get_ach_R(idx: int) -> void:
	if idx < 0 or idx >= ach_data.size():
		return
	# 检查是否可领取
	if ach_zhuang_tai(idx) != 0:
		return
	var config = ach_data[idx]
	var xu_hao = str(config[0])   # 成就序号（4位字符串，保留前导零）
	var ach_name = config[1]
	var jiang_li = config[5]      # 奖励物品名
	var jiang_li_n = config[6]    # 奖励数量
	# 获取存档数据
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return
	var data = json_1.du_qu(json_1.id)
	var bag = data.get("背包", {})
	var tip_text = ""
	if ach_name == "采花贼":
		# 采花贼特殊奖励：99朵奇花等概率随机分配给四种花
		var hua_ming = ["百合", "水仙", "玫瑰", "鸢尾"]
		var hua_n = [0, 0, 0, 0]
		for i in range(jiang_li_n):
			hua_n[randi() % 4] += 1
		# 发放到背包并构建提示文本
		var parts = []
		for i in range(4):
			if hua_n[i] > 0:
				bag[hua_ming[i]] = int(bag.get(hua_ming[i], 0)) + hua_n[i]
				parts.append("%s×%d" % [tr(hua_ming[i]), hua_n[i]])
		tip_text = tr("恭喜获得成就【%s】！\n获得%s！") % [tr(ach_name), "、".join(parts)]
	else:
		# 普通成就：直接发放指定物品
		bag[jiang_li] = int(bag.get(jiang_li, 0)) + jiang_li_n
		tip_text = tr("恭喜获得成就【%s】！\n奖励%s×%d！") % [tr(ach_name), tr(jiang_li), jiang_li_n]
	data["背包"] = bag
	# 保存存档（成就字段只记录已领取的序号清单）
	ach_lq.append(xu_hao)
	data["成就"] = ach_lq
	json_1.bao_cun(json_1.id, data)
	# 同步记录到通用存档历史成就
	json_1.add_ach_ty(xu_hao)
	# 同步上报 Steam 成就（Steam 不可用时静默跳过）
	Steam管理.jie_suo(xu_hao)
	# 显示获得提示
	提示弹幕.wen_ben(tip_text, 0)
	# 刷新成就列表
	upd_ach()

# 刷新成就列表（状态实时推导 + 两级排序 + 每页6行）
func upd_ach() -> void:
	# 清空现有成就项
	for i in ach_1:
		i.queue_free()
	ach_1.clear()
	# 获取最新已领取清单
	get_ach()
	# 排序依据：[状态, 序号数值, 成就下标]
	# 状态分组：已完成未领取(0) → 已完成已领取(1) → 未完成(2)，组内按序号升序
	var lie_biao: Array = []
	for i in range(ach_data.size()):
		lie_biao.append([ach_zhuang_tai(i), int(ach_data[i][0]), i])
	lie_biao.sort_custom(func(a, b):
		if a[0] != b[0]:
			return a[0] < b[0]
		return a[1] < b[1]
	)
	# 设置总数并按页创建
	fan_ye_ach.she_zhi(lie_biao.size())
	var qi = fan_ye_ach.qi_shi()
	var hang_shu = min(6, lie_biao.size() - qi)
	for j in range(hang_shu):
		var xiang = lie_biao[qi + j]
		var ach_3 = C_ach(xiang[2], j, xiang[0])
		ach.add_child(ach_3)
		ach_1.append(ach_3)
