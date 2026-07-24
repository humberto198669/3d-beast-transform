extends CharacterBody3D

const LEFT_TURN_MODEL := preload("res://Characters/Human/Animations/ethan_human_left_turn.fbx")
const RIGHT_TURN_MODEL := preload("res://Characters/Human/Animations/ethan_human_right_turn.fbx")
const JUMP_MODEL := preload("res://Characters/Human/Animations/ethan_human_jump.fbx")

signal crashed
signal beast_hit_mammoth(mammoth: Node3D)
signal lane_action_requested(direction: int)
signal jump_action_requested

@export var speed := 10.0
@export var jump_force := 8.0
@export var gravity := 20.0

@export var lane_distance := 5.0
@export var max_lateral_speed := 11.0
@export var lateral_acceleration := 55.0
@export var lateral_response := 8.0
@export var swipe_threshold_ratio := 0.075
@export var jump_buffer_time := 0.12
@export var coyote_time := 0.1
@export var slide_duration := 0.72
@export_range(0.5, 1.5, 0.05) var lane_jump_animation_speed := 1.4
@export_range(0.0, 25.0, 0.5) var lane_jump_tilt_degrees := 10.0
@onready var visual_pivot: Node3D = $VisualPivot
@onready var run_visual: Node3D = $"VisualPivot/Fast Run"
@onready var body_collision: CollisionShape3D = $CollisionShape3D

var current_lane := 1
var target_x := 0.0
var touch_start := Vector2.ZERO
var active_touch_index := -1
var gesture_triggered := false
var jump_buffer_timer := 0.0
var coyote_timer := 0.0
var controls_enabled := true
var beast_mode := false
var human_form_visible := true
var left_turn_visual: Node3D
var right_turn_visual: Node3D
var jump_visual: Node3D
var action_serial := 0
var lane_action_active := false
var sliding := false
var slide_serial := 0

func _ready() -> void:
	left_turn_visual = _create_action_visual(LEFT_TURN_MODEL, "EthanLeftTurn")
	right_turn_visual = _create_action_visual(RIGHT_TURN_MODEL, "EthanRightTurn")
	jump_visual = _create_action_visual(JUMP_MODEL, "EthanJump")
	# Conserva la compensacion de inclinacion usada antes del ajuste de velocidad.
	left_turn_visual.rotation.z = deg_to_rad(-lane_jump_tilt_degrees)
	right_turn_visual.rotation.z = deg_to_rad(lane_jump_tilt_degrees)

func _create_action_visual(model: PackedScene, visual_name: String) -> Node3D:
	var visual: Node3D = model.instantiate() as Node3D
	visual.name = visual_name
	visual.scale = Vector3.ONE * 155.0
	visual.visible = false
	visual_pivot.add_child(visual)
	return visual

func _physics_process(delta):
	# Velocidad
	velocity.z = -speed
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = maxf(0.0, coyote_timer - delta)
	jump_buffer_timer = maxf(0.0, jump_buffer_timer - delta)
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Carriles
	if controls_enabled and Input.is_action_just_pressed("uileft"):
		move_left()
		
	if controls_enabled and Input.is_action_just_pressed("uiright"):
		move_right()
		
	# Salto
	if controls_enabled and Input.is_action_just_pressed("uiaccept"):
		request_jump()
	if controls_enabled and Input.is_action_just_pressed("uidown"):
		request_slide()
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		_play_human_action(jump_visual)
		jump_action_requested.emit()
		
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
		_finish_lane_action()
	
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision == null:
			continue
		var collider: Node = collision.get_collider() as Node
		if collider == null or not collider.is_in_group("obstacle"):
			continue
		# Ethan y el oso reciben el mismo efecto al chocar. El modo bestia
		# aumenta la recompensa, pero no destruye ni atraviesa obstaculos.
		crashed.emit()
		return

func set_beast_mode(enabled: bool) -> void:
	beast_mode = enabled

func set_human_form_visible(visible: bool) -> void:
	human_form_visible = visible
	action_serial += 1
	lane_action_active = false
	run_visual.visible = visible
	left_turn_visual.visible = false
	right_turn_visual.visible = false
	jump_visual.visible = false

func _play_human_action(action_visual: Node3D) -> void:
	if not human_form_visible or beast_mode or action_visual == null:
		return
	action_serial += 1
	var current_action_serial: int = action_serial
	run_visual.visible = false
	left_turn_visual.visible = action_visual == left_turn_visual
	right_turn_visual.visible = action_visual == right_turn_visual
	jump_visual.visible = action_visual == jump_visual
	var animation_player: AnimationPlayer = _find_action_animation_player(action_visual)
	if animation_player == null:
		_restore_run_after_action(current_action_serial)
		return
	var animation_name: StringName = _first_action_animation(animation_player)
	if animation_name == &"":
		_restore_run_after_action(current_action_serial)
		return
	var animation: Animation = animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	var playback_speed: float = 1.0
	if action_visual == left_turn_visual or action_visual == right_turn_visual:
		playback_speed = lane_jump_animation_speed
	# Una segunda orden hacia el mismo lado debe iniciar un nuevo paso visible.
	animation_player.stop()
	animation_player.play(animation_name, -1.0, playback_speed)
	animation_player.seek(0.0, true)
	await animation_player.animation_finished
	_restore_run_after_action(current_action_serial)

func _find_action_animation_player(root: Node) -> AnimationPlayer:
	var animation_nodes: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
	for animation_node: Node in animation_nodes:
		var animation_player: AnimationPlayer = animation_node as AnimationPlayer
		if animation_player != null:
			return animation_player
	return null

func _first_action_animation(animation_player: AnimationPlayer) -> StringName:
	for animation_name: StringName in animation_player.get_animation_list():
		if animation_name != &"RESET":
			return animation_name
	return &""

func _restore_run_after_action(expected_serial: int) -> void:
	if expected_serial != action_serial or not human_form_visible or beast_mode:
		return
	left_turn_visual.visible = false
	right_turn_visual.visible = false
	jump_visual.visible = false
	run_visual.visible = true
	lane_action_active = false

func _finish_lane_action() -> void:
	if not lane_action_active or not human_form_visible or beast_mode:
		return
	action_serial += 1
	lane_action_active = false
	left_turn_visual.visible = false
	right_turn_visual.visible = false
	jump_visual.visible = false
	run_visual.visible = true

func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		active_touch_index = -1
		gesture_triggered = false
		jump_buffer_timer = 0.0

func _unhandled_input(event):
	if not controls_enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if active_touch_index < 0:
				active_touch_index = event.index
				touch_start = event.position
				gesture_triggered = false
		elif event.index == active_touch_index:
			if not gesture_triggered:
				_try_trigger_swipe(event.position)
			active_touch_index = -1
			gesture_triggered = false
	elif event is InputEventScreenDrag and event.index == active_touch_index and not gesture_triggered:
		_try_trigger_swipe(event.position)

func _try_trigger_swipe(current_position: Vector2) -> void:
	var swipe: Vector2 = current_position - touch_start
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	var swipe_threshold: float = clampf(viewport_width * swipe_threshold_ratio, 36.0, 72.0)
	if swipe.length() < swipe_threshold:
		return
	if absf(swipe.x) > absf(swipe.y):
		if swipe.x < 0.0:
			move_left()
		else:
			move_right()
		gesture_triggered = true
	elif swipe.y < 0.0:
		request_jump()
		gesture_triggered = true
	else:
		request_slide()
		gesture_triggered = true
			
func move_left():
	var previous_lane: int = current_lane
	current_lane = max(current_lane - 1, 0)
	update_lane()
	if current_lane != previous_lane:
		lane_action_active = true
		_play_human_action(left_turn_visual)
		lane_action_requested.emit(-1)

func move_right():
	var previous_lane: int = current_lane
	current_lane = min(current_lane + 1, 2)
	update_lane()
	if current_lane != previous_lane:
		lane_action_active = true
		_play_human_action(right_turn_visual)
		lane_action_requested.emit(1)
	
func update_lane():
	target_x = (current_lane - 1) * lane_distance
	
func jump():
	request_jump()

func request_jump() -> void:
	if sliding:
		return
	jump_buffer_timer = jump_buffer_time

func request_slide() -> void:
	if sliding or not controls_enabled or not is_on_floor():
		return
	sliding = true
	slide_serial += 1
	var current_slide_serial: int = slide_serial
	var capsule: CapsuleShape3D = body_collision.shape as CapsuleShape3D
	if capsule != null:
		capsule.radius = 0.28
		capsule.height = 0.65
	body_collision.position.y = 0.33
	var slide_tween: Tween = create_tween().set_parallel(true)
	slide_tween.tween_property(visual_pivot, "scale:y", 0.62, 0.1)
	slide_tween.tween_property(visual_pivot, "position:y", -0.08, 0.1)
	await get_tree().create_timer(slide_duration).timeout
	if current_slide_serial != slide_serial:
		return
	if capsule != null:
		capsule.radius = 0.45
		capsule.height = 1.3
	body_collision.position.y = 0.65
	var restore_tween: Tween = create_tween().set_parallel(true)
	restore_tween.tween_property(visual_pivot, "scale:y", 1.0, 0.12)
	restore_tween.tween_property(visual_pivot, "position:y", 0.0, 0.12)
	await restore_tween.finished
	if current_slide_serial == slide_serial:
		sliding = false
