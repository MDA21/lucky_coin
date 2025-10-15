extends Node

# preload scenes
const VIEW_PATHS: Array[PackedScene] = [
	preload("res://project/scenes/views/main_menu_view.tscn"),
	preload("res://project/scenes/views/store_view.tscn"),
	preload("res://project/scenes/views/hall_view.tscn"),
	preload("res://project/scenes/views/bank_view.tscn"),
	preload("res://project/scenes/views/exit_view.tscn")
]

# 场景索引，用于使用A键和D键切换场景
const VIEW_MAP: Dictionary = {
	1: [4,2], # exit  <- store ->hall
	2: [1,3], # store <- hall  ->bank
	3: [2,4], # hall  <- bank  ->exit
	4: [3,1]  # bank  <- exit  ->store
}

const HUD_SCENE: PackedScene = preload("res://project/scenes/ui/hud.tscn")

var hud_node: CanvasLayer = null

#游戏状态
enum GameState {
	MAIN_MENU,
	IN_GAME,
	GAME_OVER
}
var current_state: GameState = GameState.MAIN_MENU

# start from scene "main_menu"

#通过数组管理场景
var current_view_index: int = 1
var current_view_node: Node = null

#当新游戏成功开始并初始化后发出此信号
signal game_started

func _ready():
	#将自身注册到Global，以便在任何地方都能访问到
	Global.game_manager = self
	
	#连接到全局的游戏结束信号。这是至关重要的一步。
	#当任何系统（如此处的债务系统）判定游戏结束时，
	#这个管理器会监听到并做出反应。
	Global.game_over_triggered.connect(_on_game_over)
	
func start_new_game():
	"""
	这个函数应该由你主菜单中的“开始游戏”按钮调用。
	它会重置所有玩家数据，并切换到主游戏场景。
	"""
	#1. 从配置文件加载默认的玩家数值
	var config = _load_game_config()
	if config and config.has("player_defaults"):
		var defaults = config.player_defaults
		Global.current_money = defaults.get("start_money", 100.0)
		Global.casino_currency = defaults.get("start_casino_currency", 10)
		Global.current_stress = defaults.get("start_stress", 0.0)
	
	# 如果需要，你也可以在这里重置其他系统的数据
	# 例如，清空银行存款：
	# Global.bank_system.savings = 0.0

	#2. 更新游戏状态
	current_state = GameState.IN_GAME
	
	#3. 发出信号，通知任何感兴趣的节点（比如HUD）游戏已经开始
	game_started.emit()
	
	# load initial scene
	# await get_tree().process_frame
	
	# 【修正】将初始视图添加到 GameManager 自身
	var initial_view: Node = VIEW_PATHS[current_view_index].instantiate()
	add_child(initial_view)
	current_view_node = initial_view
	
func _input(event: InputEvent) -> void:
	if not VIEW_MAP.has(current_view_index):
		return
		
	var next_index: int = -1
	var current_map_entry: Array = VIEW_MAP[current_view_index]
	
	if event.is_action_pressed("scene_left"):
		next_index = current_map_entry[0]
		get_viewport().set_input_as_handled()
		
	elif event.is_action_pressed("scene_right"):
		next_index = current_map_entry[1]
		get_viewport().set_input_as_handled()
		
	if next_index != -1:
		_change_view(next_index)
			
func _change_view(new_index: int) -> void:
	# 1. 前置检查：如果索引不变，则退出
	if new_index == current_view_index:
		return
	
	# 2. 断开信号并销毁旧视图
	if current_view_node != null:
		# 确保在销毁前断开信号，避免意外连接
		if current_view_node.has_signal("request_game_start"):
			if current_view_node.request_game_start.is_connected(_on_game_start_requested):
				current_view_node.request_game_start.disconnect(_on_game_start_requested)
		
		# 销毁旧视图节点
		current_view_node.queue_free()
		current_view_node = null
		
	var is_main_menu: bool = new_index == 0
	
	if is_main_menu:
		if is_instance_valid(hud_node):
			print("DEBUG: HUD SUCCESSFULLY FREED and removed.")
			hud_node.queue_free()
			hud_node = null
	else:
		if not is_instance_valid(hud_node):
			var new_hud: CanvasLayer = HUD_SCENE.instantiate()
			add_child(new_hud)
			hud_node = new_hud
			print("DEBUG: HUD SUCCESSFULLY LOADED and added as child of GameManager.")
			_update_hud_progress()
	
	# 3. 实例化新场景
	var new_view: Node = VIEW_PATHS[new_index].instantiate()
	
	# 4. 连接新视图的信号
	if new_view.has_signal("request_game_start"):
		new_view.request_game_start.connect(_on_game_start_requested)
	
	add_child(new_view)
	
	current_view_node = new_view
	current_view_index = new_index
	
	print("change to index: ", current_view_index, " (", new_view.name, ")")
	
func _on_game_start_requested():
	_change_view(2)
	
# --- 新增：金币和游戏要求数据 ---
var current_gold: float = 50.0   # 玩家当前的金币数量
var required_gold: float = 100.0 # 预设目标数量

# 在 Game Manager 中定义更新 HUD 的内部函数
func _update_hud_progress():
	if is_instance_valid(hud_node):
		hud_node.update_coin_progress(current_gold, required_gold)
		print("HUD updated")
		
# --- 新增：一个更新金币的公共函数 ---
func add_gold(amount: float):
	current_gold += amount
	# 调用步骤 2 中的函数来更新 HUD
	_update_hud_progress() 

func end_player_turn():
	"""
	这是游戏循环的核心。
	当玩家完成一个主要动作后（例如推币机结算完成后），就应该调用此函数。
	"""
	if current_state != GameState.IN_GAME:
		return

	#通知所有相关系统处理它们的回合结束逻辑
	Global.debt_system.process_end_of_round()
	Global.bank_system.process_end_of_round()
	#在这里添加任何其他需要基于回合更新的系统，但由于具体的还没说就先不加
	#例如：Global.event_system.process_end_of_round()
	
func return_to_main_menu():
	"""
	让玩家返回主菜单界面。
	"""
	current_state = GameState.MAIN_MENU
	get_tree().change_scene_to_file("res://project/scenes/views/main_menu_view.tscn")
	
func _on_game_over(reason: String):
	"""
	响应全局的 game_over_triggered 信号。
	"""
	current_state = GameState.GAME_OVER
	
	#在这里你可以显示一个特定的游戏结束画面或弹窗。
	#目前，我们只显示一个通知，并在延迟后返回主菜单。
	Global.show_notification("游戏结束: " + reason)
	
	#创建一个计时器，等待几秒钟再返回主菜单，给玩家阅读信息的时间
	var timer = get_tree().create_timer(4.0)
	await timer.timeout
	
	return_to_main_menu()

func _load_game_config() -> Dictionary:
	"""加载主游戏配置文件。"""
	var file = FileAccess.open("res://project/data/game_config.json", FileAccess.READ)
	var parsed_json = JSON.parse_string(file.get_as_text())
	return parsed_json

# is_game_won()函数，用于查看游戏是否胜利，从而改变场景状态
func is_game_won() -> bool:
	#根据金币判断是否胜利
	return current_gold >= required_gold
	
# 在出口场景中调用，用于游戏胜利并返回主菜单
func process_game_victory():
	"""
	当 ExitView 确认玩家胜利退出时调用此函数。
	它会触发游戏结束流程，并返回主菜单。
	"""
	current_state = GameState.GAME_OVER
	
	# 1. 弹出最终胜利通知 (假设 Global.show_notification 已实现)
	Global.show_notification("你成功逃离了......吗？")
	
	# 2. 等待通知显示完毕
	var timer = get_tree().create_timer(4.0)
	await timer.timeout
	
	# 3. 返回主菜单
	return_to_main_menu()
