extends Node2D
class_name EnemySpawner

## Spawns enemies randomly in the treadmill test scene using data-driven system

# Get settings from GameController
var spawn_interval_min: float
var spawn_interval_max: float
var spawn_height_range: float

var available_enemy_types: Array[String] = []
var spawn_timer: Timer
var camera: Camera2D

func _ready():
	# Get settings from GameController
	spawn_interval_min = GameController.ENEMY_SPAWN_INTERVAL_MIN
	spawn_interval_max = GameController.ENEMY_SPAWN_INTERVAL_MAX
	spawn_height_range = GameController.ENEMY_SPAWN_HEIGHT_RANGE
	
	# Get available enemy types from factory
	available_enemy_types = EnemyFactory.get_available_enemy_types()
	
	if available_enemy_types.is_empty():
		print("ERROR: No enemy types available!")
		return
	
	# Get camera reference
	camera = get_viewport().get_camera_2d()
	if not camera:
		print("ERROR: Could not find camera for enemy spawning!")
		return
	
	# Set up spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.autostart = true
	add_child(spawn_timer)
	
	if DebugVisualization.debug_mode_enabled:
		print("EnemySpawner initialized with ", available_enemy_types.size(), " enemy types: ", available_enemy_types)

func _spawn_enemy():
	if available_enemy_types.is_empty() or not camera:
		return
	
	# Choose random enemy type
	var enemy_type = available_enemy_types[randi() % available_enemy_types.size()]
	var enemy_instance = EnemyFactory.create_enemy(enemy_type)
	
	if not enemy_instance:
		print("ERROR: Failed to create enemy of type: ", enemy_type)
		return
	
	# Grid-based spawning: spawn on 16px grid tiles
	# Spawn on column 40 (x = 40 * 16 = 640px) and rows 9-19 (road area)
	var grid_x = 40  # Column 40 (off-screen right)
	var grid_y = randi_range(9, 19)  # Random row between 9 and 19 (road area)
	
	# Convert grid coordinates to world coordinates
	var spawn_x = grid_x * 16.0
	var spawn_y = grid_y * 16.0
	
	enemy_instance.global_position = Vector2(spawn_x, spawn_y)
	
	# Add enemy to scene
	get_parent().add_child(enemy_instance)
	
	# Connect death signal for cleanup
	enemy_instance.enemy_died.connect(_on_enemy_died)
	
	# Set next spawn time
	spawn_timer.wait_time = randf_range(spawn_interval_min, spawn_interval_max)
	spawn_timer.start()
	
	if DebugVisualization.debug_mode_enabled:
		print("Spawned ", enemy_instance.get_enemy_type(), " at grid (", grid_x, ",", grid_y, ") world pos ", enemy_instance.global_position)

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death"""
	if DebugVisualization.debug_mode_enabled:
		print(enemy.get_enemy_type(), " died")

func set_spawn_rate(min_interval: float, max_interval: float):
	"""Adjust spawn rate"""
	spawn_interval_min = min_interval
	spawn_interval_max = max_interval
