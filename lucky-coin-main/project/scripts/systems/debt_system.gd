extends Node

var debt_list: Array[Dictionary] = []

func _ready():
	Global.debt_system = self
	var config = _load_config()
	if config and config.has("initial_debt"):
		var initial = config.initial_debt
		add_debt(initial.amount, initial.rounds_due)

func add_debt(amount: float, rounds_due: int):
	debt_list.append({"amount": amount, "rounds_due": rounds_due})
	_recalculate_total_debt()

func process_end_of_round():
	if debt_list.is_empty(): return

	var debts_to_repay: Array[Dictionary] = []
	var remaining_debts: Array[Dictionary] = []

	for debt in debt_list:
		debt["rounds_due"] -= 1
		if debt["rounds_due"] <= 0:
			debts_to_repay.append(debt)
		else:
			remaining_debts.append(debt)
	
	debt_list = remaining_debts
	
	if not debts_to_repay.is_empty():
		var total_due = debts_to_repay.reduce(func(sum, d): return sum + d.amount, 0.0)
		
		# -- FIX: Replaced f-string with % formatting --
		Global.show_notification("债务到期！需偿还: %s 元" % total_due)
		if Global.spend_money(total_due):
			Global.show_notification("成功偿还到期债务。")
		else:
			Global.show_notification("资金不足，无法偿还债务！游戏结束。")
			Global.game_over_triggered.emit("无法偿还到期债务")
	
	_recalculate_total_debt()

func _recalculate_total_debt():
	var total = debt_list.reduce(func(sum, d): return sum + d.amount, 0.0)
	Global.update_debt(total)

func _load_config() -> Dictionary:
	var file = FileAccess.open("res://data/debt_config.json", FileAccess.READ)
	if file:
		return JSON.parse_string(file.get_as_text())
	return {}
