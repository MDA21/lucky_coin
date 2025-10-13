extends Control

@onready var coin_system = $"/root/GameManager".get_system("coin_system")

var current_channel_id: String = ""

func setup(channel_id: String):
	current_channel_id = channel_id
	update_display()

func update_display():
	var distribution = coin_system.get_channel_distribution_info(current_channel_id)
	
	# 清空现有显示
	for child in get_children():
		child.queue_free()
	
	# 创建分布显示
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	for coin_type in distribution:
		var info = distribution[coin_type]
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		# 硬币图标
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(20, 20)
		# 这里应该加载对应的硬币纹理
		hbox.add_child(texture_rect)
		
		# 硬币名称和百分比
		var label = Label.new()
		label.text = "%s: %.1f%%" % [info.name, info.percentage]
		hbox.add_child(label)

# 当通道分布变化时更新显示
func on_distribution_changed():
	if current_channel_id != "":
		update_display()
