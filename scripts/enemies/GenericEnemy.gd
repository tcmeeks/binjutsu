extends CharacterBody2D
class_name GenericEnemy

## Generic data-driven enemy that can be configured for different behaviors

const CoinDropperSystem = preload("res://scripts/systems/CoinDropper.gd")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var enemy_data: EnemyData
var movement_component: MovementComponent
var vision_cone: VisionCone
var is_alive: bool = true
var screen_bounds: Rect2

# Speed boost system for raccoons and frogs
var base_speed: float
var target_speed: float
var current_speed_multiplier: float = 1.0
var is_in_fast_mode: bool = false
var speed_transition_time: float = 2.0
var speed_transition_timer: float = 0.0

# Chase system for slimes
var last_spotted_target: Node2D
var chase_component: ChaseMovementComponent

# Tracking system for cyclopes
var tracking_component: TrackingMovementComponent

# Leap-chase system for frogs
var leap_chase_component: LeapChaseMovementComponent

# Snake tracking system
var snake_component: SnakeMovementComponent

signal enemy_died(enemy: GenericEnemy)

func initialize_with_data(data: EnemyData):
	enemy_data = data

func _ready():
	# Add to enemies group for debug management
	add_to_group("enemies")
	
	# Set up sprite after nodes are ready
	if enemy_data and enemy_data.sprite_frames:
		sprite.sprite_frames = enemy_data.sprite_frames
		sprite.play(enemy_data.animation_name)
	
	# Initialize speed system
	if enemy_data:
		base_speed = enemy_data.move_speed
		target_speed = base_speed
	
	# Create movement component
	if enemy_data:
		movement_component = MovementComponent.create_movement_component(enemy_data.movement_type)
		add_child(movement_component)
		movement_component.initialize(self, enemy_data)
		
		# Store reference to specialized movement components
		if movement_component is ChaseMovementComponent:
			chase_component = movement_component as ChaseMovementComponent
		elif movement_component is TrackingMovementComponent:
			tracking_component = movement_component as TrackingMovementComponent
		elif movement_component is LeapChaseMovementComponent:
			leap_chase_component = movement_component as LeapChaseMovementComponent
		elif movement_component is SnakeMovementComponent:
			snake_component = movement_component as SnakeMovementComponent
	
	# Create vision cone component
	if enemy_data:
		vision_cone = VisionCone.new()
		add_child(vision_cone)
		vision_cone.set_vision_parameters(enemy_data.vision_range, enemy_data.vision_arc, Vector2.LEFT)
		vision_cone.target_groups = ["units"]
		vision_cone.debug_enabled = DebugVisualization.vision_cones_enabled
		
		# Connect vision signals
		vision_cone.target_entered.connect(_on_target_entered)
		vision_cone.target_exited.connect(_on_target_exited)
	
	# Set up screen bounds
	_update_screen_bounds()
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(_update_screen_bounds)

func _physics_process(delta):
	if not is_alive:
		return
	
	# Update speed transition for raccoons and frogs
	_update_speed_transition(delta)
	
	# Update chase target position for slimes
	_update_chase_behavior()
	
	# Update movement using component
	if movement_component:
		movement_component.update_movement(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update sprite direction based on horizontal movement
	_update_sprite_direction()
	
	# Check if enemy is off-screen and should be removed
	_check_screen_bounds()

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

func _update_sprite_direction():
	"""Flip sprite based on movement intent and net effect"""
	if sprite:
		# Get the intended movement direction from the movement component
		var intended_direction = _get_intended_movement_direction()
		
		# If there's an intended direction, use that; otherwise use net velocity
		if intended_direction != 0:
			sprite.flip_h = intended_direction > 0
		else:
			# Fall back to net velocity direction
			sprite.flip_h = velocity.x > 0

func _get_intended_movement_direction() -> float:
	"""Get the intended movement direction, ignoring treadmill effect"""
	var enemy_type = get_enemy_type()
	
	# For slimes chasing, check if they're trying to move right towards target
	if enemy_type == "Slime" and chase_component and chase_component.is_chasing:
		var target_pos = chase_component.chase_target_position
		if target_pos != Vector2.ZERO:
			return sign(target_pos.x - global_position.x)
	
	# For other enemies or when not chasing, use net velocity
	return sign(velocity.x)

func _check_screen_bounds():
	"""Remove enemy if completely off-screen to the left"""
	var camera = get_viewport().get_camera_2d()
	if camera:
		# Get left edge of camera view
		var camera_left = camera.global_position.x - (get_viewport().get_visible_rect().size.x / (2 * camera.zoom.x))
		
		# Destroy enemy when it's completely off-screen (x - 16 pixels past left edge)
		if global_position.x < camera_left - 16:
			if DebugVisualization.debug_mode_enabled:
				print("Despawned ", get_enemy_type(), " for leaving screen at ", global_position)
			_cleanup()

func take_damage(amount: int = 1):
	"""Handle taking damage"""
	if not is_alive:
		return
	
	enemy_data.health -= amount
	if enemy_data.health <= 0:
		die()

func die():
	"""Handle enemy death"""
	if not is_alive:
		return
	
	is_alive = false
	
	# Drop coins before cleanup
	_drop_coins()
	
	enemy_died.emit(self)
	_cleanup()

func _drop_coins():
	"""Drop coins when enemy dies"""
	if enemy_data and enemy_data.coin_drop_count > 0:
		if DebugVisualization.debug_mode_enabled:
			print("💀 ", get_enemy_type(), " dropping ", enemy_data.coin_drop_count, " coins!")
		# Drop the coins using static method
		CoinDropperSystem.drop_coins(
			global_position, 
			enemy_data.coin_drop_count, 
			get_tree(),
			120.0,  # drop_force_min
			180.0,  # drop_force_max
			45.0,   # arc_angle_range
			-15.0   # drop_height_offset
		)

func _cleanup():
	"""Clean up the enemy"""
	queue_free()

func get_enemy_type() -> String:
	"""Return the enemy type name"""
	return enemy_data.enemy_name if enemy_data else "Unknown"

func get_collision_radius() -> float:
	"""Get collision radius for vision line detection"""
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			return collision_shape.shape.radius
		elif collision_shape.shape is RectangleShape2D:
			var rect_shape = collision_shape.shape as RectangleShape2D
			return max(rect_shape.size.x, rect_shape.size.y) / 2.0
	return 8.0  # Default radius

func get_sprite() -> AnimatedSprite2D:
	"""Get the enemy's sprite for gib color sampling"""
	return sprite

func _update_speed_transition(delta: float):
	"""Handle speed transitions for raccoons and frogs"""
	var enemy_type = get_enemy_type()
	if enemy_type != "Raccoon" and enemy_type != "Frog":
		return
	
	# Update speed transition timer
	if speed_transition_timer > 0.0:
		speed_transition_timer -= delta
		
		# Calculate current speed multiplier using smooth interpolation
		var progress = 1.0 - (speed_transition_timer / speed_transition_time)
		progress = clamp(progress, 0.0, 1.0)
		
		# Use smooth step for more natural acceleration
		progress = progress * progress * (3.0 - 2.0 * progress)
		
		var start_multiplier = 1.0
		var end_multiplier = 4.0 if enemy_type == "Raccoon" else 2.0  # Raccoon 4x, Frog 2x
		
		current_speed_multiplier = lerp(start_multiplier, end_multiplier, progress)
		
		# Update enemy data speed for movement component
		if enemy_data:
			enemy_data.move_speed = base_speed * current_speed_multiplier

func _update_chase_behavior():
	"""Update chase and tracking behavior for slimes, cyclopes, frogs, and snakes"""
	var enemy_type = get_enemy_type()
	
	# Update chase behavior for slimes
	if enemy_type == "Slime" and chase_component:
		if last_spotted_target and is_instance_valid(last_spotted_target):
			chase_component.update_chase_target(last_spotted_target.global_position)
	
	# Update tracking behavior for cyclopes
	elif enemy_type == "Cyclope" and tracking_component:
		if last_spotted_target and is_instance_valid(last_spotted_target):
			tracking_component.update_tracking_target(last_spotted_target.global_position.y)
	
	# Update leap-chase behavior for frogs
	elif enemy_type == "Frog" and leap_chase_component:
		if last_spotted_target and is_instance_valid(last_spotted_target):
			leap_chase_component.update_chase_target(last_spotted_target.global_position)
	
	# Update snake tracking behavior
	elif enemy_type == "Snake" and snake_component:
		if last_spotted_target and is_instance_valid(last_spotted_target):
			snake_component.update_tracking_target(last_spotted_target)

func _enter_fast_mode():
	"""Enter fast mode when spotting a unit"""
	if is_in_fast_mode:
		return
	
	var enemy_type = get_enemy_type()
	if DebugVisualization.debug_mode_enabled:
		if enemy_type == "Raccoon":
			print("Raccoon entering fast mode!")
		elif enemy_type == "Frog":
			print("Frog entering fast jump mode!")
	
	is_in_fast_mode = true
	speed_transition_timer = speed_transition_time

func _on_target_entered(target: Node2D):
	"""Handle when a target enters vision cone"""
	if DebugVisualization.debug_mode_enabled:
		print(get_enemy_type(), " spotted target: ", target.name)
	DebugVisualization.add_debug_circle(target)
	
	var enemy_type = get_enemy_type()
	
	# Raccoons enter fast mode when they spot a unit
	if enemy_type == "Raccoon":
		_enter_fast_mode()
	
	# Frogs enter fast mode AND chase mode when they spot a unit
	elif enemy_type == "Frog":
		_enter_fast_mode()
		last_spotted_target = target
		if leap_chase_component:
			leap_chase_component.start_chase(target.global_position)
	
	# Slimes enter chase mode when they spot a unit
	elif enemy_type == "Slime":
		last_spotted_target = target
		if chase_component:
			chase_component.start_chase(target.global_position)
	
	# Cyclopes enter tracking mode when they spot a unit
	elif enemy_type == "Cyclope":
		last_spotted_target = target
		if tracking_component:
			tracking_component.start_tracking(target.global_position.y)
	
	# Snakes enter tracking mode when they spot a unit
	elif enemy_type == "Snake":
		last_spotted_target = target
		if snake_component:
			snake_component.start_tracking(target)

func _on_target_exited(target: Node2D):
	"""Handle when a target exits vision cone"""
	if DebugVisualization.debug_mode_enabled:
		print(get_enemy_type(), " lost sight of target: ", target.name)
	DebugVisualization.remove_debug_circle(target)
	
	# Slimes continue chasing even after losing sight (they remember the last position)
	# This creates interesting behavior where they chase towards where they last saw the target

func update_vision_debug():
	"""Update vision debug settings for this enemy"""
	if vision_cone:
		vision_cone.debug_enabled = DebugVisualization.vision_cones_enabled
