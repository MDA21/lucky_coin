extends Node

var coin_pool: Dictionary
var current_round: int = 1

# 存储每个通道的硬币分布数据
var channel_coin_distributions: Dictionary = {}
var channel_coin_collections: Dictionary = {}

func _ready():
	load_coin_config()

func load_coin_config():
	var file = FileAccess.open("res://project/data/coin_types.json", FileAccess.READ)
	if file:
		coin_pool = JSON.parse_string(file.get_as_text())
		file.close()

# 填充通道的硬币分布数据
func fill_channel_from_mountain(channel_id: String, coin_count: int = 100):
	var channel_coins = []
	var distribution = {}
	
	for coin_type in coin_pool:
		var percentage = coin_pool[coin_type].coin_mountain_percentage
		var count_for_type = int(coin_count * percentage / 100.0)
		
		for i in range(count_for_type):
			channel_coins.append(coin_type)
		
		distribution[coin_type] = count_for_type
	
	channel_coins.shuffle()
	channel_coin_collections[channel_id] = channel_coins
	calculate_channel_distribution(channel_id)
	
	return distribution

func calculate_channel_distribution(channel_id: String):
	var coins = channel_coin_collections.get(channel_id, [])
	var distribution = {}
	var total = coins.size()
	
	if total == 0:
		return {}
	
	for coin_type in coin_pool:
		distribution[coin_type] = 0
	
	for coin_type in coins:
		distribution[coin_type] = distribution.get(coin_type, 0) + 1
	
	for coin_type in distribution:
		distribution[coin_type] = float(distribution[coin_type]) / float(total)
	
	channel_coin_distributions[channel_id] = distribution
	return distribution

# 从通道获取硬币数据（用于硬币板）
func get_coin_for_slot(channel_id: String) -> Dictionary:
	var distribution = channel_coin_distributions.get(channel_id, {})
	
	if distribution.is_empty():
		fill_channel_from_mountain(channel_id)
		distribution = channel_coin_distributions[channel_id]
	
	var rand = randf()
	var cumulative = 0.0
	
	for coin_type in distribution:
		cumulative += distribution[coin_type]
		if rand <= cumulative:
			return create_coin_instance(coin_type)
	
	return create_coin_instance("real_coin")

func create_coin_instance(coin_type: String) -> Dictionary:
	var coin_data = coin_pool[coin_type].duplicate(true)
	
	if coin_data.has_two_sides:
		var is_high_value = randf() <= coin_data.high_value_probability
		coin_data.current_value = coin_data.high_value if is_high_value else coin_data.base_value
		coin_data.current_texture = coin_data.high_value_texture if is_high_value else coin_data.texture
		coin_data.is_high_value = is_high_value
	else:
		coin_data.current_value = coin_data.base_value
		coin_data.current_texture = coin_data.texture
		coin_data.is_high_value = false
	
	return coin_data

# 道具效果存储
var item_effects: Dictionary = {}

func apply_buff_to_coin_pool(buff_type: String, value: float):
	match buff_type:
		"real_coin_percentage":
			coin_pool["real_coin"].coin_mountain_percentage += value
		"pattern_coin_percentage":
			coin_pool["sun_coin"].coin_mountain_percentage += value / 3.0
			coin_pool["moon_coin"].coin_mountain_percentage += value / 3.0
			coin_pool["star_coin"].coin_mountain_percentage += value / 3.0
		"pattern_coin_high_value_prob":
			coin_pool["sun_coin"].high_value_probability += value
			coin_pool["moon_coin"].high_value_probability += value
			coin_pool["star_coin"].high_value_probability += value
		"penalty_coin_percentage":
			coin_pool["skull_coin"].coin_mountain_percentage -= value / 2.0
			coin_pool["blood_coin"].coin_mountain_percentage -= value / 2.0
		"penalty_coin_high_value_prob":
			coin_pool["skull_coin"].high_value_probability -= value
			coin_pool["blood_coin"].high_value_probability -= value

# 检查并应用道具效果
func check_item_effects():
	var shop_system = Global.get_shop_system()
	if not shop_system:
		return
	
	# 太阳图腾效果
	if shop_system.has_item("sun_totem"):
		apply_buff_to_coin_pool("pattern_coin_percentage", 2.0)
		apply_buff_to_coin_pool("pattern_coin_high_value_prob", 2.5)
	
	# 矿脉地图效果
	if shop_system.has_item("vein_map"):
		apply_buff_to_coin_pool("real_coin_percentage", 5.0)
	
	# 十字架效果
	if shop_system.has_item("cross"):
		apply_buff_to_coin_pool("penalty_coin_percentage", 2.0)
	
	# 太阳符石效果（充能道具，需要激活）
	if shop_system.has_item("sun_stone") and shop_system.get_item_quantity("sun_stone") > 0:
		var item = shop_system.get_player_inventory().get("sun_stone", {})
		if item.get("cooldown_remaining", 0) == 0:
			apply_buff_to_coin_pool("pattern_coin_percentage", 6.0)
			apply_buff_to_coin_pool("pattern_coin_high_value_prob", 5.0)
	
	# 天使号角效果（充能道具，需要激活）
	if shop_system.has_item("angel_horn") and shop_system.get_item_quantity("angel_horn") > 0:
		var item = shop_system.get_player_inventory().get("angel_horn", {})
		if item.get("cooldown_remaining", 0) == 0:
			# 临时阻止惩罚硬币出现
			block_penalty_coins_temporarily()

# 临时阻止惩罚硬币
func block_penalty_coins_temporarily():
	# 在生成硬币时检查此效果
	pass

# 修改硬币生成逻辑以应用道具效果
func get_coin_for_slot_with_effects(channel_id: String) -> Dictionary:
	# 检查天使号角效果
	var shop_system = Global.get_shop_system()
	if shop_system and shop_system.has_item("angel_horn"):
		var item = shop_system.get_player_inventory().get("angel_horn", {})
		if item.get("cooldown_remaining", 0) == 0:
			# 临时修改硬币池，移除惩罚硬币
			return get_coin_without_penalty_coins(channel_id)
	
	# 正常生成硬币
	return get_coin_for_slot(channel_id)

# 生成不包含惩罚硬币的硬币
func get_coin_without_penalty_coins(channel_id: String) -> Dictionary:
	var distribution = channel_coin_distributions.get(channel_id, {})
	
	if distribution.is_empty():
		fill_channel_from_mountain(channel_id)
		distribution = channel_coin_distributions[channel_id]
	
	# 创建临时分布，移除惩罚硬币
	var temp_distribution = {}
	var total_weight = 0.0
	
	for coin_type in distribution:
		if coin_type != "skull_coin" and coin_type != "blood_coin":
			temp_distribution[coin_type] = distribution[coin_type]
			total_weight += distribution[coin_type]
	
	# 重新归一化
	for coin_type in temp_distribution:
		temp_distribution[coin_type] = temp_distribution[coin_type] / total_weight
	
	# 根据临时分布生成硬币
	var rand = randf()
	var cumulative = 0.0
	
	for coin_type in temp_distribution:
		cumulative += temp_distribution[coin_type]
		if rand <= cumulative:
			return create_coin_instance(coin_type)
	
	return create_coin_instance("real_coin")

# 获取通道分布信息（用于金属探测器）
func get_channel_distribution_info(channel_id: String) -> Dictionary:
	if not channel_coin_distributions.has(channel_id):
		return {}
	
	var distribution = channel_coin_distributions[channel_id]
	var info = {}
	
	for coin_type in distribution:
		var coin_data = coin_pool.get(coin_type, {})
		info[coin_type] = {
			"name": coin_data.get("name", coin_type),
			"percentage": distribution[coin_type] * 100.0,
			"base_value": coin_data.get("base_value", 0),
			"high_value": coin_data.get("high_value", 0)
		}
	
	return info

# 事件效果：硬币价值倍率
var coin_value_multipliers: Dictionary = {}

func set_coin_value_multiplier(coin_target: String, multiplier: float):
	"""设置硬币价值倍率（事件效果）"""
	coin_value_multipliers[coin_target] = multiplier

func set_coin_base_value_multiplier(coin_target: String, multiplier: float):
	"""设置硬币基础价值倍率（事件效果）"""
	if not coin_value_multipliers.has(coin_target):
		coin_value_multipliers[coin_target] = {"base": 1.0, "high": 1.0}
	coin_value_multipliers[coin_target]["base"] = multiplier

func set_coin_high_value_multiplier(coin_target: String, multiplier: float):
	"""设置硬币高价值倍率（事件效果）"""
	if not coin_value_multipliers.has(coin_target):
		coin_value_multipliers[coin_target] = {"base": 1.0, "high": 1.0}
	coin_value_multipliers[coin_target]["high"] = multiplier

# 修改硬币实例创建以应用价值倍率
func create_coin_instance_with_multipliers(coin_type: String) -> Dictionary:
	var coin_data = coin_pool[coin_type].duplicate(true)
	
	# 应用价值倍率
	var multipliers = coin_value_multipliers.get(coin_type, {"base": 1.0, "high": 1.0})
	
	if coin_data.has_two_sides:
		var is_high_value = randf() <= coin_data.high_value_probability
		var base_value = coin_data.base_value
		var high_value = coin_data.high_value
		
		# 应用倍率
		if is_high_value:
			coin_data.current_value = int(high_value * multipliers.get("high", 1.0))
		else:
			coin_data.current_value = int(base_value * multipliers.get("base", 1.0))
		
		coin_data.current_texture = coin_data.high_value_texture if is_high_value else coin_data.texture
		coin_data.is_high_value = is_high_value
	else:
		coin_data.current_value = int(coin_data.base_value * multipliers.get("base", 1.0))
		coin_data.current_texture = coin_data.texture
		coin_data.is_high_value = false
	
	return coin_data
