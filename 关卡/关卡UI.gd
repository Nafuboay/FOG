class_name 关卡UI extends Node
# 父节点引用（关卡节点）
var guan_qia: Node
# 撤退按钮
var che_tui: TextureRect
# 撤退图片引用
var che_tui_1: Texture2D
var che_tui_2: Texture2D
# 背包引用
var BB: Control = null
# 音量调节引用
var YL: Control = null
# 道具容器
var dao_ju: Control = null
# 选定恢复等级（0表示未选定，1-6对应等级）
var hui_fu_lv: int = 0
# 恢复符启用中
var hui_fu_ing: TextureRect = null
# 人物按钮
var helo_btn: TextureRect = null
var png1: Texture2D = null  # 人物按钮图片
# 怪物按钮
var guai_wu_btn: TextureRect = null
var png2: Texture2D = null  # 怪物按钮图片

# 获取父节点
func _ready() -> void:
	var parent = get_parent()
	# 父节点不是关卡基类时向上查找（兼容诛邪等子类场景）
	if not (parent is 关卡基类):
		parent = parent.get_parent()
	guan_qia = parent
	# 实例化背包系统
	BB = load("res://全局/空间袋.gd").new()
	BB.name = "背包"
	guan_qia.add_child(BB)
	# 实例化音量调节系统
	YL = load("res://音乐/音量调节.gd").new()
	YL.name = "音量调节"
	guan_qia.add_child(YL)
	# 创建道具容器
	C_dao_ju()
	# 将当前节点添加到背包状态监听组
	add_to_group("BB_3")

# 背包状态改变处理函数
func BB_4(BB_on: bool) -> void:
	if BB_on:
		# 背包打开时：隐藏人物面板（左侧），删除怪物面板（右侧）
		# 隐藏人物面板
		if guan_qia.look_helo != null:
			guan_qia.look_helo.visible = false
		if guan_qia.kuai_1 != null:
			guan_qia.kuai_1.visible = false
		# 删除怪物面板
		if guan_qia.look_guai_wu != null:
			guan_qia.look_guai_wu.queue_free()
			guan_qia.look_guai_wu = null
		if guan_qia.kuai_2 != null:
			guan_qia.kuai_2.queue_free()
			guan_qia.kuai_2 = null
		guan_qia.guai_wu_x_ing = -1
		guan_qia.guai_wu_y_ing = -1

# 创建怪物数量文本
func C_guai_wu_lbl() -> void:
	# 加载签名框背景图片
	var kuang = load("res://关卡/信息/签名框.png")
	# 创建背景TextureRect
	var png = TextureRect.new()
	png.texture = kuang
	png.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	png.size = Vector2(166,32)
	png.position = Vector2(278.5,16)
	png.z_index = 1000
	# 创建Label对象
	guan_qia.guai_wu_lbl = Label.new()
	guan_qia.guai_wu_lbl.size = Vector2(166, 32)
	# 设置文本内容
	guan_qia.guai_wu_lbl.text = "怪物数量：" + str(guan_qia.guai_wu_xian) + "/" + str(guan_qia.guai_wu_zong)
	# 设置文字颜色为纯黑色
	guan_qia.guai_wu_lbl.add_theme_color_override("font_color", Color.BLACK)
	# 文本层级
	guan_qia.guai_wu_lbl.z_index = 1000
	# 文字居中
	guan_qia.guai_wu_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guan_qia.guai_wu_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 添加到场景
	guan_qia.add_child(png)
	png.add_child(guan_qia.guai_wu_lbl)

# 创建关卡标签
func C_guan_kia_lbl() -> void:
	# 加载签名框背景图片
	var kuang = load("res://关卡/信息/签名框.png")
	# 创建背景TextureRect
	var png = TextureRect.new()
	png.texture = kuang
	png.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	png.size = Vector2(166,32)
	png.position = Vector2(557,16)
	png.z_index = 1000
	# 创建Label对象
	guan_qia.guan_kia_lbl = Label.new()
	guan_qia.guan_kia_lbl.size = Vector2(166, 32)
	# 根据模式设置标题：诛邪为「诛邪·m级」，主线为「主线·n关」
	var cur_mode = 0
	if has_node("/root/数据管理"):
		cur_mode = get_node("/root/数据管理").mode
	var zx_lv = guan_qia.get("zx_lv")
	if cur_mode == 1 and zx_lv != null:
		guan_qia.guan_kia_lbl.text = "诛邪·" + str(int(zx_lv)) + "级"
	else:
		guan_qia.guan_kia_lbl.text = "主线·" + str(guan_qia.guan_kia_id + 1) + "关"
	# 设置文字颜色为纯黑色
	guan_qia.guan_kia_lbl.add_theme_color_override("font_color", Color.BLACK)
	# 文本层级
	guan_qia.guan_kia_lbl.z_index = 1000
	# 文字居中
	guan_qia.guan_kia_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guan_qia.guan_kia_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 添加到场景
	guan_qia.add_child(png)
	png.add_child(guan_qia.guan_kia_lbl)

# 创建可缩放容器
func C_rong_qi() -> void:
	# 加载签名框背景图片
	var kuang = load("res://关卡/信息/签名框.png")
	# 创建背景TextureRect
	var png = TextureRect.new()
	png.texture = kuang
	png.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	png.size = Vector2(166,32)
	png.position = Vector2(835.5,16)
	png.z_index = 1000
	# 显示文本
	guan_qia.suo_fang_lal = Label.new()
	guan_qia.suo_fang_lal.size = Vector2(166, 32)
	guan_qia.suo_fang_lal.text = "画面比例：100%"
	# 设置文字颜色为纯黑色
	guan_qia.suo_fang_lal.add_theme_color_override("font_color", Color.BLACK)
	guan_qia.suo_fang_lal.z_index = 1000
	# 文字居中
	guan_qia.suo_fang_lal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guan_qia.suo_fang_lal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	guan_qia.add_child(png)
	png.add_child(guan_qia.suo_fang_lal)
	# 加载缩小按钮图片
	var suo_xiao_0 = load("res://关卡/信息/缩小0.png")
	var suo_xiao_1 = load("res://关卡/信息/缩小1.png")
	# 缩小按钮
	var suo_xiao_an_niu = TextureRect.new()
	suo_xiao_an_niu.texture = suo_xiao_0
	suo_xiao_an_niu.position = Vector2(1016,32)
	suo_xiao_an_niu.z_index = 1000
	suo_xiao_an_niu.mouse_entered.connect(func(): suo_xiao_an_niu.texture = suo_xiao_1)
	suo_xiao_an_niu.mouse_exited.connect(func(): suo_xiao_an_niu.texture = suo_xiao_0)
	suo_xiao_an_niu.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			suo_fang_upd(false)
			get_viewport().gui_release_focus()
	)
	guan_qia.add_child(suo_xiao_an_niu)
	# 加载放大按钮图片
	var fang_da_0 = load("res://关卡/信息/放大0.png")
	var fang_da_1 = load("res://关卡/信息/放大1.png")
	# 放大按钮
	var fang_da_an_niu = TextureRect.new()
	fang_da_an_niu.texture = fang_da_0
	fang_da_an_niu.position = Vector2(1096,32)
	fang_da_an_niu.z_index = 1000
	fang_da_an_niu.mouse_entered.connect(func(): fang_da_an_niu.texture = fang_da_1)
	fang_da_an_niu.mouse_exited.connect(func(): fang_da_an_niu.texture = fang_da_0)
	fang_da_an_niu.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			suo_fang_upd(true)
			get_viewport().gui_release_focus()
	)
	guan_qia.add_child(fang_da_an_niu)

# 重新挑战和背包按钮
func C_again() -> void:
	var upd_0 = load("res://关卡/信息/重新挑战0.png")
	var upd_1 = load("res://关卡/信息/重新挑战1.png")
	var an_niu = TextureRect.new()
	an_niu.texture = upd_0
	an_niu.z_index = 1000
	an_niu.mouse_entered.connect(func(): an_niu.texture = upd_1)
	an_niu.mouse_exited.connect(func(): an_niu.texture = upd_0)
	an_niu.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_again()
	)
	guan_qia.add_child(an_niu)
	C_che_tui()
	# 显示背包按钮
	BB.BB_1()
	# 更新道具显示
	dao_ju_upd()
	# 创建角色按钮
	C_role_btn()

# 撤退按钮
func C_che_tui() -> void:
	che_tui_1 = load("res://关卡/信息/撤退1.png")
	che_tui_2 = load("res://关卡/信息/撤退2.png")
	che_tui = TextureRect.new()
	che_tui.texture = che_tui_1
	che_tui.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	che_tui.size = Vector2(72,36)
	che_tui.z_index = 1000
	che_tui.visible = false
	che_tui.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_che_tui()
	)
	guan_qia.rong_qi.add_child(che_tui)
	che_tui_upd()

# 更新撤退按钮位置
func che_tui_upd() -> void:
	if guan_qia == null or che_tui == null:
		return
	var GZ_z = guan_qia.GZ_zhong(guan_qia.helo_x - 1, guan_qia.helo_y - 1)
	che_tui.position = Vector2(GZ_z.x-36,GZ_z.y+18)

# 创建道具容器
func C_dao_ju() -> void:
	dao_ju = Control.new()
	dao_ju.name = "道具"
	dao_ju.z_index = 1000
	dao_ju.visible = false
	guan_qia.add_child(dao_ju)

# 更新道具显示
func dao_ju_upd() -> void:
	if dao_ju == null:
		return
	# 清除现有图标
	for child in dao_ju.get_children():
		child.queue_free()
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 道具列表
	var dao_ju_list = ["1级恢复符","2级恢复符","3级恢复符","4级恢复符","5级恢复符","6级恢复符","优秀探测器","精良探测器","史诗探测器","神话探测器"]
	var p_x = 110
	var p_y = 631
	var p_1 = 50  # 物品宽度
	var p_2 = 64  # 总宽度
	var idx = 0
	# 记录恢复符位置用于显示启用标记
	var hui_fu_xy = Vector2(-1, -1)
	for wu_ming in dao_ju_list:
		if wu_pin.has(wu_ming):
			var n = int(wu_pin[wu_ming])
			if n > 0:
				# 创建物品图标
				if 物品信息.wu_pin_png.has(wu_ming):
					var wu_pin_tu = TextureRect.new()
					wu_pin_tu.texture = load(物品信息.wu_pin_png[wu_ming])
					wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					wu_pin_tu.size = Vector2(p_1,p_1)
					wu_pin_tu.position = Vector2(p_x+idx*p_2,p_y)
					wu_pin_tu.z_index = 1000
					# 为探测器添加点击事件
					if wu_ming in ["优秀探测器","精良探测器","史诗探测器","神话探测器"]:
						wu_pin_tu.gui_input.connect(func(event):
							if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
								Tan_ce_qi(wu_ming)
								get_viewport().gui_release_focus()
						)
					# 为恢复符添加点击事件
					if wu_ming.find("恢复符") != -1:
						var lv = int(wu_ming[0])  # 获取恢复符等级
						wu_pin_tu.gui_input.connect(func(event, wu_lv=lv):
							if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
								hui_fu_ING(wu_lv)
								get_viewport().gui_release_focus()
						)
						# 记录当前选定恢复符的位置
						if hui_fu_lv == lv:
							hui_fu_xy = Vector2(p_x+idx*p_2, p_y)
					dao_ju.add_child(wu_pin_tu)
					# 如果数量大于1，显示数量标签
					if n > 1:
						var wu_n = Label.new()
						wu_n.text = str(n)
						wu_n.add_theme_color_override("font_color", Color.BLACK)
						wu_n.position = Vector2(p_x+idx*p_2+p_1-wu_n.get_minimum_size().x+10,p_y+p_1-wu_n.get_minimum_size().y+10)
						wu_n.z_index = 1000
						dao_ju.add_child(wu_n)
					idx += 1
	# 显示启用中标记
	if hui_fu_lv > 0 and hui_fu_xy.x >= 0:
		hui_fu_ing = TextureRect.new()
		hui_fu_ing.texture = load("res://关卡/信息/启用中.png")
		hui_fu_ing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hui_fu_ing.size = Vector2(p_1, p_1)
		hui_fu_ing.position = hui_fu_xy
		hui_fu_ing.z_index = 1001
		# 取消启用中遮盖
		hui_fu_ing.mouse_filter = TextureRect.MOUSE_FILTER_IGNORE
		dao_ju.add_child(hui_fu_ing)
	# 设置可见性
	dao_ju.visible = idx > 0

# 恢复符选定处理
func hui_fu_ING(lv: int) -> void:
	# 点击同一个恢复符，取消选定
	if hui_fu_lv == lv:
		hui_fu_lv = 0
	else:
		# 点击不同的恢复符，切换选定
		hui_fu_lv = lv
	# 刷新道具显示
	dao_ju_upd()

# 使用探测器
func Tan_ce_qi(wu_ming: String) -> void:
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(guan_qia.json_id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 检查道具数量
	if not wu_pin.has(wu_ming) or int(wu_pin[wu_ming]) <= 0:
		return
	# 探测器探测半径配置{名称: 半径}，实际边长=半径×2+1
	var fan_wei_biao = {"优秀探测器": 1, "精良探测器": 2, "史诗探测器": 4, "神话探测器": 49}
	# 获取当前探测器的探测半径（神话半径49，超出地图边界遍历时自动截断，等同探明全图）
	var fan_wei = int(fan_wei_biao.get(wu_ming, -1))
	# 非探测器物品直接返回
	if fan_wei < 0:
		return
	# 获取人物当前位置（转换为0开始索引）
	var helo_x = guan_qia.helo_x - 1
	var helo_y = guan_qia.helo_y - 1
	# 检查范围内是否有未翻开的格子
	var you_wei_fan_kai = false
	for y in range(max(0, helo_y - fan_wei), min(guan_qia.GZ_y, helo_y + fan_wei + 1)):
		for x in range(max(0, helo_x - fan_wei), min(guan_qia.GZ_x, helo_x + fan_wei + 1)):
			if not guan_qia.GZ[y][x]["fan_kai"]:
				you_wei_fan_kai = true
				break
		if you_wei_fan_kai:
			break
	# 如果范围内所有格子都已翻开，不使用探测器并提示
	if not you_wei_fan_kai:
			提示弹幕.wen_ben("周围已经没有未探明的区域！", 0)
			return
	# 减少道具数量
	wu_pin[wu_ming] = int(wu_pin[wu_ming]) - 1
	# 如果数量变为0，删除该物品字段
	if int(wu_pin[wu_ming]) <= 0:
		wu_pin.erase(wu_ming)
	data["背包"] = wu_pin
	json.bao_cun(guan_qia.json_id, data)
	# 遍历范围内的格子并翻开
	for y in range(max(0, helo_y - fan_wei), min(guan_qia.GZ_y, helo_y + fan_wei + 1)):
		for x in range(max(0, helo_x - fan_wei), min(guan_qia.GZ_x, helo_x + fan_wei + 1)):
			# 如果格子未翻开，则翻开
			if not guan_qia.GZ[y][x]["fan_kai"]:
				guan_qia.fan_kai.kai_ge_zi(x, y, false)
	# 刷新道具显示
	dao_ju_upd()
	# 显示提示弹幕（显示探测器配置的名义边长）
	var shi_ji_fan_wei = fan_wei * 2 + 1
	提示弹幕.wen_ben("使用【" + wu_ming + "】探明了" + str(shi_ji_fan_wei) + "×" + str(shi_ji_fan_wei) + "及周边区域！", 0)

# 重新挑战按钮点击事件
func on_again() -> void:
	# 重新开始游戏
	get_tree().reload_current_scene()

# 撤退按钮点击事件
func on_che_tui() -> void:
	if guan_qia.zhan_dou.che_tui_ing:
		return
	guan_qia.zhan_dou.che_tui_ing = true
	che_tui.texture = che_tui_2
	guan_qia.zhan_dou.che_tui_0()
	get_viewport().gui_release_focus()

# 缩放刷新
func suo_fang_upd(fang_da: bool) -> void:
	if guan_qia.rong_qi == null:
		return
	# 获取当前缩放比例
	var suo_fang_ing = guan_qia.rong_qi.scale.x
	# 2的立方根（每次缩放的比例）
	var bei_shu = pow(2.0, 1.0 / 3.0)
	# 计算新的缩放比例
	var suo_fang_xin = suo_fang_ing * bei_shu if fang_da else suo_fang_ing / bei_shu
	# 限制缩放范围
	suo_fang_xin = clamp(suo_fang_xin, 0.25, 8.0)
	# 如果缩放比例没有变化，直接返回
	if abs(suo_fang_xin - suo_fang_ing) < 0.001:
		return
	# 计算缩放前屏幕中心对应的世界坐标
	var viewport_center = guan_qia.get_viewport_rect().size / 2
	var world_center_before = (viewport_center - guan_qia.rong_qi.position) / suo_fang_ing
	# 应用缩放
	guan_qia.rong_qi.scale = Vector2(suo_fang_xin, suo_fang_xin)
	# 调整位置，使原来屏幕中心的点保持在屏幕中心
	guan_qia.rong_qi.position = viewport_center - world_center_before * suo_fang_xin
	# 显示缩放百分比（四舍五入）
	guan_qia.suo_fang_lal.text = "画面比例：%d%%" % round(suo_fang_xin * 100)
	# 通知所有监听缩放变化的节点
	for node in get_tree().get_nodes_in_group("suo_fang_group"):
		if node.has_method("on_suo_fang_changed"):
			node.on_suo_fang_changed()

# 创建胜利界面
func C_sheng_li() -> void:
	# 更新存档进度
	var json = get_node("/root/游戏存档")
	var data = json.du_qu(guan_qia.json_id)
	var stg = round(data.get("进度", 1))
	if guan_qia.guan_kia_id + 1 == stg:
		data["进度"] = stg + 1
	# 计算并添加经验
	var exp_add = ji_suan_exp()
	var exp_0 = data.get("经验", 0)
	data["经验"] = exp_0 + exp_add
	# 调用游戏存档的升级检查函数
	json.chk_lv(data)
	# 同步背包物品到存档
	var wu_pin_ls = guan_qia.BB_ls
	if not wu_pin_ls.is_empty():
		var wu_pin = data.get("背包", {})
		for wu_ming in wu_pin_ls:
			var n = wu_pin_ls[wu_ming]
			if wu_pin.has(wu_ming):
				wu_pin[wu_ming] += n
			else:
				wu_pin[wu_ming] = n
		data["背包"] = wu_pin
	# 保存银币数据
	var S = data.get("银币", 0)
	data["银币"] = S
	json.bao_cun(guan_qia.json_id, data)
	# 经验弹幕
	提示弹幕.wen_ben("获得" + str(exp_add) + "经验。", 0)
	# 获取视口宽度用于居中显示（逻辑分辨率）
	var viewport_size = guan_qia.get_viewport_rect().size
	# 加载胜利图片
	var sheng_li = load("res://关卡/信息/胜利.png")
	# 创建胜利图片TextureRect
	var png_1 = TextureRect.new()
	png_1.texture = sheng_li
	png_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	png_1.size = Vector2(256,256)
	png_1.position = Vector2(viewport_size.x/2.0-128,64)
	png_1.z_index = 1000
	guan_qia.add_child(png_1)
	# 判断是否是最后一关
	var end = 关卡数据.guan_kia_n()
	if guan_qia.guan_kia_id < end - 1:
		# 加载下一关按钮图片
		var xia_yi_guan_0 = load("res://关卡/信息/下一关0.png")
		var xia_yi_guan_1 = load("res://关卡/信息/下一关1.png")
		# 创建下一关按钮
		var an_niu = TextureRect.new()
		an_niu.texture = xia_yi_guan_0
		an_niu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		an_niu.size = Vector2(150, 50)
		an_niu.position = Vector2(viewport_size.x/2.0-75,384)
		an_niu.z_index = 1000
		an_niu.mouse_entered.connect(func(): an_niu.texture = xia_yi_guan_1)
		an_niu.mouse_exited.connect(func(): an_niu.texture = xia_yi_guan_0)
		an_niu.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				on_xia_yi_guan()
		)
		guan_qia.add_child(an_niu)

# 下一关按钮点击事件
func on_xia_yi_guan() -> void:
	# 将下一关ID保存到数据管理节点
	if has_node("/root/数据管理"):
		get_node("/root/数据管理").stg = guan_qia.guan_kia_id + 1
	# 切换到关卡场景
	get_tree().change_scene_to_file("res://关卡/关卡.tscn")

# 根据关卡初始怪物数据计算获得的经验
func ji_suan_exp() -> int:
	# 获取当前关卡数据
	var guan_kia = 关卡数据.guan_kia(guan_qia.guan_kia_id)
	# 获取怪物类型列表和数量列表
	var guai_wu = guan_kia.get("guai_wu", [])
	var guai_wu_n = guan_kia.get("guai_wu_n", [])
	# 累计经验
	var exp_n = 0
	# 遍历普通怪物计算经验
	for i in range(guai_wu.size()):
		var guai_wu_ming = guai_wu[i]
		var n = guai_wu_n[i] if i < guai_wu_n.size() else 0
		var exp_1 = get_exp(guai_wu_ming)
		exp_n += exp_1 * n
	# 获取BOSS列表和数量
	var boss_list = guan_kia.get("BOSS", [])
	var boss_n = guan_kia.get("BOSS_n", [])
	# 遍历BOSS计算经验（乘以243倍）
	for i in range(boss_list.size()):
		var boss_ming = boss_list[i]
		var n = boss_n[i] if i < boss_n.size() else 0
		var exp_1 = get_exp(boss_ming) * 243
		exp_n += exp_1 * n
	return exp_n

# 获取单个怪物的经验值
func get_exp(guai_wu_ming: String) -> int:
	# 获取怪物场景路径
	var tscn_lu_jing = 关卡数据.get_tscn(guai_wu_ming)
	# 加载场景
	var tscn = load(tscn_lu_jing)
	if tscn:
		# 实例化怪物节点
		var guai_wu = tscn.instantiate()
		add_child(guai_wu)
		# 计算经验：HP * LL * FY * CT
		var exp_1 = guai_wu.HP * guai_wu.LL * guai_wu.FY * guai_wu.CT
		guai_wu.queue_free()
		return exp_1
	return 0

# 创建角色按钮
func C_role_btn() -> void:
	# 加载按钮图片资源
	png1 = load("res://全局/图片/图标.png")
	png2 = load("res://全局/图片/怪物.png")
	# 创建人物按钮
	helo_btn = TextureRect.new()
	helo_btn.texture = png1
	helo_btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	helo_btn.size = Vector2(64, 64)
	helo_btn.position = Vector2(992,624)  # 英雄按钮位置
	helo_btn.z_index = 1000  # 设置高层级确保显示在最前面
	helo_btn.gui_input.connect(_on_helo_btn_clicked)
	guan_qia.add_child(helo_btn)  # 添加到关卡节点
	# 创建怪物按钮（显示战力最高怪物信息面板）
	guai_wu_btn = TextureRect.new()
	guai_wu_btn.texture = png2
	guai_wu_btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	guai_wu_btn.size = Vector2(64, 64)
	guai_wu_btn.position = Vector2(1078,624)  # 怪物按钮位置
	guai_wu_btn.z_index = 1000
	guai_wu_btn.gui_input.connect(_on_guai_wu_btn_clicked)
	guan_qia.add_child(guai_wu_btn)

# 人物按钮点击事件处理：切换人物信息面板显示状态
func _on_helo_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if guan_qia.look_helo != null: guan_qia.look_helo.visible = !guan_qia.look_helo.visible  # 切换面板可见性
		if guan_qia.kuai_1 != null: guan_qia.kuai_1.visible = !guan_qia.kuai_1.visible  # 切换背景可见性
		if guan_qia.look_helo != null and guan_qia.look_helo.visible: guan_qia.XX.look_helo_upd()  # 打开时刷新面板内容
		get_viewport().gui_release_focus()  # 释放焦点

# 计算目标战力值
func _calculate_power(x: int, y: int) -> int:
	if x < 0 or y < 0 or y >= guan_qia.GZ_y or x >= guan_qia.GZ_x:
		return 0
	var gz = guan_qia.GZ[y][x]
	var hp = gz.get("hp", 1)
	var ll = gz.get("ll", 1)
	var fy = gz.get("fy", 1)
	var ct = gz.get("ct", 1)
	var lv = gz.get("lv", 1)
	return hp * ll * fy * ct * lv

# 怪物按钮点击事件处理：显示/隐藏当前战力最高怪物的信息面板
func _on_guai_wu_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if guan_qia.look_guai_wu != null and guan_qia.look_guai_wu.visible:  # 如果面板已打开则关闭
			guan_qia.look_guai_wu.visible = false
			if guan_qia.kuai_2 != null: guan_qia.kuai_2.visible = false
			get_viewport().gui_release_focus()
			return
		# 查找目标并显示信息面板（优先级：战力最高的存活BOSS > 战力最高的已翻开存活怪物 > 障碍 > NPC）
		var target_x = -1
		var target_y = -1
		var max_power = 0
		var _target_type = ""  # 目标类型：BOSS/怪物/障碍/NPC
		# 遍历所有BOSS，找出战力最高的存活BOSS
		for xy in guan_qia.BOSS_xy:
			var x = int(xy.x)
			var y = int(xy.y)
			if guan_qia.GZ[y][x].get("BOSS", false) and guan_qia.GZ[y][x].get("hp", 0) > 0:
				var power = _calculate_power(x, y)
				if power > max_power:
					max_power = power
					target_x = x
					target_y = y
					_target_type = "BOSS"
		# 如果没有找到存活BOSS，遍历普通怪物
		if target_x < 0:
			for xy in guan_qia.guai_wu_xy:
				var x = int(xy.x)
				var y = int(xy.y)
				if guan_qia.GZ[y][x].get("fan_kai", false) and guan_qia.GZ[y][x].get("guai_wu", false) and guan_qia.GZ[y][x].get("hp", 0) > 0:
					var power = _calculate_power(x, y)
					if power > max_power:
						max_power = power
						target_x = x
						target_y = y
						_target_type = "怪物"
		# 如果没有找到怪物，查找障碍
		if target_x < 0:
			for xy in guan_qia.zhang_ai_xy:
				var x = int(xy.x)
				var y = int(xy.y)
				if guan_qia.GZ[y][x].get("zhang_ai", false) and guan_qia.GZ[y][x].get("fan_kai", false):
					target_x = x
					target_y = y
					_target_type = "障碍"
					break
		# 如果没有找到障碍，查找NPC
		if target_x < 0:
			var npc_x = 1
			var npc_y = 1
			if npc_y < guan_qia.GZ_y and npc_x < guan_qia.GZ_x and guan_qia.GZ[npc_y][npc_x].get("NPC", false):
				target_x = npc_x
				target_y = npc_y
				_target_type = "NPC"
		# 根据找到的目标显示信息面板
		if target_x >= 0 and target_y >= 0:
			guan_qia.XX.look(false, target_x, target_y)  # 调用信息面板显示目标信息
			if guan_qia.look_guai_wu != null: guan_qia.look_guai_wu.visible = true
			if guan_qia.kuai_2 != null: guan_qia.kuai_2.visible = true
		else:
			提示弹幕.wen_ben("又出BUG了，快去通知虹！", 0)  # 没有找到任何目标时提示
		get_viewport().gui_release_focus()
