class_name 提示弹幕 extends Control
static var instance: 提示弹幕
# 存储当前显示的所有提示
var ti_shi: Array[Label] = []
# 缓存的楷体字体
static var _kai_ti_font: FontFile = null
# 上一条弹幕显示的时间（用于控制弹幕间隔）
var time_1: float = 0.0
# 当前弹幕间隔时间
var time_t: float = 0.5
# 弹幕字芯颜色
const ZI_XIN_YAN_SE = Color(0, 0, 0)
# 内环颜色
const NEI_HUAN_YAN_SE = Color(0, 0, 0)
# 外环颜色
const WAI_HUAN_YAN_SE = Color(1, 1, 0.8, 0.8)

# 显示文本内容（delay为延迟出现时间，单位秒）
# 内部自动对文本进行国际化翻译，调用方传入中文原文即可
static func wen_ben(s: String, delay: float = 0.0) -> void:
	if instance != null:
		instance.dan_mu(s, delay)

# 节点就绪时执行的初始化
func _ready() -> void:
	visible = false
	instance = self

# 实际创建和显示提示弹幕（extra_delay为用户指定的延迟出现时间）
func dan_mu(s: String, extra_delay: float = 0.0) -> void:
	s = tr(s)
	visible = true
	# 计算需要延迟的时间
	var now = Time.get_ticks_msec() / 1000.0  # 转换为秒
	var actual_appear_time = now + extra_delay  # 这条弹幕的实际出现时间
	var interval_delay = max(0.0, time_t - (actual_appear_time - time_1))
	var delay = max(interval_delay, extra_delay)  # 取较大值
	# 更新上一条弹幕显示时间（记录的是实际出现时间）
	time_1 = now + delay
	# 根据是否有间隔延迟设置字体大小和下次间隔
	var font_size = 32
	if interval_delay > 0.0:
		font_size = 16
		time_t = 0.25  # 弹幕多时，下次间隔缩短
	else:
		time_t = 0.5   # 弹幕正常，下次间隔恢复
	# 如果有延迟，使用定时器延迟创建弹幕
	if delay > 0.0:
		var timer = get_tree().create_timer(delay)
		timer.timeout.connect(func():
			C_dan_mu(s, font_size)
		)
	else:
		# 无延迟，直接创建弹幕
		C_dan_mu(s, font_size)

# 创建弹幕节点并播放动画
func C_dan_mu(s: String, font_size: int) -> void:
	# 描边宽度随字号变化，小字收窄避免糊成一团
	var nei_kuan = 2 if font_size >= 32 else 1
	var wai_kuan = nei_kuan
	var label = _zhi_zuo_label(s, font_size, WAI_HUAN_YAN_SE, WAI_HUAN_YAN_SE, nei_kuan + wai_kuan)
	var zi_label = _zhi_zuo_label(s, font_size, ZI_XIN_YAN_SE, NEI_HUAN_YAN_SE, nei_kuan)
	label.add_child(zi_label)
	zi_label.position = Vector2(wai_kuan, wai_kuan)
	# 设置z_index确保弹幕显示在最上层
	label.z_index = 2000
	# 将Label添加到管理数组中
	ti_shi.append(label)
	# 获取视口尺寸（逻辑分辨率）
	var viewport_size = get_viewport_rect().size
	# 先将Label添加到当前节点，这样尺寸才能正确计算
	add_child(label)
	# 获取Label的实际尺寸用于计算位置
	var label_size = label.size
	# 计算Label位置，使其在屏幕水平居中、垂直居中
	label.position = Vector2((viewport_size.x - label_size.x) / 2.0, viewport_size.y / 2.0)
	# 记录动画起始Y坐标
	var start_y = label.position.y
	# 创建tween动画
	var tween = create_tween()
	# 弹幕向上移动
	tween.tween_property(label, "position:y", start_y - 300, 5.0)
	# 弹幕淡出
	tween.parallel().tween_property(label, "modulate:a", 0.0, 5.0)
	# 动画完成后执行清理回调
	tween.tween_callback(_wan_cheng.bind(label))

# 创建一层弹幕文字，描边宽度决定这一层向外扩出的轮廓
func _zhi_zuo_label(s: String, font_size: int, zi_se: Color, bian_se: Color, bian_kuan: int) -> Label:
	var label = Label.new()
	label.text = s
	label.add_theme_font_size_override("font_size", font_size)
	# 设置楷体字体
	kai_ti(label)
	# 设置文本水平居中对齐
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# 设置文本垂直居中对齐
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 字芯颜色
	label.add_theme_color_override("font_color", zi_se)
	# 描边颜色
	label.add_theme_color_override("font_outline_color", bian_se)
	# 描边宽度
	label.add_theme_constant_override("outline_size", bian_kuan)
	# 设置鼠标过滤器为忽略，使鼠标事件穿透该Label，不阻挡下方UI交互
	label.mouse_filter = MOUSE_FILTER_IGNORE
	return label

# 获取楷体字体
static func get_kai_ti_font() -> FontFile:
	# 如果缓存中有，直接返回
	if _kai_ti_font != null:
		return _kai_ti_font
	# 获取楷体字体路径
	var font_path = OS.get_system_font_path("KaiTi")
	if font_path and not font_path.is_empty():
		# 读取字体文件
		var file = FileAccess.open(font_path, FileAccess.READ)
		if file != null:
			var font_data = file.get_buffer(file.get_length())
			file.close()
			# 创建FontFile并缓存
			_kai_ti_font = FontFile.new()
			_kai_ti_font.data = font_data
			return _kai_ti_font
	return null

# 设置Label使用楷体字体（加粗）
func kai_ti(label: Label) -> void:
	var font_file = 提示弹幕.get_kai_ti_font()
	if font_file != null:
		# 设置字体为楷体
		label.add_theme_font_override("font", font_file)

# 动画完成后的清理回调
# 参数：label - 需要清理的Label节点
func _wan_cheng(label: Label) -> void:
	# 从管理数组中移除
	ti_shi.erase(label)
	# 标记节点等待自动释放
	label.queue_free()
	# 如果所有提示都已消失，则隐藏父节点
	if ti_shi.is_empty():
		visible = false
