extends Node

var pattern_config: Dictionary
var detected_patterns: Array = []

func _ready():
	load_pattern_config()

func load_pattern_config():
	var file = FileAccess.open("res://data/pattern_config.json", FileAccess.READ)
	if file:
		pattern_config = JSON.parse_string(file.get_as_text())
		file.close()

func detect_patterns(coin_grid: Array) -> Dictionary:
	detected_patterns.clear()
	var grid = convert_to_simple_grid(coin_grid)
	
	# 检测所有图案
	detect_basic_patterns(grid)
	detect_special_patterns(grid)
	
	# 应用排除规则（基础图案算大不算小）
	apply_exclusion_rules()
	
	return calculate_results(coin_grid)

func convert_to_simple_grid(coin_grid: Array) -> Array:
	# 将硬币网格转换为简单的类型网格用于图案检测
	var simple_grid = []
	for row in coin_grid:
		var simple_row = []
		for coin_data in row:
			if coin_data.has("name"):
				simple_row.append(coin_data.name)
			else:
				simple_row.append("unknown")
		simple_grid.append(simple_row)
	return simple_grid

func detect_basic_patterns(grid: Array):
	var patterns = pattern_config.patterns
	
	# 检测三连（横、竖、斜）
	for shape_group in patterns.three_line.shapes:
		for shape in patterns.three_line.shapes[shape_group]:
			if check_shape_match(grid, shape):
				detected_patterns.append({
					"type": "three_line",
					"shape": shape,
					"multiplier": patterns.three_line.multiplier,
					"stress_reduction": patterns.three_line.stress_reduction
				})
	
	# 检测四连（竖）
	for shape in patterns.four_line.shapes.vertical:
		if check_shape_match(grid, shape):
			detected_patterns.append({
				"type": "four_line", 
				"shape": shape,
				"multiplier": patterns.four_line.multiplier,
				"stress_reduction": patterns.four_line.stress_reduction
			})
	
	# 检测五连（竖）
	for shape in patterns.five_line.shapes.vertical:
		if check_shape_match(grid, shape):
			detected_patterns.append({
				"type": "five_line",
				"shape": shape,
				"multiplier": patterns.five_line.multiplier,
				"stress_reduction": patterns.five_line.stress_reduction
			})

func detect_special_patterns(grid: Array):
	var patterns = pattern_config.patterns
	var special_patterns = ["left_arrow", "right_arrow", "left_big", "right_big", "eye", "sun", "full_screen"]
	
	for pattern_type in special_patterns:
		var pattern_data = patterns[pattern_type]
		if check_shape_match(grid, pattern_data.shape):
			detected_patterns.append({
				"type": pattern_type,
				"shape": pattern_data.shape,
				"multiplier": pattern_data.multiplier,
				"stress_reduction": pattern_data.stress_reduction
			})

func check_shape_match(grid: Array, shape: Array) -> bool:
	# 检查形状是否匹配（所有位置都有硬币）
	for position in shape:
		var row = position[0]
		var col = position[1]
		
		if row < 0 or row >= grid.size() or col < 0 or col >= grid[0].size():
			return false
		
		if grid[row][col] == "empty" or grid[row][col] == "unknown":
			return false
	
	return true

func apply_exclusion_rules():
	var basic_patterns = pattern_config.exclusion_rules.basic_patterns
	var patterns_to_remove = []
	
	# 对于基础图案，只保留最大的（五连 > 四连 > 三连）
	for i in range(detected_patterns.size()):
		var pattern1 = detected_patterns[i]
		if not basic_patterns.has(pattern1.type):
			continue
			
		for j in range(i + 1, detected_patterns.size()):
			var pattern2 = detected_patterns[j]
			if not basic_patterns.has(pattern2.type):
				continue
			
			# 检查是否是相同类型的更大图案
			if is_larger_pattern(pattern1, pattern2) and patterns_overlap(pattern1.shape, pattern2.shape):
				if get_pattern_size(pattern1.type) > get_pattern_size(pattern2.type):
					patterns_to_remove.append(pattern2)
				else:
					patterns_to_remove.append(pattern1)
	
	# 移除被排除的图案
	for pattern in patterns_to_remove:
		if detected_patterns.has(pattern):
			detected_patterns.erase(pattern)

func is_larger_pattern(pattern1: Dictionary, pattern2: Dictionary) -> bool:
	var sizes = {"three_line": 1, "four_line": 2, "five_line": 3}
	return pattern1.type != pattern2.type

func get_pattern_size(pattern_type: String) -> int:
	var sizes = {"three_line": 1, "four_line": 2, "five_line": 3}
	return sizes.get(pattern_type, 0)

func patterns_overlap(shape1: Array, shape2: Array) -> bool:
	for pos1 in shape1:
		for pos2 in shape2:
			if pos1[0] == pos2[0] and pos1[1] == pos2[1]:
				return true
	return false

func calculate_results(coin_grid: Array) -> Dictionary:
	var total_money = 0
	var total_stress_change = 0
	var pattern_details = []
	
	for pattern in detected_patterns:
		var pattern_money = 0
		var pattern_stress = 0
		
		# 计算图案覆盖的硬币价值
		for position in pattern.shape:
			var row = position[0]
			var col = position[1]
			var coin_data = coin_grid[row][col]
			
			# 血币增加压力，其他币增加金钱
			if coin_data.has("is_stress_coin") and coin_data.is_stress_coin:
				pattern_stress += abs(coin_data.get("current_value", 0))
			else:
				pattern_money += coin_data.get("current_value", 0)
		
		# 应用倍率
		pattern_money *= pattern.multiplier
		pattern_stress *= pattern.multiplier
		
		total_money += pattern_money
		total_stress_change += pattern_stress
		
		# 减去图案带来的压力减少
		total_stress_change -= pattern.stress_reduction
		
		pattern_details.append({
			"type": pattern.type,
			"money": pattern_money,
			"stress_change": pattern_stress - pattern.stress_reduction,
			"multiplier": pattern.multiplier
		})
	
	return {
		"total_money": total_money,
		"total_stress_change": total_stress_change,
		"patterns_found": pattern_details,
		"pattern_count": detected_patterns.size()
	}

func get_detected_patterns() -> Array:
	return detected_patterns.duplicate()
