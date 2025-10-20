extends CanvasLayer

# 添加新的引用
@onready var debt_label: Label = $StatDisplayRoot/DebtGroup/DebtLabel
@onready var loan_label: Label = $StatDisplayRoot/LoanGroup/LoanLabel
@onready var gold_label: Label = $StatDisplayRoot/GoldGroup/GoldLabel
@onready var stress_label: Label = $StatDisplayRoot/StressGroup/StressLabel
@onready var pause_gear_button: TextureButton = $PauseGearButton

# 点击齿轮时触发
signal pause_menu_requested

func _ready():
	"""
	连接按钮的信号，用于触发菜单界面
	"""
	pause_gear_button.pressed.connect(_on_pause_gear_button_pressed)

# 更新数值状态
func update_stats(required_gold: int, current_loan: int, current_money: int, casino_currency: int, current_stress: int):
	"""
	更新 HUD 上所有统计数据的显示。
	money_amount 和 casino_money_amount 将在 gold_label 中合并显示。
	"""
	
	# 1. 更新债务
	debt_label.text = str(required_gold)
	
	# 2. 更新贷款
	loan_label.text = str(current_loan)
	
	# 3. 格式化和更新金币数 (合并显示)
	# 格式为: 货币 + 赌场货币 (例如: 1000 + 500)
	var combined_gold_text = str(current_money) + " + " + str(casino_currency)
	gold_label.text = combined_gold_text
	
	# 4. 更新压力值
	stress_label.text = str(current_stress) + "%"

func _on_pause_gear_button_pressed():
	""" 
	当齿轮按钮被点击时调用。
	发出信号，请求 GameManager 加载并显示暂停菜单。
	"""
	pause_menu_requested.emit()
