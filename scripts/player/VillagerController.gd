extends CharacterBody2D

@export var speed: float = 50.0
@export var wander_range: float = 100.0
@export var wait_time_min: float = 1.0
@export var wait_time_max: float = 3.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wander_timer: Timer = $WanderTimer

enum State {
	IDLE,
	WALKING,
	WAITING
}

var current_state: State = State.IDLE
var movement_direction: Vector2 = Vector2.ZERO
var spawn_position: Vector2
var target_position: Vector2

func _ready():
	spawn_position = global_position
	_setup_wander_timer()
	_start_wandering()

func _setup_wander_timer():
	wander_timer.wait_time = randf_range(wait_time_min, wait_time_max)
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	wander_timer.start()

func _physics_process(delta):
	match current_state:
		State.WALKING:
			_handle_walking(delta)
		State.IDLE:
			_handle_idle()
		State.WAITING:
			_handle_waiting()
	
	move_and_slide()
	
	_update_animation()

func _handle_walking(delta):
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	movement_direction = direction
	
	# Check if we've reached the target
	if global_position.distance_to(target_position) < 5.0:
		velocity = Vector2.ZERO
		movement_direction = Vector2.ZERO
		_start_waiting()

func _handle_idle():
	velocity = Vector2.ZERO

func _handle_waiting():
	velocity = Vector2.ZERO

func _start_wandering():
	# Pick a random point within wander range
	var angle = randf() * 2 * PI
	var distance = randf() * wander_range
	target_position = spawn_position + Vector2(cos(angle), sin(angle)) * distance
	
	current_state = State.WALKING

func _start_waiting():
	current_state = State.WAITING
	wander_timer.wait_time = randf_range(wait_time_min, wait_time_max)
	wander_timer.start()

func _on_wander_timer_timeout():
	if current_state == State.WAITING:
		_start_wandering()

func _update_animation():
	if velocity.length() > 0:
		# Walking animations based on direction
		if abs(movement_direction.x) > abs(movement_direction.y):
			# Horizontal movement
			if movement_direction.x > 0:
				sprite.play("walk_right")
			else:
				sprite.play("walk_left")
		else:
			# Vertical movement
			if movement_direction.y > 0:
				sprite.play("walk_down")
			else:
				sprite.play("walk_up")
	else:
		# Idle animations - use last movement direction for facing
		if abs(movement_direction.x) > abs(movement_direction.y):
			if movement_direction.x > 0:
				sprite.play("idle_right")
			else:
				sprite.play("idle_left")
		else:
			if movement_direction.y > 0:
				sprite.play("idle_down")
			else:
				sprite.play("idle_up")
		
		# Default idle if no previous movement
		if movement_direction == Vector2.ZERO:
			sprite.play("idle_down")
