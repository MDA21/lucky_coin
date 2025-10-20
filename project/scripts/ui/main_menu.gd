extends Control

# 定义信号，用于通知 GameManager 执行流程控制操作
signal return_to_main_menu_requested
signal menu_closed # 通知 GameManager 销毁菜单节点

# --- 节点引用 (@onready 路径必须与你的最终场景结构匹配) ---
@onready var close_button: TextureButton = $MenuContainer/MenuContent/CloseButton
@onready var return_button: TextureButton = $MenuContainer/MenuContent/ButtonContainer/ReturnButton
@onready var quit_button: TextureButton = $MenuContainer/MenuContent/ButtonContainer/QuitButton


func _ready():
	# 1. 立即暂停游戏
	# 确保根节点 MainMenu 的 Process Mode 已设置为 When Paused
	get_tree().paused = true
	
	# 2. 连接 UI 按钮信号
	close_button.pressed.connect(_on_close_button_pressed)
	return_button.pressed.connect(_on_return_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _unhandled_input(event: InputEvent):
	# 3. 处理 ESC 键输入 (ui_cancel 通常映射到 ESC 键)
	# 由于此脚本的 Process Mode 是 When Paused，它只在暂停时才接收输入
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
		# 标记事件已处理，防止输入穿透
		get_viewport().set_input_as_handled()


# --- 内部方法 ---

func _close_menu():
	""" 恢复游戏并通知 GameManager 卸载菜单。 """
	
	# 1. 恢复游戏运行
	get_tree().paused = false
	
	# 2. 发出信号，通知 GameManager 销毁这个菜单节点
	menu_closed.emit()


# --- 信号连接函数 ---

func _on_close_button_pressed():
	""" X 按钮被点击时关闭菜单。 """
	_close_menu()

func _on_return_button_pressed():
	""" 返回主菜单按钮被点击。 """
	
	# 1. 恢复游戏运行 (切换场景必须在非暂停状态下进行)
	get_tree().paused = false
	
	# 2. 发出信号，请求 GameManager 切换到主菜单 (索引 0)
	return_to_main_menu_requested.emit()

func _on_quit_button_pressed():
	""" 退出游戏按钮被点击。 """
	
	# 1. 恢复游戏运行
	get_tree().paused = false
	
	# 2. 请求退出游戏 (Godot 内置功能)
	get_tree().quit()
