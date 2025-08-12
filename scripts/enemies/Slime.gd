extends Enemy
class_name Slime

## Slime enemy that moves in a straight line

func _update_movement(_delta):
	"""Slime moves straight left at constant speed"""
	# Move left at treadmill speed PLUS additional movement speed
	velocity.x = -GameController.TREADMILL_SPEED - move_speed
	velocity.y = 0  # No vertical movement

func get_enemy_type() -> String:
	return "Slime"
