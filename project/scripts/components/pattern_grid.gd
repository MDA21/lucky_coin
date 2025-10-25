extends GridContainer

var coin_system = null
var pattern_system = null


@export var debug_enabled: bool = true
@export var channel_id: String = "A"

const GRID_ROWS = 5
const GRID_COLS = 3

var coin_grid: Array = []
var coin_nodes: Array = []

func _ready():
	if debug_enabled:
		print("=== PatternGrid _ready() 开始 ===")
		print("节点路径: ", get_path())
		print("节点名称: ", name)
	
	self.visible = false
	self.z_index = 100

	
	# 设置网格容器属性
	self.columns = GRID_COLS
	self.add_theme_constant_override("h_separation", 5)
	self.add_theme_constant_override("v_separation", 5)
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)  # 深色半透明背景
	self.add_theme_stylebox_override("panel", style_box)
	
	# 设置最小尺寸
	self.custom_minimum_size = Vector2(150, 250)
	

	# 延迟获取系统引用，确保Global已初始化
	call_deferred("initialize_systems")

func initialize_systems():
	if debug_enabled:
		print("初始化系统引用")
	
	coin_system = Global.get_coin_system()
	pattern_system = Global.get_pattern_system()
	
	if debug_enabled:
		print("Coin System: ", coin_system != null)
		print("Pattern System: ", pattern_system != null)
	
	# 如果指定了通道ID，自动填充网格
	if channel_id != "":
		call_deferred("fill_grid_from_channel", channel_id)

func setup_grid():
	print("设置网格布局，行数: ", GRID_ROWS, " 列数: ", GRID_COLS)
	
	# 清空现有子节点
	for child in get_children():
		remove_child(child)
		child.queue_free()
	
	coin_grid.clear()
	coin_nodes.clear()
	
	# 创建空网格
	for row in range(GRID_ROWS):
		var grid_row = []
		var node_row = []
		for col in range(GRID_COLS):
			var empty_spot = ColorRect.new()
			empty_spot.color = Color(0.3, 0.3, 0.3, 0.5)  # 灰色半透明，用于调试
			empty_spot.custom_minimum_size = Vector2(60, 60)
			empty_spot.size = Vector2(60, 60)
			empty_spot.visible = true
			add_child(empty_spot)
			grid_row.append({"type": "empty"})
			node_row.append(empty_spot)
		coin_grid.append(grid_row)
		coin_nodes.append(node_row)
	
	if debug_enabled:
		print("网格设置完成，子节点数量: ", get_child_count())


func fill_grid_from_channel(channel_id: String):
	
	if debug_enabled:
		print("从通道 ", channel_id, " 填充网格")
	
	if not coin_system:
		if debug_enabled:
			print("错误: Coin system 未初始化")
		return
		
	setup_grid()
	
# 严格按照条件概率：从特定通道抽取硬币
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var coin_data = coin_system.get_coin_for_slot(channel_id)
			coin_grid[row][col] = coin_data
			create_coin_visual(coin_data, row, col)
			
	


func create_coin_visual(coin_data: Dictionary, row: int, col: int):
	var coin_texture_path = coin_data.get("current_texture", "")
	var coin_texture = null
	
	if coin_texture_path:
		if ResourceLoader.exists(coin_texture_path):
			coin_texture = load(coin_texture_path)
			if debug_enabled:
				print("纹理加载成功: ", coin_texture != null)
		else:
			if debug_enabled:
				print("纹理路径不存在: ", coin_texture_path)
	
	if coin_texture:
		var texture_rect = TextureRect.new()
		texture_rect.texture = coin_texture
		texture_rect.expand = true
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.custom_minimum_size = Vector2(55, 55)
		texture_rect.size = Vector2(55, 55)
		texture_rect.visible = true
		
		# 替换网格中的空位置
		var old_node = coin_nodes[row][col]
		if is_instance_valid(old_node):
			remove_child(old_node)
			old_node.queue_free()
		
		add_child(texture_rect)
		coin_nodes[row][col] = texture_rect
		print("创建硬币视觉: 行 ", row, " 列 ", col, " 类型: ", coin_data.get("name", "未知"))
	else:
		return 

func show_grid():
	self.visible = true
	if debug_enabled:
		print("显示硬币板: ", channel_id)

func hide_grid():
	self.visible = false
	if debug_enabled:
		print("隐藏硬币板: ", channel_id)

func get_coin_grid() -> Array:
	return coin_grid.duplicate()

func highlight_pattern(pattern_shape: Array, highlight_color: Color = Color.YELLOW):
	#高亮显示检测到的图案
	clear_highlights()
	
	for position in pattern_shape:
		var row = position[0]
		var col = position[1]
		var node = coin_nodes[row][col]
		
		if node is TextureRect:
			node.modulate = highlight_color
		elif node is ColorRect:
			node.color = highlight_color

func clear_highlights():
	#清除所有高亮
	for row in coin_nodes:
		for node in row:
			if node is TextureRect:
				node.modulate = Color.WHITE
			elif node is ColorRect:
				node.color = Color.TRANSPARENT
