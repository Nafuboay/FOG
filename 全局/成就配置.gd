# 成就配置静态模块：成就序号 / 名称 / 图标 / 条件 / 奖励 / 英雄绑定的唯一来源
# Steam 后台 API 映射仍由 全局/Steam管理.gd 的 ACH_API 维护，两边序号必须一致
# 本模块不承担存档迁移或解锁状态持久化职责；英雄可选状态由历史成就实时推导
class_name 成就配置
extends RefCounted

const ACH_DATA: Array = [
	{
		"xu_hao": "0001", "ming": "救世主Ⅰ", "tu_biao": "救世主",
		"tiao_jian": 1, "zhi": 31, "wu_pin": "", "shu_liang": 0,
		"miao_shu": "通关主线", "ying_xiong": "玄戈",
	},
	{
		"xu_hao": "0002", "ming": "救世主Ⅱ", "tu_biao": "救世主",
		"tiao_jian": 1, "zhi": 61, "wu_pin": "", "shu_liang": 0,
		"miao_shu": "通关支线", "ying_xiong": "秤干戚",
	},
	{
		"xu_hao": "1000", "ming": "不朽者", "tu_biao": "不朽者",
		"tiao_jian": 0, "zhi": "破损稻草人", "wu_pin": "朱雀圣像", "shu_liang": 1,
		"miao_shu": "拥有【破损稻草人】", "ying_xiong": "",
	},
	{
		"xu_hao": "1001", "ming": "饮虹使", "tu_biao": "饮虹使",
		"tiao_jian": 0, "zhi": "彩虹", "wu_pin": "彩虹", "shu_liang": 7,
		"miao_shu": "拥有【彩虹】", "ying_xiong": "",
	},
	{
		"xu_hao": "1004", "ming": "采花贼", "tu_biao": "采花贼",
		"tiao_jian": 2, "zhi": "", "wu_pin": "奇花", "shu_liang": 99,
		"miao_shu": "拥有四种奇花", "ying_xiong": "",
	},
	{
		"xu_hao": "0107", "ming": "A7富豪", "tu_biao": "A7",
		"tiao_jian": 3, "zhi": 1000, "wu_pin": "银币", "shu_liang": 1,
		"miao_shu": "拥有1000银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0108", "ming": "A8富豪", "tu_biao": "A8",
		"tiao_jian": 3, "zhi": 10000, "wu_pin": "银币", "shu_liang": 10,
		"miao_shu": "拥有1万银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0109", "ming": "A9富豪", "tu_biao": "A9",
		"tiao_jian": 3, "zhi": 100000, "wu_pin": "银币", "shu_liang": 100,
		"miao_shu": "拥有10万银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0110", "ming": "A10富豪", "tu_biao": "A10",
		"tiao_jian": 3, "zhi": 1000000, "wu_pin": "银币", "shu_liang": 1000,
		"miao_shu": "拥有100万银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0111", "ming": "A11富豪", "tu_biao": "A11",
		"tiao_jian": 3, "zhi": 10000000, "wu_pin": "银币", "shu_liang": 10000,
		"miao_shu": "拥有1000万银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0112", "ming": "A12富豪", "tu_biao": "A12",
		"tiao_jian": 3, "zhi": 100000000, "wu_pin": "银币", "shu_liang": 100000,
		"miao_shu": "拥有1亿银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0113", "ming": "A13富豪", "tu_biao": "A13",
		"tiao_jian": 3, "zhi": 1000000000, "wu_pin": "银币", "shu_liang": 1000000,
		"miao_shu": "拥有10亿银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0114", "ming": "A14富豪", "tu_biao": "A14",
		"tiao_jian": 3, "zhi": 10000000000, "wu_pin": "银币", "shu_liang": 10000000,
		"miao_shu": "拥有100亿银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0115", "ming": "A15富豪", "tu_biao": "A15",
		"tiao_jian": 3, "zhi": 100000000000, "wu_pin": "银币", "shu_liang": 100000000,
		"miao_shu": "拥有1000亿银币", "ying_xiong": "",
	},
	{
		"xu_hao": "0116", "ming": "A16富豪", "tu_biao": "A16",
		"tiao_jian": 3, "zhi": 1000000000000, "wu_pin": "银币", "shu_liang": 1000000000,
		"miao_shu": "拥有1万亿银币", "ying_xiong": "",
	},
]

static func quan_bu() -> Array:
	return ACH_DATA

static func qu(xu_hao: String) -> Dictionary:
	for cfg in ACH_DATA:
		if str(cfg.get("xu_hao", "")) == xu_hao:
			return cfg
	return {}

static func lai_yuan_ying_xiong(ying_xiong: String) -> String:
	if ying_xiong.is_empty():
		return ""
	for cfg in ACH_DATA:
		if str(cfg.get("ying_xiong", "")) == ying_xiong:
			return str(cfg.get("xu_hao", ""))
	return ""

static func you_wu_zhi_jiang_li(cfg: Dictionary) -> bool:
	return not str(cfg.get("wu_pin", "")).is_empty() and int(cfg.get("shu_liang", 0)) > 0

static func he_fa(cfg: Dictionary) -> bool:
	if cfg.is_empty():
		return false
	var xu_hao: String = str(cfg.get("xu_hao", ""))
	if xu_hao.length() != 4 or not xu_hao.is_valid_int():
		return false
	if str(cfg.get("ming", "")).is_empty():
		return false
	if str(cfg.get("tu_biao", "")).is_empty():
		return false
	if str(cfg.get("miao_shu", "")).is_empty():
		return false
	var tiao_jian: int = int(cfg.get("tiao_jian", -1))
	if tiao_jian < 0 or tiao_jian > 3:
		return false
	if int(cfg.get("shu_liang", -1)) < 0:
		return false
	return true