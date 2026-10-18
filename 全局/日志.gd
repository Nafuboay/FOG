extends Node
# 全局日志单例：print输出到控制台的同时，把内容追加写入 迷雾存档/日志.txt

# 日志文件大小上限：1MB
const DA_XIAO_SHANG_XIAN: int = 1024 * 1024
# 日志文件完整路径（_ready时初始化）
var lu_jing: String = ""

func _ready() -> void:
	# 日志文件存放在存档目录（编辑器=项目目录，桌面端=exe同目录）
	lu_jing = 游戏存档.mu_lu() + "/日志.txt"

# 打印并记录一条日志（替代print，控制台输出保持原样）
func 打印(nei_rong) -> void:
	print(nei_rong)
	_xie_ru(str(nei_rong))

# 把内容追加写入日志文件，写入前检查大小是否超限
func _xie_ru(nei_rong: String) -> void:
	# 确保存档目录存在（幂等，目录已存在时无害）
	DirAccess.make_dir_recursive_absolute(游戏存档.mu_lu())
	# 文件不存在则先创建空文件（READ_WRITE模式不会自动创建文件）
	if not FileAccess.file_exists(lu_jing):
		var xin: FileAccess = FileAccess.open(lu_jing, FileAccess.WRITE)
		if xin == null:
			return
		xin.close()
	# 写入前检查大小，超过1MB删除一半旧内容
	_jian_cha_da_xiao()
	# 以读写方式打开并定位到末尾追加
	var f: FileAccess = FileAccess.open(lu_jing, FileAccess.READ_WRITE)
	if f == null:
		return
	f.seek_end()
	# 每行带真实时间戳前缀，格式 [2026-10-18 14:30:05]
	f.store_line("[%s] %s" % [Time.get_datetime_string_from_system(false, true), nei_rong])
	f.close()

# 超过上限时从文件中间截断，跳过被切断的半行，保留较新的一半重写
func _jian_cha_da_xiao() -> void:
	var f: FileAccess = FileAccess.open(lu_jing, FileAccess.READ)
	if f == null:
		return
	var da_xiao: int = f.get_length()
	if da_xiao <= DA_XIAO_SHANG_XIAN:
		f.close()
		return
	# 定位到文件中间（>>1即除以2取整），丢弃被切断的半行，从下一行行首开始保留
	f.seek(da_xiao >> 1)
	f.get_line()
	var bao_liu: PackedByteArray = f.get_buffer(f.get_length() - f.get_position())
	f.close()
	# 重写文件为保留的后半部分
	var w: FileAccess = FileAccess.open(lu_jing, FileAccess.WRITE)
	if w == null:
		return
	w.store_buffer(bao_liu)
	w.close()
