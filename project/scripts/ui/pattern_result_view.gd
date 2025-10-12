extends Control

@onready var result_label = $ResultLabel
@onready var pattern_list = $PatternList
@onready var animation_player = $AnimationPlayer

func show_results(result_data: Dictionary):
	visible = true
	
	var result_text = "结算结果:\n"
	result_text += "金钱: %d $\n" % result_data.total_money
	result_text += "压力变化: %d\n" % result_data.total_stress_change
	result_text += "发现图案: %d 个\n" % result_data.pattern_count
	
	result_label.text = result_text
	
	#显示详细的图案列表
	pattern_list.clear()
	for pattern in result_data.patterns_found:
		var pattern_text = "%s: %d $ (x%d)" % [pattern.type, pattern.money, pattern.multiplier]
		pattern_list.add_item(pattern_text)
	
	#播放显示动画
	animation_player.play("show_results")

func _on_continue_pressed():
	animation_player.play("hide_results")
	await animation_player.animation_finished
	visible = false
