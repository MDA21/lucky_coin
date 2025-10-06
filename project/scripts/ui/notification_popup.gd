extends CanvasLayer

@onready var label = $Control/Label
@onready var animation_player = $Control/AnimationPlayer

func show_message(message: String):
	label.text = message
	animation_player.play("show_and_fade")
	# 动画结束后自动销毁
	await animation_player.animation_finished
	queue_free()
