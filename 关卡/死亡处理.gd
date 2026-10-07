# 【死亡处理】战斗中的死亡与胜利结算逻辑（主线与诛邪通用）
# 从战斗系统剥离：人物死亡、怪物死亡（含掉落与胜利判断）、BOSS宝箱生成
# 掉落表本体在掉落物.gd（diao_luo_wu），本文件只负责死亡流程与界面结算
# 与特殊技能.gd同模式：RefCounted持有关卡与战斗系统引用，通过preload路径使用
extends RefCounted

# 关卡节点引用（访问GZ网格、GZs显示、面板、背包、关卡UI等）
var guan_qia: Node2D
# 战斗系统引用（访问战斗状态guai_wu_x/y、guai_wu_ing、zhan_dou_time、结束战斗等）
var zhan_dou: Node

# 初始化：传入关卡节点和战斗系统
func _init(gq: Node2D, zd: Node) -> void:
	guan_qia = gq
	zhan_dou = zd

# 人物死亡统一处理：添加破损稻草人、清除人物、显示失败图片并结束战斗
func helo_si_wang() -> void:
	var shi_jian = (Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0
	print("%.2f秒 英雄死亡\n" % shi_jian)
	# 人物死亡时添加破损稻草人到永久背包
	var json = guan_qia.get_node("/root/游戏存档") if guan_qia.has_node("/root/游戏存档") else null
	if json != null:
		var data = json.du_qu(guan_qia.json_id)
		var bei_bao = data.get("背包", {})
		if bei_bao.has("破损稻草人"):
			bei_bao["破损稻草人"] += 1
		else:
			bei_bao["破损稻草人"] = 1
		data["背包"] = bei_bao
		json.bao_cun(guan_qia.json_id, data)
	var helo = guan_qia.helo
	if helo != null:
		helo.queue_free()
		# 立即清除人物引用
		guan_qia.helo = null
	# 画面变暗并显示失败图片
	guan_qia.modulate = Color(0.5, 0.5, 0.5)
	for c in guan_qia.get_children():
		if c is CanvasLayer:
			for yun in c.get_children():
				yun.modulate = Color(0.5, 0.5, 0.5)
	var shi_bai = TextureRect.new()
	shi_bai.texture = load("res://关卡/信息/失败.png")
	shi_bai.position = Vector2(384, 104)
	shi_bai.z_index = 1000
	guan_qia.add_child(shi_bai)
	# 调用通用结束战斗底层
	zhan_dou.zhan_dou_end()

# 怪物死亡处理
func guai_wu_die() -> void:
	# 记录怪物位置
	var die_x = zhan_dou.guai_wu_x
	var die_y = zhan_dou.guai_wu_y
	# 获取关卡数据引用
	var GZ = guan_qia.GZ
	var GZs = guan_qia.GZs
	var tile_fan_kai = guan_qia.tile_fan_kai
	var tile_shu_zi = guan_qia.tile_shu_zi
	# 打印怪物死亡时间
	var shi_jian = (Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0
	print("%.2f秒 怪物死亡" % shi_jian)
	# 计算掉落并显示弹幕
	var diao_luo_ing = 掉落物.diao_luo_wu(guan_qia, die_x, die_y)
	# 在背包中显示掉落的物品
	guan_qia.get_node("背包").xian_shi_wu_pin(guan_qia.BB_ls)
	for wu_ming in diao_luo_ing:
		var n = diao_luo_ing[wu_ming]
		提示弹幕.wen_ben("获得【" + wu_ming + "】×" + str(n) + "！", 0)
	# 移除怪物节点
	if zhan_dou.guai_wu_ing != null and is_instance_valid(zhan_dou.guai_wu_ing):
		zhan_dou.guai_wu_ing.queue_free()
		await zhan_dou.get_tree().create_timer(0.05).timeout
	# 移除格子怪物数据
	GZ[die_y][die_x]["guai_wu"] = false
	# 如果是BOSS，同步属性到其他3个格子，然后清除BOSS标记
	if GZ[die_y][die_x]["BOSS"] == true:
		var boss_hp = GZ[die_y][die_x]["hp"]
		var boss_shp = GZ[die_y][die_x]["shp"]
		for ny in range(die_y, die_y + 2):
			for nx in range(die_x, die_x + 2):
				if ny == die_y and nx == die_x:
					continue
				GZ[ny][nx]["hp"] = boss_hp
				GZ[ny][nx]["shp"] = boss_shp
		# 清除BOSS标记
		for ny in range(die_y, die_y + 2):
			for nx in range(die_x, die_x + 2):
				GZ[ny][nx]["BOSS"] = false
		# BOSS宝箱
		C_BX(die_x, die_y)
	# 刷新格子
	guan_qia.shu_zi_n()
	for ny in range(max(0, die_y - 1), min(guan_qia.GZ_y, die_y + 2)):
		for nx in range(max(0, die_x - 1), min(guan_qia.GZ_x, die_x + 2)):
			var GZ2 = GZ[ny][nx]
			if GZ2["fan_kai"] == true:
				if GZ2["shu_zi"] == true:
					GZs[ny][nx].texture = tile_shu_zi[GZ2["number"] - 1]
				elif GZ2["kong_bai"] == true:
					GZs[ny][nx].texture = tile_fan_kai
					guan_qia.fan_kai.flood_fill(nx, ny)
	# 自动排雷、和弦
	guan_qia.fan_kai.pai_lei()
	guan_qia.fan_kai.he_xian()
	# 更新怪物数量
	var n_1 = 0
	var n_4 = 0
	for y in range(guan_qia.GZ_y):
		for x in range(guan_qia.GZ_x):
			var GZ1 = guan_qia.GZ[y][x]
			if GZ1.get("guai_wu", false) == true:
				n_1 += 1
			if GZ1.get("BOSS", false) == true:
				n_4 += 1
	guan_qia.guai_wu_xian = n_1 + int(n_4 / 4.0)
	# 更新怪物数量标签（诛邪模式下可能不存在）
	if guan_qia.guai_wu_lbl != null:
		guan_qia.guai_wu_lbl.text = "怪物数量：" + str(guan_qia.guai_wu_xian) + "/" + str(guan_qia.guai_wu_zong)
	# 怪物死亡类技能（野猪王热血：场上怪物越多生命越高）
	zhan_dou.ji_neng.guai_wu_die_ji_neng()
	# 检查胜利条件：人物存活且怪物数量为0
	if guan_qia.helo_hp > 0 and guan_qia.guai_wu_xian == 0:
		# 诛邪模式下：保存等级并重新进入关卡
		if guan_qia.has_method("_zhu_xie_win"):
			# 先结束战斗状态（重置zhan_dou_ing），防止挂起的攻击协程在场景切换后继续执行导致崩溃
			zhan_dou.zhan_dou_end()
			guan_qia._zhu_xie_win()
			return  # 不执行后续的helo_move等
		# 主线模式：显示胜利UI
		if guan_qia.guan_ui != null:
			guan_qia.guan_ui.C_sheng_li()
	# 怪物死亡特殊：先结束战斗，再清除朝向标记，最后人物移动到该格
	zhan_dou.zhan_dou_end()
	zhan_dou.fan1 = false
	zhan_dou.fan2 = false
	guan_qia.helo_move(die_x, die_y)
	print("%.2f秒 战斗胜利\n" % ((Time.get_ticks_msec() - zhan_dou.zhan_dou_time) / 1000.0))

# BOSS死亡后生成宝箱
func C_BX(boss_x: int, boss_y: int) -> void:
	var n_x = boss_x
	var n_y = boss_y + 1
	# 检查目标格子是否有效
	if n_x < 0 or n_x >= guan_qia.GZ_x or n_y < 0 or n_y >= guan_qia.GZ_y:
		return
	# 获取BOSS名称
	var boss_ming = guan_qia.GZ[boss_y][boss_x].get("名字", "")
	# 创建宝箱节点
	var n = Sprite2D.new()
	n.name = "BOSS宝箱"
	# 加载宝箱图片
	n.texture = load("res://关卡/信息/宝箱.png")
	# 计算宝箱位置（格子中心往上偏10像素）
	var GZ_z = guan_qia.GZ_zhong(n_x,n_y)
	n.position = GZ_z - Vector2(0, 10)
	# 设置层级：与该格子层级一致
	n.z_index = (guan_qia.GZ_x - n_x) + n_y * guan_qia.GZ_y
	# 添加到游戏容器
	guan_qia.rong_qi.add_child(n)
	# 在格子数据中标记有宝箱、宝箱名称和开启次数
	guan_qia.GZ[n_y][n_x]["BX"] = true
	guan_qia.GZ[n_y][n_x]["BX_id"] = boss_ming
	guan_qia.GZ[n_y][n_x]["BX_n"] = 0
