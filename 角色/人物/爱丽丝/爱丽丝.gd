class_name 爱丽丝 extends "res://角色/人物基类.gd"

const LV: int = 1
const HP: int = 6
const LL: int = 8
const FY: int = 6
const CT: int = 9

# 本场战斗涅槃已成功触发次数（每场战斗重置，作为概率分母递增）
var nie_pan_ci_shu: int = 0

# 战斗结束特殊技能：生命回满并重置涅槃次数（战斗系统通过has_method调用，参数为战斗系统）
func zhan_dou_end_ji_neng(zd: Node) -> void:
	var hui_fu_zhi = zd.guan_qia.helo_shp - zd.guan_qia.helo_hp
	zd.hui_fu(0, 0, hui_fu_zhi, true)
	zd.guan_qia.shu_wu_upd.emit()
	nie_pan_ci_shu = 0

# 涅槃：受常规伤害后0.2秒（约每回合0.4秒）按概率回满血
# 概率=(最大生命-结算时当前生命)×本次常规伤害÷最大生命²÷(已触发次数+1)
# 结算时当前生命取0.2秒后实际值（期间真伤如实计入），但本次伤害只计常规伤害，真伤不调用本方法
func nie_pan_pan_ding(zd: Node, ben_ci_shang_hai: int) -> void:
	await zd.get_tree().create_timer(0.2).timeout
	# 场景已切换/释放中时终止协程
	if not zd.is_inside_tree():
		return
	# 战斗已结束（撤退等）时不判定
	if not zd.zhan_dou_ing:
		return
	# 人物已更换、已释放或已死亡（含0.2秒内被真伤击杀、战斗已结束）时不判定
	if zd.guan_qia.helo != self or not is_instance_valid(self) or zd.guan_qia.helo_hp <= 0:
		return
	var sheng_ming: int = zd.guan_qia.helo_shp
	var dang_qian_sheng_ming: int = zd.guan_qia.helo_hp
	var ci_shu: int = nie_pan_ci_shu + 1
	# 已损生命比例与本次伤害比例（均相对最大生命）
	var sun_shi_bi: float = float(sheng_ming - dang_qian_sheng_ming) / sheng_ming
	var shang_hai_bi: float = float(ben_ci_shang_hai) / sheng_ming
	# 涅槃概率=已损生命比例×本次伤害比例÷次数
	var gai_lv: float = sun_shi_bi * shang_hai_bi / ci_shu
	var shi_jian = (Time.get_ticks_msec() - zd.zhan_dou_time) / 1000.0
	# 概率判定
	if randf() < gai_lv:
		var hui_fu_zhi: int = sheng_ming - dang_qian_sheng_ming
		print("%.2f秒 涅槃概率：%.2f%%=%.2f%%×%.2f%%÷%d=(%d-%d)×%d÷%d^2÷%d，涅槃成功，恢复%d生命" % [shi_jian, gai_lv * 100, sun_shi_bi * 100, shang_hai_bi * 100, ci_shu, sheng_ming, dang_qian_sheng_ming, ben_ci_shang_hai, sheng_ming, ci_shu, hui_fu_zhi])
		# 走统一恢复流程（含血条刷新与绿色恢复飘字）
		zd.hui_fu(0, 0, hui_fu_zhi, true)
		zd.guan_qia.shu_wu_upd.emit()
		nie_pan_ci_shu += 1
	else:
		print("%.2f秒 涅槃概率：%.2f%%=%.2f%%×%.2f%%÷%d=(%d-%d)×%d÷%d^2÷%d，本次未触发" % [shi_jian, gai_lv * 100, sun_shi_bi * 100, shang_hai_bi * 100, ci_shu, sheng_ming, dang_qian_sheng_ming, ben_ci_shang_hai, sheng_ming, ci_shu])
