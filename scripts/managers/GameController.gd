extends Node

## Central game controller that manages global game settings and constants

# Game Speed Settings
const BASE_TREADMILL_SPEED: float = 50.0  # Base pixels per second for treadmill and enemy movement
static var TREADMILL_SPEED: float = 50.0  # Current treadmill speed (dynamic)

# Player Settings
const PLAYER_BASE_SPEED: float = 50.0
const PLAYER_TREADMILL_FORWARD_MULTIPLIER: float = 0.8  # Moving with treadmill (slower)
const PLAYER_TREADMILL_BACKWARD_MULTIPLIER: float = 2.0  # Moving against treadmill (faster)

# Screen and Boundary Settings
const UNIT_BOUNDARY_MARGIN: float = 16.0  # Margin from screen edges for units

# Enemy Settings
const ENEMY_BASE_HEALTH: int = 1
const ENEMY_SPAWN_INTERVAL_MIN: float = 2.0
const ENEMY_SPAWN_INTERVAL_MAX: float = 5.0
const ENEMY_SPAWN_HEIGHT_RANGE: float = 100.0

# Treadmill Settings
const TREADMILL_SLICE_WIDTH: int = 128  # Width of each slice in pixels (8 tiles * 16px)

# Debug Settings (using existing DebugVisualization system)

# Treadmill Control
var treadmill_running: bool = true  # Current treadmill state
var target_treadmill_speed: float = BASE_TREADMILL_SPEED  # Target speed to lerp to
var start_treadmill_speed: float = BASE_TREADMILL_SPEED  # Speed at start of transition
var treadmill_transition_time: float = 3.0  # Time to transition between speeds
var treadmill_transition_timer: float = 0.0  # Current transition timer



func _ready():
	print("GameController initialized with TREADMILL_SPEED: ", TREADMILL_SPEED)
	# Initialize static variable
	TREADMILL_SPEED = BASE_TREADMILL_SPEED
	target_treadmill_speed = BASE_TREADMILL_SPEED

func _physics_process(delta):
	_handle_input()
	_update_treadmill_speed(delta)

func _handle_input():
	"""Handle input for treadmill control"""
	# Use direct key input event handling instead of ui_accept to avoid Enter key
	pass  # Input handling moved to _input() method

func _input(event):
	"""Handle input events for treadmill control"""
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		toggle_treadmill()
		get_viewport().set_input_as_handled()


func toggle_treadmill():
	"""Toggle treadmill between running and stopped"""
	treadmill_running = !treadmill_running
	start_treadmill_speed = TREADMILL_SPEED  # Store current speed as start
	target_treadmill_speed = BASE_TREADMILL_SPEED if treadmill_running else 0.0
	treadmill_transition_timer = treadmill_transition_time
	
	print("Treadmill toggled: ", "RUNNING" if treadmill_running else "STOPPED")
	print("Transitioning from ", start_treadmill_speed, " to ", target_treadmill_speed)

func _update_treadmill_speed(delta: float):
	"""Update treadmill speed with smooth transition"""
	if treadmill_transition_timer > 0.0:
		treadmill_transition_timer -= delta
		
		# Calculate transition progress (0.0 to 1.0)
		var progress = 1.0 - (treadmill_transition_timer / treadmill_transition_time)
		progress = clamp(progress, 0.0, 1.0)
		
		# Use smooth step for natural transition
		progress = progress * progress * (3.0 - 2.0 * progress)
		
		# Lerp from start speed to target speed
		TREADMILL_SPEED = lerp(start_treadmill_speed, target_treadmill_speed, progress)
