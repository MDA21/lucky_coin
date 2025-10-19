extends Control

# --- 节点引用 ---
@onready var remote_view: Control = $RemoteView
@onready var close_up_area: Area2D = $RemoteView/CloseUpArea # 远景中用于点击的 Area

@onready var closeup_view: Control = $CloseUpView
@onready var items_container: Control = $CloseUpView/ItemContainer
@onready var refresh_area: Area2D = $CloseUpView/RefreshPanel/RefreshArea
@onready var refresh_price_label: Label = $CloseUpView/RefreshPanel/RefreshPriceLabel

# --- 状态 ---
var is_close_up: bool = false
@onready var game_manager = get_node("/root/GameManager") # 保持对 GameManager 的引用

# --- 初始化 ---

func _ready():
	# 1. 初始设置视图为远景
	_set_view(false)
	
	# 2. 连接远景点击区域的信号
	# 注意：这里的信号应在编辑器中连接或使用代码连接
	close_up_area.input_event.connect(_on_close_up_area_input_event)
	
# 【新增】：连接刷新区域的输入事件信号
	if is_instance_valid(refresh_area):
		refresh_area.input_event.connect(_on_refresh_area_input_event)
	else:
		push_error("RefreshArea 节点缺失，无法连接刷新信号！")

# --- 核心逻辑：视图切换 ---

func _set_view(to_close_up: bool):
	"""
	切换远景和近景的可见性。
	"""
	is_close_up = to_close_up
	
	remote_view.visible = not to_close_up
	closeup_view.visible = to_close_up

# --- 输入处理：ESC 返回远景 ---

func _input(event: InputEvent):
	"""
	处理 Esc 键按下事件，用于退出近景视图。
	"""
	if event.is_action_pressed("ui_cancel"): # ui_cancel 通常绑定 Esc 键
		if is_close_up:
			# 如果当前是近景，则切换回远景
			_set_view(false)
			get_viewport().set_input_as_handled()
			
# --- 信号处理：远景点击 ---

func _on_close_up_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理远景点击事件，切换到近景。
	"""
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	if not is_close_up:
		# 切换到近景
		_set_view(true)
		get_viewport().set_input_as_handled()
		
func _on_refresh_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理 RefreshArea 的点击事件。
	"""
	# 仅处理鼠标左键按下事件（与你的 close_up_area 逻辑类似）
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	# 确保在近景模式下才能点击刷新（可选的逻辑检查）
	if is_close_up:
		print("Refresh Area Clicked! Triggering shop refresh...")
		# 【TODO】：在这里调用 GameManager 或 ShopSystem 的刷新函数
		# 例如：game_manager.shop_system.refresh_items() 
		
		get_viewport().set_input_as_handled()
