extends Control

const PAUSE_BUTTON_TEXTURE := preload("res://Assets/UI/Icons/pause_button_green_glow_v2.png")

var world: Node
var pause_button: Button
var overlay: Control
var pause_button_top := 28.0

func setup(world_node: Node, safe_top: float = 28.0) -> void:
	world = world_node
	pause_button_top = maxf(28.0, safe_top)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_interface()

func _build_interface() -> void:
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.text = ""
	pause_button.icon = PAUSE_BUTTON_TEXTURE
	pause_button.expand_icon = true
	pause_button.flat = true
	pause_button.tooltip_text = "Pausar"
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.custom_minimum_size = Vector2(76.0, 76.0)
	pause_button.anchor_left = 0.5
	pause_button.anchor_right = 0.5
	pause_button.offset_left = -38.0
	pause_button.offset_top = pause_button_top
	pause_button.offset_right = 38.0
	pause_button.offset_bottom = pause_button_top + 76.0
	pause_button.material = _pause_icon_material()
	pause_button.pressed.connect(_open_pause)
	pause_button.mouse_entered.connect(_animate_pause_button.bind(1.08))
	pause_button.mouse_exited.connect(_animate_pause_button.bind(1.0))
	add_child(pause_button)

	overlay = Control.new()
	overlay.name = "PauseOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.025, 0.045, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(390.0, 330.0)
	card.add_theme_stylebox_override("panel", _button_style(Color(0.018, 0.06, 0.085, 0.97), Color(0.25, 0.9, 0.7, 1.0), 26, 3))
	center.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 38)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 38)
	margin.add_theme_constant_override("margin_bottom", 30)
	card.add_child(margin)

	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(buttons)

	var title := Label.new()
	title.text = "JUEGO EN PAUSA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.55, 1.0, 0.72))
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 3)
	buttons.add_child(title)

	buttons.add_child(_menu_button("CONTINUAR", _resume_game))
	buttons.add_child(_menu_button("REINICIAR", _restart_game))
	buttons.add_child(_menu_button("SALIR AL MENU", _exit_to_menu))
	overlay.hide()

func _pause_icon_material() -> ShaderMaterial:
	# Elimina solamente el residuo violeta del fondo de extraccion y conserva
	# el halo verde/blanco semitransparente alrededor de la piedra.
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float purple = min(color.r, color.b) - color.g;
	float remove_key = smoothstep(0.035, 0.16, purple);
	color.a *= 1.0 - remove_key;
	COLOR = color;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _animate_pause_button(target_scale: float) -> void:
	if pause_button == null:
		return
	pause_button.pivot_offset = pause_button.size * 0.5
	var tween := create_tween()
	tween.tween_property(pause_button, "scale", Vector2.ONE * target_scale, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _menu_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(285.0, 58.0)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color(0.72, 1.0, 0.82))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.11, 0.13, 0.96), Color(0.22, 0.66, 0.52, 1.0), 14, 2))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.06, 0.23, 0.18, 1.0), Color(0.52, 1.0, 0.72, 1.0), 14, 2))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.02, 0.07, 0.08, 1.0), Color(0.3, 0.86, 0.61, 1.0), 14, 2))
	button.pressed.connect(callback)
	return button

func _button_style(color: Color, border_color: Color, radius: int, border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	style.shadow_size = 7
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	return style

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if overlay.visible:
			_resume_game()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	if world == null or bool(world.get("finished")) or bool(world.get("transformation_in_progress")):
		return
	overlay.show()
	pause_button.hide()
	get_tree().paused = true

func _resume_game() -> void:
	get_tree().paused = false
	overlay.hide()
	pause_button.show()

func _restart_game() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/World1/World1.tscn")

func _exit_to_menu() -> void:
	get_tree().paused = false
	SceneTransition.change_scene("res://Scenes/Menu.tscn")

func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false
