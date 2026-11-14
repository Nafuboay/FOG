# 余烬（照明消耗品）档位配置的唯一来源
# 每档上限合计 85 = 86 个光源槽位 − 1 个英雄夜视槽位，与 关卡/夜晚遮罩.gdshader 的 dian_guang[86] 一致
# 价格不写在本表：统一从 物品信息.get_XX(名)["商店售价"] 读取，避免两处维护
class_name 余烬档位

const 表: Dictionary = {
	"火焰余烬": {
		"半径格": 5.0, "时长": 40.0, "色调": Color(1, 0.2, 0), "上限": 64,
		"上限提示": "火焰太多了，好热！",
		"帧": "res://关卡/余烬/火焰余烬_动画.tres",
		"图标": "res://全局/图片/火焰余烬.png", "序号": 1,
	},
	"爆炸余烬": {
		"半径格": 10.0, "时长": 100.0, "色调": Color(1, 0.6, 0.2), "上限": 16,
		"上限提示": "你不害怕爆炸吗？",
		"帧": "res://关卡/余烬/爆炸余烬_动画.tres",
		"图标": "res://全局/图片/爆炸余烬.png", "序号": 2,
	},
	"流星余烬": {
		"半径格": 20.0, "时长": 250.0, "色调": Color(1, 0.8, 0.6), "上限": 4,
		"上限提示": "流星已经够多了，快来许愿吧！",
		"帧": "res://关卡/余烬/流星余烬_动画.tres",
		"图标": "res://全局/图片/流星余烬.png", "序号": 3,
	},
	"太阳余烬": {
		"半径格": 40.0, "时长": 625.0, "色调": Color(1, 1, 0.8), "上限": 1,
		"上限提示": "世界不希望同时出现两个太阳！",
		"上限提示_无夜": "世界不希望同时出现三个太阳！",
		"帧": "res://关卡/余烬/太阳余烬_动画.tres",
		"图标": "res://全局/图片/太阳余烬.png", "序号": 4,
	},
}

# 取某档配置（未知名返回空字典）
static func qu(ming: String) -> Dictionary:
	return 表.get(ming, {})

# 全部档位名（1~4 档顺序）
static func quan_bu() -> Array:
	return ["火焰余烬", "爆炸余烬", "流星余烬", "太阳余烬"]

# 是否为合法的余烬档位（未知名、半径/时长非法一律 false）
static func shi_yu_jin(ming: String) -> bool:
	var cfg = qu(ming)
	if cfg.is_empty():
		return false
	if float(cfg.get("半径格", 0.0)) <= 0.0 or float(cfg.get("时长", 0.0)) <= 0.0:
		print("余烬档位非法：" + ming)
		return false
	return true

# 达上限提示：太阳按是否存在夜晚遮罩二选一，其余档位返回专属文案
static func shang_xian_ti_shi(ming: String, you_ye_wan: bool) -> String:
	var cfg = qu(ming)
	if cfg.is_empty():
		return ""
	if ming == "太阳余烬":
		return str(cfg.get("上限提示", "")) if you_ye_wan else str(cfg.get("上限提示_无夜", ""))
	return str(cfg.get("上限提示", ""))