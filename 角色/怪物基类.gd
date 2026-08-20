extends Node2D
# 攻击触发信号
# signal attack_xin_hao
# 怪物基类
# 动画精灵节点引用
@onready var s: AnimatedSprite2D = $AnimatedSprite2D
# 是否处于待机状态
var idle: bool = true
# 是否处于战斗模式
var zhan_dou: bool = false
# 是否处于攻击动画
var attack: bool = false
# 当前timer的ID
var id: int = 0
# 结束
var end: bool = false

# 节点就绪时调用
func _ready() -> void:
	s.animation_finished.connect(attack_end)
	play_idle()

# 播放待机动画
func play_idle(jin: bool = false) -> void:
	if jin:
		if not zhan_dou:
			return
		end = true
		return
	zhan_dou = false
	end = true
	zhan_dou = false
	end = false
	attack = false
	id += 1  # 使之前的timer失效
	if s.sprite_frames and s.sprite_frames.has_animation("idle"):
		s.play("idle")
		s.speed_scale = 0.4
		idle = true

# 播放战斗动画
func play_zhan_dou() -> void:
	zhan_dou = true
	if s.sprite_frames and s.sprite_frames.has_animation("idle"):
		s.play("idle")
		s.speed_scale = 0.4
		idle = true

# 切换到战斗模式
func zhan_dou_ing() -> void:
	if zhan_dou:
		return
	zhan_dou = true
	if s.sprite_frames and s.sprite_frames.has_animation("idle"):
		s.play("idle")
		idle = true

# 播放攻击动画
func play_attack(jin: bool = false) -> bool:
	if zhan_dou and not jin:
		pass
	elif not idle:
		return false
	if jin and zhan_dou:
		return false
	id += 1
	if s.sprite_frames and s.sprite_frames.has_animation("attack"):
		zhan_dou = true
		s.play("attack")
		s.speed_scale = 1.0
		idle = false
		attack = true
		che_tui()
		# attack_xin_hao.emit()
		return true
	return false

# 继续战斗
func attack_end() -> void:
	if s.animation == "attack":
		if attack:
			play_zhan_dou()
		else:
			play_idle()

# 撤退
func che_tui() -> void:
	var current_id: int = id
	await get_tree().create_timer(1).timeout
	if current_id != id:
		return
	if end:
		end = false
		attack = false
		play_idle()
	elif attack:
		play_attack()
