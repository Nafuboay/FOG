extends Button
# 返回信号，点击时发出
signal fan_hui
# 目标场景路径，填写后点击按钮会切换到该场景
@export var tscn: String = ""
# 自定义函数，点击时额外执行的逻辑
@export var DIY: Callable = Callable()
# 进入主城时是否自动进入迷雾状态
@export var auto_mi_wu: bool = false
var fan_hui_normal: Texture2D
var fan_hui_hover: Texture2D

func _ready() -> void:
	# 加载返回按钮图片
	fan_hui_normal = load("res://主界面/图片/返回0.png")
	fan_hui_hover = load("res://主界面/图片/返回1.png")
	# 获取视口宽度，设置按钮位置在右上角（逻辑分辨率）
	var viewport_size = get_viewport_rect().size
	position = Vector2(viewport_size.x-96,32)
	# 设置按钮大小
	custom_minimum_size = Vector2(64, 64)
	# 设置层级
	z_index = 1000
	# 设置按钮样式
	var fan_hui_0 = StyleBoxTexture.new()
	fan_hui_0.texture = fan_hui_normal
	var fan_hui_1 = StyleBoxTexture.new()
	fan_hui_1.texture = fan_hui_hover
	add_theme_stylebox_override("normal", fan_hui_0)
	add_theme_stylebox_override("hover", fan_hui_1)
	add_theme_stylebox_override("pressed", fan_hui_1)
	# 连接点击信号
	pressed.connect(on_fan_hui)

# 点击返回按钮时的处理函数
func on_fan_hui() -> void:
	# 发出返回信号
	fan_hui.emit()
	# 执行自定义函数（如果有）
	if DIY.is_valid():
		DIY.call()
	# 切换到目标场景（如果有）
	if tscn != "":
		get_tree().change_scene_to_file(tscn)
