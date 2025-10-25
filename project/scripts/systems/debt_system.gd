extends Node

var debt_config: Dictionary
var current_major_round: int = 1
var current_sub_round: int = 1
var debt_paid: int = 0
var debt_targets: Dictionary = {}
var round_history: Array = []

var currency_system = null
var stress_system = null
signal debt_round_changed(major_round: int, sub_round: int)
signal debt_target_updated(target_amount: int, paid_amount: int, remaining: int)
signal debt_paid_successful(amount: int, round_number: int)
signal debt_default(round_number: int, target_amount: int, paid_amount: int)
signal game_over(reason: String)
signal all_debts_completed # 新增：所有债务完成信号
signal game_victory # 新增：游戏胜利信号

func _ready():
	load_debt_config()
	stress_system = Global.get_stress_system()
	currency_system = Global.get_currency_system()

func load_debt_config():
	var file = FileAccess.open("res://project/data/debt_config.json", FileAccess.READ)
	if file:
		debt_config = JSON.parse_string(file.get_as_text())
		debt_targets = debt_config.debt_targets
		file.close()
	
	# 确保回合结构与配置文件一致
	if not debt_config.has("round_structure"):
		debt_config.round_structure = {
			"major_rounds": 6,
			"sub_rounds_per_major": 4
		}

func start_new_game():
	current_major_round = 1
	current_sub_round = 1
	debt_paid = 0
	round_history.clear()
	# 同步Global的回合状态
	if Global:
		Global.current_round = current_major_round
		Global.current_sub_round = current_sub_round
	debt_round_changed.emit(current_major_round, current_sub_round)
	update_debt_target_display()

func advance_round():
	current_sub_round += 1
	
	if current_sub_round > debt_config.round_structure.sub_rounds_per_major:
		current_sub_round = 1
		current_major_round += 1
		
		# 同步Global的回合状态
		if Global:
			Global.current_round = current_major_round
			Global.current_sub_round = current_sub_round
		
		# 检查大回合结束条件
		if current_major_round > debt_config.round_structure.major_rounds:
			# 检查是否完成所有债务
			check_game_victory()
			if not are_all_debts_completed():
				trigger_game_over("max_rounds")
			return false
		
		# 新的大回合开始，重置债务支付状态
		debt_paid = 0
		update_debt_target_display()
	
	debt_round_changed.emit(current_major_round, current_sub_round)
	return true

func get_current_debt_target() -> int:
	return debt_targets.get(str(current_major_round), 0)

func can_afford_debt() -> bool:
	var total_money = currency_system.get_money_breakdown().total_money
	return total_money >= get_current_debt_target()

func pay_debt(amount: int = -1) -> bool:
	var target_amount = get_current_debt_target()
	var remaining_amount = target_amount - debt_paid
	
	if amount == -1:
		amount = remaining_amount
	else:
		# 不能支付超过剩余需要的金额
		amount = min(amount, remaining_amount)
	
	# 确保有足够的金额
	if amount <= 0:
		return true  # 已经完成
	
	if currency_system.spend_money(amount, "debt_payment", "auto"):
		debt_paid += amount
		debt_paid_successful.emit(amount, current_major_round)
		update_debt_target_display()
		
		# 检查是否完成当前回合债务
		if debt_paid >= target_amount:
			complete_round_debt()
		
		return true
	
	return false

func complete_round_debt():
	# 记录回合历史
	round_history.append({
		"round": current_major_round,
		"target": get_current_debt_target(),
		"paid": debt_paid,
		"completed": true,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# 重置已支付金额，准备下一回合
	debt_paid = 0
	
	# 压力减少（盈利时）
	stress_system.change_stress(-debt_config.penalties.round_profit_stress_decrease, "debt_paid")
	
	# 检查是否所有债务都已完成
	if current_major_round >= debt_config.round_structure.major_rounds:
		check_game_victory()

func check_round_balance(round_earned: int, round_spent: int):
	# 检查回合收益是否小于投入
	if round_earned < round_spent:
		stress_system.change_stress(debt_config.penalties.round_loss_stress_increase, "round_loss")
	else:
		stress_system.change_stress(-debt_config.penalties.round_profit_stress_decrease, "round_profit")

func check_debt_default():
	var stress_system = null
	currency_system = Global.get_currency_system()
	stress_system = Global.get_stress_system()
	# 第一个大回合不检查违约，给玩家适应期
	if current_major_round <= 0:
		return false
	
	var target = get_current_debt_target()
	var total_money = currency_system.get_money_breakdown().total_money
	
	if total_money < target:
		# 无法偿还债务
		stress_system.change_stress(debt_config.penalties.cannot_repay_stress_increase, "debt_default")
		debt_default.emit(current_major_round, target, total_money)
		trigger_game_over("debt_default")
		return true
	
	return false

func trigger_game_over(reason: String):
	# 同步触发全局的游戏结束流程，保持信号与处理逻辑一致
	if Engine.has_singleton("Global") or Global != null:
		Global.trigger_game_over(reason)
	# 仍保留本地信号，供需要直接监听债务系统的节点使用
	game_over.emit(reason)

func update_debt_target_display():
	var target = get_current_debt_target()
	var remaining = max(0, target - debt_paid)
	debt_target_updated.emit(target, debt_paid, remaining)

func get_debt_progress() -> Dictionary:
	var target = get_current_debt_target()
	return {
		"current_round": current_major_round,
		"current_sub_round": current_sub_round,
		"target_amount": target,
		"paid_amount": debt_paid,
		"remaining_amount": max(0, target - debt_paid),
		"progress_percentage": float(debt_paid) / float(target) if target > 0 else 0.0
	}

func get_round_history() -> Array:
	return round_history.duplicate()

func is_final_round() -> bool:
	return current_major_round >= debt_config.round_structure.major_rounds



# 新增方法：检查所有债务是否完成
func are_all_debts_completed() -> bool:
	"""检查所有6个大回合的债务是否都已完成"""
	for round_num in range(1, debt_config.round_structure.major_rounds + 1):
		var found = false
		for record in round_history:
			if record.round == round_num and record.completed:
				found = true
				break
		if not found:
			return false
	return true

# 新增方法：检查游戏胜利条件
func check_game_victory():
	"""检查是否满足游戏胜利条件"""
	if are_all_debts_completed():
		all_debts_completed.emit()
		game_victory.emit()
		# 触发全局胜利处理
		if Global:
			Global.trigger_game_victory()

# 新增方法：获取债务完成状态
func get_debt_completion_status() -> Dictionary:
	"""获取所有债务的完成状态"""
	var status = {}
	for round_num in range(1, debt_config.round_structure.major_rounds + 1):
		status[str(round_num)] = false
		for record in round_history:
			if record.round == round_num and record.completed:
				status[str(round_num)] = true
				break
	return status
	
func process_major_round_end():
	"""在大回合结束时调用，自动扣除债务"""
	currency_system = Global.get_currency_system()
	var target_amount = get_current_debt_target()
	var remaining_amount = target_amount - debt_paid
	
	# 如果当前回合已经支付了部分债务，只扣除剩余部分
	if remaining_amount > 0:
		# 检查玩家是否有足够的钱支付剩余债务
		if currency_system.can_afford(remaining_amount):
			# 自动扣除债务
			if currency_system.spend_money(remaining_amount, "debt_payment_auto", "auto"):
				debt_paid += remaining_amount
				Global.show_notification("自动扣除债务: %d 元" % remaining_amount)
				complete_round_debt()
				return true
			else:
				# 扣除失败，触发违约
				trigger_debt_default()
				return false
		else:
			# 资金不足，触发违约
			trigger_debt_default()
			return false
	else:
		# 债务已经完成
		complete_round_debt()
		return true

func trigger_debt_default():
	"""触发债务违约"""
	var target = get_current_debt_target()
	
	# 记录违约历史
	round_history.append({
		"round": current_major_round,
		"target": target,
		"paid": debt_paid,
		"completed": false,
		"defaulted": true,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# 增加压力值
	stress_system.change_stress(debt_config.penalties.cannot_repay_stress_increase, "debt_default")
	
	# 发出违约信号
	debt_default.emit(current_major_round, target, debt_paid)
	
	# 直接触发游戏结束
	Global.trigger_game_over("债务违约")

# 修改现有的 process_end_of_round 方法
func process_end_of_round():
	"""在每个小回合结束时调用"""
	if current_sub_round >= debt_config.round_structure.sub_rounds_per_major:
		# 确保不是第一个大回合的第一轮（给玩家赚钱的机会）
		if current_major_round > 1 or (current_major_round == 1 and current_sub_round > 1):
			var target = get_current_debt_target()
			if debt_paid < target:
				# 大回合结束时债务未完成，触发违约
				check_debt_default()
		
func advance_major_round() -> bool:
	"""推进到大回合，返回是否成功（没有违约）"""
	# 先检查当前大回合的债务是否完成
	var target = get_current_debt_target()
	if debt_paid < target:
		# 债务未完成，触发违约
		trigger_debt_default()
		return false
	
	# 债务完成，记录历史
	complete_round_debt()
	
	# 推进到下一大回合
	current_major_round += 1
	current_sub_round = 1
	
	# 同步Global的回合状态
	if Global:
		Global.current_round = current_major_round
		Global.current_sub_round = current_sub_round
	
	# 检查是否所有债务都已完成
	if current_major_round > debt_config.round_structure.major_rounds:
		check_game_victory()
		return true
	
	# 重置已支付金额，准备下一回合
	debt_paid = 0
	update_debt_target_display()
	debt_round_changed.emit(current_major_round, current_sub_round)
	
	return true
