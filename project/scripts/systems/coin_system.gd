extends Node

#存储从JSON加载的所有硬币的定义
var coin_data: Dictionary = {}
#存储由道具等引起的概率调整
var probability_modifiers: Dictionary = {}

#结算完成信号，参数为最终收益（正为赢，负为亏）
signal payout_calculated(payout_amount)

func _ready():
	#将自身注册到Global，方便其他系统调用
	Global.coin_system = self
	#加载硬币数据
	coin_data = _load_coin_data()

func _load_coin_data() -> Dictionary:

	var file = FileAccess.open("res://project/data/coin_types.json", FileAccess.READ)
	var parsed_json = JSON.parse_string(file.get_as_text())
	return parsed_json


# --- 概率管理 ---

func set_probability_modifier(coin_id: String, multiplier: float):
	"""
	外部系统（如商店）调用此函数来调整特定硬币的出现概率。
	multiplier > 1 表示增加概率, < 1 表示减少。
	例如: multiplier = 1.1 表示增加10%的权重。
	"""
	probability_modifiers[coin_id] = multiplier

func clear_probability_modifier(coin_id: String):
	"""移除特定硬币的概率调整。"""
	if probability_modifiers.has(coin_id):
		probability_modifiers.erase(coin_id)

func generate_coins(count: int) -> Array[Dictionary]:
	"""
	根据权重生成指定数量的硬币。
	返回一个字典数组，每个字典包含硬币ID和具体图案。
	e.g., [{"id": "clover_coin", "pattern": "four_leaf_clover"}, ...]
	"""
	var generated_coins: Array[Dictionary] = []
	if coin_data.is_empty(): return generated_coins

	#1. 计算总权重
	var weighted_list: Array = []
	var total_weight: float = 0.0
	for coin_id in coin_data:
		var coin = coin_data[coin_id]
		var base_weight = float(coin.get("base_probability_weight", 0.0))
		var modifier = float(probability_modifiers.get(coin_id, 1.0))
		var adjusted_weight = base_weight * modifier
		
		if adjusted_weight > 0:
			total_weight += adjusted_weight
			weighted_list.append({"id": coin_id, "weight": adjusted_weight})

	if total_weight <= 0: return generated_coins
	
	#2. 生成硬币
	for i in range(count):
		var random_value = randf() * total_weight
		for item in weighted_list:
			random_value -= item.weight
			if random_value <= 0:
				var chosen_coin_id = item.id
				var coin_info = {"id": chosen_coin_id}
				
				#如果硬币有图案，随机选择一个
				var coin_def = coin_data[chosen_coin_id]
				if coin_def.has("patterns"):
					var patterns = coin_def.patterns
					coin_info["pattern"] = patterns[randi() % patterns.size()]
				
				generated_coins.append(coin_info)
				break
				
	return generated_coins

# --- 结算逻辑 ---

func calculate_payout(coins_in_channel: Array[Dictionary], player_multiplier: float) -> float:
	"""
	计算一个通道内所有硬币的总收益。
	- coins_in_channel: `generate_coins` 生成的字典数组。
	- player_multiplier: 玩家选择的倍率。
	"""
	if coin_data.is_empty(): return 0.0

	var total_payout: float = 0.0
	
	# 1. 预处理：统计所有硬币ID和图案的数量
	var coin_id_counts: Dictionary = {}
	var pattern_counts: Dictionary = {} # e.g., {"clover_coin": {"weed": 5, "clover": 3}}

	for coin in coins_in_channel:
		var id = coin.id
		coin_id_counts[id] = coin_id_counts.get(id, 0) + 1
		
		if coin.has("pattern"):
			if not pattern_counts.has(id):
				pattern_counts[id] = {}
			var pattern = coin.pattern
			pattern_counts[id][pattern] = pattern_counts[id].get(pattern, 0) + 1

	# 2. 分别计算不同类型硬币的收益
	for coin_id in coin_id_counts:
		var coin_def = coin_data[coin_id]
		if coin_def.get("is_direct_cash", false):
			# A. 直接是金钱的硬币
			total_payout += coin_id_counts[coin_id] * coin_def.base_value
		elif coin_def.has("combo_settings"):
			# B. 需要计算图案组合的硬币
			total_payout += _calculate_pattern_combo_payout(coin_id, pattern_counts.get(coin_id, {}))
	
	#3. 应用玩家选择的倍率
	total_payout *= player_multiplier
	
	#4. 发出信号并返回结果
	payout_calculated.emit(total_payout)
	return total_payout


#这里的奖励机制有待策划补充！！这个是三叶草币的例子
func _calculate_pattern_combo_payout(coin_id: String, counts: Dictionary) -> float:
	"""计算单一类型图案组合硬币的收益（例如，只计算三叶草币的部分）。"""
	var payout: float = 0.0
	var coin_def = coin_data[coin_id]
	var combo_settings = coin_def.combo_settings
	var min_combo = combo_settings.min_combo_count
	var multiplier = combo_settings.same_type_multiplier
	
	for i in range(coin_def.patterns.size()):
		var pattern_name = coin_def.patterns[i]
		var pattern_value = float(coin_def.pattern_values[i])
		var count = counts.get(pattern_name, 0)
		
		var num_combos = floor(count / min_combo)
		if num_combos > 0:
			var combo_payout: float = 0.0
			#使用策划案中的累进乘数算法
			for j in range(num_combos):
				combo_payout = (combo_payout + (min_combo * pattern_value)) * multiplier
			payout += combo_payout
			
	return payout
