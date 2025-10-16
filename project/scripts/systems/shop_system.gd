extends Node

var shop_config: Dictionary
var current_items: Array = []
var player_inventory: Dictionary = {}
var refresh_cost: float = 0
var refresh_count: int = 0

@onready var currency_system = Global.get_currency_system()
@onready var coin_system = Global.get_coin_system()
@onready var stress_system = Global.get_stress_system()
@onready var bank_system = Global.get_bank_system()
@onready var debt_system = Global.get_debt_system()

signal shop_items_updated(items: Array)
signal item_purchased(item_id: String, success: bool)
signal inventory_updated(inventory: Dictionary)
signal refresh_cost_updated(cost: float)

func _ready():
	load_shop_config()
	initialize_shop()

func load_shop_config():
	var file = FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file:
		shop_config = JSON.parse_string(file.get_as_text())
		refresh_cost = shop_config.refresh_cost.initial
		file.close()

func initialize_shop():
	generate_new_items()
	refresh_cost_updated.emit(refresh_cost)

func generate_new_items(count: int = 5):
	current_items.clear()
	var available_items = shop_config.items.keys()
	available_items.shuffle()
	
	for i in range(min(count, available_items.size())):
		var item_id = available_items[i]
		var item_data = shop_config.items[item_id].duplicate(true)
		item_data.id = item_id
		current_items.append(item_data)
	
	shop_items_updated.emit(current_items)

func purchase_item(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if not item_data:
		return false
	
	if currency_system.spend_money(item_data.price, "shop_purchase", "auto"):
		# 添加到玩家库存
		add_to_inventory(item_id, item_data)
		
		# 应用物品效果
		apply_item_effect(item_id, item_data)
		
		item_purchased.emit(item_id, true)
		return true
	else:
		item_purchased.emit(item_id, false)
		return false

func add_to_inventory(item_id: String, item_data: Dictionary):
	if not player_inventory.has(item_id):
		player_inventory[item_id] = {
			"data": item_data,
			"quantity": 0,
			"uses_remaining": item_data.get("max_uses", 1),
			"cooldown_remaining": 0
		}
	
	player_inventory[item_id].quantity += 1
	inventory_updated.emit(player_inventory)

func apply_item_effect(item_id: String, item_data: Dictionary):
	var effect = item_data.effect
	var effect_value = item_data.get("effect_value", {})
	
	match effect:
		"show_channel_distribution":
			# 金属探测器效果 - 在通道查看时显示分布
			pass  # 在UI中实现
		"increase_pattern_coin_stats":
			coin_system.apply_buff_to_coin_pool("pattern_coin_percentage", effect_value.percentage)
			coin_system.apply_buff_to_coin_pool("pattern_coin_high_value_prob", effect_value.high_value_prob)
		"increase_complex_pattern_multiplier":
			# 在图案系统中实现
			pass
		"reduce_penalty_coins":
			coin_system.apply_buff_to_coin_pool("penalty_coin_percentage", effect_value.percentage)
		"temporary_boost":
			# 回合限时效果，在回合开始时应用
			pass
		"boost_pattern_coins":
			# 充能道具，在激活时应用
			pass
		"block_penalty_coins":
			# 充能道具，在激活时应用
			pass
		"double_real_coin_value":
			# 在硬币系统中实现
			pass
		"increase_real_coin_percentage":
			coin_system.apply_buff_to_coin_pool("real_coin_percentage", effect_value)
		"increase_luck":
			# 在概率计算中实现
			pass
		"extra_sub_round":
			# 在回合管理中实现
			pass
		"reset_stress":
			stress_system.reset_stress()
		"interest_free_loan":
			# 在银行系统中实现特殊贷款
			pass
		"free_refresh":
			refresh_shop_free()
		"increase_basic_pattern_multiplier":
			# 在图案系统中实现
			pass
		"reduce_stress":
			stress_system.reduce_stress_immediate(effect_value)
		"free_channel_unlock":
			# 在通道系统中实现
			pass
		"recharge_all_items":
			recharge_all_rechargeable_items()

func use_item(item_id: String) -> bool:
	if not player_inventory.has(item_id):
		return false
	
	var item = player_inventory[item_id]
	
	# 检查使用限制
	if item.uses_remaining <= 0:
		return false
	
	if item.data.effect_type == "rechargeable" and item.cooldown_remaining > 0:
		return false
	
	# 应用效果
	apply_item_effect(item_id, item.data)
	
	# 更新使用次数
	item.uses_remaining -= 1
	
	# 设置冷却（如果是充能道具）
	if item.data.effect_type == "rechargeable":
		item.cooldown_remaining = item.data.cooldown_rounds
	
	# 如果使用次数用完，从库存中移除
	if item.uses_remaining <= 0:
		player_inventory.erase(item_id)
	
	inventory_updated.emit(player_inventory)
	return true

func refresh_shop():
	if currency_system.spend_money(int(refresh_cost), "shop_refresh", "auto"):
		refresh_count += 1
		refresh_cost = shop_config.refresh_cost.initial * pow(shop_config.refresh_cost.multiplier, refresh_count)
		generate_new_items()
		refresh_cost_updated.emit(refresh_cost)
		return true
	return false

func refresh_shop_free():
	generate_new_items()
	refresh_cost_updated.emit(refresh_cost)

func get_item_data(item_id: String) -> Dictionary:
	return shop_config.items.get(item_id, {})

func get_current_items() -> Array:
	return current_items.duplicate()

func get_player_inventory() -> Dictionary:
	return player_inventory.duplicate()

func process_round_start():
	# 处理充能道具冷却
	for item_id in player_inventory:
		var item = player_inventory[item_id]
		if item.data.effect_type == "rechargeable" and item.cooldown_remaining > 0:
			item.cooldown_remaining -= 1
	
	inventory_updated.emit(player_inventory)

func recharge_all_rechargeable_items():
	for item_id in player_inventory:
		var item = player_inventory[item_id]
		if item.data.effect_type == "rechargeable":
			item.cooldown_remaining = 0
	
	inventory_updated.emit(player_inventory)

func has_item(item_id: String) -> bool:
	return player_inventory.has(item_id)

func get_item_quantity(item_id: String) -> int:
	if player_inventory.has(item_id):
		return player_inventory[item_id].quantity
	return 0
