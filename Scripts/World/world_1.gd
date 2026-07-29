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
const LOG_MODEL := preload("res://Assets/Models/Obstacles/world1/tronco.glb")
const SIGN_MODEL := preload("res://Assets/Models/Obstacles/world1/signal.glb")
const MAMMOTH_MODEL := preload("res://Assets/Models/Obstacles/world1/mamut.glb")
const GIANT_TRAIN_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/tren_gigante.glb")
const SLEIGH_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/trineo.glb")
const GIANT_PANEL_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/panel_gigante.glb")
const GATE_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/porton.glb")
const INTERMEDIATE_JUMP_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/salton_intermedio.glb")
const ICE_BRIDGE_MODEL := preload("res://Assets/Models/Obstacles/world1/otros/puente_hielo.glb")
const NEW_SIDE_BASE := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/base.glb")
const NEW_SIDE_PINE := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/pino.glb")
const NEW_SIDE_IGLOO := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/igloo.glb")
const NEW_SIDE_HILLS := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/colinas.glb")
const NEW_SIDE_COLORFUL := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/colorido.glb")
const NEW_SIDE_ROCKS := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/piedras.glb")
const SNOW_VOLCANO_MODEL := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/volcan_nieve.glb")
const STRAIGHT_MOUNTAINS_MODEL := preload("res://Assets/Models/Enviroment/world1/Modular/nuevos/montanas_rectas.glb")

const LANES := [-2.7, 0.0, 2.7]
# Solo existen los tres carriles jugables. El paisaje modular comienza justo
# después de ellos, como los edificios y aceras de Subway Surfers.
const TILE_COLUMNS := [-2.7, 0.0, 2.7]
const LEVEL_LENGTH := 420.0
const SIDE_MODULE_LENGTH := 42.0
# Los modelos tienen extremos irregulares. Se solapan seis metros para que no
# queden aberturas triangulares entre un paisaje y el siguiente.
const SIDE_MODULE_SPACING := 36.0
# La franja del horizonte pertenecía al cielo procedural, no al final del piso.
# Dieciséis módulos cubren 576 m y evitan cargar decoración fuera de la cámara.
const SIDE_MODULE_COUNT := 16
const SIDE_MODULE_LOOP_LENGTH := SIDE_MODULE_SPACING * SIDE_MODULE_COUNT
const SIDE_SCENARIO_MODULES := 9
const SIDE_SCENARIO_COUNT := 5
const VOLCANO_SPACING := 300.0
const VOLCANO_CYCLE_LENGTH := VOLCANO_SPACING * 2.0
const STRAIGHT_MOUNTAIN_SPACING := 300.0
const STRAIGHT_MOUNTAIN_CYCLE_LENGTH := STRAIGHT_MOUNTAIN_SPACING * 3.0
const LANDFORM_SPACING := 52.0
const LANDFORM_COUNT_PER_SIDE := 16
const LANDFORM_LOOP_LENGTH := LANDFORM_SPACING * LANDFORM_COUNT_PER_SIDE
const MOUNTAIN_APPROACH_DEPTH := 290.0
const MOUNTAIN_APPROACH_SLOWNESS := 6000.0
const SNOWFALL_INTERVAL := 20.0
const SNOWFALL_DURATION := 10.0
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
@onready var distant_mountain: Node3D = $HorizonBackdrop/CordilleraNieve
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
var snow_volcanoes: Array[Node3D] = []
var straight_mountains: Array[Node3D] = []
var background_landforms: Array[Node3D] = []
var moving_sky_clouds: Array[Node3D] = []
var snowfall: GPUParticles3D
var snowfall_elapsed := 0.0
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
	_build_background_landform_chain()
	_prepare_snowfall()
	_prepare_moving_sky_clouds()
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

func _build_background_landform_chain() -> void:
	# Dos cadenas desfasadas evitan la simetría: cuatro montañas, un volcán,
	# tres montañas y otro volcán. Las piezas se solapan visualmente.
	for side_index: int in range(2):
		var side_sign: float = -1.0 if side_index == 0 else 1.0
		for slot_index: int in range(LANDFORM_COUNT_PER_SIDE):
			var pattern_index: int = (slot_index + side_index * 3) % 9
			var use_volcano: bool = pattern_index == 4 or pattern_index == 8
			var z_position: float = -135.0 - float(slot_index) * LANDFORM_SPACING
			_add_background_landform(side_sign, z_position, slot_index, side_index, use_volcano)

func _add_background_landform(
	side_sign: float,
	z_position: float,
	slot_index: int,
	side_index: int,
	use_volcano: bool
) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "Landscape_%s_%02d" % ["Left" if side_sign < 0.0 else "Right", slot_index]
	var depth_variants: Array[float] = [0.0, 2.0, -1.5, 3.0, -2.0]
	var lateral_variants: Array[float] = [0.0, 1.6, -1.2, 2.2, -1.8]
	var variant_index: int = (slot_index + side_index * 2) % depth_variants.size()
	holder.position = Vector3(
		side_sign * (31.0 + lateral_variants[variant_index]),
		SIDE_ENVIRONMENT_Y,
		z_position + depth_variants[variant_index]
	)
	holder.set_meta("landform_side", side_sign)
	course.add_child(holder)

	var source_model: PackedScene = SNOW_VOLCANO_MODEL if use_volcano else STRAIGHT_MOUNTAINS_MODEL
	var visual: Node3D = source_model.instantiate() as Node3D
	holder.add_child(visual)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		background_landforms.append(holder)
		return

	var scale_variants: Array[float] = [0.78, 0.92, 1.08, 1.18, 0.86, 1.02]
	var rotation_variants: Array[float] = [-9.0, 5.0, -3.0, 10.0, 2.0, -6.0]
	var visual_variant: int = (slot_index * 2 + side_index) % scale_variants.size()
	var target_width: float = (39.0 if use_volcano else 50.0) * scale_variants[visual_variant]
	var target_height: float = (31.0 if use_volcano else 28.0) * scale_variants[visual_variant]
	var width_scale: float = target_width / maxf(bounds.size.x, bounds.size.z)
	var height_scale: float = target_height / bounds.size.y
	var landform_scale: float = minf(width_scale, height_scale)
	var angle: float = deg_to_rad(rotation_variants[visual_variant] * side_sign)
	visual.rotation.y = angle
	visual.scale = Vector3.ONE * landform_scale
	var anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * landform_scale,
		bounds.position.y * landform_scale,
		(bounds.position.z + bounds.size.z * 0.5) * landform_scale
	)
	visual.position = -anchor.rotated(Vector3.UP, angle)
	_optimize_side_asset(visual)
	background_landforms.append(holder)

func _update_background_landform_chain() -> void:
	for landform: Node3D in background_landforms:
		if not is_instance_valid(landform):
			continue
		if landform.global_position.z > player.global_position.z + 105.0:
			landform.position.z -= LANDFORM_LOOP_LENGTH

func _build_snow_volcano_cycle() -> void:
	# Dos volcanes separados 300 m: el cercano enmarca un costado y el siguiente
	# ya se distingue en el lado contrario antes de que ocurra el recambio.
	_add_snow_volcano(Vector3(-30.0, 0.0, -280.0), 0)
	_add_snow_volcano(Vector3(30.0, 0.0, -580.0), 1)

func _add_snow_volcano(at: Vector3, cycle_index: int) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "SnowVolcano%d" % cycle_index
	holder.position = at
	holder.set_meta("cycle_index", cycle_index)
	course.add_child(holder)
	var visual: Node3D = SNOW_VOLCANO_MODEL.instantiate() as Node3D
	holder.add_child(visual)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		snow_volcanoes.append(holder)
		return
	var height_scale: float = 34.0 / bounds.size.y
	var width_scale: float = 42.0 / maxf(bounds.size.x, bounds.size.z)
	var volcano_scale: float = minf(height_scale, width_scale)
	var angle: float = deg_to_rad(12.0 if cycle_index == 0 else -12.0)
	visual.rotation.y = angle
	visual.scale = Vector3.ONE * volcano_scale
	var anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * volcano_scale,
		bounds.position.y * volcano_scale,
		(bounds.position.z + bounds.size.z * 0.5) * volcano_scale
	)
	visual.position = -anchor.rotated(Vector3.UP, angle)
	_optimize_side_asset(visual)
	snow_volcanoes.append(holder)

func _update_snow_volcano_cycle() -> void:
	for volcano: Node3D in snow_volcanoes:
		if not is_instance_valid(volcano):
			continue
		if volcano.global_position.z > player.global_position.z + 85.0:
			volcano.position.z -= VOLCANO_CYCLE_LENGTH

func _build_straight_mountain_cycle() -> void:
	# Alternan entre ambos costados y dejan libres los tres carriles.
	# Al quedar atrás se reciclan al frente, igual que los volcanes.
	for mountain_index: int in range(3):
		var side_x: float = -31.0 if mountain_index % 2 == 0 else 31.0
		_add_straight_mountain(
			Vector3(side_x, SIDE_ENVIRONMENT_Y, -360.0 - STRAIGHT_MOUNTAIN_SPACING * mountain_index),
			mountain_index
		)

func _add_straight_mountain(at: Vector3, cycle_index: int) -> void:
	var holder: Node3D = Node3D.new()
	holder.name = "StraightMountains%d" % cycle_index
	holder.position = at
	course.add_child(holder)
	var visual: Node3D = STRAIGHT_MOUNTAINS_MODEL.instantiate() as Node3D
	holder.add_child(visual)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		straight_mountains.append(holder)
		return
	var width_scale: float = 42.0 / maxf(bounds.size.x, bounds.size.z)
	var height_scale: float = 25.0 / bounds.size.y
	var mountain_scale: float = minf(width_scale, height_scale)
	visual.scale = Vector3.ONE * mountain_scale
	var anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * mountain_scale,
		bounds.position.y * mountain_scale,
		(bounds.position.z + bounds.size.z * 0.5) * mountain_scale
	)
	visual.position = -anchor
	_optimize_side_asset(visual)
	straight_mountains.append(holder)

func _update_straight_mountain_cycle() -> void:
	for mountain: Node3D in straight_mountains:
		if not is_instance_valid(mountain):
			continue
		if mountain.global_position.z > player.global_position.z + 100.0:
			mountain.position.z -= STRAIGHT_MOUNTAIN_CYCLE_LENGTH

func _update_distant_mountain(distance: float) -> void:
	# Acercamiento asintótico: avanza durante toda la partida, cada vez más lento,
	# sin alcanzar el límite ni reiniciarse de forma visible.
	var approach_progress: float = 1.0 - exp(-distance / MOUNTAIN_APPROACH_SLOWNESS)
	distant_mountain.position.z = MOUNTAIN_APPROACH_DEPTH * approach_progress

func _prepare_snowfall() -> void:
	snowfall = GPUParticles3D.new()
	snowfall.name = "MountainSnowfall"
	snowfall.amount = 180
	snowfall.lifetime = 5.0
	snowfall.randomness = 0.55
	snowfall.local_coords = false
	snowfall.emitting = false
	snowfall.visibility_aabb = AABB(Vector3(-22.0, -15.0, -42.0), Vector3(44.0, 32.0, 84.0))

	var particle_material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(13.0, 1.0, 30.0)
	particle_material.direction = Vector3(0.08, -1.0, 0.04)
	particle_material.spread = 12.0
	particle_material.gravity = Vector3(0.0, -1.7, 0.0)
	particle_material.initial_velocity_min = 2.4
	particle_material.initial_velocity_max = 4.2
	particle_material.scale_min = 0.55
	particle_material.scale_max = 1.35
	snowfall.process_material = particle_material

	var flake_material: StandardMaterial3D = StandardMaterial3D.new()
	flake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flake_material.albedo_color = Color(0.94, 0.98, 1.0, 0.88)
	var flake_mesh: QuadMesh = QuadMesh.new()
	flake_mesh.size = Vector2(0.11, 0.11)
	flake_mesh.material = flake_material
	snowfall.draw_pass_1 = flake_mesh
	add_child(snowfall)

func _update_snowfall(delta: float) -> void:
	if snowfall == null:
		return
	snowfall_elapsed += delta
	var should_snow: bool = snowfall_elapsed >= SNOWFALL_INTERVAL \
		and fmod(snowfall_elapsed, SNOWFALL_INTERVAL) < SNOWFALL_DURATION
	if snowfall.emitting != should_snow:
		snowfall.emitting = should_snow
	# El emisor acompaña al jugador, pero los copos emitidos quedan en el mundo.
	snowfall.global_position = player.global_position + Vector3(0.0, 12.0, -20.0)

func _prepare_moving_sky_clouds() -> void:
	var cloud_template: MeshInstance3D = $HorizonBackdrop/CloudLeft
	$HorizonBackdrop/CloudLeft.visible = false
	$HorizonBackdrop/CloudLeftSmall.visible = false
	$HorizonBackdrop/CloudRight.visible = false
	$HorizonBackdrop/CloudRightSmall.visible = false
	var cloud_positions: Array[Vector3] = [
		Vector3(-165.0, 76.0, 145.0), Vector3(-118.0, 111.0, 70.0),
		Vector3(-72.0, 91.0, 185.0), Vector3(-25.0, 126.0, 105.0),
		Vector3(24.0, 79.0, 155.0), Vector3(70.0, 113.0, 60.0),
		Vector3(116.0, 94.0, 190.0), Vector3(164.0, 120.0, 115.0),
	]
	var cloud_sizes: Array[float] = [2.8, 2.0, 3.1, 1.8, 2.6, 2.1, 3.0, 2.2]
	var cloud_speeds: Array[float] = [1.5, 2.0, 2.5, 1.7, 2.8, 2.2, 3.1, 2.0]
	var lobe_positions: Array[Vector3] = [
		Vector3(-1.55, -0.10, 0.0), Vector3(-0.78, 0.12, 0.0),
		Vector3(0.0, 0.30, 0.0), Vector3(0.82, 0.10, 0.0),
		Vector3(1.55, -0.12, 0.0), Vector3(-0.38, 0.72, 0.02),
		Vector3(0.48, 0.66, 0.02),
	]
	var lobe_scales: Array[Vector3] = [
		Vector3(1.05, 0.58, 0.52), Vector3(1.18, 0.72, 0.58),
		Vector3(1.38, 0.82, 0.66), Vector3(1.15, 0.70, 0.57),
		Vector3(0.98, 0.54, 0.48), Vector3(0.92, 0.88, 0.58),
		Vector3(0.84, 0.76, 0.54),
	]
	for cloud_index: int in range(cloud_positions.size()):
		var cloud: Node3D = Node3D.new()
		cloud.name = "MovingCloud%d" % cloud_index
		horizon_backdrop.add_child(cloud)
		cloud.position = cloud_positions[cloud_index]
		cloud.scale = Vector3.ONE * cloud_sizes[cloud_index]
		cloud.set_meta("cloud_speed", cloud_speeds[cloud_index])
		for lobe_index: int in range(lobe_positions.size()):
			var cloud_lobe: MeshInstance3D = cloud_template.duplicate() as MeshInstance3D
			cloud_lobe.visible = true
			cloud_lobe.position = lobe_positions[lobe_index]
			cloud_lobe.scale = lobe_scales[lobe_index]
			cloud_lobe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cloud.add_child(cloud_lobe)
		moving_sky_clouds.append(cloud)

func _update_moving_sky_clouds(delta: float) -> void:
	for cloud: Node3D in moving_sky_clouds:
		if not is_instance_valid(cloud):
			continue
		var cloud_speed: float = float(cloud.get_meta("cloud_speed", 2.0))
		cloud.position.x += cloud_speed * delta
		if cloud.position.x > 180.0:
			cloud.position.x = -180.0

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
	_update_background_landform_chain()
	_update_snowfall(_delta)
	_update_moving_sky_clouds(_delta)
	_update_difficulty(_delta)
	# El plano cubre varios kilómetros para que su borde quede siempre mucho más
	# lejos que el horizonte visible de la cámara.
	side_snow_base.position.z = player.position.z - 1800.0
	# Fondo distante estable: acompana la carrera sin acercarse como un obstaculo.
	horizon_backdrop.position.z = player.position.z - 650.0
	var distance := maxf(0.0, -player.global_position.z)
	distance_label.text = "%03d m" % int(distance)
	_update_distant_mountain(distance)
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
			if item.is_in_group("side_environment_module"):
				var side_item: Node3D = item as Node3D
				var next_serial: int = int(side_item.get_meta("scenario_serial", 0)) + SIDE_MODULE_COUNT
				_configure_side_scenario(side_item, bool(side_item.get_meta("right_side", false)), next_serial)

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
		[148, GATE_MODEL], [276, BARREL_MODEL], [316, LOG_MODEL],
		[352, INTERMEDIATE_JUMP_MODEL], [388, GIANT_PANEL_MODEL]
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

	# Las nuevas bases modulares ya contienen toda la ambientación lateral.
	# Conservamos algunas señales pequeñas como puntos de orientación del camino.
	var signal_distance: int = rng.randi_range(25, 38)
	while signal_distance < 420:
		var signal_side: float = -1.0 if rng.randi_range(0, 1) == 0 else 1.0
		_add_decoration(SIGN_MODEL, Vector3(signal_side * rng.randf_range(6.9, 7.4), 0.0, -float(signal_distance)), rng.randf_range(1.05, 1.3), rng.randf_range(-10.0, 10.0))
		signal_distance += rng.randi_range(34, 50)
	# Franja continua de prueba: diez módulos por cada lado cubren todo el tramo.
	for module_index: int in range(SIDE_MODULE_COUNT):
		var module_z: float = -20.0 - float(module_index) * SIDE_MODULE_SPACING
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
	if model == LOG_MODEL:
		visual_scale = 1.25
		visual.position.y = 0.65
		obstacle_size = Vector3(2.5, 1.2, 1.8)
	elif model == SIGN_MODEL:
		visual_scale = 0.7
		visual.position.y = 0.7
		obstacle_size = Vector3(1.15, 1.4, 1.0)
	visual.scale = Vector3.ONE * visual_scale
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = obstacle_size
	collision.shape = shape
	collision.position.y = obstacle_size.y * 0.5
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
	var vertical_offset: float = size if model == SIGN_MODEL else 0.0
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

func _add_side_forest_module(at: Vector3, right_side: bool, variant_index: int) -> void:
	var holder: Node3D = Node3D.new()
	holder.add_to_group("recyclable_course")
	holder.add_to_group("side_environment_module")
	var side_direction: float = 1.0 if right_side else -1.0
	holder.position = Vector3(side_direction * 6.35, SIDE_ENVIRONMENT_Y - 0.48, at.z)
	course.add_child(holder)
	_configure_side_scenario(holder, right_side, variant_index)

func _configure_side_scenario(holder: Node3D, right_side: bool, serial: int) -> void:
	for child: Node in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	holder.set_meta("right_side", right_side)
	holder.set_meta("scenario_serial", serial)
	# Tres franjas solapadas de base cubren desde el borde del carril hasta el
	# fondo de la decoración. Así nunca queda visible el color azul del vacío.
	var outward: float = 1.0 if right_side else -1.0
	_add_fitted_side_base(holder, 0.0)
	_add_fitted_side_base(holder, outward * 4.75)
	# La última franja es más ancha y se extiende fuera del encuadre para que la
	# perspectiva de la cámara nunca alcance a mostrar el vacío azul exterior.
	_add_fitted_side_base(holder, outward * 16.75, 20.0)

	# Cada familia dura nueve módulos (324 m). Las cinco familias completan
	# 1.620 m antes de repetir su identidad visual.
	var scenario_index: int = posmod(int(serial / SIDE_SCENARIO_MODULES), SIDE_SCENARIO_COUNT)
	var variation: int = posmod(serial, SIDE_SCENARIO_MODULES)
	var inner_x: float = -1.15 if right_side else 1.15
	var outer_x: float = 1.0 if right_side else -1.0
	var z_shift: float = float(variation - 4) * 0.7
	var turn: float = 180.0 if right_side else 0.0

	match scenario_index:
		0: # Bosque de pinos
			_add_side_prop(holder, NEW_SIDE_PINE, Vector3(inner_x, 0.0, -10.5 + z_shift), 7.2, 5.2, turn + float(variation * 17))
			_add_side_prop(holder, NEW_SIDE_PINE, Vector3(outer_x, 0.0, 9.0 - z_shift), 6.0, 4.6, turn - float(variation * 13))
			_add_side_prop(holder, NEW_SIDE_ROCKS, Vector3(inner_x * 0.7, 0.0, 1.0), 1.8, 4.0, turn)
		1: # Aldea de hielo
			_add_side_prop(holder, NEW_SIDE_IGLOO, Vector3(outer_x * 0.55, 0.0, -2.0 + z_shift), 3.6, 6.2, turn)
			_add_side_prop(holder, NEW_SIDE_PINE, Vector3(inner_x, 0.0, 11.5), 6.3, 4.5, turn + 25.0)
			_add_side_prop(holder, NEW_SIDE_COLORFUL, Vector3(inner_x, 1.0, -12.0), 2.0, 3.8, turn)
		2: # Colinas congeladas
			# Las colinas quedan como fondo bajo, no como una pared junto al carril.
			_add_side_prop(holder, NEW_SIDE_HILLS, Vector3(outer_x * 3.35, 0.0, z_shift), 3.8, 7.0, turn)
			_add_side_prop(holder, NEW_SIDE_ROCKS, Vector3(inner_x, 0.0, -12.0), 1.7, 3.8, turn + 20.0)
			_add_side_prop(holder, NEW_SIDE_COLORFUL, Vector3(inner_x, 1.0, 12.5), 1.8, 3.4, turn)
			_add_side_prop(holder, NEW_SIDE_PINE, Vector3(inner_x, 0.0, 2.0 - z_shift), 5.8, 4.2, turn + 18.0)
		3: # Jardín de colores
			_add_side_prop(holder, NEW_SIDE_COLORFUL, Vector3(inner_x, 1.0, -10.0 + z_shift), 2.7, 4.8, turn + float(variation * 19))
			_add_side_prop(holder, NEW_SIDE_COLORFUL, Vector3(outer_x, 1.0, 9.5 - z_shift), 2.2, 4.2, turn - float(variation * 11))
			_add_side_prop(holder, NEW_SIDE_PINE, Vector3(outer_x * 0.8, 0.0, 0.0), 6.5, 4.6, turn)
		4: # Paisaje mixto
			_add_side_prop(holder, NEW_SIDE_IGLOO, Vector3(inner_x * 0.65, 0.0, -10.0 + z_shift), 3.1, 5.3, turn)
			_add_side_prop(holder, NEW_SIDE_HILLS, Vector3(outer_x * 3.2, 0.0, 9.0 - z_shift), 3.2, 5.5, turn)
			_add_side_prop(holder, NEW_SIDE_ROCKS, Vector3(inner_x, 0.0, 2.5), 1.5, 3.5, turn)
			_add_side_prop(holder, NEW_SIDE_COLORFUL, Vector3(inner_x, 1.0, 12.5), 1.7, 3.2, turn)

func _add_fitted_side_base(holder: Node3D, local_x: float, target_width: float = 5.0) -> void:
	var visual: Node3D = NEW_SIDE_BASE.instantiate() as Node3D
	holder.add_child(visual)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return
	var angle: float = 0.0
	var target_size: Vector3 = Vector3(target_width, 1.0, 40.0)
	var fitted_scale: Vector3
	if bounds.size.x >= bounds.size.z:
		angle = deg_to_rad(90.0)
		fitted_scale = Vector3(target_size.z / bounds.size.x, target_size.y / bounds.size.y, target_size.x / bounds.size.z)
	else:
		fitted_scale = Vector3(target_size.x / bounds.size.x, target_size.y / bounds.size.y, target_size.z / bounds.size.z)
	visual.rotation.y = angle
	visual.scale = fitted_scale
	var scaled_anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * fitted_scale.x,
		bounds.position.y * fitted_scale.y,
		(bounds.position.z + bounds.size.z * 0.5) * fitted_scale.z
	)
	visual.position = Vector3(local_x, 0.0, 0.0) - scaled_anchor.rotated(Vector3.UP, angle)
	_optimize_side_asset(visual)

func _add_side_prop(holder: Node3D, model: PackedScene, local_position: Vector3, target_height: float, max_footprint: float, rotation_y: float) -> void:
	var visual: Node3D = model.instantiate() as Node3D
	holder.add_child(visual)
	var bounds: AABB = _calculate_visual_bounds(visual)
	if bounds.size.x <= 0.001 or bounds.size.y <= 0.001 or bounds.size.z <= 0.001:
		return
	var height_scale: float = target_height / bounds.size.y
	var footprint_scale: float = max_footprint / maxf(bounds.size.x, bounds.size.z)
	var uniform_scale: float = minf(height_scale, footprint_scale)
	var angle: float = deg_to_rad(rotation_y)
	visual.rotation.y = angle
	visual.scale = Vector3.ONE * uniform_scale
	var anchor: Vector3 = Vector3(
		(bounds.position.x + bounds.size.x * 0.5) * uniform_scale,
		bounds.position.y * uniform_scale,
		(bounds.position.z + bounds.size.z * 0.5) * uniform_scale
	)
	visual.position = local_position - anchor.rotated(Vector3.UP, angle)
	_optimize_side_asset(visual)

func _optimize_side_asset(visual: Node3D) -> void:
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
