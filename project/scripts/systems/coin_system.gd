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
