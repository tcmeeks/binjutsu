extends Node2D
class_name VisionCone

## Reusable vision cone component for detecting targets within a cone-shaped area

signal target_entered(target: Node2D)
signal target_exited(target: Node2D)

@export var vision_range: float = 128.0  # Distance in pixels
@export var vision_arc: float = 110.0    # Arc in degrees
@export var vision_direction: Vector2 = Vector2.LEFT  # Direction the cone faces
@export var target_groups: Array[String] = ["units"]  # Groups to detect
@export var debug_enabled: bool = false  # Toggle debug visualization

var detected_targets: Array[Node2D] = []
var owner_node: Node2D

func _ready():
	# Get the owner node (parent)
	owner_node = get_parent() as Node2D
	if not owner_node:
		print("ERROR: VisionCone must be child of a Node2D!")
		return

func _process(_delta):
	_update_vision()
	
	# Always queue redraw if debug is enabled, so we can clear when debug mode is turned off
	if debug_enabled:
		queue_redraw()

func _update_vision():
	"""Update vision detection each frame"""
	if not owner_node:
		return
	
	var current_targets: Array[Node2D] = []
	
	# Get all potential targets from specified groups
	for group_name in target_groups:
		var group_nodes = get_tree().get_nodes_in_group(group_name)
		for node in group_nodes:
			if node == owner_node:
				continue  # Don't detect self
			
			var target = node as Node2D
			if target and _is_target_in_vision_cone(target):
				current_targets.append(target)
	
	# Check for new targets
	for target in current_targets:
		if target not in detected_targets:
			detected_targets.append(target)
			target_entered.emit(target)
	
	# Check for targets that left
	for target in detected_targets:
		if target not in current_targets:
			detected_targets.erase(target)
			target_exited.emit(target)

func _is_target_in_vision_cone(target: Node2D) -> bool:
	"""Check if target is within the vision cone or line"""
	var to_target = target.global_position - owner_node.global_position
	var distance = to_target.length()
	
	# Check distance
	if distance > vision_range:
		return false
	
	# Special case: vision_arc of 0 means line-based detection
	if vision_arc == 0.0:
		return _is_target_on_vision_line(target)
	
	# Regular cone detection
	var angle_to_target = to_target.angle()
	var vision_angle = vision_direction.angle()
	var half_arc = deg_to_rad(vision_arc / 2.0)
	
	var angle_diff = abs(angle_difference(angle_to_target, vision_angle))
	return angle_diff <= half_arc

func _is_target_on_vision_line(target: Node2D) -> bool:
	"""Check if target intersects with the vision line (for arc = 0)"""
	var line_start = owner_node.global_position
	var line_end = line_start + vision_direction * vision_range
	
	# Get target's collision shape for more accurate detection
	var target_radius = 8.0  # Default radius
	if target.has_method("get_collision_radius"):
		target_radius = target.get_collision_radius()
	
	# Calculate distance from target to line
	var distance_to_line = _point_to_line_distance(target.global_position, line_start, line_end)
	
	return distance_to_line <= target_radius

func _point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	"""Calculate the shortest distance from a point to a line segment"""
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	
	var line_length_squared = line_vec.length_squared()
	if line_length_squared == 0.0:
		return point_vec.length()  # Line is a point
	
	# Project point onto line
	var t = point_vec.dot(line_vec) / line_length_squared
	t = clamp(t, 0.0, 1.0)  # Clamp to line segment
	
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

func _draw():
	"""Debug visualization of the vision cone or line"""
	if not debug_enabled or not owner_node or not DebugVisualization.debug_mode_enabled:
		return
	
	# Special case: vision_arc of 0 means draw a line
	if vision_arc == 0.0:
		var line_end = vision_direction * vision_range
		draw_line(Vector2.ZERO, line_end, Color.RED, 2.0)
		# Draw a small circle at the end to show range
		draw_circle(line_end, 4.0, Color.RED)
		return
	
	# Draw vision cone outline
	var half_arc = deg_to_rad(vision_arc / 2.0)
	var vision_angle = vision_direction.angle()
	
	# Draw cone edges
	var edge1 = Vector2.from_angle(vision_angle - half_arc) * vision_range
	var edge2 = Vector2.from_angle(vision_angle + half_arc) * vision_range
	
	draw_line(Vector2.ZERO, edge1, Color.YELLOW, 1.0)
	draw_line(Vector2.ZERO, edge2, Color.YELLOW, 1.0)
	
	# Draw arc
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)
	
	var steps = 20
	for i in range(steps + 1):
		var t = float(i) / float(steps)
		var angle = vision_angle - half_arc + (2.0 * half_arc * t)
		var point = Vector2.from_angle(angle) * vision_range
		points.append(point)
	
	points.append(Vector2.ZERO)
	draw_colored_polygon(points, Color(1.0, 1.0, 0.0, 0.1))  # Semi-transparent yellow

func set_vision_parameters(range_value: float, arc: float, direction: Vector2):
	"""Set vision cone parameters"""
	vision_range = range_value
	vision_arc = arc
	vision_direction = direction.normalized()

func get_detected_targets() -> Array[Node2D]:
	"""Get currently detected targets"""
	return detected_targets.duplicate()

func has_targets() -> bool:
	"""Check if any targets are currently detected"""
	return not detected_targets.is_empty()
