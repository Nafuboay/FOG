# NPC基类
extends Node2D
@onready var s: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	play_idle()

func play_idle() -> void:
	if s.sprite_frames and s.sprite_frames.has_animation("idle"):
		s.play("idle")
		s.speed_scale = 0.4
