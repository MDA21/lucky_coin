extends Node2D
class_name Coin

# 硬币类型枚举
enum CoinType {
	REAL,           # 真硬币
	CLOVER,         # 三叶草币
	LEMON,          # 柠檬币
	CHERRY,         # 樱桃币
	CAT             # 猫猫币
}

#硬币属性
var coin_type: CoinType
var coin_value: float = 0.0
var pattern_level: int = 1
var texture_path: String = ""
var is_visible: bool = true

#节点引用
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# 连接 Area2D 的信号
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	connect("input_event", _on_input_event)
	
	setup_visuals()

#初始化硬币
func setup(type: CoinType, pattern: int = 1):
	coin_type = type
	pattern_level = pattern
	load_coin_config()
	setup_visuals()

#配置文件加载硬币属性
func load_coin_config():
	var config_path = "res://project/data/coin_types.json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	

	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
		

	var coin_data = json.data
	match coin_type:
		CoinType.REAL:
			var real_data = coin_data["real_coin"]
			coin_value = real_data["base_value"]
			texture_path = real_data["texture"]
		CoinType.CLOVER:
			var clover_data = coin_data["clover_coin"]
			var patterns = clover_data["patterns"]
			var pattern_values = clover_data["pattern_values"]
					
			if pattern_level <= pattern_values.size():
				coin_value = pattern_values[pattern_level - 1]
				#根据图案等级选择纹理
				texture_path = clover_data["texture_base"] + "_" + patterns[pattern_level - 1] + ".png"

#设置硬币视觉效果
func setup_visuals():
	if ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		if sprite:
			sprite.texture = texture
	
	if collision_shape:
		collision_shape.disabled = !is_visible

#获取硬币价值（用于结算）
func get_value() -> float:
	return coin_value

#获取硬币类型
func get_coin_type() -> CoinType:
	return coin_type

#获取图案等级
func get_pattern_level() -> int:
	return pattern_level

#设置硬币可见性
func set_coin_visible(visible: bool):
	is_visible = visible
	if sprite:
		sprite.visible = visible
	if collision_shape:
		collision_shape.disabled = !visible

#硬币进入通道时的动画
func play_enter_channel_animation():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

#硬币结算时的动画
func play_settle_animation():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	tween.tween_callback(queue_free)

#鼠标悬停处理
func _on_mouse_entered():
	#悬停效果，后续等效果确定下来可以改成悬停显示效果
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2)

#鼠标离开处理
func _on_mouse_exited():
	#恢复正常颜色
	if sprite:
		sprite.modulate = Color(1, 1, 1)

#输入事件处理
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		#硬币被点击时会告诉玩家种类
		print("Coin clicked: ", coin_type)
