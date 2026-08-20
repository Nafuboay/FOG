extends Node # 数据管理
var json: int = 1 # 当前选中的存档槽位号
var stg: int = 1 # 当前选中的关卡ID

# 重置数据（游戏结束时调用）
func reset() -> void:
    json = 1
    stg = 1