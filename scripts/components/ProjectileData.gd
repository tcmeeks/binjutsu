extends Resource
class_name ProjectileData

## Data resource defining projectile properties

@export var projectile_name: String
@export var travel_speed: float
@export var damage: int
@export var sprite_frames: SpriteFrames
@export var animation_name: String = "default"
@export var collision_radius: float = 4.0

## Create SpriteFrames from a single texture
static func _create_sprite_frames(texture_path: String) -> SpriteFrames:
	var sprite_frames = SpriteFrames.new()
	var texture = load(texture_path) as Texture2D
	if texture:
		sprite_frames.add_animation("default")
		sprite_frames.add_frame("default", texture)
	return sprite_frames

## Get predefined projectile definitions
static func get_projectile_definitions() -> Dictionary:
	return {
		"kunai": {
			"projectile_name": "Kunai",
			"travel_speed": 300.0,
			"damage": 1,
			"sprite_frames": _create_sprite_frames("res://assets/sprites/attacks/Kunai.png"),
			"animation_name": "default",
			"collision_radius": 3.0
		},
		"shuriken": {
			"projectile_name": "Shuriken",
			"travel_speed": 225.0,
			"damage": 2,
			"sprite_frames": _create_sprite_frames("res://assets/sprites/attacks/Shuriken.png"),
			"animation_name": "default",
			"collision_radius": 4.0
		},
		"arrow": {
			"projectile_name": "Arrow",
			"travel_speed": 450.0,
			"damage": 3,
			"sprite_frames": _create_sprite_frames("res://assets/sprites/attacks/Arrow.png"),
			"animation_name": "default",
			"collision_radius": 2.0
		}
	}

## Create a ProjectileData from definition
static func create_from_definition(projectile_type: String) -> ProjectileData:
	var definitions = get_projectile_definitions()
	if not definitions.has(projectile_type):
		push_error("Unknown projectile type: " + projectile_type)
		return null
	
	var def = definitions[projectile_type]
	var data = ProjectileData.new()
	
	data.projectile_name = def.projectile_name
	data.travel_speed = def.travel_speed
	data.damage = def.damage
	data.sprite_frames = def.sprite_frames
	data.animation_name = def.animation_name
	data.collision_radius = def.collision_radius
	
	return data
