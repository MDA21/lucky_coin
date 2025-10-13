extends GridContainer

@onready var coin_system = $"/root/GameManager".get_system("coin_system")
@onready var pattern_system = $"/root/GameManager".get_system("pattern_system")

const GRID_ROWS = 5
const GRID_COLS = 3

var coin_grid: Array = []
var coin_nodes: Array = []

func _ready():
	setup_grid()

func setup_grid():
	#设置网格布局
	columns = GRID_COLS
	#清空现有子节点
	for child in get_children():
		child.queue_free()
	
	coin_grid.clear()
	coin_nodes.clear()
	
	#创建空网格
	for row in range(GRID_ROWS):
		var grid_row = []
		var node_row = []
		for col in range(GRID_COLS):
			var empty_spot = ColorRect.new()
			empty_spot.color = Color.TRANSPARENT
			empty_spot.custom_minimum_size = Vector2(50, 50)
			add_child(empty_spot)
			grid_row.append({"type": "empty"})
			node_row.append(empty_spot)
		coin_grid.append(grid_row)
		coin_nodes.append(node_row)

func fill_grid_from_channel(channel_id: String):
	setup_grid()
	
# 严格按照条件概率：从特定通道抽取硬币
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var coin_data = coin_system.get_coin_for_slot(channel_id)
			coin_grid[row][col] = coin_data
			create_coin_visual(coin_data, row, col)


func create_coin_visual(coin_data: Dictionary, row: int, col: int):
	var coin_texture = load(coin_data.get("current_texture", ""))
	var texture_rect = TextureRect.new()
	
	if coin_texture:
		texture_rect.texture = coin_texture
	else:
		#备用：根据硬币类型设置颜色
		var color_map = {
			"real_coin": Color.GOLD,
			"sun_coin": Color.YELLOW,
			"moon_coin": Color.SILVER, 
			"star_coin": Color.CYAN,
			"skull_coin": Color.BLACK,
			"blood_coin": Color.RED
		}
		var color_rect = ColorRect.new()
		for coin_type in color_map:
			if coin_type in coin_data.get("name", "").to_lower():
				color_rect.color = color_map[coin_type]
				break
		texture_rect = color_rect
	
	texture_rect.custom_minimum_size = Vector2(45, 45)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	
	#替换网格中的空位置
	var old_node = coin_nodes[row][col]
	remove_child(old_node)
	old_node.queue_free()
	
	add_child(texture_rect)
	coin_nodes[row][col] = texture_rect

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
