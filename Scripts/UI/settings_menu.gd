extends Control

@onready var sound_toggle: CheckButton = $Content/Margin/Layout/SoundToggle
@onready var sound_status: Label = $Content/Margin/Layout/SoundStatus

func _ready() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	sound_toggle.button_pressed = master_bus < 0 or not AudioServer.is_bus_mute(master_bus)
	sound_toggle.toggled.connect(_on_sound_toggled)
	_update_sound_text()

func _on_sound_toggled(enabled: bool) -> void:
	Progression.set_sound_enabled(enabled)
	_update_sound_text()

func _update_sound_text() -> void:
	sound_status.text = "SONIDO ACTIVADO" if sound_toggle.button_pressed else "SONIDO DESACTIVADO"
