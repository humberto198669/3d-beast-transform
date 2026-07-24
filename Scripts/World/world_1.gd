extends Node3D

const GROUND_TILE := preload("res://Scenes/World1/ground_tile_01.tscn")
const COIN_MODEL := preload("res://Assets/Models/Objects/Coin.glb")
const GEM_MODEL := preload("res://Assets/Models/Collectibles/gema_verde.glb")
const BEAR_MODEL := preload("res://Characters/Bear/ethan_bear.fbx")
const BEAR_LEFT_TURN_MODEL := preload("res://Characters/Bear/Animation/ethan_bear_left_turn.fbx")
const BEAR_RIGHT_TURN_MODEL := preload("res://Characters/Bear/Animation/ethan_bear_right_turn.fbx")
const BEAR_JUMP_MODEL := preload("res://Characters/Bear/Animation/ethan_bear_jump.fbx")
const CRASH_BEAST_SMOKE := preload("res://Assets/Effects/Crash/impact_beast_smoke.png")
const CRASH_BEAST_FLASH := preload("res://Assets/Effects/Crash/impact_beast_flash.png")
const CRASH_BEAST_PAW := preload("res://Assets/Effects/Crash/impact_beast_paw.png")
const BARREL_MODEL := preload("res://Assets/Models/Obstacles/world1/barril.glb")
const ROCK_MODEL := preload("res://Assets/Models/Obstacles/world1/roca.glb")
const STUMP_MODEL := preload("res://Assets/Models/Obstacles/world1/tocon.glb")
const LOG_MODEL := preload("res://Assets/Models/Obstacles/world1/tronco.glb")
const PINE_MODEL := preload("res://Assets/Models/Obstacles/world1/Pino01.glb")
const DRY_TREE_MODEL := preload("res://Assets/Models/Obstacles/world1/Seco01.glb")
const SIGN_MODEL := preload("res://Assets/Models/Obstacles/world1/signal.glb")
const MAMMOTH_MODEL := preload("res://Assets/Models/Obstacles/world1/mamut.glb")
const GIANT_TRAIN_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/tren_gigante.glb")
const SLEIGH_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/trineo.glb")
const GIANT_PANEL_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/panel_gigante.glb")
const GATE_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/porton.glb")
const INTERMEDIATE_JUMP_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/salton_intermedio.glb")
const ICE_BRIDGE_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/puente_hielo.glb")
const SIDE_FOREST_MODULE_01 := preload("res://Assets/Models/Enviroment/world1/Modular/bosque_lateral_recto_01.glb")
const SIDE_FOREST_MODULE_02 := preload("res://Assets/Models/Enviroment/world1/Modular/bosque_lateral_recto_02.glb")
const SIDE_FOREST_RIGHT_MODULE_01 := preload("res://Assets/Models/Enviroment/world1/Modular/bosque_lateral_recto_derecho_01.glb")

const LANES := [-2.7, 0.0, 2.7]
# Solo existen los tres carriles jugables. El paisaje modular comienza justo
# después de ellos, como los edificios y aceras de Subway Surfers.
const TILE_COLUMNS := [-2.7, 0.0, 2.7]
const LEVEL_LENGTH := 420.0
const SIDE_MODULE_LENGTH := 42.0
const SIDE_MODULE_COUNT := 12
const SIDE_MODULE_LOOP_LENGTH := SIDE_MODULE_LENGTH * SIDE_MODULE_COUNT
const GROUND_ROWS := 18
const ROW_SPACING := 5.0
const GROUND_SURFACE_Y := 0.38
const SIDE_TRACK_HEIGHT := 0.3
const SIDE_ENVIRONMENT_Y := 0.2
const MIN_SPEED := 9.0
const SPEED_PER_LEVEL := 2.0
const START_SPEED_LEVEL := 7
const MAX_SPEED_LEVEL := 10
const DIFFICULTY_INTERVAL := 10.0
const MAMMOTH_SPEED := 20.0
const COURSE_CHECK_INTERVAL := 0.12
const SAFE_START_DISTANCE := 90
const DISTANCE_DIFFICULTY_STEP := 500.0
const SPEED_BONUS_PER_DISTANCE_STEP := 1.5
const MAX_DISTANCE_SPEED_BONUS := 12.0
const BEAST_TRANSFORM_DELAY := 3.0
const BEAST_REVEAL_DELAY := 2.1
const BEAST_DURATION := 15.0
const BEAST_SPEED := 42.0

@onready var player: CharacterBody3D = $Player
@onready var player_visual_pivot: Node3D = $Player/VisualPivot
@onready var ground: Node3D = $Ground
@onready var course: Node3D = $Course
@onready var side_snow_base: MeshInstance3D = $SideSnowBase
@onready var horizon_backdrop: Node3D = $HorizonBackdrop
@onready var distance_label: Label = $HUD/SafeArea/TopBar/Stats/Distance/Content/Value
@onready var coins_label: Label = $HUD/SafeArea/TopBar/Stats/CoinCounter/Content/Amount
@onready var gem_meter: Panel = $HUD/GemMeter
@onready var gem_fill: Panel = $HUD/GemMeter/Fill
@onready var safe_area: MarginContainer = $HUD/SafeArea
@onready var message_panel: Control = $HUD/MessagePanel
@onready var message_title: Label = $HUD/MessagePanel/Card/Content/Title
@onready var message_text: Label = $HUD/MessagePanel/Card/Content/Message

var ground_rows: Array = []
var mammoth_slots: Array[Vector2i] = []
var coin_lane_counts: Array[int] = [0, 0, 0]
var blocked_lane_sections: Array[Dictionary] = []
var course_check_elapsed := 0.0
var mammoth_path_check_elapsed := 0.0
var next_distance_difficulty := DISTANCE_DIFFICULTY_STEP
var distance_difficulty_stage := 0
var distance_speed_bonus := 0.0
var collected_coins := 0
var collected_gems := 0
var finished := false
var elapsed_time := 0.0
var speed_level := START_SPEED_LEVEL
var coin_glow_texture: GradientTexture2D
var gem_glow_texture: GradientTexture2D
var smoke_texture: GradientTexture2D
var crash_dust_texture: GradientTexture2D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var bear_visual: Node3D
var bear_left_visual: Node3D
var bear_right_visual: Node3D
var bear_jump_visual: Node3D
var bear_action_serial := 0
var transformation_in_progress := false
var beast_active := false
var crash_effect_playing := false
var run_progress_saved := false

func _ready() -> void:
	rng.randomize()
	coin_glow_texture = _create_coin_glow_texture()
	gem_glow_texture = _create_gem_glow_texture()
	smoke_texture = _create_smoke_texture()
	crash_dust_texture = _create_crash_dust_texture()
	_prepare_bear_visual()
	_build_ground()
	_build_course()
	_disable_horizon_shadows()
	player.crashed.connect(_on_player_crashed)
	player.beast_hit_mammoth.connect(_on_beast_hit_mammoth)
	player.lane_action_requested.connect(_on_bear_lane_action_requested)
	player.jump_action_requested.connect(_on_bear_jump_action_requested)
	get_viewport().size_changed.connect(_apply_mobile_safe_area)
	_apply_mobile_safe_area()
	_apply_speed_level()
	message_panel.hide()

func _apply_mobile_safe_area() -> void:
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	var display_safe_rect: Rect2i = DisplayServer.get_display_safe_area()
	if screen_size.x <= 0 or screen_size.y <= 0 or display_safe_rect.size == Vector2i.ZERO:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_to_viewport := Vector2(
		viewport_size.x / float(screen_size.x),
		viewport_size.y / float(screen_size.y)
	)
	var left_inset: float = float(display_safe_rect.position.x) * scale_to_viewport.x
	var top_inset: float = float(display_safe_rect.position.y) * scale_to_viewport.y
	var right_pixels: int = screen_size.x - display_safe_rect.end.x
	var right_inset: float = float(maxi(0, right_pixels)) * scale_to_viewport.x
	safe_area.offset_left = maxf(22.0, left_inset + 12.0)
	safe_area.offset_top = maxf(28.0, top_inset + 12.0)
	safe_area.offset_right = -maxf(22.0, right_inset + 12.0)
	gem_meter.offset_left = 28.0 + left_inset
	gem_meter.offset_right = 88.0 + left_inset

func _disable_horizon_shadows() -> void:
	for geometry_node: Node in horizon_backdrop.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = geometry_node as GeometryInstance3D
		if geometry != null:
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _prepare_bear_visual() -> void:
	bear_visual = BEAR_MODEL.instantiate() as Node3D
	bear_visual.name = "EthanBear"
	# Mas grande y ancho que la transformacion anterior para verse robusto.
	bear_visual.scale = Vector3(245.0, 225.0, 245.0)
	bear_visual.visible = false
	player_visual_pivot.add_child(bear_visual)
	bear_left_visual = _create_bear_action_visual(BEAR_LEFT_TURN_MODEL, "EthanBearLeft")
	bear_right_visual = _create_bear_action_visual(BEAR_RIGHT_TURN_MODEL, "EthanBearRight")
	bear_jump_visual = _create_bear_action_visual(BEAR_JUMP_MODEL, "EthanBearJump")
	bear_left_visual.rotation.z = deg_to_rad(-10.0)
	bear_right_visual.rotation.z = deg_to_rad(10.0)

func _create_bear_action_visual(model: PackedScene, visual_name: String) -> Node3D:
	var visual: Node3D = model.instantiate() as Node3D
	visual.name = visual_name
	visual.scale = Vector3(245.0, 225.0, 245.0)
	visual.visible = false
	player_visual_pivot.add_child(visual)
	return visual

func _on_bear_lane_action_requested(direction: int) -> void:
	if not beast_active or transformation_in_progress:
		return
	var action_visual: Node3D = bear_left_visual if direction < 0 else bear_right_visual
	_play_bear_action(action_visual, 1.4)

func _on_bear_jump_action_requested() -> void:
	if not beast_active or transformation_in_progress:
		return
	_play_bear_action(bear_jump_visual, 1.0)

func _play_bear_action(action_visual: Node3D, playback_speed: float) -> void:
	if action_visual == null:
		return
	bear_action_serial += 1
	var current_serial: int = bear_action_serial
	bear_visual.visible = false
	bear_left_visual.visible = action_visual == bear_left_visual
	bear_right_visual.visible = action_visual == bear_right_visual
	bear_jump_visual.visible = action_visual == bear_jump_visual
	var animation_player: AnimationPlayer = _find_animation_player(action_visual)
	if animation_player == null:
		_restore_bear_run(current_serial)
		return
	var animation_name: StringName = _first_animation_name(animation_player)
	if animation_name == &"":
		_restore_bear_run(current_serial)
		return
	var animation: Animation = animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	# Reinicia el gesto cuando el jugador encadena dos cambios de carril.
	animation_player.stop()
	animation_player.play(animation_name, -1.0, playback_speed)
	animation_player.seek(0.0, true)
	await animation_player.animation_finished
	_restore_bear_run(current_serial)

func _find_animation_player(root: Node) -> AnimationPlayer:
	var animation_nodes: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
	for animation_node: Node in animation_nodes:
		var animation_player: AnimationPlayer = animation_node as AnimationPlayer
		if animation_player != null:
			return animation_player
	return null

func _first_animation_name(animation_player: AnimationPlayer) -> StringName:
	for animation_name: StringName in animation_player.get_animation_list():
		if animation_name != &"RESET":
			return animation_name
	return &""

func _restore_bear_run(expected_serial: int) -> void:
	if expected_serial != bear_action_serial or not beast_active or transformation_in_progress:
		return
	bear_left_visual.visible = false
	bear_right_visual.visible = false
	bear_jump_visual.visible = false
	bear_visual.visible = true
	_play_mammoth_animation(bear_visual)

func _start_beast_transformation() -> void:
	if transformation_in_progress or beast_active or finished:
		return
	transformation_in_progress = true
	player.call("set_controls_enabled", false)
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	player.call("set_human_form_visible", false)
	_play_transformation_smoke(BEAST_TRANSFORM_DELAY)
	await get_tree().create_timer(BEAST_REVEAL_DELAY).timeout
	if finished:
		return
	bear_left_visual.visible = false
	bear_right_visual.visible = false
	bear_jump_visual.visible = false
	bear_visual.visible = true
	_play_mammoth_animation(bear_visual)
	await get_tree().create_timer(BEAST_TRANSFORM_DELAY - BEAST_REVEAL_DELAY).timeout
	if finished:
		return
	player.call("set_beast_mode", true)
	player.speed = BEAST_SPEED
	beast_active = true
	transformation_in_progress = false
	player.call("set_controls_enabled", true)
	player.set_physics_process(true)

	await get_tree().create_timer(BEAST_DURATION).timeout
	if finished:
		return
	transformation_in_progress = true
	player.call("set_controls_enabled", false)
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	bear_action_serial += 1
	bear_visual.visible = false
	bear_left_visual.visible = false
	bear_right_visual.visible = false
	bear_jump_visual.visible = false
	_play_transformation_smoke(BEAST_TRANSFORM_DELAY)
	await get_tree().create_timer(BEAST_REVEAL_DELAY).timeout
	player.call("set_human_form_visible", true)
	await get_tree().create_timer(BEAST_TRANSFORM_DELAY - BEAST_REVEAL_DELAY).timeout
	player.call("set_beast_mode", false)
	beast_active = false
	collected_gems = 0
	_update_gem_fill_shape()
	var empty_top: float = gem_meter.size.y - 2.0
	create_tween().tween_property(gem_fill, "offset_top", empty_top, 0.3)
	_apply_speed_level()
	transformation_in_progress = false
	player.call("set_controls_enabled", true)
	player.set_physics_process(true)

func _play_transformation_smoke(duration: float) -> void:
	var smoke_root: Node3D = Node3D.new()
	add_child(smoke_root)
	smoke_root.global_position = player.global_position + Vector3.UP * 1.0

	# Version envolvente del mismo humo bestial usado en el choque.
	var beast_cloud: Sprite3D = Sprite3D.new()
	beast_cloud.texture = CRASH_BEAST_SMOKE
	beast_cloud.pixel_size = 0.0028
	beast_cloud.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	beast_cloud.shaded = false
	beast_cloud.no_depth_test = true
	beast_cloud.modulate = Color(0.88, 1.0, 0.78, 0.0)
	beast_cloud.scale = Vector3.ONE * 0.12
	beast_cloud.position.z = 0.05
	smoke_root.add_child(beast_cloud)
	var cloud_tween: Tween = create_tween()
	cloud_tween.tween_property(beast_cloud, "modulate:a", 0.94, 0.18)
	cloud_tween.parallel().tween_property(beast_cloud, "scale", Vector3.ONE * 2.25, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cloud_tween.tween_interval(maxf(0.2, duration - 1.02))
	cloud_tween.tween_property(beast_cloud, "modulate:a", 0.0, 0.42).set_ease(Tween.EASE_IN)

	var transform_flash: Sprite3D = Sprite3D.new()
	transform_flash.texture = CRASH_BEAST_FLASH
	transform_flash.pixel_size = 0.0025
	transform_flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	transform_flash.shaded = false
	transform_flash.no_depth_test = true
	transform_flash.scale = Vector3.ONE * 0.12
	transform_flash.position.z = 0.08
	smoke_root.add_child(transform_flash)
	var flash_tween: Tween = create_tween().set_parallel(true)
	flash_tween.tween_property(transform_flash, "scale", Vector3.ONE * 1.35, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(transform_flash, "modulate:a", 0.0, 0.48).set_delay(0.08)

	for paw_index: int in range(4):
		var paw: Sprite3D = Sprite3D.new()
		paw.texture = CRASH_BEAST_PAW
		paw.pixel_size = 0.0022
		paw.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		paw.shaded = false
		paw.no_depth_test = true
		paw.modulate = Color(0.82, 1.0, 0.42, 0.0)
		paw.scale = Vector3.ONE * 0.28
		paw.position = Vector3(-0.42 + float(paw_index % 2) * 0.84, -0.25, 0.09 + float(paw_index) * 0.01)
		smoke_root.add_child(paw)
		var paw_delay: float = 0.22 + float(paw_index) * 0.28
		var paw_tween: Tween = create_tween().set_parallel(true)
		paw_tween.tween_property(paw, "modulate:a", 0.9, 0.16).set_delay(paw_delay)
		paw_tween.tween_property(paw, "position:y", 0.9 + float(paw_index) * 0.16, 1.15).set_delay(paw_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		paw_tween.tween_property(paw, "scale", Vector3.ONE * 0.58, 1.0).set_delay(paw_delay)
		paw_tween.tween_property(paw, "modulate:a", 0.0, 0.35).set_delay(paw_delay + 0.82)

	# Volutas secundarias suavizan el borde de la imagen principal.
	for _smoke_index: int in range(8):
		var smoke: Sprite3D = Sprite3D.new()
		smoke.texture = smoke_texture
		smoke.pixel_size = rng.randf_range(0.006, 0.01)
		smoke.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		smoke.shaded = false
		smoke.modulate = Color(0.7, 1.0, 0.45, 0.68)
		smoke.position = Vector3(
			rng.randf_range(-0.48, 0.48),
			rng.randf_range(-0.4, 0.5),
			rng.randf_range(-0.5, 0.5)
		)
		smoke_root.add_child(smoke)
		var smoke_tween: Tween = create_tween().set_parallel(true)
		smoke_tween.tween_property(smoke, "position", smoke.position + Vector3(rng.randf_range(-0.28, 0.28), rng.randf_range(0.65, 1.15), 0.0), duration)
		smoke_tween.tween_property(smoke, "scale", Vector3.ONE * rng.randf_range(1.3, 2.0), duration)
		smoke_tween.tween_property(smoke, "modulate:a", 0.0, duration)
	get_tree().create_timer(duration + 0.05).timeout.connect(smoke_root.queue_free)

func _create_smoke_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.94, 1.0, 0.96, 0.95),
		Color(0.7, 0.84, 0.76, 0.5),
		Color(0.55, 0.68, 0.6, 0.0)
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture

func _create_crash_dust_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 0.96),
		Color(0.82, 0.92, 1.0, 0.62),
		Color(0.55, 0.7, 0.82, 0.0)
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture

func _process(_delta: float) -> void:
	if finished:
		return
	if transformation_in_progress:
		return
	_recycle_ground()
	course_check_elapsed += _delta
	if course_check_elapsed >= COURSE_CHECK_INTERVAL:
		course_check_elapsed = 0.0
		_recycle_course()
	_update_mammoths(_delta)
	_update_difficulty(_delta)
	# Mantiene nieve visible hasta el horizonte, muy por delante de la cámara.
	side_snow_base.position.z = player.position.z - 500.0
	# Fondo distante estable: acompana la carrera sin acercarse como un obstaculo.
	horizon_backdrop.position.z = player.position.z - 650.0
	var distance := maxf(0.0, -player.global_position.z)
	distance_label.text = "%03d m" % int(distance)
	_update_distance_difficulty(distance)

func _update_difficulty(delta: float) -> void:
	elapsed_time += delta
	var new_level := mini(START_SPEED_LEVEL + int(elapsed_time / DIFFICULTY_INTERVAL), MAX_SPEED_LEVEL)
	if new_level == speed_level:
		return
	speed_level = new_level
	_apply_speed_level()

func _apply_speed_level() -> void:
	# Nivel 1 = 9, nivel 7 = 21 y nivel 10 = 27 unidades por segundo.
	if beast_active:
		player.speed = BEAST_SPEED
		return
	player.speed = MIN_SPEED + float(speed_level - 1) * SPEED_PER_LEVEL + distance_speed_bonus

func _update_distance_difficulty(distance: float) -> void:
	if distance < next_distance_difficulty:
		return
	distance_difficulty_stage += 1
	next_distance_difficulty += DISTANCE_DIFFICULTY_STEP
	if distance >= 1500.0:
		distance_speed_bonus = MAX_DISTANCE_SPEED_BONUS
	else:
		distance_speed_bonus = minf(
			float(distance_difficulty_stage) * SPEED_BONUS_PER_DISTANCE_STEP,
			MAX_DISTANCE_SPEED_BONUS
		)
	_apply_speed_level()
	# Los nuevos obstaculos quedan en el circuito y se reciclan, por eso la
	# densidad aumenta de forma acumulativa sin crear decenas de golpe.
	_add_distance_difficulty_obstacles(2)

func _add_distance_difficulty_obstacles(amount: int) -> void:
	var difficulty_models: Array[PackedScene] = [
		BARREL_MODEL, LOG_MODEL, INTERMEDIATE_JUMP_MODEL,
		GIANT_PANEL_MODEL, GATE_MODEL
	]
	for obstacle_index: int in range(amount):
		var placed := false
		for _attempt: int in range(10):
			var ahead: float = 115.0 + float(obstacle_index) * 75.0 + rng.randf_range(0.0, 38.0)
			var spawn_z: float = player.global_position.z - ahead
			var repeated_distance: int = int(fposmod(-spawn_z, LEVEL_LENGTH))
			var lane_candidates: Array[int] = _allowed_lanes_for_distance(repeated_distance)
			if lane_candidates.is_empty():
				continue
			var lane_index: int = lane_candidates[rng.randi_range(0, lane_candidates.size() - 1)]
			var spawn_x: float = LANES[lane_index]
			if not _is_difficulty_spawn_clear(spawn_x, spawn_z):
				continue
			var model: PackedScene = difficulty_models[rng.randi_range(0, difficulty_models.size() - 1)]
			_add_selected_obstacle(model, spawn_x, spawn_z)
			placed = true
			break
		if not placed:
			continue

func _is_difficulty_spawn_clear(spawn_x: float, spawn_z: float) -> bool:
	for obstacle_value in get_tree().get_nodes_in_group("obstacle"):
		var obstacle: Node3D = obstacle_value as Node3D
		if obstacle == null:
			continue
		if absf(obstacle.global_position.z - spawn_z) < 12.0 \
		and absf(obstacle.global_position.x - spawn_x) < 0.9:
			return false
	for coin_value in get_tree().get_nodes_in_group("collectible_coin"):
		var coin: Area3D = coin_value as Area3D
		if coin == null:
			continue
		if absf(coin.global_position.z - spawn_z) < 7.0 \
		and absf(coin.global_position.x - spawn_x) < 0.9:
			return false
	return true

func _has_course_overlap(x: float, z: float, separation: float) -> bool:
	for obstacle_value in get_tree().get_nodes_in_group("obstacle"):
		var obstacle: Node3D = obstacle_value as Node3D
		if obstacle == null or obstacle.is_queued_for_deletion():
			continue
		if absf(obstacle.global_position.x - x) < 1.0 \
		and absf(obstacle.global_position.z - z) < separation:
			return true
	for coin_value in get_tree().get_nodes_in_group("collectible_coin"):
		var coin: Area3D = coin_value as Area3D
		if coin == null or coin.is_queued_for_deletion():
			continue
		if absf(coin.global_position.x - x) < 1.0 \
		and absf(coin.global_position.z - z) < separation:
			return true
	for gem_value in get_tree().get_nodes_in_group("collectible_gem"):
		var gem: Area3D = gem_value as Area3D
		if gem == null or gem.is_queued_for_deletion():
			continue
		if absf(gem.global_position.x - x) < 1.0 \
		and absf(gem.global_position.z - z) < separation:
			return true
	return false

func _recycle_course() -> void:
	for item in get_tree().get_nodes_in_group("recyclable_course"):
		if item.is_in_group("moving_mammoth"):
			continue
		if is_instance_valid(item) and item.global_position.z > player.global_position.z + 12.0:
			# El paisaje lateral cubre mas distancia para ocultar su union final.
			var recycle_length: float = SIDE_MODULE_LOOP_LENGTH if item.is_in_group("side_environment_module") else LEVEL_LENGTH
			item.position.z -= recycle_length

func _update_mammoths(delta: float) -> void:
	mammoth_path_check_elapsed += delta
	var should_check_path: bool = mammoth_path_check_elapsed >= COURSE_CHECK_INTERVAL
	if should_check_path:
		mammoth_path_check_elapsed = 0.0
	for mammoth_value in get_tree().get_nodes_in_group("moving_mammoth"):
		var mammoth: AnimatableBody3D = mammoth_value as AnimatableBody3D
		if mammoth == null:
			continue
		if bool(mammoth.get_meta("repositioning", false)):
			continue
		if should_check_path:
			if _mammoth_is_approaching_bridge(mammoth):
				_reposition_mammoth_ahead(mammoth)
				continue
			_clear_mammoth_path(mammoth)
		mammoth.position.z += MAMMOTH_SPEED * delta
		if mammoth.global_position.z > player.global_position.z + 14.0:
			_reposition_mammoth_ahead(mammoth)

func _mammoth_is_approaching_bridge(mammoth: AnimatableBody3D) -> bool:
	for bridge_value in get_tree().get_nodes_in_group("snow_bridge_zone"):
		var bridge: Node3D = bridge_value as Node3D
		if bridge == null or bridge.is_queued_for_deletion():
			continue
		if absf(bridge.global_position.x - mammoth.global_position.x) >= 1.1:
			continue
		var distance_to_bridge: float = bridge.global_position.z - mammoth.global_position.z
		if distance_to_bridge > -6.0 and distance_to_bridge < 52.0:
			return true
	for blocker_value in get_tree().get_nodes_in_group("long_lane_blocker"):
		var blocker: Node3D = blocker_value as Node3D
		if blocker == null or blocker.is_queued_for_deletion():
			continue
		if absf(blocker.global_position.x - mammoth.global_position.x) >= 1.1:
			continue
		var blocker_half_length: float = float(blocker.get_meta("half_length", 10.0))
		var distance_to_blocker: float = blocker.global_position.z - mammoth.global_position.z
		if distance_to_blocker > -8.0 and distance_to_blocker < blocker_half_length + 24.0:
			return true
	return false

func _reposition_mammoth_ahead(mammoth: AnimatableBody3D) -> void:
	if bool(mammoth.get_meta("repositioning", false)):
		return
	mammoth.set_meta("repositioning", true)
	mammoth.visible = false
	# Busca una posicion distante que no comparta el corredor longitudinal
	# de ningun puente. Así el mamut siempre parece venir desde el horizonte.
	var target_position: Vector3 = Vector3(
		0.0,
		GROUND_SURFACE_Y - 0.1,
		player.global_position.z - 390.0
	)
	for _attempt: int in range(18):
		var lane_index: int = rng.randi_range(0, LANES.size() - 1)
		var candidate: Vector3 = Vector3(
			LANES[lane_index],
			GROUND_SURFACE_Y - 0.1,
			player.global_position.z - rng.randf_range(230.0, 350.0)
		)
		var bridge_clear: bool = true
		for bridge_value in get_tree().get_nodes_in_group("snow_bridge_zone"):
			var bridge: Node3D = bridge_value as Node3D
			if bridge == null or bridge.is_queued_for_deletion():
				continue
			if absf(bridge.global_position.x - candidate.x) < 1.1 \
			and absf(bridge.global_position.z - candidate.z) < 62.0:
				bridge_clear = false
				break
		if bridge_clear and not _has_course_overlap(candidate.x, candidate.z, 42.0):
			target_position = candidate
			break
	mammoth.global_position = target_position
	mammoth.rotation = Vector3.ZERO
	mammoth.reset_physics_interpolation()
	# Evita que el render mezcle la posicion anterior con la nueva y produzca
	# una silueta doble semitransparente.
	await get_tree().physics_frame
	if not is_instance_valid(mammoth):
		return
	mammoth.reset_physics_interpolation()
	mammoth.visible = true
	mammoth.set_meta("repositioning", false)

func _clear_mammoth_path(mammoth: AnimatableBody3D) -> void:
	# Retira solamente lo que el mamut esta a punto de atravesar. De esta forma
	# el resto del circuito conserva monedas y obstaculos en los tres carriles.
	for obstacle_value in get_tree().get_nodes_in_group("obstacle"):
		var obstacle: Node3D = obstacle_value as Node3D
		if obstacle == null or obstacle == mammoth or obstacle.is_in_group("moving_mammoth"):
			continue
		if absf(obstacle.global_position.x - mammoth.global_position.x) < 0.8 \
		and absf(obstacle.global_position.z - mammoth.global_position.z) < 18.0:
			obstacle.queue_free()
	for coin_value in get_tree().get_nodes_in_group("collectible_coin"):
		var coin: Area3D = coin_value as Area3D
		if coin == null:
			continue
		if absf(coin.global_position.x - mammoth.global_position.x) < 0.8 \
		and absf(coin.global_position.z - mammoth.global_position.z) < 18.0:
			coin.queue_free()
	for gem_value in get_tree().get_nodes_in_group("collectible_gem"):
		var gem: Area3D = gem_value as Area3D
		if gem == null:
			continue
		if absf(gem.global_position.x - mammoth.global_position.x) < 0.8 \
		and absf(gem.global_position.z - mammoth.global_position.z) < 18.0:
			gem.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if finished and not crash_effect_playing and (event.is_action_pressed("uiaccept") or (event is InputEventScreenTouch and event.pressed)):
		SceneTransition.change_scene("res://Scenes/Menu.tscn")

func _build_ground() -> void:
	for row_index in range(GROUND_ROWS):
		var row: Array = []
		var z: float = 10.0 - row_index * ROW_SPACING
		for lane_x in TILE_COLUMNS:
			var tile := GROUND_TILE.instantiate()
			# El modelo original es horizontal. Girarlo y escalar sus ejes por
			# separado crea franjas largas alineadas con la dirección de carrera.
			tile.rotation_degrees.y = 90.0
			tile.scale = Vector3(2.5, 2.5, 3.0)
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
	# Cada mamut recibe un corredor reservado. Los demas generadores consultan
	# estos espacios para no colocar monedas ni obstaculos atravesando su cuerpo.
	mammoth_slots.clear()
	coin_lane_counts = [0, 0, 0]
	blocked_lane_sections.clear()
	var first_mammoth_lane: int = rng.randi_range(0, LANES.size() - 1)
	# Nace cerca del limite visible para que primero se distinga en el horizonte.
	mammoth_slots.append(Vector2i(408, first_mammoth_lane))
	var bridge_lane: int = rng.randi_range(0, LANES.size() - 1)
	_add_ice_bridge(LANES[bridge_lane], -122.0)
	for bridge_distance: int in range(94, 151, 9):
		_add_coin(LANES[bridge_lane], -float(bridge_distance), 2.15)

	var combo_lanes: Array[int] = [0, 1, 2]
	combo_lanes.shuffle()
	var train_lane: int = combo_lanes[0]
	var sleigh_lane: int = combo_lanes[1]
	var safe_lane: int = combo_lanes[2]
	var blocked_lanes: Array[int] = []
	var long_obstacle_roll: int = rng.randi_range(0, 99)
	if long_obstacle_roll < 45:
		# Combinación difícil: dos carriles bloqueados y una sola salida.
		blocked_lanes.assign([train_lane, sleigh_lane])
		_add_full_lane_blocker(GIANT_TRAIN_MODEL, LANES[train_lane], -220.0, Vector3(2.45, 3.15, 30.0), true)
		_add_full_lane_blocker(SLEIGH_MODEL, LANES[sleigh_lane], -220.0, Vector3(2.35, 2.35, 12.0), true)
	elif long_obstacle_roll < 73:
		# Solo tren: cualquiera de los otros dos carriles puede ser la ruta segura.
		blocked_lanes.append(train_lane)
		safe_lane = combo_lanes[rng.randi_range(1, 2)]
		_add_full_lane_blocker(GIANT_TRAIN_MODEL, LANES[train_lane], -220.0, Vector3(2.45, 3.15, 30.0), true)
	else:
		# Solo trineo.
		blocked_lanes.append(sleigh_lane)
		safe_lane = combo_lanes[0] if rng.randi_range(0, 1) == 0 else combo_lanes[2]
		_add_full_lane_blocker(SLEIGH_MODEL, LANES[sleigh_lane], -220.0, Vector3(2.35, 2.35, 12.0), true)
	blocked_lane_sections.append({"from": 204, "to": 236, "blocked": blocked_lanes, "safe": safe_lane})
	for reward_distance: int in range(204, 237, 7):
		_add_coin(LANES[safe_lane], -float(reward_distance))
	_add_gem(LANES[safe_lane], -222.0)
	var obstacle_data := [
		[158, BARREL_MODEL], [276, GIANT_PANEL_MODEL], [316, LOG_MODEL],
		[352, INTERMEDIATE_JUMP_MODEL], [388, GATE_MODEL]
	]
	var obstacle_slots: Array[Vector2i] = []
	for data in obstacle_data:
		var distance: int = int(data[0])
		if distance < SAFE_START_DISTANCE:
			continue
		var model: PackedScene = data[1] as PackedScene
		var lane_index: int = _choose_obstacle_lane(distance, obstacle_slots)
		if lane_index < 0:
			continue
		obstacle_slots.append(Vector2i(distance, lane_index))
		_add_selected_obstacle(model, LANES[lane_index], -float(distance))
	# Barreras altas: no se pueden saltar y fuerzan un cambio de carril.
	# Mamuts que corren hacia el jugador y bloquean un carril completo.
	_add_mammoth(LANES[first_mammoth_lane], -408.0)
	# Un puente central largo y, más adelante, dos puentes laterales paralelos.
	var coin_clusters := [
		[12, 18, 24], [42, 48], [62, 68, 74], [92, 101],
		[146, 154], [166, 174, 182], [258, 266], [288, 296],
		[326, 334], [362, 370], [402]
	]
	for cluster_value in coin_clusters:
		var cluster: Array = cluster_value as Array
		var coin_lane: int = _choose_safe_coin_lane(cluster, obstacle_slots)
		if coin_lane < 0:
			continue
		for distance_value in cluster:
			_add_coin(LANES[coin_lane], -float(distance_value))
	# Coleccionables raros: tres oportunidades por cada tramo completo.
	for gem_distance: int in [78, 292, 372]:
		_add_gem_in_safe_lane(gem_distance)

	# Bosque lateral asimétrico: modelos, tamaños, giros y profundidad variables.
	# Prueba visual: únicamente árboles Seco01 forman ambos costados.
	for distance in range(12, 430, 18):
		var left_z: float = -float(distance) + rng.randf_range(-2.5, 2.5)
		var right_z: float = -float(distance) + rng.randf_range(-2.5, 2.5)
		_add_decoration(DRY_TREE_MODEL, Vector3(-rng.randf_range(14.0, 16.0), 0.0, left_z), rng.randf_range(8.0, 11.0), rng.randf_range(0.0, 360.0))
		_add_decoration(DRY_TREE_MODEL, Vector3(rng.randf_range(14.0, 16.0), 0.0, right_z), rng.randf_range(8.0, 11.0), rng.randf_range(0.0, 360.0))
	var signal_distance: int = rng.randi_range(25, 38)
	while signal_distance < 420:
		var signal_side: float = -1.0 if rng.randi_range(0, 1) == 0 else 1.0
		_add_decoration(SIGN_MODEL, Vector3(signal_side * rng.randf_range(6.9, 7.4), 0.0, -float(signal_distance)), rng.randf_range(1.05, 1.3), rng.randf_range(-10.0, 10.0))
		signal_distance += rng.randi_range(34, 50)
	# Franja continua de prueba: diez módulos por cada lado cubren todo el tramo.
	for module_index: int in range(SIDE_MODULE_COUNT):
		var module_z: float = -20.0 - float(module_index) * SIDE_MODULE_LENGTH
		_add_side_forest_module(Vector3(-6.1, 0.0, module_z), false, module_index)
		_add_side_forest_module(Vector3(6.1, 0.0, module_z), true, module_index + 3)

func _allowed_lanes_for_distance(distance: int) -> Array[int]:
	var candidates: Array[int] = [0, 1, 2]
	for section: Dictionary in blocked_lane_sections:
		var section_from: int = int(section.get("from", -1))
		var section_to: int = int(section.get("to", -1))
		if distance < section_from or distance > section_to:
			continue
		var blocked_lanes: Array = section.get("blocked", []) as Array
		for blocked_lane_value in blocked_lanes:
			candidates.erase(int(blocked_lane_value))
	return candidates

func _choose_obstacle_lane(distance: int, occupied: Array[Vector2i]) -> int:
	var candidates: Array[int] = _allowed_lanes_for_distance(distance)
	_remove_mammoth_corridor_lanes(candidates, distance)
	for slot: Vector2i in occupied:
		if slot.x == distance:
			candidates.erase(slot.y)
	# Siempre queda al menos un carril totalmente libre para el jugador.
	if candidates.size() <= 1:
		return -1
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _choose_safe_coin_lane(distances: Array, obstacles: Array[Vector2i]) -> int:
	var candidates: Array[int] = [0, 1, 2]
	for distance_value in distances:
		var distance: int = int(distance_value)
		var allowed: Array[int] = _allowed_lanes_for_distance(distance)
		for lane_value in candidates.duplicate():
			var lane_index: int = int(lane_value)
			if not allowed.has(lane_index):
				candidates.erase(lane_index)
		_remove_mammoth_corridor_lanes(candidates, distance)
		for slot: Vector2i in obstacles:
			if abs(slot.x - distance) <= 3:
				candidates.erase(slot.y)
	if candidates.is_empty():
		return -1
	var least_used_count: int = 1000000
	var least_used_lanes: Array[int] = []
	for candidate_lane: int in candidates:
		var usage_count: int = coin_lane_counts[candidate_lane]
		if usage_count < least_used_count:
			least_used_count = usage_count
			least_used_lanes = [candidate_lane]
		elif usage_count == least_used_count:
			least_used_lanes.append(candidate_lane)
	var selected_lane: int = least_used_lanes[rng.randi_range(0, least_used_lanes.size() - 1)]
	coin_lane_counts[selected_lane] += 1
	return selected_lane

func _remove_mammoth_corridor_lanes(candidates: Array[int], _distance: int) -> void:
	# Solo se reserva el espacio donde aparecen; durante la carrera cada mamut
	# limpia dinamicamente su camino sin vaciar un carril completo.
	for mammoth_slot: Vector2i in mammoth_slots:
		if abs(mammoth_slot.x - _distance) <= 30:
			candidates.erase(mammoth_slot.y)

func _decoration_scale(model: PackedScene) -> float:
	if model == PINE_MODEL or model == DRY_TREE_MODEL:
		return rng.randf_range(6.5, 10.5)
	if model == ROCK_MODEL:
		return rng.randf_range(1.8, 3.2)
	if model == STUMP_MODEL:
		return rng.randf_range(1.4, 2.4)
	return rng.randf_range(1.0, 1.8)

func _add_selected_obstacle(model: PackedScene, x: float, z: float) -> void:
	if model == GIANT_PANEL_MODEL or model == GATE_MODEL:
		_add_full_lane_blocker(model, x, z, Vector3(2.45, 3.3, 1.35))
	elif model == INTERMEDIATE_JUMP_MODEL:
		_add_intermediate_obstacle(x, z)
	else:
		_add_obstacle(model, x, z)

func _add_full_lane_blocker(model: PackedScene, x: float, z: float, target_size: Vector3, preserve_proportions: bool = false) -> void:
	if _has_course_overlap(x, z, maxf(8.0, target_size.z * 0.5)):
		return
	var body: StaticBody3D = StaticBody3D.new()
	body.add_to_group("obstacle")
	body.add_to_group("recyclable_course")
	body.add_to_group("full_lane_blocker")
	if target_size.z > 8.0:
		body.add_to_group("long_lane_blocker")
	body.set_meta("half_length", target_size.z * 0.5)
	body.position = Vector3(x, GROUND_SURFACE_Y, z)
	var visual: Node3D = model.instantiate() as Node3D
	body.add_child(visual)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = target_size
	collision.shape = shape
	collision.position.y = target_size.y * 0.5
	body.add_child(collision)
	course.add_child(body)
	if model == GIANT_TRAIN_MODEL or model == SLEIGH_MODEL:
		# El tren y el trineo, igual que el puente de hielo, traen su eje largo
		# sobre X. Se giran y dimensionan usando los ejes intercambiados.
		_fit_bridge_visual(visual, target_size)
	elif preserve_proportions:
		var fitted_size: Vector3 = _fit_long_visual_preserving_proportions(visual, target_size)
		if fitted_size.z > 0.1:
			# La colisión termina donde termina el modelo; así no queda una pared invisible.
			shape.size.z = fitted_size.z
			body.set_meta("half_length", fitted_size.z * 0.5)
	else:
		_fit_visual_to_box(visual, target_size)

func _fit_long_visual_preserving_proportions(visual: Node3D, target_size: Vector3) -> Vector3:
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return Vector3.ZERO
	# Estos modelos ya fueron exportados mirando en la dirección correcta del
	# camino. No se giran automáticamente: hacerlo mostraba el extremo angosto
	# del tren, el trineo y el puente hacia la cámara.
	# El ancho determina también la longitud para no aplastar ni estirar el modelo.
	# La altura se ajusta aparte porque muchos modelos de Meshy incluyen salientes
	# muy largos que falsean su caja y hacían que todo se viera diminuto.
	var horizontal_scale: float = target_size.x / bounds.size.x
	var vertical_scale: float = target_size.y / bounds.size.y
	visual.scale = Vector3(horizontal_scale, vertical_scale, horizontal_scale)
	visual.position = Vector3(
		-(bounds.position.x + bounds.size.x * 0.5) * horizontal_scale,
		-bounds.position.y * vertical_scale,
		-(bounds.position.z + bounds.size.z * 0.5) * horizontal_scale
	)
	return Vector3(
		bounds.size.x * horizontal_scale,
		bounds.size.y * vertical_scale,
		bounds.size.z * horizontal_scale
	)

func _fit_bridge_visual(visual: Node3D, target_size: Vector3) -> void:
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return
	# El largo original del puente está sobre X. Después del giro, X pasa a ser
	# el largo del camino (Z) y Z pasa a ser el ancho visible del carril (X).
	var bridge_scale: Vector3 = Vector3(
		target_size.z / bounds.size.x,
		target_size.y / bounds.size.y,
		target_size.x / bounds.size.z
	)
	var angle: float = deg_to_rad(90.0)
	visual.rotation.y = angle
	visual.scale = bridge_scale
	var scaled_anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * bridge_scale.x,
		bounds.position.y * bridge_scale.y,
		(bounds.position.z + bounds.size.z * 0.5) * bridge_scale.z
	)
	var rotated_anchor: Vector3 = scaled_anchor.rotated(Vector3.UP, angle)
	visual.position = -rotated_anchor

func _add_intermediate_obstacle(x: float, z: float) -> void:
	if _has_course_overlap(x, z, 8.0):
		return
	var body: StaticBody3D = StaticBody3D.new()
	body.add_to_group("obstacle")
	body.add_to_group("recyclable_course")
	body.add_to_group("slide_or_jump_obstacle")
	body.position = Vector3(x, GROUND_SURFACE_Y, z)
	var visual: Node3D = INTERMEDIATE_JUMP_MODEL.instantiate() as Node3D
	body.add_child(visual)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.35, 0.52, 0.8)
	collision.shape = shape
	# Corredor libre debajo de 0.8 m y espacio superior para superar saltando.
	collision.position.y = 1.06
	body.add_child(collision)
	course.add_child(body)
	_fit_visual_to_box(visual, Vector3(2.5, 2.65, 1.15))

func _fit_visual_to_box(visual: Node3D, target_size: Vector3) -> void:
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return
	var fitted_scale: Vector3 = Vector3(
		target_size.x / bounds.size.x,
		target_size.y / bounds.size.y,
		target_size.z / bounds.size.z
	)
	visual.scale = fitted_scale
	visual.position = Vector3(
		-(bounds.position.x + bounds.size.x * 0.5) * fitted_scale.x,
		-bounds.position.y * fitted_scale.y,
		-(bounds.position.z + bounds.size.z * 0.5) * fitted_scale.z
	)

func _calculate_visual_bounds(root: Node3D) -> AABB:
	var combined_bounds: AABB = AABB()
	var has_bounds: bool = false
	var root_inverse: Transform3D = root.global_transform.affine_inverse()
	if root is MeshInstance3D:
		var root_mesh: MeshInstance3D = root as MeshInstance3D
		if root_mesh.mesh != null:
			combined_bounds = root_mesh.get_aabb()
			has_bounds = true
	for mesh_node: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = mesh_node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var relative_transform: Transform3D = root_inverse * mesh_instance.global_transform
		var transformed_bounds: AABB = relative_transform * mesh_instance.get_aabb()
		combined_bounds = transformed_bounds if not has_bounds else combined_bounds.merge(transformed_bounds)
		has_bounds = true
	return combined_bounds

func _add_obstacle(model: PackedScene, x: float, z: float) -> void:
	if _has_course_overlap(x, z, 7.0):
		return
	var body := StaticBody3D.new()
	body.add_to_group("obstacle")
	body.add_to_group("recyclable_course")
	if model == SIGN_MODEL:
		body.add_to_group("signal_obstacle")
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
	if _has_course_overlap(x, z, 10.0):
		return
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

func _add_mammoth(x: float, z: float) -> void:
	var mammoth: AnimatableBody3D = AnimatableBody3D.new()
	mammoth.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	mammoth.add_to_group("obstacle")
	mammoth.add_to_group("moving_mammoth")
	mammoth.add_to_group("recyclable_course")
	mammoth.position = Vector3(x, GROUND_SURFACE_Y - 0.1, z)

	var visual: Node3D = MAMMOTH_MODEL.instantiate() as Node3D
	visual.name = "MammothVisual"
	visual.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	visual.scale = Vector3.ONE * 1900.0
	mammoth.add_child(visual)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.45, 3.6, 5.2)
	collision.shape = shape
	collision.position.y = 1.8
	mammoth.add_child(collision)
	course.add_child(mammoth)
	_play_mammoth_animation(visual)

func _play_mammoth_animation(root: Node) -> void:
	var animation_nodes: Array[Node] = root.find_children("*", "AnimationPlayer", true, false)
	for animation_node: Node in animation_nodes:
		var animation_player: AnimationPlayer = animation_node as AnimationPlayer
		if animation_player == null:
			continue
		var animation_names: PackedStringArray = animation_player.get_animation_list()
		for animation_name: StringName in animation_names:
			if animation_name == &"RESET":
				continue
			var animation: Animation = animation_player.get_animation(animation_name)
			if animation != null:
				animation.loop_mode = Animation.LOOP_LINEAR
			animation_player.play(animation_name)
			return

func _add_ice_bridge(x: float, z: float) -> void:
	var bridge := Node3D.new()
	bridge.add_to_group("recyclable_course")
	bridge.add_to_group("snow_bridge_zone")
	bridge.position = Vector3(x, GROUND_SURFACE_Y, z)

	var visual: Node3D = ICE_BRIDGE_MODEL.instantiate() as Node3D
	bridge.add_child(visual)

	# Superficie plana superior, sobre la que el personaje puede correr.
	var top_body := StaticBody3D.new()
	var top_collision := CollisionShape3D.new()
	var top_shape := BoxShape3D.new()
	top_shape.size = Vector3(2.8, 0.22, 35.0)
	top_collision.shape = top_shape
	top_collision.position = Vector3(0.0, 1.58, 0.0)
	top_body.add_child(top_collision)
	bridge.add_child(top_body)

	# Rampa de entrada: el extremo cercano comienza al nivel de la nieve.
	var ramp_body := StaticBody3D.new()
	var ramp_collision := CollisionShape3D.new()
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(2.8, 0.22, 10.0)
	ramp_collision.shape = ramp_shape
	# Empieza enterrada antes del modelo y alcanza pronto la altura visible.
	ramp_collision.position = Vector3(0.0, 0.79, 22.5)
	ramp_collision.rotation_degrees.x = 9.0
	ramp_body.add_child(ramp_collision)
	bridge.add_child(ramp_body)

	# Rampa de salida simetrica: devuelve al personaje suavemente a la nieve.
	var exit_ramp_body: StaticBody3D = StaticBody3D.new()
	var exit_ramp_collision: CollisionShape3D = CollisionShape3D.new()
	var exit_ramp_shape: BoxShape3D = BoxShape3D.new()
	exit_ramp_shape.size = Vector3(2.8, 0.22, 10.0)
	exit_ramp_collision.shape = exit_ramp_shape
	exit_ramp_collision.position = Vector3(0.0, 0.79, -22.5)
	exit_ramp_collision.rotation_degrees.x = -9.0
	exit_ramp_body.add_child(exit_ramp_collision)
	bridge.add_child(exit_ramp_body)

	# Paredes laterales: impiden entrar atravesando el costado del modelo.
	var side_body: StaticBody3D = StaticBody3D.new()
	for side_x: float in [-1.38, 1.38]:
		var deck_side_collision: CollisionShape3D = CollisionShape3D.new()
		var deck_side_shape: BoxShape3D = BoxShape3D.new()
		deck_side_shape.size = Vector3(0.28, 1.58, 35.0)
		deck_side_collision.shape = deck_side_shape
		deck_side_collision.position = Vector3(side_x, 0.79, 0.0)
		side_body.add_child(deck_side_collision)

		var ramp_side_collision: CollisionShape3D = CollisionShape3D.new()
		var ramp_side_shape: BoxShape3D = BoxShape3D.new()
		ramp_side_shape.size = Vector3(0.28, 1.25, 10.0)
		ramp_side_collision.shape = ramp_side_shape
		ramp_side_collision.position = Vector3(side_x, 0.62, 22.5)
		ramp_side_collision.rotation_degrees.x = 9.0
		side_body.add_child(ramp_side_collision)

		var exit_side_collision: CollisionShape3D = CollisionShape3D.new()
		var exit_side_shape: BoxShape3D = BoxShape3D.new()
		exit_side_shape.size = Vector3(0.28, 1.25, 10.0)
		exit_side_collision.shape = exit_side_shape
		exit_side_collision.position = Vector3(side_x, 0.62, -22.5)
		exit_side_collision.rotation_degrees.x = -9.0
		side_body.add_child(exit_side_collision)
	bridge.add_child(side_body)

	course.add_child(bridge)
	# Conserva la silueta original del puente. Su longitud física se construye con
	# plataforma y rampas. Este archivo sí trae su eje largo sobre X, por eso solo
	# el puente se gira 90 grados para avanzar hacia el fondo del camino.
	_fit_bridge_visual(visual, Vector3(3.05, 2.35, 55.0))

func _add_coin(x: float, z: float, height := 1.05) -> void:
	if _has_course_overlap(x, z, 4.5):
		return
	var area := Area3D.new()
	area.add_to_group("recyclable_course")
	area.add_to_group("collectible_coin")
	area.position = Vector3(x, GROUND_SURFACE_Y + height, z)
	area.body_entered.connect(_on_coin_collected.bind(area))
	var glow: Sprite3D = Sprite3D.new()
	glow.texture = coin_glow_texture
	glow.pixel_size = 0.014
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	glow.position.z = -0.12
	area.add_child(glow)
	var visual := COIN_MODEL.instantiate()
	visual.scale = Vector3.ONE * 0.42
	area.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape
	area.add_child(collision)
	course.add_child(area)
	_spin_collectible(visual, 1.2)

func _add_gem_in_safe_lane(distance: int) -> void:
	var lane_candidates: Array[int] = [0, 1, 2]
	lane_candidates.shuffle()
	for lane_index: int in lane_candidates:
		var gem_x: float = LANES[lane_index]
		var gem_z: float = -float(distance)
		if not _has_course_overlap(gem_x, gem_z, 8.0):
			_add_gem(gem_x, gem_z)
			return

func _add_gem(x: float, z: float) -> void:
	var area: Area3D = Area3D.new()
	area.add_to_group("recyclable_course")
	area.add_to_group("collectible_gem")
	area.position = Vector3(x, GROUND_SURFACE_Y + 1.3, z)
	area.body_entered.connect(_on_gem_collected.bind(area))

	var glow: Sprite3D = Sprite3D.new()
	glow.texture = gem_glow_texture
	glow.pixel_size = 0.016
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.shaded = false
	glow.position.z = -0.12
	area.add_child(glow)

	var visual: Node3D = GEM_MODEL.instantiate() as Node3D
	visual.scale = Vector3.ONE * 0.62
	for geometry_node: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = geometry_node as GeometryInstance3D
		if geometry != null:
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(visual)

	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = 0.7
	collision.shape = shape
	area.add_child(collision)
	course.add_child(area)

	_spin_collectible(visual, 1.6)

func _spin_collectible(visual: Object, duration: float) -> void:
	if not is_instance_valid(visual):
		return
	var visual_node: Node3D = visual as Node3D
	if visual_node == null:
		return
	visual_node.rotation_degrees.y = 0.0
	var spin_tween: Tween = create_tween()
	spin_tween.tween_property(visual_node, "rotation_degrees:y", 360.0, duration)
	spin_tween.finished.connect(_spin_collectible.bind(visual_node, duration))

func _create_coin_glow_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 1.0, 0.48, 0.68),
		Color(1.0, 0.94, 0.22, 0.32),
		Color(1.0, 0.9, 0.16, 0.0)
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture

func _create_gem_glow_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.55, 1.0, 0.42, 0.75),
		Color(0.12, 0.95, 0.3, 0.34),
		Color(0.05, 0.72, 0.22, 0.0)
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture

func _add_decoration(model: PackedScene, at: Vector3, size: float, rotation_y := 0.0) -> void:
	var visual := model.instantiate()
	visual.add_to_group("recyclable_course")
	var vertical_offset := 0.0
	if model == SIGN_MODEL:
		vertical_offset = size
	elif model == DRY_TREE_MODEL:
		vertical_offset = -0.16
	visual.position = at + Vector3.UP * (SIDE_ENVIRONMENT_Y + vertical_offset)
	visual.scale = Vector3.ONE * size
	visual.rotation_degrees.y = rotation_y
	# Los cientos de arboles laterales no necesitan proyectar sombras dinamicas.
	# La iluminacion propia del modelo se conserva y baja mucho el coste grafico.
	var geometry_nodes: Array[Node] = visual.find_children("*", "GeometryInstance3D", true, false)
	for geometry_node: Node in geometry_nodes:
		var geometry: GeometryInstance3D = geometry_node as GeometryInstance3D
		if geometry != null:
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	course.add_child(visual)

func _side_forest_model_for_variant(variant_index: int) -> PackedScene:
	# El modulo 01 ocupa cuatro de cada seis espacios porque tiene el suelo mas
	# claro. Los otros dos rompen la repeticion sin dominar el paisaje.
	var selector: int = posmod(variant_index, 6)
	if selector == 2:
		return SIDE_FOREST_MODULE_02
	if selector == 4:
		return SIDE_FOREST_RIGHT_MODULE_01
	return SIDE_FOREST_MODULE_01

func _add_side_forest_module(at: Vector3, right_side: bool, variant_index: int) -> void:
	var holder: Node3D = Node3D.new()
	holder.add_to_group("recyclable_course")
	holder.add_to_group("side_environment_module")
	# Hundimos la base alta de cubos: solo queda un borde bajo visible, cercano a
	# 10 px en el encuadre móvil, mientras árboles y montañas siguen sobresaliendo.
	holder.position = at + Vector3.UP * (SIDE_ENVIRONMENT_Y - 1.38)
	var side_model: PackedScene = _side_forest_model_for_variant(variant_index)
	var visual: Node3D = side_model.instantiate() as Node3D
	holder.add_child(visual)
	course.add_child(holder)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return
	var long_axis: float = maxf(bounds.size.x, bounds.size.z)
	var module_scale: float = minf(SIDE_MODULE_LENGTH / long_axis, 16.0 / bounds.size.y)
	var angle: float = 0.0
	if bounds.size.x >= bounds.size.z:
		angle = deg_to_rad(-90.0 if right_side else 90.0)
	elif right_side:
		angle = deg_to_rad(180.0)
	# Coloca el borde interior del módulo fuera de las cinco pistas. Como el nodo
	# se centra por su caja, debemos sumar la mitad de su profundidad visible.
	var world_width: float = (bounds.size.z if bounds.size.x >= bounds.size.z else bounds.size.x) * module_scale
	var side_direction: float = 1.0 if right_side else -1.0
	# La base rocosa empieza inmediatamente después de los tres carriles. Con el
	# ancho actual de cada bloque, el borde exterior está cerca de X = +/-4.0.
	# Un solape mínimo con el último bloque de pista elimina la rendija negra.
	holder.position.x = side_direction * (3.9 + world_width * 0.5)
	visual.rotation.y = angle
	visual.scale = Vector3.ONE * module_scale
	var scaled_anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * module_scale,
		bounds.position.y * module_scale,
		(bounds.position.z + bounds.size.z * 0.5) * module_scale
	)
	visual.position = -scaled_anchor.rotated(Vector3.UP, angle)
	# Es una escenografía inaccesible: eliminamos colisiones importadas y sombras
	# dinámicas para evitar coste físico y gráfico innecesario en móviles.
	for collision_node: Node in visual.find_children("*", "CollisionShape3D", true, false):
		var collision: CollisionShape3D = collision_node as CollisionShape3D
		if collision != null:
			collision.disabled = true
	for geometry_node: Node in visual.find_children("*", "GeometryInstance3D", true, false):
		var geometry: GeometryInstance3D = geometry_node as GeometryInstance3D
		if geometry != null:
			geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _on_coin_collected(body: Node3D, coin: Area3D) -> void:
	if body != player or not is_instance_valid(coin):
		return
	collected_coins += 2 if beast_active else 1
	coins_label.text = "%02d" % collected_coins
	coin.position.z -= LEVEL_LENGTH

func _on_gem_collected(body: Node3D, gem: Area3D) -> void:
	if body != player or not is_instance_valid(gem):
		return
	if collected_gems < 5:
		collected_gems += 1
	_update_gem_fill_shape()
	var fill_ratio: float = float(collected_gems) / 5.0
	var usable_height: float = gem_meter.size.y - 4.0
	var target_top: float = 2.0 + usable_height * (1.0 - fill_ratio)
	var fill_tween: Tween = create_tween()
	fill_tween.tween_property(gem_fill, "offset_top", target_top, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	gem.position.z -= LEVEL_LENGTH
	if collected_gems >= 5 and not beast_active and not transformation_in_progress:
		_start_beast_transformation()

func _update_gem_fill_shape() -> void:
	var fill_style: StyleBoxFlat = gem_fill.get_theme_stylebox("panel") as StyleBoxFlat
	if fill_style == null:
		return
	var top_corner_radius: int = 28 if collected_gems >= 5 else 0
	fill_style.corner_radius_top_left = top_corner_radius
	fill_style.corner_radius_top_right = top_corner_radius
	# La base pertenece a la capsula exterior y debe permanecer redondeada.
	fill_style.corner_radius_bottom_left = 28
	fill_style.corner_radius_bottom_right = 28

func _on_beast_hit_mammoth(mammoth: Node3D) -> void:
	if not beast_active or not is_instance_valid(mammoth):
		return
	mammoth.remove_from_group("moving_mammoth")
	mammoth.remove_from_group("obstacle")
	# El cuerpo fisico permanece siempre derecho; solo rota el modelo visual.
	mammoth.rotation = Vector3.ZERO
	mammoth.reset_physics_interpolation()
	var mammoth_visual: Node3D = mammoth.get_node_or_null("MammothVisual") as Node3D
	for collision_node: Node in mammoth.find_children("*", "CollisionShape3D", true, false):
		var collision_shape: CollisionShape3D = collision_node as CollisionShape3D
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)
	var fly_side: float = -1.0 if mammoth.global_position.x <= player.global_position.x else 1.0
	var fly_target: Vector3 = mammoth.global_position + Vector3(fly_side * 15.0, 9.0, 5.0)
	var fly_tween: Tween = create_tween().set_parallel(true)
	fly_tween.tween_property(mammoth, "global_position", fly_target, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if mammoth_visual != null:
		fly_tween.tween_property(mammoth_visual, "rotation_degrees", Vector3(-85.0, fly_side * 110.0, fly_side * 190.0), 0.8)
	await fly_tween.finished
	_reset_mammoth_after_beast_hit(mammoth)

func _reset_mammoth_after_beast_hit(mammoth: Node3D) -> void:
	if not is_instance_valid(mammoth):
		return
	mammoth.visible = false
	var reset_position := Vector3(
		LANES[rng.randi_range(0, LANES.size() - 1)],
		GROUND_SURFACE_Y - 0.1,
		player.global_position.z - LEVEL_LENGTH
	)
	mammoth.global_transform = Transform3D(Basis.IDENTITY, reset_position)
	mammoth.scale = Vector3.ONE
	var mammoth_visual: Node3D = mammoth.get_node_or_null("MammothVisual") as Node3D
	if mammoth_visual != null:
		mammoth_visual.position = Vector3.ZERO
		mammoth_visual.rotation = Vector3.ZERO
		mammoth_visual.scale = Vector3.ONE * 1900.0
	mammoth.reset_physics_interpolation()
	mammoth.add_to_group("moving_mammoth")
	mammoth.add_to_group("obstacle")
	for collision_node: Node in mammoth.find_children("*", "CollisionShape3D", true, false):
		var collision_shape: CollisionShape3D = collision_node as CollisionShape3D
		if collision_shape != null:
			collision_shape.set_deferred("disabled", false)
	mammoth.visible = true

func _on_player_crashed() -> void:
	if finished:
		return
	finished = true
	_save_run_progress()
	crash_effect_playing = true
	player.call("set_controls_enabled", false)
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	_play_crash_beast_impact()
	await get_tree().create_timer(0.8).timeout
	message_title.text = "¡CUIDADO!"
	message_text.text = "Recogiste %d monedas\nPulsa ESPACIO o toca para volver al menú" % collected_coins
	message_panel.show()
	crash_effect_playing = false

func _play_crash_beast_impact() -> void:
	var burst_root: Node3D = Node3D.new()
	add_child(burst_root)
	burst_root.global_position = player.global_position + Vector3(0.0, 1.05, 0.15)

	# Oculta al corredor desde el primer destello para que la nube lo envuelva.
	player.call("set_human_form_visible", false)
	bear_action_serial += 1
	bear_visual.visible = false
	bear_left_visual.visible = false
	bear_right_visual.visible = false
	bear_jump_visual.visible = false

	var flash: Sprite3D = Sprite3D.new()
	flash.texture = CRASH_BEAST_FLASH
	flash.pixel_size = 0.0065
	flash.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	flash.shaded = false
	flash.no_depth_test = true
	flash.modulate = Color(1.0, 1.0, 1.0, 1.0)
	flash.scale = Vector3.ONE * 0.2
	flash.position.z = 0.04
	burst_root.add_child(flash)
	var flash_tween: Tween = create_tween().set_parallel(true)
	flash_tween.tween_property(flash, "scale", Vector3.ONE * 4.8, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.34).set_delay(0.08)

	var beast_smoke: Sprite3D = Sprite3D.new()
	beast_smoke.texture = CRASH_BEAST_SMOKE
	beast_smoke.pixel_size = 0.0068
	beast_smoke.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	beast_smoke.shaded = false
	beast_smoke.no_depth_test = true
	beast_smoke.modulate = Color(0.9, 1.0, 0.82, 0.98)
	beast_smoke.scale = Vector3.ONE * 0.15
	beast_smoke.position = Vector3(0.0, 0.2, 0.06)
	burst_root.add_child(beast_smoke)
	var beast_smoke_tween: Tween = create_tween()
	beast_smoke_tween.tween_property(beast_smoke, "scale", Vector3.ONE * 4.4, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Tras el golpe continua respirando y expandiendose detras del mensaje.
	beast_smoke_tween.tween_property(beast_smoke, "scale", Vector3.ONE * 4.9, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	for paw_index: int in range(3):
		var paw: Sprite3D = Sprite3D.new()
		paw.texture = CRASH_BEAST_PAW
		paw.pixel_size = 0.0045
		paw.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		paw.shaded = false
		paw.no_depth_test = true
		paw.modulate = Color(0.82, 1.0, 0.36, 0.0)
		paw.scale = Vector3.ONE * 0.45
		paw.position = Vector3(-0.65 + float(paw_index) * 0.65, -0.05, 0.08 + float(paw_index) * 0.01)
		burst_root.add_child(paw)
		var paw_tween: Tween = create_tween().set_parallel(true)
		paw_tween.tween_property(paw, "modulate:a", 0.95, 0.12).set_delay(0.18 + float(paw_index) * 0.07)
		paw_tween.tween_property(paw, "position:y", 1.2 + float(paw_index) * 0.28, 0.7).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		paw_tween.tween_property(paw, "scale", Vector3.ONE * 1.25, 0.65).set_delay(0.16)
		paw_tween.tween_property(paw, "modulate:a", 0.0, 0.3).set_delay(0.62)

	# Nube central: representa la frenada brusca contra el obstaculo.
	var center_cloud: Sprite3D = Sprite3D.new()
	center_cloud.texture = crash_dust_texture
	center_cloud.pixel_size = 0.016
	center_cloud.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	center_cloud.shaded = false
	center_cloud.modulate = Color(0.92, 0.97, 1.0, 0.72)
	center_cloud.scale = Vector3.ONE * 0.35
	burst_root.add_child(center_cloud)
	var center_tween: Tween = create_tween().set_parallel(true)
	center_tween.tween_property(center_cloud, "scale", Vector3.ONE * 5.2, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	center_tween.tween_property(center_cloud, "modulate:a", 0.0, 0.7).set_ease(Tween.EASE_IN)

	# Copos y polvo salen hacia los lados y hacia atras por la velocidad.
	for particle_index: int in range(18):
		var dust: Sprite3D = Sprite3D.new()
		dust.texture = crash_dust_texture
		dust.pixel_size = rng.randf_range(0.012, 0.022)
		dust.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		dust.shaded = false
		dust.modulate = Color(0.88, 0.96, 1.0, rng.randf_range(0.72, 0.95))
		dust.position = Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.15, 0.35), rng.randf_range(-0.2, 0.25))
		burst_root.add_child(dust)
		var side: float = -1.0 if particle_index % 2 == 0 else 1.0
		var destination: Vector3 = dust.position + Vector3(
			side * rng.randf_range(0.7, 2.1),
			rng.randf_range(0.25, 1.35),
			rng.randf_range(0.45, 1.8)
		)
		var dust_tween: Tween = create_tween().set_parallel(true)
		dust_tween.tween_property(dust, "position", destination, rng.randf_range(0.45, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dust_tween.tween_property(dust, "scale", Vector3.ONE * rng.randf_range(1.8, 3.5), 0.65)
		dust_tween.tween_property(dust, "modulate:a", 0.0, 0.75).set_ease(Tween.EASE_IN)

	# La nube bestial permanece detras del mensaje hasta reiniciar la escena.

func _finish_level() -> void:
	finished = true
	_save_run_progress()
	player.set_physics_process(false)
	message_title.text = "¡MUNDO 1 COMPLETADO!"
	message_text.text = "Recogiste %d monedas\nPulsa ESPACIO o toca para volver al menú" % collected_coins
	message_panel.show()

func _save_run_progress() -> void:
	if run_progress_saved:
		return
	run_progress_saved = true
	var run_distance: int = int(maxf(0.0, -player.global_position.z))
	Progression.record_run(run_distance, collected_coins)
