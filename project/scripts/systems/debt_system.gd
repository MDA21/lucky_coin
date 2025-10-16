extends Node

var debt_config: Dictionary
var current_major_round: int = 1
var current_sub_round: int = 1
var debt_paid: int = 0
var debt_targets: Dictionary = {}
var round_history: Array = []

@onready var currency_system = Global.get_currency_system()
@onready var stress_system = Global.get_stress_system()

signal debt_round_changed(major_round: int, sub_round: int)
signal debt_target_updated(target_amount: int, paid_amount: int, remaining: int)
signal debt_paid_successful(amount: int, round_number: int)
signal debt_default(round_number: int, target_amount: int, paid_amount: int)
signal game_over(reason: String)

func _ready():
	load_debt_config()

func load_debt_config():
	var file = FileAccess.open("res://data/debt_config.json", FileAccess.READ)
	if file:
		debt_config = JSON.parse_string(file.get_as_text())
		debt_targets = debt_config.debt_targets
		file.close()

func start_new_game():
	current_major_round = 1
	current_sub_round = 1
	debt_paid = 0
	round_history.clear()
	debt_round_changed.emit(current_major_round, current_sub_round)
	update_debt_target_display()

func advance_round():
	current_sub_round += 1
	
	if current_sub_round > debt_config.round_structure.sub_rounds_per_major:
		current_sub_round = 1
		current_major_round += 1
		
		# 检查大回合结束条件
		if current_major_round > debt_config.round_structure.major_rounds:
			trigger_game_over("max_rounds")
			return false
	
	debt_round_changed.emit(current_major_round, current_sub_round)
	return true

func get_current_debt_target() -> int:
	return debt_targets.get(str(current_major_round), 0)

func can_afford_debt() -> bool:
	var total_money = currency_system.get_money_breakdown().total_money
	return total_money >= get_current_debt_target()

func pay_debt(amount: int = -1) -> bool:
	var target_amount = get_current_debt_target()
	
	if amount == -1:
		amount = target_amount
	
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

func check_round_balance(round_earned: int, round_spent: int):
	# 检查回合收益是否小于投入
	if round_earned < round_spent:
		stress_system.change_stress(debt_config.penalties.round_loss_stress_increase, "round_loss")
	else:
		stress_system.change_stress(-debt_config.penalties.round_profit_stress_decrease, "round_profit")

func check_debt_default():
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
