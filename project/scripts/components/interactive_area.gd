extends Area2D
class_name InteractiveArea

#交互类型枚举
enum InteractionType {
	GENERIC,        #通用交互
	VIEW_SWITCH,    #视角切换
	OBJECT_PICKUP,  #物品拾取
	BUTTON_PRESS    #按钮按下
}

#交互区域属性
var interaction_type: InteractionType = InteractionType.GENERIC
var interaction_name: String = ""
var tooltip_text: String = ""
var is_active: bool = true
var requires_item: String = ""  #需要特定物品才能交互，商店道具可能的效果

#视觉反馈
@onready var highlight_sprite: Sprite2D = $HighlightSprite

signal area_clicked(area_name, interaction_type)
signal area_hovered(area_name, is_hovered)

func _ready():
	#连接信号
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	
	#初始隐藏高亮
	if highlight_sprite:
		highlight_sprite.visible = false

#初始化交互区域
func setup(type: InteractionType, name: String, tooltip: String = "", active: bool = true):
	interaction_type = type
	interaction_name = name
	tooltip_text = tooltip
	is_active = active
	update_collision_state()

#更新碰撞状态
func update_collision_state():
	#设置碰撞层的启用状态
	monitorable = is_active
	monitoring = is_active
	
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.disabled = !is_active

#鼠标悬停处理
func _on_mouse_entered():
	if is_active:
		show_highlight()
		emit_signal("area_hovered", interaction_name, true)

#鼠标离开处理
func _on_mouse_exited():
	hide_highlight()
	emit_signal("area_hovered", interaction_name, false)

#显示高亮效果
func show_highlight():
	if highlight_sprite:
		highlight_sprite.visible = true
		var tween = create_tween()
		tween.tween_property(highlight_sprite, "modulate", Color(1, 1, 1, 0.8), 0.2)

#隐藏高亮效果
func hide_highlight():
	if highlight_sprite:
		var tween = create_tween()
		tween.tween_property(highlight_sprite, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.tween_callback(_hide_sprite)

func _hide_sprite():
	if highlight_sprite:
		highlight_sprite.visible = false

#输入事件处理
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active:
			handle_click()

#处理点击交互
func handle_click():
	#播放点击反馈
	play_click_feedback()
	
	#发射交互信号
	emit_signal("area_clicked", interaction_name, interaction_type)
	
	#根据交互类型执行不同操作
	match interaction_type:
		InteractionType.VIEW_SWITCH:
			switch_view()
		InteractionType.OBJECT_PICKUP:
			pickup_object()
		InteractionType.BUTTON_PRESS:
			press_button()
		_:
			generic_interaction()

#播放点击反馈动画
func play_click_feedback():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

#视角切换交互
func switch_view():
	print("切换到视图: ", interaction_name)
	#这里会连接到ViewManager进行实际切换

#物品拾取交互
func pickup_object():
	print("拾取物品: ", interaction_name)
	#这里会连接到InventorySystem

#按钮按下交互
func press_button():
	print("按下按钮: ", interaction_name)
	#这里会连接到对应的功能系统

#通用交互
func generic_interaction():
	print("通用交互: ", interaction_name)

#设置激活状态
func set_active(active: bool):
	is_active = active
	update_collision_state()
	
	if !active:
		hide_highlight()

#获取工具提示文本
func get_tooltip() -> String:
	return tooltip_text

#检查是否需要特定物品
func requires_specific_item() -> bool:
	return requires_item != ""

#获取所需物品名称
func get_required_item() -> String:
	return requires_item
