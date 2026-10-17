class_name 游戏存档 extends Node
# 存档槽位数量（支持15个存档）
const cao_wei: int = 15
# 角色最高等级（开放更高等级只需改此处）
const MAX_LV: int = 4
# 当前使用的存档槽位编号(0~14)
var id: int = 0
# 存档文件夹路径（与exe文件同目录）
var mi_wu_json: String = ""

func _ready() -> void:
	# 获取exe文件所在目录作为存档根目录
	mi_wu_json = mu_lu()
	# 确保存档文件夹存在
	wen_jian_jia()
	# 启动时主动创建通用存档：不存在时写入默认值（分贝0=标准，非静音），所有档共用
	if not FileAccess.file_exists(get_ty_lu_jing()):
		bao_cun_ty({"分贝": 0, "静音": 0, "历史成就": []})

# 获取存档根目录路径
static func mu_lu() -> String:
	var gen_mu_lu: String
	if OS.has_feature("editor"):
		# 在编辑器中运行，使用项目目录
		gen_mu_lu = ProjectSettings.globalize_path("res://")
	elif OS.has_feature("mobile"):
		# 移动端，使用应用私有数据目录
		gen_mu_lu = OS.get_user_data_dir()
	else:
		# 桌面端，使用exe所在目录
		var exe_lu_jing = OS.get_executable_path()
		gen_mu_lu = exe_lu_jing.get_base_dir()
	return gen_mu_lu + "/迷雾存档"

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
	提示弹幕.wen_ben("恭喜升到%d级！当前总强化值%d，返还金条×%d！" % [new_lv, total, jt], 0)

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
	if not data.has("道具选择") or data.get("道具选择", []).is_empty():
		return 物品信息.guan_kia_dao_ju.duplicate()
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

# 获取存档的模式（0=主线，1=诛邪）
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

# 记录成就到通用存档历史（某存档领取成就后调用，永久保留）
# ach_idx 成就索引，ach_count 当前版本成就总数量
func add_ach_ty(ach_idx: int, ach_count: int) -> void:
	var data = du_qu_ty()
	# 读取现有历史成就列表，不存在时创建空数组
	var his_ach = data.get("历史成就", [])
	# 长度不足当前版本时扩展，已有值保留，新位置补0
	if his_ach.size() < ach_count:
		var old_size = his_ach.size()
		his_ach.resize(ach_count)
		for i in range(old_size, ach_count):
			his_ach[i] = 0
	# 标记指定成就为已完成
	if ach_idx >= 0 and ach_idx < his_ach.size():
		his_ach[ach_idx] = 1
		data["历史成就"] = his_ach
		bao_cun_ty(data)

# 检查某成就是否已在通用存档历史中被完成过
# ach_idx 成就索引
func has_ach_ty(ach_idx: int) -> bool:
	var data = du_qu_ty()
	var his_ach = data.get("历史成就", [])
	if ach_idx >= 0 and ach_idx < his_ach.size():
		return int(his_ach[ach_idx]) == 1
	return false
