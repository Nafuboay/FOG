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
var ach_ti_shi: Label = null # 成就页顶部提示行（富豪模式/读档失败）
var ach_lq: Array = [] # 当前存档已领取的成就序号清单
var fan_ye_tsk = null # 任务翻页系统
var fan_ye_ach = null # 成就翻页系统
var ach_data: Array = 成就配置.quan_bu() # 成就配置（唯一来源见 全局/成就配置.gd）
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
	# 成就页顶部提示行（富豪模式/读档失败时显示，标准模式隐藏）
	ach_ti_shi = Label.new()
	ach_ti_shi.text = tr("此存档无法获得成就")
	ach_ti_shi.size = Vector2(280, 24)
	ach_ti_shi.position = Vector2(0, 0)
	ach_ti_shi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ach_ti_shi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ach_ti_shi.add_theme_font_size_override("font_size", 16)
	ach_ti_shi.add_theme_color_override("font_color", Color.BLACK)
	var kai_ti_2 = 提示弹幕.get_kai_ti_font()
	if kai_ti_2 != null:
		ach_ti_shi.add_theme_font_override("font", kai_ti_2)
	ach_ti_shi.visible = false
	ach.add_child(ach_ti_shi)

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

# 获取存档当前银币数量（用于富豪系列成就实时判定）
func get_yin_bi() -> int:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return 0
	var data = json_1.du_qu(json_1.id)
	return int(data.get("银币", 0))

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
	var type_1 = int(config["tiao_jian"])
	var value = config["zhi"]
	if type_1 == 0:
		# 条件类型0：背包物品检测
		return has_item(value)
	elif type_1 == 1:
		# 条件类型1：进度检测
		return get_stg() >= value
	elif type_1 == 2:
		# 条件类型2：同时拥有四种奇花
		return has_item("百合") and has_item("水仙") and has_item("玫瑰") and has_item("鸢尾")
	elif type_1 == 3:
		# 条件类型3：银币持有量检测（实时读取当前存档银币，未领取前花掉则回到未完成）
		return get_yin_bi() >= int(value)
	return false

# 获取成就状态：0=已完成未领取，1=已领取，2=未完成
func ach_zhuang_tai(idx: int) -> int:
	if ach_lq.has(str(ach_data[idx]["xu_hao"])):
		return 1
	if chk_ach(idx):
		return 0
	return 2

# 创建单个成就项（idx=成就下标，hang=本页行号，state=成就状态，fu_hao=富豪模式版式）
func C_ach(idx: int, hang: int, state: int, fu_hao: bool = false) -> Control:
	# 配置非法时跳过展示，不占用行号
	var config = ach_data[idx]
	if not 成就配置.he_fa(config):
		return null
	var ach_3 = Control.new()
	ach_3.size = Vector2(280, 64)
	# 每页6行按容器高度均分；富豪模式为顶部提示行让位，行距略收紧
	ach_3.position = Vector2(0, 30 + hang*73) if fu_hao else Vector2(0, 6 + hang*79)
	# 获取成就配置数据
	var ach_name = config["ming"]
	var tu_biao = config["tu_biao"]       # 图标名（救世主Ⅰ/Ⅱ共用"救世主"图标）
	var wu_pin = config["wu_pin"]         # 奖励物品名（空串=无物质奖励）
	var shu_liang = int(config["shu_liang"])  # 奖励数量
	var miao_shu = config["miao_shu"]     # 条件描述
	var ying_xiong = config["ying_xiong"] # 英雄绑定（空串=不绑定）
	# 创建成就背景（使用签名框背景）
	var ach_bg = TextureRect.new()
	ach_bg.texture = load("res://关卡/信息/签名框1.png")
	ach_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ach_bg.size = Vector2(280, 64)
	ach_3.add_child(ach_bg)
	# 创建成就图标（已领取用1图，其余用0图）
	# 富豪系列素材命名为「状态+图标名」（0A7/1A7），其余成就为「图标名+状态」（救世主0/救世主1）
	var ach_icon = TextureRect.new()
	var zt_1 = "1" if state == 1 else "0"
	if tu_biao.begins_with("A"):
		ach_icon.texture = load("res://主城/图片/" + zt_1 + tu_biao + ".png")
	else:
		ach_icon.texture = load("res://主城/图片/" + tu_biao + zt_1 + ".png")
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
		# 未完成或可领取状态：显示完成条件和奖励；无物质奖励时展示解锁英雄
		if 成就配置.you_wu_zhi_jiang_li(config):
			if wu_pin == "银币":
				# 银币奖励直接写数量
				lbl.text = tr("\n%s\n奖励：%s银币") % [tr(miao_shu), 排版工具.shu_zi_suo_xie(shu_liang)]
			else:
				lbl.text = tr("\n%s\n奖励：%s×%s") % [tr(miao_shu), tr(wu_pin), 排版工具.shu_zi_suo_xie(shu_liang)]
		elif not str(ying_xiong).is_empty():
			lbl.text = "\n" + tr(miao_shu) + "\n" + tr("解锁英雄【%s】") % tr(ying_xiong)
		else:
			lbl.text = tr("\n%s") % tr(miao_shu)
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
	# 获取存档数据（模式判定与后续发放共用同一次读取）
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		提示弹幕.wen_ben(tr("存档读取失败，请稍后重试"), 0)
		return
	var data = json_1.du_qu(json_1.id)
	if data.is_empty():
		提示弹幕.wen_ben(tr("存档读取失败，请稍后重试"), 0)
		return
	var config = ach_data[idx]
	var xu_hao: String = str(config["xu_hao"])   # 成就序号（4位字符串，保留前导零）
	if not 成就配置.he_fa(config):
		日志.打印("成就配置非法：" + xu_hao)
		return
	# 富豪模式封禁成就：不判定条件、不发奖、不写任何记录
	if 游戏存档.mo_shi_biao_zhi_of(data) == 游戏存档.MO_SHI_FU_HAO:
		日志.打印("富豪模式拒绝领取成就：" + xu_hao + " 槽位=" + str(json_1.id))
		return
	# 检查是否可领取（未完成不可领、已获得不可再领）
	if ach_zhuang_tai(idx) != 0:
		return
	var ach_name: String = str(config["ming"])
	var wu_pin: String = str(config["wu_pin"])   # 奖励物品名（空串=无物质奖励）
	var shu_liang: int = int(config["shu_liang"])  # 奖励数量
	var ying_xiong: String = str(config["ying_xiong"]) # 英雄绑定（空串=不绑定）
	var bag = data.get("背包", {})
	var tip_text = ""
	if ach_name == "采花贼":
		# 采花贼特殊奖励：99朵奇花等概率随机分配给四种花
		var hua_ming = ["百合", "水仙", "玫瑰", "鸢尾"]
		var hua_n = [0, 0, 0, 0]
		for i in range(shu_liang):
			hua_n[randi() % 4] += 1
		# 发放到背包并构建提示文本
		var parts = []
		for i in range(4):
			if hua_n[i] > 0:
				bag[hua_ming[i]] = int(bag.get(hua_ming[i], 0)) + hua_n[i]
				parts.append("%s×%d" % [tr(hua_ming[i]), hua_n[i]])
		data["背包"] = bag
		tip_text = tr("恭喜获得成就【%s】！\n获得%s！") % [tr(ach_name), "、".join(parts)]
	elif 成就配置.you_wu_zhi_jiang_li(config):
		if wu_pin == "银币":
			# 银币类成就奖励：直接写入存档银币字段，不进入背包
			data["银币"] = int(data.get("银币", 0)) + shu_liang
			tip_text = tr("恭喜获得成就【%s】！\n奖励%s银币！") % [tr(ach_name), 排版工具.shu_zi_suo_xie(shu_liang)]
		else:
			# 普通成就：直接发放指定物品
			bag[wu_pin] = int(bag.get(wu_pin, 0)) + shu_liang
			data["背包"] = bag
			tip_text = tr("恭喜获得成就【%s】！\n奖励%s×%s！") % [tr(ach_name), tr(wu_pin), 排版工具.shu_zi_suo_xie(shu_liang)]
	elif not ying_xiong.is_empty():
		# 无物质奖励：只解锁英雄，不写背包/银币
		tip_text = tr("恭喜获得成就【%s】！") % tr(ach_name) + "\n" + tr("解锁英雄【%s】！") % tr(ying_xiong)
	else:
		tip_text = tr("恭喜获得成就【%s】！") % tr(ach_name)
	# 提交前构造新清单，避免重复点击或状态滞后产生重复序号
	var xin_lq: Array = ach_lq.duplicate()
	if not xin_lq.has(xu_hao):
		xin_lq.append(xu_hao)
	data["成就"] = xin_lq
	# 单次写入并校验返回值：失败时不提交任何内存状态，成就保持可领取
	if not json_1.bao_cun(json_1.id, data):
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		日志.打印("成就保存失败：" + xu_hao)
		upd_ach()
		return
	ach_lq = xin_lq
	# 同步记录到通用存档历史成就（失败仅记日志，不回滚已写入的当前存档）
	if not json_1.add_ach_ty(xu_hao):
		日志.打印("历史成就写入失败：" + xu_hao)
	# 同步上报 Steam 成就（Steam 不可用时静默跳过）
	Steam管理.jie_suo(xu_hao)
	# 显示获得提示
	提示弹幕.wen_ben(tip_text, 0)
	# 刷新成就列表
	upd_ach()
	日志.打印("成就领取成功：" + xu_hao)

# 刷新成就列表（状态实时推导 + 两级排序 + 每页6行）
func upd_ach() -> void:
	# 清空现有成就项
	for i in ach_1:
		i.queue_free()
	ach_1.clear()
	# 单次读取当前存档：模式与已领取清单共用本次数据
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	var data: Dictionary = {} if json_1 == null else json_1.du_qu(json_1.id)
	var du_qu_shi_bai: bool = json_1 == null or data.is_empty()
	var fu_hao: bool = false
	if not du_qu_shi_bai:
		fu_hao = 游戏存档.mo_shi_biao_zhi_of(data) == 游戏存档.MO_SHI_FU_HAO
	ach_lq = [] if du_qu_shi_bai else 游戏存档.ach_lq_of(data)
	# 顶部提示行：读档失败或富豪模式时显示
	if ach_ti_shi != null:
		ach_ti_shi.text = tr("存档读取失败，请稍后重试") if du_qu_shi_bai else tr("此存档无法获得成就")
		ach_ti_shi.visible = du_qu_shi_bai or fu_hao
	# 富豪模式/读档失败：不判定任何条件，全部按未获得展示，仅按序号升序
	if du_qu_shi_bai or fu_hao:
		var lie_biao_bu_ke: Array = []
		for i in range(ach_data.size()):
			lie_biao_bu_ke.append([2, int(ach_data[i]["xu_hao"]), i])
		lie_biao_bu_ke.sort_custom(func(a, b): return a[1] < b[1])
		fan_ye_ach.she_zhi(lie_biao_bu_ke.size())
		var qi_bu_ke = fan_ye_ach.qi_shi()
		var hang_shu_bu_ke = min(6, lie_biao_bu_ke.size() - qi_bu_ke)
		for j in range(hang_shu_bu_ke):
			var xiang_bu_ke = lie_biao_bu_ke[qi_bu_ke + j]
			var ach_bu_ke = C_ach(xiang_bu_ke[2], j, 2, true)
			# 配置非法时不展示，该行留空
			if ach_bu_ke == null:
				continue
			ach.add_child(ach_bu_ke)
			ach_1.append(ach_bu_ke)
		return
	# 排序依据：[状态, 序号数值, 成就下标]
	# 状态分组：已完成未领取(0) → 已完成已领取(1) → 未完成(2)，组内按序号升序
	var lie_biao: Array = []
	for i in range(ach_data.size()):
		lie_biao.append([ach_zhuang_tai(i), int(ach_data[i]["xu_hao"]), i])
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
		# 配置非法时不展示，该行留空
		if ach_3 == null:
			continue
		ach.add_child(ach_3)
		ach_1.append(ach_3)
