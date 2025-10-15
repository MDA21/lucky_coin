extends Node

class Currency:
	var normal_money: int = 0
	var loan_money: int = 0
	
	func get_total() -> int:
		return normal_money + loan_money
	
	func can_afford(amount: int) -> bool:
		return get_total() >= amount
	
	func spend(amount: int, spend_preference: String = "auto") -> bool:
		#支付优先级: "normal", "loan", "auto"
		if not can_afford(amount):
			return false
		
		match spend_preference:
			"normal":
				if normal_money >= amount:
					normal_money -= amount
					return true
				else:
					return false
			"loan":
				if loan_money >= amount:
					loan_money -= amount
					return true
				else:
					return false
			"auto":
				#优先使用普通货币
				if normal_money >= amount:
					normal_money -= amount
					return true
				else:
					var remaining = amount - normal_money
					normal_money = 0
					loan_money -= remaining
					return true
		
		return false

var player_currency: Currency
var total_earned: int = 0
var total_spent: int = 0

signal money_changed(normal_money: int, loan_money: int, total_money: int)
signal money_earned(amount: int, source: String, is_loan_money: bool)
signal money_spent(amount: int, purpose: String, used_loan_money: bool)

func _ready():
	player_currency = Currency.new()
	# 初始资金
	player_currency.normal_money = 100

func add_money(amount: int, source_type: String = "normal", is_loan: bool = false):
	if amount <= 0:
		return
	
	if is_loan:
		player_currency.loan_money += amount
	else:
		player_currency.normal_money += amount
	
	total_earned += amount
	money_changed.emit(player_currency.normal_money, player_currency.loan_money, player_currency.get_total())
	money_earned.emit(amount, source_type, is_loan)

func spend_money(amount: int, purpose: String, spend_preference: String = "auto") -> bool:
	if player_currency.spend(amount, spend_preference):
		total_spent += amount
		var used_loan = (spend_preference == "loan") or (spend_preference == "auto" and player_currency.normal_money < amount)
		money_changed.emit(player_currency.normal_money, player_currency.loan_money, player_currency.get_total())
		money_spent.emit(amount, purpose, used_loan)
		return true
	return false

func can_afford(amount: int) -> bool:
	return player_currency.can_afford(amount)

func get_money_breakdown() -> Dictionary:
	return {
		"normal_money": player_currency.normal_money,
		"loan_money": player_currency.loan_money,
		"total_money": player_currency.get_total(),
		"normal_percentage": float(player_currency.normal_money) / float(player_currency.get_total()) if player_currency.get_total() > 0 else 0.0
	}

# 用于UI显示货币来源
func get_money_source_for_purchase(amount: int, spend_preference: String = "auto") -> Dictionary:
	var temp_currency = Currency.new()
	temp_currency.normal_money = player_currency.normal_money
	temp_currency.loan_money = player_currency.loan_money
	
	var used_normal = 0
	var used_loan = 0
	
	match spend_preference:
		"normal":
			used_normal = min(amount, temp_currency.normal_money)
		"loan":
			used_loan = min(amount, temp_currency.loan_money)
		"auto":
			used_normal = min(amount, temp_currency.normal_money)
			used_loan = amount - used_normal
	
	return {
		"used_normal": used_normal,
		"used_loan": used_loan,
		"remaining_normal": temp_currency.normal_money - used_normal,
		"remaining_loan": temp_currency.loan_money - used_loan
	}

func transfer_to_bank(amount: int) -> bool:
	# 只有普通货币可以存入银行
	if player_currency.normal_money >= amount:
		player_currency.normal_money -= amount
		money_changed.emit(player_currency.normal_money, player_currency.loan_money, player_currency.get_total())
		return true
	return false

func withdraw_from_bank(amount: int):
	player_currency.normal_money += amount
	money_changed.emit(player_currency.normal_money, player_currency.loan_money, player_currency.get_total())

func get_available_for_bank() -> int:
	return player_currency.normal_money
