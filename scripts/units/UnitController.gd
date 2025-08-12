extends CharacterBody2D
class_name UnitController

## Player-controlled unit that uses Villager animations and movement

# Get settings from GameController
var move_speed: float
var boundary_margin: float

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var projectile_attack: ProjectileAttack = $ProjectileAttack

var movement_direction: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.RIGHT  # Default facing right
var screen_bounds: Rect2

func _ready():
	# Add to units group for vision detection
	add_to_group("units")
	add_to_group("debug_visualizers")
	
	# Get settings from GameController
	move_speed = GameController.PLAYER_BASE_SPEED
	boundary_margin = GameController.UNIT_BOUNDARY_MARGIN
	
	# Start with walk_right animation to simulate running on treadmill
	sprite.play("walk_right")
	
	# Initialize screen bounds
	_update_screen_bounds()
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_update_screen_bounds)
	
	# Configure projectile attack if it exists
	if projectile_attack:
		projectile_attack.attack_range = 128.0  # Doubled attack range
		projectile_attack.attack_speed = 1.0
		projectile_attack.projectile_type = "kunai"
		projectile_attack.auto_attack = true  # Enable auto-attack for testing
		projectile_attack.show_range_debug = DebugVisualization.debug_mode_enabled

func _physics_process(_delta):
	# Get input for movement (arrow keys + WASD)
	var input_vector = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_vector.y += 1
	
	# Apply movement with treadmill speed adjustments
	velocity = Vector2.ZERO
	
	# Horizontal movement with different speeds
	if input_vector.x > 0:  # Moving right (forward) - slower but noticeable
		velocity.x = move_speed * GameController.PLAYER_TREADMILL_FORWARD_MULTIPLIER
	elif input_vector.x < 0:  # Moving left (backward) - double speed
		velocity.x = -move_speed * GameController.PLAYER_TREADMILL_BACKWARD_MULTIPLIER
	
	# Vertical movement - normal speed
	velocity.y = input_vector.y * move_speed
	
	move_and_slide()
	
	# Apply boundary constraints
	_apply_boundary_constraints()
	
	# Update animation
	_update_animation()

func _update_animation():
	# Always show walking right animation (running on treadmill)
	sprite.play("walk_right")

func set_facing_direction(direction: Vector2):
	"""Set the unit's facing direction without moving"""
	last_movement_direction = direction
	if velocity.length() == 0:
		_update_animation()

func _update_screen_bounds():
	"""Update screen bounds based on camera position and viewport size"""
	var camera = get_viewport().get_camera_2d()
	if camera:
		var viewport_size = get_viewport().get_visible_rect().size
		var camera_pos = camera.global_position
		var zoom = camera.zoom
		
		# Calculate screen bounds with margin
		var half_screen = viewport_size / (2 * zoom)
		screen_bounds = Rect2(
			camera_pos - half_screen + Vector2(boundary_margin, boundary_margin),
			viewport_size / zoom - Vector2(boundary_margin * 2, boundary_margin * 2)
		)
	else:
		# Fallback if no camera found
		var viewport_size = get_viewport().get_visible_rect().size
		screen_bounds = Rect2(
			Vector2(boundary_margin, boundary_margin),
			viewport_size - Vector2(boundary_margin * 2, boundary_margin * 2)
		)

func _apply_boundary_constraints():
	"""Keep the unit within screen boundaries"""
	if screen_bounds.size.x <= 0 or screen_bounds.size.y <= 0:
		return
	
	# Clamp position to screen bounds
	var new_position = global_position
	new_position.x = clamp(new_position.x, screen_bounds.position.x, screen_bounds.position.x + screen_bounds.size.x)
	new_position.y = clamp(new_position.y, screen_bounds.position.y, screen_bounds.position.y + screen_bounds.size.y)
	
	# If position was clamped, stop velocity in that direction
	if new_position.x != global_position.x:
		velocity.x = 0
	if new_position.y != global_position.y:
		velocity.y = 0
	
	global_position = new_position

func set_debug_mode(enabled: bool):
	"""Set debug mode for this unit"""
	if projectile_attack:
		projectile_attack.set_debug_mode(enabled)

func get_collision_radius() -> float:
	"""Get collision radius for vision line detection"""
	var collision_shape = get_node("CollisionShape2D") as CollisionShape2D
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			return collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			return max(rect_shape.size.x, rect_shape.size.y) / 2.0
	return 8.0  # Default radius
