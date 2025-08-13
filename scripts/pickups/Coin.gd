extends RigidBody2D
class_name Coin

## Physics-based bouncing coin that settles after bouncing

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var collection_area: Area2D = $CollectionArea
@onready var collection_collision: CollisionShape2D = $CollectionArea/CollisionShape2D
@onready var treadmill_component: TreadmillAffected

var is_collected: bool = false
var settle_timer: float = 0.0
var settle_threshold: float = 0.5  # Time before coin settles
var velocity_threshold: float = 15.0  # More forgiving threshold for settling
var bounce_count: int = 0  # Count bounces to determine settling
var max_bounces: int = 3  # Settle after this many bounces
var ground_y: float = 0.0  # Ground plane Y position
var is_settled: bool = false
var rotation_tween: Tween
var treadmill_speed: float = 50.0  # Treadmill scroll speed (matches GameController)

# Magnetism system
var is_magnetized: bool = false
var magnet_target: Node2D = null
var magnet_speed: float = 200.0  # Speed when moving toward unit
var collection_distance: float = 4.0  # Distance at which coin gets collected

signal coin_collected(coin: Coin)

func _ready():
	# Set up treadmill component
	treadmill_component = TreadmillAffected.new()
	add_child(treadmill_component)
	treadmill_component.treadmill_enabled = false  # Disabled while bouncing
	treadmill_component.treadmill_direction = -1  # Leftward movement (default)
	
	# Set up physics properties for bouncing
	gravity_scale = 1.0
	
	# No physical collision - coins pass through everything but still detect ground manually
	collision_layer = 0  # No collision layer
	collision_mask = 0   # No collision mask - pass through everything
	
	# Connect collection area
	collection_area.body_entered.connect(_on_collection_area_entered)
	collection_area.body_exited.connect(_on_collection_area_exited)
	collection_area.collision_layer = 0
	collection_area.collision_mask = 2  # Player layer
	
	# Enable collection area from the start
	collection_area.monitoring = true
	
	# Start coin visual effect (simple rotation animation)
	if sprite:
		_start_rotation_animation()

func _physics_process(delta):
	if is_collected:
		return
	
	# Handle magnetism to unit center
	if is_magnetized and magnet_target and is_instance_valid(magnet_target):
		_update_magnetism(delta)
		return  # Skip normal physics when magnetized
	
	# Clean up coins that have moved too far off-screen to the left
	var camera = get_viewport().get_camera_2d()
	if camera and global_position.x < camera.global_position.x - 400:  # 400px buffer
		queue_free()
		return
	
	# Apply treadmill effect when settled using component
	if is_settled and treadmill_component:
		treadmill_component.apply_treadmill_to_rigidbody(self)
		linear_velocity.y = 0  # Keep settled coins on ground
		return  # Skip physics processing when settled
	
	# Enforce ground plane - don't let coin fall below ground level
	if global_position.y > ground_y:
		global_position.y = ground_y
		# Bounce off ground if moving downward
		if linear_velocity.y > 0:
			bounce_count += 1
			linear_velocity.y = -linear_velocity.y * 0.5  # Bounce with energy loss
			# Add some horizontal friction when bouncing on ground
			linear_velocity.x *= 0.8
	
	# Check if coin has settled - use bounce count and velocity
	var is_on_ground = abs(global_position.y - ground_y) < 1.0
	var is_slow = linear_velocity.length() < velocity_threshold
	
	# Settle if we've bounced enough times OR if slow and on ground for a bit
	if not is_settled:
		if bounce_count >= max_bounces:
			_settle_coin()
		elif is_on_ground and is_slow:
			settle_timer += delta
			if settle_timer >= settle_threshold:
				_settle_coin()
		elif not (is_on_ground and is_slow):
			settle_timer = 0.0

func launch(initial_velocity: Vector2, ground_level: float):
	"""Launch the coin with initial velocity and set ground plane"""
	linear_velocity = initial_velocity
	angular_velocity = randf_range(-10.0, 10.0)  # Random spin
	ground_y = ground_level

func _settle_coin():
	"""Make coin settle and become purely collectible"""
	if is_settled:  # Prevent multiple calls
		return
		
	is_settled = true
	
	# Stop rotation animation properly
	if rotation_tween:
		rotation_tween.kill()
		rotation_tween = null
	
	# Reset the RigidBody2D's rotation to 0 (this is the key fix)
	rotation = 0.0
	
	# Set sprite rotation to 0 (upright) - redundant but safe
	if sprite:
		sprite.rotation = 0.0
	
	# Stop any remaining rotation
	angular_velocity = 0.0
	
	# Lock rotation to prevent future wiggling
	lock_rotation = true
	
	# Stop all vertical movement and position on ground
	linear_velocity.y = 0.0
	global_position.y = ground_y
	
	# Disable gravity and physics when settled
	gravity_scale = 0.0
	linear_damp = 0.0  # Don't damp treadmill movement
	
	# Enable treadmill component now that coin is settled
	if treadmill_component:
		treadmill_component.treadmill_enabled = true
	
	# Coin settled

func _on_collection_area_entered(body):
	"""Handle coin magnetism trigger"""
	if is_collected or is_magnetized:
		return
	
	if body.is_in_group("units"):  # Start magnetism toward unit
		start_magnetism(body)
	else:
		pass  # Body is not in units group

func _on_collection_area_exited(body):
	"""Handle unit leaving collection area - but don't stop magnetism once started"""
	# Once magnetism starts, it continues until collection or cleanup
	pass

func start_magnetism(target: Node2D):
	"""Start magnetizing coin toward target unit"""
	is_magnetized = true
	magnet_target = target
	
	# Disable physics when magnetized
	if treadmill_component:
		treadmill_component.treadmill_enabled = false
	gravity_scale = 0.0
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _update_magnetism(delta: float):
	"""Update magnetism movement toward target"""
	if not magnet_target or not is_instance_valid(magnet_target):
		return
	
	# Calculate direction to target center
	var target_pos = magnet_target.global_position
	var direction = (target_pos - global_position).normalized()
	var distance = global_position.distance_to(target_pos)
	
	# Check if close enough to collect
	if distance <= collection_distance:
		collect()
		return
	
	# Move toward target
	global_position += direction * magnet_speed * delta

func collect():
	"""Collect the coin"""
	if is_collected:
		return
	
	is_collected = true
	coin_collected.emit(self)
	
	# Play collection effect (could add sound/particles here)
	_play_collection_effect()
	
	# Remove coin
	queue_free()

func _start_rotation_animation():
	"""Start the rotation animation loop"""
	if not sprite or is_settled:
		return
		
	rotation_tween = create_tween()
	rotation_tween.tween_property(sprite, "rotation", sprite.rotation + PI * 2, 1.0)
	rotation_tween.tween_callback(func(): 
		if not is_settled:  # Only continue if not settled
			_start_rotation_animation()
	)

func _play_collection_effect():
	"""Play visual/audio effects for collection"""
	# Could add particle effects, sound, etc.
	pass
