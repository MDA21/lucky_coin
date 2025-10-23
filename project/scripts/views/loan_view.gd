extends CanvasLayer

# --- 信号 ---
signal loan_view_closed # 告诉父节点（BankView）它已被关闭
signal loan_taken(amount: int) # 新增：贷款成功信号

@onready var option1 : Label = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/OptionalLabel1
@onready var option2 : Label = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/OptionalLabel2
@onready var option3 : Label = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/OptionalLabel3

@onready var loan_button_1: Button = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/Button1
@onready var loan_button_2: Button = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/Button2
@onready var loan_button_3: Button = $BackgroundPanel/MarginContainer/VBoxContainer/GridContainer/Button3

var bank_system = null
var shop_system = null
# 贷款金额配置（与label中显示的一致）
var loan_amounts: Array = [300, 600, 1200]
var loan_rounds: int = 6 # 6个小回合后偿还

func _ready():
	
	# 连接按钮信号 - 需要你确保按钮节点存在
	if loan_button_1:
		loan_button_1.pressed.connect(_on_loan_button_1_pressed)
	if loan_button_2:
		loan_button_2.pressed.connect(_on_loan_button_2_pressed)
	if loan_button_3:
		loan_button_3.pressed.connect(_on_loan_button_3_pressed)
		
func _on_loan_button_1_pressed():
	"""第一个贷款按钮点击处理"""
	_process_loan(0)

func _on_loan_button_2_pressed():
	"""第二个贷款按钮点击处理"""
	_process_loan(1)

func _on_loan_button_3_pressed():
	"""第三个贷款按钮点击处理"""
	_process_loan(2)

func _process_loan(option_index: int):
	"""处理贷款申请"""
	if option_index < 0 or option_index >= loan_amounts.size():
		push_error("Invalid loan option index: ", option_index)
		return
	
	bank_system = Global.get_bank_system()
	if not bank_system:
		push_error("Bank system not found!")
		return
		
	var amount = loan_amounts[option_index]
	
	# 检查是否是无息贷款（优质客户凭证效果）
	var is_interest_free = false
	shop_system = Global.get_shop_system()
	if shop_system and shop_system.has_item("premium_customer_certificate"):
		is_interest_free = true
	
	# 执行贷款
	if is_interest_free:
		bank_system.take_loan_with_all_effects(amount, loan_rounds)
	else:
		bank_system.take_loan(amount, loan_rounds)
	
	# 发出贷款成功信号
	loan_taken.emit(amount)
	
	# 关闭贷款视图
	loan_view_closed.emit()
	
	# 显示成功通知（通过全局通知系统）
	Global.show_notification("成功获得贷款: %d 元" % amount)

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
