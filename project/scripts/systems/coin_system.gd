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

func fill_channel_from_mountain(channel_id: String, coin_count: int = 100):
	# 先检查并应用道具效果
	check_item_effects()
	
	var channel_coins = []
	var distribution = {}
	var total_percentage = 0.0
	
	# 计算总百分比，确保归一化
	for coin_type in coin_pool:
		total_percentage += coin_pool[coin_type].coin_mountain_percentage
	
	# 根据通道ID调整分布（让不同通道有不同特点）
	var channel_multipliers = _get_channel_multipliers(channel_id)
	
	# 生成硬币
	for coin_type in coin_pool:
		var base_percentage = coin_pool[coin_type].coin_mountain_percentage
		var channel_multiplier = channel_multipliers.get(coin_type, 1.0)
		var adjusted_percentage = (base_percentage * channel_multiplier) / total_percentage
		
		var count_for_type = int(coin_count * adjusted_percentage)
		
		# 确保至少有一个硬币
		if count_for_type == 0 and base_percentage > 0:
			count_for_type = 1
		
		for i in range(count_for_type):
			channel_coins.append(coin_type)
		
		distribution[coin_type] = count_for_type
	
	# 如果硬币数量不足，补充随机硬币
	while channel_coins.size() < coin_count:
		var random_coin = _get_random_coin_type()
		channel_coins.append(random_coin)
		distribution[random_coin] = distribution.get(random_coin, 0) + 1
	
	# 如果硬币数量超过，随机移除
	while channel_coins.size() > coin_count:
		var random_index = randi() % channel_coins.size()
		var removed_coin = channel_coins[random_index]
		channel_coins.remove_at(random_index)
		distribution[removed_coin] = distribution.get(removed_coin, 1) - 1
		if distribution[removed_coin] <= 0:
			distribution.erase(removed_coin)
	
	channel_coins.shuffle()
	channel_coin_collections[channel_id] = channel_coins
	calculate_channel_distribution(channel_id)
	
	# 调试输出
	print("通道 %s 填充完成:" % channel_id)
	for coin_type in distribution:
		var percentage = (float(distribution[coin_type]) / float(coin_count)) * 100.0
		print("  %s: %d个 (%.1f%%)" % [coin_pool[coin_type].name, distribution[coin_type], percentage])
	
	return distribution

# 获取通道特定的倍数调整
func _get_channel_multipliers(channel_id: String) -> Dictionary:
	match channel_id:
		"A":  # 通道A：偏向真硬币和太阳币
			return {
				"real_coin": 1.5,
				"sun_coin": 1.3,
				"moon_coin": 0.8,
				"star_coin": 0.8,
				"skull_coin": 0.7,
				"blood_coin": 0.7
			}
		"B":  # 通道B：偏向月亮币和星星币
			return {
				"real_coin": 0.8,
				"sun_coin": 0.8,
				"moon_coin": 1.5,
				"star_coin": 1.5,
				"skull_coin": 0.9,
				"blood_coin": 0.9
			}
		"C":  # 通道C：高风险高回报，更多血币和骷髅币
			return {
				"real_coin": 0.6,
				"sun_coin": 0.7,
				"moon_coin": 0.7,
				"star_coin": 0.7,
				"skull_coin": 1.8,
				"blood_coin": 1.8
			}
		"D":  # 通道D：平衡分布
			return {
				"real_coin": 1.2,
				"sun_coin": 1.1,
				"moon_coin": 1.1,
				"star_coin": 1.1,
				"skull_coin": 0.8,
				"blood_coin": 0.8
			}
		_:
			return {}  # 默认无调整

# 获取随机硬币类型（考虑当前分布）
func _get_random_coin_type() -> String:
	var weights = {}
	var total_weight = 0.0
	
	for coin_type in coin_pool:
		var weight = coin_pool[coin_type].coin_mountain_percentage
		weights[coin_type] = weight
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0.0
	
	for coin_type in weights:
		cumulative += weights[coin_type]
		if random_value <= cumulative:
			return coin_type
	
	return "real_coin"  # 默认返回真硬币

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
	"""
	获取通道的真实硬币分布信息
	基于实际抽取100个硬币统计，而不是默认的硬币山分布
	"""
	# 确保通道有数据
	if not channel_coin_collections.has(channel_id) or channel_coin_collections[channel_id].is_empty():
		fill_channel_from_mountain(channel_id, 100)
	
	var coins = channel_coin_collections[channel_id]
	var total_coins = coins.size()
	
	if total_coins == 0:
		return {}
	
	# 统计每种硬币的实际数量
	var coin_counts = {}
	for coin_type in coin_pool:
		coin_counts[coin_type] = 0
	
	for coin_type in coins:
		coin_counts[coin_type] = coin_counts.get(coin_type, 0) + 1
	
	# 计算实际百分比并构建结果
	var info = {}
	for coin_type in coin_counts:
		var count = coin_counts[coin_type]
		var percentage = (float(count) / float(total_coins)) * 100.0
		var coin_data = coin_pool.get(coin_type, {})
		
		info[coin_type] = {
			"name": coin_data.get("name", coin_type),
			"percentage": percentage,
			"base_value": coin_data.get("base_value", 0),
			"high_value": coin_data.get("high_value", 0),
			"count": count,
			"total_coins": total_coins
		}
	
	# 调试输出
	print("通道 %s 统计分布:" % channel_id)
	for coin_type in info:
		var data = info[coin_type]
		print("  %s: %.1f%% (%d/%d)" % [data.name, data.percentage, data.count, data.total_coins])
	
	return info
	
# 新增方法：获取通道的统计分布数据（用于GameManager）
func get_channel_statistical_distribution(channel_id: String, sample_size: int = 100) -> Array:
	"""
	获取通道的统计分布数据
	返回数组顺序: [真硬币, 太阳币, 月亮币, 星星币, 骷髅币, 血币] 的概率(0-1之间)
	"""
	var distribution_info = get_channel_distribution_info(channel_id)
	if distribution_info.is_empty():
		push_warning("无法获取通道 %s 的分布信息" % channel_id)
		return []
	
	# 定义硬币类型顺序
	var coin_order = ["real_coin", "sun_coin", "moon_coin", "star_coin", "skull_coin", "blood_coin"]
	var result = []
	
	# 按照固定顺序提取概率
	for coin_type in coin_order:
		if distribution_info.has(coin_type):
			# 获取百分比并转换为0-1之间的小数
			var percentage = distribution_info[coin_type].get("percentage", 0.0)
			result.append(percentage / 100.0)
		else:
			result.append(0.0)
	
	# 验证数据完整性
	if result.size() != 6:
		push_error("无效的分布数据 for channel %s: %s" % [channel_id, result])
		return _get_default_distribution()
	
	# 验证概率总和接近1.0（允许小的浮点误差）
	var total = 0.0
	for prob in result:
		total += prob
	
	if abs(total - 1.0) > 0.01:  # 允许1%的误差
		push_warning("通道 %s 分布总和不为1.0 (sum=%.3f)，正在归一化" % [channel_id, total])
		# 归一化处理
		for i in range(result.size()):
			result[i] = result[i] / total
	
	print("通道 %s 统计分布: %s" % [channel_id, result])
	return result

func _get_default_distribution() -> Array:
	"""获取默认的分布数据（备用方案）"""
	return [0.166, 0.166, 0.166, 0.166, 0.166, 0.166]  # 平均分布

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
