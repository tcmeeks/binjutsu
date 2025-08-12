extends MovementComponent
class_name ChaseMovementComponent

## Chase movement component - moves towards last spotted target

var chase_target_position: Vector2
var is_chasing: bool = false
var chase_speed_multiplier: float = 1.5  # Slightly faster when chasing

func update_movement(_delta: float):
	if is_chasing and chase_target_position != Vector2.ZERO:
		# Calculate direction to target
		var direction_to_target = (chase_target_position - enemy.global_position).normalized()
		
		# Apply chase movement (towards target)
		var chase_velocity = direction_to_target * data.move_speed * chase_speed_multiplier
		
		# Always apply treadmill effect (moving left)
		var treadmill_velocity = Vector2(-GameController.TREADMILL_SPEED, 0)
		
		# Combine chase and treadmill velocities
		enemy.velocity = chase_velocity + treadmill_velocity
	else:
		# Default straight movement when not chasing
		enemy.velocity.x = -GameController.TREADMILL_SPEED - data.move_speed
		enemy.velocity.y = 0

func start_chase(target_position: Vector2):
	"""Start chasing towards the given position"""
	chase_target_position = target_position
	is_chasing = true
	if DebugVisualization.debug_mode_enabled:
		print("Starting chase towards: ", target_position)

func stop_chase():
	"""Stop chasing and return to normal movement"""
	is_chasing = false
	chase_target_position = Vector2.ZERO
	if DebugVisualization.debug_mode_enabled:
		print("Stopped chasing")

func update_chase_target(target_position: Vector2):
	"""Update the chase target position"""
	if is_chasing:
		chase_target_position = target_position
