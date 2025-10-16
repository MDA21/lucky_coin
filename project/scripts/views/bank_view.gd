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
var current_loan_popup: CanvasLayer = null # 【新增】用于保存弹窗实例的引用
# 加载 LoanView 场景
@onready var loan_view_scene: PackedScene = preload("res://project/scenes/views/loan_view.tscn") 
@onready var game_manager = get_node("/root/GameManager") # 假设 GameManager 是单例

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

# --- 弹窗管理函数 (新增) ---

func _show_loan_view():
	"""
	实例化并显示 LoanView 弹窗。
	"""
	if is_instance_valid(current_loan_popup):
		return # 防止重复创建弹窗

	var loan_popup_instance = loan_view_scene.instantiate()
	# 确保 LoanView 脚本已定义 loan_view_closed 信号
	if not loan_popup_instance.has_signal("loan_view_closed"):
		push_error("LoanView 脚本未定义 'loan_view_closed' 信号!")
		return
		
	current_loan_popup = loan_popup_instance
	
	# 将弹窗添加到场景树的根节点，确保在最顶层渲染
	get_tree().root.add_child(loan_popup_instance)
	
	# 连接弹窗发出的关闭信号
	loan_popup_instance.loan_view_closed.connect(_on_loan_view_closed)
	
func _on_loan_view_closed():
	"""
	响应 LoanView 发出的关闭信号，销毁弹窗实例。
	"""
	if is_instance_valid(current_loan_popup):
		# 销毁弹窗，释放内存
		current_loan_popup.queue_free()
		current_loan_popup = null


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
		
	# 如果弹窗正在显示，阻止门区域的交互
	if is_instance_valid(current_loan_popup):
		get_viewport().set_input_as_handled()
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
		
	# 如果弹窗正在显示，阻止重复显示
	if is_instance_valid(current_loan_popup):
		get_viewport().set_input_as_handled()
		return
		
	if current_bank_state == STATE_INTERIOR:
		# 实例化 LoanView 并显示
		_show_loan_view() 
		get_viewport().set_input_as_handled()
