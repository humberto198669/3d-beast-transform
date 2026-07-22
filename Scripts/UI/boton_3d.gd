extends Button

## Botón reutilizable que muestra el modelo 3D "boton_inicio.glb" renderizado
## en un SubViewport, con un texto encima. Usar la propiedad label_text para
## cambiar el texto de cada instancia (ENTRAR, MODO HISTORIA, MODO INFINITO...).

@export var label_text: String = "BOTON":
	set(value):
		label_text = value
		if is_inside_tree():
			_apply_label()

@onready var label: Label = $Label

func _ready():
	pivot_offset = size / 2.0
	_apply_label()
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	button_down.connect(_on_press)
	button_up.connect(_on_release)

func _apply_label():
	if label:
		label.text = label_text

func _on_hover():
	scale = Vector2(1.05, 1.05)

func _on_unhover():
	scale = Vector2(1.0, 1.0)

func _on_press():
	scale = Vector2(0.95, 0.95)

func _on_release():
	scale = Vector2(1.05, 1.05) if is_hovered() else Vector2.ONE
