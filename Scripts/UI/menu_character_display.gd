extends SubViewportContainer

## Visor 3D del personaje seleccionado. Para agregar otro personaje basta con
## registrar aquí su escena de saludo usando el mismo identificador guardado.
const CHARACTER_PREVIEWS: Dictionary = {
	"ethan": "res://Characters/Human/Animations/ethan_wave.fbx",
}

@onready var character_pivot: Node3D = $Viewport/CharacterPivot

var animation_player: AnimationPlayer
var wave_animation: StringName = &""
var replay_serial: int = 0

func _ready() -> void:
	_load_selected_character()

func _load_selected_character() -> void:
	for child: Node in character_pivot.get_children():
		child.queue_free()
	var character_id: String = Progression.selected_character_id
	var scene_path: String = str(CHARACTER_PREVIEWS.get(character_id, CHARACTER_PREVIEWS["ethan"]))
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		push_warning("No se pudo cargar la presentación del personaje: %s" % scene_path)
		return
	var character: Node3D = packed_scene.instantiate() as Node3D
	if character == null:
		return
	character.name = "SelectedCharacter"
	character.scale = Vector3.ONE * 155.0
	# Los FBX de presentación ya miran hacia la cámara en su orientación original.
	character.rotation_degrees.y = 0.0
	character_pivot.add_child(character)
	animation_player = _find_animation_player(character)
	if animation_player != null:
		wave_animation = _find_wave_animation(animation_player)
		if wave_animation != &"":
			animation_player.animation_finished.connect(_on_animation_finished)
			animation_player.play(wave_animation)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child: Node in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result != null:
			return result
	return null

func _find_wave_animation(player: AnimationPlayer) -> StringName:
	var fallback: StringName = &""
	for animation_name: StringName in player.get_animation_list():
		if animation_name == &"RESET":
			continue
		if fallback == &"":
			fallback = animation_name
		if "wave" in String(animation_name).to_lower():
			return animation_name
	return fallback

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != wave_animation:
		return
	replay_serial += 1
	var current_serial: int = replay_serial
	await get_tree().create_timer(3.0).timeout
	if current_serial == replay_serial and is_instance_valid(animation_player):
		animation_player.play(wave_animation)
