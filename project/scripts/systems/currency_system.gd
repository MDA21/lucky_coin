extends Node

func _ready():
	Global.currency_system = self
	# var game_manager = get_node("/root/game_manager")
	#处理依赖关系 确定了再写

func convert_to_casino(): # 货币转换系统，暂时定为常规货币二比一转换
	if Global.current_money >= 2:
		# 计算可转换的数量（确保是2的倍数）
		var convertible = int(Global.current_money / 2) * 2
		var converted_amount = convertible / 2
		
		# 执行转换
		Global.current_money -= convertible
		Global.casino_currency += converted_amount
		
		# 发出信号通知变化
		regular_currency_changed.emit(Global.current_money)
		casino_currency_changed.emit(Global.casino_currency)
		
		return true  # 转换成功
	return false  # 转换失败（常规货币不足）

# 回合结束时自动转换
func _on_round_ended():
	# 自动将常规货币按2:1比例转换为赌场货币
	convert_to_casino()
