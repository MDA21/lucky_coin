extends Node

var savings: float = 0.0
var savings_interest_rate: float
var loan_interest_rate: float
var active_loans: Array = []  # 存储活跃贷款

signal bank_data_updated(new_savings)
signal loan_added(loan_data: Dictionary)  # 新增贷款信号
signal loan_due_check(loan_data: Dictionary)  # 贷款到期检查信号

var stress_system = null

func _ready():
	GameManager.bank_system = self
	var config = _load_config()
	if config:
		savings_interest_rate = config.bank_system.savings_interest_rate
		loan_interest_rate = config.bank_system.loan_interest_rate

func deposit(amount: float):
	var purpose = "deposit"
	if Global.spend_money(amount,purpose):
		savings += amount
		Global.show_notification("存款成功: %s 元" % amount)
		bank_data_updated.emit(savings)

func withdraw(amount: float):
	if savings >= amount:
		savings -= amount
		Global.add_money(amount)
		Global.show_notification("取款成功: %s 元" % amount)
		bank_data_updated.emit(savings)
	else:
		Global.show_notification("存款不足！")

func take_loan(amount: float, rounds_to_repay: int):
	Global.add_money(amount, "loan", true)  # is_loan = true
	# 创建贷款记录
	var loan_data = {
		"amount": amount,
		"total_repayment": amount * (1 + loan_interest_rate),
		"remaining_rounds": 6,  # 6个小回合后偿还
		"stress_value": _calculate_loan_stress(amount)  # 根据金额计算压力值
	}
	active_loans.append(loan_data)
	
	# 增加压力值
	Global.stress_system.change_stress(loan_data.stress_value, "loan_taken")
	
	Global.show_notification("获得贷款: %s 元, 需在6回合内偿还 %s 元" % [amount, loan_data.total_repayment])
	loan_added.emit(loan_data)

func _calculate_loan_stress(amount: float) -> int:
	stress_system = Global.get_stress_system()
	var stress_value = stress_system.calculate_loan_stress(amount, true)
	'''var stress_map = {
		100: 15,
		300: 20, 
		600: 25,
		750: 25,
		1200: 30,
		1500: 30,
		2400: 35,
		2500: 35,
		3000: 40,
		5000: 45
	}''' #暂时不启用
	
	return stress_value

func process_end_of_round():
	var interest = savings * savings_interest_rate
	if interest > 0:
		savings += interest
		Global.show_notification("获得存款利息: %s 元" % interest.snapped(0.01))
		bank_data_updated.emit(savings)
		
		# 更新所有活跃贷款的剩余回合数
		_update_loans_rounds()

# 更新贷款回合数并检查到期贷款
func _update_loans_rounds():
	var loans_to_remove = []
	
	for i in range(active_loans.size()):
		var loan = active_loans[i]
		loan.remaining_rounds -= 1
		
		# 检查贷款是否到期
		if loan.remaining_rounds <= 0:
			loans_to_remove.append(i)
			_check_loan_repayment(loan)
	
	# 移除已处理的贷款（倒序删除避免索引问题）
	for i in range(loans_to_remove.size() - 1, -1, -1):
		active_loans.remove_at(loans_to_remove[i])

# 检查贷款偿还
func _check_loan_repayment(loan_data: Dictionary):
	var total_repayment = loan_data.total_repayment
	
	# 检查玩家是否有足够的钱偿还
	if Global.currency_system.can_afford(total_repayment):
		# 强制偿还
		if Global.currency_system.spend_money(total_repayment, "loan_repayment"):
			Global.show_notification("贷款已偿还: %s 元" % total_repayment)
			# 减少压力值（偿还后压力清零）
			Global.stress_system.reduce_stress(loan_data.stress_value, "loan_repaid")
	else:
		# 无法偿还，游戏失败
		Global.show_notification("无法偿还贷款！游戏结束")
		loan_due_check.emit(loan_data)
		# 触发游戏失败逻辑
		Global.trigger_game_over("贷款违约")



# 获取即将到期的贷款
func get_due_loans() -> Array:
	var due_loans = []
	for loan in active_loans:
		if loan.remaining_rounds <= 1:  # 下回合到期
			due_loans.append(loan)
	return due_loans

# 提前偿还贷款（可选功能）
func repay_loan_early(loan_index: int):
	if loan_index < 0 or loan_index >= active_loans.size():
		return false
	
	var loan = active_loans[loan_index]
	var repayment_amount = loan.total_repayment
	
	if Global.currency_system.spend_money(repayment_amount, "early_loan_repayment"):
		# 减少压力值（按比例，因为提前偿还）
		var stress_reduction = loan.stress_value * 0.5  # 提前偿还减少50%压力
		Global.stress_system.reduce_stress(stress_reduction, "early_loan_repaid")
		
		active_loans.remove_at(loan_index)
		Global.show_notification("提前偿还贷款: %s 元" % repayment_amount)
		return true
	
	return false

# 获取活跃贷款列表（用于UI显示）
func get_active_loans() -> Array:
	return active_loans.duplicate()

func _load_config() -> Dictionary:
	var file = FileAccess.open("res://project/data/game_config.json", FileAccess.READ)
	if file:
		return JSON.parse_string(file.get_as_text())
	return {}

# 检查并应用道具效果
func check_item_effects():
	var shop_system = Global.get_shop_system()
	if not shop_system:
		return
	
	# 优质客户凭证 - 无息贷款
	if shop_system.has_item("premium_customer_certificate"):
		# 这个效果在贷款时检查
		pass
	
	# 紧缩的货币政策 - 增加存款利率
	if shop_system.has_item("tight_monetary_policy"):
		savings_interest_rate += 0.045  # 增加4.5%
	
	# 扩张的货币政策 - 减少贷款利率
	if shop_system.has_item("expansionary_monetary_policy"):
		loan_interest_rate *= 0.65  # 长期贷款利率减少35%
	
	# 灵活投贷政策 - 增加贷款选项
	if shop_system.has_item("flexible_loan_policy"):
		# 这个效果在UI中实现
		pass
	
	# 灵活还贷政策 - 增加还贷方式
	if shop_system.has_item("flexible_repayment_policy"):
		# 这个效果在UI中实现
		pass

# 删除重复的贷款方法，已合并到上面的统一方法中

# 应用道具效果的存款利息计算
func process_end_of_round_with_effects():
	# 检查道具效果
	check_item_effects()
	
	# 计算利息
	var interest = savings * savings_interest_rate
	if interest > 0:
		savings += interest
		Global.show_notification("获得存款利息: %s 元" % interest.snapped(0.01))
		bank_data_updated.emit(savings)
		
	_update_loans_rounds()

# 获取当前贷款利率（考虑道具效果）
func get_current_loan_interest_rate() -> float:
	check_item_effects()
	return loan_interest_rate

# 获取当前存款利率（考虑道具效果）
func get_current_savings_interest_rate() -> float:
	check_item_effects()
	return savings_interest_rate

# 事件效果：银行系统扩展功能
var expanded_loan_options_enabled: bool = false
var flexible_repayment_enabled: bool = false
var loan_interest_multipliers: Dictionary = {"long_term": 1.0, "short_term": 1.0}

func set_loan_interest_multipliers(multipliers: Dictionary):
	"""设置贷款利率倍率（事件效果）"""
	loan_interest_multipliers = multipliers

func enable_expanded_loan_options():
	"""启用扩展贷款选项（事件效果）"""
	expanded_loan_options_enabled = true

func enable_flexible_repayment():
	"""启用灵活还贷方式（事件效果）"""
	flexible_repayment_enabled = true

# 统一贷款方法（合并道具和事件效果）
func take_loan_with_all_effects(amount: float, is_interest_free: bool = false):
	# 检查优质客户凭证效果（无息贷款）
	if is_interest_free:
		Global.add_money(amount, "loan", true)
		
		var loan_data = {
			"amount": amount,
			"total_repayment": amount,  # 只还本金
			"remaining_rounds": 6,
			"stress_value": _calculate_loan_stress(amount) * 0.5  # 无息贷款压力减半
		}
		
		active_loans.append(loan_data)
		Global.stress_system.add_stress(loan_data.stress_value, "interest_free_loan")
		Global.show_notification("获得无息贷款: %s 元" % amount)
		loan_added.emit(loan_data)
		return
	
	# 正常贷款，六轮还
	take_loan(amount, 6)

# 获取扩展贷款选项
func get_expanded_loan_options() -> Array:
	if not expanded_loan_options_enabled:
		return []
	
	return [
		{"amount": 350, "rounds": 9, "interest": 0.145},
		{"amount": 550, "rounds": 9, "interest": 0.145},
		{"amount": 7500, "rounds": 9, "interest": 0.145}
	]

# 检查是否支持灵活还贷
func supports_flexible_repayment() -> bool:
	return flexible_repayment_enabled
	
# 获取总贷款金额
func get_total_loan_amount() -> float:
	var total = 0.0
	for loan in active_loans:
		total += loan.amount
	return total
