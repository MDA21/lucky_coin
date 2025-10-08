extends CanvasLayer # 假设所有视图的根节点都是 CanvasLayer

# 获取项目设置中配置的视口尺寸
const VIEWPORT_WIDTH = 1152
const VIEWPORT_HEIGHT = 648

@onready var background_wall: ColorRect = $BackgroundWall

func _ready():
	# 保持 _ready 简洁，并使用 call_deferred 确保安全时机
	call_deferred("force_full_screen_layout")

func force_full_screen_layout():
	if not is_instance_valid(background_wall):
		return

	# 1. 强制应用锚点预设为全屏 (PRESET_FULL_RECT)
	# 这是 Godot 4 中用于代码设置全屏布局的标准方法。
	background_wall.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 2. 绕过布局延迟：通过修改一个不影响视觉的主题常量来强制布局系统重新计算。
	# 这是解决首帧渲染问题的常见 hack，因为它能保证触发 Control 节点的内部尺寸变化信号。
	background_wall.add_theme_constant_override("margin_left", 0) 

	# 3. 强制重绘，确保变化立即在下一帧生效
	background_wall.queue_redraw()
	
	# 4. 移除 hack 留下的覆盖（虽然它不会影响视觉，但最好清理）
	background_wall.remove_theme_constant_override("margin_left")
	
	print("DEBUG: Background layout enforced.")
