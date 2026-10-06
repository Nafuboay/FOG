# 【关卡基类】
class_name 关卡基类
extends Node2D
# 信息面板刷新信号
signal shu_wu_upd
# 返回按钮目标场景
@export var fan_hui: String = "res://主城/主城.tscn"
# 网格行数
var GZ_y = 9
# 网格列数
var GZ_x = 9
# 每个格子的像素大小
var GZ_size = 36
# 角色左右偏移量（人物向右，怪物向左）
var role_pian_yi_x = 17
# 角色上下偏移量（中心点上46）
var role_pian_yi_y = 46
# 网格左上角相对于场景原点的X偏移
var WG_pian_yi_x = 0
# 网格起点Y坐标
var WG_pian_yi_y = 0
# 人物所在位置
var helo_y = 1
var helo_x = 1
# GZ: 存储游戏逻辑数据
var GZ = []
# GZs: 存储每个格子对应的Sprite2D显示对象，用于显示图片
var GZs = []
# 障碍物
var zhang_ai = []
# tile_fan_kai: 已翻开格子图片
var tile_fan_kai: Texture2D
# tile_fan_kai_zi: 紫地版本已翻开格子图片（用于障碍格子）
var tile_fan_kai_zi: Texture2D
# tile_shu_zi: 数字1-8的图片数组，分别对应周围1-8个怪物
var tile_shu_zi: Array[Texture2D] = []
# tile_wei_fan_kai: 未翻开格子图片
var tile_wei_fan_kai: Texture2D
# tile_wei_fan_kai_zi: 紫地版本未翻开格子图片（用于障碍格子）
var tile_wei_fan_kai_zi: Texture2D
# tile_biao_ji: 标记旗帜图片
var tile_biao_ji: Texture2D
# tile_biao_ji_zi: 紫地版本标记旗帜图片（用于障碍格子）
var tile_biao_ji_zi: Texture2D
# 模块背景
var kuai: Texture2D
# 信息面板尺寸
var shu_wu_x: int = 256
var shu_wu_y: int = 512
# 九宫格背景容器
var kuai_1: NinePatchRect  # 人物面板九宫格背景
var kuai_2: NinePatchRect  # 怪物面板九宫格背景
# 人物节点
var helo = null
# 怪物位置列表，存储(x, y)坐标
var guai_wu_xy = []
# 存储已生成的怪物节点
var guai_wu = []
# NPC节点引用
var NPC_jie_dian: Node2D = null
# 树图片纹理
var tile_zhang_ai: Texture2D
# 树位置列表，存储主格(x,y)坐标
var zhang_ai_xy = []
# BOSS位置列表，存储主格(x,y)坐标
var BOSS_xy = []
# 战斗系统预加载
const zhan_dou_0 = preload("res://关卡/战斗系统.gd")
# 人物基础属性（等级×默认值）
var helo_lv: int
var helo_jc_shp: int
var helo_jc_hp: int
var helo_jc_ll: int
var helo_jc_fy: int
var helo_jc_ct: int
# 人物当前属性
var helo_shp: int
var helo_hp: int
# 信息面板
var look_helo: Control  # 人物信息面板（左边）
var look_guai_wu: Control  # 怪物信息面板（右边）
var helo_x_ing: int = -1  # 当前查看的人物X坐标
var helo_y_ing: int = -1  # 当前查看的人物Y坐标
var guai_wu_x_ing: int = -1  # 当前显示的怪物X坐标
var guai_wu_y_ing: int = -1  # 当前显示的怪物Y坐标
# 已死亡怪物的属性记录
var guai_wu_si_wang: Dictionary = {}
# 怪物总数量
var guai_wu_zong: int = 0
# 当前怪物数量
var guai_wu_xian: int = 0
# 怪物数量文本
var guai_wu_lbl: Label
# 系统引用
var zhan_dou: 战斗系统
var fan_kai: 翻开系统
var guan_ui: 关卡UI
var XX: 信息面板
# 游戏内容容器（用于缩放）
var rong_qi: Node2D
# 鼠标拖拽起始位置（-1表示未拖拽）
var tuo_dong = Vector2(-1, -1)
# 缩放显示文本
var suo_fang_lal: Label
# 关卡标签
var guan_kia_lbl: Label
# 关卡信息
var guan_kia_id: int = 0 # 关卡值，从0开始
var BB_ls: Dictionary = {} # 临时背包
var guan_kia: Dictionary = {} # 关卡数据字典
var guai_wu_n: Array = [] # 每种怪物的数量
var zhang_ai_n0: int = 0 # 障碍的数量
var BOSS_n: Array = [] # 每种BOSS的数量
var BOSS: Array = [] # BOSS类型列表
var json_id: int = 0 # 当前使用的存档槽位
# 血量倍数
var xue = 1

# 生命周期函数
func _ready() -> void:
	# 加载关卡数据
	du_qu_guan_kia()
	# 获取视口尺寸（逻辑分辨率），避免全屏时偏移
	var viewport_size = get_viewport_rect().size
	# 计算网格居中偏移（相对于容器中心）
	WG_pian_yi_x = -GZ_x * GZ_size / 2.0
	WG_pian_yi_y = -GZ_y * GZ_size / 2.0
	# 加载背景图片
	var canvas = CanvasLayer.new()
	canvas.layer = -1  # 设置层级为-1，确保背景在游戏内容下方
	add_child(canvas)
	var yun_hai = TextureRect.new()  # TextureRect用于显示图片
	yun_hai.texture = load("res://关卡/云海.png")  # 加载云海图片
	yun_hai.set_anchors_preset(Control.PRESET_FULL_RECT)  # 设置为全屏铺满
	canvas.add_child(yun_hai)
	# 创建游戏内容容器
	rong_qi = Node2D.new()
	rong_qi.name = "GameContainer"
	# 容器位置设为屏幕中心（使用视口大小而非物理窗口大小）
	rong_qi.position = viewport_size / 2
	add_child(rong_qi)
	# 加载图片资源
	load_zi_yuan()
	# 实例化战斗系统
	zhan_dou = 战斗系统.new()
	rong_qi.add_child(zhan_dou)
	# 实例化翻开系统
	fan_kai = 翻开系统.new()
	rong_qi.add_child(fan_kai)
	# 实例化关卡UI
	guan_ui = 关卡UI.new()
	add_child(guan_ui)
	# 实例化信息面板
	XX = 信息面板.new()
	add_child(XX)
	# 加载输入处理模块
	var pc_input = load("res://关卡/PC输入.gd").new()
	pc_input.name = "PC输入"
	add_child(pc_input)
	# 创建游戏数据网格
	C_GZ()
	# 连接伤害信号到面板刷新
	shu_wu_upd.connect(XX.on_shu_wu_upd)
	# 创建格子可视化对象
	C_GZ1()
	# 显示BOSS（初始翻开状态）
	BOSS_xian_shi()
	# 创建人物
	C_helo()
	# 创建人物面板
	XX.C_look_helo()
	# 创建缩放按钮
	guan_ui.C_rong_qi()
	# 创建重新挑战按钮
	guan_ui.C_again()

# 加载地图
func load_zi_yuan() -> void:
	var zi_yuan = 关卡数据.load_zi_yuan(guan_kia_id)
	tile_fan_kai = zi_yuan["tile_fan_kai"]
	tile_fan_kai_zi = zi_yuan.get("tile_fan_kai_zi", tile_fan_kai)
	for tex in zi_yuan["tile_shu_zi"]:
		tile_shu_zi.append(tex)
	tile_wei_fan_kai = zi_yuan["tile_wei_fan_kai"]
	tile_wei_fan_kai_zi = zi_yuan.get("tile_wei_fan_kai_zi", tile_wei_fan_kai)
	tile_biao_ji = zi_yuan["tile_biao_ji"]
	tile_biao_ji_zi = zi_yuan.get("tile_biao_ji_zi", tile_biao_ji)
	tile_zhang_ai = zi_yuan["tile_zhang_ai"]

# 数据读取
func du_qu_guan_kia() -> void:
	# 检查并创建存档文件夹
	var json = load("res://主界面/游戏存档.gd").new()
	json.wen_jian_jia()
	json.free()
	# 从数据管理节点读取关卡ID
	if has_node("/root/数据管理"):
		guan_kia_id = get_node("/root/数据管理").stg
	# 获取关卡数据
	guan_kia = 关卡数据.guan_kia(guan_kia_id)
	# 设置网格大小
	GZ_x = guan_kia.get("x", 9)
	GZ_y = guan_kia.get("y", 9)
	# 获取怪物生成数量
	guai_wu_n = guan_kia.get("guai_wu_n", [10])
	# 获取障碍物数量
	zhang_ai_n0 = guan_kia.get("zhang_ai_n", 0)
	# 获取BOSS生成数量
	BOSS = guan_kia.get("BOSS", [])
	BOSS_n = guan_kia.get("BOSS_n", [0])
	# 根据关卡显示提示弹幕
	if guan_kia_id == 0:
		提示弹幕.wen_ben("花精灵·沙华：\"英雄，快去击退那些被邪力污染的怪物吧！\"",1)
	elif guan_kia_id == 1:
		提示弹幕.wen_ben("花精灵·沙华：\"迷雾就是那些魔法树带来的，看起来被邪力影响很深！\"",1)
	elif guan_kia_id == 23:
		提示弹幕.wen_ben("花精灵·沙华：\"荆冠是早期被邪力影响的怪物，非常强大！\"",1)
	elif guan_kia_id == 29:
		提示弹幕.wen_ben("花精灵·沙华：\"犽翡是邪力最初的载体，击败他或许一切就结束了！\"",1)

# 创建网格
func C_GZ() -> void:
	# 清空现有数据
	GZ.clear()
	# 清空怪物位置列表
	guai_wu_xy.clear()
	# 清空怪物节点列表
	guai_wu.clear()
	# 清空树位置列表
	zhang_ai_xy.clear()
	# 清空BOSS位置列表
	BOSS_xy.clear()
	# 遍历每一行
	for y in range(GZ_y):
		# 创建新行
		var row = []
		# 遍历每一列
		for x in range(GZ_x): # 添加初始格子数据
			row.append({
				"number": 0,
				"fan_kai": false,
				"shu_zi": false,
				"kong_bai": false,
				"guai_wu": false,
				"NPC": false,
				"biao_ji": false,
				"da": false,
				"xiao": false,
				"zhang_ai": false,
				"BOSS": false,
				"BX": false,
				"lv": 1,
				"shp": 1,
				"hp": 1,
				"ll": 1,
				"fy": 1,
				"ct": 1
			})
		# 将行添加到网格
		GZ.append(row)
	# 障碍生成数量
	zhang_ai_n(zhang_ai_n0)
	# BOSS生成数量
	sheng_cheng_BOSS()
	# 怪物数量（在人物九宫格外）
	guai_wu_n0()
	# NPC生成
	npc_chu_sheng()
	# 怪物和BOSS总数量
	guai_wu_zong = guai_wu_xy.size() + BOSS_xy.size()
	guai_wu_xian = guai_wu_zong
	# 计算每个格子周围怪物数量
	shu_zi_n()
	# 创建怪物数量文本
	guan_ui.C_guai_wu_lbl()
	# 创建关卡标签
	guan_ui.C_guan_kia_lbl()
# 空格确定：确定数字格子和空白格子
func shu_zi_n() -> void:
	for y in range(GZ_y):
		for x in range(GZ_x):
			# 跳过非空格子
			if GZ[y][x]["guai_wu"] == true:
				continue
			if GZ[y][x].get("zhang_ai", false) == true:
				continue
			if GZ[y][x]["BOSS"] == true:
				continue
			# 统计周围8个格子的怪物数量
			var n = fan_kai.guai_wu_n9(x, y)
			# 记录周围怪物数量
			GZ[y][x]["number"] = n
			# 如果周围有怪物，标记为数字
			if n > 0:
				GZ[y][x]["shu_zi"] = true
				GZ[y][x]["kong_bai"] = false
			# 如果周围没有怪物，标记为空白
			else:
				GZ[y][x]["kong_bai"] = true
				GZ[y][x]["shu_zi"] = false
# 格子显示：为每个网格位置创建一个Sprite2D用于显示图片
func C_GZ1() -> void:
	# 清除现有的Sprite2D子节点
	for child in get_children():
		if child is Sprite2D:
			child.queue_free()
	# 清空格子数组
	GZs.clear()
	# 清空障碍物数组
	zhang_ai.clear()
	# 遍历每一行
	for y in range(GZ_y):
		# 创建新行
		var row = []
		var zhang_ai_row = []
		# 遍历每一列
		for x in range(GZ_x):
			# 创建底层Sprite2D对象
			var s = Sprite2D.new()
			# 设置纹理为未翻开图片，障碍格子使用紫地版本
			s.texture = tile_wei_fan_kai_zi if GZ[y][x].get("zhang_ai", false) else tile_wei_fan_kai
			# 设置位置，根据偏移量和格子索引计算
			s.position = Vector2(
				WG_pian_yi_x + x * GZ_size + GZ_size / 2.0,
				WG_pian_yi_y + y * GZ_size + GZ_size / 2.0
			)
			# 添加到游戏容器
			rong_qi.add_child(s)
			# 添加到格子数组
			row.append(s)
			# 创建上层Sprite2D对象（显示树遮挡物，默认隐藏）
			# 树精灵在格子翻开时显示，覆盖在草地上面
			var zhang_ai_tu = Sprite2D.new()
			# 设置树的纹理图片
			zhang_ai_tu.texture = tile_zhang_ai
			# 设置位置，相对于底层向右偏移18像素
			zhang_ai_tu.position = s.position + Vector2(18, 0)
			# 默认隐藏，翻开树格子时再显示
			zhang_ai_tu.visible = false
			# 设置层级为左下角格子对应的层级（树的主格下方一格）
			zhang_ai_tu.z_index = (GZ_x - x) + (y + 1) * GZ_y
			# 添加到游戏容器
			rong_qi.add_child(zhang_ai_tu)
			# 将树精灵添加到当前行的数组
			zhang_ai_row.append(zhang_ai_tu)
		# 将当前行的精灵数组添加到二维数组
		GZs.append(row)
		zhang_ai.append(zhang_ai_row)

# 生成障碍
func zhang_ai_n(n: int) -> void:
	# 人物位置（从1开始）
	var helo_x0 = helo_x - 1
	var helo_y0 = helo_y - 1
	var min_x = helo_x0
	var max_x = helo_x0 + 1
	var min_y = helo_y0
	var max_y = helo_y0 + 1
	# 随机生成n棵树
	for i in range(n):
		var sheng_cheng = false
		var try = 0
		while not sheng_cheng and try < 1000:
			# 随机选择主格位置
			var x = randi() % (GZ_x - 1)
			var y = randi() % (GZ_y - 1)
			# 检查主格是否在九宫格内
			if x >= min_x and x <= max_x and y >= min_y and y <= max_y:
				try += 1
				continue
			# 检查3x3区域是否与已有树重叠（树之间保持1格间隔）
			var overlap = false
			for shu in zhang_ai_xy:
				var sx = int(shu.x)
				var sy = int(shu.y)
				if x < sx + 3 and x + 3 > sx and y < sy + 3 and y + 3 > sy:
					overlap = true
					break
			if overlap:
				try += 1
				continue
			# 检查是否已有障碍物
			if GZ[y][x].get("zhang_ai", false) == true:
				try += 1
				continue
			# 标记4个格子为障碍物（2x2区域）
			for ny in range(y, y + 2):
				for nx in range(x, x + 2):
					GZ[ny][nx]["zhang_ai"] = true
			# 记录树主格位置
			zhang_ai_xy.append(Vector2(x, y))
			sheng_cheng = true

# 生成BOSS
func sheng_cheng_BOSS() -> void:
	# 如果没有配置BOSS数据，则直接返回
	if BOSS.is_empty():
		return
	# 人物位置（从1开始，转为0开始索引）
	var helo_x0 = helo_x - 1
	var helo_y0 = helo_y - 1
	# 遍历每种BOSS类型（支持多种BOSS）
	for i in range(BOSS.size()):
		# 获取当前BOSS类型名称
		var boss_ming = BOSS[i]
		# 获取当前BOSS类型的数量
		var boss_shu = 0
		if i < BOSS_n.size():
			boss_shu = BOSS_n[i]
		# 循环生成指定数量的BOSS
		for j in range(boss_shu):
			var sheng_cheng = false
			var try_count = 0
			# 尝试最多1000次找到合适位置
			while not sheng_cheng and try_count < 1000:
				# 随机选择主格位置（主格为左上角）
				var x = randi() % (GZ_x - 1)
				var y = randi() % (GZ_y - 1)
				# 检查主格是否在人物九宫格内
				if x >= helo_x0 and x <= helo_x0 + 1 and y >= helo_y0 and y <= helo_y0 + 1:
					try_count += 1
					continue
				# 检查3x3区域是否与已有树重叠
				var overlap = false
				for shu in zhang_ai_xy:
					var sx = int(shu.x)
					var sy = int(shu.y)
					if x < sx + 3 and x + 3 > sx and y < sy + 3 and y + 3 > sy:
						overlap = true
						break
				if overlap:
					try_count += 1
					continue
				# 检查3x3区域是否与已有BOSS重叠
				for boss in BOSS_xy:
					var bx = int(boss.x)
					var by = int(boss.y)
					if x < bx + 3 and x + 3 > bx and y < by + 3 and y + 3 > by:
						overlap = true
						break
				if overlap:
					try_count += 1
					continue
				# 检查是否已有障碍物或普通怪物
				if GZ[y][x].get("zhang_ai", false) == true or GZ[y][x].get("guai_wu", false) == true:
					try_count += 1
					continue
				# 标记4个格子为BOSS（2x2区域），不标记为怪物以免影响数字显示
				for ny in range(y, y + 2):
					for nx in range(x, x + 2):
						GZ[ny][nx]["BOSS"] = true       # 标记为BOSS
						GZ[ny][nx]["fan_kai"] = true    # 标记为已翻开（初始显示）
						GZ[ny][nx]["guai_wu_id"] = boss_ming  # 记录BOSS类型
				# 记录BOSS主格位置
				BOSS_xy.append(Vector2(x, y))
				sheng_cheng = true

# 怪物确定
func guai_wu_n0() -> void:
	# 人物位置
	var min_x = helo_x - 1
	var max_x = helo_x
	var min_y = helo_y - 1
	var max_y = helo_y
	# 收集所有可用位置
	var guai_wu_fan_wei = []
	# 遍历地图每个格子
	for y in range(GZ_y):
		for x in range(GZ_x):
			# 检查格子是否可投放怪物
			if x >= min_x and x <= max_x and y >= min_y and y <= max_y:
				continue  # 在人物初始位置附近，跳过
			if GZ[y][x].get("zhang_ai", false) == true:
				continue  # 有障碍，跳过
			if GZ[y][x]["BOSS"] == true:
				continue  # 有BOSS，跳过
			# 该格子可用，添加到可用位置列表
			guai_wu_fan_wei.append(Vector2(x, y))
	# 随机打乱可用位置列表，让怪物生成位置随机
	guai_wu_fan_wei.shuffle()
	# 从关卡数据中获取怪物类型列表
	var n2 = guan_kia.get("guai_wu", ["null"])
	# 怪物位置索引（用于从打乱后的位置列表中取值）
	var n0 = 0
	# 遍历每种怪物类型
	for n1 in range(n2.size()):
		# n3 是当前类型的怪物名称
		var n3 = n2[n1]
		# n4 是该类型怪物要生成的数量
		var n4 = 0
		if n1 < guai_wu_n.size():
			n4 = guai_wu_n[n1]
		else:
			n4 = 0
		# 循环生成该类型的怪物
		for j in range(n4):
			# 检查可用位置是否已用完
			if n0 >= guai_wu_fan_wei.size():
				break  # 没有可用位置了，停止生成
			# 从可用位置列表中取一个坐标
			var xy = guai_wu_fan_wei[n0]
			var x = int(xy.x)  # 格子X坐标
			var y = int(xy.y)  # 格子Y坐标
			# 在网格数据中标记该格子有怪物
			GZ[y][x]["guai_wu"] = true
			# 记录该怪物的具体类型ID
			GZ[y][x]["guai_wu_id"] = n3
			# 把怪物位置添加到位置列表（用于后续实例化）
			guai_wu_xy.append(xy)
			# 位置索引+1，下次取下一个位置
			n0 += 1

func npc_chu_sheng() -> void:
	var x = 1
	var y = 1
	GZ[y][x]["NPC"] = true
	GZ[y][x]["NPC_id"] = "花精灵·沙华"
	GZ[y][x]["NPC_hp"] = guan_kia_id + 1
	npc_xian_shi(x, y)

# 显示NPC
func npc_xian_shi(x: int, y: int) -> void:
	# 获取NPC名称，默认为琥珀
	var NPC_id = GZ[y][x].get("NPC_id", "花精灵·沙华")
	# 根据NPC名称获取场景路径
	var lu_jing = 关卡数据.get_npc_tscn(NPC_id)
	# 如果路径为空，直接返回
	if lu_jing.is_empty():
		return
	# 实例化NPC场景
	var npc = load(lu_jing).instantiate()
	# 存储网格坐标到NPC节点元数据
	npc.set_meta("grid_x", x)
	npc.set_meta("grid_y", y)
	# 存储NPC节点引用
	NPC_jie_dian = npc
	# 计算格子中心位置
	var GZ_z = GZ_zhong(x, y)
	# 设置缩放为1倍（和玩家一样）
	var suo_fang = 1
	# 计算偏移量
	var pian_yi_x1 = role_pian_yi_x * suo_fang
	var pian_yi_y1 = role_pian_yi_y * suo_fang
	# 设置NPC位置：格子中心减去偏移
	npc.position = Vector2(GZ_z.x - pian_yi_x1, GZ_z.y - pian_yi_y1)
	# 设置层级：左边比右边高，下边比上边高
	npc.z_index = (GZ_x - x) + y * GZ_y
	# 设置缩放
	npc.scale = Vector2(suo_fang, suo_fang)
	# 添加到游戏容器
	rong_qi.add_child(npc)

# NPC消失处理
func NPC_xiao_shi(x: int, y: int) -> void:
	# 清除NPC标记
	GZ[y][x]["NPC"] = false
	# 如果正在查看该NPC，关闭面板
	if guai_wu_x_ing == x and guai_wu_y_ing == y:
		if look_guai_wu != null:
			look_guai_wu.queue_free()
			look_guai_wu = null
		if kuai_2 != null:
			kuai_2.queue_free()
			kuai_2 = null
		guai_wu_x_ing = -1
		guai_wu_y_ing = -1
	# 删除NPC节点
	if NPC_jie_dian != null:
		NPC_jie_dian.queue_free()
		NPC_jie_dian = null
	提示弹幕.wen_ben("花精灵·沙华：“我的力量耗尽了，祝你好运。”", 0.5)

# 怪物显示
func guai_wu_xian_shi(x: int, y: int, cai: bool = false) -> void:
	# 根据怪物名称加载对应的场景
	var guai_wu_id = GZ[y][x].get("guai_wu_id", "红巨蟹")
	var lu_jing = 关卡数据.get_tscn(guai_wu_id)
	var guai_wu1 = load(lu_jing).instantiate()
	# 存储坐标到怪物节点
	guai_wu1.set_meta("grid_x", x)
	guai_wu1.set_meta("grid_y", y)
	# 存储怪物名称到GZ数据（直接用关卡数据里的名字）
	GZ[y][x]["名字"] = guai_wu_id
	# 从掉落物脚本获取怪物描述
	GZ[y][x]["miao_shu"] = 掉落物.guai_wu_miao_shu.get(guai_wu_id, "")
	# 设置怪物属性：大怪物×2，小怪物直接调用脚本中的初始值
	var shuang = 2 if cai else 1
	GZ[y][x]["lv"] = guai_wu1.LV * shuang
	# 魔法树加成
	var add = 0
	add = fan_kai.zhang_ai_n9(x, y)
	GZ[y][x]["shp"] = guai_wu1.HP * shuang * xue + add
	GZ[y][x]["hp"] = GZ[y][x]["shp"]
	GZ[y][x]["ll"] = guai_wu1.LL * shuang + add
	GZ[y][x]["fy"] = guai_wu1.FY * shuang + add
	GZ[y][x]["ct"] = guai_wu1.CT * shuang + add
	GZ[y][x]["add"] = add  # 存储魔法树加成值
	# 计算格子中心位置
	var GZ_z = GZ_zhong(x, y)
	# 缩放后偏移也要乘以缩放比例
	var suo_fang = 0.5
	var pian_yi_x1 = role_pian_yi_x * suo_fang
	var pian_yi_y1 = role_pian_yi_y * suo_fang
	if cai:
		suo_fang = 1.0
		pian_yi_x1 = role_pian_yi_x * suo_fang
		pian_yi_y1 = role_pian_yi_y * suo_fang
	guai_wu1.position = Vector2(GZ_z.x - pian_yi_x1, GZ_z.y - pian_yi_y1)
	# 设置层级：左边比右边高，下边比上边高，左下角最高
	guai_wu1.z_index = (GZ_x - x) + y * GZ_y
	# 排雷0.5倍，踩雷1倍（先设置位置，缩放会改变位置）
	guai_wu1.scale = Vector2(suo_fang, suo_fang)
	# 添加到游戏容器
	rong_qi.add_child(guai_wu1)
	# 存储怪物引用
	guai_wu.append(guai_wu1)
	# 确保动画播放
	if guai_wu1.has_node("AnimatedSprite2D"):
		var dong_hua = guai_wu1.get_node("AnimatedSprite2D")
		if dong_hua.sprite_frames and dong_hua.sprite_frames.has_animation("idle"):
			dong_hua.play("idle")

# BOSS显示
func BOSS_xian_shi() -> void:
	# 遍历所有BOSS位置
	for boss_xy in BOSS_xy:
		# 获取BOSS主格坐标（左上角）
		var x = int(boss_xy.x)
		var y = int(boss_xy.y)
		# 获取BOSS类型名称
		var guai_wu_id = GZ[y][x].get("guai_wu_id", "红巨蟹")
		# 根据类型获取场景路径并实例化
		var lu_jing = 关卡数据.get_tscn(guai_wu_id)
		var guai_wu1 = load(lu_jing).instantiate()
		# 存储网格坐标到怪物节点元数据
		guai_wu1.set_meta("grid_x", x)
		guai_wu1.set_meta("grid_y", y)
		# 计算BOSS属性
		var boss_lv = guai_wu1.LV * 2
		var boss_shp = int(round(guai_wu1.HP * 15.1875)) * xue
		var boss_ll = guai_wu1.LL * 2
		var boss_fy = guai_wu1.FY * 2
		var boss_ct = guai_wu1.CT * 2
		var shp_1 = boss_shp # 记录基础生命值（用于热血技能动态计算）
		if guai_wu_id == "野猪王·冕笑":
			var shp_add = (guai_wu_xian - 1) * boss_lv
			boss_shp += shp_add
		# 在4个格子都写入相同的属性
		for by in range(y, y + 2):
			for bx in range(x, x + 2):
				GZ[by][bx]["名字"] = guai_wu_id
				GZ[by][bx]["miao_shu"] = 掉落物.guai_wu_miao_shu.get(guai_wu_id, "")
				GZ[by][bx]["lv"] = boss_lv
				GZ[by][bx]["shp_1"] = shp_1  # 存储基础生命值
				GZ[by][bx]["shp"] = boss_shp
				GZ[by][bx]["hp"] = boss_shp
				GZ[by][bx]["ll"] = boss_ll
				GZ[by][bx]["fy"] = boss_fy
				GZ[by][bx]["ct"] = boss_ct
				# BOSS技能初始化（主线与诛邪通用）
				BOSS_ji_neng_chu_shi(GZ[by][bx], guai_wu_id, boss_lv)
		# 计算显示位置（格子中心）
		var GZ_z = GZ_zhong(x, y)
		# 缩放比例1.5倍（比大怪物更大）
		var suo_fang = 1.5
		# 计算偏移量（根据缩放比例调整）
		var pian_yi_x1 = role_pian_yi_x*suo_fang-18
		var pian_yi_y1 = role_pian_yi_y*suo_fang-18
		# 设置怪物位置
		guai_wu1.position = Vector2(GZ_z.x - pian_yi_x1, GZ_z.y - pian_yi_y1)
		# 设置层级：左边比右边高，下边比上边高，左下角最高（+1显示在2x2区域的左下角）
		guai_wu1.z_index = (GZ_x - x) + (y + 1) * GZ_y
		# 设置缩放
		guai_wu1.scale = Vector2(suo_fang, suo_fang)
		# 添加到游戏容器
		rong_qi.add_child(guai_wu1)
		# 存储怪物引用
		guai_wu.append(guai_wu1)
		# 确保动画播放
		if guai_wu1.has_node("AnimatedSprite2D"):
			var dong_hua = guai_wu1.get_node("AnimatedSprite2D")
			if dong_hua.sprite_frames and dong_hua.sprite_frames.has_animation("idle"):
				dong_hua.play("idle")
		# 将BOSS占据的格子显示为已翻开（草地图片）
		for ny in range(y, y + 2):
			for nx in range(x, x + 2):
				GZs[ny][nx].texture = tile_fan_kai

# BOSS技能初始化：设置依赖初始字段的技能数据（主线BOSS_xian_shi与诛邪_zhu_xie_guai_wu通用）
func BOSS_ji_neng_chu_shi(cell: Dictionary, guai_wu_id: String, boss_lv: int) -> void:
	# 猛犸王【重甲】技能：增加防御，受击减少
	var fy_add_4 = 0
	if guai_wu_id == "猛犸王·犽翡":
		fy_add_4 = 32 * boss_lv
		cell["fy"] += fy_add_4
	# 写入重甲防御加成（供战斗系统受击减防和信息面板读取）
	cell["fy_add_4"] = fy_add_4

# 创建人物等
func C_helo() -> void:
	# 检查是否已有存档节点，没有则创建
	var json: Node
	if not has_node("/root/游戏存档"):
		# 加载存档管理脚本并创建新节点
		json = load("res://主界面/游戏存档.gd").new()
		# 设置节点名称为"游戏存档"
		json.name = "游戏存档"
		# 将节点添加到根节点下（全局单例）
		get_tree().root.add_child(json)
	else:
		# 已有存档节点，直接获取
		json = get_node("/root/游戏存档")
	# 读取当前档位
	json_id = json.get_dang_wei()
	# 从存档中读取数据（包含人物名字和等级）
	var data = json.du_qu(json_id)
	# 获取人物名字
	var helo_name = data.get("英雄", "未知")
	# 加载人物场景资源
	var helo_tscn = load("res://角色/人物/" + helo_name + "/" + helo_name + ".tscn")
	# 实例化人物节点（创建人物对象）
	helo = helo_tscn.instantiate()
	# 从角色脚本中读取初始属性（基础属性）
	var hp = helo.HP
	var ll = helo.LL
	var fy = helo.FY
	var ct = helo.CT
	# 读取存档中保存的等级，默认1级
	var lv = 1
	if data.size() > 0 and data.has("等级"):
		lv = round(data["等级"])
	# 根据等级计算属性（基础属性 * 等级）
	helo_lv = lv
	helo_jc_shp = hp * lv * xue
	helo_jc_hp = helo_jc_shp
	helo_jc_ll = ll * lv
	helo_jc_fy = fy * lv
	helo_jc_ct = ct * lv
	helo_shp = helo_jc_shp
	helo_hp = helo_jc_hp
	# 应用装备强化属性
	get_ZB(data)
	# 获取人物格子的中心坐标（从1开始计数，转换为0开始索引）
	var helo_x0 = helo_x - 1
	var helo_y0 = helo_y - 1
	# 计算人物中心位置
	var GZ_z = GZ_zhong(helo_x0, helo_y0)
	helo.position = Vector2(GZ_z.x + role_pian_yi_x, GZ_z.y - role_pian_yi_y)
	# 设置层级：左边比右边高，下边比上边高，右下比左上高
	helo.z_index = (GZ_x - helo_x0) + helo_y0 * GZ_y
	# 将人物节点添加到游戏容器中
	rong_qi.add_child(helo)
	# 播放待机动画（如果有该方法）
	if helo.has_method("play_idle"):
		helo.play_idle(true)
	# 加载血条资源并创建血条
	zhan_dou.load_xue_tiao_zi_yuan()
	zhan_dou.C_xue_tiao_1()
	zhan_dou.C_xue_tiao_2()
	# 翻开人物九宫格
	fan_kai.kai_ge_zi(helo_x0, helo_y0, true)
	fan_kai.kai_ge_zi(helo_x0 + 1, helo_y0, true)
	fan_kai.kai_ge_zi(helo_x0, helo_y0 + 1, true)
	fan_kai.kai_ge_zi(helo_x0 + 1, helo_y0 + 1, true)

func helo_move(x: int, y: int) -> void:
	var pc_input = get_node_or_null("PC输入")
	if pc_input and pc_input.has_method("helo_move"):
		pc_input.helo_move(x, y)

# 计算格子中心位置
func GZ_zhong(x: int, y: int) -> Vector2:
	var GZ_zhong_x = WG_pian_yi_x + x * GZ_size + GZ_size / 2.0
	var GZ_zhong_y = WG_pian_yi_y + y * GZ_size + GZ_size / 2.0
	return Vector2(GZ_zhong_x, GZ_zhong_y)

# 应用装备强化属性到角色
func get_ZB(data: Dictionary) -> void:
	# 检查人物节点是否有效
	if helo == null:
		return
	# 从存档中获取强化数据
	var QHs = data.get("强化", {})
	# 获取各属性的强化等级
	var hp_lv = QHs.get("生命", 0)
	var ll_lv = QHs.get("力量", 0)
	var fy_lv = QHs.get("防御", 0)
	var ct_lv = QHs.get("穿透", 0)
	# 应用装备强化等级到装备加成字段
	helo.shp_add_0 = hp_lv
	helo.ll_add_0 = ll_lv
	helo.fy_add_0 = fy_lv
	helo.ct_add_0 = ct_lv
	# 更新当前生命值上限
	helo_shp = helo.shu_xing_upd(helo_jc_shp, "shp")
	helo_hp = helo_shp
