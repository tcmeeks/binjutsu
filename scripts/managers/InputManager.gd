extends Node

func _ready():
	_setup_input_action()


func _setup_input_action():
	# Ensure the input action exists
	if not InputMap.has_action("toggle_fullscreen"):
		InputMap.add_action("toggle_fullscreen")
		
		# Add Enter key
		var enter_event = InputEventKey.new()
		enter_event.keycode = KEY_ENTER
		InputMap.action_add_event("toggle_fullscreen", enter_event)

func _input(event):
	# Check for Enter key press
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()  # Consume the event
	
	# Check for O key press (toggle debug mode)
	if event is InputEventKey and event.pressed and event.keycode == KEY_O:
		DebugVisualization.toggle_debug_mode()
		_update_vision_debug_for_all_enemies()
		get_viewport().set_input_as_handled()
	
	# Check for V key press (toggle vision debug)
	if event is InputEventKey and event.pressed and event.keycode == KEY_V:
		DebugVisualization.toggle_vision_debug()
		DebugVisualization.toggle_target_highlighting()
		_update_vision_debug_for_all_enemies()
		get_viewport().set_input_as_handled()
	
	# Check for numpad keys (spawn enemies)
	if event is InputEventKey and event.pressed:
		_handle_numpad_enemy_spawn(event.keycode)

func _update_vision_debug_for_all_enemies():
	"""Update vision debug setting for all existing enemies"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("update_vision_debug"):
			enemy.update_vision_debug()
		
		# Force redraw of vision cones to clear them when debug is turned off
		var vision_cone = enemy.get_node_or_null("VisionCone")
		if vision_cone and vision_cone.has_method("queue_redraw"):
			vision_cone.queue_redraw()
	
	# Also update debug visualization for units
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		if unit.has_method("set_debug_mode"):
			unit.set_debug_mode(DebugVisualization.debug_mode_enabled)

func _toggle_fullscreen():
	var current_mode = DisplayServer.window_get_mode()
	
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _handle_numpad_enemy_spawn(keycode: int):
	"""Handle numpad keys for enemy spawning"""
	var numpad_keys = [
		KEY_KP_1, KEY_KP_2, KEY_KP_3, KEY_KP_4, KEY_KP_5,
		KEY_KP_6, KEY_KP_7, KEY_KP_8, KEY_KP_9
	]
	
	var key_index = numpad_keys.find(keycode)
	if key_index == -1:
		return  # Not a numpad key we care about
	
	# Get available enemy types
	var available_enemies = EnemyFactory.get_available_enemy_types()
	if key_index >= available_enemies.size():
		if DebugVisualization.debug_mode_enabled:
			print("Numpad ", key_index + 1, " pressed but only ", available_enemies.size(), " enemy types available")
		return
	
	# Spawn the corresponding enemy
	var enemy_type = available_enemies[key_index]
	_spawn_enemy_at_player(enemy_type)
	get_viewport().set_input_as_handled()

func _spawn_enemy_at_player(enemy_type: String):
	"""Spawn an enemy near the player position"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		print("ERROR: No camera found for enemy spawning")
		return
	
	var enemy_instance = EnemyFactory.create_enemy(enemy_type)
	if not enemy_instance:
		print("ERROR: Failed to create enemy of type: ", enemy_type)
		return
	
	# Spawn enemy to the right of the camera view
	var camera_pos = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	var spawn_x = camera_pos.x + (viewport_size.x / 2) + 50  # Just off-screen right
	var spawn_y = camera_pos.y + randf_range(-100, 100)  # Random Y near camera
	
	enemy_instance.global_position = Vector2(spawn_x, spawn_y)
	
	# Add to scene tree (find the main scene)
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(enemy_instance)
		if DebugVisualization.debug_mode_enabled:
			print("Spawned ", enemy_type, " at ", enemy_instance.global_position, " via numpad")
	else:
		print("ERROR: Could not find main scene to add enemy")
		enemy_instance.queue_free()
