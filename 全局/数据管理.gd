extends Node # 数据管理
var json: int = 1 # 当前选中的存档槽位号
var stg: int = 1 # 当前选中的关卡ID
var mode: int = 0 # 当前模式：0=主线, 1=诛邪
var zx_guan_kia_id: int = 1 # 诛邪模式关卡ID

# 重置数据（游戏结束时调用）
func reset() -> void:
	json = 1
	stg = 1
	mode = 0
	zx_guan_kia_id = 1
