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

var currency_system:Node = null
var refresh_cost = 6


# --- 状态 ---
var is_close_up: bool = false
var current_hovered_item: String = ""  # 当前悬停的物品ID
@onready var game_manager = get_node("/root/GameManager") # 保持对 GameManager 的引用
# 存储商品区域和商品ID的映射
var item_area_to_id_map = {}

# --- 动态创建的 Tooltip 组件 ---
var tooltip_name: Label
var tooltip_price: Label
var tooltip_type: Label
var tooltip_description: Label

# --- 初始化 ---

func _ready():

	# 1. 初始设置视图为远景
	_set_view(false)
	
	# 2. 连接远景点击区域的信号
	# 注意：这里的信号应在编辑器中连接或使用代码连接
	close_up_area.input_event.connect(_on_close_up_area_input_event)
	
# 连接刷新区域的输入事件信号
	if is_instance_valid(refresh_area):
		refresh_area.input_event.connect(_on_refresh_area_input_event)
	else:
		push_error("RefreshArea 节点缺失，无法连接刷新信号！")
		
	# 3. 连接刷新区域的输入事件信号
	if is_instance_valid(refresh_area):
		refresh_area.input_event.connect(_on_refresh_area_input_event)
	else:
		push_error("RefreshArea 节点缺失，无法连接刷新信号！")
	
	# 4. 创建自适应 TooltipPanel
	_create_adaptive_tooltip()
	
	# 5. 连接商店系统的信号
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
	item_area_to_id_map.clear()
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
		
	if item_sprite:
		# 确保精灵不会拦截鼠标事件
		if item_sprite is Control:  # 如果是 TextureRect 等 Control 节点
			item_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif item_sprite is Node2D:  # 如果是 Sprite2D 等 Node2D 节点
			item_sprite.z_index = -1  # 降低层级，确保在碰撞区域下方
	
	if item_area:
		 # 确保Area2D能够检测鼠标
		item_area.monitoring = true
		item_area.input_pickable = true
		
		 #清除旧的连接
		if item_area.is_connected("input_event", Callable(self, "_on_item_area_input_event")):
			item_area.disconnect("input_event", Callable(self, "_on_item_area_input_event"))
		if item_area.is_connected("mouse_entered", Callable(self, "_on_item_area_mouse_entered")):
			item_area.disconnect("mouse_entered", Callable(self, "_on_item_area_mouse_entered"))
		if item_area.is_connected("mouse_exited", Callable(self, "_on_item_area_mouse_exited")):
			item_area.disconnect("mouse_exited", Callable(self, "_on_item_area_mouse_exited"))

		# 连接新的点击事件，传递商品ID
		item_area.connect("input_event", Callable(self, "_on_item_area_input_event").bind(item_data["id"]))
		# 连接鼠标悬停事件
		item_area.connect("mouse_entered", Callable(self, "_on_item_area_mouse_entered").bind(item_data["id"]))
		item_area.connect("mouse_exited", Callable(self, "_on_item_area_mouse_exited"))
		
		# 添加到映射表
		item_area_to_id_map[item_area] = item_data["id"]
		
		print("已连接商品区域信号: ", item_data["id"])

func _hide_slot(slot: Node):
	"""隐藏指定槽位"""
	var item_area = slot.get_node_or_null("ItemArea")
	if item_area and item_area_to_id_map.has(item_area):
		# 从映射表中移除
		item_area_to_id_map.erase(item_area)
	
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
		var item_data = Global.shop_system.get_item_data(item_id)
		var item_name = item_data.get("name", item_id)
		Global.show_notification("购买成功: " + item_name)
		print("购买成功: ", item_id)
		
		# 立即更新UI显示空槽位
		_update_shop_items(Global.shop_system.get_current_items())
	else:
		Global.show_notification("资金不足！")
		print("购买失败: ", item_id)
		
	# 【新增】强制更新HUD显示
	if Global.currency_system:
		var breakdown = Global.currency_system.get_money_breakdown()
		Global.money_changed.emit(breakdown.normal_money, breakdown.loan_money, breakdown.total_money)
		
func _on_item_area_mouse_entered(item_id: String):
	"""鼠标进入商品区域，显示提示"""
	print("鼠标进入商品区域: ", item_id)
	current_hovered_item = item_id
	_show_tooltip(item_id)

func _on_item_area_mouse_exited():
	"""鼠标离开商品区域，隐藏提示"""
	print("鼠标离开商品区域")
	current_hovered_item = ""
	_hide_tooltip()
	

func _show_tooltip(item_id: String):
	"""显示物品提示信息"""
	print("尝试显示提示框: ", item_id)
	
	if not Global.shop_system:
		return
		
	var item_data = Global.shop_system.get_item_data(item_id)
	if not item_data:
		return
	
	# 直接从 JSON 数据读取并显示到对应标签
	tooltip_name.text = item_data.get("name", "未知物品")
	tooltip_price.text = "$%d" % item_data.get("price", 0)
	
	# 翻译效果类型为中文
	var effect_type = item_data.get("effect_type", "unknown")
	var type_chinese = _translate_effect_type(effect_type)
	tooltip_type.text = type_chinese
	
	# 显示描述
	tooltip_description.text = item_data.get("description", "暂无描述")
	
	# 显示提示框
	tooltip_panel.visible = true
	
	# 等待一帧让布局计算完成
	await get_tree().process_frame
	
	# 定位提示框到鼠标位置
	var mouse_pos = get_global_mouse_position()
	tooltip_panel.position = mouse_pos + Vector2(20, 20)
	
	# 确保提示框不会超出屏幕
	_adjust_tooltip_position()

func _translate_effect_type(effect_type: String) -> String:
	"""将效果类型翻译为中文"""
	match effect_type:
		"permanent":
			return "永久"
		"consumable":
			return "消耗品"
		"rechargeable":
			return "充能道具"
		"round_limited":
			return "回合限时"
		"limited_use":
			return "限次使用"
		_:
			return "未知类型"

func _adjust_tooltip_position():
	"""调整提示框位置确保不会超出屏幕"""
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = tooltip_panel.size
	
	# 计算理想位置
	var target_pos = tooltip_panel.position
	
	# 检查右边界
	if target_pos.x + tooltip_size.x > viewport_size.x:
		target_pos.x = max(10, viewport_size.x - tooltip_size.x - 10)
	
	# 检查下边界
	if target_pos.y + tooltip_size.y > viewport_size.y:
		target_pos.y = max(10, viewport_size.y - tooltip_size.y - 10)
	
	# 检查左边界
	if target_pos.x < 10:
		target_pos.x = 10
	
	# 检查上边界
	if target_pos.y < 10:
		target_pos.y = 10
	
	tooltip_panel.position = target_pos

func _hide_tooltip():
	"""隐藏物品提示"""
	tooltip_panel.visible = false

func _create_adaptive_tooltip():
	# 如果已经存在 TooltipPanel，先移除
	if tooltip_panel and tooltip_panel.get_parent():
		tooltip_panel.get_parent().remove_child(tooltip_panel)
	
	# 创建新的自适应 TooltipPanel
	tooltip_panel = Panel.new()
	tooltip_panel.name = "TooltipPanel"
	
	# 设置面板样式
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	stylebox.border_color = Color(0.8, 0.6, 0.2)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.shadow_size = 6
	stylebox.shadow_color = Color(0, 0, 0, 0.7)
	tooltip_panel.add_theme_stylebox_override("panel", stylebox)
	
	# 设置最小尺寸
	tooltip_panel.custom_minimum_size = Vector2(350, 200)
	
	# 创建 MarginContainer
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	margin_container.add_theme_constant_override("margin_left", 16)
	margin_container.add_theme_constant_override("margin_top", 16)
	margin_container.add_theme_constant_override("margin_right", 16)
	margin_container.add_theme_constant_override("margin_bottom", 16)
	tooltip_panel.add_child(margin_container)
	
	# 创建主 VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	margin_container.add_child(vbox)
	
	# 创建标题行 (名称 + 价格)
	var header_hbox = HBoxContainer.new()
	header_hbox.name = "HeaderHBox"
	vbox.add_child(header_hbox)
	
	# 商品名称标签
	tooltip_name = Label.new()
	tooltip_name.name = "ItemName"
	tooltip_name.add_theme_font_size_override("font_size", 20)
	tooltip_name.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	tooltip_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tooltip_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_name.custom_minimum_size = Vector2(250, 0)
	header_hbox.add_child(tooltip_name)
	
	# 商品价格标签
	tooltip_price = Label.new()
	tooltip_price.name = "ItemPrice"
	tooltip_price.add_theme_font_size_override("font_size", 18)
	tooltip_price.add_theme_color_override("font_color", Color(0.6, 1, 0.6))
	tooltip_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tooltip_price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_name.custom_minimum_size = Vector2(250, 0)
	header_hbox.add_child(tooltip_price)
	
	# 物品类型标签
	tooltip_type = Label.new()
	tooltip_type.name = "ItemType"
	tooltip_type.add_theme_font_size_override("font_size", 14)
	tooltip_type.add_theme_color_override("font_color", Color(0.7, 0.8, 1))
	tooltip_type.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_name.custom_minimum_size = Vector2(250, 0)
	vbox.add_child(tooltip_type)
	
	# 分隔线1
	var separator1 = HSeparator.new()
	separator1.name = "Separator1"
	vbox.add_child(separator1)
	
	# 商品描述标签
	tooltip_description = Label.new()
	tooltip_description.name = "ItemDescription"
	tooltip_description.add_theme_font_size_override("font_size", 14)
	tooltip_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_name.custom_minimum_size = Vector2(250, 0)
	vbox.add_child(tooltip_description)
	
	# 添加到场景
	add_child(tooltip_panel)
	tooltip_panel.visible = false
