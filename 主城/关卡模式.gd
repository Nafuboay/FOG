extends TextureRect # 关卡模式切换按钮
enum Mode { ZHU_XIAN, ZHU_XIE }
const TEX_MAIN_NORMAL: Texture2D = preload("res://主城/图片/主线1.png")    # 主线普通状态
const TEX_MAIN_HOVER: Texture2D = preload("res://主城/图片/主线2.png")      # 主线鼠标悬浮
const TEX_ZHUXIE_NORMAL: Texture2D = preload("res://主城/图片/诛邪1.png")    # 诛邪普通状态
const TEX_ZHUXIE_HOVER: Texture2D = preload("res://主城/图片/诛邪2.png")    # 诛邪鼠标悬浮
# 当前选中的游戏模式，初始默认主线
var current_mode: Mode = Mode.ZHU_XIAN
# 标记鼠标是否悬浮在按钮上
var is_hover: bool = false

func _ready() -> void:
	# 设置按钮位置（选关面板右侧，之后可自行调整）
	position = Vector2(1000, 600)
	# 鼠标进入按钮区域，开启悬浮标记，刷新按钮贴图
	mouse_entered.connect(func(): is_hover = true; _upd())
	# 鼠标离开按钮区域，关闭悬浮标记，刷新按钮贴图
	mouse_exited.connect(func(): is_hover = false; _upd())
	# 绑定鼠标点击输入回调
	gui_input.connect(_on_click)
	# 如果父节点存在，监听父节点显示状态变化
	if get_parent():
		# 父节点变为可见时，强制重置回主线模式（不保存上次选择）
		get_parent().visibility_changed.connect(func(): if get_parent().visible: _reset())
	# 初始化重置按钮状态
	_reset()

# 处理按钮鼠标点击事件
func _on_click(event: InputEvent) -> void:
	# 判断：鼠标左键按下
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 模式循环切换：主线 ↔ 诛邪
		current_mode = Mode.ZHU_XIE if current_mode == Mode.ZHU_XIAN else Mode.ZHU_XIAN
		# 通知数据管理节点模式变化
		if has_node("/root/数据管理"):
			get_node("/root/数据管理").mode = current_mode
		# 通知选关面板刷新显示
		if get_parent() and get_parent().has_method("set_mode"):
			get_parent().set_mode(current_mode)
		# 切换后刷新按钮显示贴图
		_upd()

# 重置按钮状态：恢复默认主线模式，清除悬浮标记
func _reset() -> void:
	current_mode = Mode.ZHU_XIAN
	is_hover = false
	# 通知数据管理节点模式变化
	if has_node("/root/数据管理"):
		get_node("/root/数据管理").mode = 0
	_upd()

# 更新按钮贴图：根据【当前模式】+【是否悬浮】赋值对应预加载纹理
func _upd() -> void:
	var target_tex: Texture2D
	if current_mode == Mode.ZHU_XIAN:
		# 主线模式：悬浮取主线2，普通状态取主线1
		target_tex = TEX_MAIN_HOVER if is_hover else TEX_MAIN_NORMAL
	else:
		# 诛邪模式：悬浮取诛邪2，普通状态取诛邪1
		target_tex = TEX_ZHUXIE_HOVER if is_hover else TEX_ZHUXIE_NORMAL
	# 安全校验：图片资源没找到时不赋值，避免报错
	if target_tex != null:
		texture = target_tex
