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
	# 清空旧标签
	for child in guan_qia.look_helo.get_children():
		child.queue_free()
	# 计算生命值百分比
	var hp_pct = ji_suan_hp_pct(guan_qia.helo_hp, guan_qia.helo_shp)
	# 获取属性字符串（装备加成 + 战斗临时加成）
	var ll_str = get_str(guan_qia.helo_jc_ll, guan_qia.helo.ll_add_0 + guan_qia.helo.ll_add_1)
	var fy_str = get_str(guan_qia.helo_jc_fy, guan_qia.helo.fy_add_0 + guan_qia.helo.fy_add_1)
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
	var json = get_node("/root/游戏存档")
	var data = json.du_qu(guan_qia.json_id)
	var exp_0 = data.get("经验", 0)
	# 计算升级所需经验和经验占比
	var exp_pct = ji_suan_exp_pct(exp_0, lv)
	# 经验显示文本
	var exp_str = ""
	if exp_pct == 100:
		exp_str = "MAX"
	else:
		exp_str = "%d(%d%%)" % [exp_0, exp_pct]
	# 组装显示文本
	var text = "\n  【英雄】%s\n  【战力】%d\n  【等级】%d\n  【经验】%s\n  【生命】%d/%d（%d%%）
	  【力量】%s\n  【防御】%s\n  【穿透】%s\n  【位置】（%d，%d）" % [
		helo_name, helo_zl, lv, exp_str, guan_qia.helo_hp, guan_qia.helo_shp, hp_pct,
		ll_str, fy_str, ct_str, guan_qia.helo_x, guan_qia.helo_y
	]
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
		var npc_text = "\n  【友方】%s\n  【位置】（%d，%d）\n  【治愈】%d/%d" % [
			npc_name, x + 1, y + 1, npc_hp, npc_hp_max
		]
		C_label(npc_text, guan_qia.look_guai_wu)
		return
	# 点击到障碍：显示障碍信息
	if GZ1.get("zhang_ai", false) == true:
		var zhang_ai_name = GZ1.get("zhang_ai_ming", "魔法树")
		var zhang_ai_lv = GZ1.get("zhang_ai_lv", 1)
		var zhang_ai_text = "\n  【障碍】%s\n  【等级】%d\n  【位置】（%d，%d）\n  【魔化】怪物周围有魔法树，\n  全属性增加，可叠加" % [
			zhang_ai_name, zhang_ai_lv, x + 1, y + 1
		]
		C_label(zhang_ai_text, guan_qia.look_guai_wu)
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
	# 计算生命值百分比
	var hp_pct = ji_suan_hp_pct(hp, shp)
	# 计算战力
	var guai_wu_zl = lv * hp * ll * fy * ct
	# 获取各项属性加成
	var add = GZ1.get("add", 0)  # 魔法树四项属性加成值
	var fy_add_4 = GZ1.get("fy_add_4", 0)  # 重甲防御加成
	var fy_add_5 = GZ1.get("fy_add_5", 0)  # 硬化防御加成
	var fy_add = add + fy_add_4 + fy_add_5
	# 格式化力量显示（基础值+加成）
	var ll_str = str(ll)
	if add > 0:
		ll_str = str(ll - add) + "+" + str(add)
	# 格式化防御显示（基础值+加成）
	var fy_str = str(fy)
	if fy_add > 0:
		fy_str = str(fy - fy_add) + "+" + str(fy_add)
	# 格式化穿透显示（基础值+加成）
	var ct_str = str(ct)
	if add > 0:
		ct_str = str(ct - add) + "+" + str(add)
	# 获取怪物描述
	var guai_wu_miao_shu = GZ1.get("miao_shu", "")
	var miao_shu_str = ""
	if guai_wu_miao_shu != "":
		miao_shu_str = "\n  %s" % [guai_wu_miao_shu]
	# 组装显示文本
	var text = "\n  【怪物】%s\n  【战力】%d\n  【等级】%d\n  【生命】%d/%d（%d%%）\n  【力量】%s\n  【防御】%s\n  【穿透】%s\n  【位置】（%d，%d）%s" % [
		guai_wu_name, guai_wu_zl, lv, hp, shp, hp_pct, ll_str, fy_str, ct_str, x1 + 1, y1 + 1, miao_shu_str
	]
	# 创建标签
	C_label(text, guan_qia.look_guai_wu)

# 刷新信息面板
func on_shu_wu_upd() -> void:
	# 刷新人物面板
	look_helo_upd()
	# 更新人物血条显示
	guan_qia.zhan_dou.xue_tiao_upd_1()
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
	label.text = text
	label.position = Vector2(0,0)
	label.add_theme_color_override("font_color", Color.BLACK)
	# 设置楷体字体
	kai_ti(label)
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
	if lv != 1 and lv != 2 and lv != 3:
		return 100
	var exp_need = 13271040 if lv == 1 else (100776960 if lv == 2 else 424673280)
	var exp_pct = int(round(float(exp_0) / exp_need * 100))
	if exp_0 > 0 and exp_pct < 1:
		exp_pct = 1
	if exp_0 < exp_need and exp_pct > 99:
		exp_pct = 99
	return exp_pct

# 获取属性字符串
func get_str(ji_chu: int, add: int) -> String:
	if add > 0:
		return str(ji_chu) + "+" + str(add)
	elif add == 0:
		return str(ji_chu)
	else:
		return str(ji_chu) + str(add)
