extends Node

# preload scenes
const VIEW_PATHS: Array[PackedScene] = [
	preload("res://project/scenes/views/main_menu_view.tscn"),
	preload("res://project/scenes/views/store_view.tscn"),
	preload("res://project/scenes/views/hall_view.tscn"),
	preload("res://project/scenes/views/bank_view.tscn")
]

const HUD_SCENE: PackedScene = preload("res://project/scenes/ui/hud.tscn")

var hud_node: CanvasLayer = null

# start from scene "main_menu"
var current_view_index: int = 0
var current_view_node: Node = null

func _ready():
	# load initial scene
	# await get_tree().process_frame
	
	# 【修正】将初始视图添加到 GameManager 自身
	var initial_view: Node = VIEW_PATHS[current_view_index].instantiate()
	add_child(initial_view)
	current_view_node = initial_view
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scene_left"):
		if current_view_index > 1:
			_change_view(current_view_index-1)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("scene_right"):
		if current_view_index < VIEW_PATHS.size() - 1:
			_change_view(current_view_index + 1)
			get_viewport().set_input_as_handled()
			
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
var required_gold: float = 100.0 # 玩一次推币机所需的金币数量

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
