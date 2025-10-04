extends Node2D
class_name Channel

#通道状态枚举
enum ChannelState {
	LOCKED,         # 未解锁
	EMPTY,          # 已解锁但为空
	FILLED,         # 已灌注硬币
	OBSERVED,       # 已观察
	SETTLED         # 已结算
}

#通道属性
var channel_id: int = 0
var channel_state: ChannelState = ChannelState.LOCKED
var coins: Array[Coin] = []
var unlock_cost: float = 0.0
var is_observed: bool = false

#节点引用
@onready var coin_container: Node2D = $CoinContainer
@onready var unlock_button: Area2D = $UnlockButton
@onready var observe_button: Area2D = $ObserveButton

signal channel_unlocked(channel_id, cost)
signal channel_observed(channel_id)
signal coins_settled(channel_id, total_value)

func _ready():
	#连接按钮信号
	if unlock_button:
		unlock_button.connect("input_event", _on_unlock_button_input_event)
	if observe_button:
		observe_button.connect("input_event", _on_observe_button_input_event)
	
	update_visual_state()

#交互
func _on_unlock_button_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		unlock()

func _on_observe_button_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		observe()

#初始化通道
func setup(id: int, base_cost: float):
	channel_id = id
	unlock_cost = calculate_unlock_cost(base_cost, id)
	update_visual_state()

#计算解锁费用
func calculate_unlock_cost(base_cost: float, channel_index: int) -> float:
	#这里是瞎填的，等后续策划大大说了算
	return base_cost * pow(1.5, channel_index - 1)

#解锁通道
func unlock():
	if channel_state == ChannelState.LOCKED:
		channel_state = ChannelState.EMPTY
		update_visual_state()
		emit_signal("channel_unlocked", channel_id, unlock_cost)

#灌注硬币到通道
func fill_coins(coin_list: Array[Coin]):
	if channel_state == ChannelState.EMPTY:
		coins = coin_list
		channel_state = ChannelState.FILLED
		
		#将硬币添加到容器中
		for coin in coins:
			coin_container.add_child(coin)
			coin.play_enter_channel_animation()
		
		update_visual_state()

#观察通道（第一次拉杆后）
func observe():
	if channel_state == ChannelState.FILLED && !is_observed:
		is_observed = true
		channel_state = ChannelState.OBSERVED
		update_visual_state()
		emit_signal("channel_observed", channel_id)


#筛选硬币（选择倍率后）
func filter_coins(keep_count: int):
	if channel_state == ChannelState.OBSERVED:
		#随机保留一定数量的硬币
		var kept_coins: Array[Coin] = []
		var available_coins = coins.duplicate()
		
		for i in range(min(keep_count, available_coins.size())):
			var random_index = randi() % available_coins.size()
			kept_coins.append(available_coins[random_index])
			available_coins.remove_at(random_index)
		
		for coin in coins:
			if not coin in kept_coins:
				coin.queue_free()
		
		coins = kept_coins
		
		#重新排列保留的硬币
		arrange_coins()

#排列通道内的硬币，这里的间距和位置都是随便填的
func arrange_coins():
	var coin_count = coins.size()
	var spacing = 60  #硬币间距
	
	for i in range(coin_count):
		var coin = coins[i]
		var x_pos = (i - (coin_count - 1) / 2.0) * spacing
		var tween = create_tween()
		tween.tween_property(coin, "position", Vector2(x_pos, 0), 0.3)

#结算通道内的硬币
func settle_coins(multiplier: float = 1.0) -> float:
	if channel_state == ChannelState.OBSERVED:
		var total_value = 0.0
		
		#计算基础价值
		for coin in coins:
			total_value += coin.get_value()
		
		#应用组合奖励（特殊效果的硬币）
		total_value += calculate_pattern_bonus()
		
		#应用倍率
		total_value *= multiplier
		
		#播放结算动画
		for coin in coins:
			coin.play_settle_animation()
		
		channel_state = ChannelState.SETTLED
		coins.clear()
		update_visual_state()
		
		emit_signal("coins_settled", channel_id, total_value)
		return total_value
	
	return 0.0

#计算图案组合奖励（三叶草币特殊逻辑）
func calculate_pattern_bonus() -> float:
	var bonus = 0.0
	var clover_coins = []
	
	#收集所有三叶草币
	for coin in coins:
		if coin.get_coin_type() == Coin.CoinType.CLOVER:
			clover_coins.append(coin)
	
	if clover_coins.size() >= 3:
		#按图案等级分组
		var pattern_groups = {1: 0, 2: 0, 3: 0}
		for coin in clover_coins:
			var level = coin.get_pattern_level()
			pattern_groups[level] = pattern_groups.get(level, 0) + 1
		
		#计算组合奖励（这里使用策划文档中的算法示例）
		var base_value = 0.0
		for level in pattern_groups:
			var count = pattern_groups[level]
			if count >= 3:
				var sets = count / 3
				base_value += sets * level * 3  # 每组3个基础价值
		
		#应用连乘系数
		var total_sets = clover_coins.size() / 3
		if total_sets >= 2:
			bonus = base_value * pow(1.2, total_sets - 1)
		else:
			bonus = base_value
	
	return bonus

#获取通道状态
func get_state() -> ChannelState:
	return channel_state

#获取通道内的硬币数量
func get_coin_count() -> int:
	return coins.size()

#获取解锁费用
func get_unlock_cost() -> float:
	return unlock_cost

#更新通道的视觉状态
func update_visual_state():
	match channel_state:
		ChannelState.LOCKED:
			modulate = Color(0.5, 0.5, 0.5)  #灰色，表示锁定
			if unlock_button:
				unlock_button.visible = true
				observe_button.visible = false
		ChannelState.EMPTY:
			modulate = Color(1, 1, 1)  #正常颜色，白色
			if unlock_button:
				unlock_button.visible = false
				observe_button.visible = false
		ChannelState.FILLED:
			modulate = Color(1, 1, 1)
			if unlock_button:
				unlock_button.visible = false
				observe_button.visible = true
		ChannelState.OBSERVED:
			modulate = Color(0.01, 0.36, 0.313, 1.0)  #深绿色，表示已观察
			if unlock_button:
				unlock_button.visible = false
				observe_button.visible = false
		ChannelState.SETTLED:
			modulate = Color(0.231, 0.6, 0.906, 1.0)  #浅蓝色，表示已结算
			if unlock_button:
				unlock_button.visible = false
				observe_button.visible = false
