extends Node

var high_stress_threshold: float
var max_stress: float
var burst_penalty_range: Vector2

var is_in_high_stress_state = false

signal high_stress_entered
signal high_stress_exited
signal stress_burst

func _ready():
	Global.stress_system = self
	
	var config = _load_config()
	if config:
		high_stress_threshold = config.stress_system.high_stress_threshold
		max_stress = config.stress_system.max_stress
		burst_penalty_range = Vector2(config.stress_system.burst_penalty_min, config.stress_system.burst_penalty_max)

func add_stress(amount: float):
	var new_stress = clampf(Global.current_stress + amount, 0, max_stress)
	Global.update_stress(new_stress)
	
	if new_stress >= high_stress_threshold and not is_in_high_stress_state:
		is_in_high_stress_state = true
		high_stress_entered.emit()

	if new_stress >= max_stress:
		stress_burst.emit()
		_punish_for_burst()

func reduce_stress(amount: float):
	var new_stress = clampf(Global.current_stress - amount, 0, max_stress)
	Global.update_stress(new_stress)
	
	if new_stress < high_stress_threshold and is_in_high_stress_state:
		is_in_high_stress_state = false
		high_stress_exited.emit()

func _punish_for_burst():
	var penalty = round(randf_range(burst_penalty_range.x, burst_penalty_range.y))
	Global.spend_money(penalty)
	Global.update_stress(0)
	is_in_high_stress_state = false
	Global.show_notification("暴怒！你损失了 %s 元作为赔偿！" % penalty)

func _load_config() -> Dictionary:
	var file = FileAccess.open("res://data/game_config.json", FileAccess.READ)
	if file:
		return JSON.parse_string(file.get_as_text())
	return {}
