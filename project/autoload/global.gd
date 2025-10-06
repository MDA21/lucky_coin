extends Node

#预加载通知场景
var notification_scene = preload("res://project/scenes/ui/NotificationPopup.tscn")

#全局玩家数据
var current_money: float = 0.0
var casino_currency: int = 0
var current_stress: float = 0.0
var current_debt: float = 0.0

#全局信号中心
signal money_changed(new_amount)
signal stress_changed(new_amount)
signal debt_changed(new_amount)
signal game_over_triggered(reason)

#系统引用
var game_manager = null
var coin_system = null
var debt_system = null
var stress_system = null
var currency_system = null
var shop_system = null
var bank_system = null
var event_system = null

# --- 公共方法 ---

func show_notification(message: String):
	"""全局通知方法"""
	var notification = notification_scene.instantiate()
	get_tree().root.add_child(notification)
	notification.show_message(message)

# --- 数据更新方法 ---

func add_money(amount: float):
	current_money += amount
	money_changed.emit(current_money)

func spend_money(amount: float) -> bool:
	if current_money >= amount:
		current_money -= amount
		money_changed.emit(current_money)
		return true
	return false

func update_stress(new_stress: float):
	#压力值将在stress_system中被clamp
	current_stress = new_stress
	stress_changed.emit(current_stress)

func update_debt(new_debt: float):
	current_debt = new_debt
	debt_changed.emit(current_debt)
