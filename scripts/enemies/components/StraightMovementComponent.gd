extends MovementComponent
class_name StraightMovementComponent

## Straight line movement component (like Slime)

func update_movement(_delta: float):
	# Move left at treadmill speed PLUS additional movement speed
	enemy.velocity.x = -GameController.TREADMILL_SPEED - data.move_speed
	enemy.velocity.y = 0  # No vertical movement
