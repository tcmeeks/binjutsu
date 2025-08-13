extends Node
class_name UnitFactory

## Factory for creating data-driven units

static var generic_unit_scene: PackedScene = preload("res://scenes/units/GenericUnit.tscn")

static func create_unit(unit_type: String) -> GenericUnit:
	var unit_data = UnitData.create_unit_data(unit_type)
	if not unit_data:
		return null
	
	var unit_instance = generic_unit_scene.instantiate() as GenericUnit
	if not unit_instance:
		print("ERROR: Failed to instantiate generic unit!")
		return null
	
	unit_instance.initialize_with_data(unit_data)
	return unit_instance

static func get_available_unit_types() -> Array[String]:
	return ["player"]