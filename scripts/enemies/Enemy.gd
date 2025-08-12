extends CharacterBody2D
class_name Enemy

## Base enemy class that provides common functionality for all enemies

@export var move_speed: float = 30.0
@export var health: int = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_alive: bool = true
var screen_bounds: Rect2

signal enemy_died(enemy: Enemy)

func _ready():
	# Set default health from GameController if not overridden
	if health == 1:  # Only set if using default value
		health = GameController.ENEMY_BASE_HEALTH
	
	# Set up screen bounds for cleanup
	_update_screen_bounds()
	
	# Start animation
	_start_animation()
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_update_screen_bounds)

func _physics_process(delta):
	if not is_alive:
		return
	
	# Update movement (to be overridden by specific enemies)
	_update_movement(delta)
	
	# Apply movement
	move_and_slide()
	
	# Check if enemy is off-screen and should be removed
	_check_screen_bounds()

func _update_movement(_delta):
	"""Override this in specific enemy classes"""
	# Default: move left at treadmill speed PLUS additional movement speed
	velocity.x = -GameController.TREADMILL_SPEED - move_speed

func _start_animation():
	"""Override this in specific enemy classes"""
	if sprite and sprite.sprite_frames:
		sprite.play("move_left")

func _update_screen_bounds():
	"""Update screen bounds for cleanup detection"""
	var viewport = get_viewport()
	if viewport:
		var camera = get_viewport().get_camera_2d()
		if camera:
			var screen_size = viewport.get_visible_rect().size / camera.zoom
			var camera_pos = camera.global_position
			screen_bounds = Rect2(
				camera_pos - screen_size / 2 - Vector2(100, 100),  # Extra buffer
				screen_size + Vector2(200, 200)  # Extra buffer on all sides
			)

func _check_screen_bounds():
	"""Remove enemy if completely off-screen"""
	if not screen_bounds.has_point(global_position):
		# Check if we're to the left of the screen (main cleanup condition)
		var camera = get_viewport().get_camera_2d()
		if camera and global_position.x < camera.global_position.x - screen_bounds.size.x / 2 - 50:
			print("Despawned ", get_enemy_type(), " for leaving screen at ", global_position)
			_cleanup()

func take_damage(amount: int = 1):
	"""Handle taking damage"""
	if not is_alive:
		return
	
	health -= amount
	if health <= 0:
		die()

func die():
	"""Handle enemy death"""
	if not is_alive:
		return
	
	is_alive = false
	enemy_died.emit(self)
	_cleanup()

func _cleanup():
	"""Clean up the enemy"""
	queue_free()

func get_enemy_type() -> String:
	"""Return the enemy type name - override in subclasses"""
	return "Enemy"
