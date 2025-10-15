extends Control

const STATE_LOCKED = 0
const STATE_UNLOCKED = 1
const STATE_OPEN = 2

const TEX_LOCKED_FAR: Texture2D = preload("res://project/assets/photo/exit_locked_far.jpg")
const TEX_UNLOCKED: Texture2D = preload("res://project/assets/photo/exit_unlocked.png")
const TEX_ON: Texture2D = preload("res://project/assets/photo/exit_on.png")
const TEX_LOCKED_CLOSE: Texture2D = preload("res://project/assets/photo/exit_locked_close.jpg")

@onready var remote_view: Control = $RemoteView
@onready var remote_door_sprite: Sprite2D = $RemoteView/RemoteDoorSprite
@onready var remote_door_area: Area2D = $RemoteView/RemoteDoorArea

@onready var closeup_view: Control = $CloseUpView
@onready var closeup_door_area: Area2D = $CloseUpView/CloseUpDoorArea

@onready var notification_popup_scene: PackedScene = preload("res://project/scenes/ui/NotificationPopup.tscn")
@onready var game_manager = get_node("/root/GameManager")

var current_door_state: int = STATE_LOCKED 
var is_close_up: bool = false

# 视图切换辅助函数
func _set_view(to_close_up: bool):
	is_close_up = to_close_up
	
	remote_view.visible = not to_close_up
	closeup_view.visible = to_close_up

# 显示通知弹窗函数
func _show_popup(message: String):
	var popup_instance = notification_popup_scene.instantiate()
	
	# 将弹窗添加到场景树的根节点，确保在最顶层渲染
	get_tree().root.add_child(popup_instance)
	
	# 调用弹窗脚本的 show_message 方法
	if popup_instance.has_method("show_message"):
		popup_instance.show_message(message)
		
# 初始化函数
func _ready():
	# 1. 初始化游戏状态：检查全局胜利状态
	
	if game_manager.is_game_won(): # 调用 GameManager 的 is_game_won() 方法
		current_door_state = STATE_UNLOCKED
	else:
		current_door_state = STATE_LOCKED
		
	# 2. 初始化视图可见性：默认显示远景
	_set_view(false) # 设置 is_close_up = false
		
	# 3. 设置初始远景贴图 (近景贴图已在编辑器中设置)
	_update_remote_sprite()
	
	# 4. 连接点击信号 (始终连接，但在不同状态下逻辑不同)
	remote_door_area.input_event.connect(_on_remote_door_input_event)
	closeup_door_area.input_event.connect(_on_closeup_door_input_event)
	
# 负责远景三张图片切换
func _update_remote_sprite():
	match current_door_state:
		STATE_LOCKED:
			remote_door_sprite.texture = TEX_LOCKED_FAR
		STATE_UNLOCKED:
			remote_door_sprite.texture = TEX_UNLOCKED
		STATE_OPEN:
			remote_door_sprite.texture = TEX_ON
		
# 近景视图点击
func _on_closeup_door_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return

	# 动作：弹出警告
	_show_popup("你不能出去！")
		
	get_viewport().set_input_as_handled()
	
# 远景视图点击处理
func _on_remote_door_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	match current_door_state:
		STATE_LOCKED:
			# --- 流程 1: 未胜利，远景上锁 (第一次点击) ---
			
			# 动作：切换到近景视图
			_set_view(true) # 隐藏远景，显示近景
			# 玩家的下一次点击将由 _on_closeup_door_input_event 处理
			
		STATE_UNLOCKED:
			# --- 流程 2: 胜利，远景未上锁 (第一次点击) ---
			
			# 动作：将门的状态切换为 STATE_OPEN
			current_door_state = STATE_OPEN
			
			# 动作：更新远景 Sprite 贴图为 exit_on.png (开着的门)
			_update_remote_sprite()
			# 玩家的下一次点击将触发 STATE_OPEN 分支
			
		STATE_OPEN:
			# --- 流程 3: 胜利，远景开着的门 (第二次点击) ---
			
			# 动作：弹出胜利信息
			_show_popup("游戏胜利")
			
			# 动作：跳转至某个场景 / 结束游戏 (TODO: 待实现)
			game_manager.change_to_end_screen() 
			
	get_viewport().set_input_as_handled()
