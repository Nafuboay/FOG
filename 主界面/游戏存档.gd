class_name 游戏存档 extends Node
# 存档槽位数量（支持6个存档）
const cao_wei: int = 6
# 当前使用的存档槽位编号(0~5)
var id: int = 0
# 存档文件夹路径（与exe文件同目录）
var mi_wu_json: String = ""

func _ready() -> void:
	# 获取exe文件所在目录作为存档根目录
	mi_wu_json = mu_lu()

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
# json_id 存档槽位编号(0~5)
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
# json_id 存档槽位编号(0~5)
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

# 检查并修正等级
func chk_lv(data: Dictionary) -> int:
	var Exp = data.get("经验", 0)
	var lv = 1
	if Exp >= 424673280:
		lv = 4
	elif Exp >= 100776960:
		lv = 3
	elif Exp >= 13271040:
		lv = 2
	else:
		lv = 1
	# 更新数据中的等级
	data["等级"] = lv
	return lv

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
