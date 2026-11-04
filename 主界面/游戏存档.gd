class_name 游戏存档 extends Node
# 存档槽位数量（支持15个存档）
const cao_wei: int = 15
# 角色最高等级（开放更高等级只需改此处）
const MAX_LV: int = 4
# 动画基础帧率默认值（24帧/秒，即所有动画默认播放速度）
const ZHEN_LV_MO_REN: int = 24
# 动画基础帧率下限（设置界面滑块最小值）
const ZHEN_LV_MIN: int = 10
# 动画基础帧率上限（设置界面滑块最大值）
const ZHEN_LV_MAX: int = 60
# 动画帧率倍率：实际帧率 = 基础帧率 × 倍率（目前所有动画统一为1，保留常量便于后续单独调整）
const DONG_HUA_BEI_LV: float = 1.0
# 动画资源自身的原始帧率（项目所有 .tres SpriteFrames 的 speed 均为60）
const ZI_YUAN_ZHEN_LV: float = 60.0
# 当前使用的存档槽位编号(0~14)
var id: int = 0
# 基础帧率内存缓存（-1表示未加载；避免战斗中每次播放动画都读存档文件）
var ji_chu_zhen_lv_huan_cun: int = -1
# 存档文件夹路径（系统用户数据目录下，Windows 为 %APPDATA%\Godot\app_userdata\FOG\迷雾存档）
var mi_wu_json: String = ""

func _ready() -> void:
	# 获取系统用户数据目录下的存档根目录
	mi_wu_json = mu_lu()
	# 确保存档文件夹存在
	wen_jian_jia()
	# 启动时主动创建通用存档：不存在时写入默认值（分贝0=标准，非静音，语言简体中文），所有档共用
	if not FileAccess.file_exists(get_ty_lu_jing()):
		bao_cun_ty({"分贝": 0, "静音": 0, "历史成就": [], "语言": "zh_CN", "基础帧率": ZHEN_LV_MO_REN})
	# 手动加载翻译资源（project.godot 的 [locale] 配置在含中文路径"翻译/"时可能加载失败，代码手动加载更可靠）
	_jia_zai_fan_yi()
	# 启动时应用存档中的语言设置
	_ying_yong_yu_yan(get_yu_yan())

# 手动加载所有翻译资源到 TranslationServer（绕过 project.godot 的 [locale] 配置，避免路径含中文导致加载失败）
func _jia_zai_fan_yi() -> void:
	var lu_jing_lie_biao = [
		"res://翻译/翻译.en.translation",
		"res://翻译/翻译.zh_TW.translation",
		"res://翻译/翻译.ja.translation",
	]
	for lu_jing in lu_jing_lie_biao:
		var t = load(lu_jing)
		if t != null:
			TranslationServer.add_translation(t)

# 应用语言设置到引擎
# zh_CN 时用空 locale：引擎不查找任何翻译，tr() 直接返回 key 本身（即中文）
# 这样避免引擎在 zh_CN 找不到翻译时按"同语言族"回退到已注册的 zh_TW 翻译（导致简体界面显示繁体）
func _ying_yong_yu_yan(yu_yan: String) -> void:
	if yu_yan == "zh_CN":
		TranslationServer.set_locale("")
	else:
		TranslationServer.set_locale(yu_yan)

# 获取存档根目录路径
# 统一使用系统用户数据目录（Windows 为 %APPDATA%\FOG）
static func mu_lu() -> String:
	return OS.get_user_data_dir() + "/迷雾存档"

# 检查并创建存档文件夹
func wen_jian_jia() -> bool:
	# 确保存档路径已初始化
	if mi_wu_json.is_empty():
		mi_wu_json = mu_lu()
	var dir = DirAccess.open(mi_wu_json)
	if dir == null:
		# 获取父目录来创建存档文件夹
		var gen_mu_lu = mi_wu_json.get_base_dir()
		dir = DirAccess.open(gen_mu_lu)
		if dir:
			var jie_guo = dir.make_dir(mi_wu_json)
			return jie_guo == OK
		return false
	return true

# 检查存档是否存在
func you_cai_dang(json_id: int) -> bool:
	if json_id < 0 or json_id >= cao_wei:
		return false
	var lu_jing = get_lu_jing(json_id)
	return FileAccess.file_exists(lu_jing)

# 从数据管理节点读取当前档位
func get_dang_wei() -> int:
	wen_jian_jia()
	if has_node("/root/数据管理"):
		id = get_node("/root/数据管理").json
	return id

# 从文件读取当前档位并返回当前进度
func get_stg() -> int:
	get_dang_wei()
	var data = du_qu(id)
	return round(data.get("进度", 1))

# 保存游戏数据到指定槽位
# json_id 存档槽位编号(0~14)
func bao_cun(json_id: int, data: Dictionary) -> bool:
	wen_jian_jia()
	# 获取存档文件路径
	var lu_jing = get_lu_jing(json_id)
	# 打开文件
	var wen_jian = FileAccess.open(lu_jing, FileAccess.WRITE)
	if wen_jian == null:
		return false
	# 将数据字典转为JSON字符串并写入文件
	var json = JSON.stringify(data)
	wen_jian.store_line(json)
	wen_jian.close()
	return true

# 从指定槽位读取游戏数据
func du_qu(json_id: int) -> Dictionary:
	# 检查存档是否存在
	if not you_cai_dang(json_id):
		return {}
	# 获取存档文件路径
	var lu_jing = get_lu_jing(json_id)
	# 打开文件读取内容
	var wen_jian = FileAccess.open(lu_jing, FileAccess.READ)
	if wen_jian == null:
		return {}
	# 读取
	var nei_rong = wen_jian.get_line()
	wen_jian.close()
	# 解析JSON字符串为字典
	var jie_xi = JSON.parse_string(nei_rong)
	if jie_xi == null:
		return {}
	return jie_xi

# 获取存档文件路径
func get_lu_jing(json_id: int) -> String:
	return mi_wu_json + "/存档" + str(json_id + 1) + ".json"

# 删除存档文件
# json_id 存档槽位编号(0~14)
func shan_chu(json_id: int) -> bool:
	wen_jian_jia()
	# 检查存档是否存在
	if not you_cai_dang(json_id):
		return false
	# 获取存档文件路径
	var lu_jing = get_lu_jing(json_id)
	# 打开目录
	var dir = DirAccess.open(mi_wu_json)
	if dir:
		# 删除文件
		dir.remove(lu_jing)
		return true
	return false

# 计算升到指定等级所需的累计经验
# 公式：lv^5 * 10万（1级为0）
static func get_exp_need(lv: int) -> int:
	if lv <= 1:
		return 0
	return int(float(lv) ** 5 * 100000.0)

# 检查并修正等级
func chk_lv(data: Dictionary) -> int:
	var Exp = data.get("经验", 0)
	var lv = 1
	# 从2级往最高等级遍历，累计经验达到阈值则升级，未达到则停止
	for n in range(2, MAX_LV + 1):
		if Exp >= get_exp_need(n):
			lv = n
		else:
			break
	# 读取旧等级（用于判断是否升级）
	var old_lv = int(data.get("等级", 1))
	# 更新数据中的等级
	data["等级"] = lv
	# 升级时重置强化系统并返还金条（用旧等级计算已消耗强化值）
	if lv > old_lv:
		rst_qh(data, old_lv)
	return lv

# 计算强化值（英雄等级n时，装备从(m-1)级升到m级的强化值）
# n 英雄等级, m 目标强化等级
func calc_qh_m(hero_lv: int, m: int) -> int:
	var n = float(hero_lv)
	var base = 25.0 * pow(n, 5.0)
	var term1 = pow(float(m) / (n * 10.0) + 1.0, 4.0)
	var term2 = pow(float(m) / (n * 10.0) + 1.0 - 1.0 / (n * 10.0), 4.0)
	return round(base * (term1 - term2))

# 重置强化系统（英雄升级时调用）
# hero_lv 旧英雄等级（用于计算已消耗的强化值）
func rst_qh(data: Dictionary, hero_lv: int) -> void:
	# 强化数据为按第1~4件装备位的等级数组
	var QHs = data.get("强化", [0, 0, 0, 0])
	# 用旧英雄等级计算总强化值
	var total = 0
	for idx in range(4):
		var qh_lv = int(QHs[idx]) if idx < QHs.size() else 0
		# 累计该装备位从1级到当前等级的强化值
		for m in range(1, qh_lv + 1):
			total += calc_qh_m(hero_lv, m)
	# 按每满1024返1金条（向下取整）
	var jt = int(total / 1024.0)
	if jt > 0:
		var bag = data.get("背包", {})
		bag["金条"] = int(bag.get("金条", 0)) + jt
		data["背包"] = bag
	# 强化全部归零
	data["强化"] = [0, 0, 0, 0]
	# 升级提示弹幕（新等级已在 chk_lv 中写入 data）
	var new_lv = int(data.get("等级", hero_lv))
	提示弹幕.wen_ben(tr("恭喜升到%d级！当前总强化值%d，返还金条×%d！") % [new_lv, total, jt], 0)

# 获取指定关卡的诛邪等级
func get_zx_lv(guan_kia_id: int) -> int:
	get_dang_wei()
	var data = du_qu(id)
	var zx_data = data.get("诛邪等级", {})
	return int(zx_data.get(str(guan_kia_id), 1))

# 更新指定关卡的诛邪等级并保存
func upd_zx_lv(guan_kia_id: int) -> void:
	get_dang_wei()
	var data = du_qu(id)
	var zx_data = data.get("诛邪等级", {})
	var old_lv = int(zx_data.get(str(guan_kia_id), 1))
	zx_data[str(guan_kia_id)] = old_lv + 1
	data["诛邪等级"] = zx_data
	bao_cun(id, data)

# 删除指定关卡的诛邪等级记录（选关面板×重置用，删除后get_zx_lv恢复默认1级）
func rst_zx_lv(guan_kia_id: int) -> void:
	get_dang_wei()
	var data = du_qu(id)
	var zx_data = data.get("诛邪等级", {})
	# 存在该关记录时才删除并写回，避免无意义的存档写入
	if zx_data.has(str(guan_kia_id)):
		zx_data.erase(str(guan_kia_id))
		data["诛邪等级"] = zx_data
		bao_cun(id, data)

# 获取关卡道具携带配置（道具选择界面保存的物品名有序数组，最多10个）
# 存档无记录或记录为空数组时均返回默认顺序；有内容时按内容来
func get_dao_ju_xz() -> Array:
	get_dang_wei()
	var data = du_qu(id)
	# 字段不存在或为空数组=从未主动选择/主动全取消，均走默认顺序
	# 默认顺序：按候选池顺序取玩家当前拥有（背包数量>0）的道具，最多10种
	if not data.has("道具选择") or data.get("道具选择", []).is_empty():
		var bag = data.get("背包", {})
		var mo_ren: Array = []
		for wu_ming in 物品信息.guan_kia_dao_ju:
			if int(bag.get(wu_ming, 0)) > 0:
				mo_ren.append(wu_ming)
				if mo_ren.size() >= 10:
					break
		return mo_ren
	# 字段存在且有内容：过滤掉已不在可用道具表中的项、去重、截断10个
	var jie_guo: Array = []
	for wu_ming in data.get("道具选择", []):
		if 物品信息.guan_kia_dao_ju.has(wu_ming) and not jie_guo.has(wu_ming):
			jie_guo.append(wu_ming)
		if jie_guo.size() >= 10:
			break
	return jie_guo

# 保存关卡道具携带配置（xz为物品名有序数组，允许空数组）
func bao_cun_dao_ju_xz(xz: Array) -> void:
	get_dang_wei()
	var data = du_qu(id)
	data["道具选择"] = xz
	bao_cun(id, data)

# 获取存档的模式（0=主线，1=诛邪，2=支线）
func get_mode() -> int:
	get_dang_wei()
	var data = du_qu(id)
	return int(data.get("模式", 0))

# 更新存档的模式并保存
func upd_mode(mode: int) -> void:
	get_dang_wei()
	var data = du_qu(id)
	data["模式"] = mode
	bao_cun(id, data)

# 获取通用存档文件路径（所有档位共用一个文件）
func get_ty_lu_jing() -> String:
	return mi_wu_json + "/通用存档.json"

# 从通用存档读取数据（文件不存在或解析失败返回空字典）
func du_qu_ty() -> Dictionary:
	# 确保存档路径已初始化
	if mi_wu_json.is_empty():
		mi_wu_json = mu_lu()
	var lu_jing = get_ty_lu_jing()
	# 通用存档不存在时返回空字典（读取方用get默认值兜底）
	if not FileAccess.file_exists(lu_jing):
		return {}
	var wen_jian = FileAccess.open(lu_jing, FileAccess.READ)
	if wen_jian == null:
		return {}
	var nei_rong = wen_jian.get_line()
	wen_jian.close()
	var jie_xi = JSON.parse_string(nei_rong)
	if jie_xi == null:
		return {}
	return jie_xi

# 保存数据到通用存档（整体覆盖写入）
func bao_cun_ty(data: Dictionary) -> bool:
	# 确保存档路径已初始化
	if mi_wu_json.is_empty():
		mi_wu_json = mu_lu()
	var wen_jian = FileAccess.open(get_ty_lu_jing(), FileAccess.WRITE)
	if wen_jian == null:
		return false
	wen_jian.store_line(JSON.stringify(data))
	wen_jian.close()
	return true

# 读取当前存档的已领取成就序号清单（4位字符串序号，保留前导零）
# 字段不存在或旧格式（下标0/1数组）一律视为空清单，不做迁移
func get_ach_lq() -> Array:
	var data = du_qu(id)
	var lq = data.get("成就", [])
	var jg: Array = []
	if lq is Array:
		for x in lq:
			if x is String and not x.is_empty() and not jg.has(x):
				jg.append(x)
	return jg

# 记录成就到通用存档历史（某存档领取成就后调用，永久保留）
# xu_hao 成就序号（4位字符串，如"0001"）
func add_ach_ty(xu_hao: String) -> void:
	var data = du_qu_ty()
	# 读取现有历史成就序号清单（旧格式/非字符串项一律忽略，视为空）
	var his_ach = data.get("历史成就", [])
	var jg: Array = []
	if his_ach is Array:
		for x in his_ach:
			if x is String and not x.is_empty() and not jg.has(x):
				jg.append(x)
	# 追加本次领取的序号
	if not jg.has(xu_hao):
		jg.append(xu_hao)
	data["历史成就"] = jg
	bao_cun_ty(data)

# 检查某成就是否已在通用存档历史中被领取过
# xu_hao 成就序号（4位字符串，如"1000"）
func has_ach_ty(xu_hao: String) -> bool:
	var data = du_qu_ty()
	var his_ach = data.get("历史成就", [])
	if his_ach is Array:
		for x in his_ach:
			if x is String and x == xu_hao:
				return true
	return false

# 获取当前语言设置（从通用存档读取，默认简体中文 zh_CN）
func get_yu_yan() -> String:
	var data = du_qu_ty()
	return str(data.get("语言", "zh_CN"))

# 保存语言设置到通用存档并立即切换生效
# yu_yan 语言代码，如 "zh_CN"、"en"、"zh_TW"、"ja"
func set_yu_yan(yu_yan: String) -> void:
	var data = du_qu_ty()
	data["语言"] = yu_yan
	bao_cun_ty(data)
	# 立即切换引擎语言（zh_CN 走空 locale 避免回退到繁体）
	_ying_yong_yu_yan(yu_yan)

# 获取动画基础帧率（首次调用读存档并缓存，之后直接返回缓存值）
func get_ji_chu_zhen_lv() -> int:
	if ji_chu_zhen_lv_huan_cun < 0:
		ji_chu_zhen_lv_huan_cun = clampi(int(du_qu_ty().get("基础帧率", ZHEN_LV_MO_REN)), ZHEN_LV_MIN, ZHEN_LV_MAX)
	return ji_chu_zhen_lv_huan_cun

# 保存动画基础帧率到通用存档（限制在10~60之间后写入，并同步更新缓存）
# zhen_lv 基础帧率（帧/秒）
func set_ji_chu_zhen_lv(zhen_lv: int) -> void:
	var data = du_qu_ty()
	data["基础帧率"] = clampi(zhen_lv, ZHEN_LV_MIN, ZHEN_LV_MAX)
	bao_cun_ty(data)
	ji_chu_zhen_lv_huan_cun = int(data["基础帧率"])

# 计算 AnimatedSprite2D 的播放速度缩放值
# 动画资源原始帧率为60，speed_scale=基础帧率/60×倍率，实际帧率即等于基础帧率×倍率
func get_dong_hua_su_du() -> float:
	return get_ji_chu_zhen_lv() / ZI_YUAN_ZHEN_LV * DONG_HUA_BEI_LV

# 立即刷新当前场景内所有动画节点的播放速度（用于主界面改完基础帧率后马上生效）
func shua_xin_dong_hua_su_du() -> void:
	# 当前场景为空（切换场景过程中）时直接返回
	var chang_jing = get_tree().current_scene
	if chang_jing == null:
		return
	var su_du = get_dong_hua_su_du()
	# 递归查找场景内所有 AnimatedSprite2D 并统一设置速度
	for dong_hua in chang_jing.find_children("*", "AnimatedSprite2D", true, false):
		if dong_hua is AnimatedSprite2D:
			dong_hua.speed_scale = su_du
