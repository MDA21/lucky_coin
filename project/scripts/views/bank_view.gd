extends Control

# --- 状态常量 ---
const STATE_CLOSED = 0    # 关着的门 (默认状态)
const STATE_OPENING = 1   # 开着的门 (第一次点击后)
const STATE_INTERIOR = 2  # 银行内部 (第二次点击后)

# --- 节点引用 ---
@onready var door_view: Control = $DoorView
@onready var door_locked_sprite: Sprite2D = $DoorView/DoorClosedSprite
@onready var door_open_sprite: Sprite2D = $DoorView/DoorOpenSprite
@onready var door_area: Area2D = $DoorView/DoorArea

@onready var bank_interior_view: Control = $BankInteriorView
@onready var loan_area: Area2D = $BankInteriorView/LoanArea

# --- 状态变量 ---
var current_bank_state: int = STATE_CLOSED
# 【TODO】加载 LoanView 场景，在你创建 LoanView.tscn 后取消注释
# @onready var loan_view_scene: PackedScene = preload("res://project/scenes/ui/LoanView.tscn") 
# @onready var game_manager = get_node("/root/GameManager")

# --- 核心逻辑：状态切换 ---

func _set_view_state(new_state: int):
	"""
	根据新的状态值切换场景的可见视图（门关/门开/银行内部）。
	"""
	current_bank_state = new_state
	
	match new_state:
		STATE_CLOSED:
			# 状态 0: 关着的门
			door_view.visible = true
			bank_interior_view.visible = false
			
			door_locked_sprite.visible = true
			door_open_sprite.visible = false
			
		STATE_OPENING:
			# 状态 1: 开着的门
			door_view.visible = true
			bank_interior_view.visible = false
			
			door_locked_sprite.visible = false
			door_open_sprite.visible = true
			
		STATE_INTERIOR:
			# 状态 2: 银行内部
			door_view.visible = false
			bank_interior_view.visible = true
			
		_:
			pass # 保持当前状态不变

# --- 初始化 ---

func _ready():
	# 确保初始状态设置正确
	_set_view_state(STATE_CLOSED)
	
	# 连接两个 Area2D 的点击信号
	door_area.input_event.connect(_on_door_area_input_event)
	loan_area.input_event.connect(_on_loan_area_input_event)


# --- 信号处理 ---

func _on_door_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理 DoorArea 的点击事件，将状态从 0 -> 1 -> 2 推进。
	"""
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	match current_bank_state:
		STATE_CLOSED:
			# 第一次点击：关着的门 -> 开着的门
			_set_view_state(STATE_OPENING)
			
		STATE_OPENING:
			# 第二次点击：开着的门 -> 银行内部
			_set_view_state(STATE_INTERIOR)
			
		STATE_INTERIOR:
			# 可选：如果进入内部后点击门区域，可能用于退出，这里暂时保持不变
			pass
			
	get_viewport().set_input_as_handled()


func _on_loan_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理 LoanArea 的点击事件，在 STATE_INTERIOR 状态下弹出 LoanView。
	"""
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	if current_bank_state == STATE_INTERIOR:
		# 【TODO】实例化 LoanView 并显示
		# _show_loan_view() 
		
		# 暂时显示一个调试信息，直到 LoanView 完成
		print("DEBUG: 弹出 LoanView 弹窗")
		get_viewport().set_input_as_handled()
