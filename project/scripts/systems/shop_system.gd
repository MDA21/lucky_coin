extends Node

var shop_items: Dictionary = {}
var player_inventory: Dictionary = {}

signal inventory_updated(new_inventory)

func _ready():
	Global.shop_system = self
	shop_items = _load_shop_items()

func purchase_item(item_id: String):
	if not shop_items.has(item_id): return
	
	var item = shop_items[item_id]
	if Global.spend_money(item.price):
		_add_item_to_inventory(item_id)
		Global.show_notification("成功购买: %s" % item.name)
	else:
		Global.show_notification("金钱不足！")

func use_item(item_id: String):
	if not player_inventory.has(item_id) or player_inventory[item_id] <= 0: return

	var item = shop_items[item_id]
	if item.type == "consumable":
		var effect = item.effect
		if effect.action == "reduce_stress":
			Global.stress_system.reduce_stress(effect.value)
			Global.show_notification("使用了 %s，压力降低了！" % item.name)
		
		player_inventory[item_id] -= 1
		if player_inventory[item_id] <= 0:
			player_inventory.erase(item_id)
		inventory_updated.emit(player_inventory)

func _add_item_to_inventory(item_id: String):
	player_inventory[item_id] = player_inventory.get(item_id, 0) + 1
	inventory_updated.emit(player_inventory)

func _load_shop_items() -> Dictionary:
	var file = FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file:
		return JSON.parse_string(file.get_as_text())
	return {}
