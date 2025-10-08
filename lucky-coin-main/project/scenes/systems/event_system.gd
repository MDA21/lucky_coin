extends Node

var events: Array[Dictionary] = []

signal event_triggered(event: Dictionary)

func _ready():
	Global.event_system = self
	events = _load_events()

func trigger_random_events(num: int = 1):
	if events.is_empty():
		print("警告: 没有可用的事件！")
		return
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()  # 初始化种子，确保每次不同
	
	for i in range(num):
		var random_index = rng.randi_range(0, events.size() - 1)
		var selected_event = events[random_index]
		
		_apply_event_effect(selected_event)
		
		event_triggered.emit(selected_event)
		
		Global.show_notification("%s: %s" % [selected_event.name, selected_event.description])
	
	print("触发了 %d 个随机事件。" % num)

func _apply_event_effect(event: Dictionary):
	if not event.has("effect"):
		return
	
	var effect = event.effect
	var action = effect.action
	var value = effect.value
	
	match action:
		"add_money":
			Global.current_money += value
		"reduce_money":
			Global.current_money -= value
			if Global.current_money < 0:
				Global.current_money = 0 
		"add_stress":
			Global.current_stress += value 
		"reduce_stress":
			Global.current_stress -= value
			if Global.current_stress < 0:
				Global.current_stress = 0
		"add_debt":
			Global.debt_system.add_debt(value)
		_:
			print("未知事件效果: %s" % action)

func _load_events() -> Array[Dictionary]:
	var file = FileAccess.open("res://project/data/events.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_text)
		if parsed is Array:
			return parsed
		else:
			print("错误: events.json 不是有效的数组！")
	else:
		print("错误: 无法打开 events.json！")
	return []
