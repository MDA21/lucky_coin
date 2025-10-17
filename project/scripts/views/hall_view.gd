extends "res://project/scripts/views/base_view.gd" 

# 这里是你将来要引用的节点，例如推币机入口
# @onready var coin_pusher_entrance: Area2D = $WorldContainer/CoinPusherEntrance 
@onready var lever_area: Area2D = $LeverSprite/LeverArea
@onready var lever_animator: AnimationPlayer = $LeverSprite/LeverAnimator

# 倍率选择与观察模式（简化占位）
var current_multiplier: float = 1.0
var is_observation_mode: bool = false

signal lever_pulled

func _ready():
	# 这一行是必须的！它调用了 base_view.gd 中的 _ready() 函数，
	# 从而触发了背景设置、强制布局刷新等所有通用功能。
	super._ready()
	
	print("Hall View Loaded and Ready.")
	
	lever_area.input_event.connect(_on_lever_area_input_event)
	# 订阅全局小回合开始/结束（可用于重置UI状态）
	Global.sub_round_started.connect(_on_sub_round_started)
	Global.sub_round_ended.connect(_on_sub_round_ended)

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
		# 拉杆后进入观察阶段（第一次拉杆）：
		is_observation_mode = true
		_show_observation_overlay(true)

# 选择倍率（例如由UI按钮调用）
func set_multiplier(mult: float):
	current_multiplier = max(1.0, mult)

# 观察阶段切换显示（占位：后续可替换为实际UI控件）
func _show_observation_overlay(visible: bool):
	# 这里预留接口以展示观察提示、倍率按钮等
	pass

func _on_sub_round_started(_major_round: int, _sub_round: int):
	# 新小回合：重置观察与倍率
	is_observation_mode = false
	current_multiplier = 1.0
	_show_observation_overlay(false)

func _on_sub_round_ended(_major_round: int, _sub_round: int):
	# 小回合结束：清理状态
	_show_observation_overlay(false)
	
