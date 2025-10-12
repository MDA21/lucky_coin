extends Node

var unlocked_channels: Array = []
var current_round: int = 1
var channel_costs: Dictionary
@onready var coin_system = $"/root/GameManager".get_system("coin_system")


func _ready():
	load_channel_costs()

func load_channel_costs():
	var file = FileAccess.open("res://project/data/channel_costs.json", FileAccess.READ)
	if file:
		var config = JSON.parse_string(file.get_as_text())
		channel_costs = config.round_costs
		file.close()

func get_unlock_cost(channel_count: int) -> int:
	var round_config = channel_costs.get(str(current_round), {})
	if round_config.is_empty():
		return 0
	
	var base_cost = round_config.initial_cost
	var increment = round_config.cost_increment
	
	return base_cost + (channel_count * increment)

func can_unlock_channel(money_available: int, current_channel_count: int) -> bool:
	return money_available >= get_unlock_cost(current_channel_count)

func unlock_channel(channel_id: String, current_channel_count: int) -> int:
	var cost = get_unlock_cost(current_channel_count)
	
	if not unlocked_channels.has(channel_id):
		unlocked_channels.append(channel_id)
	coin_system.fill_channel_from_mountain(channel_id)
	
	return cost
	
# 获取通道的硬币分布信息（用于金属探测器等道具）
func get_channel_distribution_info(channel_id: String) -> Dictionary:
	if unlocked_channels.has(channel_id):
		return coin_system.get_channel_distribution_info(channel_id)
	return {}

func abandon_channel(channel_id: String):
	if unlocked_channels.has(channel_id):
		unlocked_channels.erase(channel_id)

func get_unlocked_channels() -> Array:
	return unlocked_channels.duplicate()

func set_current_round(round_number: int):
	current_round = round_number
	#新回合清空已解锁通道
	unlocked_channels.clear()

func get_current_round_channels() -> Dictionary:
	return channel_costs.get(str(current_round), {})
