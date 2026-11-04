extends Node
# Steam 管理单例：初始化 Steamworks、每帧驱动回调、成就上报
# 依赖 GodotSteam GDExtension（addons/godotsteam）；未初始化成功时所有功能静默降级，不影响游戏运行

# Steam AppID
const APP_ID: int = 5484320
# 成就序号 → Steam 后台 API 名映射（必须与 Steamworks 后台 Stats & Achievements 中创建的 API 名完全一致）
# 序号为4位字符串（保留前导零），与 树屋.gd ach_data 的序号一致；新增成就只需按序号追加键值
const ACH_API: Dictionary = {
	"1000": "ACH_BU_XIU_ZHE",   # 不朽者
	"0001": "ACH_Hero",          # 救世主Ⅰ
	"0002": "ACH_Hero_2",       # 救世主Ⅱ
	"1001": "ACH_YIN_HONG_SHI",  # 饮虹使
	"1004": "ACH_CAI_HUA_ZEI",   # 采花贼
	"0107": "ACH_A7",            # A7富豪
	"0108": "ACH_A8",            # A8富豪
	"0109": "ACH_A9",            # A9富豪
	"0110": "ACH_A10",           # A10富豪
	"0111": "ACH_A11",           # A11富豪
	"0112": "ACH_A12",           # A12富豪
	"0113": "ACH_A13",           # A13富豪
	"0114": "ACH_A14",           # A14富豪
	"0115": "ACH_A15",           # A15富豪
	"0116": "ACH_A16",           # A16富豪
}

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
	for xu_hao in ACH_API:
		if cun_dang.has_ach_ty(xu_hao):
			var zhuang_tai: Dictionary = Steam.getAchievement(ACH_API[xu_hao])
			if not zhuang_tai.get("achieved", false):
				jie_suo(xu_hao)
	cun_dang.free()

# 解锁成就并立即上传；xu_hao 为游戏内成就序号（对应 ACH_API 映射），Steam 不可用时静默跳过
func jie_suo(xu_hao: String) -> void:
	if not ke_yong:
		return
	if not ACH_API.has(xu_hao):
		return
	var api_ming: String = ACH_API[xu_hao]
	Steam.setAchievement(api_ming)
	Steam.storeStats()
