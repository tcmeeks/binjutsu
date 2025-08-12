extends Node2D
class_name TreadmillManager

## Simple endless sidescrolling treadmill system

@export var camera: Camera2D

# Get settings from GameController
var slice_width: int
var slice_overlap: int = 2  # 2 pixel overlap for seamless transitions

# Slice management
var slice_scenes: Array[PackedScene] = []
var active_slices: Array[Node2D] = []

# Slice paths
var slice_paths = [
	"res://scenes/treadmills/slices/TreadmillSlice0.tscn",
	"res://scenes/treadmills/slices/TreadmillSlice1.tscn",
	"res://scenes/treadmills/slices/TreadmillSlice2.tscn",
	"res://scenes/treadmills/slices/TreadmillSlice3.tscn",
	"res://scenes/treadmills/slices/TreadmillSlice4.tscn"
]

func _ready():
	# Get settings from GameController
	slice_width = GameController.TREADMILL_SLICE_WIDTH
	
	# Get camera reference if not set
	if not camera:
		camera = get_node("../Camera2D")
		if not camera:
			print("ERROR: Could not find camera!")
			return
	
	# Load all slice scenes
	for path in slice_paths:
		var scene = load(path) as PackedScene
		if scene:
			slice_scenes.append(scene)
		else:
			print("Failed to load slice: ", path)
	
	# Spawn initial slices to fill screen
	spawn_initial_slices()

func spawn_initial_slices():
	# Calculate how many slices we need to fill the screen plus buffer
	var screen_width = get_viewport().get_visible_rect().size.x
	var base_slices_needed = ceil(screen_width / slice_width) + 3  # Extra buffer
	
	# Double the slices for more variety
	var slices_needed = base_slices_needed * 2
	
	# Start from left edge of screen
	var start_x = -slice_width
	
	for i in range(slices_needed):
		var slice_instance = slice_scenes[i % slice_scenes.size()].instantiate()
		slice_instance.position.x = start_x + (i * (slice_width - slice_overlap))
		slice_instance.position.y = 0
		add_child(slice_instance)
		active_slices.append(slice_instance)

func _physics_process(delta):
	# Move all slices left using current treadmill speed
	var current_speed = GameController.TREADMILL_SPEED
	for slice in active_slices:
		slice.position.x -= current_speed * delta
	
	# Check if leftmost slice is off-screen and needs to be moved to the right
	if active_slices.size() > 0:
		var leftmost_slice = active_slices[0]
		if leftmost_slice.position.x < -slice_width * 2:
			# Move this slice to the right end
			var rightmost_x = get_rightmost_slice_position()
			leftmost_slice.position.x = rightmost_x + (slice_width - slice_overlap)
			
			# Move it to the end of the array
			active_slices.remove_at(0)
			active_slices.append(leftmost_slice)

func get_rightmost_slice_position() -> float:
	var rightmost_x = -999999.0
	for slice in active_slices:
		if slice.position.x > rightmost_x:
			rightmost_x = slice.position.x
	return rightmost_x

func get_treadmill_speed() -> float:
	return GameController.TREADMILL_SPEED
