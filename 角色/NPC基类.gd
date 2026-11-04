# NPC基类
extends Node2D
@onready var s: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	play_idle()

# 获取当前基础帧率对应的动画播放速度（实际帧率=基础帧率×倍率，倍率目前为1）
func dong_hua_su_du() -> float:
	var json = get_node_or_null("/root/游戏存档")
	if json != null:
		return json.get_dong_hua_su_du()
	# 存档节点尚未创建时按默认24帧率返回（资源原始帧率60）
	return 0.4

func play_idle() -> void:
	if s.sprite_frames and s.sprite_frames.has_animation("idle"):
		s.play("idle")
		s.speed_scale = dong_hua_su_du()
