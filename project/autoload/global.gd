extends Node

# 预加载常用场景
var notification_scene = preload("res://project/scenes/ui/NotificationPopup.tscn")

# 修改！！！
# --- 全局玩家数据（由 GameManager 初始化和控制）---
# 必须显式声明，以避免 'Invalid assignment of property' 错误
var current_money: int = 0     # 玩家的现金
var current_loan: int = 0		  # 玩家当前的还款数
var current_stress: int = 0    # 玩家的压力值
var required_gold: int = 100   # 假设的胜利目标金币

# 系统引用缓存（通过GameManager获取，这里只是缓存）
var game_manager = null
var coin_system = null
var debt_system = null
var stress_system = null
var currency_system = null
var shop_system = null
var bank_system = null
var event_system = null
var  pattern_system = null

# 全局游戏状态
const MAJOR_ROUNDS: int = 6
const SUB_ROUNDS_PER_MAJOR: int = 4

var current_round: int = 1
var current_sub_round: int = 1
var game_state: String = "menu" # menu, playing, paused, game_over
var game_over_reason: String = ""

# 全局配置
var config: Dictionary = {}

# === 全局信号中心 ===
# 经济相关信号
signal money_changed(normal_money: int, loan_money: int, total_money: int)
signal money_earned(amount: int, source: String, is_loan_money: bool)
signal money_spent(amount: int, purpose: String, used_loan_money: bool)

# 游戏状态信号
signal stress_changed(new_stress: int, old_stress: int, change: int)
signal stress_effect_changed(distortion: float, filter: float)
signal stress_max_reached()
signal debt_changed(new_debt: float)
signal round_changed(major_round: int, sub_round: int)
signal sub_round_started(major_round: int, sub_round: int)
signal sub_round_ended(major_round: int, sub_round: int)
signal game_state_changed(new_state: String, old_state: String)
signal game_over(reason: String)

# 系统相关信号
signal systems_initialized()
signal save_loaded()
signal config_loaded()

# === 初始化方法 ===
func _ready():
	# 延迟获取系统引用，确保GameManager先初始化
	#call_deferred("initialize_system_references")
	load_config()
	
# 添加这个方法供 GameManager 调用
func on_game_manager_ready(game_mgr):
	"""由 GameManager 在初始化完成后调用"""
	game_manager = game_mgr
	cache_system_references()
	systems_initialized.emit()

func initialize_system_references():
	"""在GameManager初始化后调用此方法"""
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		cache_system_references()
		systems_initialized.emit()

func cache_system_references():
	"""缓存各个系统的引用"""
	if game_manager:
		currency_system = GameManager.get_currency_system()
		stress_system = GameManager.get_stress_system()
		debt_system = GameManager.get_debt_system()
		coin_system = GameManager.get_coin_system()
		shop_system = GameManager.get_shop_system()
		bank_system = GameManager.get_bank_system()
		event_system = GameManager.get_event_system()
		pattern_system = GameManager.get_pattern_system() 
		
		# 连接系统信号到全局信号
		connect_system_signals()

func connect_system_signals():
	"""连接各个系统的信号到全局信号"""
	if currency_system:
		if currency_system.has_signal("money_changed"):
			currency_system.money_changed.connect(_on_currency_money_changed)
		if currency_system.has_signal("money_earned"):
			currency_system.money_earned.connect(_on_money_earned)
		if currency_system.has_signal("money_spent"):
			currency_system.money_spent.connect(_on_money_spent)
	
	if stress_system:
		if stress_system.has_signal("stress_changed"):
			stress_system.stress_changed.connect(_on_stress_changed)
		if stress_system.has_signal("stress_effect_changed"):
			stress_system.stress_effect_changed.connect(_on_stress_effect_changed)
		if stress_system.has_signal("stress_max_reached"):
			stress_system.stress_max_reached.connect(_on_stress_max_reached)
	
	# 【新增】连接债务系统信号
	if debt_system:
		if debt_system.has_signal("debt_default"):
			debt_system.debt_default.connect(_on_debt_default)
		if debt_system.has_signal("game_victory"):
			debt_system.game_victory.connect(_on_game_victory)
	
	# 【新增】连接银行系统信号
	if bank_system:
		if bank_system.has_signal("loan_due_check"):
			bank_system.loan_due_check.connect(_on_loan_due_check)

func load_config():
	"""加载游戏配置"""
	var file = FileAccess.open("res://project/data/game_config.json", FileAccess.READ)
	if file:
		config = JSON.parse_string(file.get_as_text())
		file.close()
		config_loaded.emit()

# === 系统引用获取方法 ===
func get_currency_system():
	return currency_system

func get_stress_system():
	return stress_system

func get_debt_system():
	return debt_system

func get_coin_system():
	return coin_system

func get_shop_system():
	return shop_system

func get_bank_system():
	return bank_system

func get_event_system():
	return event_system
	
func get_pattern_system():
	return pattern_system

# === 便捷方法 - 经济系统 ===
func add_money(amount: int, source_type: String = "normal", is_loan: bool = false):
	"""添加金钱（委托给货币系统）"""
	if currency_system:
		currency_system.add_money(amount, source_type, is_loan)
	else:
		push_warning("Currency system not available")

func spend_money(amount: int, purpose: String, spend_preference: String = "auto") -> bool:
	"""花费金钱（委托给货币系统）"""
	if currency_system:
		return currency_system.spend_money(amount, purpose, spend_preference)
	else:
		push_warning("Currency system not available")
		return false

func can_afford(amount: int) -> bool:
	"""检查是否能够支付（委托给货币系统）"""
	if currency_system:
		return currency_system.can_afford(amount)
	else:
		push_warning("Currency system not available")
		return false

func get_money_breakdown() -> Dictionary:
	"""获取货币明细（委托给货币系统）"""
	if currency_system:
		return currency_system.get_money_breakdown()
	else:
		return {"normal_money": 0, "loan_money": 0, "total_money": 0, "normal_percentage": 0.0}

# === 便捷方法 - 压力系统 ===
func change_stress(amount: int, source: String = "unknown"):
	"""改变压力值（委托给压力系统）"""
	if stress_system:
		stress_system.change_stress(amount, source)
	else:
		push_warning("Stress system not available")

func get_stress_info() -> Dictionary:
	"""获取压力信息（委托给压力系统）"""
	if stress_system:
		return {
			"current_stress": stress_system.current_stress,
			"max_stress": stress_system.max_stress,
			"stress_level": stress_system.get_stress_level(),
			"stress_percentage": stress_system.get_stress_percentage(),
			"distortion_intensity": stress_system.distortion_intensity,
			"filter_intensity": stress_system.filter_intensity
		}
	else:
		return {"current_stress": 0, "max_stress": 100, "stress_level": "low", "stress_percentage": 0.0}

# === 游戏状态管理 ===
func set_game_state(new_state: String):
	var old_state = game_state
	game_state = new_state
	game_state_changed.emit(new_state, old_state)

func set_round(major_round: int, sub_round: int = 1):
	current_round = major_round
	current_sub_round = sub_round
	round_changed.emit(major_round, sub_round)

func advance_sub_round():
	# 结束当前小回合
	sub_round_ended.emit(current_round, current_sub_round)

	# 进入下一个小回合/大回合
	current_sub_round += 1
	if current_sub_round > SUB_ROUNDS_PER_MAJOR:
		current_sub_round = 1
		current_round += 1

	# 同步债务系统的回合状态
		if debt_system and debt_system.has_method("advance_major_round"):
			var success = debt_system.advance_major_round()
			if not success:
				# 债务系统处理了游戏结束，不需要再次处理
				return
		else:
			# 如果没有债务系统，使用原来的逻辑
			if current_round > MAJOR_ROUNDS:
				trigger_game_over("max_rounds")
				return

	# 通知变更并开启新小回合
	round_changed.emit(current_round, current_sub_round)
	sub_round_started.emit(current_round, current_sub_round)

func is_final_round() -> bool:
	return current_round >= MAJOR_ROUNDS and current_sub_round >= SUB_ROUNDS_PER_MAJOR
	
# 统一的游戏结束检查函数
func check_game_end_conditions():
	"""统一检查所有游戏结束条件"""
	# 检查压力爆表
	if stress_system and stress_system.current_stress >= stress_system.max_stress:
		trigger_game_over("压力爆表")
		return true
	
	# 检查债务违约
	if debt_system and debt_system.has_method("check_debt_default"):
		if debt_system.check_debt_default():
			return true
	
	# 检查回合用尽
	if current_round > MAJOR_ROUNDS:
		trigger_game_over("max_rounds")
		return true
	
	return false

# 在 global.gd 中简化 trigger_game_over 函数

func trigger_game_over(reason: String):
	"""
	触发游戏结束 - 显示通知并返回主界面
	"""
	# 检查是否已经处于游戏结束状态，避免重复触发
	if game_state == "game_over":
		return
	
	print("游戏结束触发，原因: ", reason)
	
	# 设置游戏状态
	game_state = "game_over"
	
	# 根据原因显示不同的消息
	var message = _get_game_over_message(reason)
	show_notification(message)
	
	# 发出游戏结束信号
	game_over.emit(reason)
	
	# 创建计时器，等待几秒后返回主菜单
	var timer = Timer.new()
	timer.wait_time = 3.0  # 3秒后返回主菜单
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_return_to_main_menu_after_game_over)
	timer.start()

func _get_game_over_message(reason: String) -> String:
	"""根据游戏结束原因返回对应的消息"""
	match reason:
		"debt_default", "债务违约":
			return "债务违约！你未能按时偿还债务"
		"stress_max", "压力爆表":
			return "压力爆表！你的精神崩溃了"
		"loan_default", "贷款违约":
			return "贷款违约！你未能偿还贷款"
		"max_rounds", "回合用尽":
			return "时间耗尽！你未能完成所有债务"
		"victory", "胜利":
			return "恭喜！你成功偿还了所有债务，获得了自由！"
		"loan_pressure", "贷款压力过大":
			return "贷款压力过大！你无法承受贷款带来的压力"
		_:
			return "游戏结束: " + reason

func _return_to_main_menu_after_game_over():
	"""游戏结束后返回主菜单"""
	# 清理计时器
	var timer = get_child(get_child_count() - 1)  # 获取最后一个子节点（应该是计时器）
	if timer is Timer:
		timer.queue_free()
	
	# 返回主菜单
	if game_manager and game_manager.has_method("return_to_main_menu"):
		game_manager.return_to_main_menu()
	else:
		# 如果没有game_manager引用，直接切换场景
		get_tree().change_scene_to_file("res://project/scenes/views/start_menu_view.tscn")

func trigger_game_victory():
	"""触发游戏胜利"""
	game_over_reason = "victory"
	game_state = "game_over"
	# 发出胜利信号而不是失败信号
	game_over.emit("victory")

# === UI 相关方法 ===
func show_notification(message: String):
	"""显示全局通知"""
	var notification = notification_scene.instantiate()
	get_tree().root.add_child(notification)
	notification.show_message(message)

func show_insufficient_funds_notification():
	"""显示资金不足通知"""
	show_notification("资金不足！")

func show_stress_warning_notification():
	"""显示压力警告通知"""
	show_notification("压力过高！请谨慎操作")

# === 信号转发方法 ===
func _on_currency_money_changed(normal_money: int, loan_money: int, total_money: int):
	money_changed.emit(normal_money, loan_money, total_money)

func _on_money_earned(amount: int, source: String, is_loan_money: bool):
	money_earned.emit(amount, source, is_loan_money)

func _on_money_spent(amount: int, purpose: String, used_loan_money: bool):
	money_spent.emit(amount, purpose, used_loan_money)

func _on_stress_changed(new_stress: int, old_stress: int, change: int):
	stress_changed.emit(new_stress, old_stress, change)

func _on_stress_effect_changed(distortion: float, filter: float):
	stress_effect_changed.emit(distortion, filter)

func _on_stress_max_reached():
	stress_max_reached.emit()

# 【新增】债务违约信号处理
func _on_debt_default(round_number: int, target_amount: int, paid_amount: int):
	"""处理债务违约"""
	trigger_game_over("债务违约")

# 【新增】游戏胜利信号处理
func _on_game_victory():
	"""处理游戏胜利"""
	trigger_game_over("victory")

# 【新增】贷款到期检查信号处理
func _on_loan_due_check(loan_data: Dictionary):
	"""处理贷款到期无法偿还"""
	trigger_game_over("贷款违约")

# === 保存/加载方法 ===  暂时没有
'''func save_game():
	"""保存游戏状态"""
	var save_data = {
		"current_round": current_round,
		"current_sub_round": current_sub_round,
		"game_state": game_state,
		"money_breakdown": get_money_breakdown(),
		"stress_info": get_stress_info()
	}
	
	# 这里可以添加更多保存逻辑
	# 例如：var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	
	return save_data

func load_game(save_data: Dictionary):
	"""加载游戏状态"""
	if save_data.has("current_round"):
		current_round = save_data.current_round
	if save_data.has("current_sub_round"):
		current_sub_round = save_data.current_sub_round
	if save_data.has("game_state"):
		game_state = save_data.game_state
	
	round_changed.emit(current_round, current_sub_round)
	game_state_changed.emit(game_state, "loading")
	save_loaded.emit()'''

# === 工具方法 ===
func get_system_ready() -> bool:
	"""检查系统是否已初始化完成"""
	return (currency_system != null and 
			stress_system != null and 
			debt_system != null and 
			coin_system != null)

func print_debug_info():
	"""打印调试信息"""
	print("=== Global System Debug ===")
	print("Game State: ", game_state)
	print("Round: ", current_round, "-", current_sub_round)
	print("Systems Ready: ", get_system_ready())
	
	if currency_system:
		var money = get_money_breakdown()
		print("Money: Normal=%d, Loan=%d, Total=%d" % [money.normal_money, money.loan_money, money.total_money])
	
	if stress_system:
		var stress = get_stress_info()
		print("Stress: %d/%d (%s)" % [stress.current_stress, stress.max_stress, stress.stress_level])

# is_game_won()函数，用于查看游戏是否胜利，从而改变场景状态
func is_game_won() -> bool:
	'''
	根据债务系统判断是否胜利 - 所有6个大回合的债务都偿还完成
	'''
	if debt_system and debt_system.has_method("are_all_debts_completed"):
		return debt_system.are_all_debts_completed()
	return false
