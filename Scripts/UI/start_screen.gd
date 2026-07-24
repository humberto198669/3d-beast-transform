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
	enter_button.modulate.a = 0.0
	enter_button.scale = Vector2(0.82, 0.82)
	var reveal_tween: Tween = create_tween()
	reveal_tween.set_parallel(true)
	reveal_tween.tween_property(enter_button, "modulate:a", 1.0, 0.28)
	reveal_tween.tween_property(enter_button, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_enter_pressed():
	SceneTransition.change_scene(next_scene_path)
