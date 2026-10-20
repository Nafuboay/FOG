# 通用翻页系统（可实例化工具类）
# 用途：统一管理强化材料区、主城背包、关卡临时背包、商店的翻页状态与翻页按钮
# 说明：每个界面各自持有一个实例，页码互不影响；每页格数在创建实例时传入
# 用法：fan_ye = 翻页系统_SCRIPT.new(每页格数, 翻页后重新显示的回调)
#       fan_ye.chuang_jian(界面容器)  # 创建立即被遮挡的上一页/下一页按钮
#       fan_ye.she_zhi(物品总数)      # 显示前设置总数（越界自动回到最后一页）
#       fan_ye.qi_shi()               # 本页第一个物品的序号
#       fan_ye.chong_zhi()            # 界面每次打开时重置到第一页
extends RefCounted
# 翻页按钮贴图（0=普通，1=悬停）
var SY_png0: Texture2D
var SY_png1: Texture2D
var XY_png0: Texture2D
var XY_png1: Texture2D
# 每页格数
var mei_ye: int = 49
# 当前页（从0开始）
var ye: int = 0
# 当前物品总数
var zong_shu: int = 0
# 上一页/下一页按钮
var SY_btn: TextureRect = null
var XY_btn: TextureRect = null
# 按钮悬停状态（无效状态不响应悬停）
var SY_xuan_fu: bool = false
var XY_xuan_fu: bool = false
# 翻页后回调（由使用方传入，用于重新显示当前页内容）
var bian_hua_hui_diao: Callable = Callable()

# 初始化：mei_ye_1=每页格数，hui_diao=翻页后重新显示的回调
func _init(mei_ye_1: int, hui_diao: Callable = Callable()) -> void:
	mei_ye = max(1, mei_ye_1)
	bian_hua_hui_diao = hui_diao
	SY_png0 = load("res://全局/图片/上一页0.png")
	SY_png1 = load("res://全局/图片/上一页1.png")
	XY_png0 = load("res://全局/图片/下一页0.png")
	XY_png1 = load("res://全局/图片/下一页1.png")

# 创建翻页按钮（原始大小128×64；qi_wei为空时默认放在界面面板正下方居中）
func chuang_jian(parent: Control, qi_wei: Vector2 = Vector2(-1, -1)) -> void:
	var btn_size = Vector2(128, 64)
	var jian_ge = 20
	# 未指定坐标时：面板底边 y=610 下方 4px 居中并排
	if qi_wei.x < 0:
		var win_size = parent.get_viewport_rect().size
		qi_wei = Vector2(win_size.x / 2.0 - (btn_size.x * 2 + jian_ge) / 2.0, win_size.y / 2.0 + 254.0)
	# 上一页按钮
	SY_btn = _chuang_jian_btn(parent, SY_png0, qi_wei, btn_size)
	SY_btn.mouse_entered.connect(_on_SY_btn_mouse_entered)
	SY_btn.mouse_exited.connect(_on_SY_btn_mouse_exited)
	SY_btn.gui_input.connect(_on_SY_btn_clicked)
	# 下一页按钮
	XY_btn = _chuang_jian_btn(parent, XY_png0, qi_wei + Vector2(btn_size.x + jian_ge, 0), btn_size)
	XY_btn.mouse_entered.connect(_on_XY_btn_mouse_entered)
	XY_btn.mouse_exited.connect(_on_XY_btn_mouse_exited)
	XY_btn.gui_input.connect(_on_XY_btn_clicked)
	# 初始刷新一次按钮状态
	ye_btn_upd()

# 创建一个翻页按钮节点
func _chuang_jian_btn(parent: Control, png: Texture2D, wei: Vector2, da_xiao: Vector2) -> TextureRect:
	var btn = TextureRect.new()
	btn.texture = png
	btn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	btn.size = da_xiao
	btn.position = wei
	parent.add_child(btn)
	return btn

# 设置物品总数（显示前调用）
# 总数变化导致当前页不存在时（例如最后一页物品被用完），自动删掉该页并回到新的最后一页
func she_zhi(zong_shu_1: int) -> void:
	zong_shu = max(0, zong_shu_1)
	var zui_da_ye = zong_ye() - 1
	if ye > zui_da_ye:
		ye = zui_da_ye
	if ye < 0:
		ye = 0
	ye_btn_upd()

# 获取总页数（没有物品时为0页）
func zong_ye() -> int:
	return int(ceil(zong_shu / float(mei_ye)))

# 获取本页第一个物品的序号
func qi_shi() -> int:
	return ye * mei_ye

# 重置到第一页（界面每次打开时调用）
func chong_zhi() -> void:
	ye = 0
	SY_xuan_fu = false
	XY_xuan_fu = false
	ye_btn_upd()

# 上一页是否可用
func SY_ke_yong() -> bool:
	return ye > 0

# 下一页是否可用
func XY_ke_yong() -> bool:
	return ye < zong_ye() - 1

# 刷新翻页按钮贴图（只有一页时两个都无效；前页有效/后页无效等按实际情况判断）
func ye_btn_upd() -> void:
	if SY_btn == null or XY_btn == null:
		return
	# 无效时保持普通图，且不响应悬停
	SY_btn.texture = SY_png1 if (SY_ke_yong() and SY_xuan_fu) else SY_png0
	XY_btn.texture = XY_png1 if (XY_ke_yong() and XY_xuan_fu) else XY_png0

# 上一页按钮鼠标悬停
func _on_SY_btn_mouse_entered() -> void:
	SY_xuan_fu = true
	ye_btn_upd()

# 上一页按钮鼠标移出
func _on_SY_btn_mouse_exited() -> void:
	SY_xuan_fu = false
	ye_btn_upd()

# 下一页按钮鼠标悬停
func _on_XY_btn_mouse_entered() -> void:
	XY_xuan_fu = true
	ye_btn_upd()

# 下一页按钮鼠标移出
func _on_XY_btn_mouse_exited() -> void:
	XY_xuan_fu = false
	ye_btn_upd()

# 上一页按钮点击（无效时无反应）
func _on_SY_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not SY_ke_yong():
			return
		ye -= 1
		_fan_ye_le()

# 下一页按钮点击（无效时无反应）
func _on_XY_btn_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not XY_ke_yong():
			return
		ye += 1
		_fan_ye_le()

# 翻页后的统一处理：刷新按钮并通知使用方重新显示
func _fan_ye_le() -> void:
	ye_btn_upd()
	if bian_hua_hui_diao.is_valid():
		bian_hua_hui_diao.call()
