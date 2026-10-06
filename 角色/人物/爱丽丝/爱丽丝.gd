class_name 爱丽丝 extends "res://角色/人物基类.gd"

const LV: int = 1
const HP: int = 6
const LL: int = 8
const FY: int = 6
const CT: int = 9

# 战斗结束特殊技能：生命回满（战斗系统通过has_method调用，参数为战斗系统）
func zhan_dou_end_ji_neng(zd: Node) -> void:
	var hui_fu_zhi = zd.guan_qia.helo_shp - zd.guan_qia.helo_hp
	zd.hui_fu(0, 0, hui_fu_zhi, true)
	zd.guan_qia.shu_wu_upd.emit()
