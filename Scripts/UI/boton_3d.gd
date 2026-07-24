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
@onready var text_depth: Label = $TextDepth

var scale_tween: Tween

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
	if text_depth:
		text_depth.text = label_text

func _animate_scale(target_scale: Vector2, duration: float) -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween()
	scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", target_scale, duration)

func _on_hover():
	_animate_scale(Vector2(1.045, 1.045), 0.16)

func _on_unhover():
	_animate_scale(Vector2.ONE, 0.18)

func _on_press():
	_animate_scale(Vector2(0.94, 0.94), 0.08)

func _on_release():
	_animate_scale(Vector2(1.045, 1.045) if is_hovered() else Vector2.ONE, 0.14)
