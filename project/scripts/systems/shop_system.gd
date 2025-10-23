extends Node

var shop_config: Dictionary
var current_items: Array = []
var player_inventory: Dictionary = {}
var refresh_cost: float = 0
var refresh_count: int = 0

var currency_system = null
var coin_system = null
var stress_system = null
var bank_system = null
var debt_system = null

signal shop_items_updated(items: Array)
signal item_purchased(item_id: String, success: bool)
signal inventory_updated(inventory: Dictionary)
signal refresh_cost_updated(cost: float)

func _ready():
	load_shop_config()
	initialize_shop()
	# 延迟获取系统引用，确保 Global 已经初始化完成
	call_deferred("initialize_system_references")
	
func initialize_system_references():
	"""初始化系统引用"""
	currency_system = Global.get_currency_system()
	coin_system = Global.get_coin_system()
	stress_system = Global.get_stress_system()
	bank_system = Global.get_bank_system()
	debt_system = Global.get_debt_system()

func load_shop_config():
	var file = FileAccess.open("res://project/data/shop_items.json", FileAccess.READ)
	if file:
		shop_config = JSON.parse_string(file.get_as_text())
		refresh_cost = shop_config.refresh_cost.initial
		file.close()

func initialize_shop():
	generate_new_items()
	refresh_cost_updated.emit(refresh_cost)

func generate_new_items(count: int = 5):
	current_items.clear()
	
	# 获取所有可用的物品ID
	var available_items = get_available_items()
	
	# 随机选择不重复的物品
	for i in range(min(count, available_items.size())):
		if available_items.is_empty():
			break
			
		# 随机选择一个物品
		var random_index = randi() % available_items.size()
		var item_id = available_items[random_index]
		
		# 添加到当前物品列表
		var item_data = shop_config.items[item_id].duplicate(true)
		item_data.id = item_id
		current_items.append(item_data)
		
		# 从可用列表中移除，确保不会重复选择
		available_items.remove_at(random_index)
	
	shop_items_updated.emit(current_items)

func get_available_items() -> Array:
	"""获取当前可用的物品ID列表"""
	var available_items = []
	
	# 遍历所有物品
	for item_id in shop_config.items:
		# 跳过已经在当前显示的物品（避免同一次刷新重复）
		if is_item_in_current_display(item_id):
			continue
			
		# 跳过已购买的非一次性物品
		if is_non_consumable_item_purchased(item_id):
			continue
			
		available_items.append(item_id)
	
	return available_items

func is_item_in_current_display(item_id: String) -> bool:
	"""检查物品是否已经在当前刷新中显示"""
	for item in current_items:
		if item.id == item_id:
			return true
	return false

func is_non_consumable_item_purchased(item_id: String) -> bool:
	"""检查非一次性物品是否已被购买"""
	if not player_inventory.has(item_id):
		return false
	
	var item_data = shop_config.items.get(item_id, {})
	var effect_type = item_data.get("effect_type", "")
	
	# 定义非一次性物品类型
	var non_consumable_types = ["permanent", "rechargeable", "round_limited"]
	
	# 如果是非一次性物品且已在库存中，则视为已购买
	if non_consumable_types.has(effect_type) and player_inventory[item_id].quantity > 0:
		return true
	
	return false

func purchase_item(item_id: String) -> bool:
	var item_data = get_item_data(item_id)
	if not item_data:
		return false
	
	# 安全检查：确保货币系统可用
	if not currency_system:
		push_error("货币系统不可用！")
		return false
	
	if currency_system.can_afford(item_data.price) and currency_system.spend_money(item_data.price, "shop_purchase", "auto"):
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
			if coin_system:
				coin_system.apply_buff_to_coin_pool("pattern_coin_percentage", effect_value.percentage)
				coin_system.apply_buff_to_coin_pool("pattern_coin_high_value_prob", effect_value.high_value_prob)
		"increase_complex_pattern_multiplier":
			# 在图案系统中实现
			pass
		"reduce_penalty_coins":
			if coin_system:
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
			if coin_system:
				coin_system.apply_buff_to_coin_pool("real_coin_percentage", effect_value)
		"increase_luck":
			# 在概率计算中实现
			pass
		"extra_sub_round":
			# 在回合管理中实现
			pass
		"reset_stress":
			if stress_system:
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
			if stress_system:
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
	# 安全检查：确保货币系统可用
	if not currency_system:
		push_error("货币系统不可用！")
		return false
	
	if currency_system.can_afford(int(refresh_cost)) and currency_system.spend_money(int(refresh_cost), "shop_refresh", "auto"):
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

# 事件效果：商店系统扩展功能
var shop_discounts_enabled: bool = false
var discount_config: Dictionary = {}
var refresh_cost_multiplier: float = 1.0

func enable_shop_discounts(discount_data: Dictionary):
	"""启用商店折扣功能（事件效果）"""
	shop_discounts_enabled = true
	discount_config = discount_data

func set_refresh_cost_multiplier(multiplier: float):
	"""设置刷新费用倍率（事件效果）"""
	refresh_cost_multiplier = multiplier

# 应用事件效果的刷新费用
func get_refresh_cost_with_effects() -> int:
	var base_cost = refresh_cost
	return int(base_cost * refresh_cost_multiplier)

# 统一刷新方法（合并道具和事件效果）
func refresh_shop_with_all_effects():
	# 使用调整后的刷新费用
	var cost = get_refresh_cost_with_effects()
	
	if currency_system and currency_system.can_afford(cost) and currency_system.spend_money(cost, "shop_refresh", "auto"):
		generate_new_items()
		refresh_cost_updated.emit(refresh_cost)
		return true
	return false

# 检查商品是否有折扣
func has_item_discount(item_id: String) -> bool:
	if not shop_discounts_enabled:
		return false
	
	# 根据折扣配置检查概率
	var probability = discount_config.get("probability", 0.0)
	return randf() <= probability

# 获取商品折扣率
func get_item_discount_rate(item_id: String) -> float:
	if not has_item_discount(item_id):
		return 1.0
	
	# 随机生成折扣率
	var min_discount = discount_config.get("min_discount", 0.1)
	var max_discount = discount_config.get("max_discount", 0.9)
	return randf_range(min_discount, max_discount)

# 应用折扣到商品价格
func get_item_price_with_discount(item_id: String) -> int:
	var item_data = get_item_data(item_id)
	if not item_data:
		return 0
	
	var base_price = item_data.get("price", 0)
	var discount_rate = get_item_discount_rate(item_id)
	return int(base_price * discount_rate)
