# 空间袋系统（继承通用基类）
extends "res://全局/背包.gd"
# 背包按钮（空间袋特有）
var BB_btn: TextureRect
# 背包按钮图片
var BB_png0: Texture2D
var BB_png1: Texture2D
# 操作按钮图片
var cao_zuo_png0: Texture2D
var cao_zuo_png1: Texture2D

# 初始化空间袋
func _ready() -> void:
	# 调用父类初始化
	super._ready()
	# 加载空间袋特有资源
	BB_png0 = load("res://全局/图片/空间袋0.png")
	BB_png1 = load("res://全局/图片/空间袋1.png")
	wen_ben_png = load("res://全局/图片/空间袋文本.png")
	# 加载出售按钮图片（操作按钮图片）
	cao_zuo_png0 = load("res://全局/图片/出售0.png")
	cao_zuo_png1 = load("res://全局/图片/出售1.png")
	# 创建背包按钮（空间袋特有）
	BB_btn = TextureRect.new()
	BB_btn.texture = BB_png0
	BB_btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	BB_btn.size = Vector2(64, 64)
	BB_btn.z_index = 1000
	BB_btn.mouse_entered.connect(_on_btn_mouse_entered)
	BB_btn.mouse_exited.connect(_on_btn_mouse_exited)
	BB_btn.gui_input.connect(_on_btn_clicked)
	BB_btn.visible = false
	add_child(BB_btn)
	# 创建界面背景和文字（调用父类通用方法）
	Bg(wen_ben_png)

# 按钮鼠标悬停（空间袋特有）
func _on_btn_mouse_entered() -> void:
	BB_btn.texture = BB_png1

# 按钮鼠标移出
func _on_btn_mouse_exited() -> void:
	BB_btn.texture = BB_png0

# 按钮点击
func _on_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		btn_BB()

# 打开/关闭背包
func btn_BB() -> void:
	BB_on = !BB_on
	BB_n.visible = BB_on
	if BB_on:
		BB_n_xy()
		S_upd()
		# 只有主城模式才从存档读取物品，关卡模式由外部传入临时背包
		if is_zhu:
			wu_upd()
	if not BB_on:
		GZ_ing = -1
		for ge in GZ:
			ge.texture = GZ_png1
		wu_pin_XX_0()
	get_tree().call_group("BB_3", "BB_4", BB_on)

# 刷新背包物品显示（从存档重新读取）
func wu_upd() -> void:
	# 获取存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	# 读取存档数据
	var data = json.du_qu(json.id)
	# 获取背包物品
	var wu_pin = data.get("背包", {})
	# 显示物品
	xian_shi_wu_pin(wu_pin)

# 显示背包按钮
func BB_1() -> void:
	BB_btn.visible = true
	S_lbl.visible = true
	S.visible = true
	btn_xy()

# 隐藏背包按钮
func BB_0() -> void:
	BB_btn.visible = false
	S_lbl.visible = false
	S.visible = false
	BB_n.visible = false
	BB_on = false
	wu_pin_XX_0()

# 更新背包按钮位置
func btn_xy() -> void:
	var win_y = win_size.y
	BB_btn.position = Vector2(32,win_y-96)

# 在背包中显示物品
func xian_shi_wu_pin(BB_ls: Dictionary) -> void:
	# 保存当前物品字典（用于点击时查找）
	wu_pin_ing = BB_ls
	# 先清理背包格子中之前显示的物品
	for ge in GZ:
		for child in ge.get_children():
			child.queue_free()
	# 如果没有物品则直接返回
	if BB_ls.is_empty():
		return
	# 按物品列表顺序遍历
	var index = 0
	for wu_ming in 物品信息.wu_pin:
		# 如果背包格子已满则停止显示
		if index >= GZ.size():
			break
		# 如果临时背包中有该物品则显示
		if BB_ls.has(wu_ming):
			var n = BB_ls[wu_ming]
			var ge = GZ[index]
			# 如果物品有对应图片，则显示物品图片
			if 物品信息.wu_pin_png.has(wu_ming):
				var wu_pin_tu = TextureRect.new()
				wu_pin_tu.texture = load(物品信息.wu_pin_png[wu_ming])
				wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				wu_pin_tu.size = Vector2(50, 50)
				# 计算居中偏移量
				var offset = (GZ_size - 50) / 2.0
				wu_pin_tu.position = Vector2(offset, offset)
				ge.add_child(wu_pin_tu)
			# 如果物品数量大于1，则在格子右下角显示数量标签
			if n > 1:
				# 创建数量标签
				var wu_n = Label.new()
				# 设置显示数量（转为整型避免显示小数点）
				wu_n.text = str(int(n))
				# 设置文字颜色为黑色
				wu_n.add_theme_color_override("font_color", Color.BLACK)
				# 先添加到格子，以便计算实际大小
				ge.add_child(wu_n)
				# 根据文字大小计算位置，让右下角对齐格子右下角
				var wu_n_size = wu_n.get_minimum_size()
				wu_n.position = Vector2(GZ_size-wu_n_size.x-6,GZ_size-wu_n_size.y-2)
			index += 1

# 根据格子索引获取物品名称（重写父类）
func get_wu_ming(idx: int) -> String:
	# 使用保存的物品字典，按显示顺序查找
	var index = 0
	for wu_ming in 物品信息.wu_pin:
		if wu_pin_ing.has(wu_ming):
			if index == idx:
				return wu_ming
			index += 1
	return ""

# 获取售价字段名称（空间袋使用背包售价）
func get_shou_jia_zi_duan() -> String:
	return "背包售价"
# 获取出售按钮图片
func get_cao_zuo_png0() -> Texture2D:
	return cao_zuo_png0
func get_cao_zuo_png1() -> Texture2D:
	return cao_zuo_png1
# 是否显示出售按钮（主城场景显示）
func yao_xian_shi_cao_zuo_btn() -> bool:
	return is_zhu

# 创建出售操作按钮（重写基类：一件/10%/全部）
func create_cao_zuo_buttons() -> void:
	var font_file = 提示弹幕.get_kai_ti_font()
	# 一件按钮（出售1件，amount=1）
	cao_zuo_btn1 = TextureRect.new()
	cao_zuo_btn1.texture = get_cao_zuo_png0()
	cao_zuo_btn1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cao_zuo_btn1.size = Vector2(64, 64)
	cao_zuo_btn1.position = Vector2(96, 192)
	cao_zuo_btn1.mouse_entered.connect(func(): if cao_zuo_btn1 != null: cao_zuo_btn1.texture = get_cao_zuo_png1())
	cao_zuo_btn1.mouse_exited.connect(func(): if cao_zuo_btn1 != null: cao_zuo_btn1.texture = get_cao_zuo_png0())
	cao_zuo_btn1.gui_input.connect(func(event): cao_zuo_3(event, 1))
	wu_pin_kuai.add_child(cao_zuo_btn1)
	# 一件文本
	cao_zuo_text10 = Label.new()
	cao_zuo_text10.text = "一件"
	cao_zuo_text10.add_theme_color_override("font_color", Color.BLACK)
	cao_zuo_text10.add_theme_font_size_override("font_size", 24)
	if font_file != null:
		cao_zuo_text10.add_theme_font_override("font", font_file)
	cao_zuo_text10.position = Vector2(160, 212)
	wu_pin_kuai.add_child(cao_zuo_text10)
	# 10%按钮（出售当前数量10%向上取整，amount=0）
	cao_zuo_btn10 = TextureRect.new()
	cao_zuo_btn10.texture = get_cao_zuo_png0()
	cao_zuo_btn10.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cao_zuo_btn10.size = Vector2(64, 64)
	cao_zuo_btn10.position = Vector2(96, 288)
	cao_zuo_btn10.mouse_entered.connect(func(): if cao_zuo_btn10 != null: cao_zuo_btn10.texture = get_cao_zuo_png1())
	cao_zuo_btn10.mouse_exited.connect(func(): if cao_zuo_btn10 != null: cao_zuo_btn10.texture = get_cao_zuo_png0())
	cao_zuo_btn10.gui_input.connect(func(event): cao_zuo_3(event, 0))
	wu_pin_kuai.add_child(cao_zuo_btn10)
	# 10%文本
	cao_zuo_text100 = Label.new()
	cao_zuo_text100.text = "10%"
	cao_zuo_text100.add_theme_color_override("font_color", Color.BLACK)
	cao_zuo_text100.add_theme_font_size_override("font_size", 24)
	if font_file != null:
		cao_zuo_text100.add_theme_font_override("font", font_file)
	cao_zuo_text100.position = Vector2(160, 308)
	wu_pin_kuai.add_child(cao_zuo_text100)
	# 全部按钮（出售全部，amount=-1）
	cao_zuo_btn100 = TextureRect.new()
	cao_zuo_btn100.texture = get_cao_zuo_png0()
	cao_zuo_btn100.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cao_zuo_btn100.size = Vector2(64, 64)
	cao_zuo_btn100.position = Vector2(96, 384)
	cao_zuo_btn100.mouse_entered.connect(func(): if cao_zuo_btn100 != null: cao_zuo_btn100.texture = get_cao_zuo_png1())
	cao_zuo_btn100.mouse_exited.connect(func(): if cao_zuo_btn100 != null: cao_zuo_btn100.texture = get_cao_zuo_png0())
	cao_zuo_btn100.gui_input.connect(func(event): cao_zuo_3(event, -1))
	wu_pin_kuai.add_child(cao_zuo_btn100)
	# 全部文本
	var text_all = Label.new()
	text_all.text = "全部"
	text_all.add_theme_color_override("font_color", Color.BLACK)
	text_all.add_theme_font_size_override("font_size", 24)
	if font_file != null:
		text_all.add_theme_font_override("font", font_file)
	text_all.position = Vector2(160, 404)
	wu_pin_kuai.add_child(text_all)

# 出售按钮点击处理
# amount 为出售模式：1=一件，0=当前数量10%向上取整，-1=全部
func cao_zuo_3(event: InputEvent, amount: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 获取当前选中物品名称
		var wu_ming = get_wu_ming(GZ_ing)
		if wu_ming == "":
			return
		# 获取物品数量
		var shu_liang = wu_pin_ing.get(wu_ming, 0)
		if shu_liang <= 0:
			提示弹幕.wen_ben("出BUG了，快去找虹！", 0)
			return
		# 根据出售模式计算实际出售数量
		var actual: int
		match amount:
			1:
				actual = 1
			0:  # 10%向上取整
				actual = int(ceil(shu_liang * 0.1))
			-1:  # 全部
				actual = shu_liang
			_:
				actual = amount
		actual = min(actual, shu_liang)
		if actual <= 0:
			提示弹幕.wen_ben("出BUG了，快去找虹！", 0)
			return
		# 获取物品售价
		var XX = 物品信息.get_XX(wu_ming)
		var shou_jia = XX.get("背包售价", 0)
		# 获取存档节点
		var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
		if json == null:
			return
		# 读取当前存档数据
		var data = json.du_qu(json.id)
		var BB = data.get("背包", {})
		var S_1 = int(data.get("银币", 0))
		# 执行批量出售
		chu_shou_batch(wu_ming, shu_liang, shou_jia, BB, S_1, json, actual)

# 批量出售物品
func chu_shou_batch(wu_ming: String, shu_liang: int, shou_jia: int, BB: Dictionary, S_1: int, json, amount: int) -> void:
	# 计算实际出售数量
	var actual_amount = min(amount, shu_liang)
	if actual_amount <= 0:
		提示弹幕.wen_ben("出BUG了，快去找虹！", 0)
		return
	# 减少物品数量
	BB[wu_ming] = shu_liang - actual_amount
	# 如果数量为0或负数，从背包中删除该物品
	if BB[wu_ming] <= 0:
		BB.erase(wu_ming)
	# 增加银币
	var total_earn = shou_jia * actual_amount
	S_1 += total_earn
	# 更新存档数据
	var data = json.du_qu(json.id)
	data["背包"] = BB
	data["银币"] = S_1
	json.bao_cun(json.id, data)
	# 更新显示
	wu_pin_ing = BB
	xian_shi_wu_pin(BB)
	S_upd()
	# 显示弹幕提示
	提示弹幕.wen_ben("出售%sx%d，获得%d银币！" % [wu_ming, actual_amount, total_earn], 0)
	# 如果物品已售完，关闭信息面板
	if not BB.has(wu_ming):
		GZ_ing = -1
		for ge in GZ:
			ge.texture = GZ_png1
		wu_pin_XX_0()
