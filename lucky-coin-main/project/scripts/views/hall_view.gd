extends "res://project/scripts/views/base_view.gd" 

# 这里是你将来要引用的节点，例如推币机入口
# @onready var coin_pusher_entrance: Area2D = $WorldContainer/CoinPusherEntrance 
@onready var lever_area: Area2D = $LeverSprite/LeverArea
@onready var lever_animator: AnimationPlayer = $LeverSprite/LeverAnimator

signal lever_pulled

func _ready():
	# 这一行是必须的！它调用了 base_view.gd 中的 _ready() 函数，
	# 从而触发了背景设置、强制布局刷新等所有通用功能。
	super._ready()
	
	print("Hall View Loaded and Ready.")
	
	lever_area.input_event.connect(_on_lever_area_input_event)

func _on_lever_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		if lever_animator.is_playing():
			return
		
		print("拉杆拉下")
		
		play_lever_animation()
		
		get_viewport().set_input_as_handled()
		
func play_lever_animation():
	lever_animator.play("pull")
	
	lever_animator.animation_finished.connect(_on_pull_animation_finished, CONNECT_ONE_SHOT)
	
func _on_pull_animation_finished(anim_name: StringName):
	if anim_name == "pull":
		print("播放完毕")
		emit_signal("lever_pulled")
		
		lever_animator.play("idle")
	
