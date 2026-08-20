extends Node2D

# 按钮节点引用
@onready var an_niu = $按钮
@onready var bg = $游戏开始0
# 按钮普通状态图片
var an_niu_normal: Texture2D
# 按钮悬停状态图片
var an_niu_hover: Texture2D

# 存档槽位按钮
@onready var an_niu_0 = $存档按钮0
@onready var an_niu_1 = $存档按钮1
@onready var an_niu_2 = $存档按钮2
@onready var an_niu_3 = $存档按钮3
@onready var an_niu_4 = $存档按钮4
@onready var an_niu_5 = $存档按钮5
# 人物选择面板
@onready var helo_xuan_ze = $人物选择面板
@onready var Alice = $人物选择面板/爱丽丝按钮
@onready var xuan_ge = $人物选择面板/玄戈按钮
@onready var Alice_idle = $人物选择面板/爱丽丝待机
@onready var xuan_ge_idle = $人物选择面板/玄戈待机
@onready var fan_hui = $人物选择面板/返回按钮
# 返回按钮图片
var fan_hui_normal: Texture2D
var fan_hui_hover: Texture2D
# 删除按钮
@onready var shan_chu_0 = $删除按钮0
@onready var shan_chu_1 = $删除按钮1
@onready var shan_chu_2 = $删除按钮2
@onready var shan_chu_3 = $删除按钮3
@onready var shan_chu_4 = $删除按钮4
@onready var shan_chu_5 = $删除按钮5
# 存档待机动画
@onready var json_idle_0 = $存档待机0
@onready var json_idle_1 = $存档待机1
@onready var json_idle_2 = $存档待机2
@onready var json_idle_3 = $存档待机3
@onready var json_idle_4 = $存档待机4
@onready var json_idle_5 = $存档待机5
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
# 存档数量
const cao_wei: int = 6

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
	# 默认隐藏存档按钮
	var an_nius_1 = [an_niu_0, an_niu_1, an_niu_2, an_niu_3, an_niu_4, an_niu_5]
	var json_idle = [json_idle_0, json_idle_1, json_idle_2, json_idle_3, json_idle_4, json_idle_5]
	for btn in an_nius_1:
		btn.visible = false
	for s in json_idle:
		s.visible = false
	# 获取窗口大小（提前定义以便在后续代码中使用）
	var size = get_viewport_rect().size
	var win_x = size.x
	var win_y = size.y
	# 计算按钮位置（2行3列布局）
	var hang_shu_1 = 2  # 行数
	var lie_shu_1 = 3   # 列数
	for i in range(cao_wei):
		var m = i % lie_shu_1
		var n = int(i / float(lie_shu_1))
		var x = (2.0 * m + 3.0) / (lie_shu_1 * 2.0 + 4.0) * win_x-64
		var y = (2.0 * n + 3.0) / (hang_shu_1 * 2.0 + 4.0) * win_y-64
		an_nius_1[i].position = Vector2(x, y)
		# 设置存档待机动画位置
		json_idle[i].position = Vector2(x + 47, y + 47)
		var cao_yuan_0 = StyleBoxTexture.new()
		cao_yuan_0.texture = load("res://主界面/图片/模块0.png")
		an_nius_1[i].add_theme_stylebox_override("normal", cao_yuan_0)
		an_nius_1[i].add_theme_stylebox_override("hover", cao_yuan_0)
		an_nius_1[i].add_theme_stylebox_override("pressed", cao_yuan_0)
		an_nius_1[i].add_theme_color_override("font_hover_color", Color.BLACK)
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
		# 将节点添加到根节点下（全局单例）
		get_tree().root.call_deferred("add_child", json)
	else:
		# 已有存档节点，直接获取
		json = get_node("/root/游戏存档")
	# 设置人物选择按钮位置（1行2列布局）
	var an_nius_2 = [Alice, xuan_ge]
	var hang_shu_2 = 1  # 行数
	var lie_shu_2 = 2    # 列数
	var idle = [Alice_idle, xuan_ge_idle]
	for i in range(an_nius_2.size()):
		var m = i % lie_shu_2
		var n = int(i / float(lie_shu_2))
		var x = (2.0 * m + 3.0) / (lie_shu_2 * 2.0 + 4.0) * win_x - 64
		var y = (2.0 * n + 3.0) / (hang_shu_2 * 2.0 + 4.0) * win_y - 64
		an_nius_2[i].position = Vector2(x, y)
		# 设置待机动画位置与按钮相同
		idle[i].position = Vector2(x + 47, y + 47)
		# 加载预定义的待机动画
		var idle_n = load("res://角色/人物/爱丽丝/爱丽丝动画.tres") if i == 0 else load("res://角色/人物/玄戈/玄戈动画.tres")
		idle[i].sprite_frames = idle_n
		idle[i].play("idle")
		idle[i].speed_scale = 0.4
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
	var shan_chus = [shan_chu_0, shan_chu_1, shan_chu_2, shan_chu_3, shan_chu_4, shan_chu_5]
	var hang_shu_3 = 2  # 行数
	var lie_shu_3 = 3    # 列数
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
			an_niu_upd()

# 刷新存档按钮显示状态
func an_niu_upd() -> void:
	var an_nius_1 = [an_niu_0, an_niu_1, an_niu_2, an_niu_3, an_niu_4, an_niu_5]
	var shan_chus = [shan_chu_0, shan_chu_1, shan_chu_2, shan_chu_3, shan_chu_4, shan_chu_5]
	var json_idle = [json_idle_0, json_idle_1, json_idle_2, json_idle_3, json_idle_4, json_idle_5]
	for btn in an_nius_1:
		btn.visible = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	for i in range(cao_wei):
		if json.you_cai_dang(i):
			var data = json.du_qu(i)
			var lv = data.get("等级", 1)
			an_nius_1[i].text = "   %d\n\n\n\n    Lv.%d" % [i + 1, lv]
			shan_chus[i].visible = true
			# 显示待机动画
			var ming_zi = data.get("英雄", "")
			var dong_hua = load("res://角色/人物/爱丽丝/爱丽丝动画.tres") if ming_zi == "爱丽丝" else load("res://角色/人物/玄戈/玄戈动画.tres")
			json_idle[i].sprite_frames = dong_hua
			json_idle[i].visible = true
			json_idle[i].play("idle")
			json_idle[i].speed_scale = 0.4
		else:
			an_nius_1[i].text = "   %d\n\n\n\n\n" % (i + 1)
			# 隐藏删除按钮
			shan_chus[i].visible = false
			# 隐藏待机动画
			json_idle[i].visible = false

# 点击存档槽位0
func _on_存档按钮0_input() -> void:
	dian_ji(0)
# 点击存档槽位1
func _on_存档按钮1_input() -> void:
	dian_ji(1)
# 点击存档槽位2
func _on_存档按钮2_input() -> void:
	dian_ji(2)
# 点击存档槽位3
func _on_存档按钮3_input() -> void:
	dian_ji(3)
# 点击存档槽位4
func _on_存档按钮4_input() -> void:
	dian_ji(4)
# 点击存档槽位5
func _on_存档按钮5_input() -> void:
	dian_ji(5)

func _on_存档按钮0_hover() -> void:
	an_niu_0.modulate = Color(2, 1, 1, 1)
func _on_存档按钮0_exit() -> void:
	an_niu_0.modulate = Color(1, 1, 1, 1)
func _on_存档按钮1_hover() -> void:
	an_niu_1.modulate = Color(2, 2, 1, 1)
func _on_存档按钮1_exit() -> void:
	an_niu_1.modulate = Color(1, 1, 1, 1)
func _on_存档按钮2_hover() -> void:
	an_niu_2.modulate = Color(1, 2, 1, 1)
func _on_存档按钮2_exit() -> void:
	an_niu_2.modulate = Color(1, 1, 1, 1)
func _on_存档按钮3_hover() -> void:
	an_niu_3.modulate = Color(1, 2, 2, 1)
func _on_存档按钮3_exit() -> void:
	an_niu_3.modulate = Color(1, 1, 1, 1)
func _on_存档按钮4_hover() -> void:
	an_niu_4.modulate = Color(1, 1, 2, 1)
func _on_存档按钮4_exit() -> void:
	an_niu_4.modulate = Color(1, 1, 1, 1)
func _on_存档按钮5_hover() -> void:
	an_niu_5.modulate = Color(2, 1, 2, 1)
func _on_存档按钮5_exit() -> void:
	an_niu_5.modulate = Color(1, 1, 1, 1)

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
		# 检查任务字段
		if not data.has("任务"):
			data["任务"] = 1
		# 检查强化字段
		if not data.has("强化"):
			data["强化"] = {"生命":0, "力量":0, "防御":0, "穿透":0}
		# 检查成就字段
		if not data.has("成就"):
			data["成就"] = [0,0,0]
		# 保存
		json.bao_cun(dang_wei, data)
		# 保存当前存档ID到游戏存档节点
		json.id = dang_wei
		# 将游戏存档节点移到root下，使其在切换场景后继续存在
		if json.get_parent() != get_tree().root:
			get_tree().root.add_child(json)
		# 已有存档，进入主城
		get_tree().change_scene_to_file("res://主城/主城.tscn")
	else:
		# 隐藏所有存档按钮和删除按钮
		var an_nius_1 = [an_niu_0, an_niu_1, an_niu_2, an_niu_3, an_niu_4, an_niu_5]
		var shan_chus = [shan_chu_0, shan_chu_1, shan_chu_2, shan_chu_3, shan_chu_4, shan_chu_5]
		var json_idle = [json_idle_0, json_idle_1, json_idle_2, json_idle_3, json_idle_4, json_idle_5]
		for btn in an_nius_1:
			btn.visible = false
		for btn in shan_chus:
			btn.visible = false
		for s in json_idle:
			s.visible = false
		# 隐藏存档返回按钮
		json_fan_hui.visible = false
		helo_xuan_ze.visible = true

# 点击爱丽丝
func _on_爱丽丝按钮_input() -> void:
	C_json("爱丽丝")
# 点击玄戈
func _on_玄戈按钮_input() -> void:
	C_json("玄戈")

# 爱丽丝按钮悬停
func _on_爱丽丝按钮_hover() -> void:
	Alice.modulate = Color(0.5, 1, 2, 1)
# 爱丽丝按钮离开
func _on_爱丽丝按钮_exit() -> void:
	Alice.modulate = Color(1, 1, 1, 1)
# 玄戈按钮悬停
func _on_玄戈按钮_hover() -> void:
	xuan_ge.modulate = Color(2, 1, 0.5, 1)
# 玄戈按钮离开
func _on_玄戈按钮_exit() -> void:
	xuan_ge.modulate = Color(1, 1, 1, 1)

# 选择人物并创建存档
func C_json(helo_name: String) -> void:
	# 拼接人物场景路径
	var helo_path = "res://角色/人物/" + helo_name + "/" + helo_name + ".tscn"
	# 加载人物场景
	var helo_tscn = load(helo_path)
	# 实例化人物节点获取属性
	var helo = helo_tscn.instantiate()
	# 创建初始存档数据
	var data = {
		"英雄": helo.get_name(),
		"等级": 1,
		"经验": 0,
		"银币": 0,
		"进度": 1,
		"任务": 1,
		"强化": {"生命":0, "力量":0, "防御":0, "穿透":0},
		"成就": [0,0,0]
	}
	# 释放临时人物节点
	helo.free()
	# 保存到指定槽位
	json.bao_cun(json_id, data)
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

# 点击删除按钮0
func _on_删除按钮0_input() -> void:
	shan_chu_an_niu(0)
# 点击删除按钮1
func _on_删除按钮1_input() -> void:
	shan_chu_an_niu(1)
# 点击删除按钮2
func _on_删除按钮2_input() -> void:
	shan_chu_an_niu(2)
# 点击删除按钮3
func _on_删除按钮3_input() -> void:
	shan_chu_an_niu(3)
# 点击删除按钮4
func _on_删除按钮4_input() -> void:
	shan_chu_an_niu(4)
# 点击删除按钮5
func _on_删除按钮5_input() -> void:
	shan_chu_an_niu(5)

# 删除按钮点击处理
func shan_chu_an_niu(dang_wei: int) -> void:
	json_id = dang_wei
	# 隐藏存档返回按钮
	json_fan_hui.visible = false
	# 隐藏存档按钮和删除按钮
	var an_nius_1 = [an_niu_0, an_niu_1, an_niu_2, an_niu_3, an_niu_4, an_niu_5]
	var shan_chus = [shan_chu_0, shan_chu_1, shan_chu_2, shan_chu_3, shan_chu_4, shan_chu_5]
	var json_idle = [json_idle_0, json_idle_1, json_idle_2, json_idle_3, json_idle_4, json_idle_5]
	for btn in an_nius_1:
		btn.visible = false
	for btn in shan_chus:
		btn.visible = false
	for s in json_idle:
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
	var an_nius_1 = [an_niu_0, an_niu_1, an_niu_2, an_niu_3, an_niu_4, an_niu_5]
	var shan_chus = [shan_chu_0, shan_chu_1, shan_chu_2, shan_chu_3, shan_chu_4, shan_chu_5]
	var json_idles = [json_idle_0, json_idle_1, json_idle_2, json_idle_3, json_idle_4, json_idle_5]
	for btn in an_nius_1:
		btn.visible = false
	for btn in shan_chus:
		btn.visible = false
	for idle in json_idles:
		idle.visible = false
	# 显示开始游戏按钮
	an_niu.visible = true
