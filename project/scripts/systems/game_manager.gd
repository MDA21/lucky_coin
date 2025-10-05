extends Node

# preload scenes
const VIEW_PATHS: Array[PackedScene] = [
	preload("res://project/scenes/views/main_menu_view.tscn"),
	preload("res://project/scenes/views/store_view.tscn"),
	preload("res://project/scenes/views/hall_view.tscn"),
	preload("res://project/scenes/views/bank_view.tscn")
]

# start from scene "hall"
var current_view_index: int = 0
var current_view_node: Node = null

func _ready():
	# load initial scene
	await get_tree().process_frame
	_change_view(current_view_index)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("scene_left"):
		if current_view_index > 1:
			_change_view(current_view_index-1)
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("scene_right"):
		if current_view_index < VIEW_PATHS.size() - 1:
			_change_view(current_view_index + 1)
			get_viewport().set_input_as_handled()
			
func _change_view(new_index: int) -> void:
	if new_index == current_view_index:
		return
	
	if current_view_node != null:
		if current_view_node.has_signal("request_game_start"):
			current_view_node.request_game_start.disconnect(_on_game_start_requested)
		
		current_view_node.queue_free()
		current_view_node = null
	
	var new_view: Node = VIEW_PATHS[new_index].instantiate()
	
	if new_view.has_signal("request_game_start"):
		new_view.request_game_start.connect(_on_game_start_requested)
	
	add_child(new_view)
	
	current_view_node = new_view
	current_view_index = new_index
	
	print("change to index: ", current_view_index, " (", new_view.name, ")")
	
func _on_game_start_requested():
	_change_view(2)
	
