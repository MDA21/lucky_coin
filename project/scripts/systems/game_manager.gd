extends Node

# preload scenes
const VIEW_PATHS: Array[PackedScene] = [
	preload("res://project/scenes/views/start_menu_view.tscn"),
	preload("res://project/scenes/views/store_view.tscn"),
	preload("res://project/scenes/views/hall_view.tscn"),
	preload("res://project/scenes/views/bank_view.tscn"),
	preload("res://project/scenes/views/exit_view.tscn"),
	preload("res://project/scenes/views/channel_view.tscn")
]

# 场景索引，用于使用A键和D键切换场景
const VIEW_MAP: Dictionary = {
	1: [4,2], # exit  <- store ->hall
	2: [1,3], # store <- hall  ->bank
	3: [2,4], # hall  <- bank  ->exit
	4: [3,1]  # bank  <- exit  ->store
}

# 加载主UI
const HUD_SCENE: PackedScene = preload("res://project/scenes/ui/hud.tscn")
var hud_node: CanvasLayer = null

# 加载主菜单UI
const MAIN_MENU_SCENE: PackedScene = preload("res://project/scenes/ui/main_menu.tscn")
var pause_menu_node: Control = null

#游戏状态
enum GameState {
	MAIN_MENU,
	IN_GAME,
	GAME_OVER
}
var current_state: GameState = GameState.MAIN_MENU

# start from scene "main_menu"

#通过数组管理场景
var current_view_index: int = 0
var current_view_node: Node = null

# --- 系统引用 ---
var currency_system: Node = null
var stress_system: Node = null
var debt_system: Node = null
var coin_system: Node = null
var shop_system: Node = null
var bank_system: Node = null
var event_system: Node = null
var pattern_system: Node = null

var total_settlement_money: int = 0
var settlement_stress_change: int = 0

#当新游戏成功开始并初始化后发出此信号
signal game_started

func _ready():
	# 初始化所有子系统引用
	_initialize_systems()
	
	#将自身注册到Global，以便在任何地方都能访问到
	Global.game_manager = self
	Global.on_game_manager_ready(self)
	#连接到全局的游戏结束信号。这是至关重要的一步。
	#当任何系统（如此处的债务系统）判定游戏结束时，
	#这个管理器会监听到并做出反应。
	Global.game_over.connect(_on_global_game_over)
	
	call_deferred("_initialize_start_view")

func _initialize_systems():
	"""初始化所有子系统引用"""
	# 获取所有子系统节点
	currency_system = get_node_or_null("CurrencySystem")
	stress_system = get_node_or_null("StressSystem")
	debt_system = get_node_or_null("DebtSystem")
	coin_system = get_node_or_null("CoinSystem")
	shop_system = get_node_or_null("ShopSystem")
	bank_system = get_node_or_null("BankSystem")
	event_system = get_node_or_null("EventSystem")
	pattern_system = get_node_or_null("PatternSystem")
	
	# 打印系统初始化状态用于调试
	print("=== GameManager System Initialization ===")
	print("CurrencySystem: ", "✓" if currency_system else "✗")
	print("StressSystem: ", "✓" if stress_system else "✗")
	print("DebtSystem: ", "✓" if debt_system else "✗")
	print("CoinSystem: ", "✓" if coin_system else "✗")
	print("ShopSystem: ", "✓" if shop_system else "✗")
	print("BankSystem: ", "✓" if bank_system else "✗")
	print("EventSystem: ", "✓" if event_system else "✗")
	print("PatternSystem: ", "✓" if pattern_system else "✗")
	
	# 连接债务系统信号
	_connect_debt_system_signals()
	
	# 通知 Global 系统已初始化
	call_deferred("_notify_global_systems_ready")

func _connect_debt_system_signals():
	"""连接债务系统信号"""
	if debt_system:
		if debt_system.has_signal("game_victory"):
			debt_system.game_victory.connect(_on_debt_system_victory)
		if debt_system.has_signal("all_debts_completed"):
			debt_system.all_debts_completed.connect(_on_all_debts_completed)

func _notify_global_systems_ready():
	"""通知 Global 系统已准备就绪"""
	if Global.has_method("initialize_system_references"):
		Global.initialize_system_references()
	
func _initialize_start_view():
	var initial_view: Node = null
	
	# 尝试直接获取 StartMenuView 节点
	# 查找 /root/ 下的唯一一个不是 Autoload 的节点
	for child in get_tree().get_root().get_children():
		# 检查当前子节点是否是我们期望的 StartMenuView 场景实例
		# 通过比较其场景文件路径和 VIEW_PATHS[0] 的路径来判断
		var is_start_menu = false
		
		if child.get_scene_file_path() == VIEW_PATHS[0].get_path():
			is_start_menu = true
			
		if is_start_menu:
			initial_view = child
			break

	# 确保我们找到了节点
	if is_instance_valid(initial_view):
		
		# 1. 验证 StartMenuView 是否有请求信号 (双重保险)
		if initial_view.has_signal("request_game_start"):
			
			# 2. 从其父节点 (/root/) 中移除
			# 此时因为是延迟调用，移除应该是成功的
			initial_view.get_parent().remove_child(initial_view) 
			
			# 3. 将它添加到 GameManager 之下
			add_child(initial_view)
			
			# 4. 赋值给 current_view_node 并连接信号
			current_view_node = initial_view
			current_view_index = 0
			
			current_view_node.request_game_start.connect(_on_game_start_requested)

			print("DEBUG: GameManager successfully found, managed, and connected StartMenuView.")
		else:
			push_error("ERROR: Initial view found (name: " + initial_view.name + ") but is missing the 'request_game_start' signal.")
	else:
		push_error("ERROR: The main scene (StartMenuView) was not found as a direct child of /root/. Check your project settings.")
		
func start_new_game():
	"""
	这个函数应该由你主菜单中的"开始游戏"按钮调用。
	它会重置所有玩家数据，并切换到主游戏场景。
	"""
	#1. 从配置文件加载默认的玩家数值
	var config = _load_game_config()
	if config and config.has("player_defaults"):
		var defaults = config.player_defaults
		Global.current_money = defaults.get("start_money", 100.0)
		Global.current_stress = defaults.get("start_stress", 0.0)
	
	# 如果需要，你也可以在这里重置其他系统的数据
	# 例如，清空银行存款：
	# Global.bank_system.savings = 0.0

	# 初始化债务系统
	if debt_system and debt_system.has_method("start_new_game"):
		debt_system.start_new_game()
		
	# 【新增】初始化通道数据
	initialize_channel_data()

	#2. 更新游戏状态
	current_state = GameState.IN_GAME
	
	#3. 发出信号，通知任何感兴趣的节点（比如HUD）游戏已经开始
	game_started.emit()
	
	# load initial scene
	# await get_tree().process_frame
	
	# 【修正】将初始视图添加到 GameManager 自身
	const HALL_VIEW_INDEX = 2
	_change_view(HALL_VIEW_INDEX)
	
func _input(event: InputEvent) -> void:
	if current_state != GameState.IN_GAME:
		return
	
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
		
		if current_view_node.has_signal("view_clicked"):
			# 注意：这里的连接对象是 _change_view 自身
			if current_view_node.view_clicked.is_connected(_change_view):
				current_view_node.view_clicked.disconnect(_change_view)
				
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
			
			if hud_node.has_signal("pause_menu_requested"):
				hud_node.pause_menu_requested.connect(_on_pause_menu_requested)
				
			_update_hud_stats() 
	
	# 3. 实例化新场景
	var new_view: Node = VIEW_PATHS[new_index].instantiate()
	
	# 4. 连接新视图的信号
	if new_view.has_signal("request_game_start"):
		new_view.request_game_start.connect(_on_game_start_requested)
	
	add_child(new_view)
	
	if new_index == 2:
		if new_view.has_signal("view_clicked"):
			# 当 HallView 发出点击信号时，调用 _change_view 来执行切换
			new_view.view_clicked.connect(_change_view)
	
	current_view_node = new_view
	current_view_index = new_index
	
	print("change to index: ", current_view_index, " (", new_view.name, ")")
	
func _on_game_start_requested():
	'''
	接收start_menu_view.gd的信号，完成游戏的初始化任务
	'''
	start_new_game()

# 在 Game Manager 中定义更新 HUD 的内部函数
func _update_hud_stats():
	if is_instance_valid(hud_node):
		hud_node.update_stats()
		print("HUD updated")
		
# --- 新增：一个更新金币的公共函数 ---
func add_gold(amount: float):
	currency_system.player_currency.normal_money += amount
	# 调用步骤 2 中的函数来更新 HUD
	_update_hud_stats() 

func end_player_turn():
	"""
	这是游戏循环的核心。
	当玩家完成一个主要动作后（例如推币机结算完成后），就应该调用此函数。
	"""
	if current_state != GameState.IN_GAME:
		return

	#通知所有相关系统处理它们的回合结束逻辑
	if debt_system and debt_system.has_method("process_end_of_round"):
		debt_system.process_end_of_round()
	if bank_system and bank_system.has_method("process_end_of_round"):
		bank_system.process_end_of_round()
	if shop_system and shop_system.has_method("process_round_start"):
		# 下一小回合开始前刷新一次可用状态
		shop_system.process_round_start()
	if event_system and event_system.has_method("process_round_end"):
		event_system.process_round_end()
	# 应用货币自动增长
	if currency_system and currency_system.has_method("apply_growth"):
		var growth_amount = currency_system.apply_growth()
		if growth_amount > 0:
			Global.show_notification("货币自动增长: %d 元" % growth_amount)
			
	if Global.check_game_end_conditions():
		return  # 如果游戏结束，不再推进回合
	
	
	if Global.current_sub_round == 1 and Global.current_round > 1:
		Global.show_notification("第 %d 大回合开始" % Global.current_round)
	else:
		Global.show_notification("第 %d 小回合结束" % Global.current_sub_round)
		
	# 推进到下一个小回合（6大回合×4小回合）
	Global.advance_sub_round()
	
	
	
func _on_global_game_over(reason: String):
	"""
	响应全局游戏结束信号
	"""
	current_state = GameState.GAME_OVER
	print("游戏结束，原因: ", reason)
	# 显示游戏结束消息
	_show_game_over_message(reason)

func _show_game_over_message(reason: String):
	"""显示游戏结束消息并返回主菜单"""
	var message = _get_game_over_message(reason)
	Global.show_notification(message)
	
	# 创建计时器，等待几秒后返回主菜单
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(_return_to_main_menu_after_game_over)

func _get_game_over_message(reason: String) -> String:
	"""根据游戏结束原因返回对应的消息"""
	match reason:
		"债务违约", "debt_default":
			return "债务违约！你未能按时偿还债务，游戏结束"
		"压力爆表", "stress_max":
			return "压力爆表！你的精神崩溃了，游戏结束"
		"贷款违约", "loan_default":
			return "贷款违约！你未能偿还贷款，游戏结束"
		"回合用尽", "max_rounds":
			return "时间耗尽！你未能完成所有债务，游戏结束"
		_:
			return "游戏结束: " + reason

func _return_to_main_menu_after_game_over():
	"""游戏结束后返回主菜单"""
	return_to_main_menu()
	
func return_to_main_menu():
	"""
	让玩家返回主菜单界面。
	"""
	current_state = GameState.MAIN_MENU
	#get_tree().change_scene_to_file("res://project/scenes/views/main_menu_view.tscn")
	_change_view(0)
	
'''func _on_game_over(reason: String):
	"""
    响应全局的 game_over 信号。
	"""
	current_state = GameState.GAME_OVER
	
	# 根据原因显示不同的消息
	if reason == "victory":
		Global.show_notification("恭喜！你成功偿还了所有债务，获得了自由！")
	else:
		Global.show_notification("游戏结束: " + reason)
	
	#创建一个计时器，等待几秒钟再返回主菜单，给玩家阅读信息的时间
	var timer = get_tree().create_timer(4.0)
	await timer.timeout
	
	return_to_main_menu()'''

func _load_game_config() -> Dictionary:
	"""加载主游戏配置文件。"""
	var file = FileAccess.open("res://project/data/game_config.json", FileAccess.READ)
	var parsed_json = JSON.parse_string(file.get_as_text())
	return parsed_json

# is_game_won()函数，用于查看游戏是否胜利，从而改变场景状态
func is_game_won() -> bool:
	'''
	根据债务系统判断是否胜利 - 所有6个大回合的债务都偿还完成
	'''

	if debt_system and debt_system.has_method("are_all_debts_completed") and Global.current_round == 6:
		return debt_system.are_all_debts_completed()
	return false

	
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

# === 系统获取方法 ===
func get_currency_system() -> Node:
	return currency_system

func get_stress_system() -> Node:
	return stress_system

func get_debt_system() -> Node:
	return debt_system

func get_coin_system() -> Node:
	return coin_system

func get_shop_system() -> Node:
	return shop_system

func get_bank_system() -> Node:
	return bank_system

func get_event_system() -> Node:
	return event_system

func get_pattern_system() -> Node:
	return pattern_system

# === 债务系统信号处理方法 ===
func _on_debt_system_victory():
	"""债务系统胜利信号处理"""
	print("GameManager: 债务系统报告游戏胜利！")
	process_game_victory()

func _on_all_debts_completed():
	"""所有债务完成信号处理"""
	print("GameManager: 所有债务已完成！")
	if current_state == GameState.IN_GAME:
		# 可以在这里添加额外的胜利逻辑，比如显示特殊消息
		Global.show_notification("恭喜！你成功偿还了所有债务！")


func _on_pause_menu_requested():
	""" 
	响应 HUD 齿轮按钮的信号，加载暂停菜单。
	此函数也用于处理 ESC 键的输入。
	"""
	# 避免重复加载菜单
	if is_instance_valid(pause_menu_node):
		return

	# 1. 实例化菜单
	var new_menu: Control = MAIN_MENU_SCENE.instantiate()
	
	# 2. 连接菜单的退出信号
	new_menu.menu_closed.connect(_on_menu_closed)
	new_menu.return_to_main_menu_requested.connect(_on_return_to_main_menu_requested)
	
	# 3. 将菜单添加到场景树 (添加到 GameManager 节点下)
	add_child(new_menu)
	pause_menu_node = new_menu
	
	print("DEBUG: Pause menu loaded and game paused.")


func _on_menu_closed():
	""" 
	响应 MainMenu 脚本发出的关闭信号 (来自 ESC 或 X 按钮)。
	"""
	if is_instance_valid(pause_menu_node):
		# 1. 销毁菜单节点
		pause_menu_node.queue_free()
		pause_menu_node = null
		
		# 2. 游戏恢复运行已在 MainMenu.gd 的 _close_menu 中处理
		
		print("DEBUG: Pause menu freed and game resumed.")


func _on_return_to_main_menu_requested():
	""" 
	响应 MainMenu 脚本发出的返回主菜单请求。
	"""
	# 游戏恢复运行已在 MainMenu.gd 的 _on_return_button_pressed 中处理
	
	# 1. 确保菜单被清理 (防止在切换场景后残留)
	_on_menu_closed() 
	
	# 2. 切换到主菜单场景 (假设主菜单索引为 0)
	_change_view(0)
	
	print("DEBUG: Switching to Main Menu.")
	
func _unhandled_input(event: InputEvent):
	# 检查是否按下了 ESC 键，并且当前不在主菜单 (假设索引 0 是主菜单)
	if event.is_action_pressed("ui_cancel") and current_view_index != 0:
		
		if is_instance_valid(pause_menu_node):
			# 如果菜单已经打开，我们信任 MainMenu.gd 会自行处理 ESC 键的关闭逻辑。
			pass 
		else:
			# 如果菜单没有打开，则请求打开菜单
			_on_pause_menu_requested() 
			
		get_viewport().set_input_as_handled()

# [TODO] 获取概率的四个函数
# [DONE] 获取概率的四个函数 - 基于coin_system的实际数据
func _get_channel_a_data() -> Array:
	"""获取通道A的真实硬币分布数据"""
	return _get_channel_distribution_data("A")

func _get_channel_b_data() -> Array:
	"""获取通道B的真实硬币分布数据"""
	return _get_channel_distribution_data("B")

func _get_channel_c_data() -> Array:
	"""获取通道C的真实硬币分布数据"""
	return _get_channel_distribution_data("C")

func _get_channel_d_data() -> Array:
	"""获取通道D的真实硬币分布数据"""
	return _get_channel_distribution_data("D")

func _get_channel_distribution_data(channel_id: String) -> Array:
	"""
	获取指定通道的真实硬币分布数据
	返回数组顺序: [真硬币, 太阳币, 月亮币, 星星币, 骷髅币, 血币] 的概率(0-1之间)
	"""
	if not coin_system:
		push_warning("Coin system not available, returning default distribution")
		return _get_default_channel_data(channel_id)
	
	# 使用新的统计方法获取实际分布
	if coin_system.has_method("get_channel_statistical_distribution"):
		return coin_system.get_channel_statistical_distribution(channel_id)
	else:
		push_warning("Coin system doesn't have statistical distribution method")
		return _get_default_channel_data(channel_id)

func _get_default_channel_data(channel_id: String) -> Array:
	"""获取默认的通道数据（备用方案）"""
	match channel_id:
		"A":
			return [0.1, 0.2, 0.3, 0.1, 0.1, 0.2]
		"B":
			return [0.15, 0.15, 0.2, 0.1, 0.2, 0.2]
		"C":
			return [0.05, 0.05, 0.5, 0.1, 0.1, 0.2]
		"D":
			return [0.4, 0.1, 0.1, 0.1, 0.1, 0.2]
		_:
			return [0.166, 0.166, 0.166, 0.166, 0.166, 0.166]  # 平均分布

# [DONE] 初始化通道数据
func initialize_channel_data():
	"""初始化所有通道的硬币分布数据"""
	if not coin_system:
		push_warning("Coin system not available for channel initialization")
		return
		
	# 初始化所有通道
	for channel_id in ["A", "B", "C", "D"]:
		coin_system.fill_channel_from_mountain(channel_id, 100)
		print("Initialized channel %s with coin distribution" % channel_id)
	

	
# [DONE] 获取后三个通道开销的函数
func _get_channel_costs() -> Array:
	# 占位符
	return [20,40,60]

# [DONE] 告知gamemanager该通道被选择
func _handle_channel_selected(channel_id: String, cost: int):
	"""
	告知gamemanager该通道被选择
	第一个参数为"A"/"B"/"C"/"D" 后一个参数为价格
	"""
	print("通道 ", channel_id, " 被选择，费用: ", cost)
	
	# 扣除费用
	if currency_system and currency_system.has_method("spend_money"):
		var success = currency_system.spend_money(cost, "channel_unlock")
		if success:
			print("成功扣除通道费用: ", cost)
			# 显示弹窗提示
			Global.show_notification("通道 %s 解锁成功\n花费 %d 元" % [channel_id, cost])
		else:
			print("扣除通道费用失败，资金不足")
			Global.show_notification("资金不足，无法解锁通道 %s" % channel_id)
	
	# 更新 HUD 显示
	_update_hud_stats()

# 检查并应用道具效果
func check_item_effects():
	if not shop_system:
		return
	
	# 深渊之眼效果 - 额外小回合
	if shop_system.has_item("abyss_eye"):
		# 这个效果在回合结束时检查
		pass
	
	# 护身符效果 - 增加幸运值
	if shop_system.has_item("talisman"):
		# 这个效果在概率计算中应用
		pass
	
	# 源石科技效果 - 充能所有道具
	if shop_system.has_item("originium_tech"):
		# 这个效果在商店系统中处理
		pass

# 应用道具效果的回合推进
func advance_sub_round_with_effects():
	# 检查深渊之眼效果
	if shop_system and shop_system.has_item("abyss_eye"):
		var item = shop_system.get_player_inventory().get("abyss_eye", {})
		if item.get("uses_remaining", 0) > 0:
			# 20%概率触发额外小回合
			if randf() <= 0.20:
				# 触发额外小回合
				trigger_extra_sub_round()
				return
	
	# 正常推进回合
	Global.advance_sub_round()

# 触发额外小回合
func trigger_extra_sub_round():
	Global.show_notification("深渊之眼触发！获得额外小回合！")
	# 这里可以添加额外的回合逻辑
	# 比如不推进回合数，而是给玩家额外的操作机会

# 应用道具效果的回合开始
func process_round_start_with_effects():
	# 检查所有系统的道具效果
	if coin_system and coin_system.has_method("check_item_effects"):
		coin_system.check_item_effects()
	
	if pattern_system and pattern_system.has_method("check_item_effects"):
		pattern_system.check_item_effects()
	
	if stress_system and stress_system.has_method("check_item_effects"):
		stress_system.check_item_effects()
	
	if bank_system and bank_system.has_method("check_item_effects"):
		bank_system.check_item_effects()
	
	# 处理商店系统的回合开始逻辑
	if shop_system and shop_system.has_method("process_round_start"):
		shop_system.process_round_start()

# 获取幸运值加成（护身符效果）
func get_luck_bonus() -> int:
	if not shop_system or not shop_system.has_item("talisman"):
		return 0
	
	var item = shop_system.get_player_inventory().get("talisman", {})
	if item.get("uses_remaining", 0) > 0:
		# 33%概率触发幸运值+5
		if randf() <= 0.33:
			return 5
	
	return 0

# 事件触发机制
func trigger_round_end_events():
	"""在大回合结束时触发事件选择"""
	if not event_system:
		return
	
	# 检查是否应该提供事件
	if debt_system and debt_system.is_final_round():
		return  # 最后一回合不提供事件
	
	# 检查债务状态
	if debt_system and debt_system.check_debt_default():
		return  # 债务违约时不提供事件
	
	# 触发事件系统
	if event_system.has_method("offer_events"):
		event_system.offer_events()

# 处理事件选择
func handle_event_selection(event_id: String, is_negative: bool = false):
	"""处理玩家选择的事件"""
	if not event_system:
		return false
	
	return event_system.select_event(event_id, is_negative)

# 获取当前可用事件
func get_available_events() -> Array:
	if not event_system:
		return []
	
	return event_system.get_random_events(3)

# 检查事件系统状态
func is_event_system_ready() -> bool:
	return event_system != null and event_system.has_method("offer_events")

# [DONE] 用于更新场景弹窗的数额，并执行加款
func process_channel_view_cleanup_and_switch():
	"""
	跳转至hall_view，更新弹窗显示金币数额，播放弹窗，标识回合结束，增加玩家金钱数量，
	"""
	# 保存结算结果
	var coin_amount = total_settlement_money
	
	# 重置结算数据
	total_settlement_money = 0
	settlement_stress_change = 0
	
	# 切换到大厅视图
	_change_view(2)
	await get_tree().process_frame
	
	# 调用 HallView 的金币掉落函数
	if is_instance_valid(current_view_node) and current_view_index == 2:
		if current_view_node.has_method("_on_coin_drop_signal_received"):
			current_view_node._on_coin_drop_signal_received(coin_amount)
			print("GameManager: HallView 金币掉落函数已成功调用。")
			
			# 等待动画播放
			await get_tree().create_timer(3.0).timeout
		else:
			push_error("HallView 缺少 _on_coin_drop_signal_received 方法！")
	else:
		push_error("场景切换失败，无法找到 HallView 节点。")
	
	# 处理回合结束逻辑
	end_player_turn()

func set_settlement_data(money: int, stress_change: int = 0):
	"""
	设置结算数据，从channel_view调用
	"""
	total_settlement_money = money
	settlement_stress_change = stress_change
	print("GameManager: 收到结算数据 - 金钱: ", money, ", 压力变化: ", stress_change)
	# 更新金钱
	if money > 0:
		add_gold(money)
	
	# 更新压力
	if stress_system and stress_change != 0:
		stress_system.change_stress(stress_change, "round_settlement")
