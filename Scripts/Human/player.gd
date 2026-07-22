extends CharacterBody3D

signal crashed

@export var speed := 10.0
@export var jump_force := 8.0
@export var gravity := 20.0

@export var lane_distance := 5.0
@export var max_lateral_speed := 11.0
@export var lateral_acceleration := 55.0
@export var lateral_response := 8.0

var current_lane := 1
var target_x := 0.0
var touch_start := Vector2.ZERO

func _physics_process(delta):
	# Velocidad
	velocity.z = -speed
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Carriles
	if Input.is_action_just_pressed("uileft"):
		move_left()
		
	if Input.is_action_just_pressed("uiright"):
		move_right()
		
	# Salto
	if Input.is_action_just_pressed("uiaccept"):
		jump()
		
	# Movimiento lateral suave: acelera al salir y frena al llegar al carril.
	var lateral_distance: float = target_x - global_position.x
	var desired_lateral_speed: float = clampf(
		lateral_distance * lateral_response,
		-max_lateral_speed,
		max_lateral_speed
	)
	velocity.x = move_toward(
		velocity.x,
		desired_lateral_speed,
		lateral_acceleration * delta
	)
	if abs(lateral_distance) < 0.025 and abs(velocity.x) < 0.5:
		global_position.x = target_x
		velocity.x = 0.0
	
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider().is_in_group("obstacle"):
			crashed.emit()
			return

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_start = event.position
		else:
			var swipe = event.position - touch_start
			if abs(swipe.x) > abs(swipe.y) and abs(swipe.x) > 40.0:
				if swipe.x < 0.0:
					move_left()
				else:
					move_right()
			elif swipe.y < -40.0:
				jump()
			
func move_left():
	current_lane = max(current_lane - 1, 0)
	update_lane()

func move_right():
	current_lane = min(current_lane + 1, 2)
	update_lane()
	
func update_lane():
	target_x = (current_lane - 1) * lane_distance
	
func jump():
	if is_on_floor():
		velocity.y = jump_force
