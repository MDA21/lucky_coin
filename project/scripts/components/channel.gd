extends Node2D

@export var channel_id: String = "channel_1"
@export var spawn_interval: float = 0.3
@export var coins_per_round: int = 50

@onready var coin_spawn_point: Marker2D = $CoinSpawnPoint
@onready var coin_container: Node2D = $CoinContainer

var coin_scene: PackedScene
var active_coins: Array = []
var spawn_timer: float = 0.0
var is_spawning: bool = false
var coins_spawned: int = 0

func _ready():
	coin_scene = preload("res://project/scenes/components/coin.tscn")
	$Area2D.add_to_group("channel_bottom")
	
	# 初始化通道的硬币分布
	Global.coin_system.fill_channel_from_mountain(channel_id)

func _process(delta):
	if is_spawning and coins_spawned < coins_per_round:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_physical_coin()
			spawn_timer = spawn_interval

func start_physical_simulation():
	is_spawning = true
	coins_spawned = 0
	spawn_timer = 0

func stop_physical_simulation():
	is_spawning = false

func spawn_physical_coin():
	var coin_instance = coin_scene.instantiate()
	
	# 从硬币系统获取硬币数据
	var coin_data = Global.coin_system.get_coin_for_slot(channel_id)
	coin_instance.coin_data = coin_data
	
	coin_container.add_child(coin_instance)
	coin_instance.spawn_at_position(coin_spawn_point.global_position)
	
	active_coins.append(coin_instance)
	coins_spawned += 1

func clear_physical_coins():
	for coin in active_coins:
		if is_instance_valid(coin):
			coin.deactivate()
	active_coins.clear()

func get_channel_id() -> String:
	return channel_id

signal physical_simulation_completed

func _on_physical_simulation_timeout():
	stop_physical_simulation()
	emit_signal("physical_simulation_completed")
