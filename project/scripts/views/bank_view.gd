extends "res://project/scripts/views/base_view.gd" 

# @onready var bank_ui: Control = $BankUI # 未来你会在这里引用银行界面

func _ready():
	super._ready()
	print("Bank View Loaded") 
	# 在这里添加银行特有的初始化代码
