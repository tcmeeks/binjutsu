extends Node2D
class_name ProjectileAttack

## Component that handles projectile-based attacks for units

signal attack_performed(target_position: Vector2)

@export var attack_range: float = 64.0
@export var attack_speed: float = 1.0  # Attacks per second
@export var projectile_type: String = "kunai"
@export var auto_attack: bool = false
@export var show_range_debug: bool = false

var attack_cooldown: float = 0.0
var projectile_data: ProjectileData
var projectile_pool: ProjectilePool
var owner_unit: Node2D

func _ready():
	# Get the owner unit
	owner_unit = get_parent()
	
	# Load projectile data
	projectile_data = ProjectileData.create_from_definition(projectile_type)
	if not projectile_data:
		push_error("Failed to load projectile data for type: " + projectile_type)
		return
	
	# Create projectile pool
	projectile_pool = ProjectilePool.new()
	add_child(projectile_pool)
	
	# No need to connect to pool signals - individual projectiles handle their own expiration

func _physics_process(delta):
	# Update attack cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta
	
	# Auto attack logic (if enabled)
	if auto_attack and can_attack():
		var target = _find_nearest_enemy()
		if target:
			attack_at_position(target.global_position)

func _draw():
	if show_range_debug and DebugVisualization.debug_mode_enabled:
		# Draw attack range circle
		draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color.RED, 2.0)

func can_attack() -> bool:
	"""Check if the unit can perform an attack"""
	return attack_cooldown <= 0.0 and projectile_data != null

func attack_at_position(target_position: Vector2) -> bool:
	"""Attack at a specific position"""
	if not can_attack():
		return false
	
	var distance = global_position.distance_to(target_position)
	if distance > attack_range:
		return false
	
	# Calculate direction to target
	var direction = (target_position - global_position).normalized()
	
	# Create and launch projectile
	var projectile = projectile_pool.get_projectile()
	projectile.configure(projectile_data, global_position, direction, owner_unit)
	
	if DebugVisualization.debug_mode_enabled:
		print("Firing ", projectile_data.projectile_name, " at ", target_position)
	
	# Connect hit signal
	if not projectile.hit_target.is_connected(_on_projectile_hit):
		projectile.hit_target.connect(_on_projectile_hit)
	
	# Start cooldown
	attack_cooldown = 1.0 / attack_speed
	
	# Emit attack signal
	attack_performed.emit(target_position)
	
	# Trigger redraw for debug visualization
	queue_redraw()
	
	return true

func attack_in_direction(direction: Vector2) -> bool:
	"""Attack in a specific direction"""
	var target_position = global_position + direction.normalized() * attack_range
	return attack_at_position(target_position)

func _find_nearest_enemy() -> Node2D:
	"""Find the nearest enemy within attack range"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node2D = null
	var nearest_distance: float = attack_range + 1.0
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= attack_range and distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	
	return nearest_enemy

func _on_projectile_hit(target: Node2D, damage: int):
	"""Handle when a projectile hits a target"""
	# Apply damage to target if it has a health component
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.has_method("hit"):
		target.hit(damage)
	
	print("Projectile hit ", target.name, " for ", damage, " damage")

func _on_projectile_expired(projectile: Projectile):
	"""Handle when a projectile expires"""
	# Disconnect hit signal to prevent memory leaks
	if projectile.hit_target.is_connected(_on_projectile_hit):
		projectile.hit_target.disconnect(_on_projectile_hit)

func set_projectile_type(new_type: String):
	"""Change the projectile type"""
	projectile_type = new_type
	projectile_data = ProjectileData.create_from_definition(projectile_type)
	if not projectile_data:
		push_error("Failed to load projectile data for type: " + projectile_type)

func get_attack_range() -> float:
	"""Get the current attack range"""
	return attack_range

func set_attack_range(new_range: float):
	"""Set the attack range"""
	attack_range = new_range
	queue_redraw()

func set_debug_mode(enabled: bool):
	"""Enable or disable debug visualization"""
	show_range_debug = enabled
	queue_redraw()
