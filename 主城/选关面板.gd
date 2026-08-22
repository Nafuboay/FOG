class_name 选关面板 extends Control
@onready var bg = $背景
@onready var fan_hui = $返回按钮
@onready var btn_0 = $关卡按钮0
@onready var btn_1 = $关卡按钮1
@onready var btn_2 = $关卡按钮2
@onready var btn_3 = $关卡按钮3
@onready var btn_4 = $关卡按钮4
@onready var btn_5 = $关卡按钮5
@onready var btn_6 = $关卡按钮6
@onready var btn_7 = $关卡按钮7
@onready var btn_8 = $关卡按钮8
@onready var btn_9 = $关卡按钮9
@onready var btn_10 = $关卡按钮10
@onready var btn_11 = $关卡按钮11
@onready var btn_12 = $关卡按钮12
@onready var btn_13 = $关卡按钮13
@onready var btn_14 = $关卡按钮14
@onready var btn_15 = $关卡按钮15
@onready var btn_16 = $关卡按钮16
@onready var btn_17 = $关卡按钮17
@onready var btn_18 = $关卡按钮18
@onready var btn_19 = $关卡按钮19
@onready var btn_20 = $关卡按钮20
@onready var btn_21 = $关卡按钮21
@onready var btn_22 = $关卡按钮22
@onready var btn_23 = $关卡按钮23
@onready var btn_24 = $关卡按钮24
@onready var btn_25 = $关卡按钮25
@onready var btn_26 = $关卡按钮26
@onready var btn_27 = $关卡按钮27
@onready var btn_28 = $关卡按钮28
@onready var btn_29 = $关卡按钮29
@onready var idle_0 = $关卡待机0
@onready var idle_1 = $关卡待机1
@onready var idle_2 = $关卡待机2
@onready var idle_3 = $关卡待机3
@onready var idle_4 = $关卡待机4
@onready var idle_5 = $关卡待机5
@onready var idle_6 = $关卡待机6
@onready var idle_7 = $关卡待机7
@onready var idle_8 = $关卡待机8
@onready var idle_9 = $关卡待机9
@onready var idle_10 = $关卡待机10
@onready var idle_11 = $关卡待机11
@onready var idle_12 = $关卡待机12
@onready var idle_13 = $关卡待机13
@onready var idle_14 = $关卡待机14
@onready var idle_15 = $关卡待机15
@onready var idle_16 = $关卡待机16
@onready var idle_17 = $关卡待机17
@onready var idle_18 = $关卡待机18
@onready var idle_19 = $关卡待机19
@onready var idle_20 = $关卡待机20
@onready var idle_21 = $关卡待机21
@onready var idle_22 = $关卡待机22
@onready var idle_23 = $关卡待机23
@onready var idle_24 = $关卡待机24
@onready var idle_25 = $关卡待机25
@onready var idle_26 = $关卡待机26
@onready var idle_27 = $关卡待机27
@onready var idle_28 = $关卡待机28
@onready var idle_29 = $关卡待机29
var btn: Array[Button] = []
var idle: Array[Node] = []
var guan: int = 30
var current_mode: int = 0 # 0=主线, 1=诛邪
# 诛邪模式下禁用的关卡ID列表（第2关为魔法树关，无新怪物）
const ZX_DISABLED_GUAN: Array[int] = [1]

func _ready() -> void:
	btn = [btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7, btn_8, btn_9, btn_10, btn_11, btn_12, btn_13, btn_14, btn_15, btn_16, btn_17, btn_18, btn_19, btn_20, btn_21, btn_22, btn_23, btn_24, btn_25, btn_26, btn_27, btn_28, btn_29]
	idle = [idle_0, idle_1, idle_2, idle_3, idle_4, idle_5, idle_6, idle_7, idle_8, idle_9, idle_10, idle_11, idle_12, idle_13, idle_14, idle_15, idle_16, idle_17, idle_18, idle_19, idle_20, idle_21, idle_22, idle_23, idle_24, idle_25, idle_26, idle_27, idle_28, idle_29]
	visible = false
	chu_shi_hua()

# 获取当前模式
func get_mode() -> int:
	if has_node("/root/数据管理"):
		current_mode = get_node("/root/数据管理").mode
	return current_mode

# 更新模式并刷新显示
func set_mode(mode: int) -> void:
	current_mode = mode
	xian_shi()

# 检查关卡在当前模式下是否可进入
func is_guan_ke_jin(guan_kia_id: int) -> bool:
	if current_mode == 1:
		# 诛邪模式：检查关卡是否被禁用
		if guan_kia_id in ZX_DISABLED_GUAN:
			return false
	return true

# 初始化
func chu_shi_hua() -> void:
	var win_size = get_viewport_rect().size
	var win_x = win_size.x
	var win_y = win_size.y
	var hang_shu = 4
	var lie_shu = 8
	for i in range(btn.size()):
		var m = i % lie_shu
		var n = int(i / float(lie_shu))
		var x = (2.0 * m + 3.0) / (lie_shu * 2.0 + 4.0) * win_x - 64
		var y = (2.0 * n + 2.0) / (hang_shu * 2.0 + 2.0) * win_y - 64
		btn[i].position = Vector2(x,y)
		btn[i].custom_minimum_size = Vector2(128,128)
		idle[i].position = Vector2(x+47,y+47)
		var cao_yuan_0 = StyleBoxTexture.new()
		cao_yuan_0.texture = load("res://主界面/图片/模块0.png")
		btn[i].add_theme_stylebox_override("normal", cao_yuan_0)
		btn[i].add_theme_stylebox_override("pressed", cao_yuan_0)
		var cao_yuan_1 = StyleBoxTexture.new()
		cao_yuan_1.texture = load("res://主界面/图片/模块1.png")
		btn[i].add_theme_stylebox_override("hover", cao_yuan_1)
		btn[i].add_theme_color_override("font_color", Color.BLACK)
		btn[i].add_theme_color_override("font_hover_color", Color.BLACK)
		# 设置楷体字体
		get_kai_ti(btn[i])

# 设置控件使用楷体字体
func get_kai_ti(control: Control) -> void:
	var kai_ti = 提示弹幕.get_kai_ti_font()
	if kai_ti != null:
		control.add_theme_font_override("font", kai_ti)

func xian_shi() -> void:
	visible = true
	var win_size = get_viewport_rect().size
	var win_x = win_size.x
	var win_y = win_size.y
	var hang_shu = 4
	var lie_shu = 8
	# 读取当前模式
	get_mode()
	# 读取存档进度（保证stg至少为1）
	var json = get_node_or_null("/root/游戏存档")
	var stg = 1
	if json != null:
		var s = json.get_stg()
		if s > 0:
			stg = s
	var guai_wu_dong_hua = [
		load("res://角色/怪物/41紫蠃/紫蠃.tres"),
		null,
		load("res://角色/怪物/21邪嘴唇花/邪嘴唇花.tres"),
		load("res://角色/怪物/42紫蠃贤者/紫蠃贤者.tres"),
		load("res://角色/怪物/11红巨蟹/红巨蟹.tres"),
		load("res://角色/怪物/12褐巨蟹/褐巨蟹.tres"),
		load("res://角色/怪物/22橙食人花/橙食人花.tres"),
		load("res://角色/怪物/23紫食人花/紫食人花.tres"),
		load("res://角色/怪物/13青巨蟹/青巨蟹.tres"),
		load("res://角色/怪物/14紫巨蟹/紫巨蟹.tres"),
		load("res://角色/怪物/15蓝巨蟹/蓝巨蟹.tres"),
		load("res://角色/怪物/43蓝蠃勇者/蓝蠃勇者.tres"),
		load("res://角色/怪物/31白鬣野猪/白鬣野猪.tres"),
		load("res://角色/怪物/32白鬣赤猪/白鬣赤猪.tres"),
		load("res://角色/怪物/44紫蠃勇者/紫蠃勇者.tres"),
		load("res://角色/怪物/33茶鬣野猪/茶鬣野猪.tres"),
		load("res://角色/怪物/45褐蠃长老/褐蠃长老.tres"),
		load("res://角色/怪物/34绿鬣野猪/绿鬣野猪.tres"),
		load("res://角色/怪物/35黄斑野猪/黄斑野猪.tres"),
		load("res://角色/怪物/51黯灰狼/黯灰狼.tres"),
		load("res://角色/怪物/52靛苍狼/靛苍狼.tres"),
		load("res://角色/怪物/53粉褐狼/粉褐狼.tres"),
		load("res://角色/怪物/54冰河狼/冰河狼.tres"),
		load("res://角色/怪物/24邪花王·荆冠/邪花王.tres"),
		load("res://角色/怪物/25葵花王·槐昂/葵花王.tres"),
		load("res://角色/怪物/36野猪王·冕笑/野猪王.tres"),
		load("res://角色/怪物/46蠃虫王·犄眦/蠃虫王.tres"),
		load("res://角色/怪物/55双狼王·睚狈/双狼王.tres"),
		load("res://角色/怪物/61猛犸/猛犸.tres"),
		load("res://角色/怪物/62猛犸王·犽翡/猛犸王.tres")
	]
	var guai_wu_tu_pian = [
		null,
		load("res://关卡/草地/树.png"),
		null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null
	]
	for i in range(btn.size()):
		if i < guan:
			var m = i % lie_shu
			var n = int(i / float(lie_shu))
			var x = (2.0 * m + 3.0) / (lie_shu * 2.0 + 4.0) * win_x - 64
			var y = (2.0 * n + 2.0) / (hang_shu * 2.0 + 2.0) * win_y - 64
			btn[i].visible = true
			btn[i].text = "关卡"+str(i+1)+"\n\n\n\n\n\n\n"
			# 检查关卡是否可进入
			var ke_jin = true
			var guan_num = i + 1  # 关卡编号（1~30）
			if current_mode == 1:
				# 诛邪模式
				# 第2关禁用（魔法树关，无新怪物）
				if guan_num == 2:
					ke_jin = false
				# 需要主线先通关该关才能进入诛邪
				elif guan_num > stg:
					ke_jin = false
			else:
				# 主线模式
				if guan_num > stg:
					ke_jin = false
			if not ke_jin:
				btn[i].modulate = Color(0.5, 0.5, 0.5, 1)
			else:
				btn[i].modulate = Color(1, 1, 1, 1)
			if idle[i] is Sprite2D and guai_wu_tu_pian[i] != null:
				var s = idle[i] as Sprite2D
				s.position = Vector2(x+64,y+64)
				s.texture = guai_wu_tu_pian[i]
				s.visible = true
			elif idle[i] is AnimatedSprite2D and guai_wu_dong_hua[i] != null:
				var s = idle[i] as AnimatedSprite2D
				s.sprite_frames = guai_wu_dong_hua[i]
				s.play("idle")
				s.speed_scale = 0.4
				s.visible = true
		else:
			btn[i].visible = false

func yin_cang() -> void:
	visible = false
