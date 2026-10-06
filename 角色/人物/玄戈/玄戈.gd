class_name 玄戈 extends "res://角色/人物基类.gd"

const LV: int = 1
const HP: int = 8
const LL: int = 5
const FY: int = 10
const CT: int = 5

func _ready() -> void:
	super._ready()
	attack_n = 2

func shang_hai_hou() -> void:
	ll_add_1 += 1

# 战斗结束特殊技能：重置战斗临时力量加成（战斗系统通过has_method调用，参数为战斗系统）
func zhan_dou_end_ji_neng(zd: Node) -> void:
	zd.guan_qia.helo.ll_add_1 = 0
	zd.guan_qia.shu_wu_upd.emit()
