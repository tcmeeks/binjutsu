extends Node2D
class_name UnitSpawner

## Simple spawner that creates a unit using the data-driven system

@export var unit_type: String = "player"
@export var spawn_position: Vector2 = Vector2(320, 232)

func _ready():
	# Defer unit creation to avoid parent node busy error
	call_deferred("_spawn_unit")

func _spawn_unit():
	# Create unit using factory
	var unit_instance = UnitFactory.create_unit(unit_type)
	
	if unit_instance:
		unit_instance.global_position = spawn_position
		get_parent().add_child(unit_instance)
		
		if DebugVisualization.debug_mode_enabled:
			print("Spawned ", unit_instance.get_unit_type(), " at ", spawn_position)
	else:
		print("ERROR: Failed to create unit of type: ", unit_type)
