extends "res://project/scripts/views/base_view.gd" 

# @onready var store_button: Button = $StoreButton # 未来你会在这里引用商店按钮

func _ready():
	# 确保调用父类的 _ready，让背景设置生效
	super._ready()
	print("Store View Loaded") 
	# 在这里添加商店特有的初始化代码
