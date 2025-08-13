extends RigidBody2D
class_name GibParticle

## Physics-based gib particle that bounces and fades out over time

@onready var sprite: Sprite2D = $Sprite2D
@onready var treadmill_component: TreadmillAffected

var particle_color: Color = Color.WHITE
var lifespan: float = 2.0
var fade_start_time: float = 0.5
var time_alive: float = 0.0
var bounce_count: int = 0
var max_bounces: int = 3
var ground_y: float = 0.0
var is_settled: bool = false
var fade_tween: Tween

func _ready():
	# Set up treadmill component
	treadmill_component = TreadmillAffected.new()
	add_child(treadmill_component)
	treadmill_component.treadmill_enabled = false  # Disabled while bouncing
	treadmill_component.treadmill_direction = -1  # Leftward movement
	
	# Set up physics properties for bouncing (similar to coin)
	gravity_scale = 1.0
	
	# No collision detection - gibs use manual ground logic and pass through everything
	collision_layer = 0  # No collision layer
	collision_mask = 0   # No collision mask - pass through everything
	
	# Render gibs above background but below gameplay objects
	z_index = 1
	
	# Create 3x3 pixel visual
	_create_gib_visual()
	
	# No collision shape needed - gibs pass through everything
	
	# Start fade timer
	_start_fade_sequence()

func _create_gib_visual():
	"""Create a 3x3 pixel colored square"""
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	
	# Create a 3x3 texture
	var image = Image.create(3, 3, false, Image.FORMAT_RGBA8)
	image.fill(particle_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture


func _start_fade_sequence():
	"""Start the 2-second fade sequence"""
	fade_tween = create_tween()
	
	# Wait for fade_start_time before beginning fade
	fade_tween.tween_interval(fade_start_time)
	
	# Fade alpha from 1.0 to 0.0 over remaining time
	var fade_duration = lifespan - fade_start_time
	fade_tween.tween_method(_update_alpha, 1.0, 0.0, fade_duration)
	
	# Clean up after lifespan
	fade_tween.tween_callback(queue_free)

func _update_alpha(alpha: float):
	"""Update the sprite alpha"""
	if sprite:
		sprite.modulate.a = alpha

func _physics_process(delta):
	time_alive += delta
	
	# Clean up if somehow we exceed lifespan
	if time_alive > lifespan:
		queue_free()
		return
	
	# Clean up gibs that have moved too far off-screen to the left
	var camera = get_viewport().get_camera_2d()
	if camera and global_position.x < camera.global_position.x - 400:
		queue_free()
		return
	
	# Apply treadmill effect when settled
	if is_settled and treadmill_component:
		treadmill_component.apply_treadmill_to_rigidbody(self)
		linear_velocity.y = 0  # Keep settled gibs on ground
		return
	
	# Enforce ground plane - don't let gib fall below ground level
	if global_position.y > ground_y:
		global_position.y = ground_y
		# Bounce off ground if moving downward
		if linear_velocity.y > 0:
			bounce_count += 1
			linear_velocity.y = -linear_velocity.y * 0.4  # Less bouncy than coins
			linear_velocity.x *= 0.7  # More friction
			
			# Settle after a few bounces or if moving slowly
			if bounce_count >= max_bounces or linear_velocity.length() < 20.0:
				_settle_gib()

func _settle_gib():
	"""Make gib settle on ground"""
	if is_settled:
		return
	
	is_settled = true
	
	# Stop rotation and movement
	angular_velocity = 0.0
	linear_velocity.y = 0.0
	global_position.y = ground_y
	
	# Reduce physics impact
	gravity_scale = 0.0
	linear_damp = 0.0
	
	# Enable treadmill component
	if treadmill_component:
		treadmill_component.treadmill_enabled = true

func launch(initial_velocity: Vector2, ground_level: float, color: Color = Color.WHITE):
	"""Launch the gib with initial velocity, ground level, and color"""
	linear_velocity = initial_velocity
	angular_velocity = randf_range(-15.0, 15.0)  # More chaotic spin than coins
	ground_y = ground_level
	particle_color = color
	
	# Update visual with the new color
	_create_gib_visual()
