extends CanvasLayer # 替换为你场景根节点的实际类型

# 获取项目设置中配置的视口尺寸
const VIEWPORT_WIDTH = 1152
const VIEWPORT_HEIGHT = 648

@onready var background_sprite: Sprite2D = $BackgroundSprite 
@onready var start_game_button: Button = $CenterContainer/StartGameButton

signal request_game_start

func _ready():
	# 立即执行背景设置，保证在第0帧绘制
	setup_background() 
	
	# 仍保留 call_deferred 作为额外的保险
	call_deferred("setup_background")
	
	start_game_button.pressed.connect(_on_start_game_button_pressed)

func setup_background():
	if not is_instance_valid(background_sprite):
		return
		
	# 1. 动态创建一个 1x1 像素的纯白纹理
	if background_sprite.texture == null:
		var image = Image.create(1, 1, false, Image.FORMAT_RGB8)
		# 设置主菜单的背景颜色，例如：深灰色
		image.set_pixel(0, 0, Color.DARK_GRAY) 
		var texture = ImageTexture.create_from_image(image)
		background_sprite.texture = texture
	
	# 2. 手动设置 Sprite 的全屏尺寸和位置
	background_sprite.position = Vector2(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)
	background_sprite.scale = Vector2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT)
	
	background_sprite.queue_redraw()

func _on_start_game_button_pressed():
	emit_signal("request_game_start")
	GameManager.start_new_game()
