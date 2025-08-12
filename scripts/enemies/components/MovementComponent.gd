extends Node
class_name MovementComponent

## Base movement component for enemies

var enemy: CharacterBody2D
var data: EnemyData

func initialize(enemy_ref: CharacterBody2D, enemy_data: EnemyData):
	enemy = enemy_ref
	data = enemy_data

func update_movement(_delta: float):
	# Override in specific movement components
	pass

static func create_movement_component(movement_type: EnemyData.MovementType) -> MovementComponent:
	match movement_type:
		EnemyData.MovementType.STRAIGHT:
			return StraightMovementComponent.new()
		EnemyData.MovementType.SINE_WAVE:
			return SineWaveMovementComponent.new()
		EnemyData.MovementType.LEAP:
			return LeapMovementComponent.new()
		EnemyData.MovementType.CHASE:
			return ChaseMovementComponent.new()
		EnemyData.MovementType.TRACKING:
			return TrackingMovementComponent.new()
		EnemyData.MovementType.LEAP_CHASE:
			return LeapChaseMovementComponent.new()
		EnemyData.MovementType.SNAKE:
			return SnakeMovementComponent.new()
		_:
			return StraightMovementComponent.new()
