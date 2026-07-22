extends Node3D

const GROUND_TILE := preload("res://Scenes/World1/ground_tile_01.tscn")
const COIN_MODEL := preload("res://Assets/Models/Objects/Coin.glb")
const BARREL_MODEL := preload("res://Assets/Models/Obstacles/world1/barril.glb")
const ROCK_MODEL := preload("res://Assets/Models/Obstacles/world1/roca.glb")
const STUMP_MODEL := preload("res://Assets/Models/Obstacles/world1/tocon.glb")
const LOG_MODEL := preload("res://Assets/Models/Obstacles/world1/tronco.glb")
const PINE_MODEL := preload("res://Assets/Models/Obstacles/world1/Pino01.glb")
const DRY_TREE_MODEL := preload("res://Assets/Models/Obstacles/world1/Seco01.glb")
const SIGN_MODEL := preload("res://Assets/Models/Obstacles/world1/signal.glb")
const SNOW_BRIDGE_MODEL := preload("res://Assets/Models/Obstacles/world1/puente_nieve.glb")

const LANES := [-2.7, 0.0, 2.7]
const TILE_COLUMNS := [-5.0, 0.0, 5.0]
const LEVEL_LENGTH := 420.0
const GROUND_ROWS := 26
const ROW_SPACING := 2.25
const GROUND_SURFACE_Y := 0.38
const MIN_SPEED := 6.0
const SPEED_PER_LEVEL := 2.0
const START_SPEED_LEVEL := 7
const MAX_SPEED_LEVEL := 10
const DIFFICULTY_INTERVAL := 10.0

@onready var player: CharacterBody3D = $Player
@onready var ground: Node3D = $Ground
@onready var course: Node3D = $Course
@onready var distance_label: Label = $HUD/SafeArea/TopBar/Stats/Distance/Content/Value
@onready var coins_label: Label = $HUD/SafeArea/TopBar/Stats/CoinCounter/Content/Amount
@onready var message_panel: Control = $HUD/MessagePanel
@onready var message_title: Label = $HUD/MessagePanel/Card/Content/Title
@onready var message_text: Label = $HUD/MessagePanel/Card/Content/Message

var ground_rows: Array = []
var collected_coins := 0
var finished := false
var elapsed_time := 0.0
var speed_level := START_SPEED_LEVEL

func _ready() -> void:
	_build_ground()
	_build_course()
	player.crashed.connect(_on_player_crashed)
	_apply_speed_level()
	message_panel.hide()

func _process(_delta: float) -> void:
	if finished:
		return
	_recycle_ground()
	_recycle_course()
	_update_difficulty(_delta)
	var distance := maxf(0.0, -player.global_position.z)
	distance_label.text = "%03d m" % int(distance)

func _update_difficulty(delta: float) -> void:
	elapsed_time += delta
	var new_level := mini(START_SPEED_LEVEL + int(elapsed_time / DIFFICULTY_INTERVAL), MAX_SPEED_LEVEL)
	if new_level == speed_level:
		return
	speed_level = new_level
	_apply_speed_level()

func _apply_speed_level() -> void:
	# Nivel 1 = 6, nivel 5 = 14 y nivel 10 = 24 unidades por segundo.
	player.speed = MIN_SPEED + float(speed_level - 1) * SPEED_PER_LEVEL

func _recycle_course() -> void:
	for item in get_tree().get_nodes_in_group("recyclable_course"):
		if is_instance_valid(item) and item.global_position.z > player.global_position.z + 12.0:
			item.position.z -= LEVEL_LENGTH

func _unhandled_input(event: InputEvent) -> void:
	if finished and (event.is_action_pressed("uiaccept") or (event is InputEventScreenTouch and event.pressed)):
		get_tree().reload_current_scene()

func _build_ground() -> void:
	for row_index in range(GROUND_ROWS):
		var row: Array = []
		var z := 5.0 - row_index * ROW_SPACING
		for lane_x in TILE_COLUMNS:
			var tile := GROUND_TILE.instantiate()
			tile.scale = Vector3.ONE * 2.5
			tile.position = Vector3(lane_x, 0.0, z)
			ground.add_child(tile)
			row.append(tile)
		ground_rows.append(row)

func _recycle_ground() -> void:
	if ground_rows.is_empty():
		return
	var rear_row: Array = ground_rows[0]
	var rear_z: float = rear_row[0].global_position.z
	if player.global_position.z < rear_z - 15.0:
		var front_row: Array = ground_rows[ground_rows.size() - 1]
		var new_z: float = front_row[0].position.z - ROW_SPACING
		for tile in rear_row:
			tile.position.z = new_z
		ground_rows.pop_front()
		ground_rows.append(rear_row)

func _build_course() -> void:
	var obstacle_data := [
		[35, 1, BARREL_MODEL], [55, 0, ROCK_MODEL], [55, 2, STUMP_MODEL],
		[82, 1, LOG_MODEL], [108, 2, BARREL_MODEL], [138, 0, STUMP_MODEL],
		[138, 2, ROCK_MODEL], [158, 2, LOG_MODEL], [185, 0, BARREL_MODEL],
		[210, 1, STUMP_MODEL], [236, 0, ROCK_MODEL], [236, 2, BARREL_MODEL],
		[270, 1, LOG_MODEL], [338, 0, BARREL_MODEL],
		[330, 1, STUMP_MODEL], [365, 2, LOG_MODEL], [395, 0, ROCK_MODEL],
		[92, 2, SIGN_MODEL], [150, 0, PINE_MODEL], [198, 1, SIGN_MODEL],
		[250, 0, SIGN_MODEL], [350, 0, SIGN_MODEL]
	]
	for data in obstacle_data:
		_add_obstacle(data[2], LANES[data[1]], -float(data[0]))
	# Barreras altas: no se pueden saltar y fuerzan un cambio de carril.
	var giant_obstacles := [
		[72.0, PINE_MODEL], [170.0, PINE_MODEL],
		[275.0, PINE_MODEL], [375.0, PINE_MODEL]
	]
	for data in giant_obstacles:
		_add_giant_obstacle(data[1], 0.0, -data[0])
	# Un puente central largo y, más adelante, dos puentes laterales paralelos.
	_add_snow_bridge(0.0, -125.0)
	for coin_z in [-108.0, -116.0, -124.0, -132.0, -140.0, -148.0]:
		_add_coin(0.0, coin_z, 2.15)
	_add_snow_bridge(LANES[0], -300.0)
	_add_snow_bridge(LANES[2], -300.0)
	for coin_z in [-282.0, -292.0, -302.0, -312.0, -322.0]:
		_add_coin(LANES[0], coin_z, 2.15)
	for coin_z in [-287.0, -297.0, -307.0, -317.0]:
		_add_coin(LANES[2], coin_z, 2.15)
	var coin_data := [
		[12,1],[18,1],[24,1],[42,2],[48,2],[62,2],[68,2],[74,2],
		[92,0],[98,0],[104,0],[118,2],[124,2],[142,1],[148,1],
		[168,0],[174,0],[180,0],[198,2],[204,2],[220,0],[226,0],
		[246,1],[252,1],[258,1],[312,1],
		[318,1],[342,2],[348,2],[354,2],[378,2],[384,2],[402,2]
	]
	for data in coin_data:
		_add_coin(LANES[data[1]], -float(data[0]))
	_add_decoration(SIGN_MODEL, Vector3(-9.0, 0.0, -8.0), 0.9)
	# Dos paredes densas de bosque enmarcan el camino sin invadir los carriles.
	for distance in range(8, 430, 9):
		var alternate := int(distance / 9) % 2
		var left_model: PackedScene = PINE_MODEL if alternate == 0 else DRY_TREE_MODEL
		var right_model: PackedScene = DRY_TREE_MODEL if alternate == 0 else PINE_MODEL
		_add_decoration(left_model, Vector3(-8.2 - alternate * 1.3, 0.0, -float(distance)), 9.0)
		_add_decoration(right_model, Vector3(8.2 + alternate * 1.3, 0.0, -float(distance + 4)), 9.5)
		if distance % 27 == 8:
			_add_decoration(PINE_MODEL, Vector3(-11.5, 0.0, -float(distance + 5)), 7.0)
			_add_decoration(PINE_MODEL, Vector3(11.5, 0.0, -float(distance + 8)), 7.5)
	for distance in range(28, 430, 45):
		var signal_side := -1.0 if int(distance / 45) % 2 == 0 else 1.0
		_add_decoration(SIGN_MODEL, Vector3(signal_side * 7.2, 0.0, -float(distance)), 1.25)

func _add_obstacle(model: PackedScene, x: float, z: float) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("obstacle")
	body.add_to_group("recyclable_course")
	body.position = Vector3(x, GROUND_SURFACE_Y, z)
	var visual := model.instantiate()
	var visual_scale := 1.5
	var obstacle_size := Vector3(1.4, 1.5, 1.4)
	if model == ROCK_MODEL:
		visual_scale = 1.8
		obstacle_size = Vector3(1.8, 1.25, 1.55)
	elif model == STUMP_MODEL:
		visual_scale = 1.7
		obstacle_size = Vector3(1.5, 0.9, 1.7)
	elif model == LOG_MODEL:
		visual_scale = 1.25
		visual.position.y = 0.65
		obstacle_size = Vector3(2.5, 1.2, 1.8)
	elif model == SIGN_MODEL:
		visual_scale = 0.7
		visual.position.y = 0.7
		obstacle_size = Vector3(1.15, 1.4, 1.0)
	elif model == PINE_MODEL:
		visual_scale = 4.0
		visual.position.y = -0.22
		obstacle_size = Vector3(1.9, 4.0, 1.8)
	visual.scale = Vector3.ONE * visual_scale
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = obstacle_size
	collision.shape = shape
	collision.position.y = obstacle_size.y * 0.5
	body.add_child(collision)
	course.add_child(body)

func _add_giant_obstacle(model: PackedScene, x: float, z: float) -> void:
	var body := StaticBody3D.new()
	body.add_to_group("obstacle")
	body.add_to_group("recyclable_course")
	body.position = Vector3(x, GROUND_SURFACE_Y, z)
	var visual := model.instantiate()
	visual.scale = Vector3.ONE * (3.3 if model == BARREL_MODEL else 4.5)
	if model == PINE_MODEL:
		visual.position.y = -0.25
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.35, 3.25, 2.35)
	collision.shape = shape
	collision.position.y = shape.size.y * 0.5
	body.add_child(collision)
	course.add_child(body)

func _add_snow_bridge(x: float, z: float) -> void:
	var bridge := Node3D.new()
	bridge.add_to_group("recyclable_course")
	bridge.position = Vector3(x, GROUND_SURFACE_Y, z)

	var visual := SNOW_BRIDGE_MODEL.instantiate()
	# Se alarga solo en Z: conserva el ancho de un carril y la misma altura.
	visual.scale = Vector3(8.5, 8.5, 50.0)
	bridge.add_child(visual)

	# Superficie plana superior, sobre la que el personaje puede correr.
	var top_body := StaticBody3D.new()
	var top_collision := CollisionShape3D.new()
	var top_shape := BoxShape3D.new()
	top_shape.size = Vector3(2.6, 0.18, 32.0)
	top_collision.shape = top_shape
	top_collision.position = Vector3(0.0, 1.55, -9.0)
	top_body.add_child(top_collision)
	bridge.add_child(top_body)

	# Rampa de entrada: el extremo cercano comienza al nivel de la nieve.
	var ramp_body := StaticBody3D.new()
	var ramp_collision := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(2.6, 0.18, 18.2)
	ramp_collision.shape = ramp_shape
	ramp_collision.position = Vector3(0.0, 0.8, 16.0)
	ramp_collision.rotation_degrees.x = 5.0
	ramp_body.add_child(ramp_collision)
	bridge.add_child(ramp_body)

	course.add_child(bridge)

func _add_coin(x: float, z: float, height := 1.05) -> void:
	var area := Area3D.new()
	area.add_to_group("recyclable_course")
	area.position = Vector3(x, GROUND_SURFACE_Y + height, z)
	area.body_entered.connect(_on_coin_collected.bind(area))
	var visual := COIN_MODEL.instantiate()
	visual.scale = Vector3.ONE * 0.42
	area.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape
	area.add_child(collision)
	course.add_child(area)
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "rotation_degrees:y", 360.0, 1.2).from(0.0)

func _add_decoration(model: PackedScene, at: Vector3, size: float) -> void:
	var visual := model.instantiate()
	visual.add_to_group("recyclable_course")
	var vertical_offset := size if model == SIGN_MODEL else 0.0
	visual.position = at + Vector3.UP * (GROUND_SURFACE_Y + vertical_offset)
	visual.scale = Vector3.ONE * size
	course.add_child(visual)

func _on_coin_collected(body: Node3D, coin: Area3D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	collected_coins += 1
	coins_label.text = "%02d" % collected_coins
	coin.position.z -= LEVEL_LENGTH

func _on_player_crashed() -> void:
	if finished:
		return
	finished = true
	player.set_physics_process(false)
	message_title.text = "¡CUIDADO!"
	message_text.text = "Recogiste %d monedas\nPulsa ESPACIO o toca para reintentar" % collected_coins
	message_panel.show()

func _finish_level() -> void:
	finished = true
	player.set_physics_process(false)
	message_title.text = "¡MUNDO 1 COMPLETADO!"
	message_text.text = "Recogiste %d monedas\nPulsa ESPACIO o toca para jugar otra vez" % collected_coins
	message_panel.show()
