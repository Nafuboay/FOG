class_name 秤干戚 extends "res://角色/人物基类.gd"

const LV: int = 1
const HP: int = 9
const LL: int = 5
const FY: int = 9
const CT: int = 9

# 本场战斗是否尚未攻击过（首次攻击必为重击，战斗结束重置）
var shou_ci: bool = true
# 本次攻击是否为重击（取伤害系数时判定，伤害结算后据此执行防御变化）
var ben_ci_zhong: bool = false

# 伤害系数判定：每场战斗首次攻击必为重击×2.5，之后每次攻击20%重击×2.5、80%轻击×0.625
func shang_hai_xi_shu() -> float:
	if shou_ci:
		shou_ci = false
		ben_ci_zhong = true
	else:
		ben_ci_zhong = randf() < 0.2
	return 2.5 if ben_ci_zhong else 0.625

# 轻重击标签：伤害打印末尾追加【重击】/【轻击】（战斗系统通过has_method调用）
func zhong_qing_biao_qian() -> String:
	return "【重击】" if ben_ci_zhong else "【轻击】"

# 伤害后特殊技能（战斗系统通过has_method调用，参数为关卡节点；在伤害结算后执行，本次伤害按降防前计算）：
# 重击降低怪物1防御（记录在怪物格子fy_jian字段，对同一只怪物永久累计、上限自身等级×32，撤退不恢复；主线BOSS同步2×2格保持属性一致）；
# 轻击提升自身1防御（fy_add_1，上限自身等级×32，战斗结束清除）
func shang_hai_hou(guan_qia: Node) -> void:
	if ben_ci_zhong:
		var gw_x: int = guan_qia.zhan_dou.guai_wu_x
		var gw_y: int = guan_qia.zhan_dou.guai_wu_y
		if gw_x >= 0 and gw_y >= 0:
			var GZ = guan_qia.GZ
			# 该怪物被永久累计降低的防御量达到自身等级×32上限后不再降低
			if GZ[gw_y][gw_x].get("fy_jian", 0) < guan_qia.helo_lv * 32:
				# 主线BOSS占2×2格需同步降低，诛邪与普通怪物只占1格
				var fan_wei: bool = GZ[gw_y][gw_x].get("BOSS", false)
				var cells = guan_qia.shu_xing.qu_cells(gw_x, gw_y, fan_wei)
				# fy_jian为秤干戚特性专属的降低计数（上限32×自身等级，与其他增减效果互不影响）
				for cell in cells:
					cell["fy_jian"] = cell.get("fy_jian", 0) + 1
				# 防御降低走属性加成模块"秤干戚"来源（贡献 = -累计降低值，永久有效、撤退不恢复）
				guan_qia.shu_xing.she_zhi(cells, "秤干戚", {"fy": -int(GZ[gw_y][gw_x]["fy_jian"])})
	else:
		# 达到自身等级×32上限后不再增加
		if fy_add_1 < guan_qia.helo_lv * 32:
			fy_add_1 += 1

# 战斗结束特殊技能（战斗系统通过has_method调用，参数为战斗系统）：
# 只清除自身防御增幅与首次攻击标记；怪物被降低的防御为永久效果，不恢复
func zhan_dou_end_ji_neng(zd: Node) -> void:
	fy_add_1 = 0
	shou_ci = true
	zd.guan_qia.shu_wu_upd.emit()
