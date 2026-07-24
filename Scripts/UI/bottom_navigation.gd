extends Control

@export_enum("home", "missions", "characters", "settings") var current_section: String = "home"

@onready var missions_button: TextureButton = $Frame/Missions
@onready var persons_button: TextureButton = $Frame/Persons
@onready var start_button: TextureButton = $Frame/Start
@onready var adjust_button: TextureButton = $Frame/Adjust
@onready var store_button: TextureButton = $Frame/Store
@onready var tooltip_panel: PanelContainer = $Tooltip
@onready var tooltip_label: Label = $Tooltip/Text

var tooltip_serial: int = 0

func _ready() -> void:
	tooltip_panel.hide()
	_setup_button(missions_button, "missions")
	_setup_button(persons_button, "characters")
	_setup_button(start_button, "home")
	_setup_button(adjust_button, "settings")
	_setup_button(store_button, "store")
	missions_button.pressed.connect(_on_missions_pressed)
	persons_button.pressed.connect(_on_persons_pressed)
	start_button.pressed.connect(_on_start_pressed)
	adjust_button.pressed.connect(_on_adjust_pressed)
	store_button.pressed.connect(_on_store_pressed)
	_update_locked_states()

func _setup_button(button: TextureButton, section: String) -> void:
	button.pivot_offset = button.size * 0.5
	var selection: Panel = button.get_node("Selection") as Panel
	if selection != null:
		selection.visible = section == current_section
	button.mouse_entered.connect(_on_button_hover.bind(button, true))
	button.mouse_exited.connect(_on_button_hover.bind(button, false))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))

func _update_locked_states() -> void:
	missions_button.modulate = Color(0.42, 0.42, 0.42, 0.9)
	store_button.modulate = Color(0.42, 0.42, 0.42, 0.9)

func _on_button_hover(button: TextureButton, hovering: bool) -> void:
	var target_scale: Vector2 = Vector2(1.08, 1.08) if hovering else Vector2.ONE
	_create_scale_tween(button, target_scale)
	if not hovering:
		_hide_tooltip()
		return
	if button == missions_button:
		_show_tooltip("EN CONSTRUCCIÓN · DISPONIBLE PRÓXIMAMENTE", false)
	elif button == store_button:
		_show_tooltip("EN CONSTRUCCIÓN · DISPONIBLE PRÓXIMAMENTE", false)

func _on_button_down(button: TextureButton) -> void:
	_create_scale_tween(button, Vector2(0.92, 0.92))

func _on_button_up(button: TextureButton) -> void:
	_create_scale_tween(button, Vector2(1.08, 1.08) if button.is_hovered() else Vector2.ONE)

func _create_scale_tween(button: TextureButton, target: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(button, "scale", target, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_missions_pressed() -> void:
	_show_tooltip("MISIONES EN CONSTRUCCIÓN · DISPONIBLE PRÓXIMAMENTE", true)

func _on_persons_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/CharactersMenu.tscn")

func _on_start_pressed() -> void:
	if current_section == "home":
		return
	SceneTransition.change_scene("res://Scenes/Menu.tscn")

func _on_adjust_pressed() -> void:
	SceneTransition.change_scene("res://Scenes/SettingsMenu.tscn")

func _on_store_pressed() -> void:
	_show_tooltip("TIENDA EN CONSTRUCCIÓN · DISPONIBLE PRÓXIMAMENTE", true)

func _show_tooltip(message: String, auto_hide: bool) -> void:
	tooltip_serial += 1
	var current_serial: int = tooltip_serial
	tooltip_label.text = message
	tooltip_panel.modulate.a = 0.0
	tooltip_panel.show()
	create_tween().tween_property(tooltip_panel, "modulate:a", 1.0, 0.16)
	if auto_hide:
		await get_tree().create_timer(2.2).timeout
		if current_serial == tooltip_serial:
			_hide_tooltip()

func _hide_tooltip() -> void:
	tooltip_serial += 1
	tooltip_panel.hide()
