extends Resource
class_name EnemyData

## Data-driven enemy configuration system

# Basic Properties
@export var enemy_name: String
@export var move_speed: float = 30.0
@export var health: int = 3

# Visual Properties
@export var sprite_frames: SpriteFrames
@export var animation_name: String = "move_left"

# Movement Behavior
@export var movement_type: MovementType = MovementType.STRAIGHT
@export var sine_amplitude: float = 30.0
@export var sine_frequency: float = 2.0

# Vision Cone Settings
@export var vision_range: float = 128.0
@export var vision_arc: float = 110.0

# Coin Drop Settings
@export var coin_drop_count: int = 2

enum MovementType {
	STRAIGHT,
	SINE_WAVE,
	LEAP,
	CHASE,
	TRACKING,
	LEAP_CHASE,
	SNAKE
}

# Static enemy definitions
static func get_enemy_definitions() -> Dictionary:
	return {
		"slime": {
			"enemy_name": "Slime",
			"move_speed": 25.0,
			"health": 1,
			"sprite_frames": load("res://assets/sprites/enemies/Slime/Slime.tres"),
			"animation_name": "move_left",
			"movement_type": MovementType.CHASE,
			"vision_range": 128.0,
			"vision_arc": 110.0,
			"coin_drop_count": 1
		},
		"snake": {
			"enemy_name": "Snake", 
			"move_speed": 40.0,
			"health": 1,
			"sprite_frames": load("res://assets/sprites/enemies/Snake/Snake.tres"),
			"animation_name": "move_left",
			"movement_type": MovementType.SNAKE,
			"vision_range": 96.0,
			"vision_arc": 60.0,
			"coin_drop_count": 2
		},
		"raccoon": {
			"enemy_name": "Raccoon",
			"move_speed": 30.0,  # Base speed (will double to 60 when spotting units)
			"health": 1,
			"sprite_frames": load("res://assets/sprites/enemies/Racoon/Racoon.tres"),
			"animation_name": "move_left",
			"movement_type": MovementType.STRAIGHT,
			"vision_range": 160.0,
			"vision_arc": 0.0,  # Line-based vision
			"coin_drop_count": 2
		},
		"frog": {
			"enemy_name": "Frog",
			"move_speed": 30.0,  # Default speed
			"health": 3,  # Default health
			"sprite_frames": load("res://assets/sprites/enemies/KappaGreen/KappaGreen.tres"),
			"animation_name": "move_left",
			"movement_type": MovementType.LEAP_CHASE,
			"vision_range": 128.0,
			"vision_arc": 110.0,
			"coin_drop_count": 3
		},
		"cyclope": {
			"enemy_name": "Cyclope",
			"move_speed": 15.0,  # Slow speed (used for both horizontal and vertical movement)
			"health": 5,
			"sprite_frames": load("res://assets/sprites/enemies/Cyclope/Cyclope.tres"),
			"animation_name": "move_left",
			"movement_type": MovementType.TRACKING,
			"vision_range": 200.0,
			"vision_arc": 0.0,  # Laser vision - straight line
			"coin_drop_count": 5
		}
	}

static func create_enemy_data(enemy_type: String) -> EnemyData:
	var definitions = get_enemy_definitions()
	if not definitions.has(enemy_type):
		print("ERROR: Unknown enemy type: ", enemy_type)
		return null
	
	var data = EnemyData.new()
	var def = definitions[enemy_type]
	
	data.enemy_name = def.get("enemy_name", "Unknown")
	data.move_speed = def.get("move_speed", 30.0)
	data.health = def.get("health", 3)
	data.sprite_frames = def.get("sprite_frames")
	data.animation_name = def.get("animation_name", "move_left")
	data.movement_type = def.get("movement_type", MovementType.STRAIGHT)
	data.sine_amplitude = def.get("sine_amplitude", 30.0)
	data.sine_frequency = def.get("sine_frequency", 2.0)
	data.vision_range = def.get("vision_range", 128.0)
	data.vision_arc = def.get("vision_arc", 110.0)
	data.coin_drop_count = def.get("coin_drop_count", 2)
	
	return data
