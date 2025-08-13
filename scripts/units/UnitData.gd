extends Resource
class_name UnitData

## Data-driven unit configuration system

# Basic Properties
@export var unit_name: String
@export var move_speed: float = 50.0  # From GameController.PLAYER_BASE_SPEED
@export var health: int = 3

# Visual Properties
@export var sprite_frames: SpriteFrames
@export var default_facing_direction: String = "right"  # Default direction for single-direction units

# Movement Properties
@export var boundary_margin: float = 32.0  # From GameController.UNIT_BOUNDARY_MARGIN
@export var movement_acceleration: float = 400.0  # From current MovableObject setup
@export var movement_deceleration: float = 600.0  # From current MovableObject setup
@export var use_smooth_movement: bool = true

# Combat Properties
@export var attack_range: float = 128.0  # From current projectile_attack setup
@export var attack_speed: float = 1.0
@export var projectile_type: String = "kunai"  # Default projectile
@export var auto_attack: bool = true

# Treadmill Properties
@export var treadmill_effect_multiplier: float = 0.5  # From current implementation

# Collision Properties
@export var collision_radius: float = 8.0  # Estimated from current RectangleShape2D

enum UnitType {
	VILLAGER,
	WARRIOR,
	ARCHER,
	MAGE
}

@export var unit_type: UnitType = UnitType.VILLAGER

# Static unit definitions
static func get_unit_definitions() -> Dictionary:
	return {
		"player": {
			"unit_name": "Player",
			"move_speed": 50.0,
			"health": 3,
			"sprite_frames": load("res://assets/sprites/units/Hunter/HunterAnimations.tres"),
			"default_facing_direction": "right",
			"boundary_margin": 32.0,
			"movement_acceleration": 400.0,
			"movement_deceleration": 600.0,
			"use_smooth_movement": true,
			"attack_range": 128.0,
			"attack_speed": 1.0,
			"projectile_type": "kunai",
			"auto_attack": true,
			"treadmill_effect_multiplier": 0.5,
			"collision_radius": 8.0,
			"unit_type": UnitType.VILLAGER
		}
	}

static func create_unit_data(unit_type: String) -> UnitData:
	var definitions = get_unit_definitions()
	if not definitions.has(unit_type):
		print("ERROR: Unknown unit type: ", unit_type)
		return null
	
	var data = UnitData.new()
	var def = definitions[unit_type]
	
	data.unit_name = def.get("unit_name", "Unknown")
	data.move_speed = def.get("move_speed", 50.0)
	data.health = def.get("health", 3)
	data.sprite_frames = def.get("sprite_frames")
	data.default_facing_direction = def.get("default_facing_direction", "right")
	data.boundary_margin = def.get("boundary_margin", 32.0)
	data.movement_acceleration = def.get("movement_acceleration", 400.0)
	data.movement_deceleration = def.get("movement_deceleration", 600.0)
	data.use_smooth_movement = def.get("use_smooth_movement", true)
	data.attack_range = def.get("attack_range", 128.0)
	data.attack_speed = def.get("attack_speed", 1.0)
	data.projectile_type = def.get("projectile_type", "kunai")
	data.auto_attack = def.get("auto_attack", true)
	data.treadmill_effect_multiplier = def.get("treadmill_effect_multiplier", 0.5)
	data.collision_radius = def.get("collision_radius", 8.0)
	data.unit_type = def.get("unit_type", UnitType.VILLAGER)
	
	return data

## Helper methods for programmatic animation names

func get_walk_animation(direction: String = "") -> String:
	"""Get walk animation name for specified direction, or default if no direction"""
	if direction == "":
		direction = default_facing_direction
	return "walk_" + direction

func get_idle_animation(direction: String = "") -> String:
	"""Get idle animation name for specified direction, or default if no direction"""  
	if direction == "":
		direction = default_facing_direction
	return "idle_" + direction

func get_attack_animation(direction: String = "") -> String:
	"""Get attack animation name for specified direction, or default if no direction"""
	if direction == "":
		direction = default_facing_direction
	return "attack_" + direction

func get_jump_animation(direction: String = "") -> String:
	"""Get jump animation name for specified direction, or default if no direction"""
	if direction == "":
		direction = default_facing_direction
	return "jump_" + direction

func has_directional_animations() -> bool:
	"""Check if this unit's sprite_frames has directional animations"""
	if not sprite_frames:
		return false
	
	# Check if we have directional walk animations
	var animation_list = sprite_frames.get_animation_names()
	return "walk_up" in animation_list and "walk_down" in animation_list and "walk_left" in animation_list and "walk_right" in animation_list
