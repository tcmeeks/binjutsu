extends MovementComponent
class_name SineWaveMovementComponent

## Sine wave movement component (like Snake)

var time_offset: float = 0.0
var start_y: float = 0.0

func initialize(enemy_ref: CharacterBody2D, enemy_data: EnemyData):
	super.initialize(enemy_ref, enemy_data)
	# Record starting Y position for sine wave calculation
	start_y = enemy.global_position.y
	# Add random time offset so enemies don't all move in sync
	time_offset = randf() * PI * 2

func update_movement(_delta: float):
	# Horizontal movement (left) - treadmill speed PLUS additional movement speed
	enemy.velocity.x = -GameController.TREADMILL_SPEED - data.move_speed
	
	# Vertical sine wave movement
	var time = Time.get_time_dict_from_system()
	var elapsed_time = time.second + time.minute * 60.0 + time_offset
	var target_y = start_y + sin(elapsed_time * data.sine_frequency) * data.sine_amplitude
	
	# Smooth vertical movement toward sine wave position
	var current_y = enemy.global_position.y
	var y_diff = target_y - current_y
	enemy.velocity.y = y_diff * 3.0  # Adjust multiplier for smoother/snappier movement
