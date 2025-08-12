extends Node
class_name ProjectilePool

## Object pool for managing projectile instances efficiently

var projectile_scene: PackedScene
var available_projectiles: Array[Projectile] = []
var active_projectiles: Array[Projectile] = []
var max_pool_size: int = 50

func _init():
	# Create the projectile scene programmatically
	projectile_scene = _create_projectile_scene()

func _create_projectile_scene() -> PackedScene:
	"""Create the projectile scene programmatically"""
	var scene = PackedScene.new()
	
	# Create the root Area2D node
	var projectile = Area2D.new()
	projectile.set_script(load("res://scripts/components/Projectile.gd"))
	
	# Add AnimatedSprite2D
	var sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	projectile.add_child(sprite)
	sprite.owner = projectile
	
	# Add CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	projectile.add_child(collision)
	collision.owner = projectile
	
	# Pack the scene
	scene.pack(projectile)
	return scene

func get_projectile() -> Projectile:
	"""Get a projectile from the pool or create a new one"""
	var projectile: Projectile
	
	if available_projectiles.size() > 0:
		projectile = available_projectiles.pop_back()
	else:
		projectile = projectile_scene.instantiate() as Projectile
		# Connect the expired signal
		projectile.projectile_expired.connect(_on_projectile_expired)
		# Add to scene tree
		get_tree().current_scene.add_child(projectile)
	
	active_projectiles.append(projectile)
	return projectile

func return_projectile(projectile: Projectile):
	"""Return a projectile to the pool"""
	if projectile in active_projectiles:
		active_projectiles.erase(projectile)
	
	# Reset projectile state
	projectile.is_active = false
	projectile.visible = false
	projectile.data = null
	projectile.direction = Vector2.ZERO
	projectile.shooter = null
	
	# Add back to available pool if under limit
	if available_projectiles.size() < max_pool_size:
		available_projectiles.append(projectile)
	else:
		# Pool is full, destroy the projectile
		projectile.queue_free()

func _on_projectile_expired(projectile: Projectile):
	"""Handle when a projectile expires"""
	return_projectile(projectile)

func clear_all_projectiles():
	"""Clear all projectiles from the pool"""
	for projectile in active_projectiles:
		projectile.expire()
	
	for projectile in available_projectiles:
		projectile.queue_free()
	
	available_projectiles.clear()
	active_projectiles.clear()

func get_active_count() -> int:
	"""Get the number of active projectiles"""
	return active_projectiles.size()

func get_pool_size() -> int:
	"""Get the total pool size"""
	return available_projectiles.size() + active_projectiles.size()
