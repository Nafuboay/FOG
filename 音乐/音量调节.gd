# 音量调节系统
extends Control
# 按钮是否显示
var btn_visible: bool = true
# 音量面板是否打开
var is_VOL: bool = false
# 当前音量dB值
var dB_ing: int = 0
# 是否处于静音状态
var is_mut: bool = false
# 主音频总线索引
var zhu_bus: int = 0
# 窗口尺寸
var win_size: Vector2
# 音量按钮节点
var sw_btn: TextureRect = null
# 音量面板容器
var P: Control = null
# dB值显示标签
var dB_lbl: Label = null
# 音量百分比显示标签
var pct_lbl: Label = null
# 静音按钮节点
var mut_btn: TextureRect = null
# 音量调节滑块
var dB_S: HSlider = null

# 节点初始化完成时调用
func _ready() -> void:
	# 获取窗口尺寸
	win_size = get_viewport_rect().size
	# 获取主音频总线索引
	zhu_bus = AudioServer.get_bus_index("Master")
	# 创建音量按钮
	C_btn()
	# 创建音量调节面板
	C_P()
	# 从存档加载音量设置
	load_dB()

# 创建音量按钮
func C_btn() -> void:
	# 创建按钮节点
	sw_btn = TextureRect.new()
	# 设置常态图标
	sw_btn.texture = load("res://音乐/音量0.png")
	# 设置按钮位置
	sw_btn.position = Vector2(1184, 624)
	# 设置渲染层级（确保在最上层）
	sw_btn.z_index = 1000
	sw_btn.visible = btn_visible
	# 连接鼠标事件
	sw_btn.mouse_entered.connect(btn_hover)    # 鼠标进入
	sw_btn.mouse_exited.connect(btn_normal)    # 鼠标离开
	sw_btn.gui_input.connect(btn_click)        # 鼠标点击
	# 添加到节点树
	add_child(sw_btn)

# 创建音量调节面板
func C_P() -> void:
	# 创建面板容器
	P = Control.new()
	P.name = "音量面板"
	P.visible = false
	P.z_index = 1000
	add_child(P)
	var bg = TextureRect.new()
	bg.texture = load("res://全局/图片/背包背景.png")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# 背景大小
	bg.size = Vector2(320,180)
	# 背景位置
	bg.position = Vector2(win_size.x / 2.0 - bg.size.x / 2.0, win_size.y / 2.0 - bg.size.y / 2.0)
	P.add_child(bg)
	var tit = Label.new()
	tit.text = "音量调节"
	tit.position = Vector2(576,286) # 标题位置
	tit.add_theme_font_size_override("font_size",32) # 字体大小
	tit.add_theme_color_override("font_color", Color("000000")) # 字体黑色
	kai_ti(tit) # 字体楷体
	P.add_child(tit)
	dB_lbl = Label.new()
	dB_lbl.text = "分贝：标准"
	dB_lbl.position = Vector2(580,334) # 分贝文本位置
	dB_lbl.add_theme_font_size_override("font_size",24) # 字体大小
	dB_lbl.add_theme_color_override("font_color", Color("000000"))
	kai_ti(dB_lbl)
	P.add_child(dB_lbl)
	pct_lbl = Label.new()
	pct_lbl.text = "音量：100%"
	pct_lbl.position = Vector2(580,374) # 音量文本位置
	pct_lbl.add_theme_font_size_override("font_size",24) # 字体大小
	pct_lbl.add_theme_color_override("font_color", Color("000000"))
	kai_ti(pct_lbl)
	P.add_child(pct_lbl)
	dB_S = HSlider.new()
	dB_S.position = Vector2(484,412) # 滑块位置
	dB_S.size = Vector2(312,20) # 滑块大小
	# 音量范围
	dB_S.min_value = -40
	dB_S.max_value = 12
	# 调节步长
	dB_S.step = 1
	dB_S.value = dB_ing
	# 刻度数量
	dB_S.tick_count = 53
	# 连接值变化信号
	dB_S.connect("value_changed", func(value):
		dB_ing = int(value)
		upd()
	)
	P.add_child(dB_S)
	mut_btn = TextureRect.new()
	# 设置非静音状态图标
	mut_btn.texture = load("res://音乐/非静音.png")
	# 位置：距离顶部200像素，水平居中
	mut_btn.position = Vector2(718,320)
	# 连接点击事件
	mut_btn.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mut_sw()
	)
	P.add_child(mut_btn)

# 鼠标悬停在按钮上
func btn_hover() -> void:
	if sw_btn != null and not is_VOL:
		sw_btn.texture = load("res://音乐/音量1.png")
# 鼠标离开按钮
func btn_normal() -> void:
	if sw_btn != null:
		sw_btn.texture = load("res://音乐/音量0.png")
# 按钮点击处理
func btn_click(event: InputEvent) -> void:
	# 判断是否为鼠标左键点击
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 切换面板状态
		is_VOL = !is_VOL
		P.visible = is_VOL

# 更新音量显示和实际音量
func upd() -> void:
	# 计算音量百分比
	var pct = get_pct(dB_ing)
	# 更新分贝值显示
	if dB_ing == 0:
		dB_lbl.text = "分贝：标准"
	elif dB_ing > 0:
		dB_lbl.text = "分贝：+%d" % dB_ing
	else:
		dB_lbl.text = "分贝：%d" % dB_ing
	# 根据dB值决定显示格式：
	if dB_ing <= -21:
		pct_lbl.text = "音量: %.1f%%" % pct
	else:
		pct_lbl.text = "音量: %d%%" % int(pct)
	# 同步滑块位置
	if dB_S != null and int(dB_S.value) != dB_ing:
		dB_S.value = dB_ing
	# 如果不是静音状态，应用音量到音频总线
	if not is_mut:
		AudioServer.set_bus_volume_db(zhu_bus, dB_ing)
	# 保存设置到存档
	S_json()

# dB值转音量百分比
func get_pct(db: int) -> float:
	return pow(10, db / 20.0) * 100

# 静音切换
func mut_sw() -> void:
	# 切换静音状态
	is_mut = !is_mut
	if is_mut:
		# 静音
		AudioServer.set_bus_volume_db(zhu_bus, -80)
		# 切换到静音图标
		mut_btn.texture = load("res://音乐/静音.png")
		# 禁用滑块（静音时禁止调整）
		dB_S.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dB_S.modulate = Color(0.5, 0.5, 0.5)
	else:
		# 取消静音：恢复之前的分贝值
		AudioServer.set_bus_volume_db(zhu_bus, dB_ing)
		upd()
		# 切换回非静音图标
		mut_btn.texture = load("res://音乐/非静音.png")
		# 启用滑块
		dB_S.mouse_filter = Control.MOUSE_FILTER_STOP
		dB_S.modulate = Color.WHITE
	# 保存静音状态到存档
	S_json()

# 保存音量设置到存档
func S_json() -> void:
	# 获取游戏存档节点
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json != null:
		# 读取当前存档数据
		var data = json.du_qu(json.id)
		# 保存分贝值
		data["分贝"] = dB_ing
		# 保存静音状态（1表示静音，0表示非静音）
		data["静音"] = 1 if is_mut else 0
		# 保存到存档
		json.bao_cun(json.id, data)

# 从存档加载音量设置
func load_dB() -> void:
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json != null:
		var data = json.du_qu(json.id)
		# 检查并补充缺失的字段
		if not data.has("分贝"):
			data["分贝"] = 0
		if not data.has("静音"):
			data["静音"] = 0
		# 读取保存的分贝值，默认为0
		dB_ing = int(data.get("分贝", 0))
		# 读取静音状态（1表示静音，0表示非静音）
		is_mut = data.get("静音", 0) == 1
		# 如果是静音状态，设置静音图标
		if is_mut:
			mut_btn.texture = load("res://音乐/静音.png")
		# 更新显示和实际音量
		upd()

# 关闭面板
func off_P() -> void:
	if is_VOL:
		btn_click(InputEventMouseButton.new())

# 设置控件使用楷体字体
func kai_ti(control: Control) -> void:
	# 使用全局缓存的楷体字体
	var font_file = 提示弹幕.get_kai_ti_font()
	if font_file:
		control.add_theme_font_override("font", font_file)

# 全局输入事件处理（点击面板外区域关闭面板）
func _input(event: InputEvent) -> void:
	# 如果面板已打开
	if is_VOL:
		# 判断是否为鼠标左键点击
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 获取面板和按钮的全局矩形区域
			var P_rect = P.get_global_rect()
			var mouse_pos = get_global_mouse_position()
			# 如果点击在面板外且不在按钮上，关闭面板
			if not P_rect.has_point(mouse_pos) and not sw_btn.get_global_rect().has_point(mouse_pos):
				off_P()
