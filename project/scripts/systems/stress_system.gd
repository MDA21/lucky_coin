extends Node

var current_stress: int = 0
var max_stress: int = 100
var stress_history: Array = []

# 压力视觉效果控制
var stress_effects_enabled: bool = true
var distortion_intensity: float = 0.0
var filter_intensity: float = 0.0

signal stress_changed(new_stress: int, old_stress: int, change: int)
signal stress_max_reached()
signal stress_effect_changed(distortion: float, filter: float)

func _ready():
	# 初始压力
	current_stress = 10
	update_stress_effects()
	_connect_global_signals()
	
func _connect_global_signals():
	"""连接全局信号"""
	if Global.has_signal("money_changed"):
		Global.money_changed.connect(_on_global_money_changed)
	if Global.has_signal("round_changed"):
		Global.round_changed.connect(_on_global_round_changed)

func change_stress(amount: int, source: String = "unknown"):
	var old_stress = current_stress
	current_stress = clamp(current_stress + amount, 0, max_stress)
	
	stress_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"change": amount,
		"source": source,
		"new_value": current_stress
	})
	
	# 限制历史记录长度
	if stress_history.size() > 100:
		stress_history.pop_front()
	
	stress_changed.emit(current_stress, old_stress, amount)
	update_stress_effects()
	show_stress_warning_if_needed(current_stress)
	# 检查压力爆表
	if current_stress >= max_stress:
		stress_max_reached.emit()

func update_stress_effects():
	var old_distortion = distortion_intensity
	var old_filter = filter_intensity
	
	# 75压力开始画面扭曲
	distortion_intensity = max(0.0, (float(current_stress) - 75.0) / 25.0) if current_stress > 75 else 0.0
	
	# 90压力加阴间滤镜
	filter_intensity = max(0.0, (float(current_stress) - 90.0) / 10.0) if current_stress > 90 else 0.0
	
	if old_distortion != distortion_intensity or old_filter != filter_intensity:
		stress_effect_changed.emit(distortion_intensity, filter_intensity)

# 通道无收益时的压力增加
func add_stress_no_income(channel_count: int, all_channels_no_income: bool):
	# 单个通道无收益：+5压力
	change_stress(5, "no_income")
	
	# 多个通道均无收益：额外+5压力
	if all_channels_no_income and channel_count >= 2:
		change_stress(5, "all_channels_no_income")

# 回合收益检查的压力变化
func add_stress_round_balance(round_earned: int, round_spent: int):
	if round_earned < round_spent:
		change_stress(20, "round_loss")
	else:
		change_stress(-10, "round_profit")

# 图案组合减压 - 修正版本
func reduce_stress_from_patterns(pattern_results: Array):
	var total_reduction = 0
	
	# 从全局获取图案系统
	var pattern_system = Global.get_pattern_system()
	if not pattern_system:
		push_warning("Pattern system not available for stress reduction calculation")
		return
	
	for pattern in pattern_results:
		# 直接从图案结果中获取减压值，而不是查询图案系统
		if pattern.has("stress_reduction"):
			total_reduction += pattern.stress_reduction
	
	if total_reduction > 0:
		change_stress(-total_reduction, "pattern_combo")

# 贷款压力管理 目前这部分托管给了银行系统
'''func add_stress_from_loan(loan_amount: int, is_short_term: bool) -> int:
	var stress_amount = calculate_loan_stress(loan_amount, is_short_term)
	change_stress(stress_amount, "loan_taken")
	return stress_amount'''

func calculate_loan_stress(loan_amount: int, is_short_term: bool) -> int:
	# 根据贷款金额计算压力值
	if is_short_term:
		if loan_amount <= 100:
			return 15
		elif loan_amount <= 300:
			return 20
		elif loan_amount <= 600:
			return 25
		elif loan_amount <= 1200:
			return 30
		else:
			return 35
	else:
		# 长期贷款压力计算（简化）
		return int(loan_amount / 200) + 10

func reduce_stress_from_repayment(loan_amount: int, total_installments: int, repaid_installments: int):
	var total_stress = calculate_loan_stress(loan_amount, false)
	var stress_per_installment = float(total_stress) / float(total_installments)
	var stress_reduction = int(stress_per_installment * repaid_installments)
	
	change_stress(-stress_reduction, "loan_repayment")

func get_stress_level() -> String:
	if current_stress < 30:
		return "low"
	elif current_stress < 60:
		return "medium"
	elif current_stress < 85:
		return "high"
	else:
		return "critical"

func get_stress_percentage() -> float:
	return float(current_stress) / float(max_stress)

func reset_stress():
	var old_stress = current_stress
	current_stress = 0
	stress_changed.emit(current_stress, old_stress, -old_stress)
	update_stress_effects()

func set_max_stress(new_max: int):
	max_stress = new_max
	current_stress = min(current_stress, max_stress)
	stress_changed.emit(current_stress, current_stress, 0)

# 道具效果：立即减少压力
func reduce_stress_immediate(amount: int):
	change_stress(-amount, "item_effect")

# 检查并应用道具效果
func check_item_effects():
	var shop_system = Global.get_shop_system()
	if not shop_system:
		return
	
	# 抗压体质 - 增加最大压力值
	if shop_system.has_item("stress_resistance"):
		# 这个效果在事件系统中处理，这里只是检查
		pass
	
	# 心理预期 - 减少压力增长
	if shop_system.has_item("psychological_expectation"):
		# 这个效果在事件系统中处理
		pass
	
	# 主任医师 - 增强精神类药物效果
	if shop_system.has_item("chief_physician"):
		# 这个效果在事件系统中处理
		pass
	
	# 善解人意的贷款经理 - 减少贷款压力
	if shop_system.has_item("understanding_loan_manager"):
		# 这个效果在事件系统中处理
		pass
	
	# 乐天派 - 增强图案减压效果
	if shop_system.has_item("optimist"):
		# 这个效果在事件系统中处理
		pass

# 统一压力变化方法（合并道具和事件效果）
func change_stress_with_all_effects(amount: int, source: String = "unknown"):
	var final_amount = amount
	
	# 应用事件效果倍率
	if amount > 0 and source == "slot_machine":
		final_amount = int(amount * stress_growth_multiplier)
	elif amount < 0 and source == "item_effect":
		final_amount = int(amount * stress_reduction_multiplier)
	elif amount < 0 and source == "pattern_combo":
		final_amount = int(amount * pattern_stress_reduction_multiplier)
	
	# 应用道具效果（如果事件效果未应用）
	if final_amount == amount:
		# 检查心理预期效果（减少压力增长）
		if amount > 0 and source == "slot_machine":
			var shop_system = Global.get_shop_system()
			if shop_system and shop_system.has_item("psychological_expectation"):
				final_amount = int(amount * 0.75)  # 减少25%的压力增长
		
		# 检查主任医师效果（增强减压道具效果）
		if amount < 0 and source == "item_effect":
			var shop_system = Global.get_shop_system()
			if shop_system and shop_system.has_item("chief_physician"):
				final_amount = int(amount * 1.5)  # 增强50%的减压效果
		
		# 检查乐天派效果（增强图案减压效果）
		if amount < 0 and source == "pattern_combo":
			var shop_system = Global.get_shop_system()
			if shop_system and shop_system.has_item("optimist"):
				final_amount = int(amount * 1.5)  # 增强50%的图案减压效果
	
	change_stress(final_amount, source)

# 统一贷款压力计算（合并道具和事件效果）
func add_stress_from_loan_with_all_effects(loan_amount: int, is_short_term: bool) -> int:
	var base_stress = calculate_loan_stress(loan_amount, is_short_term)
	
	# 应用事件效果倍率
	base_stress = int(base_stress * loan_stress_multiplier)
	
	# 应用道具效果（如果事件效果未应用）
	if loan_stress_multiplier == 1.0:
		var shop_system = Global.get_shop_system()
		if shop_system and shop_system.has_item("understanding_loan_manager"):
			base_stress = int(base_stress * 0.6)  # 减少40%的贷款压力
	
	change_stress(base_stress, "loan_taken")
	return base_stress

# 重置压力（AED效果）- 已在上方定义，此处删除重复

# 事件效果：压力系统倍率
var stress_growth_multiplier: float = 1.0
var stress_reduction_multiplier: float = 1.0
var loan_stress_multiplier: float = 1.0
var pattern_stress_reduction_multiplier: float = 1.0

# 全局信号处理
func _on_global_money_changed(normal_money: int, loan_money: int, total_money: int):
	"""当金钱变化时，检查是否需要增加压力"""
	# 如果贷款货币比例过高，增加压力
	var loan_ratio = float(loan_money) / float(total_money) if total_money > 0 else 0.0
	if loan_ratio > 0.7:  # 贷款占比超过70%
		change_stress(5, "high_loan_ratio")
	elif loan_ratio > 0.5:  # 贷款占比超过50%
		change_stress(2, "medium_loan_ratio")

func _on_global_round_changed(major_round: int, sub_round: int):
	"""当回合变化时，检查是否需要增加压力"""
	# 随着回合推进，基础压力逐渐增加
	if major_round > 3:  # 第4回合开始
		var round_stress = (major_round - 3) * 2  # 每回合增加2点基础压力
		change_stress(round_stress, "round_progression")
	
	# 如果是大回合的最后一个小回合，检查债务压力
	var debt_system = Global.get_debt_system()
	if debt_system and sub_round >= 4:  # 最后一个小回合
		var debt_progress = debt_system.get_debt_progress()
		var progress_percentage = debt_progress.get("progress_percentage", 0.0)
		
		if progress_percentage < 0.5:  # 债务完成度低于50%
			change_stress(10, "debt_pressure")
		elif progress_percentage < 0.8:  # 债务完成度低于80%
			change_stress(5, "debt_pressure")

# 新增方法：获取压力警告级别
func get_stress_warning_level() -> String:
	"""获取压力警告级别，用于UI显示不同的警告颜色"""
	var percentage = get_stress_percentage()
	if percentage >= 0.9:
		return "critical"
	elif percentage >= 0.75:
		return "high"
	elif percentage >= 0.5:
		return "medium"
	else:
		return "low"

# 新增方法：显示压力警告通知
func show_stress_warning_if_needed(stress:int):
	if stress >= 75:
		Global.show_notification("压力过高！请注意控制")
