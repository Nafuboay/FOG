# 余烬燃烧实体系统：放置校验 / 计时 / 1Hz 半径 / 动画缩放 / 层级 / 光源清单
# 不注册 class_name，由 关卡基类 通过 preload 创建（避免全局类与关卡基类循环引用）
# 生命周期 = 当前关卡场景；位置与计时均不写存档，只在放置成功时扣减背包并保存
extends Node

# 光源槽位上限：1 个英雄夜视 + 85 个余烬（各档上限合计）
const 最大光源: int = 86

var guan_qia: Node2D = null
# 燃烧实体表：{名, 格(Vector2i, 0基), 已烧, 整秒, 半径格, 节点, 放置序}
var 实体表: Array = []
# 预分配光源数组（供支线读取，避免每帧新建）
var guang_yuan_huan: PackedVector4Array = PackedVector4Array()
# 放置顺序（用于 shader 后放者优先）
var 放置序: int = 0

func _init(gq: Node2D) -> void:
	guan_qia = gq
	guang_yuan_huan.resize(最大光源)
	for i in range(最大光源):
		guang_yuan_huan[i] = Vector4.ZERO

# 默认格层级（与英雄同一套公式：左侧高于右侧、下方高于上方）
func _mo_ren_z(ge: Vector2i) -> int:
	return (guan_qia.GZ_x - ge.x) + ge.y * guan_qia.GZ_y

# 动画播放速度跟随项目设置（基础帧率/60×倍率），取不到存档时回落 0.4（=24fps）
func _dong_hua_su_du() -> float:
	var json = get_node_or_null("/root/游戏存档")
	if json != null and json.has_method("get_dong_hua_su_du"):
		return json.get_dong_hua_su_du()
	return 0.4

# 创建燃烧实体（动画节点），成功返回 true
func 建实体(ming: String, ge: Vector2i) -> bool:
	var cfg = 余烬档位.qu(ming)
	if cfg.is_empty():
		return false
	var frames = load(str(cfg["帧"]))
	if frames == null:
		日志.打印("余烬帧资源缺失：" + ming)
		return false
	var sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.speed_scale = _dong_hua_su_du()
	sprite.centered = true
	sprite.position = guan_qia.GZ_zhong(ge.x, ge.y)
	sprite.scale = Vector2(1.5, 1.5)
	# 放置瞬间英雄必在同格 → 先 +1 盖住英雄；离开后由 _process 回落默认层级
	sprite.z_index = _mo_ren_z(ge) + 1
	sprite.play(&"燃")
	# 加到地图容器（Node2D），不是 Control，避免被 GUI 点击检测拦截
	guan_qia.rong_qi.add_child(sprite)
	放置序 += 1
	实体表.append({
		"名": ming,
		"格": ge,
		"已烧": 0.0,
		"整秒": 0,
		"半径格": float(cfg["半径格"]),
		"节点": sprite,
		"放置序": 放置序,
	})
	return true

# 每帧推进：计时 / 连续缩放 / 1Hz 半径 / 层级
func _process(delta: float) -> void:
	var i: int = 实体表.size() - 1
	while i >= 0:
		var e: Dictionary = 实体表[i]
		var cfg = 余烬档位.qu(str(e["名"]))
		if cfg.is_empty():
			实体表.remove_at(i)
			i -= 1
			continue
		var T: float = float(cfg["时长"])
		e["已烧"] = clamp(float(e["已烧"]) + delta, 0.0, T)
		var t: float = float(e["已烧"])
		var k: float = sqrt(max(0.0, 1.0 - t / T))
		var node = e["节点"]
		if is_instance_valid(node):
			# 动画尺寸按面积连续缩小（每帧）
			node.scale = Vector2(1.5, 1.5) * k
			# 层级：异格沿用默认格排序，仅同格 +1 盖住英雄
			var ge: Vector2i = e["格"]
			var tong_ge := false
			if guan_qia.helo != null:
				tong_ge = Vector2i(guan_qia.helo_x - 1, guan_qia.helo_y - 1) == ge
			node.z_index = _mo_ren_z(ge) + (1 if tong_ge else 0)
		# 光照半径每秒只更新一次（整秒采样；第 0~1 秒保持满半径）
		var zheng: int = int(floor(t))
		if zheng != int(e["整秒"]):
			e["整秒"] = zheng
			e["半径格"] = float(cfg["半径格"]) * sqrt(max(0.0, 1.0 - float(zheng) / T))
		# 燃尽移除
		if t >= T:
			if is_instance_valid(node):
				node.queue_free()
			日志.打印("余烬燃尽：" + str(e["名"]) + " " + _ge_zi(e["格"]) + " 燃烧%.2f秒" % T)
			实体表.remove_at(i)
		i -= 1

# 输出当前所有余烬光源（屏幕坐标 / 半径px / 色板下标），按放置序升序
func guang_yuan_ming_dan(ge_ju: float, hua_bu: Transform2D) -> PackedVector4Array:
	var out := PackedVector4Array()
	for e in 实体表:
		var cfg = 余烬档位.qu(str(e["名"]))
		if cfg.is_empty():
			continue
		var r_px: float = float(e["半径格"]) * ge_ju
		if r_px <= 0.0:
			continue
		var ge: Vector2i = e["格"]
		var p: Vector2 = hua_bu * guan_qia.rong_qi.to_global(guan_qia.GZ_zhong(ge.x, ge.y))
		out.append(Vector4(p.x, p.y, r_px, float(cfg["序号"])))
		# 预留 1 个槽位给英雄夜视
		if out.size() >= 最大光源 - 1:
			日志.打印("余烬光源超出槽位上限，已截断")
			break
	return out

# 清空全部余烬（胜利/失败/重开时调用）；幂等
func quan_bu_qing_li() -> void:
	for e in 实体表:
		var node = e["节点"]
		if is_instance_valid(node):
			node.queue_free()
	实体表.clear()
	for i in range(guang_yuan_huan.size()):
		guang_yuan_huan[i] = Vector4.ZERO

# 放置入口：0=成功 1=无库存/异常 2=战斗中 3=同格占用 4=该档达上限 5=保存/资源失败
func fang_zhi(ming: String) -> int:
	var json = get_node_or_null("/root/游戏存档")
	if json == null:
		return 1
	var data = json.du_qu(json.id)
	if data.is_empty():
		return 1
	var bag = data.get("背包", {})
	if not bag.has(ming) or int(bag[ming]) <= 0:
		return 1
	# 战斗中/撤退中禁止放置，不扣道具
	var zd = guan_qia.zhan_dou
	if zd != null and (zd.zhan_dou_ing or zd.che_tui_ing):
		提示弹幕.wen_ben(tr("战斗中无法使用【%s】！") % tr(ming), 0)
		return 2
	# 英雄必须存在且格坐标合法
	if guan_qia.helo == null:
		return 1
	var ge := Vector2i(guan_qia.helo_x - 1, guan_qia.helo_y - 1)
	if ge.x < 0 or ge.y < 0 or ge.x >= guan_qia.GZ_x or ge.y >= guan_qia.GZ_y:
		return 1
	# 同一格只能 1 个余烬
	for e in 实体表:
		if e["格"] == ge:
			提示弹幕.wen_ben(tr("你该把余烬放在不同的地方！"), 0)
			日志.打印("余烬拒绝：" + ming + " " + _ge_zi(ge) + " 原因=同格占用")
			return 3
	# 各档独立场上数量上限
	var cfg = 余烬档位.qu(ming)
	var n := 0
	for e in 实体表:
		if e["名"] == ming:
			n += 1
	if n >= int(cfg.get("上限", 0)):
		var you_ye: bool = guan_qia.has_method("ye_wan_wu") and guan_qia.ye_wan_wu()
		提示弹幕.wen_ben(tr(余烬档位.shang_xian_ti_shi(ming, you_ye)), 0)
		日志.打印("余烬拒绝：" + ming + " " + _ge_zi(ge) + " 原因=该档达上限")
		return 4
	# 扣背包并保存（与探测器一致：只写背包数量）
	bag[ming] = int(bag[ming]) - 1
	if int(bag[ming]) <= 0:
		bag.erase(ming)
	data["背包"] = bag
	if not json.bao_cun(json.id, data):
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		日志.打印("余烬放置失败：存档写入失败 " + ming)
		return 5
	# 建实体；失败则回滚背包
	if not 建实体(ming, ge):
		var data2 = json.du_qu(json.id)
		var bag2 = data2.get("背包", {})
		bag2[ming] = int(bag2.get(ming, 0)) + 1
		data2["背包"] = bag2
		json.bao_cun(json.id, data2)
		提示弹幕.wen_ben(tr("保存失败，请稍后重试"), 0)
		return 5
	# 成功提示与刷新
	提示弹幕.wen_ben(tr("使用【%s】，照亮周围%d格，持续%d秒！") % [tr(ming), int(cfg["半径格"]), int(cfg["时长"])], 0)
	guan_qia.guan_ui.dao_ju_upd()
	日志.打印("余烬放置：" + ming + " " + _ge_zi(ge) + " %.2f秒" % float(cfg["时长"]))
	return 0

# 1 基格坐标文本 "(x,y)"
func _ge_zi(ge: Vector2i) -> String:
	return "(%d,%d)" % [ge.x + 1, ge.y + 1]