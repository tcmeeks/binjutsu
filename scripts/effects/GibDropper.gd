extends Node
class_name GibDropper

## System for dropping gib particles when enemies get hit

const GIB_PARTICLE_SCENE = preload("res://scenes/effects/GibParticle.tscn")

static func drop_gibs(position: Vector2, enemy_sprite: AnimatedSprite2D, scene_tree: SceneTree,
					  count: int = 8, drop_force_min: float = 80.0, drop_force_max: float = 150.0,
					  arc_angle_range: float = 60.0, drop_height_offset: float = -10.0) -> Array[GibParticle]:
	"""Drop gib particles at the specified position, colored from enemy sprite"""
	var gibs: Array[GibParticle] = []
	var base_ground_level = position.y
	
	# Sample the enemy sprite color
	var gib_color = ColorSampler.sample_center_color(enemy_sprite)
	
	if DebugVisualization.debug_mode_enabled:
		print("🩸 Dropping ", count, " gibs with color: ", gib_color)
	
	for i in count:
		var gib = _create_gib_particle()
		if not gib:
			continue
		
		# Add to scene
		scene_tree.current_scene.add_child(gib)
		
		# Position gib slightly above impact point
		gib.global_position = position + Vector2(0, drop_height_offset)
		
		# Calculate launch velocity in an arc (similar to coin system)
		var angle_offset = randf_range(-arc_angle_range, arc_angle_range)
		var launch_angle = deg_to_rad(-90 + angle_offset)  # -90 is straight up
		var launch_force = randf_range(drop_force_min, drop_force_max)
		
		var launch_velocity = Vector2(
			cos(launch_angle) * launch_force,
			sin(launch_angle) * launch_force
		)
		
		# Add some randomness to horizontal spread
		launch_velocity.x += randf_range(-30.0, 30.0)
		
		# Add random variance to ground level (like coins)
		var gib_ground_level = base_ground_level + randf_range(-4.0, 4.0)
		
		# Launch the gib with color
		gib.launch(launch_velocity, gib_ground_level, gib_color)
		
		gibs.append(gib)
	
	return gibs

static func drop_gibs_from_sprite2d(position: Vector2, sprite: Sprite2D, scene_tree: SceneTree,
									count: int = 8, drop_force_min: float = 80.0, drop_force_max: float = 150.0,
									arc_angle_range: float = 60.0, drop_height_offset: float = -10.0) -> Array[GibParticle]:
	"""Drop gib particles from a regular Sprite2D (for future use)"""
	var gibs: Array[GibParticle] = []
	var base_ground_level = position.y
	
	# Sample the sprite color
	var gib_color = ColorSampler.sample_sprite2d_center_color(sprite)
	
	if DebugVisualization.debug_mode_enabled:
		print("🩸 Dropping ", count, " gibs from Sprite2D with color: ", gib_color)
	
	for i in count:
		var gib = _create_gib_particle()
		if not gib:
			continue
		
		scene_tree.current_scene.add_child(gib)
		gib.global_position = position + Vector2(0, drop_height_offset)
		
		var angle_offset = randf_range(-arc_angle_range, arc_angle_range)
		var launch_angle = deg_to_rad(-90 + angle_offset)
		var launch_force = randf_range(drop_force_min, drop_force_max)
		
		var launch_velocity = Vector2(
			cos(launch_angle) * launch_force,
			sin(launch_angle) * launch_force
		)
		
		launch_velocity.x += randf_range(-30.0, 30.0)
		var gib_ground_level = base_ground_level + randf_range(-4.0, 4.0)
		
		gib.launch(launch_velocity, gib_ground_level, gib_color)
		gibs.append(gib)
	
	return gibs

static func _create_gib_particle() -> GibParticle:
	"""Create a new gib particle instance"""
	var gib = GIB_PARTICLE_SCENE.instantiate() as GibParticle
	return gib