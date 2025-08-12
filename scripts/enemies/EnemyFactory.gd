extends Node
class_name EnemyFactory

## Factory for creating data-driven enemies

static var generic_enemy_scene: PackedScene = preload("res://scenes/enemies/GenericEnemy.tscn")

static func create_enemy(enemy_type: String) -> GenericEnemy:
	var enemy_data = EnemyData.create_enemy_data(enemy_type)
	if not enemy_data:
		return null
	
	var enemy_instance = generic_enemy_scene.instantiate() as GenericEnemy
	if not enemy_instance:
		print("ERROR: Failed to instantiate generic enemy!")
		return null
	
	enemy_instance.initialize_with_data(enemy_data)
	return enemy_instance

static func get_available_enemy_types() -> Array[String]:
	return ["slime", "snake", "raccoon", "frog", "cyclope"]
