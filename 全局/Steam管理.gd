extends Node
# Steam 管理单例：初始化 Steamworks、每帧驱动回调、成就上报
# 依赖 GodotSteam GDExtension（addons/godotsteam）；未初始化成功时所有功能静默降级，不影响游戏运行

# Steam AppID
const APP_ID: int = 5484320
# 成就索引 → Steam 后台 API 名映射（必须与 Steamworks 后台 Stats & Achievements 中创建的 API 名完全一致）
# 0=不朽者 1=救世主 2=饮虹使 3=采花贼（顺序与 树屋.gd ach_data 一致，后续新增成就在末尾追加即可）
const ACH_API: Array = ["ACH_BU_XIU_ZHE", "ACH_Hero", "ACH_YIN_HONG_SHI", "ACH_CAI_HUA_ZEI"]

# Steam 是否可用（仅初始化成功为 true，编辑器直跑/无 Steam 客户端/离线时为 false）
var ke_yong: bool = false
# 启动时的成就补同步是否已执行（user_stats_received 可能多次触发，只同步一次）
var yi_tong_bu: bool = false

func _ready() -> void:
	# 初始化 Steamworks 并传入 AppID；失败时降级为不可用（非 Steam 环境游戏照常运行）
	var jie_guo: Dictionary = Steam.steamInitEx(APP_ID)
	if int(jie_guo.get("status", 1)) == 0:
		ke_yong = true
		# 拉取当前用户成就状态，回调里做本地历史成就补同步
		Steam.user_stats_received.connect(_on_user_stats_received)
		# 本版本 GodotSteam 未提供 requestCurrentStats，改用 requestUserStats(当前用户 SteamID) 拉取自身统计数据
		Steam.requestUserStats(Steam.getSteamID())
	else:
		日志.打印("Steam 初始化失败（成就上报不可用，游戏正常运行）：" + str(jie_guo.get("verbal", jie_guo)))

func _process(_delta: float) -> void:
	# Steamworks 需要每帧驱动回调（成就解锁弹窗、状态回执等都依赖它）
	if ke_yong:
		Steam.run_callbacks()

# 用户成就状态拉取完成回调：本地通用存档历史成就已达成但 Steam 端未解锁的，补解锁（覆盖旧存档/离线游玩场景）
func _on_user_stats_received(_game_id: int, _result: int, _steam_id: int) -> void:
	if yi_tong_bu:
		return
	yi_tong_bu = true
	# 游戏存档非 autoload，临时实例化仅用于读取通用存档（du_qu_ty 内部会自动初始化路径）
	var cun_dang = 游戏存档.new()
	for i in range(ACH_API.size()):
		if cun_dang.has_ach_ty(i):
			var zhuang_tai: Dictionary = Steam.getAchievement(ACH_API[i])
			if not zhuang_tai.get("achieved", false):
				jie_suo(i)
	cun_dang.free()

# 解锁成就并立即上传；ach_idx 为游戏内成就索引（对应 ACH_API 映射），Steam 不可用时静默跳过
func jie_suo(ach_idx: int) -> void:
	if not ke_yong:
		return
	if ach_idx < 0 or ach_idx >= ACH_API.size():
		return
	var api_ming: String = ACH_API[ach_idx]
	Steam.setAchievement(api_ming)
	Steam.storeStats()
