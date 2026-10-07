class_name PC输入 extends Node
# 父节点引用（关卡节点）
var guan_qia: Node
# 当前移动的目标网格位置（用于动态更新）
var target_grid_x: int = -1
var target_grid_y: int = -1
# 当前正在进行的tween动画
var current_tween: Tween = null

# 获取父节点引用并启用输入处理
func _ready() -> void:
	var parent = get_parent()
	# 父节点不是关卡基类时向上查找（兼容诛邪等子类场景）
	if not (parent is 关卡基类):
		parent = parent.get_parent()
	guan_qia = parent
	set_process_input(true)
	# 添加到缩放变化监听组
	add_to_group("suo_fang_group")

# 根据输入类型分发到不同的处理逻辑
func _input(event: InputEvent) -> void:
	# 获取战斗系统和UI的引用
	var zhan_dou = guan_qia.zhan_dou
	var guan_ui = guan_qia.guan_ui
	# C键打开/关闭背包（不受背包打开状态限制）
	if event is InputEventKey and event.pressed and event.keycode == KEY_C:
		if guan_ui.BB != null:
			guan_ui.BB.btn_BB()
		return
	# 检查背包是否打开，如果打开则禁止其他操作
	if guan_ui.BB != null and guan_ui.BB.BB_on:
		return
	# 检查音量面板是否打开，如果打开则禁止其他操作
	if guan_ui.YL != null and guan_ui.YL.is_VOL:
		return
	# 获取战斗状态标志
	var zhan_dou_ing = zhan_dou.zhan_dou_ing
	var che_tui_ing = zhan_dou.che_tui_ing
	var zhan_bai = zhan_dou.zhan_bai
	# 战斗中的F键撤退
	if zhan_dou_ing and not che_tui_ing:
		if event is InputEventKey and event.pressed and event.keycode == KEY_F:
			guan_ui.on_che_tui()
	# 战斗中和战败时禁止其他操作
	if zhan_dou_ing or zhan_bai:
		return
	# 检查鼠标是否点击在GUI控件上
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_xy = guan_qia.get_global_mouse_position()
		for child in guan_qia.get_children():
			if GUI(child, mouse_xy):
				return
	# 键盘按键处理
	if event is InputEventKey:
		if event.pressed:
			# A键向左移动人物
			if event.keycode == KEY_A:
				WSAD(guan_qia.helo_x-2,guan_qia.helo_y-1)
			# D键向右移动人物
			elif event.keycode == KEY_D:
				WSAD(guan_qia.helo_x,guan_qia.helo_y-1)
			# W键向上移动人物
			elif event.keycode == KEY_W:
				WSAD(guan_qia.helo_x-1,guan_qia.helo_y-2)
			# S键向下移动人物
			elif event.keycode == KEY_S:
				WSAD(guan_qia.helo_x-1,guan_qia.helo_y)
	# 鼠标操作统一处理
	if event is InputEventMouseButton:
		# 滚轮向上放大
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			guan_ui.suo_fang_upd(true)
		# 滚轮向下缩小
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			guan_ui.suo_fang_upd(false)
	# 鼠标拖拽游戏容器
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_xy = guan_qia.get_local_mouse_position()
			var GZ_xy = win_xy_GZ(mouse_xy)
			# 只有点击在网格外才允许拖拽
			if GZ_xy.x < 0 or GZ_xy.y < 0:
				if event.pressed:
					# 如果画面正在移动，停止移动
					if current_tween != null and current_tween.is_valid():
						current_tween.kill()
						current_tween = null
						target_grid_x = -1
						target_grid_y = -1
					guan_qia.tuo_dong = event.position
				else:
					guan_qia.tuo_dong = Vector2(-1, -1)
	# 鼠标拖拽移动容器
	if event is InputEventMouseMotion and guan_qia.tuo_dong.x >= 0:
		guan_qia.rong_qi.position += event.position - guan_qia.tuo_dong
		guan_qia.tuo_dong = event.position
	# 鼠标点击格子处理
	if event is InputEventMouseButton:
		var mouse_xy = guan_qia.get_local_mouse_position()
		var GZ_xy = win_xy_GZ(mouse_xy)
		# 鼠标左键点击：翻开格子或触发战斗
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			LMB_1(int(GZ_xy.x), int(GZ_xy.y))
		# 鼠标右键点击：标记/取消标记/查看怪物信息
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var click_x = int(GZ_xy.x)
			var click_y = int(GZ_xy.y)
			RMB(click_x, click_y)

# 递归检查是否点击了任何GUI控件（包括嵌套控件）
func GUI(node: Node, mouse_xy: Vector2) -> bool:
	if node is Control and node.visible:
		# 检查当前节点是否被点击
		if node.get_global_rect().has_point(mouse_xy):
			return true
		# 递归检查所有子节点
		for child in node.get_children():
			if GUI(child, mouse_xy):
				return true
	return false

# 左键大部分功能
func LMB_1(dian_x: int, dian_y: int) -> void:
	var zhan_dou = guan_qia.zhan_dou
	# 检查格子是否有效
	if not you_xiao_GZ(dian_x, dian_y):
		return
	# 获取格子数据
	var GZ1 = guan_qia.GZ[dian_y][dian_x]
	# 已标记的格子不能翻开
	if GZ1["biao_ji"] == true:
		return
	# 点击到宝箱：移动到附近可站位置并开启宝箱
	if GZ1.get("BX", false) == true:
		# 计算移动目标位置（按单格怪物的位置顺序查找）
		var mu_biao = move_xy(dian_x, dian_y, true, false, false)
		helo_move(int(mu_biao.x), int(mu_biao.y))
		# 开启宝箱逻辑
		kai_qi_BX(dian_x, dian_y)
		return
	# 点击到NPC：移动到位置(1,2)并恢复血量
	if GZ1["NPC"] == true:
		# 人物移动
		helo_move(0, 1)
		# 检查人物是否满血
		if guan_qia.helo_hp < guan_qia.helo_shp:
			# 计算回满所需的血量
			var hp1 = guan_qia.helo_shp - guan_qia.helo_hp
			# 获取NPC剩余可恢复量
			var hp2 = GZ1["NPC_hp"]
			# 实际恢复量取两者中较小的值
			var hp3 = min(hp1, hp2)
			# 恢复人物血量
			zhan_dou.hui_fu(0, 0, hp3, true)
			# 显示治愈弹幕
			提示弹幕.wen_ben("花精灵·沙华：“治愈术！”", 0)
			# 刷新信息面板
			guan_qia.XX.look_helo_upd()
			# 更新NPC剩余可恢复量
			GZ1["NPC_hp"] = hp2 - hp3
			# 如果恢复量已用完，NPC消失
			if GZ1["NPC_hp"] <= 0:
				guan_qia.NPC_xiao_shi(dian_x, dian_y)
		else:
			# 满血时显示提示弹幕
			提示弹幕.wen_ben("花精灵·沙华：“我可以为你疗伤。”", 0)
		return
	# 如果点击的是已翻开的怪物格，触发战斗
	if GZ1["fan_kai"] == true and (GZ1["guai_wu"] == true or GZ1["BOSS"] == true):
		# 计算移动目标位置（移动到怪物附近的已翻开格）
		var mu_biao = move_xy(dian_x, dian_y, true, false, false)
		helo_move(int(mu_biao.x), int(mu_biao.y))
		zhan_dou.zhan_dou(dian_x, dian_y)
	else:
		# 翻开前记录格子状态
		var yi_kai = guan_qia.GZ[dian_y][dian_x]["fan_kai"] == true
		var GZ_shu_zi = guan_qia.GZ[dian_y][dian_x]["shu_zi"]
		var GZ_kong_bai = guan_qia.GZ[dian_y][dian_x]["kong_bai"]
		# 翻开格子（玩家直接点击视为踩雷）
		guan_qia.fan_kai.kai_ge_zi(dian_x, dian_y, true)
		# 计算移动目标位置
		var mu_biao = move_xy(dian_x, dian_y, yi_kai, GZ_shu_zi, GZ_kong_bai)
		# 移动人物到目标位置
		helo_move(int(mu_biao.x), int(mu_biao.y))
		# 翻开后的格子如果是怪物格，触发战斗
		if guan_qia.GZ[dian_y][dian_x]["guai_wu"] == true:
			zhan_dou.zhan_dou(dian_x, dian_y)

# 右键：标记/解除标记/查看
func RMB(x: int, y: int) -> void:
	# 检查是否点击到人物
	if x == guan_qia.helo_x - 1 and y == guan_qia.helo_y - 1:
		# 切换人物面板显示状态
		guan_qia.look_helo.visible = not guan_qia.look_helo.visible
		guan_qia.kuai_1.visible = guan_qia.look_helo.visible
		if guan_qia.look_helo.visible:
			guan_qia.XX.look_helo_upd()
		return
	# 检查坐标是否在网格范围内
	if x < 0 or x >= guan_qia.GZ_x or y < 0 or y >= guan_qia.GZ_y:
		return
	# 获取格子数据
	var GZ1 = guan_qia.GZ[y][x]
	# 点击到已翻开的怪物或BOSS
	if GZ1["fan_kai"] == true and (GZ1["guai_wu"] == true or GZ1["BOSS"] == true):
		# 如果是BOSS，找到BOSS主格位置
		var look_x = x
		var look_y = y
		if GZ1["BOSS"] == true:
			for boss_xy in guan_qia.BOSS_xy:
				var bx = int(boss_xy.x)
				var by = int(boss_xy.y)
				if x >= bx and x < bx + 2 and y >= by and y < by + 2:
					look_x = bx
					look_y = by
					break
		# 如果怪物面板已显示同一只怪物，则关闭
		if guan_qia.look_guai_wu != null and guan_qia.guai_wu_x_ing == look_x and guan_qia.guai_wu_y_ing == look_y:
			guan_qia.look_guai_wu.queue_free()
			guan_qia.look_guai_wu = null
			if guan_qia.kuai_2 != null:
				guan_qia.kuai_2.queue_free()
				guan_qia.kuai_2 = null
			guan_qia.guai_wu_x_ing = -1
			guan_qia.guai_wu_y_ing = -1
		else:
			guan_qia.XX.look(false, look_x, look_y, x, y)
	# 点击到NPC：显示NPC信息面板
	elif GZ1["NPC"] == true:
		# 如果NPC面板已显示同一个NPC，则关闭
		if guan_qia.look_guai_wu != null and guan_qia.guai_wu_x_ing == x and guan_qia.guai_wu_y_ing == y:
			guan_qia.look_guai_wu.queue_free()
			guan_qia.look_guai_wu = null
			if guan_qia.kuai_2 != null:
				guan_qia.kuai_2.queue_free()
				guan_qia.kuai_2 = null
			guan_qia.guai_wu_x_ing = -1
			guan_qia.guai_wu_y_ing = -1
		else:
			guan_qia.XX.look(false, x, y)
	# 点击到已翻开的障碍：显示障碍信息面板
	elif GZ1["fan_kai"] == true and GZ1.get("zhang_ai", false) == true:
		# 如果障碍面板已显示同一个障碍，则关闭
		if guan_qia.look_guai_wu != null and guan_qia.guai_wu_x_ing == x and guan_qia.guai_wu_y_ing == y:
			guan_qia.look_guai_wu.queue_free()
			guan_qia.look_guai_wu = null
			if guan_qia.kuai_2 != null:
				guan_qia.kuai_2.queue_free()
				guan_qia.kuai_2 = null
			guan_qia.guai_wu_x_ing = -1
			guan_qia.guai_wu_y_ing = -1
		else:
			guan_qia.XX.look(false, x, y)
	# 未翻开的格子：切换标记状态
	elif GZ1["fan_kai"] == false:
		if GZ1["biao_ji"] == true:
			# 取消标记
			GZ1["biao_ji"] = false
			# 障碍格子使用紫地版本的未翻开图片
			guan_qia.GZs[y][x].texture = guan_qia.tile_wei_fan_kai_zi if GZ1.get("zhang_ai", false) else guan_qia.tile_wei_fan_kai
		else:
			# 添加标记
			GZ1["biao_ji"] = true
			# 障碍格子使用紫地版本的标记图片
			guan_qia.GZs[y][x].texture = guan_qia.tile_biao_ji_zi if GZ1.get("zhang_ai", false) else guan_qia.tile_biao_ji
	# 调试信息
	var guai_wu_str = "BOSS" if GZ1.get("BOSS", false) else ("怪物" if GZ1["guai_wu"] else ("障碍" if GZ1.get("zhang_ai",false) else "空地"))
	var yi_kai_str = "已翻开" if GZ1["fan_kai"] else "未翻开"
	var biao_ji_str = "已标记" if GZ1["biao_ji"] else "未标记"
	print("(%d,%d) %s %s %s" % [x+1, y+1, yi_kai_str, biao_ji_str, guai_wu_str])

# 坐标转换：将屏幕坐标转换为网格坐标
func win_xy_GZ(xy: Vector2) -> Vector2:
	# 容器缩放比例
	var rong_qi_suo_fang = guan_qia.rong_qi.scale.x
	# 容器在屏幕中心，先减去容器位置，再除以缩放
	var rong_qi_xy = (xy - guan_qia.rong_qi.position) / rong_qi_suo_fang
	# 根据偏移量和格子大小计算网格索引
	var x = int(floor((rong_qi_xy.x - guan_qia.WG_pian_yi_x) / guan_qia.GZ_size))
	var y = int(floor((rong_qi_xy.y - guan_qia.WG_pian_yi_y) / guan_qia.GZ_size))
	# 返回有效的网格坐标
	if x >= 0 and x < guan_qia.GZ_x and y >= 0 and y < guan_qia.GZ_y:
		return Vector2(x, y)
	return Vector2(-1, -1)

# 检查坐标是否在有效网格范围内
func you_xiao_GZ(x: int, y: int) -> bool:
	# 检查是否在网格范围内
	if x < 0 or x >= guan_qia.GZ_x or y < 0 or y >= guan_qia.GZ_y:
		return false
	var GZ1 = guan_qia.GZ[y][x]
	# 已翻开可直接点击
	if GZ1["fan_kai"] == true:
		return true
	# 未翻开的格子，检查九宫格是否有数字或空白的已翻开格
	if GZ1["fan_kai"] == false:
		for ny in range(max(0, y - 1), min(guan_qia.GZ_y, y + 2)):
			for nx in range(max(0, x - 1), min(guan_qia.GZ_x, x + 2)):
				if nx == x and ny == y:
					continue
				var GZ2 = guan_qia.GZ[ny][nx]
				# 检查是否是已翻开且是数字或空白
				if GZ2["fan_kai"] == true and (GZ2["shu_zi"] == true or GZ2["kong_bai"] == true):
					return true
	return false

# 计算移动目标位置
func move_xy(x: int, y: int, GZ_fan_kai: bool, GZ_shu_zi: bool, GZ_kong_bai: bool) -> Vector2:
	# 边界检查
	if x < 0 or x >= guan_qia.GZ_x or y < 0 or y >= guan_qia.GZ_y:
		return Vector2(-1, -1)
	# 如果是BOSS，使用BOSS专用移动计算
	if guan_qia.GZ[y][x].get("BOSS", false) == true:
		return guan_qia.zhan_dou.move_xy_BOSS(x, y)
	# 调用战斗系统的移动计算
	return guan_qia.zhan_dou.move_xy(x, y, GZ_fan_kai, GZ_shu_zi, GZ_kong_bai)

# 键盘上下左右移动人物
func WSAD(dian_x: int, dian_y: int) -> void:
	if not you_xiao_GZ(dian_x, dian_y):
		return
	LMB_1(dian_x, dian_y)

# 人物移动
func helo_move(x: int, y: int) -> void:
	if guan_qia.helo == null:
		return
	# 记录目标网格位置（用于缩放变化时重新计算）
	target_grid_x = x
	target_grid_y = y
	# 更新人物位置记录
	guan_qia.helo_x = x + 1
	guan_qia.helo_y = y + 1
	# 计算格子中心位置
	var GZ_z = guan_qia.GZ_zhong(x, y)
	# 人物偏移
	guan_qia.helo.position = Vector2(GZ_z.x + guan_qia.role_pian_yi_x, GZ_z.y - guan_qia.role_pian_yi_y)
	# 血条位置（血条显示逻辑在血条飘字.gd）
	if guan_qia.zhan_dou.xue_tiao_qi != null and guan_qia.zhan_dou.xue_tiao_qi.xue_tiao_0 != null:
		guan_qia.zhan_dou.xue_tiao_qi.xue_tiao_0.position = Vector2(GZ_z.x - guan_qia.zhan_dou.xue_tiao_qi.xue_tiao_0.size.x / 2, GZ_z.y - 74)
		guan_qia.zhan_dou.xue_tiao_qi.xue_tiao_0.z_index = (guan_qia.GZ_x - x) + y * guan_qia.GZ_y
	# 人物层级
	guan_qia.helo.z_index = (guan_qia.GZ_x - x) + y * guan_qia.GZ_y
	# 重新播放待机动画
	if guan_qia.helo.has_method("play_idle"):
		guan_qia.helo.play_idle(true)
	# 更新人物面板
	if guan_qia.look_helo != null and guan_qia.look_helo.visible:
		guan_qia.kuai_1.visible = true
		guan_qia.XX.look_helo_upd()
	# 容器跟随人物移动，保持人物在屏幕中心
	rong_qi_move_to_center(GZ_z)

# 容器移动到人物居中位置
func rong_qi_move_to_center(GZ_z: Vector2) -> void:
	var suo_fang = guan_qia.rong_qi.scale.x
	# 使用视口大小
	var viewport_size = guan_qia.get_viewport_rect().size
	var mu_biao = viewport_size / 2 - GZ_z * suo_fang
	# 计算移动距离和时间
	var distance = guan_qia.rong_qi.position.distance_to(mu_biao)
	var speed = 60.0 * suo_fang  # 每秒移速
	var duration = distance / speed
	# 画面移动时间上限4.8秒
	if duration > 4.8:
		duration = 4.8
	# 如果正在移动，先停止当前动画
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	# 创建新的动画
	current_tween = guan_qia.create_tween()
	current_tween.tween_property(guan_qia.rong_qi, "position", mu_biao, duration).set_trans(Tween.TRANS_SINE)
	# 动画完成后重置目标位置
	current_tween.finished.connect(func():
		target_grid_x = -1
		target_grid_y = -1
		current_tween = null
	)

# 缩放变化时重新计算居中位置
func on_suo_fang_changed() -> void:
	if target_grid_x >= 0 and guan_qia.helo != null:
		# 根据目标位置重新计算格子中心
		var GZ_z = guan_qia.GZ_zhong(target_grid_x, target_grid_y)
		rong_qi_move_to_center(GZ_z)

# 缩放处理
func suo_fang_ing() -> float:
	return guan_qia.rong_qi.scale.x

# 容器居中
func rong_qi_ju_zhong() -> void:
	var mu_biao = guan_qia.get_viewport_rect().size / 2
	var tween = guan_qia.create_tween()
	tween.tween_property(guan_qia.rong_qi, "position", mu_biao, 1).set_trans(Tween.TRANS_SINE)

# 开启宝箱
func kai_qi_BX(x: int, y: int) -> void:
	var GZ1 = guan_qia.GZ[y][x]
	# 检查宝箱是否存在
	if not GZ1.get("BX", false):
		return
	# 获取宝箱名称
	var BX_id = GZ1.get("BX_id", "")
	# 获取开启次数
	var kao_ci = GZ1.get("BX_n", 0)
	# 判断是否是首次开启
	var is_first = kao_ci == 0
	# 如果不是首次开启，需要消耗钥匙
	if not is_first:
		# 检查是否有钥匙
		if not 掉落物.you_yao_shi(guan_qia):
			提示弹幕.wen_ben("需要钥匙才能继续开启宝箱！", 0)
			return
		# 消耗钥匙
		if not 掉落物.add_yao_shi(guan_qia):
			提示弹幕.wen_ben("你遇上BUG了，快去通知作者！", 0)
			return
	# 计算掉落物品
	var diao_luo_ing = 掉落物.diao_luo_wu_2(guan_qia, BX_id, is_first)
	# 在背包中显示掉落的物品
	guan_qia.get_node("背包").xian_shi_wu_pin(guan_qia.BB_ls)
	# 判断是否通关（怪物数量为0），通关后继续游戏时需要保存物品到存档
	if guan_qia.guai_wu_xian == 0 and diao_luo_ing.size() > 0:
		# 获取存档节点
		var json = get_node("/root/游戏存档")
		# 读取当前存档数据
		var data = json.du_qu(guan_qia.json_id)
		# 获取当前存档中的背包物品
		var wu_pin = data.get("背包", {})
		# 遍历这次获得的物品，添加到存档
		for wu_ming in diao_luo_ing:
			wu_pin[wu_ming] = wu_pin.get(wu_ming, 0) + diao_luo_ing[wu_ming]
		# 更新存档中的背包数据
		data["背包"] = wu_pin
		# 保存到文件
		json.bao_cun(guan_qia.json_id, data)
	# 更新开启次数
	GZ1["BX_n"] = kao_ci + 1
	# 显示获得物品弹幕
	if diao_luo_ing.size() > 0:
		for wu_ming in diao_luo_ing:
			var n = diao_luo_ing[wu_ming]
			# 根据开启次数显示不同提示
			var ti_shi = ""
			if kao_ci == 0:
				ti_shi = "免费开启获得【" + wu_ming + "】×" + str(n) + "！"
			else:
				ti_shi = "第" + str(kao_ci) + "次消耗钥匙获得【" + wu_ming + "】×" + str(n) + "！"
			提示弹幕.wen_ben(ti_shi, 0)
	else:
		提示弹幕.wen_ben("不够好运，没能获得金条！", 0)
