extends CanvasLayer

# -------------------- 0. 信号定义 --------------------
signal channel_to_hall 

# -------------------- 1. 节点引用 (@onready) --------------------

# GameManager 引用
@onready var game_manager = get_node("/root/GameManager")

# 着色器进度条
@onready var bar_A: Control = $"InteractionRoot/ChannelProgress/Bar_A_Color"
@onready var bar_B: Control = $"InteractionRoot/ChannelProgress/Bar_B_Color"
@onready var bar_C: Control = $"InteractionRoot/ChannelProgress/Bar_C_Color"
@onready var bar_D: Control = $"InteractionRoot/ChannelProgress/Bar_D_Color"

# Tooltip 根和 Label
@onready var tooltip_layer: Control = $"TooltipLayer"
@onready var tooltip_label: Label = $"TooltipLayer/Tooltip"

# Tooltip Panel 引用
@onready var tooltip_a: Panel = $"TooltipLayer/Tooltip_A"
@onready var tooltip_b: Panel = $"TooltipLayer/Tooltip_B"
@onready var tooltip_c: Panel = $"TooltipLayer/Tooltip_C"
@onready var tooltip_d: Panel = $"TooltipLayer/Tooltip_D"

# UI 根节点
@onready var interaction_root: Control = $"InteractionRoot"

# Lever
@onready var lever_button: TextureButton = $"InteractionRoot/Lever"
@onready var lever_anim: AnimationPlayer = $"InteractionRoot/Lever/Lever_Anim"

# Center Button
@onready var center_button: TextureButton = $"InteractionRoot/CenterButton"
@onready var center_anim: AnimationPlayer = $"InteractionRoot/CenterButton/Center_Anim"

# Coin Stack
@onready var coinstack: AnimatedSprite2D = $"InteractionRoot/CoinStack"
@onready var coin_anim: AnimationPlayer = $"InteractionRoot/CoinStack/Coin_Anim"

# Channel Sprites (视觉动画)
@onready var channel_a_sprite: AnimatedSprite2D = $"BackgroundRoot/Channels/Channel_A"
@onready var channel_b_sprite: AnimatedSprite2D = $"BackgroundRoot/Channels/Channel_B"
@onready var channel_c_sprite: AnimatedSprite2D = $"BackgroundRoot/Channels/Channel_C"
@onready var channel_d_sprite: AnimatedSprite2D = $"BackgroundRoot/Channels/Channel_D"

# Channel AnimPlayers
@onready var channel_a_anim: AnimationPlayer = $"BackgroundRoot/Channels/Channel_A/Channel_Anim_A"
@onready var channel_b_anim: AnimationPlayer = $"BackgroundRoot/Channels/Channel_B/Channel_Anim_B"
@onready var channel_c_anim: AnimationPlayer = $"BackgroundRoot/Channels/Channel_C/Channel_Anim_C"
@onready var channel_d_anim: AnimationPlayer = $"BackgroundRoot/Channels/Channel_D/Channel_Anim_D"

# Channel Button Areas (交互区域)
@onready var channel_a_area: Area2D = $"InteractionRoot/ChannelButtons/Channel_A"
@onready var channel_b_area: Area2D = $"InteractionRoot/ChannelButtons/Channel_B"
@onready var channel_c_area: Area2D = $"InteractionRoot/ChannelButtons/Channel_C"
@onready var channel_d_area: Area2D = $"InteractionRoot/ChannelButtons/Channel_D"

# Channel Elements
var channel_elements = {}
var channel_bars = {} 
var tooltip_panels = {} # 确保此变量已在类级别声明


# -------------------- 2. 常量 (const) 和变量 (var) --------------------

const PROPORTION_NAMES = [
	"真硬币", "太阳币", "月亮币",
	"星星币", "骷髅币", "血币"
]
const ANIM_PULL_DOWN = "pull_down"
const ANIM_FALL = "fall"
const ANIM_PRESS = "press"
const ANIM_OPEN = "open"

var channel_data = {
	"A": [], 
	"B": [],
	"C": [],
	"D": [],
}
var channel_costs = [0, 0, 0, 0] 
var activated_channels = []


# -------------------- 3. 生命周期函数 (_ready) --------------------

func _ready():
	# 初始化映射字典
	_init_channel_elements()
	_init_channel_bars()
	_init_tooltip_panels()
	
	# 从 GameManager 获取最新的 Channel Data
	_fetch_and_init_channel_data()
	
	# --- 初始化四个进度条的显示 (设置着色器参数) ---
	set_channel_data("A", channel_data["A"])
	set_channel_data("B", channel_data["B"])
	set_channel_data("C", channel_data["C"])
	set_channel_data("D", channel_data["D"])
		
	for bar in [bar_A, bar_B, bar_C, bar_D]:
		bar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bar.visible = false 
	
	# ★★★ 步骤 1: 初始化 UI 状态 ★★★
	tooltip_layer.visible = false 
	_set_all_tooltip_panels_visible(false)
	
	_set_channel_interaction_enabled(false)
	center_button.disabled = true
	lever_button.disabled = false

	_set_channel_labels_visible(false)
	_set_animated_sprites_stopped()
	
	# 连接信号 (Godot 4 语法：使用 .connect())
	lever_button.pressed.connect(_on_lever_button_pressed)
	center_button.pressed.connect(_on_center_button_pressed)
	
	channel_a_area.input_event.connect(_on_channel_area_input_event.bind("A"))
	channel_b_area.input_event.connect(_on_channel_area_input_event.bind("B"))
	channel_c_area.input_event.connect(_on_channel_area_input_event.bind("C"))
	channel_d_area.input_event.connect(_on_channel_area_input_event.bind("D"))


# -------------------- 4. 核心功能函数 --------------------

func _fetch_and_init_channel_data():
	if !game_manager: return
	
	channel_data["A"] = game_manager._get_channel_a_data()
	channel_data["B"] = game_manager._get_channel_b_data()
	channel_data["C"] = game_manager._get_channel_c_data()
	channel_data["D"] = game_manager._get_channel_d_data()


func _init_channel_elements():
	var id_list = ["A", "B", "C", "D"]
	var area_list = [channel_a_area, channel_b_area, channel_c_area, channel_d_area]
	
	for i in range(4):
		var area = area_list[i]
		var id = id_list[i]
		
		channel_elements[id] = {
			"area": area,
			"label": area.get_node("CostLabel") as Label,
			"sprite": area.get_node("ButtonSprite") as Sprite2D
		}

func _init_channel_bars():
	channel_bars = {
		bar_A: "A",
		bar_B: "B",
		bar_C: "C",
		bar_D: "D",
	}
	
func _init_tooltip_panels():
	tooltip_panels = {
		"A": tooltip_a,
		"B": tooltip_b,
		"C": tooltip_c,
		"D": tooltip_d,
	}
	
func _set_all_tooltip_panels_visible(_is_visible: bool):
	for panel in tooltip_panels.values():
		panel.visible = _is_visible


func _set_animated_sprites_stopped():
	if coinstack: coinstack.stop()
	if channel_a_sprite: channel_a_sprite.stop()
	if channel_b_sprite: channel_b_sprite.stop()
	if channel_c_sprite: channel_c_sprite.stop()
	if channel_d_sprite: channel_d_sprite.stop()

func _set_channel_interaction_enabled(enabled: bool):
	for id in channel_elements:
		channel_elements[id].area.monitorable = enabled
		print("Channel ", id, " monitorable set to: ", enabled)
	
	center_button.disabled = !enabled 
	print("Center Button disabled set to: ", !enabled)

func _set_channel_labels_visible(_is_visible: bool):
	for id in channel_elements:
		channel_elements[id].label.visible = _is_visible


func _initialize_costs():
	var external_costs = game_manager._get_channel_costs() 
	
	channel_costs = [0] + external_costs.slice(0, 3) 
	
	for i in range(4):
		var id = ["A", "B", "C", "D"][i]
		var cost = channel_costs[i]
		
		channel_elements[id].label.text = "$%d" % cost
		channel_elements[id].label.visible = true 


func set_channel_data(channel_id: String, new_proportions: Array) -> bool:
	if not channel_data.has(channel_id) or new_proportions.size() != 6:
		push_error("Error: Invalid channel ID or proportions size.")
		return false
		
	channel_data[channel_id] = new_proportions
	
	var target_bar: Control
	match channel_id:
		"A": target_bar = bar_A
		"B": target_bar = bar_B
		"C": target_bar = bar_C
		"D": target_bar = bar_D
		_: return false
			
	update_color_bar_parameters(target_bar, new_proportions)
	
	return true


func update_color_bar_parameters(bar_node: Control, proportions_array: Array):
	var shader_material = bar_node.material as ShaderMaterial
	
	if !shader_material:
		return
		
	var cumulative_break = 0.0
	
	for i in range(5):
		cumulative_break += proportions_array[i]
		
		if cumulative_break > 1.0: cumulative_break = 1.0

		var break_name = "break_%d" % (i + 1)
		shader_material.set_shader_parameter(break_name, cumulative_break)


func _format_tooltip_text(proportions: Array) -> String:
	var parts: Array = []
	
	for i in range(proportions.size()):
		var prop_name = PROPORTION_NAMES[i]
		var percentage = proportions[i] * 100.0
		var formatted_text = "%s：%.2f%%" % [prop_name, percentage]
		
		parts.append(formatted_text)
		
		if i == 2:
			parts.append("\n")

	return " ".join(parts)


# 辅助函数：播放动画并等待完成 (使用 await)
func _play_animation_and_wait(player: AnimationPlayer, anim_name: String):
	if !player: return
	
	player.play(anim_name, -1, 0.0, true) 
	
	await get_tree().create_timer(0.01).timeout 
	
	player.play(anim_name)
	await player.animation_finished


# -------------------- 5. 流程控制函数 (对应步骤 2, 5) --------------------

# ★★★ 步骤 2: 拉杆点击响应 ★★★
func _on_lever_button_pressed():
	if lever_button.disabled: return

	lever_button.disabled = true
	
	await _play_animation_and_wait(lever_anim, ANIM_PULL_DOWN)
	await _play_animation_and_wait(coin_anim, ANIM_FALL)
	
	_set_channel_interaction_enabled(true)
	center_button.disabled = false
	
	_initialize_costs()
	print("步骤 2 完成: 交互启用，费用显示。")


func _on_channel_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, channel_id: String):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		channel_elements[channel_id].area.monitorable = false
		channel_elements[channel_id].label.visible = false
		
		var bar: Control
		var anim_player: AnimationPlayer
		match channel_id:
			"A": bar = bar_A; anim_player = channel_a_anim
			"B": bar = bar_B; anim_player = channel_b_anim
			"C": bar = bar_C; anim_player = channel_c_anim
			"D": bar = bar_D; anim_player = channel_d_anim
		
		bar.visible = true
		
		await _play_animation_and_wait(anim_player, ANIM_OPEN)
		
		if !activated_channels.has(channel_id):
			activated_channels.append(channel_id)
			
		var cost_index = ["A", "B", "C", "D"].find(channel_id)
		var cost = channel_costs[cost_index]
		
		if game_manager:
			game_manager._handle_channel_selected(channel_id, cost)
		
		print("步骤 3 完成: 通道 ", channel_id, " 激活，着色器显示。")


# ★★★ 步骤 4: Center Button 点击响应 ★★★
func _on_center_button_pressed():
	if center_button.disabled: return
	
	_set_channel_interaction_enabled(false) 
	center_button.disabled = true 
	
	await _play_animation_and_wait(center_anim, ANIM_PRESS)
	
	_perform_game_operation() 
	
	_start_reset_and_cleanup()

# [TODO]硬币板的结算
# 占位函数：执行游戏核心操作 (留白)
func _perform_game_operation():
	print("--- 步骤 4: 执行核心游戏操作 (占位符) ---")
	pass 
	
	print("--- 核心游戏操作完成。---")


# ★★★ 步骤 5: 结算/重置/跳转 (修正 all() 函数问题) ★★★
func _start_reset_and_cleanup():
	print("步骤 5: 开始重置动画和清理。")

	# 1. 着色器消失 (隐藏进度条)
	for bar in [bar_A, bar_B, bar_C, bar_D]:
		bar.visible = false
		
	# 2. 隐藏 Tooltip Layer 和所有 Panel 
	_set_all_tooltip_panels_visible(false)
	tooltip_layer.visible = false
	
	
	# 最后清理 activated_channels 列表，准备下次进入
	activated_channels.clear() 
	
	if game_manager:
		game_manager.process_channel_view_cleanup_and_switch()
		


# -------------------- 6. Tooltip 信号响应函数 --------------------

func _handle_mouse_entered(channel_id: String):
	var target_bar: Control
	var target_tooltip_panel: Panel
	
	match channel_id:
		"A": target_bar = bar_A; target_tooltip_panel = tooltip_a
		"B": target_bar = bar_B; target_tooltip_panel = tooltip_b
		"C": target_bar = bar_C; target_tooltip_panel = tooltip_c
		"D": target_bar = bar_D; target_tooltip_panel = tooltip_d
		_: return
		
	if target_bar.visible:
		var proportions = channel_data.get(channel_id)
		if not proportions:
			return

		var tooltip_text = _format_tooltip_text(proportions)
		tooltip_label.text = tooltip_text
		
		_set_all_tooltip_panels_visible(false)
		target_tooltip_panel.visible = true 
		
		tooltip_layer.visible = true
	

func _handle_mouse_exited():
	tooltip_layer.visible = false
	_set_all_tooltip_panels_visible(false)

func _on_bar_a_color_mouse_entered() -> void:
	_handle_mouse_entered("A")
func _on_bar_a_color_mouse_exited() -> void:
	_handle_mouse_exited()

func _on_bar_b_color_mouse_entered() -> void:
	_handle_mouse_entered("B")
func _on_bar_b_color_mouse_exited() -> void:
	_handle_mouse_exited()

func _on_bar_c_color_mouse_entered() -> void:
	_handle_mouse_entered("C")
func _on_bar_c_color_mouse_exited() -> void:
	_handle_mouse_exited()

func _on_bar_d_color_mouse_entered() -> void:
	_handle_mouse_entered("D")
func _on_bar_d_color_mouse_exited() -> void:
	_handle_mouse_exited()
