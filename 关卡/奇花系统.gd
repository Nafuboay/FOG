# 【奇花系统】
# 与战斗系统/翻开系统/死亡处理同属 Node 子节点模式，父节点为关卡节点
# 花在关卡数据层的表示：GZ[y][x]["hua"] = true + ["hua_id"] = 花名
extends Node
# 四种奇花名称（顺序与物品信息.gd 物品名一致）
const HUA_MING = ["百合", "水仙", "玫瑰", "鸢尾"]
# 每种花的属性加成（按 shp 生命 / ll 力量 / fy 防御 / ct 穿透 顺序）
const HUA_JIA_CHENG = {
	"百合": {"shp": 7, "ll": 3, "fy": 3, "ct": 3},
	"水仙": {"shp": 3, "ll": 7, "fy": 3, "ct": 3},
	"玫瑰": {"shp": 3, "ll": 3, "fy": 7, "ct": 3},
	"鸢尾": {"shp": 3, "ll": 3, "fy": 3, "ct": 7}
}
var guan_qia: Node2D
# 四种花贴图（关卡数据返回的字典；无花的关卡（主线/诛邪）时为空字典 {}）
var tile_hua: Dictionary = {}
# 花朵节点二维数组（每格一个 Sprite2D，默认隐藏；花格翻开时显示）
var hua = []
# 花所在位置列表（Vector2(x,y)，采摘时 erase）
var hua_xy = []

# 获取父节点
func _ready() -> void:
	var parent = get_parent()
	if parent.name != "关卡":
		parent = parent.get_parent()
	guan_qia = parent

# 外部入口：加载花贴图（由关卡基类 load_zi_yuan 调用，传入关卡数据 tile_hua 字典）
func load_tile_hua(tle: Dictionary) -> void:
	tile_hua = tle

# 外部入口：创建花朵节点二维数组（由关卡基类 C_GZ1 调用）
func C_hua() -> void:
	hua.clear()
	var GZ_x: int = guan_qia.GZ_x
	var GZ_y: int = guan_qia.GZ_y
	var rong_qi: Node2D = guan_qia.rong_qi
	for y in range(GZ_y):
		var hua_row = []
		for x in range(GZ_x):
			var s = guan_qia.GZs[y][x]
			var hua_tu = Sprite2D.new()
			hua_tu.position = s.position + Vector2(0, -12)
			hua_tu.visible = false
			# 层级同底层格子/怪物/人物：左边比右边高、下边比上边高
			hua_tu.z_index = (GZ_x - x) + y * GZ_y
			rong_qi.add_child(hua_tu)
			hua_row.append(hua_tu)
		hua.append(hua_row)

# 由支线.gd 覆写的 sheng_cheng_BOSS() 调用
# 避开人物九宫格、BOSS 2x2、已有花/障碍/怪物格
func hua_sheng_cheng(count: int) -> void:
	if count <= 0:
		return
	if tile_hua.is_empty():
		return
	var helo_x0 = guan_qia.helo_x - 1
	var helo_y0 = guan_qia.helo_y - 1
	for hua_i in range(HUA_MING.size()):
		var hua_name = HUA_MING[hua_i]
		for i in range(count):
			var placed = false
			var tries = 0
			while not placed and tries < 1000:
				tries += 1
				var x = randi() % guan_qia.GZ_x
				var y = randi() % guan_qia.GZ_y
				if x >= helo_x0 and x <= helo_x0 + 1 and y >= helo_y0 and y <= helo_y0 + 1:
					continue
				var GZ1 = guan_qia.GZ[y][x]
				# 花先于怪物放置（顺序：BOSS→花→怪物），所以只需要避开已有的东西：
				# BOSS（先放了）、已有花（不能重叠）、NPC（此时还没生成但保险）
				if GZ1["BOSS"] == true:
					continue
				if GZ1.get("hua", false) == true:
					continue
				if GZ1.get("NPC", false) == true:
					continue
				GZ1["hua"] = true
				GZ1["hua_id"] = hua_name
				hua_xy.append(Vector2(x, y))
				placed = true
				break

# 计算 (x,y) 位置怪物/BOSS 周围的花香加成
# is_boss=true：扫 BOSS 占 2x2 的外圈 12 格（4x4 减自身 2x2）
# is_boss=false：扫普通怪周围 8 格
func hua_xiang_jia_cheng(x: int, y: int, is_boss: bool = false) -> Dictionary:
	var result = {"shp": 0, "ll": 0, "fy": 0, "ct": 0}
	if tile_hua.is_empty():
		return result
	var x_min: int
	var x_max: int
	var y_min: int
	var y_max: int
	var GZ_x: int = guan_qia.GZ_x
	var GZ_y: int = guan_qia.GZ_y
	if is_boss:
		x_min = x - 1
		x_max = x + 2
		y_min = y - 1
		y_max = y + 2
	else:
		x_min = x - 1
		x_max = x + 1
		y_min = y - 1
		y_max = y + 1
	for ny in range(max(0, y_min), min(GZ_y, y_max + 1)):
		for nx in range(max(0, x_min), min(GZ_x, x_max + 1)):
			if nx == x and ny == y:
				continue
			if is_boss and nx >= x and nx <= x + 1 and ny >= y and ny <= y + 1:
				continue
			var GZ2 = guan_qia.GZ[ny][nx]
			if GZ2.get("hua", false) == true:
				var hua_id = GZ2.get("hua_id", "")
				var buff = HUA_JIA_CHENG.get(hua_id, {})
				result["shp"] += buff.get("shp", 0)
				result["ll"] += buff.get("ll", 0)
				result["fy"] += buff.get("fy", 0)
				result["ct"] += buff.get("ct", 0)
	return result

# 翻开花格时显示花朵（位置/纹理由本系统统一管理）
func hua_xian_shi(hx: int, hy: int) -> void:
	if hx < 0 or hx >= guan_qia.GZ_x or hy < 0 or hy >= guan_qia.GZ_y:
		return
	var GZ1 = guan_qia.GZ[hy][hx]
	if GZ1.get("hua", false) != true:
		return
	var hua_id = GZ1.get("hua_id", "")
	if hua.is_empty() or hua[hy].size() <= hx:
		return
	var hua_tu = hua[hy][hx]
	if hua_tu == null:
		return
	if tile_hua.has(hua_id):
		hua_tu.texture = tile_hua[hua_id]
		# 按原始纹理尺寸缩放到格子大小（GZ_size=36px）
		var t = hua_tu.texture
		if t != null and t.get_width() > 0 and t.get_height() > 0:
			var s = guan_qia.GZ_size
			hua_tu.scale = Vector2(float(s) / t.get_width(), float(s) / t.get_height())
	hua_tu.visible = true

# 采摘后隐藏花朵节点（同时重置纹理）
func hua_xiao_shi(hx: int, hy: int) -> void:
	if hx < 0 or hx >= guan_qia.GZ_x or hy < 0 or hy >= guan_qia.GZ_y:
		return
	if hua.is_empty() or hua[hy].size() <= hx:
		return
	var hua_tu = hua[hy][hx]
	if hua_tu == null:
		return
	hua_tu.visible = false
	hua_tu.texture = null

# 花 (hx, hy) 消失时：直接扫花周围找受影响的怪物/BOSS 并重算属性
# 普通怪：花周围 8 格内，哪格 guai_wu=true 就重算哪只（O(8)）
# BOSS：花是否落在 BOSS 的 12 格扫描范围（4x4 外框减自身 2x2）
func hua_xiang_chong_suan_zhou_wei(hx: int, hy: int) -> void:
	var guan_qia_zz = guan_qia
	var GZ_x: int = guan_qia_zz.GZ_x
	var GZ_y: int = guan_qia_zz.GZ_y
	# 花周围 8 格内的普通怪物
	for ny in range(max(0, hy - 1), min(GZ_y, hy + 2)):
		for nx in range(max(0, hx - 1), min(GZ_x, hx + 2)):
			if nx == hx and ny == hy:
				continue
			var GZ2 = guan_qia_zz.GZ[ny][nx]
			if GZ2["guai_wu"] == true:
				_hua_chong_suan_yi_zhi(nx, ny, false)
	# BOSS_xy 一般 0~1 个，遍历无妨
	for bxy in guan_qia_zz.BOSS_xy:
		var bx = int(bxy.x)
		var by = int(bxy.y)
		# 花是否落在该 BOSS 的 4x4 外框扫描范围里（去掉自身 2x2）
		var in_range = (hx >= bx - 1 and hx <= bx + 2 and hy >= by - 1 and hy <= by + 2) \
			and not (hx >= bx and hx <= bx + 1 and hy >= by and hy <= by + 1)
		if in_range:
			_hua_chong_suan_yi_zhi(bx, by, true)

# 内部函数：重算某一只普通怪或某一只 BOSS（4 格同步）的花香来源
# 只覆盖"花香"来源贡献，树/热血/重甲等其他来源不受影响；
# 上限变动时当前生命由属性加成模块统一同步
func _hua_chong_suan_yi_zhi(x: int, y: int, is_boss: bool) -> void:
	var cells = guan_qia.shu_xing.qu_cells(x, y, is_boss)
	# 新花香贡献 = 重扫周围现存的花
	var hua_add = hua_xiang_jia_cheng(x, y, is_boss)
	guan_qia.shu_xing.she_zhi(cells, "花香", hua_add)
