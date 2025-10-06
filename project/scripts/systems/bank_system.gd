extends Node

var savings: float = 0.0
var savings_interest_rate: float
var loan_interest_rate: float

signal bank_data_updated(new_savings)

func _ready():
	Global.bank_system = self
	var config = _load_config()
	if config:
		savings_interest_rate = config.bank_system.savings_interest_rate
		loan_interest_rate = config.bank_system.loan_interest_rate

func deposit(amount: float):
	if Global.spend_money(amount):
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
	Global.add_money(amount)
	var total_repayment = amount * (1 + loan_interest_rate)
	Global.debt_system.add_debt(total_repayment, rounds_to_repay)
	Global.show_notification("获得贷款: %s 元, %s回合后需偿还 %s 元" % [amount, rounds_to_repay, total_repayment])

func process_end_of_round():
	var interest = savings * savings_interest_rate
	if interest > 0:
		savings += interest
		Global.show_notification("获得存款利息: %s 元" % interest.snapped(0.01))
		bank_data_updated.emit(savings)

func _load_config() -> Dictionary:
	var file = FileAccess.open("res://data/game_config.json", FileAccess.READ)
	if file:
		return JSON.parse_string(file.get_as_text())
	return {}
