extends Area2D
class_name Projectile

## Reusable projectile that can be configured with ProjectileData

signal hit_target(target: Node2D, damage: int)
signal projectile_expired(projectile: Projectile)

var data: ProjectileData
var direction: Vector2
var shooter: Node2D
var is_active: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# Connect area signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Set collision layer/mask for projectiles
	collision_layer = 4  # Projectile layer
	collision_mask = 1 + 2   # Default layer (1) + Enemy layer (2) to hit both CharacterBody2D and Area2D enemies

func _physics_process(delta):
	if not is_active or not data:
		return
	
	# Move projectile
	global_position += direction * data.travel_speed * delta
	
	# Check if projectile is off-screen
	if _is_off_screen():
		expire()

func configure(projectile_data: ProjectileData, start_position: Vector2, target_direction: Vector2, source: Node2D):
	"""Configure the projectile with data and initial state"""
	data = projectile_data
	direction = target_direction.normalized()
	shooter = source
	global_position = start_position
	is_active = true
	
	# Configure sprite
	if data.sprite_frames and data.sprite_frames.has_animation(data.animation_name):
		sprite.sprite_frames = data.sprite_frames
		sprite.play(data.animation_name)
		
		# Rotate sprite to face movement direction
		# Sprite faces right by default, so calculate angle from right (0 degrees)
		var angle = direction.angle()
		sprite.rotation = angle
		
		if DebugVisualization.debug_mode_enabled:
			print("Configured projectile sprite with ", data.projectile_name, " facing angle: ", rad_to_deg(angle))
	else:
		# Use a simple colored rectangle as placeholder
		if DebugVisualization.debug_mode_enabled:
			print("Using placeholder sprite for ", data.projectile_name if data else "unknown projectile")
		_create_placeholder_sprite()
	
	# Configure collision shape
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = data.collision_radius
	collision_shape.shape = circle_shape
	
	# Show the projectile
	visible = true

func _create_placeholder_sprite():
	"""Create a simple placeholder sprite when no sprite frames are provided"""
	# Remove animated sprite and create a simple ColorRect
	if sprite:
		sprite.queue_free()
	
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(8, 2)
	color_rect.position = Vector2(-4, -1)
	color_rect.color = Color.YELLOW
	add_child(color_rect)

func expire():
	"""Mark projectile as expired and emit signal"""
	is_active = false
	visible = false
	projectile_expired.emit(self)

func _on_area_entered(area: Area2D):
	"""Handle collision with another area"""
	if not is_active:
		return
	
	# Check if it's an enemy or other valid target
	if area.is_in_group("enemies") and area != shooter:
		hit_target.emit(area, data.damage)
		expire()

func _on_body_entered(body: Node2D):
	"""Handle collision with a body"""
	if not is_active:
		return
	
	# Check if it's an enemy or other valid target
	if body.is_in_group("enemies") and body != shooter:
		hit_target.emit(body, data.damage)
		expire()

func _is_off_screen() -> bool:
	"""Check if projectile is off-screen and should be recycled"""
	var viewport = get_viewport()
	if not viewport:
		return false
	
	var camera = viewport.get_camera_2d()
	if not camera:
		return false
	
	var viewport_size = viewport.get_visible_rect().size
	var camera_pos = camera.global_position
	var zoom = camera.zoom
	
	# Calculate screen bounds with buffer
	var buffer = 100.0  # Extra buffer to prevent pop-in
	var half_screen = viewport_size / (2 * zoom) + Vector2(buffer, buffer)
	var screen_rect = Rect2(camera_pos - half_screen, viewport_size / zoom + Vector2(buffer * 2, buffer * 2))
	
	return not screen_rect.has_point(global_position)
