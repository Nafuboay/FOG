class_name 翻开系统 extends Node
# 父节点引用（关卡节点）
var guan_qia: Node2D

# 获取父节点，如果父节点是容器则继续往上找真正的关卡节点
func _ready() -> void:
	var parent = get_parent()
	if parent.name != "关卡":
		parent = parent.get_parent()
	guan_qia = parent

# 统计九宫格内怪物总数
func guai_wu_n9(x: int, y: int) -> int:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var n = 0
	for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
		for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
			if nx == x and ny == y:
				continue
			if GZ[ny][nx]["guai_wu"] == true:
				n += 1
	return n

# 统计九宫格内未翻开的格子数
func wei_fan_kai_n9(x: int, y: int) -> int:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var n = 0
	for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
		for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
			if nx == x and ny == y:
				continue
			if GZ[ny][nx]["fan_kai"] == false:
				n += 1
	return n

# 统计九宫格内已翻开的怪物数
func fan_kai_guai_wu_n9(x: int, y: int) -> int:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var n = 0
	for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
		for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
			if nx == x and ny == y:
				continue
			var GZ2 = GZ[ny][nx]
			if GZ2["fan_kai"] == true and GZ2["guai_wu"] == true:
				n += 1
	return n

# 统计九宫格内障碍数量（用于怪物防御加成计算）
func zhang_ai_n9(x: int, y: int) -> int:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var n = 0
	for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
		for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
			if nx == x and ny == y:
				continue
			if GZ[ny][nx].get("zhang_ai", false) == true:
				n += 1
	return n

# 递归展开空白格子（洪水填充）
func flood_fill(x: int, y: int) -> void:
	var GZ = guan_qia.GZ
	var GZs = guan_qia.GZs
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var tile_fan_kai = guan_qia.tile_fan_kai
	var tile_shu_zi = guan_qia.tile_shu_zi
	var zhang_ai = guan_qia.zhang_ai
	var zhang_ai_xy = guan_qia.zhang_ai_xy
	# 遍历周围8个格子
	for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
		for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
			# 跳过自身
			if nx == x and ny == y:
				continue
			# 获取周围格子数据
			var GZ2 = GZ[ny][nx]
			# 跳过翻开状态
			if GZ2["fan_kai"] == true:
				continue
			# 设置已翻开
			GZ2["fan_kai"] = true
			GZ2["biao_ji"] = false
			# 根据状态显示
			if GZ2.get("zhang_ai", false) == true:
				# 障碍，翻开整个2x2区域
				for shu in zhang_ai_xy:
					var sx = int(shu.x)
					var sy = int(shu.y)
					if nx >= sx and nx < sx + 2 and ny >= sy and ny < sy + 2:
						# 翻开2x2区域的4个格子
						for tny in range(sy, sy + 2):
							for tnx in range(sx, sx + 2):
								GZ[tny][tnx]["fan_kai"] = true
								GZ[tny][tnx]["biao_ji"] = false
								# 障碍格子使用紫地版本的已翻开图片
								GZs[tny][tnx].texture = guan_qia.tile_fan_kai_zi if guan_qia.tile_fan_kai_zi != null else tile_fan_kai
								# 主格显示树
								if tnx == sx and tny == sy:
									zhang_ai[tny][tnx].visible = true
								else:
									zhang_ai[tny][tnx].visible = false
						break
						break
			elif GZ2["shu_zi"] == true:
				# 数字格子
				GZs[ny][nx].texture = tile_shu_zi[GZ2["number"] - 1]
			elif GZ2["kong_bai"] == true:
				# 空白格子
				GZs[ny][nx].texture = tile_fan_kai
				flood_fill(nx, ny)

# 排雷：该数字格数字=九宫格未翻开格子数量+九宫格已翻开怪物数量，九宫格未翻开格子皆为怪物格
func pai_lei() -> void:
	var GZ = guan_qia.GZ
	var GZs = guan_qia.GZs
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var tile_fan_kai = guan_qia.tile_fan_kai
	# 遍历所有格子
	for y in range(GZ_y):
		for x in range(GZ_x):
			var GZ1 = GZ[y][x]
			# 只处理已翻开的数字格子
			if GZ1["fan_kai"] == false or GZ1["shu_zi"] == false:
				continue
			# 统计周围未翻开格子数量
			var wei_fan_kai_n1 = wei_fan_kai_n9(x, y)
			# 统计周围已确定怪物数量（翻开且怪物）
			var fan_kai_guai_wu_n1 = fan_kai_guai_wu_n9(x, y)
			# 实时统计周围怪物总数
			var guai_wu_n1 = guai_wu_n9(x, y)
			# 如果数字 = 未翻 + 已确定怪物，将周围未翻格子标记为排雷
			if wei_fan_kai_n1 + fan_kai_guai_wu_n1 == guai_wu_n1:
				for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
					for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
						if nx == x and ny == y:
							continue
						var GZ2 = GZ[ny][nx]
						# 只处理未翻开的格子
						if GZ2["fan_kai"] == false:
							# 只有怪物才标记
							if GZ2["guai_wu"] == true:
								# 标记为排雷（小怪物）
								GZ2["fan_kai"] = true
								GZ2["biao_ji"] = false
								GZ2["xiao"] = true
								# 显示翻开图片
								GZs[ny][nx].texture = tile_fan_kai
								# 生成怪物（排雷，小）
								guan_qia.guai_wu_xian_shi(nx, ny, false)

# 和弦：该数字格数字=九宫格已翻开怪物数量，九宫格未翻开格子皆为空格
func he_xian() -> void:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	# 遍历所有格子
	for y in range(GZ_y):
		for x in range(GZ_x):
			var GZ1 = GZ[y][x]
			# 只处理翻开状态的数字格
			if GZ1["fan_kai"] == false:
				continue
			if GZ1["shu_zi"] == false:
				continue
			# 统计周围怪物总数
			var guai_wu_n1 = guai_wu_n9(x, y)
			# 统计周围已确定怪物（翻开且怪物）
			var fan_kai_guai_wu_n1 = fan_kai_guai_wu_n9(x, y)
			# 如果已确定怪物 = 怪物总数（所有怪物都被确定），翻开周围所有未翻开格子
			if fan_kai_guai_wu_n1 == guai_wu_n1:
				for ny in range(max(0, y - 1), min(GZ_y, y + 2)):
					for nx in range(max(0, x - 1), min(GZ_x, x + 2)):
						if nx == x and ny == y:
							continue
						# 只翻开未翻开的格子
						if GZ[ny][nx]["fan_kai"] == false:
							kai_ge_zi(nx, ny, false)

# 翻开格子数量是否变化
func fan_kai_n() -> int:
	var GZ = guan_qia.GZ
	var GZ_y = guan_qia.GZ_y
	var GZ_x = guan_qia.GZ_x
	var n = 0
	for yy in range(GZ_y):
		for xx in range(GZ_x):
			if GZ[yy][xx]["fan_kai"] == true:
				n += 1
	return n

# 翻开格子
func kai_ge_zi(x: int, y: int, cai: bool = false) -> void:
	# 检查坐标是否在网格范围内
	if x < 0 or x >= guan_qia.GZ_x or y < 0 or y >= guan_qia.GZ_y:
		return
	# 获取格子数据
	var GZ1 = guan_qia.GZ[y][x]
	# 如果是障碍，翻开整个2x2区域
	if GZ1.get("zhang_ai", false) == true:
		# 找到树的主格位置
		for shu in guan_qia.zhang_ai_xy:
			var sx = int(shu.x)
			var sy = int(shu.y)
			# 检查当前点击的格子是否在这个树的2x2范围内
			if x >= sx and x < sx + 2 and y >= sy and y < sy + 2:
				# 翻开2x2区域的4个格子
				for ny in range(sy, sy + 2):
					for nx in range(sx, sx + 2):
						if guan_qia.GZ[ny][nx]["fan_kai"] == false and guan_qia.GZ[ny][nx]["biao_ji"] == false:
							guan_qia.GZ[ny][nx]["fan_kai"] = true
							# 障碍格子使用紫地版本的已翻开图片
							guan_qia.GZs[ny][nx].texture = guan_qia.tile_fan_kai_zi if guan_qia.tile_fan_kai_zi != null else guan_qia.tile_fan_kai
							# 主格（左上角）显示树，其他格不显示树
							if nx == sx and ny == sy:
								guan_qia.zhang_ai[ny][nx].visible = true
							else:
								guan_qia.zhang_ai[ny][nx].visible = false
				return
		return
	# 根据格子状态设置属性
	if GZ1["guai_wu"] == true:
		# 怪物格子
		GZ1["fan_kai"] = true
		GZ1["biao_ji"] = false
		if cai:
			GZ1["da"] = true
		else:
			GZ1["xiao"] = true
		# 显示已翻开图片
		guan_qia.GZs[y][x].texture = guan_qia.tile_fan_kai
		# 生成怪物
		guan_qia.guai_wu_xian_shi(x, y, cai)
	elif GZ1["shu_zi"] == true:
		# 数字格子
		GZ1["fan_kai"] = true
		GZ1["biao_ji"] = false
		# 使用预存的 number 显示数字
		guan_qia.GZs[y][x].texture = guan_qia.tile_shu_zi[GZ1["number"] - 1]
	elif GZ1["kong_bai"] == true:
		# 空白格子
		GZ1["fan_kai"] = true
		GZ1["biao_ji"] = false
		# 显示已翻开图片
		guan_qia.GZs[y][x].texture = guan_qia.tile_fan_kai
		# 递归展开周围格子
		guan_qia.fan_kai.flood_fill(x, y)
	# 一键开屏
	while true:
		var bian_hua = false
		# 记录当前已翻开数量
		var qian_n = guan_qia.fan_kai.fan_kai_n()
		# 自动排雷
		guan_qia.fan_kai.pai_lei()
		# 自动和弦开雷
		guan_qia.fan_kai.he_xian()
		# 记录当前已翻开数量
		var hou_n = guan_qia.fan_kai.fan_kai_n()
		# 如果有新格子被翻开，继续循环
		if hou_n > qian_n:
			bian_hua = true
		else:
			break
		# 防止无限循环
		if not bian_hua:
			break
