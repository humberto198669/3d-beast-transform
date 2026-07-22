extends Control

## Pantalla de inicio: muestra la portada, llena una barra de carga
## (simulada, con tiempo fijo, sin texto) y al terminar deja aparecer
## el botón 3D "ENTRAR" que lleva al menú principal.

@export var next_scene_path := "res://Scenes/Menu.tscn"
@export var load_duration := 2.5 # segundos que tarda la barra en llenarse

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var enter_button: Button = $EnterButton

var elapsed := 0.0
var loading_done := false

func _ready():
	progress_bar.value = 0
	enter_button.visible = false
	enter_button.disabled = true
	enter_button.pressed.connect(_on_enter_pressed)

func _process(delta):
	if loading_done:
		return

	elapsed += delta
	var progress = clamp(elapsed / load_duration, 0.0, 1.0)
	progress_bar.value = progress * 100.0

	if progress >= 1.0:
		_on_loading_finished()

func _on_loading_finished():
	loading_done = true
	enter_button.visible = true
	enter_button.disabled = false
	progress_bar.visible = false

func _on_enter_pressed():
	get_tree().change_scene_to_file(next_scene_path)
