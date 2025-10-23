extends Control

# 定义一个信号，用于向上通知 GameManager 切换场景
# GameManager 应该连接这个信号。
signal view_clicked(target_index)

# === 节点引用 ===

# 远景点击区域，用于跳转到 ChannelView
@onready var channel_view_area: Area2D = $ChannelViewArea 

@onready var coin_animator: AnimationPlayer = $CoinAnimator
@onready var coin_drop_animation: AnimatedSprite2D = $CoinUILayer/CoinDropAnimation
@onready var coin_popup: TextureRect = $CoinUILayer/CoinPopup 
@onready var amount_label: Label = $CoinUILayer/CoinPopup/AmountLabel

# 假设 GameManager 已经将 channel_view.tscn 注册到 VIEW_PATHS 的索引 5
# 请根据你的实际配置修改这个索引
const CHANNEL_VIEW_INDEX = 5 

# 用于管理场景切换，在动画播放时禁止场景切换
var is_scene_switch_locked: bool = false

# === 初始化 ===

func _ready():
	coin_drop_animation.visible = false
	coin_drop_animation.frame = 0 # 确保动画帧重置到第 0 帧
	
	coin_animator.animation_finished.connect(_on_coin_sequence_finished)
	# 确保 Area2D 节点有效
	if is_instance_valid(channel_view_area):
		# 连接 Area2D 的 input_event 信号到处理函数
		channel_view_area.input_event.connect(_on_channel_view_area_input_event)
	else:
		push_error("ChannelViewArea 节点缺失或路径错误，无法实现点击跳转。")
	pass

# 调试函数：用于模拟外部信号触发（已删除）

# === 信号处理：点击跳转 ===

func _on_channel_view_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理 Area2D 接收到的输入事件。
	
	_viewport: 忽略，通常是根视口。
	event: 发生的输入事件。
	_shape_idx: 忽略，当 Area2D 有多个形状时使用。
	"""
	
	if is_scene_switch_locked:
		get_viewport().set_input_as_handled()
		return
	
	# 1. 仅处理鼠标左键按下事件 (即玩家点击)
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	# 2. 检查事件是否应该被忽略（例如，如果游戏暂停或有弹窗打开）
	# 这里可以根据需要添加 Global.game_manager.current_state 检查
	
	# 3. 发射信号通知 GameManager 切换场景
	print("HallView: Clicked Area to switch to ChannelView (Index ", CHANNEL_VIEW_INDEX, ")")
	view_clicked.emit(CHANNEL_VIEW_INDEX)
	
	# 4. 标记事件已处理，防止事件穿透到背景或其他场景
	get_viewport().set_input_as_handled()

# 外部系统将连接并调用这个函数，传入硬币数量
func _on_coin_drop_signal_received(get_coin_amount: float):
	"""
	接收到 Coin_Drop_Signal 信号后，启动动画序列。
	"""
	# 禁止场景切换
	is_scene_switch_locked = true
	
	# 1. 设置弹窗显示的金额
	amount_label.text = str(get_coin_amount)
	
	# 2. 重置弹窗状态（确保从透明和不可见开始）
	coin_popup.modulate = Color(1, 1, 1, 0) # 弹窗先设为透明
	coin_popup.visible = false
	coin_drop_animation.visible = true
	coin_drop_animation.frame = 0
	
	# 3. 启动 AnimationPlayer 动画序列
	# 动画开始，0.0s处的关键帧会使硬币可见并播放
	coin_animator.play("CoinSequence")

# === 供 AnimationPlayer 调用的函数 ===

func _show_coin_popup():
	"""
	在 1.0s 时被 CoinAnimator 调用。
	【要求 2: 在动画播放延时约0.5s后，场景出现弹窗】
	"""
	
	# 1. 确保弹窗节点可见
	coin_popup.visible = true
	
	# 2. 使用 Tween 实现平滑淡入（0.3秒淡入）
	var tween = create_tween()
	tween.tween_property(coin_popup, "modulate", Color(1, 1, 1, 1), 0.3)


func _hide_coin_popup():
	"""
	在 2.5s 时被 CoinAnimator 调用。
	【要求 3: 在弹窗持续约1.5s后，弹窗消失，动画也不可见】
	"""
	
	print("Hiding!")
	
	coin_drop_animation.visible = false
	# 1. 使用 Tween 实现平滑淡出 (0.3秒淡出)
	var tween = create_tween()
	tween.tween_property(coin_popup, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# 2. 等待淡出效果播放完毕
	await tween.finished
	
	# 3. 清理弹窗
	coin_popup.visible = false
	

func _on_coin_sequence_finished(anim_name: StringName):
	"""
	在 AnimationPlayer 完成动画后自动调用。
	"""
	# 解锁场景切换
	is_scene_switch_locked = false
	
	if anim_name == "CoinSequence":
		coin_animator.stop()
