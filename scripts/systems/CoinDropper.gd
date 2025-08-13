extends Node
class_name CoinDropper

## System for dropping coins when enemies die

const COIN_SCENE = preload("res://scenes/pickups/Coin.tscn")

static func drop_coins(position: Vector2, count: int, scene_tree: SceneTree, 
					   drop_force_min: float = 120.0, drop_force_max: float = 180.0,
					   arc_angle_range: float = 45.0, drop_height_offset: float = -15.0) -> Array[Coin]:
	"""Drop coins at the specified position"""
	var coins: Array[Coin] = []
	var base_ground_level = position.y  # Use enemy death position as base ground plane
	
	for i in count:
		var coin = COIN_SCENE.instantiate() as Coin
		
		# Add to scene
		scene_tree.current_scene.add_child(coin)
		
		# Position coin slightly above drop point
		coin.global_position = position + Vector2(0, drop_height_offset)
		
		# Calculate launch velocity in an arc
		var angle_offset = randf_range(-arc_angle_range, arc_angle_range)
		var launch_angle = deg_to_rad(-90 + angle_offset)  # -90 is straight up
		var launch_force = randf_range(drop_force_min, drop_force_max)
		
		var launch_velocity = Vector2(
			cos(launch_angle) * launch_force,
			sin(launch_angle) * launch_force
		)
		
		# Add some randomness to horizontal spread
		launch_velocity.x += randf_range(-50.0, 50.0)
		
		# Add 6 pixel random variance to ground level for each coin
		var coin_ground_level = base_ground_level + randf_range(-6.0, 6.0)
		
		# Launch the coin with randomized ground level
		coin.launch(launch_velocity, coin_ground_level)
		
		# Connect coin collection signal
		coin.coin_collected.connect(_on_coin_collected)
		
		coins.append(coin)
	
	return coins

static func _on_coin_collected(_coin: Coin):
	"""Handle coin collection - could add score, sound, etc."""
	if DebugVisualization.debug_mode_enabled:
		print("💰 Coin collected!")
	# Could emit signal to game manager, add to score, play sound, etc.
