extends Node
class_name TreadmillAffected

## Component that handles treadmill integration for any moving object
## Attach this to any node that should be affected by the treadmill

signal treadmill_speed_changed(new_speed: float)

@export var treadmill_enabled: bool = true
@export var treadmill_multiplier: float = 1.0  # How much treadmill affects this object
@export var treadmill_direction: int = -1  # -1 for leftward (coins), +1 for rightward (units)

var parent_body: Node
var last_treadmill_speed: float = 0.0

func _ready():
	parent_body = get_parent()
	if not parent_body:
		push_error("TreadmillAffected component requires a parent node")
		return
	
	# Connect to treadmill speed changes if available
	if GameController:
		last_treadmill_speed = GameController.TREADMILL_SPEED

func get_treadmill_velocity() -> Vector2:
	"""Get the velocity vector that should be applied due to treadmill movement"""
	if not treadmill_enabled:
		return Vector2.ZERO
	
	var current_speed = GameController.TREADMILL_SPEED if GameController else 0.0
	return Vector2(treadmill_direction * current_speed * treadmill_multiplier, 0.0)

func apply_treadmill_to_velocity(base_velocity: Vector2) -> Vector2:
	"""Apply treadmill effect to a base velocity vector"""
	return base_velocity + get_treadmill_velocity()

func apply_treadmill_to_rigidbody(body: RigidBody2D):
	"""Apply treadmill effect directly to a RigidBody2D's linear_velocity"""
	if not treadmill_enabled or not body:
		return
	
	var treadmill_vel = get_treadmill_velocity()
	body.linear_velocity.x = treadmill_vel.x

func apply_treadmill_to_characterbody(body: CharacterBody2D) -> Vector2:
	"""Apply treadmill effect to CharacterBody2D velocity and return the result"""
	if not treadmill_enabled or not body:
		return body.velocity if body else Vector2.ZERO
	
	return apply_treadmill_to_velocity(body.velocity)

func set_treadmill_enabled(enabled: bool):
	"""Enable or disable treadmill effects for this object"""
	treadmill_enabled = enabled

func set_treadmill_multiplier(multiplier: float):
	"""Set how much the treadmill affects this object (1.0 = normal, 0.5 = half effect, etc.)"""
	treadmill_multiplier = multiplier

func _physics_process(_delta):
	"""Monitor treadmill speed changes"""
	if GameController:
		var current_speed = GameController.TREADMILL_SPEED
		if current_speed != last_treadmill_speed:
			last_treadmill_speed = current_speed
			treadmill_speed_changed.emit(current_speed)
