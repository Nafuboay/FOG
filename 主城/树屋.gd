extends Control # 树屋-任务/成就界面
var is_tsk: bool = true    # 是否选中任务标签
var is_ach: bool = false   # 是否选中成就标签
var shu_wu: Control # 界面容器
var bg: TextureRect # 背景面板
var tsk_btn: TextureRect # 任务标签图片
var ach_btn: TextureRect # 成就标签图片
var tsk: Control # 任务容器
var ach: Control # 成就容器
var tsk_1: Array = [] # 任务项列表
var ach_1: Array = [] # 成就项列表
var ach_2: Array = [0, 0, 0] # 当前存档的成就状态
var ach_data: Array = [ # 成就配置数据: [成就名称,条件类型,条件值,奖励金条数量,条件描述]
	["不朽者", 0, "破损稻草人", 1, "获得【破损稻草人】"],
	["救世主", 1, 31, 10, "击败犽翡及其爪牙"],
	["饮虹使", 0, "彩虹", 100, "获得【彩虹】"]
]

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
	upd_tsk()

func get_tsk() -> int: # 获取当前任务进度
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return 1
	var data = json_1.du_qu(json_1.id)
	return int(data.get("任务",1))

# 刷新任务列表
func upd_tsk() -> void:
	# 清空现有任务
	for i in tsk_1:
		i.queue_free()
	tsk_1.clear()
	# 获取存档进度
	var stg = get_stg()
	# 获取当前任务进度
	var tsk_ing = get_tsk()
	# 创建任务项（最多显示8个）
	var tsk_8 = 0
	for T_id in range(tsk_ing, 31):
		if tsk_8 >= 8:
			break
		var F = stg > T_id
		# 创建任务项
		var tsk_2 = C_tsk(T_id,F)
		tsk.add_child(tsk_2)
		tsk_1.append(tsk_2)
		tsk_8 += 1

# 创建单个任务项
func C_tsk(T_id: int, F: bool) -> Control:
	var tsk_3 = Control.new()
	tsk_3.size = Vector2(280, 54)
	tsk_3.position = Vector2(0,tsk_1.size()*59)
	# 创建任务背景（签名框）
	var tsk_bg = TextureRect.new()
	tsk_bg.texture = load("res://关卡/信息/签名框1.png")
	tsk_3.add_child(tsk_bg)
	# 获取当前任务进度
	var tsk_ing = get_tsk()
	# 判断是否可领取
	var F_1 = F and T_id == tsk_ing
	# 创建任务文本
	var lbl = Label.new()
	lbl.name = "任务文本"
	# 根据关卡显示不同奖励
	if T_id > 23:
		lbl.text = "通过主线·%d关   奖励：金条×1" % T_id
	elif T_id > 9:
		lbl.text = "通过主线·%d关   奖励：100银币" % T_id
	else:
		lbl.text = "通过主线·%d关    奖励：100银币" % T_id
	lbl.size = Vector2(280,54) # 任务文本范围
	lbl.position = Vector2(24,17) # 任务文本位置
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		lbl.add_theme_font_override("font", kai_ti)
	if F_1:
		lbl.add_theme_color_override("font_color", Color("00ff00"))
	else:
		lbl.add_theme_color_override("font_color", Color("000000"))
	tsk_3.add_child(lbl)
	# 如果可领取，添加点击领取功能
	if F_1:
		tsk_3.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				get_tsk_R(T_id)
		)
	return tsk_3

# 领取任务奖励
func get_tsk_R(T_id: int) -> void:
	# 获取当前任务进度
	var tsk_ing = get_tsk()
	# 只能领取当前任务
	if T_id != tsk_ing:
		return
	# 给予奖励
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 != null:
		var data = json_1.du_qu(json_1.id)
		# 根据关卡给予不同奖励
		if T_id < 24:
			var S = int(data.get("银币", 0))
			S += 100
			data["银币"] = S
			提示弹幕.wen_ben("获得100银币！", 0)
		else:
			var bag = data.get("背包", {})
			bag["金条"] = int(bag.get("金条", 0)) + 1
			data["背包"] = bag
			提示弹幕.wen_ben("获得金条×1！", 0)
		# 更新任务进度
		data["任务"] = tsk_ing + 1
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

# 获取存档中的成就状态
func get_ach() -> void:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		ach_2 = [0, 0, 0]
		return
	var data = json_1.du_qu(json_1.id)
	ach_2 = data.get("成就", [0, 0, 0])

# 检查背包是否有指定物品
func has_item(item_name: String) -> bool:
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return false
	var data = json_1.du_qu(json_1.id)
	var bag = data.get("背包", {})
	return bag.has(item_name) and int(bag.get(item_name, 0)) > 0

# 检查指定成就是否完成（未领取状态下检测条件）
func chk_ach(idx: int) -> bool:
	if idx < 0 or idx >= ach_data.size():
		return false
	# 如果已领取，直接返回false
	if ach_2[idx] == 1:
		return false
	var config = ach_data[idx]
	var type_1 = config[1]
	var value = config[2]
	if type_1 == 0:
		# 条件类型0：背包物品检测
		return has_item(value)
	elif type_1 == 1:
		# 条件类型1：进度检测
		return get_stg() >= value
	return false

# 创建单个成就项
func C_ach(idx: int, state: int) -> Control:
	var ach_3 = Control.new()
	ach_3.size = Vector2(280, 64)
	ach_3.position = Vector2(0,ach_1.size()*110+32)
	# 获取成就配置数据
	var config = ach_data[idx]
	var ach_name = config[0]
	var reward = config[3]
	# 创建成就背景（使用签名框背景）
	var ach_bg = TextureRect.new()
	ach_bg.texture = load("res://关卡/信息/签名框1.png")
	ach_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ach_bg.size = Vector2(280, 64)
	ach_3.add_child(ach_bg)
	# 创建成就图标
	var ach_icon = TextureRect.new()
	ach_icon.texture = load("res://主城/图片/" + ach_name + str(state) + ".png")
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
		lbl.text = "\n已获得成就《%s》" % ach_name
		lbl.add_theme_color_override("font_color", Color("000000"))
	else:
		# 未完成或可领取状态：显示完成条件和奖励
		var cond_text = config[4]  # 使用配置中的条件描述
		lbl.text = "\n%s\n奖励：金条×%d" % [cond_text, reward]
		if chk_ach(idx): # 可领取状态：绿色文本
			lbl.add_theme_color_override("font_color", Color("00ff00"))
		else: # 未完成状态：黑色文本
			lbl.add_theme_color_override("font_color", Color("000000"))
	ach_3.add_child(lbl)
	if state == 0 and chk_ach(idx): # 如果可领取，添加点击领取功能
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
	if ach_2[idx] == 1 or not chk_ach(idx):
		return
	var config = ach_data[idx]
	var ach_name = config[0]
	var reward = config[3]
	# 获取存档数据
	var json_1 = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json_1 == null:
		return
	var data = json_1.du_qu(json_1.id)
	# 增加金条奖励
	var bag = data.get("背包", {})
	bag["金条"] = int(bag.get("金条", 0)) + reward
	data["背包"] = bag
	# 更新成就状态为已领取
	ach_2[idx] = 1
	data["成就"] = ach_2
	# 保存存档
	json_1.bao_cun(json_1.id, data)
	# 显示获得提示
	提示弹幕.wen_ben("恭喜获得成就《%s》！\n奖励金条×%d！" % [ach_name, reward], 0)
	# 刷新成就列表
	upd_ach()

# 刷新成就列表
func upd_ach() -> void:
	# 清空现有成就项
	for i in ach_1:
		i.queue_free()
	ach_1.clear()
	# 获取最新成就状态
	get_ach()
	# 创建成就项
	for i in range(ach_data.size()):
		var state = ach_2[i]
		if state == 0 and chk_ach(i): # 检测是否完成
			# 条件满足但未领取，状态仍为0但可点击
			pass
		var ach_3 = C_ach(i, state)
		ach.add_child(ach_3)
		ach_1.append(ach_3)
