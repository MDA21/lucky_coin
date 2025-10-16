extends Node

var events_config: Dictionary
var selected_events: Array = []
var available_events: Array = []
var events_history: Array = []

@onready var coin_system = $"/root/GameManager".get_system("coin_system")
@onready var stress_system = $"/root/GameManager".get_system("stress_system")
@onready var bank_system = $"/root/GameManager".get_system("bank_system")
@onready var shop_system = $"/root/GameManager".get_system("shop_system")
@onready var debt_system = $"/root/GameManager".get_system("debt_system")

signal events_available(events: Array)
signal event_selected(event_id: String, event_data: Dictionary)
signal event_applied(event_id: String, effect: String)

func _ready():
	load_events_config()
	initialize_available_events()

func load_events_config():
	var file = FileAccess.open("res://project/data/events_config.json", FileAccess.READ)
	if file:
		events_config = JSON.parse_string(file.get_as_text())
		file.close()

func initialize_available_events():
	available_events.clear()
	for category in events_config.event_categories:
		var category_events = events_config.events[category]
		for event_id in category_events:
			var event_data = category_events[event_id].duplicate(true)
			event_data.id = event_id
			available_events.append(event_data)
	
	# 随机打乱可用事件
	available_events.shuffle()

func get_random_events(count: int = 3) -> Array:
	var random_events = []
	var temp_available = available_events.duplicate()
	
	# 确保不会选择重复事件
	for i in range(min(count, temp_available.size())):
		if temp_available.is_empty():
			break
		
		var random_index = randi() % temp_available.size()
		var event_data = temp_available[random_index]
		random_events.append(event_data)
		temp_available.remove_at(random_index)
	
	return random_events

func offer_events():
	# 最后一回合不提供事件
	if debt_system.is_final_round():
		return
	
	# 检查事件数量限制
	if selected_events.size() >= events_config.event_selection.max_events_per_game:
		return
	
	var events_to_offer = get_random_events(events_config.event_selection.choices_per_round)
	events_available.emit(events_to_offer)

func select_event(event_id: String, is_negative: bool = false) -> bool:
	var event_data = find_event_data(event_id)
	if not event_data:
		return false
	
	# 应用事件效果
	var success = apply_event_effect(event_data, is_negative)
	
	if success:
		# 记录选择的事件
		selected_events.append({
			"id": event_id,
			"data": event_data,
			"is_negative": is_negative,
			"round_selected": debt_system.current_major_round,
			"timestamp": Time.get_unix_time_from_system()
		})
		
		# 从可用事件中移除
		remove_event_from_available(event_id)
		
		event_selected.emit(event_id, event_data)
	
	return success

func find_event_data(event_id: String) -> Dictionary:
	for category in events_config.events:
		var category_events = events_config.events[category]
		if category_events.has(event_id):
			return category_events[event_id].duplicate(true)
	return {}

func apply_event_effect(event_data: Dictionary, is_negative: bool) -> bool:
	var effect = event_data.effect
	var effect_value = event_data.get("effect_value", 0)
	var effect_target = event_data.get("effect_target", "")
	
	# 处理负面效果
	if is_negative and event_data.get("can_be_negative", false):
		effect_value = -effect_value
	
	match effect:
		"change_coin_percentage":
			match effect_target:
				"real_coin":
					coin_system.apply_buff_to_coin_pool("real_coin_percentage", effect_value)
				"pattern_coins":
					coin_system.apply_buff_to_coin_pool("pattern_coin_percentage", effect_value)
				"penalty_coins":
					coin_system.apply_buff_to_coin_pool("penalty_coin_percentage", effect_value)
		
		"change_high_value_probability":
			match effect_target:
				"pattern_coins":
					coin_system.apply_buff_to_coin_pool("pattern_coin_high_value_prob", effect_value)
				"penalty_coins":
					coin_system.apply_buff_to_coin_pool("penalty_coin_high_value_prob", effect_value)
		
		"increase_basic_pattern_multiplier":
			# 在图案系统中实现
			pass
		
		"multiply_coin_value":
			# 在硬币系统中实现
			pass
		
		"multiply_coin_base_value":
			# 在硬币系统中实现
			pass
		
		"multiply_coin_high_value":
			# 在硬币系统中实现
			pass
		
		"increase_max_stress":
			stress_system.set_max_stress(stress_system.max_stress + effect_value)
		
		"reduce_stress_growth":
			# 在压力系统中实现
			pass
		
		"boost_stress_reduction_items":
			# 在压力系统中实现
			pass
		
		"reduce_loan_stress":
			# 在压力系统中实现
			pass
		
		"boost_pattern_stress_reduction":
			# 在压力系统中实现
			pass
		
		"increase_savings_interest":
			bank_system.set_interest_rate(bank_system.savings_interest_rate + effect_value)
		
		"reduce_loan_interest":
			# 在银行系统中实现
			pass
		
		"expand_loan_options":
			# 在银行系统中实现
			pass
		
		"add_repayment_option":
			# 在银行系统中实现
			pass
		
		"shop_discounts":
			# 在商店系统中实现
			pass
		
		"reduce_refresh_cost":
			# 在商店系统中实现
			pass
		
		"reduce_channel_cost":
			# 在通道系统中实现
			pass
	
	event_applied.emit(event_data.id, effect)
	return true

func remove_event_from_available(event_id: String):
	for i in range(available_events.size()):
		if available_events[i].id == event_id:
			available_events.remove_at(i)
			break

func get_selected_events() -> Array:
	return selected_events.duplicate()

func get_events_history() -> Array:
	return events_history.duplicate()

func has_event(event_id: String) -> bool:
	for event in selected_events:
		if event.id == event_id:
			return true
	return false

func process_round_end():
	# 在回合结束时提供新事件
	offer_events()
