extends Node
class_name MovableObject

## Base class for all moving objects in the game
## Provides standardized movement, treadmill integration, and animation handling

signal movement_started(direction: Vector2)
signal movement_stopped()
signal direction_changed(new_direction: Vector2)

@export var movement_enabled: bool = true
@export var use_smooth_movement: bool = true
@export var movement_acceleration: float = 300.0
@export var movement_deceleration: float = 500.0

var target_velocity: Vector2 = Vector2.ZERO
var current_velocity: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.ZERO
var is_moving: bool = false

var treadmill_component: TreadmillAffected
@onready var parent_body: Node2D = get_parent()

func _ready():
	# Create treadmill component
	treadmill_component = TreadmillAffected.new()
	add_child(treadmill_component)
	
	# Connect to treadmill changes
	if treadmill_component:
		treadmill_component.treadmill_speed_changed.connect(_on_treadmill_speed_changed)

func set_target_velocity(velocity: Vector2):
	"""Set the desired velocity for this object"""
	target_velocity = velocity
	
	# Check if we're starting/stopping movement
	var was_moving = is_moving
	is_moving = velocity.length() > 0.1
	
	if is_moving and not was_moving:
		movement_started.emit(velocity.normalized())
	elif not is_moving and was_moving:
		movement_stopped.emit()
	
	# Check for direction changes
	var new_direction = velocity.normalized()
	if new_direction.distance_to(last_direction) > 0.1:
		last_direction = new_direction
		direction_changed.emit(new_direction)

func get_final_velocity() -> Vector2:
	"""Get the final velocity including treadmill effects"""
	var base_velocity = current_velocity if use_smooth_movement else target_velocity
	
	if treadmill_component:
		return treadmill_component.apply_treadmill_to_velocity(base_velocity)
	else:
		return base_velocity

func update_movement(delta: float):
	"""Update movement with optional smoothing"""
	if not movement_enabled:
		current_velocity = Vector2.ZERO
		return
	
	if use_smooth_movement:
		_update_smooth_movement(delta)
	else:
		current_velocity = target_velocity

func _update_smooth_movement(delta: float):
	"""Apply smooth acceleration/deceleration to movement"""
	var velocity_diff = target_velocity - current_velocity
	var distance_to_target = velocity_diff.length()
	
	if distance_to_target < 0.1:
		current_velocity = target_velocity
		return
	
	var direction = velocity_diff.normalized()
	var acceleration = movement_acceleration if target_velocity.length() > current_velocity.length() else movement_deceleration
	
	var max_change = acceleration * delta
	var actual_change = min(max_change, distance_to_target)
	
	current_velocity += direction * actual_change

func apply_to_character_body(body: CharacterBody2D):
	"""Apply the final velocity to a CharacterBody2D"""
	if not body:
		return
	
	body.velocity = get_final_velocity()

func apply_to_rigid_body(body: RigidBody2D):
	"""Apply the final velocity to a RigidBody2D"""
	if not body:
		return
	
	body.linear_velocity = get_final_velocity()

func get_movement_direction() -> Vector2:
	"""Get the current movement direction"""
	return last_direction

func is_object_moving() -> bool:
	"""Check if the object is currently moving"""
	return is_moving

func set_movement_enabled(enabled: bool):
	"""Enable or disable movement for this object"""
	movement_enabled = enabled
	if not enabled:
		set_target_velocity(Vector2.ZERO)

func set_treadmill_enabled(enabled: bool):
	"""Enable or disable treadmill effects"""
	if treadmill_component:
		treadmill_component.set_treadmill_enabled(enabled)

func set_treadmill_multiplier(multiplier: float):
	"""Set how much the treadmill affects this object"""
	if treadmill_component:
		treadmill_component.set_treadmill_multiplier(multiplier)

func _on_treadmill_speed_changed(_new_speed: float):
	"""Handle treadmill speed changes"""
	# Override in derived classes if needed
	pass
