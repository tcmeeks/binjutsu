extends CharacterBody2D
class_name GenericUnit

## Generic data-driven unit that can be configured for different behaviors

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var projectile_attack: ProjectileAttack = $ProjectileAttack
@onready var movement_component: MovableObject

var unit_data: UnitData
var is_alive: bool = true
var movement_direction: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.RIGHT
var last_horizontal_direction: String = "right"  # Track last horizontal movement for idle
var screen_bounds: Rect2
var treadmill_stopped: bool = false

signal unit_died(unit: GenericUnit)

func _ready():
	# Add to units group for detection
	add_to_group("units")
	add_to_group("debug_visualizers")
	
	# Initialize components if we have data already
	if unit_data:
		_initialize_components()

func initialize_with_data(data: UnitData):
	"""Initialize the unit with provided data configuration"""
	unit_data = data
	
	if not unit_data:
		print("ERROR: GenericUnit initialized without data!")
		return
	
	# If we're already in the scene tree, initialize immediately
	# Otherwise, _ready() will handle it
	if is_inside_tree():
		_initialize_components()

func _initialize_components():
	"""Initialize all components with unit data"""
	if not unit_data:
		return
	
	# Set up movement component
	movement_component = MovableObject.new()
	add_child(movement_component)
	movement_component.use_smooth_movement = unit_data.use_smooth_movement
	movement_component.movement_acceleration = unit_data.movement_acceleration
	movement_component.movement_deceleration = unit_data.movement_deceleration
	
	# Configure visual properties
	if unit_data.sprite_frames and sprite:
		sprite.sprite_frames = unit_data.sprite_frames
		sprite.play(unit_data.get_walk_animation())
	
	# Set up collision shape based on unit data
	call_deferred("_setup_collision_shape")
	
	# Configure projectile attack
	if projectile_attack:
		projectile_attack.attack_range = unit_data.attack_range
		projectile_attack.attack_speed = unit_data.attack_speed
		projectile_attack.projectile_type = unit_data.projectile_type
		projectile_attack.auto_attack = unit_data.auto_attack
		projectile_attack.show_range_debug = DebugVisualization.debug_mode_enabled
	
	# Initialize screen bounds
	_update_screen_bounds()
	
	# Connect to viewport size changes
	if not get_viewport().size_changed.is_connected(_update_screen_bounds):
		get_viewport().size_changed.connect(_update_screen_bounds)
	
	if DebugVisualization.debug_mode_enabled:
		print("Initialized ", get_unit_type(), " with data")

func _setup_collision_shape():
	"""Set up collision shape based on unit data"""
	if collision_shape and unit_data:
		var rect_shape = RectangleShape2D.new()
		rect_shape.size = Vector2(12, 16)  # Keep current size
		collision_shape.set_deferred("shape", rect_shape)

func _physics_process(delta):
	if not is_alive or not unit_data:
		return
	
	# Track treadmill state - check if speed has actually reached zero
	treadmill_stopped = GameController.TREADMILL_SPEED <= 0.0
	
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
	
	# Store input vector for animation
	movement_direction = input_vector
	
	# Track last horizontal movement direction for idle animations
	if input_vector.x < 0:
		last_horizontal_direction = "left"
	elif input_vector.x > 0:
		last_horizontal_direction = "right"
	
	# Calculate base movement velocity
	var base_velocity = Vector2.ZERO
	
	# Horizontal movement with treadmill effects
	if input_vector.x != 0:
		# Treadmill effect proportional to current speed
		var treadmill_effect = GameController.TREADMILL_SPEED * unit_data.treadmill_effect_multiplier
		
		if input_vector.x > 0:  # Moving right (against treadmill) - harder/slower
			base_velocity.x = unit_data.move_speed - treadmill_effect
		else:  # Moving left (with treadmill) - easier/faster  
			base_velocity.x = -unit_data.move_speed - treadmill_effect
	# No horizontal input = zero horizontal velocity (stays stationary on screen)
	
	# Vertical movement - normal speed
	base_velocity.y = input_vector.y * unit_data.move_speed
	
	# Apply movement through movement component
	if movement_component:
		movement_component.set_treadmill_enabled(false)  # Handle treadmill manually
		movement_component.set_target_velocity(base_velocity)
		movement_component.update_movement(delta)
		movement_component.apply_to_character_body(self)
	else:
		velocity = base_velocity
	
	move_and_slide()
	
	# Apply boundary constraints
	_apply_boundary_constraints()
	
	# Update animation
	_update_animation()

func _update_animation():
	"""Update animation based on unit data"""
	if unit_data and sprite:
		# If treadmill is stopped and unit isn't moving, show idle animation
		if treadmill_stopped and movement_direction.length() == 0:
			sprite.play(unit_data.get_idle_animation(last_horizontal_direction))
			sprite.speed_scale = 1.0  # Normal speed for idle
		elif treadmill_stopped:
			# Treadmill stopped but unit is moving - face the direction they're moving
			var facing_direction = "left" if movement_direction.x < 0 else "right"
			sprite.play(unit_data.get_walk_animation(facing_direction))
			sprite.speed_scale = 1.0  # Normal speed when treadmill stopped
		else:
			# Treadmill running - show walking animation (running on treadmill or moving)
			sprite.play(unit_data.get_walk_animation())
			
			# Scale animation speed based on treadmill speed (0x to 2x)
			var speed_ratio = GameController.TREADMILL_SPEED / GameController.BASE_TREADMILL_SPEED
			sprite.speed_scale = 1.0 + speed_ratio  # 1.0 when stopped, 2.0 when at full speed

func _update_screen_bounds():
	"""Update screen bounds based on camera position and viewport size"""
	var camera = get_viewport().get_camera_2d()
	if camera and unit_data:
		var viewport_size = get_viewport().get_visible_rect().size
		var camera_pos = camera.global_position
		var zoom = camera.zoom
		
		# Calculate screen bounds with margin
		var half_screen = viewport_size / (2 * zoom)
		screen_bounds = Rect2(
			camera_pos - half_screen + Vector2(unit_data.boundary_margin, unit_data.boundary_margin),
			viewport_size / zoom - Vector2(unit_data.boundary_margin * 2, unit_data.boundary_margin * 2)
		)
	else:
		# Fallback if no camera found
		var viewport_size = get_viewport().get_visible_rect().size
		var margin = unit_data.boundary_margin if unit_data else 32.0
		screen_bounds = Rect2(
			Vector2(margin, margin),
			viewport_size - Vector2(margin * 2, margin * 2)
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

func take_damage(amount: int = 1):
	"""Handle taking damage"""
	if not is_alive or not unit_data:
		return
	
	unit_data.health -= amount
	if unit_data.health <= 0:
		die()

func die():
	"""Handle unit death"""
	if not is_alive:
		return
	
	is_alive = false
	unit_died.emit(self)
	_cleanup()

func _cleanup():
	"""Clean up the unit"""
	queue_free()

func get_unit_type() -> String:
	"""Return the unit type name"""
	if unit_data:
		return unit_data.unit_name
	return "Unknown"

func get_collision_radius() -> float:
	"""Get collision radius for vision line detection"""
	if unit_data:
		return unit_data.collision_radius
	
	# Fallback to collision shape calculation
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			return collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			return max(rect_shape.size.x, rect_shape.size.y) / 2.0
	return 8.0  # Default radius

func get_sprite() -> AnimatedSprite2D:
	"""Get the unit's sprite for potential effects"""
	return sprite

func set_facing_direction(direction: Vector2):
	"""Set the unit's facing direction without moving"""
	last_movement_direction = direction
	if velocity.length() == 0:
		_update_animation()

func set_debug_mode(enabled: bool):
	"""Set debug mode for this unit"""
	if projectile_attack:
		projectile_attack.set_debug_mode(enabled)
