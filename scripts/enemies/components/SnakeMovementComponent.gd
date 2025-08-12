extends MovementComponent
class_name SnakeMovementComponent

## Snake movement component - discrete vertical movements with target tracking

var movement_timer: float = 0.0
var movement_interval: float = 2.0  # Time between vertical movements
var is_moving_vertically: bool = false
var vertical_movement_duration: float = 0.5  # Time to complete vertical movement

# Movement state
var current_direction: int = 1  # 1 for up, -1 for down
var target_y: float = 0.0
var start_y: float = 0.0
var movement_distance: float = 16.0  # Will be 16 or 32

# Tracking behavior
var tracking_target: Node2D
var is_tracking: bool = false

func initialize(enemy_ref: CharacterBody2D, enemy_data: EnemyData):
	super.initialize(enemy_ref, enemy_data)
	start_y = enemy.global_position.y
	target_y = start_y
	# Randomize initial direction
	current_direction = 1 if randf() > 0.5 else -1

func update_movement(delta: float):
	# Horizontal movement (left) - treadmill speed PLUS additional movement speed
	enemy.velocity.x = -GameController.TREADMILL_SPEED - data.move_speed
	
	movement_timer += delta
	
	if is_moving_vertically:
		# Currently moving vertically - lerp to target position
		var progress = (movement_interval - movement_timer + vertical_movement_duration) / vertical_movement_duration
		progress = clamp(1.0 - progress, 0.0, 1.0)
		
		# Use smooth step for natural movement
		progress = progress * progress * (3.0 - 2.0 * progress)
		
		var current_y = lerp(start_y, target_y, progress)
		enemy.velocity.y = (current_y - enemy.global_position.y) / delta
		
		# Check if movement is complete
		if progress >= 1.0:
			is_moving_vertically = false
			enemy.global_position.y = target_y
			enemy.velocity.y = 0
	else:
		# Not moving vertically
		enemy.velocity.y = 0
		
		# Check if it's time to start next movement
		if movement_timer >= movement_interval:
			_start_vertical_movement()

func _start_vertical_movement():
	"""Start a new vertical movement"""
	movement_timer = 0.0
	is_moving_vertically = true
	start_y = enemy.global_position.y
	
	# Determine movement distance (16px or 32px)
	if is_tracking and tracking_target and is_instance_valid(tracking_target):
		movement_distance = _calculate_optimal_distance()
	else:
		# Normal behavior - alternate between 16px and 32px randomly
		movement_distance = 16.0 if randf() > 0.5 else 32.0
	
	# Calculate target position
	target_y = start_y + (current_direction * movement_distance)
	
	# Flip direction for next movement
	current_direction *= -1
	
	if DebugVisualization.debug_mode_enabled:
		print("Snake moving ", movement_distance, "px ", "up" if current_direction == -1 else "down")

func _calculate_optimal_distance() -> float:
	"""Calculate whether 16px or 32px gets closer to target"""
	if not tracking_target or not is_instance_valid(tracking_target):
		return 16.0
	
	var target_unit_y = tracking_target.global_position.y
	var current_y = enemy.global_position.y
	
	# Calculate distances for both options
	var option_16_y = current_y + (current_direction * 16.0)
	var option_32_y = current_y + (current_direction * 32.0)
	
	var distance_16 = abs(target_unit_y - option_16_y)
	var distance_32 = abs(target_unit_y - option_32_y)
	
	# Choose the distance that gets closer to target
	return 16.0 if distance_16 < distance_32 else 32.0

func start_tracking(target: Node2D):
	"""Start tracking a target unit"""
	tracking_target = target
	is_tracking = true
	if DebugVisualization.debug_mode_enabled:
		print("Snake started tracking: ", target.name)

func stop_tracking():
	"""Stop tracking and return to normal movement"""
	tracking_target = null
	is_tracking = false
	if DebugVisualization.debug_mode_enabled:
		print("Snake stopped tracking")

func update_tracking_target(target: Node2D):
	"""Update the tracking target"""
	if is_tracking:
		tracking_target = target