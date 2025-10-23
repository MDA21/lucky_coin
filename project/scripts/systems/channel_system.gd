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

# 检查并应用道具效果
func check_item_effects():
	var shop_system = Global.get_shop_system()
	if not shop_system:
		return
	
	# 开锁器效果 - 免费解锁通道
	if shop_system.has_item("lockpick"):
		# 这个效果在解锁时检查
		pass
	
	# 和推币机成为朋友 - 减少通道解锁费用
	if shop_system.has_item("friends_with_slot_machine"):
		# 这个效果在计算费用时应用
		pass

# 应用道具效果的解锁费用计算
func get_unlock_cost_with_effects(channel_count: int) -> int:
	var base_cost = get_unlock_cost(channel_count)
	
	# 检查和推币机成为朋友效果
	var shop_system = Global.get_shop_system()
	if shop_system and shop_system.has_item("friends_with_slot_machine"):
		base_cost = int(base_cost * 0.65)  # 减少35%的费用
	
	return base_cost

# 删除重复的通道解锁方法，已合并到上面的统一方法中

# 检查是否可以免费解锁
func can_free_unlock() -> bool:
	var shop_system = Global.get_shop_system()
	return shop_system and shop_system.has_item("lockpick")

# 事件效果：通道系统扩展功能
var unlock_cost_multiplier: float = 1.0

func set_unlock_cost_multiplier(multiplier: float):
	"""设置解锁费用倍率（事件效果）"""
	unlock_cost_multiplier = multiplier

# 应用事件效果的解锁费用计算
func get_unlock_cost_with_event_effects(channel_count: int) -> int:
	var base_cost = get_unlock_cost(channel_count)
	return int(base_cost * unlock_cost_multiplier)

# 统一通道解锁方法（合并道具和事件效果）
func unlock_channel_with_all_effects(channel_id: String, current_channel_count: int, use_free_unlock: bool = false) -> int:
	# 检查开锁器效果
	var shop_system = Global.get_shop_system()
	if shop_system and shop_system.has_item("lockpick") and use_free_unlock:
		# 免费解锁
		if not unlocked_channels.has(channel_id):
			unlocked_channels.append(channel_id)
		coin_system.fill_channel_from_mountain(channel_id)
		return 0
	
	# 使用事件调整后的费用
	var cost = get_unlock_cost_with_event_effects(current_channel_count)
	
	# 应用道具效果（如果事件效果未应用）
	if unlock_cost_multiplier == 1.0:
		if shop_system and shop_system.has_item("friends_with_slot_machine"):
			cost = int(cost * 0.65)  # 减少35%的费用
	
	if not unlocked_channels.has(channel_id):
		unlocked_channels.append(channel_id)
	coin_system.fill_channel_from_mountain(channel_id)
	
	return cost
