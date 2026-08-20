class_name 玄戈 extends "res://角色/人物基类.gd"

const LV: int = 1
const HP: int = 8
const LL: int = 5
const FY: int = 10
const CT: int = 5

func _ready() -> void:
	super._ready()
	attack_n = 2

func shang_hai_hou() -> void:
	ll_add_1 += 1
