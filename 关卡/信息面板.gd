class_name 信息面板 extends Node
# 父节点引用
var guan_qia: Node
# 背景图资源
var kuai: Texture2D

# 获取父节点
func _ready() -> void:
	var parent = get_parent()
	# 父节点不是关卡基类时向上查找（兼容诛邪等子类场景）
	if not (parent is 关卡基类):
		parent = parent.get_parent()
	guan_qia = parent
	# 预加载背景图
	kuai = load("res://关卡/信息/模块背景.png")

# 创建信息面板
func C_look_helo() -> void:
	# 如果面板已存在则不创建
	if guan_qia.look_helo != null:
		return
	# 获取视口高度（逻辑分辨率）
	var viewport_size = guan_qia.get_viewport_rect().size
	# 创建人物面板（左侧）
	var kuai_1 = C_kuai(true, viewport_size.y)
	guan_qia.add_child(kuai_1)
	guan_qia.kuai_1 = kuai_1
	# 创建文字显示面板
	guan_qia.look_helo = C_wen_ben(true, viewport_size.y)
	guan_qia.add_child(guan_qia.look_helo)
	# 初始隐藏人物面板
	kuai_1.visible = false
	guan_qia.look_helo.visible = false
	# 初始化面板内容
	look_helo_upd()

# 刷新人物信息面板
func look_helo_upd() -> void:
	# 如果面板不存在则跳过
	if guan_qia.look_helo == null:
		return
	# 人物节点已移除（如死亡流程置空）时跳过，防止访问空实例
	if guan_qia.helo == null or not is_instance_valid(guan_qia.helo):
		return
	# 本节点已不在场景树中（如场景切换瞬间收到刷新信号）时跳过
	if not is_inside_tree():
		return
	# 清空旧标签
	for child in guan_qia.look_helo.get_children():
		child.queue_free()
	# 计算生命值百分比
	var hp_pct = ji_suan_hp_pct(guan_qia.helo_hp, guan_qia.helo_shp)
	# 获取属性字符串（装备加成 + 战斗临时加成 + 玄武盾符临时防御加成）
	var ll_str = get_str(guan_qia.helo_jc_ll, guan_qia.helo.ll_add_0 + guan_qia.helo.ll_add_1)
	var fy_str = get_str(guan_qia.helo_jc_fy, guan_qia.helo.fy_add_0 + guan_qia.helo.fy_add_1 + guan_qia.helo.fy_add_2)
	var ct_str = get_str(guan_qia.helo_jc_ct, guan_qia.helo.ct_add_0 + guan_qia.helo.ct_add_1)
	# 获取计算后的属性值
	var ll_upd = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ll, "ll")
	var fy_upd = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_fy, "fy")
	var ct_upd = guan_qia.helo.shu_xing_upd(guan_qia.helo_jc_ct, "ct")
	# 计算战力
	var helo_zl = guan_qia.helo_lv * guan_qia.helo_hp * ll_upd * fy_upd * ct_upd
	# 获取人物名称
	var helo_name = guan_qia.helo.get_name() if guan_qia.helo else "未知"
	# 获取当前等级和经验
	var lv = guan_qia.helo_lv
	# 获取存档节点（与战斗系统保护模式一致，防止场景切换瞬间空实例崩溃）
	var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
	if json == null:
		return
	var data = json.du_qu(guan_qia.json_id)
	var exp_0 = data.get("经验", 0)
	# 计算升级所需经验和经验占比
	var exp_pct = ji_suan_exp_pct(exp_0, lv)
	# 经验显示文本（数字参照战力格式化，百分比与满级MAX不变）
	var exp_str = ""
	if exp_pct == 100:
		exp_str = "MAX"
	else:
		# 升到下一级的累计经验需求，显示为 当前/所需(百分比)
		var exp_need = 游戏存档.get_exp_need(lv + 1)
		exp_str = "%s/%s(%d%%)" % [ge_shi_zl(exp_0), ge_shi_zl(exp_need), exp_pct]
	# 组装显示文本
	var text = "\n" + tr("【英雄】") + tr(helo_name)
	text += "\n" + tr("【战力】") + ge_shi_zl(helo_zl)
	text += "\n" + tr("【等级】") + str(lv)
	text += "\n" + tr("【经验】") + exp_str
	text += "\n" + tr("【生命】") + tr("%d/%d（%d%%）") % [guan_qia.helo_hp, guan_qia.helo_shp, hp_pct]
	text += "\n" + tr("【力量】") + ll_str
	text += "\n" + tr("【防御】") + fy_str
	text += "\n" + tr("【穿透】") + ct_str
	text += "\n" + tr("【位置】") + tr("（%d，%d）") % [guan_qia.helo_x, guan_qia.helo_y]
	# 创建标签
	C_label(text, guan_qia.look_helo)

# 查看怪物属性
func look(is_helo: bool, x: int = 0, y: int = 0, x1: int = -1, y1: int = -1) -> void:
	if is_helo:
		look_helo_upd()
		return
	# 如果没有指定显示位置，默认使用传入的位置
	if x1 == -1:
		x1 = x
		y1 = y
	var GZ1 = guan_qia.GZ[y][x]
	# 怪物面板不存在则创建
	if guan_qia.look_guai_wu == null:
		# 获取视口尺寸（逻辑分辨率）
		var viewport_size = guan_qia.get_viewport_rect().size
		# 创建怪物面板（右侧）
		var kuai_2 = C_kuai(false, viewport_size.y, viewport_size.x)
		guan_qia.add_child(kuai_2)
		guan_qia.kuai_2 = kuai_2
		# 创建文字显示面板
		guan_qia.look_guai_wu = C_wen_ben(false, viewport_size.y, viewport_size.x)
		guan_qia.add_child(guan_qia.look_guai_wu)
	# 记录当前查看的怪物坐标
	guan_qia.guai_wu_x_ing = x
	guan_qia.guai_wu_y_ing = y
	# 清空旧内容
	for child in guan_qia.look_guai_wu.get_children():
		child.queue_free()
	# 点击到NPC：显示NPC信息
	if GZ1.get("NPC", false) == true:
		var npc_name = GZ1.get("NPC_id", "花精灵·沙华")
		var npc_hp = GZ1.get("NPC_hp", 0)
		var npc_hp_max = guan_qia.guan_kia_id + 1
		var npc_text = "\n" + tr("【友方】") + tr(npc_name)
		npc_text += "\n" + tr("【位置】") + tr("（%d，%d）") % [x + 1, y + 1]
		npc_text += "\n" + tr("【治愈】") + tr("%d/%d") % [npc_hp, npc_hp_max]
		C_label(npc_text, guan_qia.look_guai_wu)
		return
	# 点击到障碍：显示障碍信息
	if GZ1.get("zhang_ai", false) == true:
		var zhang_ai_name = GZ1.get("zhang_ai_ming", "魔法树")
		var zhang_ai_lv = GZ1.get("zhang_ai_lv", 1)
		var zhang_ai_text = "\n" + tr("【障碍】") + tr(zhang_ai_name)
		zhang_ai_text += "\n" + tr("【等级】") + str(zhang_ai_lv)
		zhang_ai_text += "\n" + tr("【位置】") + tr("（%d，%d）") % [x + 1, y + 1]
		zhang_ai_text += "\n" + tr("【魔化】") + tr("加强周围怪物")
		C_label(zhang_ai_text, guan_qia.look_guai_wu)
		return
	# 点击到奇花：显示奇花信息面板
	if GZ1.get("hua", false) == true:
		var hua_name = GZ1.get("hua_id", "")
		var hua_text = "\n" + tr("【奇花】") + tr(hua_name)
		hua_text += "\n" + tr("【等级】") + "4"
		hua_text += "\n" + tr("【位置】") + tr("（%d，%d）") % [x + 1, y + 1]
		hua_text += "\n" + tr("【香氛】") + tr("加强周围怪物")
		C_label(hua_text, guan_qia.look_guai_wu)
		return
	# 点击到怪物：显示怪物信息
	# 获取怪物属性
	var shp: int
	var hp: int
	var lv: int
	var ll: int
	var fy: int
	var ct: int
	var guai_wu_name: String
	var si_wang_key = "%d,%d" % [x, y]
	# 如果怪物已死亡，使用死亡时的属性
	if guan_qia.guai_wu_si_wang.has(si_wang_key):
		var si_wang_data = guan_qia.guai_wu_si_wang[si_wang_key]
		shp = si_wang_data["shp"]
		hp = si_wang_data["hp"]
		lv = si_wang_data["lv"]
		ll = si_wang_data["ll"]
		fy = si_wang_data["fy"]
		ct = si_wang_data["ct"]
		guai_wu_name = si_wang_data["名字"]
	else:
		shp = GZ1["shp"]
		hp = GZ1["hp"]
		lv = GZ1["lv"]
		ll = GZ1["ll"]
		fy = GZ1["fy"]
		ct = GZ1["ct"]
		guai_wu_name = GZ1.get("名字", "未知")
	# 四项属性最低为1（当前生命hp不受此限）；ll/fy/ct钳制前保留原始值用于拆分显示
	var ll_yuan: int = ll
	var fy_yuan: int = fy
	var ct_yuan: int = ct
	shp = max(1, shp)
	ll = max(1, ll)
	fy = max(1, fy)
	ct = max(1, ct)
	# 计算生命值百分比
	var hp_pct = ji_suan_hp_pct(hp, shp)
	# 计算战力
	var guai_wu_zl = lv * hp * ll * fy * ct
	# 格式化力量/防御/穿透显示（初始值±变化值：变化值为所有增益与降低的总和，各效果的规则与上限互不影响、独立累计）
	var ll_str = ge_shi_sx(ll_yuan, GZ1.get("ll_bian", 0))
	var fy_str = ge_shi_sx(fy_yuan, GZ1.get("fy_bian", 0))
	var ct_str = ge_shi_sx(ct_yuan, GZ1.get("ct_bian", 0))
	# 获取怪物描述
	var guai_wu_miao_shu = GZ1.get("miao_shu", "")
	var miao_shu_str = ""
	if guai_wu_miao_shu != "":
		miao_shu_str = "\n%s" % [tr(guai_wu_miao_shu)]
	# 组装显示文本
	var text = "\n" + tr("【怪物】") + tr(guai_wu_name)
	text += "\n" + tr("【战力】") + ge_shi_zl(guai_wu_zl)
	text += "\n" + tr("【等级】") + str(lv)
	text += "\n" + tr("【生命】") + tr("%d/%d（%d%%）") % [hp, shp, hp_pct]
	text += "\n" + tr("【力量】") + ll_str
	text += "\n" + tr("【防御】") + fy_str
	text += "\n" + tr("【穿透】") + ct_str
	text += "\n" + tr("【位置】") + tr("（%d，%d）") % [x1 + 1, y1 + 1]
	text += miao_shu_str
	# 创建标签
	C_label(text, guan_qia.look_guai_wu)

# 格式化属性显示：初始值±变化值（变化值为正显示+n、为负显示-m、为零只显示初始值；初始值=原始总值-变化值）
func ge_shi_sx(yuan: int, bian: int) -> String:
	var ji_chu: int = yuan - bian
	if bian > 0:
		return str(ji_chu) + "+" + str(bian)
	elif bian < 0:
		return str(ji_chu) + str(bian)  # 负数自带负号
	return str(ji_chu)

# 刷新信息面板
func on_shu_wu_upd() -> void:
	# 刷新人物面板
	look_helo_upd()
	# 更新人物血条显示（血条逻辑在血条飘字.gd）
	guan_qia.zhan_dou.xue_tiao_qi.xue_tiao_upd_1()
	# 刷新当前查看的怪物面板
	if guan_qia.guai_wu_x_ing >= 0 and guan_qia.guai_wu_y_ing >= 0:
		look(false, guan_qia.guai_wu_x_ing, guan_qia.guai_wu_y_ing)

# 创建九宫格背景
func C_kuai(left: bool, win_y: int, win_x: int = 0) -> NinePatchRect:
	var kuai_bg = NinePatchRect.new()
	kuai_bg.texture = kuai
	kuai_bg.patch_margin_left = 25
	kuai_bg.patch_margin_right = 25
	kuai_bg.patch_margin_top = 25
	kuai_bg.patch_margin_bottom = 25
	var shu_wu_x = 256
	var shu_wu_y = 512
	if left:
		kuai_bg.position = Vector2(32, int((win_y - shu_wu_y) / 2.0))
	else:
		kuai_bg.position = Vector2(win_x - shu_wu_x - 32, int((win_y - shu_wu_y) / 2.0))
	kuai_bg.size = Vector2(shu_wu_x, shu_wu_y)
	kuai_bg.z_index = 1000
	return kuai_bg

# 创建文本
func C_wen_ben(left: bool, win_y: int, win_x: int = 0) -> Control:
	var wen_ben = Control.new()
	var shu_wu_x = 256
	var shu_wu_y = 512
	if left:
		wen_ben.position = Vector2(32, int((win_y - shu_wu_y) / 2.0))
	else:
		wen_ben.position = Vector2(win_x - shu_wu_x - 32, int((win_y - shu_wu_y) / 2.0))
	wen_ben.size = Vector2(shu_wu_x, shu_wu_y)
	wen_ben.z_index = 1000
	return wen_ben

# 文字显示
func C_label(text: String, parent: Control) -> void:
	var label = Label.new()
	# AUTOWRAP_WORD_SMART：英文按词断行不拆词；中文靠排版工具.pai_ban_wen_ben 在字间插 ZWSP 提供断点
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 面板宽高（与C_kuai/C_wen_ben一致）；左边距16px提供统一缩进，文本内不再用空格缩进
	var shu_wu_x = 256
	var shu_wu_y = 512
	label.position = Vector2(16, 0)
	label.size = Vector2(shu_wu_x - 32, shu_wu_y - 32)
	label.add_theme_color_override("font_color", Color.BLACK)
	# 设置楷体字体
	kai_ti(label)
	# 排版预处理：插 ZWSP/WJ 实现 CJK 禁则断行，最后设置 text 确保 autowrap 按 size 换行
	label.text = 排版工具.pai_ban_wen_ben(text)
	parent.add_child(label)

# 设置Label使用楷体字体（加粗）
func kai_ti(label: Label) -> void:
	# 使用全局缓存的楷体字体
	var font_file = 提示弹幕.get_kai_ti_font()
	if font_file != null:
		label.add_theme_font_override("font", font_file)

# 计算生命值百分比
func ji_suan_hp_pct(hp: int, shp: int) -> int:
	var hp_pct = round(float(hp) / shp * 100)
	if hp > 0 and hp_pct < 1:
		hp_pct = 1
	if hp < shp and hp_pct > 99:
		hp_pct = 99
	return hp_pct

# 计算经验百分比
func ji_suan_exp_pct(exp_0: int, lv: int) -> int:
	# 已达最高等级，显示MAX
	if lv >= 游戏存档.MAX_LV:
		return 100
	# 升到下一级所需的累计经验（统一由游戏存档公式计算）
	var exp_need = 游戏存档.get_exp_need(lv + 1)
	var exp_pct = int(round(float(exp_0) / exp_need * 100))
	if exp_0 > 0 and exp_pct < 1:
		exp_pct = 1
	if exp_0 < exp_need and exp_pct > 99:
		exp_pct = 99
	return exp_pct

# 获取属性字符串（基础值+加成）
# 最终值最低为1：加成为负且会扣到1以下时，按实际生效量显示
func get_str(ji_chu: int, add: int) -> String:
	if add == 0:
		return str(max(1, ji_chu))
	# 加成钳制：保证 基础+加成 不小于1
	add = max(add, 1 - ji_chu)
	if add > 0:
		return str(ji_chu) + "+" + str(add)
	else:
		return str(ji_chu) + str(add)

# 格式化战力显示（按当前语言缩写：中文万/亿，英文K/M/G；1万亿以上科学计数法）
func ge_shi_zl(zl: int) -> String:
	# 达到1万亿（含）使用科学计数法，固定保留3位小数（去尾法）
	if zl >= 1000000000000:
		# 指数为数字位数减1；系数取最高位及后三位数字，字符串截取天然去尾且无浮点误差
		var s = str(zl)
		var zhi_shu = s.length() - 1
		var xi_str = "%s.%s" % [s.substr(0, 1), s.substr(1, 3)]
		return "%s×10^%d" % [xi_str, zhi_shu]
	# 其余交给全局数字缩写（单位与除数按当前语言切换）
	return 排版工具.shu_zi_suo_xie(zl)
