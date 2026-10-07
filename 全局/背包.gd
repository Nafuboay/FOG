# 物品容器基类（通用）
extends Control
# 界面容器
var BB_n: Control
# 格子数组
var GZ: Array[TextureRect] = []
# 是否打开
var BB_on: bool = false
# 格子行数
var y: int = 7
# 格子列数
var x: int = 7
# 格子大小
var GZ_size: int = 64
# 格子图片
var GZ_png1: Texture2D
var GZ_png2: Texture2D
# 背景图片
var bg_png: Texture2D
# 当前选中的格子索引（-1表示未选中）
var GZ_ing: int = -1
# 物品信息面板容器
var wu_pin_kuai: Control = null
var kuai_9: NinePatchRect = null
# 物品信息面板背景
var kuai: Texture2D
# 当前显示的物品字典
var wu_pin_ing: Dictionary = {}
# 窗口尺寸
var win_size: Vector2
# 银币显示标签
var S_lbl: Label = null
# 银币图标
var S: TextureRect = null
# 是否在主城场景
var is_zhu: bool = false
# 是否为商店模式
var is_shop: bool = false
# 文本图片（由子类设置）
var wen_ben_png: Texture2D = null
# 文本显示控件
var wen_ben: TextureRect = null
# 操作按钮数组（空间袋：出售按钮，商店：购买按钮）
var cao_zuo_btn1: TextureRect = null  # 第一个按钮
var cao_zuo_btn10: TextureRect = null  # 第二个按钮
var cao_zuo_btn100: TextureRect = null  # 第三个按钮

# 初始化
func _ready() -> void:
	win_size = get_viewport_rect().size
	# 加载通用图片资源
	GZ_png1 = load("res://全局/图片/空间格子.png")
	GZ_png2 = load("res://全局/图片/闪光格子.png")
	bg_png = load("res://全局/图片/背包背景.png")
	kuai = load("res://关卡/信息/模块背景.png")
	var S_png = load("res://全局/图片/银币.png")
	# 创建界面容器
	BB_n = Control.new()
	BB_n.name = "界面容器"
	BB_n.visible = false
	BB_n.z_index = 1000
	add_child(BB_n)
	# 创建银币显示标签
	S_lbl = Label.new()
	S_lbl.text = "0"
	S_lbl.add_theme_font_size_override("font_size", 32)
	S_lbl.add_theme_color_override("font_color", Color("eeeeee"))
	# 设置楷体字体
	var font_file = 提示弹幕.get_kai_ti_font()
	if font_file != null:
		S_lbl.add_theme_font_override("font", font_file)
	S_lbl.z_index = 1000
	S_lbl.visible = false
	BB_n.add_child(S_lbl)
	# 创建银币图标
	S = TextureRect.new()
	S.texture = S_png
	S.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	S.size = Vector2(50, 50)
	S.z_index = 1000
	S.visible = false
	BB_n.add_child(S)

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

# 居中界面
func BB_n_xy() -> void:
	var GZ_49 = BB_n.get_node("背包格子")
	if GZ_49 == null:
		return
	var GZ_49_size = Vector2(x * GZ_size, y * GZ_size)
	GZ_49.position = win_size / 2.0 - GZ_49_size / 2.0
	if S_lbl != null and S != null:
		S_lbl.position = Vector2(770,93)
		S.position = Vector2(715,85)

# 创建背景
func Bg(text_png: Texture2D = null) -> void:
	# 保存文本图片引用
	wen_ben_png = text_png
	# 创建背景图片
	var bg = TextureRect.new()
	bg.texture = bg_png
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.size = Vector2(500, 526)
	bg.position = win_size / 2.0 - bg.size / 2.0 - Vector2(0, 13)
	BB_n.add_child(bg)
	# 创建文本图片
	if wen_ben_png != null:
		wen_ben = TextureRect.new()
		wen_ben.texture = wen_ben_png
		wen_ben.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wen_ben.size = wen_ben_png.get_size()
		wen_ben.position = Vector2(595, 90)
		wen_ben.z_index = 1001
		BB_n.add_child(wen_ben)
	# 创建格子容器
	C_GZ_1()

# 创建格子容器
func C_GZ_1() -> void:
	var GZ_49 = Control.new()
	GZ_49.name = "背包格子"
	BB_n.add_child(GZ_49)
	for i in range(y * x):
		var h = int(i / float(x))
		var l = i % x
		var ge = TextureRect.new()
		ge.texture = GZ_png1
		ge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ge.size = Vector2(GZ_size, GZ_size)
		ge.position = Vector2(l * GZ_size, h * GZ_size)
		ge.gui_input.connect(func(event): GZ_LMB(event, i))
		GZ_49.add_child(ge)
		GZ.append(ge)
	GZ_49.position = win_size / 2.0 - Vector2(x * GZ_size, y * GZ_size) / 2.0

# 打开/关闭
func btn_BB() -> void:
	BB_on = !BB_on
	BB_n.visible = BB_on
	if BB_on:
		BB_n_xy()
		S_upd()
	if not BB_on:
		GZ_ing = -1
		for ge in GZ:
			ge.texture = GZ_png1
		wu_pin_XX_0()
	get_tree().call_group("BB_3", "BB_4", BB_on)

# 显示物品
func xian_shi_wu_pin(wu_pin_ls: Dictionary) -> void:
	wu_pin_ing = wu_pin_ls
	for ge in GZ:
		for child in ge.get_children():
			child.queue_free()

# 格子点击事件处理
func GZ_LMB(event: InputEvent, idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var wu_ming = get_wu_ming(idx)
		if wu_ming == "":
			GZ_ing = -1
			for ge in GZ:
				ge.texture = GZ_png1
			wu_pin_XX_0()
			return
		if GZ_ing == idx:
			GZ_ing = -1
			for ge in GZ:
				ge.texture = GZ_png1
			wu_pin_XX_0()
		else:
			GZ_ing = idx
			for i in range(GZ.size()):
				GZ[i].texture = GZ_png1
			GZ[idx].texture = GZ_png2
			wu_pin_XX(wu_ming)

# 根据格子索引获取物品名称
func get_wu_ming(_idx: int) -> String:
	return ""

# 获取售价字段名称
func get_shou_jia_zi_duan() -> String:
	return "背包售价"
# 获取操作按钮图片
func get_cao_zuo_png0() -> Texture2D:
	return null
func get_cao_zuo_png1() -> Texture2D:
	return null
# 是否显示操作按钮
func yao_xian_shi_cao_zuo_btn() -> bool:
	return false
# 显示物品信息面板
func wu_pin_XX(wu_ming: String) -> void:
	# 先关闭已有面板
	wu_pin_XX_0()
	# 获取物品详细信息
	var XX = 物品信息.get_XX(wu_ming)
	if XX.is_empty():
		return
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
	kuai_9.z_index = 1000
	add_child(kuai_9)
	# 创建文字容器
	wu_pin_kuai = Control.new()
	wu_pin_kuai.position = Vector2(win_x - 256 - 32, int((win_y - 512) / 2.0))
	wu_pin_kuai.size = Vector2(256, 512)
	wu_pin_kuai.z_index = 1000
	add_child(wu_pin_kuai)
	# 获取售价（调用虚方法）
	var shou_jia_zi_duan = get_shou_jia_zi_duan()
	var shou_jia = XX.get(shou_jia_zi_duan, 0)
	var text = "\n  【物品】%s\n  【获取】%s\n  【用途】%s\n  【售价】%d银币" % [
		wu_ming, XX.get("获取", ""), XX.get("用途", ""), shou_jia
	]
	# 创建文本标签
	var label = Label.new()
	label.text = text
	label.position = Vector2(0,0)
	label.add_theme_color_override("font_color", Color.BLACK)
	# 设置楷体字体
	var font_file = 提示弹幕.get_kai_ti_font()
	if font_file != null:
		label.add_theme_font_override("font", font_file)
	wu_pin_kuai.add_child(label)
	# 判断是否显示操作按钮（调用虚方法）
	if yao_xian_shi_cao_zuo_btn():
		# 创建操作按钮容器（水平排列3个按钮）
		create_cao_zuo_buttons()

# 获取操作按钮文本（子类重写以自定义）
func get_cao_zuo_texts() -> Array:
	return ["", "×10", "×100"]

# 获取操作按钮amount参数（子类重写以自定义）
func get_cao_zuo_amounts() -> Array:
	return [1, 10, 100]

# 创建操作按钮（3个，竖向排列）
func create_cao_zuo_buttons() -> void:
	var font_file = 提示弹幕.get_kai_ti_font()
	var texts = get_cao_zuo_texts()
	var amounts = get_cao_zuo_amounts()
	var y_positions = [192, 288, 384]
	var text_y_offsets = [212, 308, 404]
	var btn_vars = ["cao_zuo_btn1", "cao_zuo_btn10", "cao_zuo_btn100"]

	for i in range(3):
		var btn = TextureRect.new()
		btn.texture = get_cao_zuo_png0()
		btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		btn.size = Vector2(64, 64)
		btn.position = Vector2(96, y_positions[i])
		var amt = amounts[i]
		btn.mouse_entered.connect(func(): if btn != null: btn.texture = get_cao_zuo_png1())
		btn.mouse_exited.connect(func(): if btn != null: btn.texture = get_cao_zuo_png0())
		btn.gui_input.connect(func(event): cao_zuo_3(event, amt))
		wu_pin_kuai.add_child(btn)
		set(btn_vars[i], btn)

		var text = texts[i]
		if text != "":
			var lbl = Label.new()
			lbl.text = text
			lbl.add_theme_color_override("font_color", Color.BLACK)
			lbl.add_theme_font_size_override("font_size", 24)
			if font_file != null:
				lbl.add_theme_font_override("font", font_file)
			lbl.position = Vector2(160, text_y_offsets[i])
			wu_pin_kuai.add_child(lbl)

# 操作按钮点击处理
func cao_zuo_3(_event: InputEvent, _amount: int) -> void:
	pass

# 关闭物品信息面板
func wu_pin_XX_0() -> void:
	if kuai_9 != null:
		kuai_9.queue_free()
		kuai_9 = null
	if wu_pin_kuai != null:
		wu_pin_kuai.queue_free()
		wu_pin_kuai = null
	cao_zuo_btn1 = null
	cao_zuo_btn10 = null
	cao_zuo_btn100 = null

# 设置是否在主城场景
func is_zhu_cheng(zai: bool) -> void:
	is_zhu = zai
