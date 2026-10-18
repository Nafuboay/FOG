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
# 玄戈是否处于锁定状态（历史成就《不朽者》未完成时为true）
var xuan_ge_suo: bool = false
# 秤干戚是否处于锁定状态（历史成就《救世主》未完成时为true）
var cheng_gan_qi_suo: bool = false
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
			an_nius[i].text = "   %d\n\n\n\n    Lv.%d" % [i + 1, lv]
			shan_chus[i].visible = true
			# 显示待机动画（英雄名无效时跳过，避免加载失败）
			var ming_zi = data.get("英雄", "")
			var dong_hua = load("res://角色/人物/" + ming_zi + "/" + ming_zi + "动画.tres")
			if dong_hua != null:
				json_idles[i].sprite_frames = dong_hua
				json_idles[i].visible = true
				json_idles[i].play("idle")
				json_idles[i].speed_scale = 0.4
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
		# 检查任务字段
		if not data.has("任务"):
			data["任务"] = 1
		# 检查强化字段（按第1~4件装备位的等级数组；旧字典格式存档直接重置）
		if not data.has("强化") or not data["强化"] is Array:
			data["强化"] = [0, 0, 0, 0]
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
		# 切换场景前先恢复总线音量：主城背景音乐在场景实例化时即autoplay，
		# 若等音量调节节点_ready再设置，音乐会先以默认0dB响一瞬后才变成设置值
		var yue_liang_bus = AudioServer.get_bus_index("Master")
		# 音量设置存在通用存档里，所有档共用
		var ty_data = json.du_qu_ty()
		if int(ty_data.get("静音", 0)) == 1:
			# 静音状态直接压到-80dB，与音量调节.gd的静音处理一致
			AudioServer.set_bus_volume_db(yue_liang_bus, -80)
		else:
			AudioServer.set_bus_volume_db(yue_liang_bus, clampi(int(ty_data.get("分贝", 0)), -80, 0))
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
		helo_xuan_ze.visible = true
		# 显示前刷新玄戈与秤干戚的解锁/锁定状态
		upd_xuan_ge_suo()
		upd_cheng_gan_qi_suo()

# 刷新玄戈的解锁状态：历史成就《不朽者》（索引0）未完成时锁定
func upd_xuan_ge_suo() -> void:
	# 任意存档领取过《不朽者》即解锁（通用存档历史成就，跨存档永久保留）
	xuan_ge_suo = not json.has_ach_ty(0)
	if xuan_ge_suo:
		# 锁定：按钮与待机动画一起暗淡
		xuan_ge.modulate = Color(0.5, 0.5, 0.5, 1)
		xuan_ge_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		# 已解锁：恢复正常亮度
		xuan_ge.modulate = Color(1, 1, 1, 1)
		xuan_ge_idle.modulate = Color(1, 1, 1, 1)
# 刷新秤干戚的解锁状态：历史成就《救世主》（索引1）未完成时锁定
func upd_cheng_gan_qi_suo() -> void:
	cheng_gan_qi_suo = not json.has_ach_ty(1)
	if cheng_gan_qi_suo:
		cheng_gan_qi.modulate = Color(0.5, 0.5, 0.5, 1)
		cheng_gan_qi_idle.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		cheng_gan_qi.modulate = Color(1, 1, 1, 1)
		cheng_gan_qi_idle.modulate = Color(1, 1, 1, 1)

# 点击爱丽丝
func _on_爱丽丝按钮_input() -> void:
	C_json("爱丽丝")
# 点击玄戈
func _on_玄戈按钮_input() -> void:
	# 锁定状态下拦截选择，提示解锁条件，不创建存档
	if xuan_ge_suo:
		提示弹幕.wen_ben("完成成就《不朽者》解锁英雄【玄戈】！", 0)
		return
	C_json("玄戈")
# 点击秤干戚
func _on_秤干戚按钮_input() -> void:
	if cheng_gan_qi_suo:
		提示弹幕.wen_ben("完成成就《救世主》解锁英雄【秤干戚】！", 0)
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
		"强化": [0, 0, 0, 0],
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
