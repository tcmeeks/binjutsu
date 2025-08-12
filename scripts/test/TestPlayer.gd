extends CharacterBody2D

@export var move_speed: float = 50.0

func _physics_process(_delta):
	# Simple movement controls - player can move around on the treadmill
	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	
	velocity = input_vector * move_speed
	move_and_slide()
	
	# Camera stays fixed - no following!
