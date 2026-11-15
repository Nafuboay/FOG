extends Node2D

# 按钮节点引用
@onready var an_niu = $按钮
@onready var bg = $游戏开始0
# 按钮普通状态图片
var an_niu_normal: Texture2D
# 按钮悬停状态图片
var an_niu_hover: Texture2D

# 人物选择面板
@onready var helo_xuan_ze = $人物选择面板
@onready var Alice = $人物选择面板/爱丽丝按钮
@onready var xuan_ge = $人物选择面板/玄戈按钮
@onready var cheng_gan_qi = $人物选择面板/秤干戚按钮
@onready var Alice_idle = $人物选择面板/爱丽丝待机
@onready var xuan_ge_idle = $人物选择面板/玄戈待机
@onready var cheng_gan_qi_idle = $人物选择面板/秤干戚待机
@onready var fan_hui = $人物选择面板/返回按钮
# 返回按钮图片
var fan_hui_normal: Texture2D
var fan_hui_hover: Texture2D
# 删除按钮图片
var shan_chu_normal: Texture2D
var shan_chu_hover: Texture2D
# 二次确定面板
@onready var er_ci = $二次确定
@onready var que_ding = $二次确定/确定按钮
@onready var qu_xiao = $二次确定/取消按钮
# 存档返回按钮
var json_fan_hui: Button
# 存档管理脚本引用
var json: Node
# 当前选中的存档槽位
var json_id: int = 0
# 设置按钮（右上角齿轮图标）
var she_zhi_btn: TextureRect = null
# 设置面板总容器（含全屏遮罩与320×540背景）
var she_zhi_panel: Control = null
# 设置三项目录层（语言/音量/基础帧率）
var she_zhi_mu_lu: Control = null
# 语言选择子界面
var she_zhi_yu_yan: Control = null
# 设置内嵌的音量调节模块实例（其P面板即音量子界面，保持原320×180居中布局不改；不做静态类型声明以便访问脚本成员P）
var VOL_sz = null
# 设置当前所在层级：0=三项目录 1=语言 2=音量 3=基础帧率 4=镜头跟随速度（用于齿轮按钮逐级返回）
var she_zhi_ceng: int = 0
# 基础帧率子界面
var she_zhi_zhen_lv: Control = null
# 基础帧率子界面控件
var she_zhi_zl_lbl: Label = null
var she_zhi_zl_slider: HSlider = null
# 镜头跟随速度子界面
var she_zhi_jing_tou: Control = null
# 镜头跟随速度子界面控件
var she_zhi_jt_lbl: Label = null
var she_zhi_jt_slider: HSlider = null
# 余烬滤镜强度子界面与控件
var she_zhi_yu_jin: Control = null
var she_zhi_yj_lbl: Label = null
var she_zhi_yj_slider: HSlider = null
# 支持的语言列表 {code: 语言代码, ming: 显示名称}
const YU_YAN_LIE_BIAO: Array = [
	{"code": "zh_CN", "ming": "简体中文"},
	{"code": "en", "ming": "英语"},
	{"code": "zh_TW", "ming": "繁体中文"},
	{"code": "ja", "ming": "日语"},
]
# 玄戈是否处于锁定状态（历史成就【救世主Ⅰ】0001 不存在时为true）
var xuan_ge_suo: bool = false
# 秤干戚是否处于锁定状态（历史成就【救世主Ⅱ】0002 不存在时为true）
var cheng_gan_qi_suo: bool = false
# 存档模式选择面板（创建空槽存档前弹出）
var mo_shi_panel: Control = null
# 当前选中的模式（默认标准）
var mo_shi_xuan: int = 游戏存档.MO_SHI_BIAO_ZHUN
# 建造档中标志：防止连点重复创建存档（模式面板点击条目即生效）
var zheng_jian_zhong: bool = false
# 存档数量
const cao_wei: int = 15

# 存档槽位按钮数组（在_ready中按节点名动态获取）
var an_nius: Array = []
# 存档槽位删除按钮数组
var shan_chus: Array = []
# 存档槽位待机动画数组
var json_idles: Array = []
# 每个存档槽位的颜色码（三位数字，每位0/1/2对应RGB的0/128/255）
const yan_se_mas: Array = ["200", "210", "220", "120", "020", "021", "022", "012", "002", "102", "202", "201", "222", "111", "000"]
# 颜色码单值到modulate通道值的映射
# modulate是乘法混合：值<1压暗、=1原色、>1提亮
# 0→0.25（深灰，避免全黑遮挡背景），1→0.6（中间调），2→1.2（提亮，使白色可见）
const yan_se_zhi: Array = [0.2, 0.6, 1.2]

# 将三位颜色码转为Color对象
func yan_se_ma_to_color(ma: String) -> Color:
	return Color(yan_se_zhi[int(ma[0])], yan_se_zhi[int(ma[1])], yan_se_zhi[int(ma[2])], 1.0)

# 初始化按钮图片
func _ready() -> void:
	# 加载按钮普通状态图片
	an_niu_normal = load("res://主界面/图片/游戏开始1.png")
	# 加载按钮悬停状态图片
	an_niu_hover = load("res://主界面/图片/游戏开始2.png")
	# 加载返回按钮图片
	fan_hui_normal = load("res://主界面/图片/返回0.png")
	fan_hui_hover = load("res://主界面/图片/返回1.png")
	# 加载删除按钮图片
	shan_chu_normal = load("res://主界面/图片/×号0.png")
	shan_chu_hover = load("res://主界面/图片/×号1.png")
	# 加载确定按钮图片
	var que_ding_normal = StyleBoxTexture.new()
	que_ding_normal.texture = load("res://主界面/图片/确定0.png")
	var que_ding_hover = StyleBoxTexture.new()
	que_ding_hover.texture = load("res://主界面/图片/确定1.png")
	que_ding.add_theme_stylebox_override("normal", que_ding_normal)
	que_ding.add_theme_stylebox_override("hover", que_ding_hover)
	que_ding.add_theme_stylebox_override("pressed", que_ding_hover)
	# 加载取消按钮图片
	var qu_xiao_normal = StyleBoxTexture.new()
	qu_xiao_normal.texture = load("res://主界面/图片/取消0.png")
	var qu_xiao_hover = StyleBoxTexture.new()
	qu_xiao_hover.texture = load("res://主界面/图片/取消1.png")
	qu_xiao.add_theme_stylebox_override("normal", qu_xiao_normal)
	qu_xiao.add_theme_stylebox_override("hover", qu_xiao_hover)
	qu_xiao.add_theme_stylebox_override("pressed", qu_xiao_hover)
	# 按节点名收集存档按钮、删除按钮、待机动画
	for i in range(cao_wei):
		an_nius.append(get_node("存档按钮" + str(i)))
		shan_chus.append(get_node("删除按钮" + str(i)))
		json_idles.append(get_node("存档待机" + str(i)))
	# 默认隐藏存档按钮
	for btn in an_nius:
		btn.visible = false
	for s in json_idles:
		s.visible = false
	# 获取窗口大小（提前定义以便在后续代码中使用）
	var size = get_viewport_rect().size
	var win_x = size.x
	var win_y = size.y
	# 计算按钮位置（3行5列布局）
	var hang_shu_1 = 3  # 行数
	var lie_shu_1 = 5   # 列数
	for i in range(cao_wei):
		var m = i % lie_shu_1
		var n = int(i / float(lie_shu_1))
		var x = (2.0 * m + 3.0) / (lie_shu_1 * 2.0 + 4.0) * win_x - 64
		var y = (2.0 * n + 3.0) / (hang_shu_1 * 2.0 + 4.0) * win_y - 64
		an_nius[i].position = Vector2(x, y)
		# 设置存档待机动画位置
		json_idles[i].position = Vector2(x + 47, y + 47)
		var cao_yuan_0 = StyleBoxTexture.new()
		cao_yuan_0.texture = load("res://主界面/图片/模块0.png")
		an_nius[i].add_theme_stylebox_override("normal", cao_yuan_0)
		an_nius[i].add_theme_stylebox_override("hover", cao_yuan_0)
		an_nius[i].add_theme_stylebox_override("pressed", cao_yuan_0)
		an_nius[i].add_theme_color_override("font_hover_color", Color.BLACK)
		# 程序化连接存档按钮的悬停/离开/点击信号
		an_nius[i].mouse_entered.connect(_on_cao_wei_hover.bind(i))
		an_nius[i].mouse_exited.connect(_on_cao_wei_exit.bind(i))
		an_nius[i].pressed.connect(dian_ji.bind(i))
	# 创建存档返回按钮
	json_fan_hui = Button.new()
	json_fan_hui.set_script(load("res://主界面/返回按钮.gd"))
	json_fan_hui.visible = false
	json_fan_hui.fan_hui.connect(on_json_fan_hui)
	add_child(json_fan_hui)
	# 检查是否已有存档节点，没有则创建
	if not has_node("/root/游戏存档"):
		# 加载存档管理脚本并创建新节点
		json = load("res://主界面/游戏存档.gd").new()
		# 必须命名为"游戏存档"：全局统一通过/root/游戏存档路径访问，缺名会导致按路径查找永远失败
		json.name = "游戏存档"
		# 将节点添加到根节点下（全局单例）
		get_tree().root.call_deferred("add_child", json)
	else:
		# 已有存档节点，直接获取
		json = get_node("/root/游戏存档")
	# 设置人物选择按钮位置（1行3列布局）
	var an_nius_2 = [Alice, xuan_ge, cheng_gan_qi]
	var hang_shu_2 = 1  # 行数
	var lie_shu_2 = 3    # 列数
	var idle = [Alice_idle, xuan_ge_idle, cheng_gan_qi_idle]
	var helo_ming = ["爱丽丝", "玄戈", "秤干戚"]
	for i in range(an_nius_2.size()):
		var m = i % lie_shu_2
		var n = int(i / float(lie_shu_2))
		var x = (2.0 * m + 3.0) / (lie_shu_2 * 2.0 + 4.0) * win_x - 64
		var y = (2.0 * n + 3.0) / (hang_shu_2 * 2.0 + 4.0) * win_y - 64
		an_nius_2[i].position = Vector2(x, y)
		# 设置待机动画位置与按钮相同
		idle[i].position = Vector2(x + 47, y + 47)
		# 加载预定义的待机动画
		idle[i].sprite_frames = load("res://角色/人物/" + helo_ming[i] + "/" + helo_ming[i] + "动画.tres")
		idle[i].play("idle")
		idle[i].speed_scale = json.get_dong_hua_su_du()
		# 设置按钮背景
		var cao_yuan_0 = StyleBoxTexture.new()
		cao_yuan_0.texture = load("res://主界面/图片/模块0.png")
		an_nius_2[i].add_theme_stylebox_override("normal", cao_yuan_0)
		an_nius_2[i].add_theme_stylebox_override("hover", cao_yuan_0)
		an_nius_2[i].add_theme_stylebox_override("pressed", cao_yuan_0)
		an_nius_2[i].add_theme_color_override("font_hover_color", Color.BLACK)
	# 设置返回按钮图片
	var fan_hui_0 = StyleBoxTexture.new()
	fan_hui_0.texture = fan_hui_normal
	var fan_hui_1 = StyleBoxTexture.new()
	fan_hui_1.texture = fan_hui_hover
	fan_hui.add_theme_stylebox_override("normal", fan_hui_0)
	fan_hui.add_theme_stylebox_override("hover", fan_hui_1)
	fan_hui.add_theme_stylebox_override("pressed", fan_hui_1)
	# 设置删除按钮图片和位置
	var hang_shu_3 = 3  # 行数
	var lie_shu_3 = 5    # 列数
	for i in range(shan_chus.size()):
		shan_chus[i].custom_minimum_size = Vector2(32, 32)
		var m = i % lie_shu_3
		var n = int(i / float(lie_shu_3))
		var x = (2.0 * m + 3.0) / (lie_shu_3 * 2.0 + 4.0) * win_x + 40
		var y = (2.0 * n + 3.0) / (hang_shu_3 * 2.0 + 4.0) * win_y - 72
		shan_chus[i].position = Vector2(x, y)
		var shan_chu_00 = StyleBoxTexture.new()
		shan_chu_00.texture = shan_chu_normal
		var shan_chu_11 = StyleBoxTexture.new()
		shan_chu_11.texture = shan_chu_hover
		shan_chus[i].add_theme_stylebox_override("normal", shan_chu_00)
		shan_chus[i].add_theme_stylebox_override("hover", shan_chu_11)
		shan_chus[i].add_theme_stylebox_override("pressed", shan_chu_11)
		# 程序化连接删除按钮的点击信号
		shan_chus[i].pressed.connect(shan_chu_an_niu.bind(i))
	# 创建设置按钮与设置面板
	chuang_jian_she_zhi()
	# 创建存档模式选择面板（初始隐藏）
	chuang_jian_mo_shi_pan()

# 创建设置齿轮按钮与设置面板（替代原来的语言按钮）
func chuang_jian_she_zhi() -> void:
	# 获取窗口大小，用于设置面板居中
	var size = get_viewport_rect().size
	var win_x = size.x
	var win_y = size.y
	# 齿轮按钮使用图片原始尺寸64×64，贴右上角
	she_zhi_btn = TextureRect.new()
	she_zhi_btn.texture = load("res://主界面/图片/齿轮0.png")
	she_zhi_btn.size = Vector2(64, 64)
	# 位置与项目统一的返回按钮一致（右上角，视口宽-96, 32）
	she_zhi_btn.position = Vector2(win_x - 96, 32)
	# 层级高于设置面板(1000)，保证设置打开时齿轮仍显示在最上层
	she_zhi_btn.z_index = 1001
	# 悬停图标切换在_input中按鼠标位置判定（面板开关瞬间mouse_entered/exited信号会丢失，信号方式不可靠）
	add_child(she_zhi_btn)
	# 设置面板总容器：只有全屏遮罩（初始隐藏，置于最上层）
	she_zhi_panel = Control.new()
	she_zhi_panel.size = Vector2(win_x, win_y)
	she_zhi_panel.visible = false
	she_zhi_panel.z_index = 1000
	# 全屏半透明遮罩（仅压暗并拦截对底层的点击，点击外部不关闭设置，返回只能点齿轮）
	var mask = ColorRect.new()
	mask.color = Color(0, 0, 0, 0.5)
	mask.anchor_right = 1.0
	mask.anchor_bottom = 1.0
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	she_zhi_panel.add_child(mask)
	# 三项目录与各子面板：各自按内容定高、屏幕居中，通过可见性切换
	she_zhi_mu_lu = C_she_zhi_mu_lu(win_x, win_y)
	she_zhi_yu_yan = C_she_zhi_yu_yan(win_x, win_y)
	she_zhi_zhen_lv = C_she_zhi_zhen_lv(win_x, win_y)
	she_zhi_jing_tou = C_she_zhi_jing_tou(win_x, win_y)
	she_zhi_yu_jin = C_she_zhi_yu_jin(win_x, win_y)
	she_zhi_yu_yan.visible = false
	she_zhi_zhen_lv.visible = false
	she_zhi_jing_tou.visible = false
	she_zhi_yu_jin.visible = false
	# 音量子界面：直接内嵌音量调节模块，其320×180面板照搬原样（屏幕居中），显隐由qie_huan_zi_jie_mian控制
	VOL_sz = load("res://音乐/音量调节.gd").new()
	VOL_sz.qian_ru = true
	she_zhi_panel.add_child(VOL_sz)
	add_child(she_zhi_panel)

# 齿轮按钮的点击与悬停在_input中直接判定（不依赖控件信号，保证设置开/关后依然生效）
func _input(event: InputEvent) -> void:
	if she_zhi_btn == null or not she_zhi_btn.visible:
		return
	# 悬停：按鼠标是否在齿轮64×64区域内切换图标
	if event is InputEventMouseMotion:
		var xuan_ting = Rect2(she_zhi_btn.position, she_zhi_btn.size).has_point(event.position)
		she_zhi_btn.texture = load("res://主界面/图片/齿轮1.png") if xuan_ting else load("res://主界面/图片/齿轮0.png")
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 只响应落在齿轮64×64区域内的点击
		if Rect2(she_zhi_btn.position, she_zhi_btn.size).has_point(event.position):
			# 逐级切换：关闭状态→打开设置目录；子界面→返回设置目录；目录→关闭设置
			if not she_zhi_panel.visible:
				dakai_she_zhi(true)
			elif she_zhi_ceng > 0:
				qie_huan_zi_jie_mian(0)
			else:
				dakai_she_zhi(false)
			# 标记事件已处理，避免同一点击穿透到底层遮罩或按钮
			get_viewport().set_input_as_handled()

# 创建条目式设置面板：标题+签名框条目列表，高度随条目数自动调整（顶部90放标题、每条64、底部留白20），屏幕居中
func C_tiao_mu_ban(biao_ti: String, tiao_mus: Array, win_x: float, win_y: float) -> Control:
	var jie = Control.new()
	var gao: int = 110 + 64 * tiao_mus.size()
	var ban_pos := Vector2((win_x - 320) / 2.0, (win_y - gao) / 2.0)
	# 面板背景：树屋同款背包背景，宽320，高度按内容计算
	var ban_bg = TextureRect.new()
	ban_bg.texture = load("res://全局/图片/背包背景.png")
	ban_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ban_bg.size = Vector2(320, gao)
	ban_bg.position = ban_pos
	jie.add_child(ban_bg)
	# 面板标题
	var lbl = Label.new()
	lbl.text = tr(biao_ti)
	lbl.size = Vector2(320, 50)
	lbl.position = ban_pos + Vector2(0, 30)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(lbl)
	jie.add_child(lbl)
	# 条目列表（每项：[文本, 点击回调]）
	for i in range(tiao_mus.size()):
		C_she_zhi_tiao_mu(jie, tiao_mus[i][0], ban_pos + Vector2(20, 90 + i * 64), tiao_mus[i][1])
	she_zhi_panel.add_child(jie)
	return jie

# 创建一条签名框样式的设置条目（wei_zhi为面板内相对坐标，hui_diao为点击回调）
func C_she_zhi_tiao_mu(rong_qi: Control, wen_ben: String, wei_zhi: Vector2, hui_diao: Callable) -> void:
	# 条目背景用树屋任务同款签名框
	var tiao_mu_bg = TextureRect.new()
	tiao_mu_bg.texture = load("res://关卡/信息/签名框1.png")
	tiao_mu_bg.size = Vector2(280, 54)
	tiao_mu_bg.position = wei_zhi
	tiao_mu_bg.mouse_entered.connect(func(): tiao_mu_bg.modulate = Color(1.3, 1.3, 1.3, 1))
	tiao_mu_bg.mouse_exited.connect(func(): tiao_mu_bg.modulate = Color(1, 1, 1, 1))
	# 项目惯例：可点击图标一律用 TextureRect + gui_input
	tiao_mu_bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			hui_diao.call()
	)
	rong_qi.add_child(tiao_mu_bg)
	# 条目文字（居中、黑色、楷体）
	var lbl = Label.new()
	lbl.text = tr(wen_ben)
	lbl.size = Vector2(280, 54)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	she_zhi_kai_ti(lbl)
	tiao_mu_bg.add_child(lbl)

# 创建存档模式选择面板：与设置面板同款条目样式，点击条目即选择并进入人物选择
func chuang_jian_mo_shi_pan() -> void:
	var size = get_viewport_rect().size
	var win_x = size.x
	var win_y = size.y
	mo_shi_panel = Control.new()
	mo_shi_panel.size = Vector2(win_x, win_y)
	mo_shi_panel.visible = false
	# 层级低于设置面板（1000）、高于槽位层
	mo_shi_panel.z_index = 900
	# 全屏半透明遮罩：拦截底层槽位点击，点面板外空白处取消并回到槽位列表
	var mask = ColorRect.new()
	mask.color = Color(0, 0, 0, 0.5)
	mask.anchor_right = 1.0
	mask.anchor_bottom = 1.0
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mo_shi_qu_xiao()
	)
	mo_shi_panel.add_child(mask)
	# 面板：标题 90 + 两条目 + 底部提示
	var gao = 270
	var ban_pos = Vector2((win_x - 320) / 2.0, (win_y - gao) / 2.0)
	var ban_bg = TextureRect.new()
	ban_bg.texture = load("res://全局/图片/背包背景.png")
	ban_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ban_bg.size = Vector2(320, gao)
	ban_bg.position = ban_pos
	ban_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	mo_shi_panel.add_child(ban_bg)
	# 面板标题
	var tit = Label.new()
	tit.text = tr("选择存档模式")
	tit.size = Vector2(320, 50)
	tit.position = ban_pos + Vector2(0, 30)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(tit)
	mo_shi_panel.add_child(tit)
	# 两个模式条目：与设置面板条目样式一致，点击即选择并进入人物选择
	C_mo_shi_tiao_mu("标准模式", ban_pos + Vector2(20, 90), 游戏存档.MO_SHI_BIAO_ZHUN)
	C_mo_shi_tiao_mu("富豪模式", ban_pos + Vector2(20, 154), 游戏存档.MO_SHI_FU_HAO)
	# 简短提示（常驻）
	var shuo = Label.new()
	shuo.text = tr("富豪模式无法获得成就")
	shuo.size = Vector2(320, 30)
	shuo.position = ban_pos + Vector2(0, 224)
	shuo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shuo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shuo.add_theme_font_size_override("font_size", 16)
	shuo.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(shuo)
	mo_shi_panel.add_child(shuo)
	add_child(mo_shi_panel)

# 创建一条模式条目（签名框背景 + 居中文字），点击后按所选模式进入人物选择
func C_mo_shi_tiao_mu(wen_ben: String, wei_zhi: Vector2, mo: int) -> void:
	var tiao_mu_bg = TextureRect.new()
	tiao_mu_bg.texture = load("res://关卡/信息/签名框1.png")
	tiao_mu_bg.size = Vector2(280, 54)
	tiao_mu_bg.position = wei_zhi
	tiao_mu_bg.mouse_entered.connect(func(): tiao_mu_bg.modulate = Color(1.3, 1.3, 1.3, 1))
	tiao_mu_bg.mouse_exited.connect(func(): tiao_mu_bg.modulate = Color(1, 1, 1, 1))
	tiao_mu_bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mo_shi_xuan_ze(mo)
	)
	mo_shi_panel.add_child(tiao_mu_bg)
	var lbl = Label.new()
	lbl.text = tr(wen_ben)
	lbl.size = Vector2(280, 54)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	she_zhi_kai_ti(lbl)
	tiao_mu_bg.add_child(lbl)

# 点击某个模式：记录选择、关闭面板并进入人物选择（异常取值按标准模式兜底）
func mo_shi_xuan_ze(mo: int) -> void:
	mo_shi_xuan = 游戏存档.MO_SHI_BIAO_ZHUN
	if mo == 游戏存档.MO_SHI_FU_HAO:
		mo_shi_xuan = 游戏存档.MO_SHI_FU_HAO
	if mo_shi_panel != null:
		mo_shi_panel.visible = false
	helo_xuan_ze.visible = true
	# 进入人物面板时刷新英雄锁定状态
	upd_xuan_ge_suo()
	upd_cheng_gan_qi_suo()

# 显示模式面板（每次打开都回到标准模式，点条目后才生效）
func xian_shi_mo_shi_pan() -> void:
	mo_shi_xuan = 游戏存档.MO_SHI_BIAO_ZHUN
	if mo_shi_panel != null:
		mo_shi_panel.visible = true

# 创建设置目录面板：语言/音量/基础帧率/镜头跟随速度/余烬滤镜强度（高度随条目数自动调整）
func C_she_zhi_mu_lu(win_x: float, win_y: float) -> Control:
	return C_tiao_mu_ban("设置", [
		["语言", qie_huan_zi_jie_mian.bind(1)],
		["音量", qie_huan_zi_jie_mian.bind(2)],
		["基础帧率", qie_huan_zi_jie_mian.bind(3)],
		["镜头跟随速度", qie_huan_zi_jie_mian.bind(4)],
		["余烬滤镜强度", qie_huan_zi_jie_mian.bind(5)],
	], win_x, win_y)

# 创建语言子界面面板：四种语言各用一条签名框条目
func C_she_zhi_yu_yan(win_x: float, win_y: float) -> Control:
	var tiao_mus: Array = []
	for yu_yan in YU_YAN_LIE_BIAO:
		tiao_mus.append([yu_yan["ming"], _on_yu_yan_xuan_ze.bind(yu_yan["code"])])
	return C_tiao_mu_ban("语言", tiao_mus, win_x, win_y)

# 创建基础帧率子界面面板：标题 + 数值文字 + 10~60 滑块，按内容定高230
func C_she_zhi_zhen_lv(win_x: float, win_y: float) -> Control:
	var jie = Control.new()
	var ban_pos := Vector2((win_x - 320) / 2.0, (win_y - 230) / 2.0)
	var ban_bg = TextureRect.new()
	ban_bg.texture = load("res://全局/图片/背包背景.png")
	ban_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ban_bg.size = Vector2(320, 230)
	ban_bg.position = ban_pos
	jie.add_child(ban_bg)
	# 面板标题
	var tit = Label.new()
	tit.text = tr("基础帧率")
	tit.size = Vector2(320, 50)
	tit.position = ban_pos + Vector2(0, 30)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(tit)
	jie.add_child(tit)
	# 当前帧率数值文字
	she_zhi_zl_lbl = Label.new()
	she_zhi_zl_lbl.position = ban_pos + Vector2(0, 100)
	she_zhi_zl_lbl.size = Vector2(320, 40)
	she_zhi_zl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	she_zhi_zl_lbl.add_theme_font_size_override("font_size", 26)
	she_zhi_zl_lbl.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(she_zhi_zl_lbl)
	jie.add_child(she_zhi_zl_lbl)
	# 帧率滑块（10~60，步长1）
	she_zhi_zl_slider = HSlider.new()
	she_zhi_zl_slider.position = ban_pos + Vector2(20, 165)
	she_zhi_zl_slider.size = Vector2(280, 20)
	she_zhi_zl_slider.min_value = 10
	she_zhi_zl_slider.max_value = 60
	she_zhi_zl_slider.step = 1
	she_zhi_zl_slider.tick_count = 51
	she_zhi_zl_slider.value_changed.connect(func(value):
		# 拖动即写入通用存档；主界面动画在关闭设置时统一刷新
		if json != null:
			json.set_ji_chu_zhen_lv(int(value))
		she_zhi_zl_lbl.text = tr("帧率：%d") % int(value)
	)
	jie.add_child(she_zhi_zl_slider)
	she_zhi_panel.add_child(jie)
	return jie

# 创建镜头跟随速度子界面：标题 + 说明文字 + 档位数值 + 0~7共8档滑块，按内容定高230
func C_she_zhi_jing_tou(win_x: float, win_y: float) -> Control:
	var jie = Control.new()
	var ban_pos := Vector2((win_x - 320) / 2.0, (win_y - 230) / 2.0)
	var ban_bg = TextureRect.new()
	ban_bg.texture = load("res://全局/图片/背包背景.png")
	ban_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ban_bg.size = Vector2(320, 230)
	ban_bg.position = ban_pos
	jie.add_child(ban_bg)
	# 面板标题
	var tit = Label.new()
	tit.text = tr("镜头跟随速度")
	tit.size = Vector2(320, 44)
	tit.position = ban_pos + Vector2(0, 24)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(tit)
	jie.add_child(tit)
	# 说明文字：固定宽度自动换行，避免长文本超出320宽面板（翻译后长度会变化）
	var shuo = Label.new()
	shuo.text = tr("英雄移动后，画面移到中心的过渡速度")
	shuo.position = ban_pos + Vector2(20, 68)
	shuo.size = Vector2(280, 66)
	shuo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shuo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shuo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shuo.add_theme_font_size_override("font_size", 16)
	shuo.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(shuo)
	jie.add_child(shuo)
	# 当前档位数值文字（0档显示「不移动」）
	she_zhi_jt_lbl = Label.new()
	she_zhi_jt_lbl.position = ban_pos + Vector2(0, 136)
	she_zhi_jt_lbl.size = Vector2(320, 32)
	she_zhi_jt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	she_zhi_jt_lbl.add_theme_font_size_override("font_size", 24)
	she_zhi_jt_lbl.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(she_zhi_jt_lbl)
	jie.add_child(she_zhi_jt_lbl)
	# 档位滑块（0~7共8档吸附，拖动即写入通用存档）
	she_zhi_jt_slider = HSlider.new()
	she_zhi_jt_slider.position = ban_pos + Vector2(20, 180)
	she_zhi_jt_slider.size = Vector2(280, 20)
	she_zhi_jt_slider.min_value = 游戏存档.JING_TOU_SU_DU_MIN
	she_zhi_jt_slider.max_value = 游戏存档.JING_TOU_SU_DU_MAX
	she_zhi_jt_slider.step = 1
	she_zhi_jt_slider.tick_count = 游戏存档.JING_TOU_SU_DU_MAX - 游戏存档.JING_TOU_SU_DU_MIN + 1
	she_zhi_jt_slider.value_changed.connect(func(value):
		# 拖动即写入通用存档；关卡内下次移动生效
		if json != null:
			json.set_jing_tou_su_du(int(value))
		upd_jing_tou_lbl(int(value))
	)
	jie.add_child(she_zhi_jt_slider)
	she_zhi_panel.add_child(jie)
	return jie

# 创建余烬滤镜强度子界面：标题 + 数值文字 + 10~60 滑块，按内容定高230
func C_she_zhi_yu_jin(win_x: float, win_y: float) -> Control:
	var jie = Control.new()
	var ban_pos := Vector2((win_x - 320) / 2.0, (win_y - 230) / 2.0)
	var ban_bg = TextureRect.new()
	ban_bg.texture = load("res://全局/图片/背包背景.png")
	ban_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ban_bg.size = Vector2(320, 230)
	ban_bg.position = ban_pos
	jie.add_child(ban_bg)
	# 面板标题
	var tit = Label.new()
	tit.text = tr("余烬滤镜强度")
	tit.size = Vector2(320, 50)
	tit.position = ban_pos + Vector2(0, 30)
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 28)
	tit.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(tit)
	jie.add_child(tit)
	# 当前强度数值文字（只翻译名称，数值与百分号各语言一致）
	she_zhi_yj_lbl = Label.new()
	she_zhi_yj_lbl.position = ban_pos + Vector2(0, 100)
	she_zhi_yj_lbl.size = Vector2(320, 40)
	she_zhi_yj_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	she_zhi_yj_lbl.add_theme_font_size_override("font_size", 26)
	she_zhi_yj_lbl.add_theme_color_override("font_color", Color.BLACK)
	she_zhi_kai_ti(she_zhi_yj_lbl)
	jie.add_child(she_zhi_yj_lbl)
	# 强度滑块（10~60，步长1）
	she_zhi_yj_slider = HSlider.new()
	she_zhi_yj_slider.position = ban_pos + Vector2(20, 165)
	she_zhi_yj_slider.size = Vector2(280, 20)
	she_zhi_yj_slider.min_value = 游戏存档.YU_JIN_QIANG_DU_MIN
	she_zhi_yj_slider.max_value = 游戏存档.YU_JIN_QIANG_DU_MAX
	she_zhi_yj_slider.step = 1
	she_zhi_yj_slider.tick_count = 游戏存档.YU_JIN_QIANG_DU_MAX - 游戏存档.YU_JIN_QIANG_DU_MIN + 1
	she_zhi_yj_slider.value_changed.connect(func(value):
		# 拖动即写入通用存档；关卡内遮罩下一帧自动读取
		if json != null:
			json.set_yu_jin_qiang_du(int(value))
		upd_yu_jin_lbl(int(value))
	)
	jie.add_child(she_zhi_yj_slider)
	she_zhi_panel.add_child(jie)
	return jie

# 刷新余烬滤镜强度数值文字
func upd_yu_jin_lbl(qiang: int) -> void:
	if she_zhi_yj_lbl == null or not is_instance_valid(she_zhi_yj_lbl):
		return
	she_zhi_yj_lbl.text = tr("余烬滤镜强度") + "：" + str(qiang) + "%"

# 刷新镜头跟随速度的数值文字（0档显示「不移动」，其余显示档位像素/秒）
func upd_jing_tou_lbl(dang: int) -> void:
	if she_zhi_jt_lbl == null or not is_instance_valid(she_zhi_jt_lbl):
		return
	if dang <= 0:
		she_zhi_jt_lbl.text = tr("镜头速度：不移动")
		return
	she_zhi_jt_lbl.text = tr("镜头速度：%d 像素/秒") % int(游戏存档.JING_TOU_SU_DU_DANG_WEI[dang])

# 给控件套用楷体字体（无字体缓存时保持默认字体）
func she_zhi_kai_ti(control: Control) -> void:
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		control.add_theme_font_override("font", kai_ti)

# 打开或关闭设置面板（打开时总是回到三项目录）
func dakai_she_zhi(da: bool) -> void:
	if she_zhi_panel == null:
		return
	she_zhi_panel.visible = da
	if da:
		qie_huan_zi_jie_mian(0)
		du_qu_zhen_lv()
		du_qu_jing_tou()
		du_qu_yu_jin()
	elif json != null:
		# 关闭设置后，主界面现有的存档/选角待机动画立即按新基础帧率播放
		json.shua_xin_dong_hua_su_du()

# 切换设置内的子界面并记录当前层级：0=三项目录 1=语言 2=音量 3=基础帧率 4=镜头跟随速度
func qie_huan_zi_jie_mian(n: int) -> void:
	she_zhi_ceng = n
	she_zhi_mu_lu.visible = n == 0
	she_zhi_yu_yan.visible = n == 1
	# 音量子界面即音量调节模块的P面板
	if VOL_sz != null and VOL_sz.P != null:
		VOL_sz.P.visible = n == 2
	she_zhi_zhen_lv.visible = n == 3
	she_zhi_jing_tou.visible = n == 4
	she_zhi_yu_jin.visible = n == 5

# 从通用存档读取基础帧率并同步到滑块与文字
func du_qu_zhen_lv() -> void:
	if json == null:
		return
	var zhen_lv = json.get_ji_chu_zhen_lv()
	if she_zhi_zl_slider != null:
		she_zhi_zl_slider.value = zhen_lv
	if she_zhi_zl_lbl != null:
		she_zhi_zl_lbl.text = tr("帧率：%d") % zhen_lv

# 从通用存档读取镜头跟随速度档位并同步到滑块与文字
func du_qu_jing_tou() -> void:
	if json == null:
		return
	var dang = json.get_jing_tou_su_du()
	if she_zhi_jt_slider != null:
		she_zhi_jt_slider.value = dang
	upd_jing_tou_lbl(dang)

# 从通用存档读取余烬滤镜强度并同步到滑块与文字
func du_qu_yu_jin() -> void:
	if json == null:
		return
	var qiang = json.get_yu_jin_qiang_du()
	if she_zhi_yj_slider != null:
		she_zhi_yj_slider.value = qiang
	upd_yu_jin_lbl(qiang)

# 语言选项被点击：保存到通用存档、关闭设置并重建场景让所有文本按新语言刷新
func _on_yu_yan_xuan_ze(code: String) -> void:
	json.set_yu_yan(code)
	she_zhi_panel.visible = false
	# Label 的 text 是一次性赋值，切换 locale 后需重建场景才能按新语言渲染
	get_tree().reload_current_scene()

# 当鼠标移动到按钮上时，显示悬停图片并将画面调亮
func _on_mouse_entered() -> void:
	an_niu.texture = an_niu_hover
	bg.modulate = Color(2, 2, 2, 1)

# 当鼠标离开按钮时，恢复普通图片和正常亮度
func _on_mouse_exited() -> void:
	an_niu.texture = an_niu_normal
	bg.modulate = Color(1, 1, 1, 1)

# 当点击开始游戏按钮，显示遮挡层和存档按钮
func _on_button_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 隐藏开始游戏按钮
			an_niu.visible = false
			# 显示存档返回按钮
			json_fan_hui.visible = true
			# 隐藏设置齿轮按钮（如果设置面板开着也一并关闭）
			dakai_she_zhi(false)
			she_zhi_btn.visible = false
			an_niu_upd()

# 存档槽位悬停：应用该槽位对应的颜色
func _on_cao_wei_hover(idx: int) -> void:
	an_nius[idx].modulate = yan_se_ma_to_color(yan_se_mas[idx])

# 存档槽位离开：恢复原始图片色（无滤镜）
func _on_cao_wei_exit(idx: int) -> void:
	an_nius[idx].modulate = Color(1, 1, 1, 1)

# 刷新存档按钮显示状态
func an_niu_upd() -> void:
	for btn in an_nius:
		btn.visible = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in range(cao_wei):
		if json.you_cai_dang(i):
			var data = json.du_qu(i)
			var lv = data.get("等级", 1)
			# 富豪模式复用本次已读取的 data 判定，不额外读档
			if 游戏存档.mo_shi_biao_zhi_of(data) == 游戏存档.MO_SHI_FU_HAO:
				an_nius[i].text = "   %d\n\n\n\n  %s" % [i + 1, tr("富豪Lv.%d") % lv]
			else:
				an_nius[i].text = "   %d\n\n\n\n    Lv.%d" % [i + 1, lv]
			shan_chus[i].visible = true
			# 显示待机动画（英雄名无效时跳过，避免加载失败）
			var ming_zi = data.get("英雄", "")
			var dong_hua = load("res://角色/人物/" + ming_zi + "/" + ming_zi + "动画.tres")
			if dong_hua != null:
				json_idles[i].sprite_frames = dong_hua
				json_idles[i].visible = true
				json_idles[i].play("idle")
				json_idles[i].speed_scale = json.get_dong_hua_su_du()
		else:
			an_nius[i].text = "   %d\n\n\n\n\n" % (i + 1)
			# 隐藏删除按钮
			shan_chus[i].visible = false
			# 隐藏待机动画
			json_idles[i].visible = false

# 记录选中的槽位号，保存到临时文件，然后根据是否有存档决定下一步操作
func dian_ji(dang_wei: int) -> void:
	# 记录当前选中的存档槽位编号
	json_id = dang_wei
	# 检查并创建存档文件夹
	json.wen_jian_jia()
	# 保存槽位号到数据管理节点
	if has_node("/root/数据管理"):
		get_node("/root/数据管理").json = dang_wei
	# 检查该槽位是否有存档
	if json.you_cai_dang(dang_wei):
		# 读取存档数据检查是否缺少字段
		var data = json.du_qu(dang_wei)
		# 检测并修正等级（根据经验值）
		json.chk_lv(data)
		# 检查名字字段
		if not data.has("英雄"):
			data["英雄"] = ""
		# 检查等级字段
		if not data.has("等级"):
			data["等级"] = 1
		# 检查经验字段
		if not data.has("经验"):
			data["经验"] = 0
		# 检查银币字段
		if not data.has("银币"):
			data["银币"] = 0
		# 检查进度字段
		if not data.has("进度"):
			data["进度"] = 1
		# 检查任务字段（已领取任务序号清单，字段不存在或旧格式整数时建空数组）
		if not data.has("任务") or not data["任务"] is Array:
			data["任务"] = []
		# 检查强化字段（按第1~4件装备位的等级数组；旧字典格式存档直接重置）
		if not data.has("强化") or not data["强化"] is Array:
			data["强化"] = [0, 0, 0, 0]
		# 检查成就字段（已领取成就序号清单，字段不存在时建空数组）
		if not data.has("成就") or not data["成就"] is Array:
			data["成就"] = []
		# 检查模式标识字段（旧档缺失时补标准模式；已存在但为非法值时保持原样，读取侧按标准处理）
		if not data.has(游戏存档.MO_SHI_ZI_DUAN):
			data[游戏存档.MO_SHI_ZI_DUAN] = 游戏存档.MO_SHI_BIAO_ZHUN
		# 保存
		json.bao_cun(dang_wei, data)
		# 保存当前存档ID到游戏存档节点
		json.id = dang_wei
		# 将游戏存档节点移到root下，使其在切换场景后继续存在
		if json.get_parent() != get_tree().root:
			get_tree().root.add_child(json)
		# 切换场景前先恢复总线音量：主城背景音乐在场景实例化时即autoplay，
		# 若等音量调节节点_ready再设置，音乐会先以默认0dB响一瞬后才变成设置值
		var yue_liang_bus = AudioServer.get_bus_index("Master")
		# 音量设置存在通用存档里，所有档共用
		var ty_data = json.du_qu_ty()
		if int(ty_data.get("静音", 0)) == 1:
			# 静音状态直接压到-80dB，与音量调节.gd的静音处理一致
			AudioServer.set_bus_volume_db(yue_liang_bus, -80)
		else:
			AudioServer.set_bus_volume_db(yue_liang_bus, clampi(int(ty_data.get("分贝", -40)), -80, 0))
		# 已有存档，进入主城
		get_tree().change_scene_to_file("res://主城/主城.tscn")
	else:
		# 隐藏所有存档按钮和删除按钮
		for btn in an_nius:
			btn.visible = false
		for btn in shan_chus:
			btn.visible = false
		for s in json_idles:
			s.visible = false
		# 隐藏存档返回按钮
		json_fan_hui.visible = false
		# 先选择存档模式，确认后才进入人物选择（英雄锁定态在确认时刷新）
		xian_shi_mo_shi_pan()

# 刷新玄戈的解锁状态：历史成就【救世主Ⅰ】（序号0001）不存在时锁定
func upd_xuan_ge_suo() -> void:
	# 解锁依据由 has_hero_jie_suo 按历史成就实时推导（不迁移、不读当前存档英雄字段）
	xuan_ge_suo = not json.has_hero_jie_suo("玄戈")
	if xuan_ge_suo:
		# 锁定：按钮与待机动画一起暗淡
		xuan_ge.modulate = Color(0.5, 0.5, 0.5, 1)
		xuan_ge_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		# 已解锁：恢复正常亮度
		xuan_ge.modulate = Color(1, 1, 1, 1)
		xuan_ge_idle.modulate = Color(1, 1, 1, 1)
# 刷新秤干戚的解锁状态：历史成就【救世主Ⅱ】（序号0002）不存在时锁定
func upd_cheng_gan_qi_suo() -> void:
	cheng_gan_qi_suo = not json.has_hero_jie_suo("秤干戚")
	if cheng_gan_qi_suo:
		cheng_gan_qi.modulate = Color(0.5, 0.5, 0.5, 1)
		cheng_gan_qi_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		cheng_gan_qi.modulate = Color(1, 1, 1, 1)
		cheng_gan_qi_idle.modulate = Color(1, 1, 1, 1)


# 模式面板取消：回到槽位列表，不创建存档、不写任何文件
func mo_shi_qu_xiao() -> void:
	if mo_shi_panel != null:
		mo_shi_panel.visible = false
	json_fan_hui.visible = true
	an_niu_upd()

# 点击爱丽丝
func _on_爱丽丝按钮_input() -> void:
	C_json("爱丽丝")
# 点击玄戈
func _on_玄戈按钮_input() -> void:
	# 锁定状态下拦截选择，提示解锁条件，不创建存档
	if xuan_ge_suo:
		提示弹幕.wen_ben(tr("完成成就【%s】解锁英雄【%s】！") % [tr("救世主Ⅰ"), tr("玄戈")], 0)
		return
	C_json("玄戈")
# 点击秤干戚
func _on_秤干戚按钮_input() -> void:
	if cheng_gan_qi_suo:
		提示弹幕.wen_ben(tr("完成成就【%s】解锁英雄【%s】！") % [tr("救世主Ⅱ"), tr("秤干戚")], 0)
		return
	C_json("秤干戚")

# 爱丽丝按钮悬停
func _on_爱丽丝按钮_hover() -> void:
	Alice.modulate = Color(0.5, 1, 2, 1)
# 爱丽丝按钮离开
func _on_爱丽丝按钮_exit() -> void:
	Alice.modulate = Color(1, 1, 1, 1)
# 玄戈按钮悬停
func _on_玄戈按钮_hover() -> void:
	# 锁定时保持暗淡，不响应悬停高亮
	if xuan_ge_suo:
		return
	xuan_ge.modulate = Color(2, 1, 0.5, 1)
# 玄戈按钮离开
func _on_玄戈按钮_exit() -> void:
	# 锁定时保持暗淡，不恢复亮色
	if xuan_ge_suo:
		return
	xuan_ge.modulate = Color(1, 1, 1, 1)
# 秤干戚按钮悬停
func _on_秤干戚按钮_hover() -> void:
	if cheng_gan_qi_suo:
		return
	cheng_gan_qi.modulate = Color(0.5, 2, 1, 1)
# 秤干戚按钮离开
func _on_秤干戚按钮_exit() -> void:
	if cheng_gan_qi_suo:
		return
	cheng_gan_qi.modulate = Color(1, 1, 1, 1)

# 选择人物并创建存档（按所选模式写入模式标识与初始银币）
func C_json(helo_name: String) -> void:
	# 防连点：建档尚未结束时忽略后续点击
	if zheng_jian_zhong:
		return
	# 槽位已被占用时不覆盖已有存档
	if json.you_cai_dang(json_id):
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		日志.打印("新建存档失败：槽位已被占用 槽位=" + str(json_id))
		return
	# 拼接人物场景路径并加载
	var helo_path = "res://角色/人物/" + helo_name + "/" + helo_name + ".tscn"
	var helo_tscn = load(helo_path)
	if helo_tscn == null:
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		日志.打印("新建存档失败：角色加载失败 " + helo_path)
		return
	# 非法模式取值一律按标准模式
	if mo_shi_xuan != 游戏存档.MO_SHI_FU_HAO:
		mo_shi_xuan = 游戏存档.MO_SHI_BIAO_ZHUN
	# 实例化人物节点获取属性
	var helo = helo_tscn.instantiate()
	var chu_shi_yin_bi: int = 游戏存档.FU_HAO_CHU_SHI_YIN_BI if mo_shi_xuan == 游戏存档.MO_SHI_FU_HAO else 0
	# 创建初始存档数据
	var data = {
		"英雄": helo.get_name(),
		"等级": 1,
		"经验": 0,
		"银币": chu_shi_yin_bi,
		"进度": 1,
		"任务": [],
		"强化": [0, 0, 0, 0],
		"成就": []
	}
	data[游戏存档.MO_SHI_ZI_DUAN] = mo_shi_xuan
	# 释放临时人物节点
	helo.free()
	# 单次写入并校验结果
	zheng_jian_zhong = true
	var cg: bool = json.bao_cun(json_id, data)
	zheng_jian_zhong = false
	if not cg:
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		日志.打印("新建存档失败：保存失败 槽位=" + str(json_id) + " 模式=" + str(mo_shi_xuan))
		return
	日志.打印("新建存档：槽位%d 模式=%d" % [json_id, mo_shi_xuan])
	# 隐藏人物选择面板
	helo_xuan_ze.visible = false
	# 显示存档返回按钮
	json_fan_hui.visible = true
	# 刷新存档按钮显示
	an_niu_upd()

# 点击返回按钮
func _on_返回按钮_input() -> void:
	# 隐藏人物选择面板
	helo_xuan_ze.visible = false
	# 显示存档返回按钮
	json_fan_hui.visible = true
	# 刷新存档按钮显示
	an_niu_upd()

# 删除按钮点击处理
func shan_chu_an_niu(dang_wei: int) -> void:
	json_id = dang_wei
	# 隐藏存档返回按钮
	json_fan_hui.visible = false
	# 隐藏存档按钮和删除按钮
	for btn in an_nius:
		btn.visible = false
	for btn in shan_chus:
		btn.visible = false
	for s in json_idles:
		s.visible = false
	# 显示确定面板
	er_ci.visible = true

# 点击确定按钮
func _on_确定按钮_input() -> void:
	# 删除存档文件
	json.shan_chu(json_id)
	# 隐藏确定面板
	er_ci.visible = false
	# 显示存档返回按钮
	json_fan_hui.visible = true
	# 刷新存档按钮显示
	an_niu_upd()

# 点击取消按钮
func _on_取消按钮_input() -> void:
	# 隐藏确定面板
	er_ci.visible = false
	# 显示存档返回按钮
	json_fan_hui.visible = true
	# 刷新存档按钮显示
	an_niu_upd()

# 存档返回按钮被点击
func on_json_fan_hui() -> void:
	# 隐藏存档返回按钮
	json_fan_hui.visible = false
	# 隐藏存档按钮和删除按钮
	for btn in an_nius:
		btn.visible = false
	for btn in shan_chus:
		btn.visible = false
	for idle in json_idles:
		idle.visible = false
	# 显示开始游戏按钮
	an_niu.visible = true
	# 恢复显示设置齿轮按钮
	she_zhi_btn.visible = true
