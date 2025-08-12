extends MovementComponent
class_name LeapChaseMovementComponent

## Leap-Chase movement component for frogs - maintains hopping timing but chases when target spotted

var leap_timer: float = 0.0
var is_leaping: bool = false
var leap_duration: float = 0.3  # How long the leap lasts
var still_duration: float = 1.0  # How long to stay still (50% more frequent leaps)
var leap_speed: float = 75.0  # Speed during leap (50% less distance)

# Chase behavior
var chase_target_position: Vector2
var is_chasing: bool = false
var chase_speed_multiplier: float = 2.0  # 2x speed when chasing (from GenericEnemy speed boost)

# Fixed leap direction (set at start of leap, doesn't change during leap)
var leap_direction: Vector2 = Vector2.LEFT

func update_movement(delta: float):
	leap_timer += delta
	
	if is_leaping:
		# During leap: use the fixed leap direction set at the start of the leap
		var leap_velocity = leap_direction * leap_speed
		var treadmill_velocity = Vector2(-GameController.TREADMILL_SPEED, 0)
		
		# Combine leap and treadmill velocities
		enemy.velocity = leap_velocity + treadmill_velocity
		
		# Check if leap is finished
		if leap_timer >= leap_duration:
			is_leaping = false
			leap_timer = 0.0
	else:
		# During still phase: only move with treadmill speed (no chase movement when still)
		enemy.velocity.x = -GameController.TREADMILL_SPEED
		enemy.velocity.y = 0
		
		# Check if it's time to leap
		if leap_timer >= still_duration:
			_start_leap()

func _start_leap():
	"""Start a leap, determining direction based on chase state"""
	is_leaping = true
	leap_timer = 0.0
	
	# Determine leap direction at the START of the leap (doesn't change during leap)
	if is_chasing and chase_target_position != Vector2.ZERO:
		# Calculate direction to target when leap starts
		var direction_to_target = (chase_target_position - enemy.global_position).normalized()
		leap_direction = direction_to_target
		
		# Apply speed boost for chasing
		leap_speed = 75.0 * chase_speed_multiplier
	else:
		# Normal leap behavior (just left)
		leap_direction = Vector2.LEFT
		leap_speed = 75.0

func start_chase(target_position: Vector2):
	"""Start chasing towards the given position"""
	chase_target_position = target_position
	is_chasing = true
	if DebugVisualization.debug_mode_enabled:
		print("Frog starting chase towards: ", target_position)

func stop_chase():
	"""Stop chasing and return to normal leap movement"""
	is_chasing = false
	chase_target_position = Vector2.ZERO
	if DebugVisualization.debug_mode_enabled:
		print("Frog stopped chasing")

func update_chase_target(target_position: Vector2):
	"""Update the chase target position (only affects next leap, not current leap)"""
	if is_chasing:
		chase_target_position = target_position