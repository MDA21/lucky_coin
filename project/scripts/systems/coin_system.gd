extends Node

var coin_pool: Dictionary
var current_round: int = 1
# 存储每个通道的硬币分布（从硬币山抽取后的实际分布）
var channel_coin_distributions: Dictionary = {}
# 存储每个通道的硬币集合（模拟从硬币山抽取）
var channel_coin_collections: Dictionary = {}

func _ready():
	load_coin_config()

func load_coin_config():
	var file = FileAccess.open("res://project/data/coin_types.json", FileAccess.READ)
	if file:
		coin_pool = JSON.parse_string(file.get_as_text())
		file.close()

# 第一步：从硬币山抽取硬币到通道
func fill_channel_from_mountain(channel_id: String, coin_count: int = 100):
	var channel_coins = []
	var distribution = {}
	
	# 按照硬币山比例抽取硬币
	for coin_type in coin_pool:
		var percentage = coin_pool[coin_type].coin_mountain_percentage
		var count_for_type = int(coin_count * percentage / 100.0)
		
		for i in range(count_for_type):
			channel_coins.append(coin_type)
		
		distribution[coin_type] = count_for_type
	
	# 随机打乱通道内的硬币顺序
	channel_coins.shuffle()
	channel_coin_collections[channel_id] = channel_coins
	
	# 计算通道的实际分布概率
	calculate_channel_distribution(channel_id)
	
	return distribution

# 计算通道的实际硬币分布概率
func calculate_channel_distribution(channel_id: String):
	var coins = channel_coin_collections.get(channel_id, [])
	var distribution = {}
	var total = coins.size()
	
	if total == 0:
		return {}
	
	# 统计每种硬币的数量
	for coin_type in coin_pool:
		distribution[coin_type] = 0
	
	for coin_type in coins:
		distribution[coin_type] = distribution.get(coin_type, 0) + 1
	
	# 转换为概率
	for coin_type in distribution:
		distribution[coin_type] = float(distribution[coin_type]) / float(total)
	
	channel_coin_distributions[channel_id] = distribution
	return distribution

# 第二步：从通道抽取硬币到硬币板（按通道分布概率）
func get_coin_for_slot(channel_id: String) -> Dictionary:
	var distribution = channel_coin_distributions.get(channel_id, {})
	
	if distribution.is_empty():
		#如果通道还没有分布，先填充硬币
		fill_channel_from_mountain(channel_id)
		distribution = channel_coin_distributions[channel_id]
	
	# 按照通道的实际分布概率随机抽取
	var rand = randf()
	var cumulative = 0.0
	
	for coin_type in distribution:
		cumulative += distribution[coin_type]
		if rand <= cumulative:
			return create_coin_instance(coin_type)
	
	# 默认返回真硬币
	return create_coin_instance("real_coin")

# 获取通道的详细分布信息（用于显示）
func get_channel_distribution_info(channel_id: String) -> Dictionary:
	var distribution = channel_coin_distributions.get(channel_id, {})
	var info = {}
	
	for coin_type in distribution:
		var percentage = distribution[coin_type] * 100.0
		info[coin_type] = {
			"name": coin_pool[coin_type].name,
			"percentage": percentage,
			"count": int(distribution[coin_type] * 100)  # 基于100个硬币的估算
		}
	
	return info

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
	#这里修改硬币山的分布，影响后续新通道的抽取
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
