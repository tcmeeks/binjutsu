extends Node
class_name DebugVisualization

## Global debug visualization system that can be easily toggled

# Debug flags
static var debug_mode_enabled: bool = false  # Master debug toggle - defaults to OFF
static var vision_cones_enabled: bool = true
static var target_highlighting_enabled: bool = true

# Visual settings
static var target_highlight_color: Color = Color.RED
static var target_highlight_radius: float = 20.0
static var target_highlight_width: float = 2.0

# Active debug circles
static var debug_circles: Dictionary = {}  # Node -> DebugCircle mapping

static func toggle_debug_mode():
	"""Toggle master debug mode - controls all debug visualization"""
	debug_mode_enabled = not debug_mode_enabled
	print("Debug mode: ", "ON" if debug_mode_enabled else "OFF")
	
	# Clear debug circles when debug is disabled
	if not debug_mode_enabled:
		clear_all_debug_circles()

static func toggle_vision_debug():
	"""Toggle vision cone debug visualization"""
	vision_cones_enabled = not vision_cones_enabled
	print("Vision cone debug: ", "ON" if vision_cones_enabled else "OFF")

static func toggle_target_highlighting():
	"""Toggle target highlighting"""
	target_highlighting_enabled = not target_highlighting_enabled
	print("Target highlighting: ", "ON" if target_highlighting_enabled else "OFF")
	
	# Clear existing circles if disabled
	if not target_highlighting_enabled:
		clear_all_debug_circles()

static func add_debug_circle(target: Node2D, color: Color = target_highlight_color):
	"""Add a debug circle around a target"""
	if not debug_mode_enabled or not target_highlighting_enabled:
		return
	
	if target in debug_circles:
		return  # Already has a circle
	
	var circle = DebugCircle.new()
	circle.setup(target, color, target_highlight_radius, target_highlight_width)
	
	# Add to scene tree
	if target.get_parent():
		target.get_parent().add_child(circle)
		debug_circles[target] = circle

static func remove_debug_circle(target: Node2D):
	"""Remove debug circle from a target"""
	if target in debug_circles:
		var circle = debug_circles[target]
		if is_instance_valid(circle):
			circle.queue_free()
		debug_circles.erase(target)

static func clear_all_debug_circles():
	"""Clear all debug circles"""
	for target in debug_circles.keys():
		var circle = debug_circles[target]
		if is_instance_valid(circle):
			circle.queue_free()
	debug_circles.clear()

# Inner class for debug circles
class DebugCircle extends Node2D:
	var target: Node2D
	var color: Color
	var radius: float
	var width: float
	
	func setup(target_node: Node2D, circle_color: Color, circle_radius: float, circle_width: float):
		target = target_node
		color = circle_color
		radius = circle_radius
		width = circle_width
		
		# Connect to target's tree_exiting signal for cleanup
		if target.is_connected("tree_exiting", _on_target_freed):
			target.tree_exiting.disconnect(_on_target_freed)
		target.tree_exiting.connect(_on_target_freed)
	
	func _physics_process(_delta):
		if not is_instance_valid(target):
			queue_free()
			return
		
		# Follow target position
		global_position = target.global_position
		queue_redraw()
	
	func _draw():
		if not DebugVisualization.debug_mode_enabled or not DebugVisualization.target_highlighting_enabled:
			return
		
		# Draw circle outline
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, width)
	
	func _on_target_freed():
		# Clean up when target is freed
		if self in DebugVisualization.debug_circles.values():
			for key in DebugVisualization.debug_circles.keys():
				if DebugVisualization.debug_circles[key] == self:
					DebugVisualization.debug_circles.erase(key)
					break
		queue_free()
