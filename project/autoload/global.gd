extends Node

# 预加载常用场景
var notification_scene = preload("res://project/scenes/ui/NotificationPopup.tscn")

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
signal game_state_changed(new_state: String, old_state: String)
signal game_over(reason: String)

# 系统相关信号
signal systems_initialized()
signal save_loaded()
signal config_loaded()

# === 初始化方法 ===
func _ready():
	# 延迟获取系统引用，确保GameManager先初始化
	call_deferred("initialize_system_references")
	load_config()

func initialize_system_references():
	"""在GameManager初始化后调用此方法"""
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		cache_system_references()
		systems_initialized.emit()

func cache_system_references():
	"""缓存各个系统的引用"""
	if game_manager:
		currency_system = game_manager.get_system("currency_system")
		stress_system = game_manager.get_system("stress_system")
		debt_system = game_manager.get_system("debt_system")
		coin_system = game_manager.get_system("coin_system")
		shop_system = game_manager.get_system("shop_system")
		bank_system = game_manager.get_system("bank_system")
		event_system = game_manager.get_system("event_system")
		pattern_system = game_manager.get_system("pattern_system") 
		
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

func load_config():
	"""加载游戏配置"""
	var file = FileAccess.open("res://data/game_config.json", FileAccess.READ)
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
	current_sub_round += 1
	if current_sub_round > 4:  # 每个大回合4个小回合
		current_sub_round = 1
		current_round += 1
	round_changed.emit(current_round, current_sub_round)

func trigger_game_over(reason: String):
	game_over_reason = reason
	game_state = "game_over"
	game_over.emit(reason)

# === UI 相关方法 ===
func show_notification(message: String, duration: float = 3.0):
	"""显示全局通知"""
	var notification = notification_scene.instantiate()
	get_tree().root.add_child(notification)
	notification.show_message(message, duration)

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

# === 保存/加载方法 ===
func save_game():
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
	save_loaded.emit()

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
