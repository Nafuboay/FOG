# 商店系统
extends "res://全局/背包.gd"
# 操作按钮图片（购买按钮）
var cao_zuo_png0: Texture2D
var cao_zuo_png1: Texture2D
# NPC节点引用
var npc1: Node2D = null
# 背包引用
var BB: Control = null
# 强化引用
var QH: Control = null

# 商店固定出售的物品列表（商店特有）
var shop_wu: Array[String] = [
	"1级经验星","2级经验星","3级经验星","4级经验星","5级经验星","6级经验星","钥匙",
	"1级恢复符","2级恢复符","3级恢复符","4级恢复符","1级探测器","2级探测器","魔核",
	"魔王核","金条"
]

# 初始化商店
func _ready() -> void:
	# 调用父类初始化
	super._ready()
	# 设置为商店模式
	is_shop = true
	# 加载商店特有资源
	wen_ben_png = load("res://全局/图片/商店文本.png")
	# 加载购买按钮图片（操作按钮图片）
	cao_zuo_png0 = load("res://全局/图片/购买0.png")
	cao_zuo_png1 = load("res://全局/图片/购买1.png")
	# 创建界面背景和文字（调用父类通用方法）
	Bg(wen_ben_png)

# 打开/关闭商店
func btn_BB() -> void:
	BB_on = !BB_on
	BB_n.visible = BB_on
	if BB_on:
		BB_n_xy()
		S_upd()
		# 显示银币图标和数值
		if S_lbl != null:
			S_lbl.visible = true
		if S != null:
			S.visible = true
		# 显示商店物品
		display_shop_items()
		# 隐藏背包按钮
		if BB != null:
			BB.BB_btn.visible = false
		# 隐藏背包的银币显示
		if BB != null and BB.S_lbl != null:
			BB.S_lbl.visible = false
		if BB != null and BB.S != null:
			BB.S.visible = false
		# 关闭强化界面（如果打开）
		if QH != null and QH.QH_on:
			QH.QH_On1()
	if not BB_on:
		GZ_ing = -1
		for ge in GZ:
			ge.texture = GZ_png1
		wu_pin_XX_0()
		# 隐藏银币图标和数值
		if S_lbl != null:
			S_lbl.visible = false
		if S != null:
			S.visible = false
		# 恢复背包按钮显示
		if BB != null:
			BB.BB_btn.visible = true
		# 恢复背包的银币显示
		if BB != null and BB.S_lbl != null:
			BB.S_lbl.visible = true
		if BB != null and BB.S != null:
			BB.S.visible = true
	get_tree().call_group("BB_3", "BB_4", BB_on)

# 显示商店物品
func display_shop_items() -> void:
	# 构建商店物品字典（数量始终为1）
	wu_pin_ing = {}
	for item_name in shop_wu:
		wu_pin_ing[item_name] = 1
	# 先清理背包格子中之前显示的物品
	for ge in GZ:
		for child in ge.get_children():
			child.queue_free()
	# 按顺序显示商店物品
	var index = 0
	for wu_ming in shop_wu:
		if index >= GZ.size():
			break
		var ge = GZ[index]
		if 物品信息.wu_pin_png.has(wu_ming):
			var wu_pin_tu = TextureRect.new()
			wu_pin_tu.texture = load(物品信息.wu_pin_png[wu_ming])
			wu_pin_tu.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			wu_pin_tu.size = Vector2(50, 50)
			var offset = (GZ_size - 50) / 2.0
			wu_pin_tu.position = Vector2(offset, offset)
			ge.add_child(wu_pin_tu)
		index += 1

# 根据格子索引获取物品名称
func get_wu_ming(idx: int) -> String:
	if idx >= 0 and idx < shop_wu.size():
		return shop_wu[idx]
	return ""

# 获取售价字段名称（商店使用商店售价）
func get_shou_jia_zi_duan() -> String:
	return "商店售价"
# 获取购买按钮图片
func get_cao_zuo_png0() -> Texture2D:
	return cao_zuo_png0
func get_cao_zuo_png1() -> Texture2D:
	return cao_zuo_png1
# 是否显示购买按钮（商店始终显示）
func yao_xian_shi_cao_zuo_btn() -> bool:
	return true

# 购买按钮点击处理
func cao_zuo_3(event: InputEvent, amount: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var wu_ming = get_wu_ming(GZ_ing)
		if wu_ming == "":
			return
		var XX = 物品信息.get_XX(wu_ming)
		var shou_jia = XX.get("商店售价", 0)
		var json = get_node("/root/游戏存档") if has_node("/root/游戏存档") else null
		if json == null:
			return
		var data = json.du_qu(json.id)
		var BB_1 = data.get("背包", {})
		var S_1 = int(data.get("银币", 0))
		# 检查银币是否足够购买指定数量
		var total_cost = shou_jia * amount
		if S_1 < total_cost:
			# 计算实际可购买数量
			var can_buy = int(S_1 / shou_jia)
			if can_buy > 0:
				提示弹幕.wen_ben("银币不足！只能购买%d件！" % can_buy, 0)
			else:
				提示弹幕.wen_ben("银币不足！", 0)
			return
		# 执行批量购买
		buy_item_batch(wu_ming, shou_jia, amount, BB_1, S_1, json)

# 批量购买物品
func buy_item_batch(wu_ming: String, shou_jia: int, amount: int, BB_1: Dictionary, S_1: int, json) -> void:
	# 扣除银币
	var total_cost = shou_jia * amount
	S_1 -= total_cost
	# 增加背包物品（商店物品数量不变）
	if BB_1.has(wu_ming):
		BB_1[wu_ming] += amount
	else:
		BB_1[wu_ming] = amount
	# 更新数据
	var data = json.du_qu(json.id)
	data["背包"] = BB_1
	data["银币"] = S_1
	# 如果是经验星，立即使用
	var exp_add = get_exp(wu_ming)
	if exp_add > 0:
		# 计算总经验
		var total_exp = exp_add * amount
		# 增加经验
		var Exp = data.get("经验", 0)
		data["经验"] = Exp + total_exp
		# 调用游戏存档的升级检查函数
		var lv = data.get("等级", 1)
		var new_lv = json.chk_lv(data)
		# 使用后从背包移除
		BB_1.erase(wu_ming)
		data["背包"] = BB_1
		json.bao_cun(json.id, data)
		S_upd()
		# 显示获得经验弹幕（包含升级提示）
		if new_lv > lv:
			提示弹幕.wen_ben("购买并使用【%s】x%d，获得%d经验！\n恭喜升级到%d级！" % [wu_ming, amount, int(total_exp), int(new_lv)], 0)
		else:
			提示弹幕.wen_ben("购买并使用【%s】x%d，获得%d经验！" % [wu_ming, amount, int(total_exp)], 0)
	else:
		json.bao_cun(json.id, data)
		S_upd()
		# 显示购买成功弹幕
		提示弹幕.wen_ben("购买%sx%d，花费%d银币！" % [wu_ming, amount, total_cost], 0)

# 获取经验星对应的经验值
func get_exp(wu_ming: String) -> int:
	if wu_ming == "1级经验星":
		return 1000
	elif wu_ming == "2级经验星":
		return 10000
	elif wu_ming == "3级经验星":
		return 100000
	elif wu_ming == "4级经验星":
		return 1000000
	elif wu_ming == "5级经验星":
		return 10000000
	elif wu_ming == "6级经验星":
		return 100000000
	else:
		return 0

# 设置NPC引用
func npc_1(npc: Node2D) -> void:
	npc1 = npc

# 设置背包引用
func BB_2(BB_ref: Control) -> void:
	BB = BB_ref

# 设置强化引用
func QH_2(QH_ref: Control) -> void:
	QH = QH_ref

# 显示NPC函数
func on_npc() -> void:
	if npc1 != null:
		npc1.visible = true

# 隐藏NPC函数
func off_npc() -> void:
	if npc1 != null:
		npc1.visible = false
