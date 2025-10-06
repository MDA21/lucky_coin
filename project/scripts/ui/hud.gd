extends CanvasLayer

# 引用你场景中的 ProgressBar 节点
@onready var resource_bar: ProgressBar = $CoinPusherBar

# --- 公共函数：供外部脚本调用 ---
func update_coin_progress(current_amount: float, required_amount: float):
	# 避免除以零或显示负值
	if required_amount <= 0:
		resource_bar.value = resource_bar.max_value
		return

	# 设置进度条的最大值（即所需金币数）
	resource_bar.max_value = required_amount
	
	# 设置当前值（即持有金币数）
	resource_bar.value = current_amount
	
	# 可选：你可以限制进度条不超过最大值
	resource_bar.value = min(resource_bar.value, resource_bar.max_value)
	
	# 如果你添加了 Label 来显示数值，在这里更新它：
	# $YourLabelNode.text = str(current_amount) + " / " + str(required_amount)
