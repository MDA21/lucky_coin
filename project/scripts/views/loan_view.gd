extends CanvasLayer

# --- 信号 ---
signal loan_view_closed # 告诉父节点（BankView）它已被关闭

# ... (@onready 变量和 _ready() 函数保持不变) ...

func _unhandled_input(event: InputEvent):
	"""
	使用 _unhandled_input 监听全局输入，处理 ESC 和 AD 键。
	"""
	
	# 1. ESC 退出弹窗 (持久性退出)
	if event.is_action_pressed("ui_cancel"): # ui_cancel 通常绑定 Esc 键
		# 发出关闭信号
		loan_view_closed.emit()
		# 消耗输入，防止输入事件继续传播给 BankView 或其他场景
		get_viewport().set_input_as_handled()
		return 
		
	# 2. AD 键退出弹窗 (防止场景切换残留)
	# 假设 A 键映射为 ui_left，D 键映射为 ui_right 动作
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		
		# 发出关闭信号，销毁弹窗
		loan_view_closed.emit() 
		
		# **关键：这里不能调用 get_viewport().set_input_as_handled()**
		# 否则，GameManager 将收不到 AD 键信号，导致场景无法切换。
		# 弹窗会被销毁，但 AD 键信号会继续传递给 GameManager，触发场景切换。
