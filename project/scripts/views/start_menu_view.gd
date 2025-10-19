extends Control

# === 【新增】定义信号，用于通知 GameManager 开始游戏 ===
signal request_game_start

# 引用StartButton节点
@onready var start_button: TextureButton = $StartButton

# GameManager 的引用可以移除，因为现在我们使用信号
# @onready var game_manager = get_node("/root/GameManager") 

func _ready():
	# 确保按钮节点有效
	if is_instance_valid(start_button):
		# 连接对应信号
		start_button.pressed.connect(_on_start_button_pressed)
	else:
		push_error("StartButton 节点未找到，无法启动游戏。")

func _on_start_button_pressed():
	'''
	处理点击事件，发送信号给 GameManager，请求开始游戏并切换到大厅视角
	'''
	print("Start Button Pressed! Requesting new game start.")
	
	# === 【关键修正】发射信号，通知 GameManager 执行 start_new_game() ===
	request_game_start.emit()
	
	# 标记事件已处理
	get_viewport().set_input_as_handled()
