extends Control

# --- 节点引用 ---
@onready var remote_view: Control = $RemoteView
@onready var close_up_area: Area2D = $RemoteView/CloseUpArea # 远景中用于点击的 Area

@onready var closeup_view: Control = $CloseUpView
@onready var items_container: Control = $CloseUpView/ItemContainer
@onready var refresh_area: Area2D = $CloseUpView/RefreshPanel/RefreshArea
@onready var refresh_price_label: Label = $CloseUpView/RefreshPanel/RefreshPriceLabel

# --- 商品槽引用 ---
@onready var item_slots: Array = [
	$CloseUpView/ItemContainer/ItemSlot1,
	$CloseUpView/ItemContainer/ItemSlot2,
	$CloseUpView/ItemContainer/ItemSlot3,
	$CloseUpView/ItemContainer/ItemSlot4,
	$CloseUpView/ItemContainer/ItemSlot5
]

# --- 提示框节点 ---
@onready var tooltip_panel: Panel = $CloseUpView/TooltipPanel
@onready var tooltip_name: Label = $CloseUpView/TooltipPanel/ItemName
@onready var tooltip_description: Label = $CloseUpView/TooltipPanel/ItemDescription
@onready var tooltip_type: Label = $CloseUpView/TooltipPanel/ItemType
@onready var tooltip_price: Label = $CloseUpView/TooltipPanel/ItemPrice

var currency_system:Node = null
var refresh_cost = 20


# --- 状态 ---
var is_close_up: bool = false
var current_hovered_item: String = ""  # 当前悬停的物品ID
@onready var game_manager = get_node("/root/GameManager") # 保持对 GameManager 的引用
# 存储商品区域和商品ID的映射
var item_area_to_id_map = {}

# --- 初始化 ---

func _ready():

	# 1. 初始设置视图为远景
	_set_view(false)
	
	# 2. 连接远景点击区域的信号
	# 注意：这里的信号应在编辑器中连接或使用代码连接
	close_up_area.input_event.connect(_on_close_up_area_input_event)
	
# 【新增】：连接刷新区域的输入事件信号
	if is_instance_valid(refresh_area):
		refresh_area.input_event.connect(_on_refresh_area_input_event)
	else:
		push_error("RefreshArea 节点缺失，无法连接刷新信号！")
		
	# 3. 连接刷新区域的输入事件信号
	if is_instance_valid(refresh_area):
		refresh_area.input_event.connect(_on_refresh_area_input_event)
	else:
		push_error("RefreshArea 节点缺失，无法连接刷新信号！")
	
	# 4. 连接商店系统的信号
	if Global.shop_system:
		_connect_shop_signals()
		# 初始化显示商品
		_update_shop_items(GameManager.shop_system.get_current_items())
		# 初始化刷新价格
		_update_refresh_price(GameManager.shop_system.refresh_cost)
	else:
		# 如果商店系统还没准备好，延迟连接
		call_deferred("_deferred_connect_shop")
		
	tooltip_panel.visible = false
		
func _deferred_connect_shop():
	"""延迟连接商店信号"""
	if Global.shop_system:
		_connect_shop_signals()
		_update_shop_items(GameManager.shop_system.get_current_items())
		_update_refresh_price(GameManager.shop_system.refresh_cost)
	else:
		push_error("商店系统不可用！")

func _connect_shop_signals():
	"""连接商店系统的信号"""
	Global.shop_system.shop_items_updated.connect(_update_shop_items)
	Global.shop_system.refresh_cost_updated.connect(_update_refresh_price)
	Global.shop_system.item_purchased.connect(_on_item_purchased)


# --- 核心逻辑：视图切换 ---

func _set_view(to_close_up: bool):
	"""
	切换远景和近景的可见性。
	"""
	is_close_up = to_close_up
	
	remote_view.visible = not to_close_up
	closeup_view.visible = to_close_up

# --- 输入处理：ESC 返回远景 ---

func _input(event: InputEvent):
	"""
	处理 Esc 键按下事件，用于退出近景视图。
	"""
	if event.is_action_pressed("ui_cancel"): # ui_cancel 通常绑定 Esc 键
		if is_close_up:
			# 如果当前是近景，则切换回远景
			_set_view(false)
			get_viewport().set_input_as_handled()
			
# --- 信号处理：远景点击 ---

func _on_close_up_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理远景点击事件，切换到近景。
	"""
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	if not is_close_up:
		# 切换到近景
		_set_view(true)
		get_viewport().set_input_as_handled()
		
	if event.is_action_pressed("ui_cancel"): # ui_cancel 通常绑定 Esc 键
		if is_close_up:
			# 如果当前是近景，则切换回远景
			_set_view(false)
			get_viewport().set_input_as_handled()
		
func _on_refresh_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	"""
	处理 RefreshArea 的点击事件。
	"""
	# 仅处理鼠标左键按下事件（与你的 close_up_area 逻辑类似）
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
		
	# 确保在近景模式下才能点击刷新（可选的逻辑检查）
	if is_close_up:
		print("Refresh Area Clicked! Triggering shop refresh...")
		# 【DONE】：在这里调用 GameManager 或 ShopSystem 的刷新函数
		# 例如：game_manager.shop_system.refresh_items() 
	if Global.shop_system:
		Global.shop_system.refresh_shop()


		
		get_viewport().set_input_as_handled()
		
# --- 商店UI更新 ---

func _update_shop_items(items: Array):
	"""更新商店商品显示"""
	print("更新商店商品，数量: ", items.size())
	
	for i in range(item_slots.size()):
		var slot = item_slots[i]
		
		if i < items.size():
			# 有商品，显示商品信息
			var item_data = items[i]
			_show_item_in_slot(slot, item_data)
		else:
			# 没有商品，隐藏槽位
			_hide_slot(slot)

func _show_item_in_slot(slot: Node, item_data: Dictionary):
	"""在指定槽位显示商品"""
	# 显示槽位
	slot.visible = true
	
	# 获取槽位中的子节点
	var item_sprite = slot.get_node_or_null("ItemSprite")
	var price_label = slot.get_node_or_null("PriceLabel")
	var item_area = slot.get_node_or_null("ItemArea")
	
	if item_sprite:
		# 加载商品纹理
		var texture = load(item_data.get("texture", ""))
		if texture:
			item_sprite.texture = texture
		else:
			print("无法加载纹理: ", item_data.get("texture", ""))
	
	if price_label:
		price_label.text = "$%d" % item_data.get("price", 0)
	
	if item_area:
		 # 确保Area2D能够检测鼠标
		item_area.monitoring = true
		item_area.input_pickable = true
		 # 清除旧的连接
		if item_area.is_connected("input_event", _on_item_area_input_event.bind(item_data["id"])):
			item_area.disconnect("input_event", _on_item_area_input_event.bind(item_data["id"]))
		if item_area.is_connected("mouse_entered", _on_item_area_mouse_entered.bind(item_data["id"])):
			item_area.disconnect("mouse_entered", _on_item_area_mouse_entered.bind(item_data["id"]))
		if item_area.is_connected("mouse_exited", _on_item_area_mouse_exited):
			item_area.disconnect("mouse_exited", _on_item_area_mouse_exited)

		# 连接新的点击事件，传递商品ID
		item_area.connect("input_event", _on_item_area_input_event.bind(item_data["id"]))
		# 连接鼠标悬停事件
		item_area.connect("mouse_entered", _on_item_area_mouse_entered.bind(item_data["id"]))
		item_area.connect("mouse_exited", _on_item_area_mouse_exited)
		print("已连接商品区域信号: ", item_data["id"])

func _hide_slot(slot: Node):
	"""隐藏指定槽位"""
	slot.visible = false

func _on_item_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, item_id: String):
	"""处理商品点击事件（购买）"""
	# 仅处理鼠标左键按下事件
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	
	print("尝试购买商品: ", item_id)
	if Global.shop_system:
		Global.shop_system.purchase_item(item_id)
	else:
		push_error("商店系统不可用，无法购买商品！")

func _update_refresh_price(cost: float):
	"""更新刷新价格显示"""
	if refresh_price_label:
		refresh_price_label.text = "刷新: $%d" % int(cost)

func _on_item_purchased(item_id: String, success: bool):
	"""处理商品购买结果"""
	if success:
		Global.show_notification("购买成功: " + item_id)
		print("购买成功: ", item_id)
	else:
		Global.show_notification("资金不足！")
		print("购买失败: ", item_id)
		
func _on_item_area_mouse_entered():
	"""鼠标进入商品区域，显示提示"""
	var item_area = get_current_mouse_area()
	if item_area and item_area_to_id_map.has(item_area):
		var item_id = item_area_to_id_map[item_area]
		print("鼠标进入商品区域: ", item_id)
		current_hovered_item = item_id
		_show_tooltip(item_id)

func _on_item_area_mouse_exited():
	"""鼠标离开商品区域，隐藏提示"""
	print("鼠标离开商品区域")
	current_hovered_item = ""
	_hide_tooltip()
	
func get_current_mouse_area() -> Area2D:
	"""获取当前鼠标所在的Area2D"""
	var mouse_pos = get_global_mouse_position()
	
	for item_area in item_area_to_id_map.keys():
		if is_instance_valid(item_area) and item_area.get_global_rect().has_point(mouse_pos):
			return item_area
			
	return null

func _show_tooltip(item_id: String):
	"""显示物品提示信息"""
	print("尝试显示提示框: ", item_id)
	var item_data = Global.shop_system.get_item_data(item_id)
	if not item_data:
		return
	
	# 更新提示框内容
	tooltip_name.text = item_data.get("name", "未知物品")
	tooltip_description.text = item_data.get("description", "暂无描述")
	tooltip_price.text = "价格: $%d" % item_data.get("price", 0)
	
	# 显示效果信息
	var effect_type = item_data.get("effect_type", "unknown")
	var effect = item_data.get("effect", "")
	var effect_value = item_data.get("effect_value", {})
	
	var effect_text = "效果类型: " + effect_type + "\n"
	effect_text += "效果: " + effect
	
	# 如果有具体效果值，显示出来
	if effect_value:
		if effect_value is Dictionary and effect_value.size() > 0:
			effect_text += "\n效果值: "
			for key in effect_value:
				effect_text += "\n  %s: %s" % [key, str(effect_value[key])]
		else:
			effect_text += "\n效果值: " + str(effect_value)
	
	tooltip_type.text = effect_text
	
	# 显示提示框
	tooltip_panel.visible = true
	
	# 确保提示框不会超出屏幕
	var viewport_size = get_viewport().get_visible_rect().size
	if tooltip_panel.position.x + tooltip_panel.size.x > viewport_size.x:
		tooltip_panel.position.x = viewport_size.x - tooltip_panel.size.x - 10
	if tooltip_panel.position.y + tooltip_panel.size.y > viewport_size.y:
		tooltip_panel.position.y = viewport_size.y - tooltip_panel.size.y - 10

func _hide_tooltip():
	"""隐藏物品提示"""
	tooltip_panel.visible = false
	
