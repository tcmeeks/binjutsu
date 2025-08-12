extends MovementComponent
class_name TrackingMovementComponent

## Tracking movement component - moves vertically to align with spotted targets (like Cyclope)

var tracking_target_y: float = 0.0
var is_tracking: bool = false
var tracking_tolerance: float = 5.0  # Stop tracking when within this distance
var tracking_speed_multiplier: float = 3.0  # 3x faster vertical movement when tracking

func update_movement(_delta: float):
	# Always move left with treadmill
	enemy.velocity.x = -GameController.TREADMILL_SPEED - data.move_speed
	
	if is_tracking:
		# Calculate vertical movement to align with target
		var current_y = enemy.global_position.y
		var distance_to_target_y = tracking_target_y - current_y
		
		# Only move if we're not close enough to the target Y position
		if abs(distance_to_target_y) > tracking_tolerance:
			# Move towards target Y at 3x movement speed for fast tracking
			var direction = sign(distance_to_target_y)
			enemy.velocity.y = direction * data.move_speed * tracking_speed_multiplier
		else:
			# Close enough, stop vertical movement
			enemy.velocity.y = 0
	else:
		# No vertical movement when not tracking
		enemy.velocity.y = 0

func start_tracking(target_y: float):
	"""Start tracking the Y position of a target"""
	tracking_target_y = target_y
	is_tracking = true
	if DebugVisualization.debug_mode_enabled:
		print("Starting Y tracking towards: ", target_y)

func stop_tracking():
	"""Stop tracking and return to normal movement"""
	is_tracking = false
	tracking_target_y = 0.0
	if DebugVisualization.debug_mode_enabled:
		print("Stopped Y tracking")

func update_tracking_target(target_y: float):
	"""Update the tracking target Y position"""
	if is_tracking:
		tracking_target_y = target_y
