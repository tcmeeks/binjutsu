extends Enemy
class_name Snake

## Snake enemy that moves in a predictable sine wave pattern

@export var amplitude: float = 30.0  # How high/low the sine wave goes
@export var frequency: float = 2.0    # How fast the sine wave oscillates

var time_offset: float = 0.0
var start_y: float = 0.0

func _ready():
	super._ready()
	# Record starting Y position for sine wave calculation
	start_y = global_position.y
	# Add random time offset so snakes don't all move in sync
	time_offset = randf() * PI * 2

func _update_movement(_delta):
	"""Snake moves left with sine wave vertical movement"""
	# Horizontal movement (left) - treadmill speed PLUS additional movement speed
	velocity.x = -GameController.TREADMILL_SPEED - move_speed
	
	# Vertical sine wave movement
	var time = Time.get_time_dict_from_system()
	var elapsed_time = time.second + time.minute * 60.0 + time_offset
	var target_y = start_y + sin(elapsed_time * frequency) * amplitude
	
	# Smooth vertical movement toward sine wave position
	var current_y = global_position.y
	var y_diff = target_y - current_y
	velocity.y = y_diff * 3.0  # Adjust multiplier for smoother/snappier movement

func get_enemy_type() -> String:
	return "Snake"
