extends Node2D

@onready var channel_system = $"/root/GameManager".get_system("channel_system")
@onready var coin_system = $"/root/GameManager".get_system("coin_system")
@onready var currency_system = $"/root/GameManager".get_system("currency_system")
@onready var pattern_system = $"/root/GameManager".get_system("pattern_system")
@onready var combo_calculator = $"/root/GameManager".get_system("combo_calculator")
@onready var stress_system = $"/root/GameManager".get_system("stress_system")
@onready var pattern_grid = $PatternGrid
@onready var distribution_display = $ChannelDistributionDisplay

var current_channel_count: int = 0
var current_active_channel: String = ""

func _ready():
	setup_channel_ui()

func setup_channel_ui():
	update_channel_costs_display()

func update_channel_costs_display():
	var cost = channel_system.get_unlock_cost(current_channel_count)
	# 更新UI显示
	# $ChannelUnlockButton/CostLabel.text = str(cost) + " $"

func _on_channel_unlock_pressed():
	var cost = channel_system.get_unlock_cost(current_channel_count)
	
	if currency_system.can_afford(cost):
		var channel_id = "channel_%s_%d" % [str(Time.get_unix_time_from_system()), current_channel_count]
		var actual_cost = channel_system.unlock_channel(channel_id, current_channel_count)
		currency_system.spend_money(actual_cost, "normal")
		current_channel_count += 1
		update_channel_costs_display()
		
		# 切换到新通道并显示分布
		switch_to_channel(channel_id)
	else:
		show_insufficient_funds_message()
		
func show_insufficient_funds_message():
	Global.show_notification("金钱不足！")

func switch_to_channel(channel_id: String):
	current_active_channel = channel_id
	pattern_grid.fill_grid_from_channel(channel_id)
	distribution_display.setup(channel_id)

func _on_lever_pulled():
	if current_active_channel == "":
		return
	
	# 为当前活动通道生成硬币网格（使用条件概率）
	pattern_grid.fill_grid_from_channel(current_active_channel)
	var coin_grid = pattern_grid.get_coin_grid()
	
	# 计算该通道的结果
	var channel_result = combo_calculator.calculate_channel_results(coin_grid)
	
	# 显示结果
	show_pattern_results({
		"total_money": channel_result.total_money,
		"total_stress_change": channel_result.total_stress_change,
		"patterns_found": channel_result.patterns_found,
		"pattern_count": channel_result.pattern_count,
		"channel_id": current_active_channel
	})
	
	# 应用金钱和压力变化
	currency_system.add_money(channel_result.total_money, "normal")
	stress_system.change_stress(channel_result.total_stress_change)



func show_pattern_results(result_data: Dictionary):
	# 显示图案结算界面
	var result_view = preload("res://project/scenes/ui/pattern_result_view.tscn").instantiate()
	add_child(result_view)
	result_view.show_results(result_data)
	
	# 应用金钱和压力变化
	currency_system.add_money(result_data.total_money, "normal")
	stress_system.change_stress(result_data.total_stress_change)
