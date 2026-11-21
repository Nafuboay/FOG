extends Control
# 公告框：960×540 棕色面板 + 大标题随滚动 + 滚轮/拖动/右侧滚动条 + 首读 3 秒倒计时
# 正文按当前语言从 公告文案_<语言>.gd 整篇读取，不走 tr()
signal guan_bi
# 面板与内容区尺寸（视口固定 1280×720，窗口缩放由 viewport 拉伸处理）
const Mian_ban_chi_cun := Vector2(960, 540)
const Nei_rong_wei_zhi := Vector2(32, 24)
const Nei_rong_chi_cun := Vector2(896, 492)
const Gun_tiao_x: float = 932.0
const Gun_tiao_kuan: float = 10.0
# 叉号中心点正对面板右上角：(960,0) - 32
const Cha_wei_zhi := Vector2(928, -32)
const Cha_chi_cun := Vector2(64, 64)
const Gun_lun_bu_chang: float = 48.0
const Dao_ji_shi_miao: float = 3.0
const Wen_an_lu_jing: String = "res://主界面/公告文案_"
const Yu_yan_lie_biao: Array = ["zh_CN", "en", "zh_TW", "ja"]
# 排版参数
const Zi_hao_biao_ti: int = 32
const Zi_hao_biao_ti_hang_ju: int = 18
const Zi_hao_zheng_wen: int = 18
const Hang_ju_xi_shu: float = 0.4
const Ju_li_biao_ti_qian: float = 16.0
const Ju_li_biao_ti_hou: float = 6.0
const Ju_li_shu_zi_qian: float = 8.0
const Ju_li_shu_zi_hou: float = 4.0
const Ju_li_tiao_mu_hou: float = 6.0
const Ju_li_shu_ming_qian: float = 20.0
const Hui_zi_key: String = "请认真查看，以免游戏中遇到障碍，可于%d秒后关闭。"
var cha: Button = null
var hui_zi: Label = null
var nei_rong_shi_kou: Control = null
var zheng_wen: Control = null
var gun_tiao_dao: ColorRect = null
var gun_dong_kuai: ColorRect = null
var _ban_pos: Vector2 = Vector2.ZERO
var _scroll: float = 0.0
var _scroll_max: float = 0.0
var _tuo_dong_zhong: bool = false
var _tuo_gun_tiao: bool = false
var _zhua_dy: float = 0.0
var _ji_shi_qi_dian: int = 0
var _shou_du: bool = false
var _ji_shi_zhong: bool = false
var _kai_ti_font: FontFile = null

# 当前语言代码（简体中文走空 locale，统一识别为 zh_CN）
static func dang_qian_yu_yan() -> String:
	var yu_yan: String = TranslationServer.get_locale()
	if yu_yan.is_empty():
		return "zh_CN"
	if not Yu_yan_lie_biao.has(yu_yan):
		return "zh_CN"
	return yu_yan

# 按语言整篇加载公告文案脚本（缺失时回退简体）
static func jia_zai_wen_an():
	var wen_an = load(Wen_an_lu_jing + dang_qian_yu_yan() + ".gd")
	if wen_an == null:
		wen_an = load(Wen_an_lu_jing + "zh_CN.gd")
	return wen_an

func _ready() -> void:
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 3000
	set_process(false)
	_kai_ti_font = 提示弹幕.get_kai_ti_font()

# 构建面板并填充正文；shou_du=true 时右上叉隐藏、下方灰字从 3 开始倒计时
func kai_chuang(shou_du: bool) -> void:
	var wen_an = jia_zai_wen_an()
	if wen_an == null:
		return
	var kuai: Array = wen_an.KUAI
	if kuai.is_empty():
		return
	_shou_du = shou_du
	_ban_pos = (size - Mian_ban_chi_cun) / 2.0
	# 全屏遮罩：压暗底层并吞掉所有点击，防止透传到开始按钮/槽位列表
	var mask = ColorRect.new()
	mask.color = Color(0, 0, 0, 0.35)
	mask.anchor_right = 1.0
	mask.anchor_bottom = 1.0
	mask.mouse_filter = Control.MOUSE_FILTER_STOP
	mask.gui_input.connect(_mask_gui_input)
	add_child(mask)
	# 面板容器（本身忽略鼠标，让滚轮/拖动冒泡到遮罩）
	var ban = Control.new()
	ban.position = _ban_pos
	ban.size = Mian_ban_chi_cun
	ban.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ban)
	# 背景：项目常用的棕色背包背景，500×500 直接拉伸为 960×540，略微提亮
	var bg = TextureRect.new()
	var bg_tex = load("res://全局/图片/背包背景.png")
	if bg_tex != null:
		bg.texture = bg_tex
	bg.modulate = Color(1.15, 1.15, 1.15, 1)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.size = Mian_ban_chi_cun
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ban.add_child(bg)
	# 内容裁剪视口（顶部不再预留固定标题区，标题随正文滚动）
	nei_rong_shi_kou = Control.new()
	nei_rong_shi_kou.position = Nei_rong_wei_zhi
	nei_rong_shi_kou.size = Nei_rong_chi_cun
	nei_rong_shi_kou.clip_contents = true
	nei_rong_shi_kou.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ban.add_child(nei_rong_shi_kou)
	# 正文容器：滚动只改它的 position.y
	zheng_wen = Control.new()
	zheng_wen.position = Vector2.ZERO
	zheng_wen.size = Vector2(Nei_rong_chi_cun.x, 0)
	zheng_wen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nei_rong_shi_kou.add_child(zheng_wen)
	_gou_jian_zheng_wen(wen_an.BIAO_TI, kuai)
	# 右侧滚动条（轨道 + 滑块），可左键拖动
	gun_tiao_dao = ColorRect.new()
	gun_tiao_dao.color = Color(0.25, 0.15, 0.08, 0.55)
	gun_tiao_dao.position = Vector2(Gun_tiao_x, Nei_rong_wei_zhi.y)
	gun_tiao_dao.size = Vector2(Gun_tiao_kuan, Nei_rong_chi_cun.y)
	gun_tiao_dao.mouse_filter = Control.MOUSE_FILTER_PASS
	gun_tiao_dao.gui_input.connect(_gun_tiao_gui_input)
	ban.add_child(gun_tiao_dao)
	gun_dong_kuai = ColorRect.new()
	gun_dong_kuai.color = Color(0.62, 0.40, 0.20, 0.95)
	gun_dong_kuai.position = Vector2.ZERO
	gun_dong_kuai.size = Vector2(Gun_tiao_kuan, 40)
	gun_dong_kuai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gun_tiao_dao.add_child(gun_dong_kuai)
	# 右上角叉号：中心点对准面板右上角，首读倒计时期间隐藏
	cha = Button.new()
	cha.position = Cha_wei_zhi
	cha.size = Cha_chi_cun
	cha.custom_minimum_size = Cha_chi_cun
	cha.focus_mode = Control.FOCUS_NONE
	var cha_0 = load("res://主界面/图片/×号0.png")
	var cha_1 = load("res://主界面/图片/×号1.png")
	if cha_0 != null and cha_1 != null:
		var st_0 = StyleBoxTexture.new()
		st_0.texture = cha_0
		var st_1 = StyleBoxTexture.new()
		st_1.texture = cha_1
		cha.add_theme_stylebox_override("normal", st_0)
		cha.add_theme_stylebox_override("hover", st_1)
		cha.add_theme_stylebox_override("pressed", st_1)
	else:
		cha.text = tr("关闭")
		cha.add_theme_color_override("font_color", Color.BLACK)
		cha_kai_ti(cha)
	cha.pressed.connect(_on_cha_pressed)
	cha.visible = not shou_du
	ban.add_child(cha)
	# 面板下方灰色倒计时文本
	hui_zi = Label.new()
	hui_zi.position = Vector2(_ban_pos.x, _ban_pos.y + Mian_ban_chi_cun.y + 16.0)
	hui_zi.size = Vector2(Mian_ban_chi_cun.x, 34)
	hui_zi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hui_zi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hui_zi.add_theme_font_size_override("font_size", 24)
	hui_zi.add_theme_color_override("font_color", Color("666666"))
	cha_kai_ti(hui_zi)
	hui_zi.text = tr(Hui_zi_key) % 3
	hui_zi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hui_zi.visible = shou_du
	add_child(hui_zi)
	# 每次打开都回到顶部
	_scroll = 0.0
	zheng_wen.position.y = 0.0
	_geng_xin_gun_tiao()
	if shou_du:
		_ji_shi_zhong = true
		_ji_shi_qi_dian = Time.get_ticks_msec()
		set_process(true)


# 按块类型逐条排版：大标题、章节标题、数字小节、条目、署名
func _gou_jian_zheng_wen(biao_ti: String, kuai: Array) -> void:
	var y: float = 0.0
	# 页面大标题：随滚动一起走
	var ti = C_wen_ben(biao_ti, Zi_hao_biao_ti, Nei_rong_chi_cun.x, HORIZONTAL_ALIGNMENT_CENTER)
	ti.position = Vector2(0, y)
	var ti_h = ce_gao(ti, Zi_hao_biao_ti, Zi_hao_biao_ti_hang_ju)
	ti.size = Vector2(Nei_rong_chi_cun.x, ti_h)
	y += ti_h + Ju_li_biao_ti_hou
	var shu_ming_di_yi = true
	for b in kuai:
		var lei: int = int(b.get("lei", 2))
		var wen: String = str(b.get("key", ""))
		if wen.is_empty():
			continue
		if lei == 3:
			# 署名与日期：右对齐，两行之间不留空行
			if shu_ming_di_yi:
				y += Ju_li_shu_ming_qian
				shu_ming_di_yi = false
			var lbl = C_wen_ben(wen, Zi_hao_zheng_wen, Nei_rong_chi_cun.x, HORIZONTAL_ALIGNMENT_RIGHT)
			lbl.position = Vector2(0, y)
			var h = ce_gao(lbl, Zi_hao_zheng_wen, int(Zi_hao_zheng_wen * Hang_ju_xi_shu))
			lbl.size = Vector2(Nei_rong_chi_cun.x, h)
			y += h
		elif wen.begins_with("【"):
			# 二级标题：居中，与正文同字号
			y += Ju_li_biao_ti_qian
			var lbl = C_wen_ben(wen, Zi_hao_zheng_wen, Nei_rong_chi_cun.x, HORIZONTAL_ALIGNMENT_CENTER)
			lbl.position = Vector2(0, y)
			var h = ce_gao(lbl, Zi_hao_zheng_wen, int(Zi_hao_zheng_wen * Hang_ju_xi_shu))
			lbl.size = Vector2(Nei_rong_chi_cun.x, h)
			y += h + Ju_li_biao_ti_hou
		elif _shi_shu_zi_biao_ti(wen):
			# 三级标题：数字. 开头，统一顶格
			y += Ju_li_shu_zi_qian
			var lbl = C_wen_ben(wen, Zi_hao_zheng_wen, Nei_rong_chi_cun.x, HORIZONTAL_ALIGNMENT_LEFT)
			lbl.position = Vector2(0, y)
			var h = ce_gao(lbl, Zi_hao_zheng_wen, int(Zi_hao_zheng_wen * Hang_ju_xi_shu))
			lbl.size = Vector2(Nei_rong_chi_cun.x, h)
			y += h + Ju_li_shu_zi_hou
		else:
			# 正文：首行缩进两格，换行顶格（- / + / × 也算正文，符号一起缩进）
			var lbl = C_wen_ben(_duan_shou_suo_jin() + wen, Zi_hao_zheng_wen, Nei_rong_chi_cun.x, HORIZONTAL_ALIGNMENT_LEFT)
			lbl.position = Vector2(0, y)
			var h = ce_gao(lbl, Zi_hao_zheng_wen, int(Zi_hao_zheng_wen * Hang_ju_xi_shu))
			lbl.size = Vector2(Nei_rong_chi_cun.x, h)
			y += h + Ju_li_tiao_mu_hou
	zheng_wen.size = Vector2(Nei_rong_chi_cun.x, y)
	_scroll_max = maxf(0.0, y - Nei_rong_chi_cun.y)

# 判断是否为“数字.”开头的三级标题（1. / 2. ...），统一顶格
func _shi_shu_zi_biao_ti(wen: String) -> bool:
	var dian: int = wen.find(".")
	if dian <= 0 or dian > 3:
		return false
	for i in dian:
		if not "0123456789".contains(wen[i]):
			return false
	return true

# 正文段首缩进：英文一个半角空格，其他语言两个全角空格
func _duan_shou_suo_jin() -> String:
	if TranslationServer.get_locale().begins_with("en"):
		return " "
	return "　　"

# 创建一个正文 Label：自动换行、黑色、楷体、行距
func C_wen_ben(wen: String, zi_hao: int, kuan: float, dui_qi: int) -> Label:
	var lbl = Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = dui_qi
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.add_theme_font_size_override("font_size", zi_hao)
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.add_theme_constant_override("line_spacing", int(zi_hao * Hang_ju_xi_shu))
	if _kai_ti_font != null:
		lbl.add_theme_font_override("font", _kai_ti_font)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size = Vector2(kuan, 0)
	lbl.text = wen
	zheng_wen.add_child(lbl)
	return lbl

# 按行数测量块高（行高未含 line_spacing，逐行补上）
func ce_gao(lbl: Label, zi_hao: int, hang_ju: int) -> float:
	var hang: int = maxi(lbl.get_line_count(), 1)
	var h: float = lbl.get_line_height() * hang
	h += float(hang - 1) * float(hang_ju)
	return maxf(h, float(zi_hao))

# 给控件套用楷体
func cha_kai_ti(control: Control) -> void:
	if _kai_ti_font != null:
		control.add_theme_font_override("font", _kai_ti_font)

# 遮罩上的滚轮与拖动统一入口
func _mask_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			gun_dong(-Gun_lun_bu_chang)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			gun_dong(Gun_lun_bu_chang)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# 只有落在正文内容区才起拖
				var qu_yu = Rect2(_ban_pos + Nei_rong_wei_zhi, Nei_rong_chi_cun)
				_tuo_dong_zhong = qu_yu.has_point(event.position)
				accept_event()
			else:
				_tuo_dong_zhong = false
				accept_event()
	elif event is InputEventMouseMotion and _tuo_dong_zhong:
		gun_dong(-event.relative.y)
		accept_event()

# 右侧滚动条：点击轨道跳转、按住滑块拖动
func _gun_tiao_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			gun_dong(-Gun_lun_bu_chang)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			gun_dong(Gun_lun_bu_chang)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var kuai_rect = Rect2(gun_dong_kuai.position, gun_dong_kuai.size)
				if kuai_rect.has_point(event.position):
					_tuo_gun_tiao = true
					_zhua_dy = event.position.y - gun_dong_kuai.position.y
				else:
					# 点轨道空白：滑块对中并跳到对应位置
					var ke_yi = maxf(1.0, gun_tiao_dao.size.y - gun_dong_kuai.size.y)
					var mu_biao = clampf(event.position.y - gun_dong_kuai.size.y / 2.0, 0.0, ke_yi)
					_gun_tiao_tiao_zhi(mu_biao)
				accept_event()
			else:
				_tuo_gun_tiao = false
				accept_event()
	elif event is InputEventMouseMotion and _tuo_gun_tiao:
		var ke_yi = maxf(1.0, gun_tiao_dao.size.y - gun_dong_kuai.size.y)
		_gun_tiao_tiao_zhi(clampf(event.position.y - _zhua_dy, 0.0, ke_yi))
		accept_event()

# 滑块移动到指定 y，并换算成正文位移
func _gun_tiao_tiao_zhi(kuai_y: float) -> void:
	if gun_dong_kuai == null or gun_tiao_dao == null:
		return
	var ke_yi = maxf(1.0, gun_tiao_dao.size.y - gun_dong_kuai.size.y)
	gun_dong_kuai.position.y = kuai_y
	_scroll = (kuai_y / ke_yi) * _scroll_max if _scroll_max > 0.0 else 0.0
	zheng_wen.position.y = -_scroll

# 滚动位移，钳制在 0 ~ (正文总高 - 内容区高)，无缓动
func gun_dong(dy: float) -> void:
	_scroll = clampf(_scroll + dy, 0.0, _scroll_max)
	if zheng_wen != null:
		zheng_wen.position.y = -_scroll
	_geng_xin_gun_tiao()

# 同步滑块高度与位置（内容不足一屏时隐藏滚动条）
func _geng_xin_gun_tiao() -> void:
	if gun_tiao_dao == null or gun_dong_kuai == null:
		return
	if _scroll_max <= 0.001:
		gun_tiao_dao.visible = false
		return
	gun_tiao_dao.visible = true
	var dao_h: float = gun_tiao_dao.size.y
	var bi: float = Nei_rong_chi_cun.y / (Nei_rong_chi_cun.y + _scroll_max)
	var kuai_h: float = maxf(40.0, dao_h * bi)
	gun_dong_kuai.size.y = kuai_h
	var ke_yi = maxf(1.0, dao_h - kuai_h)
	gun_dong_kuai.position.y = (_scroll / _scroll_max) * ke_yi


# 首读 3 秒倒计时：3→2→1，结束后隐藏灰字、显示叉
func _process(_delta: float) -> void:
	if not _ji_shi_zhong:
		return
	var sheng_yu: float = Dao_ji_shi_miao - float(Time.get_ticks_msec() - _ji_shi_qi_dian) / 1000.0
	if sheng_yu > 0.0:
		var n: int = clampi(int(ceil(sheng_yu)), 1, int(Dao_ji_shi_miao))
		var wen: String = tr(Hui_zi_key) % n
		if hui_zi != null and hui_zi.text != wen:
			hui_zi.text = wen
	else:
		if hui_zi != null:
			hui_zi.visible = false
		if cha != null:
			cha.visible = true
		_ji_shi_zhong = false
		set_process(false)

func _on_cha_pressed() -> void:
	guan_bi.emit()