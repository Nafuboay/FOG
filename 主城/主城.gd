# 主城场景
extends Node2D
# 游戏背景节点引用
@onready var xuan_guan = $选关面板
# 选关按钮节点引用
@onready var xuan_guan_btn = $选关按钮
# 主城返回按钮节点引用
@onready var fan_hui_btn = $主城返回按钮
# 返回初始状态按钮节点引用
@onready var chu_shi_btn = $返回初始状态按钮
# 树屋按钮节点引用
@onready var shu_wu_btn = $树屋按钮
# 树屋面板引用
var shu_wu: Control = null
# 背景是否已切换
var mi_wu: bool = false
# 背包引用
var BB: Control = null
# 商店引用
var shop: Control = null
# 强化引用
var QH: Control = null
# 商店NPC节点引用
@onready var npc1: Node2D = $商店NPC
# 强化NPC节点引用
@onready var npc2: Node2D = $强化NPC
# 音量调节引用
var VOL: Control = null

# 场景就绪时执行的初始化函数
func _ready() -> void:
	# 初始隐藏选关按钮
	xuan_guan_btn.modulate = Color(2,2,2,0.1)
	# 鼠标悬停时显示按钮
	xuan_guan_btn.mouse_entered.connect(func(): xuan_guan_btn.modulate = Color(2, 2, 2, 1))
	# 鼠标移出时隐藏按钮
	xuan_guan_btn.mouse_exited.connect(func(): xuan_guan_btn.modulate = Color(2,2,2,0.1))
	# 确保游戏存档节点存在
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		json = load("res://主界面/游戏存档.gd").new()
		json.name = "游戏存档"
		get_tree().root.add_child(json)
	# 读取并设置当前使用的存档槽位
	json.get_stg()
	# 实例化背包系统
	BB = load("res://全局/空间袋.gd").new()
	BB.name = "背包"
	add_child(BB)
	# 设置主城标志（用于显示出售按钮）
	BB.is_zhu_cheng(true)
	# 从存档读取背包物品并显示
	var data = json.du_qu(json.id)
	var wu_pin = data.get("背包", {})
	BB.xian_shi_wu_pin(wu_pin)
	# 实例化商店系统
	shop = load("res://全局/商店.gd").new()
	shop.name = "商店"
	add_child(shop)
	# 设置商店的NPC引用和背包引用
	shop.npc_1(npc1)
	shop.BB_2(BB)
	# 实例化强化系统
	QH = load("res://主城/强化.gd").new()
	QH.name = "强化"
	add_child(QH)
	# 设置强化的NPC引用、背包引用和商店引用
	QH.npc_1(npc2)
	QH.BB_2(BB)
	QH.shop_2(shop)
	# 设置商店对强化的引用
	shop.QH_2(QH)
	# 实例化树屋系统
	shu_wu = load("res://主城/树屋.gd").new()
	shu_wu.name = "树屋"
	add_child(shu_wu)
	# 实例化音量调节系统
	VOL = load("res://音乐/音量调节.gd").new()
	VOL.name = "音量调节"
	add_child(VOL)
	# 初始完全隐藏树屋按钮
	shu_wu_btn.visible = false
	# 鼠标悬停时显示按钮（变亮）
	shu_wu_btn.mouse_entered.connect(func(): shu_wu_btn.modulate = Color(2, 2, 2, 1))
	# 鼠标移出时恢复虚化效果
	shu_wu_btn.mouse_exited.connect(func(): shu_wu_btn.modulate = Color(2,2,2,0.1))

# 输入处理
func _input(_event: InputEvent) -> void:
	# C键打开/关闭背包
	if _event is InputEventKey and _event.pressed and _event.keycode == KEY_C:
		if BB != null and BB.BB_btn.visible:
			BB.btn_BB()
		return
	# 获取当前打开的界面
	var dang_qian_jie_mian = ""
	if BB != null and BB.BB_on:
		dang_qian_jie_mian = "BB"
	elif shop != null and shop.BB_on:
		dang_qian_jie_mian = "shop"
	elif QH != null and QH.QH_on:
		dang_qian_jie_mian = "QH"
	elif shu_wu != null and shu_wu.visible:
		dang_qian_jie_mian = "shu_wu"
	# 根据当前界面状态调整UI
	if dang_qian_jie_mian != "":
		# 有界面打开时，隐藏通用UI
		fan_hui_btn.visible = false
		chu_shi_btn.visible = false
		# 树屋界面不释放焦点，以便树屋按钮能正常接收点击事件
		if dang_qian_jie_mian != "shu_wu":
			get_viewport().gui_release_focus()
		# 隐藏其他两个NPC
		if npc1 != null:
			npc1.visible = (dang_qian_jie_mian == "shop")
		if npc2 != null:
			npc2.visible = (dang_qian_jie_mian == "QH")
		# 隐藏空间袋按钮（除非当前界面就是空间袋）
		if BB != null:
			BB.BB_btn.visible = (dang_qian_jie_mian == "BB")
		# 通知其他界面状态变化
		get_tree().call_group("BB_3", "BB_4", true)
	else:
		# 没有界面打开时，恢复UI
		if mi_wu and not xuan_guan.visible:
			# 迷雾背景且未显示选关面板时，显示NPC和按钮
			npc1.visible = true
			npc2.visible = true
			BB.BB_btn.visible = true
		# 选关面板打开时，强制隐藏NPC和按钮
		if xuan_guan.visible:
			npc1.visible = false
			npc2.visible = false
			BB.BB_btn.visible = false
		# 选关面板没有显示时，恢复对应的返回按钮
		if not xuan_guan.visible:
			if mi_wu:
				# 已经切换到迷雾背景，显示返回初始状态按钮
				chu_shi_btn.visible = true
				fan_hui_btn.visible = false
			else:
				# 初始状态，显示主城返回按钮
				fan_hui_btn.visible = true
				chu_shi_btn.visible = false
		# 通知其他界面状态变化
		get_tree().call_group("BB_3", "BB_4", false)
	# 检测商店NPC点击
	if npc1 != null and npc1.visible:
		if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
			var mouse_pos = get_global_mouse_position()
			var npc_pos = npc1.global_position
			if mouse_pos.x >= npc_pos.x - 30 and mouse_pos.x <= npc_pos.x + 64 and mouse_pos.y >= npc_pos.y - 30 and mouse_pos.y <= npc_pos.y + 64:
				shop.btn_BB()
				return
	# 检测强化NPC点击
	if npc2 != null and npc2.visible:
		if _event is InputEventMouseButton and _event.button_index == MOUSE_BUTTON_LEFT and _event.pressed:
			var mouse_pos = get_global_mouse_position()
			var npc_pos = npc2.global_position
			if mouse_pos.x >= npc_pos.x - 30 and mouse_pos.x <= npc_pos.x + 64 and mouse_pos.y >= npc_pos.y - 30 and mouse_pos.y <= npc_pos.y + 64:
				QH.QH_On1()
				return

# 选关按钮点击事件处理
func _on_选关按钮_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_选关按钮_pressed()

# 选关按钮被按下时的回调函数
func _on_选关按钮_pressed() -> void:
	# 第一次点击：切换背景并显示弹幕
	if not mi_wu:
		mi_wu = true
		var bg = get_node("游戏背景")
		bg.texture = load("res://主城/图片/主城0.png")
		提示弹幕.wen_ben("迷雾来袭，请做好战斗准备！", 0)
		# 显示背包按钮
		BB.BB_1()
		# 隐藏主城返回按钮
		fan_hui_btn.visible = false
		# 显示返回初始状态按钮
		chu_shi_btn.visible = true
		# 显示树屋按钮（虚化效果）
		shu_wu_btn.visible = true
		shu_wu_btn.modulate = Color(2,2,2,0.1)
		# 显示NPC
		shop.on_npc()
		QH.on_npc()
		return
	# 第二次点击：触发功能
	# 显示选关面板
	提示弹幕.wen_ben("已激活浮空岛传送阵，请选择传送关卡。",0.5)
	xuan_guan.xian_shi()
	# 隐藏选关按钮
	xuan_guan_btn.visible = false
	# 隐藏树屋按钮
	shu_wu_btn.visible = false
	# 隐藏返回初始状态按钮
	chu_shi_btn.visible = false
	# 隐藏背包按钮
	BB.BB_0()
	# 先关闭界面（如果打开）
	if shop.BB_on:
		shop.btn_BB()
	if QH != null and QH.QH_on:
		QH.QH_On1()
	# 再隐藏NPC
	shop.off_npc()
	QH.off_npc()

# 选关返回按钮被按下时的回调函数
func _on_选关返回按钮_pressed() -> void:
	# 隐藏选关面板
	xuan_guan.yin_cang()
	# 显示选关按钮
	xuan_guan_btn.visible = true
	# 显示树屋按钮
	shu_wu_btn.visible = true
	# 显示返回初始状态按钮
	chu_shi_btn.visible = true
	# 重新显示背包按钮
	BB.BB_1()
	# 显示NPC
	shop.on_npc()
	QH.on_npc()

# 返回初始状态按钮被按下时的回调函数
func _on_返回初始状态按钮_pressed() -> void:
	# 恢复初始背景
	var bg = get_node("游戏背景")
	bg.texture = load("res://主城/图片/主城1.png")
	# 重置mi_wu
	mi_wu = false
	# 显示主城返回按钮
	fan_hui_btn.visible = true
	# 隐藏返回初始状态按钮
	chu_shi_btn.visible = false
	# 隐藏背包按钮
	BB.BB_0()
	# 隐藏树屋按钮
	shu_wu_btn.visible = false
	# 先关闭界面（如果打开）
	if shop.BB_on:
		shop.btn_BB()
	if QH != null and QH.QH_on:
		QH.QH_On1()
	if shu_wu != null:
		shu_wu.visible = false
	# 隐藏NPC
	shop.off_npc()
	QH.off_npc()

# 树屋按钮点击事件处理
func _on_树屋按钮_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_树屋按钮_pressed()

# 树屋按钮被按下时的回调函数
func _on_树屋按钮_pressed() -> void:
	# 如果树屋界面已打开，关闭它
	if shu_wu != null and shu_wu.visible:
		shu_wu.visible = false
		# 恢复UI显示
		fan_hui_btn.visible = true
		BB.BB_1()
		# 显示选关按钮
		xuan_guan_btn.visible = true
		# 显示NPC（商店和强化）
		shop.on_npc()
		QH.on_npc()
		return
	# 显示树屋面板
	shu_wu.open()
	# 隐藏其他UI
	chu_shi_btn.visible = false
	BB.BB_0()
	# 隐藏选关按钮
	xuan_guan_btn.visible = false
	# 关闭其他界面
	if shop.BB_on:
		shop.btn_BB()
	if QH != null and QH.QH_on:
		QH.QH_On1()
	# 隐藏NPC（商店和强化）
	shop.off_npc()
	QH.off_npc()

# 关卡按钮被按下时进入指定关卡
func _on_关卡按钮0_pressed() -> void:
	jin_ru_guan_kia(0)
func _on_关卡按钮1_pressed() -> void:
	jin_ru_guan_kia(1)
func _on_关卡按钮2_pressed() -> void:
	jin_ru_guan_kia(2)
func _on_关卡按钮3_pressed() -> void:
	jin_ru_guan_kia(3)
func _on_关卡按钮4_pressed() -> void:
	jin_ru_guan_kia(4)
func _on_关卡按钮5_pressed() -> void:
	jin_ru_guan_kia(5)
func _on_关卡按钮6_pressed() -> void:
	jin_ru_guan_kia(6)
func _on_关卡按钮7_pressed() -> void:
	jin_ru_guan_kia(7)
func _on_关卡按钮8_pressed() -> void:
	jin_ru_guan_kia(8)
func _on_关卡按钮9_pressed() -> void:
	jin_ru_guan_kia(9)
func _on_关卡按钮10_pressed() -> void:
	jin_ru_guan_kia(10)
func _on_关卡按钮11_pressed() -> void:
	jin_ru_guan_kia(11)
func _on_关卡按钮12_pressed() -> void:
	jin_ru_guan_kia(12)
func _on_关卡按钮13_pressed() -> void:
	jin_ru_guan_kia(13)
func _on_关卡按钮14_pressed() -> void:
	jin_ru_guan_kia(14)
func _on_关卡按钮15_pressed() -> void:
	jin_ru_guan_kia(15)
func _on_关卡按钮16_pressed() -> void:
	jin_ru_guan_kia(16)
func _on_关卡按钮17_pressed() -> void:
	jin_ru_guan_kia(17)
func _on_关卡按钮18_pressed() -> void:
	jin_ru_guan_kia(18)
func _on_关卡按钮19_pressed() -> void:
	jin_ru_guan_kia(19)
func _on_关卡按钮20_pressed() -> void:
	jin_ru_guan_kia(20)
func _on_关卡按钮21_pressed() -> void:
	jin_ru_guan_kia(21)
func _on_关卡按钮22_pressed() -> void:
	jin_ru_guan_kia(22)
func _on_关卡按钮23_pressed() -> void:
	jin_ru_guan_kia(23)
func _on_关卡按钮24_pressed() -> void:
	jin_ru_guan_kia(24)
func _on_关卡按钮25_pressed() -> void:
	jin_ru_guan_kia(25)
func _on_关卡按钮26_pressed() -> void:
	jin_ru_guan_kia(26)
func _on_关卡按钮27_pressed() -> void:
	jin_ru_guan_kia(27)
func _on_关卡按钮28_pressed() -> void:
	jin_ru_guan_kia(28)
func _on_关卡按钮29_pressed() -> void:
	jin_ru_guan_kia(29)

# 进入指定关卡的函数
func jin_ru_guan_kia(guan_kia_id: int) -> void:
	# 读取存档进度
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		json = load("res://主界面/游戏存档.gd").new()
		json.name = "游戏存档"
		get_tree().root.add_child(json)
	var stg = json.get_stg()
	var guan_num = guan_kia_id + 1
	# 获取当前模式
	var cur_mode = 0
	if has_node("/root/数据管理"):
		cur_mode = get_node("/root/数据管理").mode
	# 诛邪模式下检查关卡
	if cur_mode == 1:
		# 第2关禁用（魔法树关）
		if guan_num == 2:
			提示弹幕.wen_ben("此关卡为魔法树关，不支持诛邪模式！", 1)
			return
		# 诛邪模式：主线n关通过，诛邪最多能打到n-1关
		if guan_num >= stg:
			提示弹幕.wen_ben("请先通关主线第%d关！" % stg, 1)
			return
	else:
		# 主线模式：检查是否已解锁
		if guan_num > stg:
			提示弹幕.wen_ben("请先通关前一关！", 1)
			return
	# 检查并创建存档文件夹
	json.wen_jian_jia()
	# 将关卡ID和模式保存到数据管理节点
	if has_node("/root/数据管理"):
		var dm = get_node("/root/数据管理")
		dm.stg = guan_kia_id
		dm.zx_guan_kia_id = guan_num
	# 切换到关卡场景
	if cur_mode == 1:
		# 诛邪模式使用诛邪场景
		get_tree().change_scene_to_file("res://关卡/诛邪.tscn")
	else:
		# 主线模式使用主线场景
		get_tree().change_scene_to_file("res://关卡/关卡.tscn")
