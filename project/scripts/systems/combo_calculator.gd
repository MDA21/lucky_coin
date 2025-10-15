extends Node

@onready var pattern_system = $"/root/GameManager".get_system("pattern_system")
@onready var stress_system = $"/root/GameManager".get_system("stress_system")

class PatternResult:
	var type: String
	var money: int
	var stress_change: int
	var multiplier: int
	var shape: Array
	
	func _init(_type: String, _money: int, _stress_change: int, _multiplier: int, _shape: Array):
		type = _type
		money = _money
		stress_change = _stress_change
		multiplier = _multiplier
		shape = _shape

func calculate_channel_results(coin_grid: Array, channel_id: String = "") -> Dictionary:
	#计算单个通道的结算结果
	var pattern_result = pattern_system.detect_patterns(coin_grid)
	
	#应用特殊规则
	apply_special_rules(pattern_result, coin_grid)
	
	#计算总收益和压力变化
	var total_result = calculate_final_totals(pattern_result, coin_grid)
	total_result.channel_id = channel_id
	
	return total_result

func apply_special_rules(result: Dictionary, coin_grid: Array):
	#特殊规则：血币和骷髅币的额外效果
	var has_blood_coins = false
	var has_skull_coins = false
	var blood_coin_count = 0
	var skull_coin_count = 0
	
	#统计血币和骷髅币数量
	for row in coin_grid:
		for coin_data in row:
			var coin_name = coin_data.get("name", "")
			if "血币" in coin_name or "blood" in coin_name.to_lower():
				has_blood_coins = true
				blood_coin_count += 1
			if "骷髅币" in coin_name or "skull" in coin_name.to_lower():
				has_skull_coins = true
				skull_coin_count += 1
	
	#血币和骷髅币同时出现时的特殊惩罚
	if has_blood_coins and has_skull_coins:
		var penalty = min(blood_coin_count, skull_coin_count) * 2
		result.total_stress_change += penalty
		result.total_money = max(0, result.total_money - penalty)

func calculate_final_totals(result: Dictionary, coin_grid: Array) -> Dictionary:
	var total_money = result.total_money
	var total_stress = result.total_stress_change
	
	# 应用真硬币的直接收益（不受图案倍率影响）
	var real_coin_money = calculate_real_coin_money(coin_grid)
	total_money += real_coin_money
	
	# 确保压力变化不会使压力值低于0或超过上限
	total_stress = clamp(total_stress, -100, 100)
	
	return {
		"total_money": total_money,
		"total_stress_change": total_stress,
		"patterns_found": result.patterns_found,
		"pattern_count": result.pattern_count,
		"real_coin_money": real_coin_money,
		"channel_coins": get_channel_coin_summary(coin_grid)
	}

func calculate_real_coin_money(coin_grid: Array) -> int:
	var real_coin_total = 0
	
	for row in coin_grid:
		for coin_data in row:
			if coin_data.get("name", "").contains("真硬币") or coin_data.get("name", "").contains("real"):
				# 真硬币直接计算价值，不受图案倍率影响
				real_coin_total += coin_data.get("current_value", 0)
	
	return real_coin_total

func get_channel_coin_summary(coin_grid: Array) -> Dictionary:
	var summary = {
		"total_coins": 0,
		"coin_types": {},
		"high_value_count": 0
	}
	
	for row in coin_grid:
		for coin_data in row:
			summary.total_coins += 1
			var coin_type = coin_data.get("name", "unknown")
			summary.coin_types[coin_type] = summary.coin_types.get(coin_type, 0) + 1
			
			if coin_data.get("is_high_value", false):
				summary.high_value_count += 1
	
	return summary

func calculate_multiple_channels_results(channel_results: Array) -> Dictionary:
	# 计算多个通道的总结果
	var total_money = 0
	var total_stress_change = 0
	var all_patterns = []
	var total_real_coin_money = 0
	
	for channel_result in channel_results:
		total_money += channel_result.total_money
		total_stress_change += channel_result.total_stress_change
		total_real_coin_money += channel_result.get("real_coin_money", 0)
		all_patterns.append_array(channel_result.patterns_found)
	
	# 检查是否所有通道都没有收益（用于压力系统规则）
	var all_channels_no_income = true
	for channel_result in channel_results:
		if channel_result.total_money > 0:
			all_channels_no_income = false
			break
	
	return {
		"total_money": total_money,
		"total_stress_change": total_stress_change,
		"all_patterns": all_patterns,
		"channel_count": channel_results.size(),
		"total_real_coin_money": total_real_coin_money,
		"all_channels_no_income": all_channels_no_income
	}

# 应用倍率到通道结果（在玩家选择倍率后调用）
func apply_multiplier_to_results(result: Dictionary, multiplier: float) -> Dictionary:
	var multiplied_result = result.duplicate(true)
	multiplied_result.total_money = int(result.total_money * multiplier)
	
	# 压力变化也按比例调整（但压力减少效果不放大）
	if result.total_stress_change < 0:
		multiplied_result.total_stress_change = result.total_stress_change
	else:
		multiplied_result.total_stress_change = int(result.total_stress_change * multiplier)
	
	# 更新图案列表中的金额
	for i in range(multiplied_result.patterns_found.size()):
		var pattern = multiplied_result.patterns_found[i]
		pattern.money = int(pattern.money * multiplier)
		if pattern.stress_change > 0:
			pattern.stress_change = int(pattern.stress_change * multiplier)
	
	return multiplied_result
