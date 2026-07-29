extends Node

const SAVE_PATH := "user://progression.cfg"
const SAVE_VERSION := 1
const FIRST_STAGE_END_LEVEL := 5
const SECOND_STAGE_END_LEVEL := 20
const FIRST_LEVEL_DISTANCE := 5000
const SECOND_LEVEL_DISTANCE := 10000
const FINAL_LEVEL_DISTANCE := 20000
const LEVEL_5_START_DISTANCE := 20000
const LEVEL_20_START_DISTANCE := 170000

var total_coins: int = 0
var total_distance: int = 0
var best_distance: int = 0
var sound_enabled: bool = true
var selected_character_id: String = "ethan"
var owned_character_ids: PackedStringArray = PackedStringArray(["ethan"])
var pending_run_coins: int = 0
var pending_run_distance: int = 0
var local_player_id: String = ""
var save_updated_at: int = 0

func _ready() -> void:
	load_progress()
	_ensure_local_player_id()
	_apply_sound_setting()

func record_run(distance: int, coins: int) -> void:
	var safe_distance: int = maxi(0, distance)
	var safe_coins: int = maxi(0, coins)
	total_distance += safe_distance
	total_coins += safe_coins
	best_distance = maxi(best_distance, safe_distance)
	pending_run_coins += safe_coins
	pending_run_distance += safe_distance
	save_progress()

func get_level() -> int:
	return get_level_for_distance(total_distance)

func get_level_for_distance(distance: int) -> int:
	var safe_distance: int = maxi(0, distance)
	if safe_distance < LEVEL_5_START_DISTANCE:
		return 1 + floori(float(safe_distance) / float(FIRST_LEVEL_DISTANCE))
	if safe_distance < LEVEL_20_START_DISTANCE:
		return FIRST_STAGE_END_LEVEL + floori(float(safe_distance - LEVEL_5_START_DISTANCE) / float(SECOND_LEVEL_DISTANCE))
	return SECOND_STAGE_END_LEVEL + floori(float(safe_distance - LEVEL_20_START_DISTANCE) / float(FINAL_LEVEL_DISTANCE))

func get_level_start_distance(level: int = get_level()) -> int:
	if level < FIRST_STAGE_END_LEVEL:
		return (level - 1) * FIRST_LEVEL_DISTANCE
	if level < SECOND_STAGE_END_LEVEL:
		return LEVEL_5_START_DISTANCE + (level - FIRST_STAGE_END_LEVEL) * SECOND_LEVEL_DISTANCE
	return LEVEL_20_START_DISTANCE + (level - SECOND_STAGE_END_LEVEL) * FINAL_LEVEL_DISTANCE

func get_next_level_distance(level: int = get_level()) -> int:
	if level < FIRST_STAGE_END_LEVEL:
		return level * FIRST_LEVEL_DISTANCE
	if level < SECOND_STAGE_END_LEVEL:
		return LEVEL_5_START_DISTANCE + (level - FIRST_STAGE_END_LEVEL + 1) * SECOND_LEVEL_DISTANCE
	return LEVEL_20_START_DISTANCE + (level - SECOND_STAGE_END_LEVEL + 1) * FINAL_LEVEL_DISTANCE

func get_level_progress() -> float:
	return get_level_progress_for_distance(total_distance)

func get_level_progress_for_distance(distance: int) -> float:
	var level: int = get_level_for_distance(distance)
	var level_start: int = get_level_start_distance(level)
	var level_end: int = get_next_level_distance(level)
	return clampf(float(distance - level_start) / float(level_end - level_start), 0.0, 1.0)

func take_pending_run_animation() -> Vector2i:
	var pending: Vector2i = Vector2i(pending_run_coins, pending_run_distance)
	pending_run_coins = 0
	pending_run_distance = 0
	save_progress()
	return pending

func is_story_mode_unlocked() -> bool:
	return get_level() >= FIRST_STAGE_END_LEVEL

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	_apply_sound_setting()
	save_progress()

func owns_character(character_id: String) -> bool:
	return owned_character_ids.has(character_id)

func select_character(character_id: String) -> bool:
	if not owns_character(character_id):
		return false
	selected_character_id = character_id
	save_progress()
	return true

func _apply_sound_setting() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, not sound_enabled)

func save_progress() -> void:
	_ensure_local_player_id()
	save_updated_at = int(Time.get_unix_time_from_system())
	var config: ConfigFile = ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "local_player_id", local_player_id)
	config.set_value("save", "updated_at", save_updated_at)
	config.set_value("progress", "total_coins", total_coins)
	config.set_value("progress", "total_distance", total_distance)
	config.set_value("progress", "best_distance", best_distance)
	config.set_value("settings", "sound_enabled", sound_enabled)
	config.set_value("characters", "selected", selected_character_id)
	config.set_value("characters", "owned", owned_character_ids)
	config.save(SAVE_PATH)

func load_progress() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var loaded_version: int = int(config.get_value("save", "version", 0))
	local_player_id = str(config.get_value("save", "local_player_id", ""))
	save_updated_at = int(config.get_value("save", "updated_at", 0))
	total_coins = int(config.get_value("progress", "total_coins", 0))
	total_distance = int(config.get_value("progress", "total_distance", 0))
	best_distance = int(config.get_value("progress", "best_distance", 0))
	sound_enabled = bool(config.get_value("settings", "sound_enabled", true))
	owned_character_ids = PackedStringArray(config.get_value("characters", "owned", PackedStringArray(["ethan"])))
	if not owned_character_ids.has("ethan"):
		owned_character_ids.append("ethan")
	selected_character_id = str(config.get_value("characters", "selected", "ethan"))
	if not owns_character(selected_character_id):
		selected_character_id = "ethan"
	if loaded_version < SAVE_VERSION:
		_migrate_save(loaded_version)

func export_progress_data() -> Dictionary:
	# Esta estructura podrá enviarse a la nube cuando se agreguen cuentas.
	return {
		"save_version": SAVE_VERSION,
		"local_player_id": local_player_id,
		"updated_at": save_updated_at,
		"total_coins": total_coins,
		"total_distance": total_distance,
		"best_distance": best_distance,
		"sound_enabled": sound_enabled,
		"selected_character_id": selected_character_id,
		"owned_character_ids": Array(owned_character_ids),
	}

func merge_cloud_progress(cloud_data: Dictionary) -> void:
	# Nunca sustituye un avance local superior por una copia remota inferior.
	total_coins = maxi(total_coins, int(cloud_data.get("total_coins", 0)))
	total_distance = maxi(total_distance, int(cloud_data.get("total_distance", 0)))
	best_distance = maxi(best_distance, int(cloud_data.get("best_distance", 0)))
	var cloud_owned_variant: Variant = cloud_data.get("owned_character_ids", [])
	if cloud_owned_variant is Array:
		for character_variant: Variant in cloud_owned_variant as Array:
			var character_id: String = str(character_variant)
			if not character_id.is_empty() and not owned_character_ids.has(character_id):
				owned_character_ids.append(character_id)
	var cloud_selected: String = str(cloud_data.get("selected_character_id", "ethan"))
	if selected_character_id == "ethan" and owned_character_ids.has(cloud_selected):
		selected_character_id = cloud_selected
	save_progress()

func _ensure_local_player_id() -> void:
	if not local_player_id.is_empty():
		return
	var random_bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	local_player_id = random_bytes.hex_encode()

func _migrate_save(_from_version: int) -> void:
	# La versión 0 corresponde a partidas creadas antes del versionado.
	# Sus monedas, distancia, récord y personajes ya fueron cargados arriba.
	_ensure_local_player_id()
	save_progress()
