# 【属性加成】怪物属性加成统一管理模块（RefCounted，_init(guan_qia, zhan_dou) 同战斗系统等模块模式）
# 核心模型：当前值 = 基础值 + 总变化量，总变化量 = 各来源贡献之和
#   cell["shp_base"/"ll_base"/"fy_base"/"ct_base"]  基础值（无任何加成）
#   cell["shp_bian"/"ll_bian"/"fy_bian"/"ct_bian"]  总变化量（信息面板"初始值±变化值"直接读它）
#   cell["shp"/"ll"/"fy"/"ct"]                      当前值（战斗/显示用）
#   cell["hp"]                                      当前生命：上限变动 delta 时同步增减（clamp 至少1、不超上限）
#   cell["jia_cheng"]                               来源贡献表 {"魔法树"/"花香"/"热血"/"重甲"/"硬化"/"秤干戚": {shp,ll,fy,ct}}
# 各加成来源只维护自己的规则与贡献：变动时调用 she_zhi 覆盖自己的贡献即可，
# 总变化量、当前值、hp 同步由本模块统一重算 —— 来源之间互不覆盖、与加成顺序无关
extends RefCounted

var guan_qia: Node2D
# 战斗系统引用（用于重算后刷新血条）
var zhan_dou: Node

# 初始化（由关卡基类 _ready 创建，引用关卡与战斗系统节点）
func _init(gq: Node2D, zd: Node) -> void:
	guan_qia = gq
	zhan_dou = zd

# 初始化单格基础属性：写入基础值、清空来源表、总变化量=0、当前值=基础值、满血
func chu_shi_hua(cell: Dictionary, base: Dictionary) -> void:
	for k in ["shp", "ll", "fy", "ct"]:
		cell[k + "_base"] = base[k]
		cell[k + "_bian"] = 0
		cell[k] = base[k]
	cell["jia_cheng"] = {}
	cell["hp"] = base["shp"]

# 取怪物占位格子数组（普通怪1格，BOSS 2x2共4格，主格为左上角(x,y)）
func qu_cells(x: int, y: int, is_boss: bool) -> Array:
	var cells = []
	var n = 2 if is_boss else 1
	for by in range(y, y + n):
		for bx in range(x, x + n):
			cells.append(guan_qia.GZ[by][bx])
	return cells

# 覆盖式设置某来源的贡献（gong_xian = {shp,ll,fy,ct}），并重算 cells 的总变化量与当前值
func she_zhi(cells: Array, lai_yuan: String, gong_xian: Dictionary) -> void:
	# 补全缺省属性为0
	var gong = {"shp": 0, "ll": 0, "fy": 0, "ct": 0}
	for k in gong.keys():
		gong[k] = gong_xian.get(k, 0)
	for cell in cells:
		var jia = cell.get("jia_cheng", {})
		jia[lai_yuan] = gong
		cell["jia_cheng"] = jia
		_chong_suan(cell)
	_shua_xin()

# 重算单格：总变化量 = 各来源贡献之和；当前值 = 基础值 + 总变化量；hp 按上限变动量同步
func _chong_suan(cell: Dictionary) -> void:
	var zong = {"shp": 0, "ll": 0, "fy": 0, "ct": 0}
	for lai in cell["jia_cheng"].values():
		for k in zong.keys():
			zong[k] += lai.get(k, 0)
	var jiu_shp: int = cell["shp"]
	for k in zong.keys():
		cell[k + "_bian"] = zong[k]
		cell[k] = cell[k + "_base"] + zong[k]
	# 上限变动同步当前生命（上限加当前加、上限降当前降，clamp 至少1）
	var delta: int = cell["shp"] - jiu_shp
	if delta != 0:
		cell["hp"] = clamp(cell["hp"] + delta, 1, max(1, cell["shp"]))

# 重算后统一刷新（信息面板 + 血条）
func _shua_xin() -> void:
	guan_qia.shu_wu_upd.emit()
	if zhan_dou != null and zhan_dou.xue_tiao_qi != null:
		zhan_dou.xue_tiao_qi.xue_tiao_upd_1()
