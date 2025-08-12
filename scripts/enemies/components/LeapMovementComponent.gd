extends MovementComponent
class_name LeapMovementComponent

## Leap movement component for frogs - still for 2 seconds, then quick leap forward

var leap_timer: float = 0.0
var is_leaping: bool = false
var leap_duration: float = 0.3  # How long the leap lasts
var still_duration: float = 1.0  # How long to stay still (50% more frequent leaps)
var leap_speed: float = 75.0  # Speed during leap (50% less distance)

func update_movement(delta: float):
	leap_timer += delta
	
	if is_leaping:
		# During leap: move fast forward
		enemy.velocity.x = -GameController.TREADMILL_SPEED - leap_speed
		enemy.velocity.y = 0
		
		# Check if leap is finished
		if leap_timer >= leap_duration:
			is_leaping = false
			leap_timer = 0.0
	else:
		# During still phase: only move with treadmill speed
		enemy.velocity.x = -GameController.TREADMILL_SPEED
		enemy.velocity.y = 0
		
		# Check if it's time to leap
		if leap_timer >= still_duration:
			is_leaping = true
			leap_timer = 0.0