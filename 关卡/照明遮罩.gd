# 光照遮罩（三种模式共用）
# 支线：压暗 + 英雄夜视 + 余烬主色
# 主线/诛邪：不压暗 + 无英雄夜视 + 仅余烬主色（白天当滤镜看）
# 载体必须是 Sprite2D（非 Control），否则 PC输入.gd 的 GUI() 会吞掉点击/拖动
extends Node

# 遮罩最多光源组数：1 夜视 + 85 余烬（与 shader 的 dian_guang[86] 一致）
const 最大光源: int = 86
# 英雄夜视半径（格）。支线保持 2.5 格
const 英雄半径格: float = 2.5
# 混色权重指数（1=线性照度，默认；越大越偏向最亮光源）
const 混色指数: float = 1.0
# 余烬滤镜强度由玩家设置提供（游戏存档.get_yu_jin_qiang_du_bi，10%~60%，默认24%）
# 色板：0=英雄白光，1~4=四档余烬主色
const 色板默认: Array = [
	Vector3(1, 1, 1),
	Vector3(1, 0.2, 0),
	Vector3(1, 0.6, 0.2),
	Vector3(1, 0.8, 0.6),
	Vector3(1, 1, 0.8),
]

var guan_qia: Node2D = null
# 压暗强度：支线 1.0，白天 0
var 压暗: float = 0.0
# 是否包含英雄夜视光源（支线 true，白天 false）
var 含英雄夜视: bool = false
var ye_wan_zhe_zhao: Sprite2D = null
var ye_wan_cai_zhi: ShaderMaterial = null
# 当前光圈中心（屏幕坐标）
var ye_wan_zhong_xin: Vector2 = Vector2.ZERO
# 玩家设置的余烬滤镜强度（0~1）；每帧只比较内存缓存，不读档
var yu_jin_json = null
var 当前强度: float = 0.24
# 预分配光源数组
var guang_yuan_huan: PackedVector4Array = PackedVector4Array()
# 色板
var 遮罩_色板: PackedVector3Array = PackedVector3Array()

func _init(gq: Node2D, ya_an: float, han_ye_shi: bool) -> void:
	guan_qia = gq
	压暗 = ya_an
	含英雄夜视 = han_ye_shi

func _ready() -> void:
	C_zhao_ming()

# 创建遮罩：全屏 Sprite2D + 多光源 shader
# 层级 500：高于世界内容、低于关卡UI（1000），不拦截鼠标
func C_zhao_ming() -> void:
	for c in 色板默认:
		遮罩_色板.append(c)
	ye_wan_zhe_zhao = Sprite2D.new()
	ye_wan_zhe_zhao.centered = false
	ye_wan_zhe_zhao.position = Vector2.ZERO
	# 1×1 纯白纹理靠缩放铺满全屏（shader 直接输出颜色，与纹理无关）
	var bai = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	bai.fill(Color.WHITE)
	ye_wan_zhe_zhao.texture = ImageTexture.create_from_image(bai)
	ye_wan_zhe_zhao.scale = get_viewport().get_visible_rect().size
	ye_wan_zhe_zhao.z_index = 500
	ye_wan_cai_zhi = ShaderMaterial.new()
	ye_wan_cai_zhi.shader = load("res://关卡/夜晚遮罩.gdshader")
	ye_wan_cai_zhi.set_shader_parameter("darkness", 压暗)
	# 滤镜强度来自玩家设置（0.10~0.60，默认 0.24）
	yu_jin_json = get_node_or_null("/root/游戏存档")
	当前强度 = yu_jin_json.get_yu_jin_qiang_du_bi() if yu_jin_json != null else 0.24
	ye_wan_cai_zhi.set_shader_parameter("tiao_qiang", 当前强度)
	ye_wan_cai_zhi.set_shader_parameter("hun_he_zhi_shu", 混色指数)
	ye_wan_cai_zhi.set_shader_parameter("tiao_se", 遮罩_色板)
	guang_yuan_huan.resize(最大光源)
	for i in range(最大光源):
		guang_yuan_huan[i] = Vector4.ZERO
	ye_wan_zhong_xin = ge_zhong_xin_ping_mu()
	ye_wan_zhe_zhao.material = ye_wan_cai_zhi
	add_child(ye_wan_zhe_zhao)
	upd_guang_yuan()

# 运行中切换配置（支线在 super() 之后设为压暗 + 夜视）
func she_zhi(ya_an: float, han_ye_shi: bool) -> void:
	压暗 = ya_an
	含英雄夜视 = han_ye_shi
	if ye_wan_cai_zhi != null:
		ye_wan_cai_zhi.set_shader_parameter("darkness", 压暗)
	upd_guang_yuan()

# 是否处于夜晚压暗（供余烬太阳上限文案判断）
func you_ya_an() -> bool:
	return 压暗 > 0.0

# 每帧：英雄光照中心直接跟随（瞬移同帧到位），并推送全部光源
func _process(_delta: float) -> void:
	if ye_wan_cai_zhi == null:
		return
	upd_tiao_qiang()
	ye_wan_zhong_xin = ge_zhong_xin_ping_mu()
	upd_guang_yuan()

# 滤镜强度即时生效：只比较内存缓存，变化才写 shader（设置改动后 ≤1 帧生效）
func upd_tiao_qiang() -> void:
	if yu_jin_json == null or not is_instance_valid(yu_jin_json):
		yu_jin_json = get_node_or_null("/root/游戏存档")
		if yu_jin_json == null:
			return
	var v: float = yu_jin_json.get_yu_jin_qiang_du_bi()
	if not is_equal_approx(v, 当前强度):
		当前强度 = v
		ye_wan_cai_zhi.set_shader_parameter("tiao_qiang", 当前强度)

# 推送光源数组：夜视（若开启）在槽 0，余烬依次随后
func upd_guang_yuan() -> void:
	if ye_wan_cai_zhi == null:
		return
	var ge_ju: float = ge_jian_ping_mu()
	var n: int = 0
	if 含英雄夜视:
		guang_yuan_huan[0] = Vector4(ye_wan_zhong_xin.x, ye_wan_zhong_xin.y, 英雄半径格 * ge_ju, 0.0)
		n = 1
	if guan_qia.yu_jin != null and is_instance_valid(guan_qia.yu_jin):
		var lie = guan_qia.yu_jin.guang_yuan_ming_dan(ge_ju, get_viewport().get_canvas_transform())
		for i in range(lie.size()):
			if n >= 最大光源:
				break
			guang_yuan_huan[n] = lie[i]
			n += 1
	for i in range(n, 最大光源):
		guang_yuan_huan[i] = Vector4.ZERO
	ye_wan_cai_zhi.set_shader_parameter("dian_guang", guang_yuan_huan)
	ye_wan_cai_zhi.set_shader_parameter("dian_guang_shu", n)

# 英雄所在格中心的屏幕坐标（helo_x/helo_y 从 1 开始，GZ_zhong 用 0 基索引）
func ge_zhong_xin_ping_mu() -> Vector2:
	if guan_qia.helo == null:
		return get_viewport().get_visible_rect().size / 2.0
	var ju_bu = guan_qia.GZ_zhong(guan_qia.helo_x - 1, guan_qia.helo_y - 1)
	if guan_qia.rong_qi != null:
		ju_bu = guan_qia.rong_qi.to_global(ju_bu)
	return get_viewport().get_canvas_transform() * ju_bu

# 一格在屏幕上的像素宽度（含画面比例缩放与画布变换）
func ge_jian_ping_mu() -> float:
	if guan_qia.rong_qi == null:
		return float(guan_qia.GZ_size)
	var bian_huan = get_viewport().get_canvas_transform()
	var jichu = bian_huan * guan_qia.rong_qi.to_global(guan_qia.GZ_zhong(0, 0))
	var lin = bian_huan * guan_qia.rong_qi.to_global(guan_qia.GZ_zhong(1, 0))
	return (lin - jichu).length()