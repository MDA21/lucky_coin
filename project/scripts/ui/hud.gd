extends CanvasLayer

# 添加新的引用
@onready var debt_label: Label = $StatDisplayRoot/DebtGroup/DebtLabel
@onready var loan_label: Label = $StatDisplayRoot/LoanGroup/LoanLabel
@onready var gold_label: Label = $StatDisplayRoot/GoldGroup/GoldLabel
@onready var stress_label: Label = $StatDisplayRoot/StressGroup/StressLabel
@onready var pause_gear_button: TextureButton = $PauseGearButton

var bank_system = null
var currency_system = null
var stress_system = null
var debt_system = null

# 点击齿轮时触发
signal pause_menu_requested

func _ready():
	"""
	连接按钮的信号，用于触发菜单界面
	"""
	pause_gear_button.pressed.connect(_on_pause_gear_button_pressed)
	# 连接系统引用
	bank_system = Global.get_bank_system()
	currency_system = Global.get_currency_system()
	stress_system = Global.get_stress_system()
	debt_system = Global.get_debt_system()
	
	# 连接信号
	if bank_system:
		bank_system.loan_added.connect(_on_loan_added)
	if currency_system:
		currency_system.money_changed.connect(_on_money_changed)
	if stress_system:
		stress_system.stress_changed.connect(_on_stress_changed)

# 更新数值状态
func update_stats():
	"""
	更新 HUD 上所有统计数据的显示。
	现在从各个系统直接获取数据，而不是通过参数传递。
	"""
	# 1. 更新债务（游戏目标债务）- 只由债务系统决定
	var required_gold = 0
	if debt_system:
		required_gold = debt_system.get_current_debt_target()
	debt_label.text = str(required_gold)
	
	# 2. 更新贷款（从银行系统获取总贷款金额）
	var total_loans = 0
	if bank_system and bank_system.has_method("get_total_loan_amount"):
		total_loans = bank_system.get_total_loan_amount()
	loan_label.text = str(total_loans)
	
	# 3. 格式化和更新金币数 (合并显示)
	# 格式为: 普通货币 + 贷款货币 (例如: 1000 + 500)
	var normal_money = 0
	var loan_money = 0
	if currency_system:
		var breakdown = currency_system.get_money_breakdown()
		normal_money = breakdown.normal_money
		loan_money = breakdown.loan_money
	
	var combined_gold_text = str(normal_money) + " + " + str(loan_money)
	gold_label.text = combined_gold_text
	
	# 4. 更新压力值
	var current_stress = 0
	if stress_system:
		current_stress = stress_system.current_stress
	stress_label.text = str(current_stress) + "%"

func _on_pause_gear_button_pressed():
	""" 
	当齿轮按钮被点击时调用。
	发出信号，请求 GameManager 加载并显示暂停菜单。
	"""
	pause_menu_requested.emit()

func _on_loan_added(loan_data: Dictionary):
	"""当新增贷款时更新显示"""
	# 可以在这里添加贷款的特殊显示效果
	print("新增贷款: ", loan_data.amount, " 压力增加: ", loan_data.stress_value)
	# 强制更新HUD显示
	update_stats()

func _on_money_changed(normal_money: int, loan_money: int, total_money: int):
	"""当货币变化时更新显示"""
	# 只更新货币相关的显示部分
	var combined_gold_text = str(normal_money) + " + " + str(loan_money)
	gold_label.text = combined_gold_text

func _on_stress_changed(new_stress: int, old_stress: int, change: int):
	"""当压力变化时更新显示"""
	stress_label.text = str(new_stress) + "%"
	# 检查是否触发游戏结束
	if new_stress >= stress_system.max_stress:
		# 压力爆表，游戏结束
		Global.trigger_game_over("压力爆表")
