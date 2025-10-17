extends RigidBody2D

@export var coin_data: Dictionary = {}

# 节点引用
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# 硬币状态
var is_high_value: bool = false
var current_value: int = 0
var coin_type: String = ""
var is_active: bool = true
var has_landed: bool = false

# 物理参数
@export var coin_gravity_scale: float = 1.0
@export var coin_linear_damp: float = 0.1
@export var coin_angular_damp: float = 0.1

func _ready():
	setup_physics()
	setup_coin()
	create_base_animations()

func setup_physics():
	gravity_scale = coin_gravity_scale
	linear_damp = coin_linear_damp
	angular_damp = coin_angular_damp
	collision_layer = 2
	collision_mask = 1

func setup_coin():
	if coin_data.is_empty():
		return
	
	coin_type = coin_data.get("name", "unknown")
	current_value = coin_data.get("current_value", 0)
	is_high_value = coin_data.get("is_high_value", false)
	
	load_and_set_texture()
	setup_collision_shape()
	setup_special_effects()

func load_and_set_texture():
	var texture_path = coin_data.get("current_texture", "")
	
	if texture_path and ResourceLoader.exists(texture_path):
		var texture = load(texture_path)
		sprite_2d.texture = texture

func setup_collision_shape():
	if sprite_2d.texture:
		var texture_size = sprite_2d.texture.get_size()
		var radius = min(texture_size.x, texture_size.y) * 0.4
		
		if collision_shape_2d.shape == null:
			collision_shape_2d.shape = CircleShape2D.new()
		
		collision_shape_2d.shape.radius = radius

func create_base_animations():
	if not animation_player:
		return
	
	# 生成动画
	if not animation_player.has_animation("spawn"):
		var spawn_anim = Animation.new()
		var track_idx = spawn_anim.add_track(Animation.TYPE_VALUE)
		spawn_anim.track_set_path(track_idx, ".:scale")
		spawn_anim.track_insert_key(track_idx, 0.0, Vector2(0.1, 0.1))
		spawn_anim.track_insert_key(track_idx, 0.2, Vector2(1.2, 1.2))
		spawn_anim.track_insert_key(track_idx, 0.4, Vector2(1.0, 1.0))
		spawn_anim.length = 0.4
		animation_player.add_animation("spawn", spawn_anim)
	
	# 高亮动画
	if not animation_player.has_animation("highlight"):
		var highlight_anim = Animation.new()
		var track_idx = highlight_anim.add_track(Animation.TYPE_VALUE)
		highlight_anim.track_set_path(track_idx, "Sprite2D:modulate")
		highlight_anim.track_insert_key(track_idx, 0.0, Color(1, 1, 1, 1))
		highlight_anim.track_insert_key(track_idx, 0.1, Color(1, 1, 0.5, 1))
		highlight_anim.track_insert_key(track_idx, 0.2, Color(1, 1, 1, 1))
		highlight_anim.length = 0.3
		animation_player.add_animation("highlight", highlight_anim)
	
	# 消失动画
	if not animation_player.has_animation("fade_out"):
		var fade_anim = Animation.new()
		var track_idx = fade_anim.add_track(Animation.TYPE_VALUE)
		fade_anim.track_set_path(track_idx, "Sprite2D:modulate:a")
		fade_anim.track_insert_key(track_idx, 0.0, 1.0)
		fade_anim.track_insert_key(track_idx, 0.3, 0.0)
		fade_anim.length = 0.3
		fade_anim.loop_mode = Animation.LOOP_NONE
		animation_player.add_animation("fade_out", fade_anim)

func setup_special_effects():
	match coin_type:
		"太阳币", "月亮币", "星星币":
			if is_high_value:
				add_glow_effect(Color.YELLOW, 0.3)
		"骷髅币":
			add_pulse_effect(Color.DARK_GRAY, 1.5)
		"血币":
			add_pulse_effect(Color.DARK_RED, 1.2)

func add_glow_effect(color: Color, strength: float):
	sprite_2d.modulate = color * (1.0 + strength)

func add_pulse_effect(color: Color, speed: float):
	if animation_player:
		var animation_name = "pulse_%s" % name
		var animation = Animation.new()
		var track_idx = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_idx, "Sprite2D:modulate")
		animation.track_insert_key(track_idx, 0.0, color * 0.8)
		animation.track_insert_key(track_idx, 0.5, color * 1.2)
		animation.track_insert_key(track_idx, 1.0, color * 0.8)
		animation.length = 1.0 / speed
		animation.loop_mode = Animation.LOOP_LINEAR
		
		animation_player.add_animation(animation_name, animation)
		animation_player.play(animation_name)

# 公共方法
func spawn_at_position(spawn_pos: Vector2):
	global_position = spawn_pos
	animation_player.play("spawn")
	
	var random_force = Vector2(randf_range(-50, 50), 0)
	apply_central_impulse(random_force)

func get_coin_value() -> int:
	return current_value

func get_coin_type() -> String:
	return coin_type

func is_stress_coin() -> bool:
	return coin_data.get("is_stress_coin", false)

func is_penalty_coin() -> bool:
	return coin_data.get("coin_group", "") == "penalty_coins"

func highlight():
	animation_player.play("highlight")

func deactivate():
	is_active = false
	collision_shape_2d.set_deferred("disabled", true)
	animation_player.play("fade_out")
	await animation_player.animation_finished
	queue_free()

# 物理回调
func _on_body_entered(body: Node):
	if not has_landed and body.is_in_group("channel_bottom"):
		has_landed = true
		linear_damp = 5.0
		angular_damp = 5.0
