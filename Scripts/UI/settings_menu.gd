extends Control

@onready var sound_toggle: CheckButton = $Content/Margin/Layout/SoundToggle
@onready var sound_status: Label = $Content/Margin/Layout/SoundStatus
@onready var account_status: Label = $Content/Margin/Layout/AccountStatus
@onready var change_password_button: Button = $Content/Margin/Layout/ChangePassword
@onready var password_form: VBoxContainer = $Content/Margin/Layout/PasswordForm
@onready var new_password: LineEdit = $Content/Margin/Layout/PasswordForm/NewPassword
@onready var confirm_password: LineEdit = $Content/Margin/Layout/PasswordForm/ConfirmPassword
@onready var password_message: Label = $Content/Margin/Layout/PasswordForm/PasswordMessage
@onready var save_password_button: Button = $Content/Margin/Layout/PasswordForm/SavePassword
@onready var sign_out_button: Button = $Content/Margin/Layout/SignOut

func _ready() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	sound_toggle.button_pressed = master_bus < 0 or not AudioServer.is_bus_mute(master_bus)
	sound_toggle.toggled.connect(_on_sound_toggled)
	change_password_button.pressed.connect(_toggle_password_form)
	save_password_button.pressed.connect(_save_new_password)
	sign_out_button.pressed.connect(_sign_out)
	_update_sound_text()
	_update_account_controls()

func _on_sound_toggled(enabled: bool) -> void:
	Progression.set_sound_enabled(enabled)
	_update_sound_text()

func _update_sound_text() -> void:
	sound_status.text = "SONIDO ACTIVADO" if sound_toggle.button_pressed else "SONIDO DESACTIVADO"

func _update_account_controls() -> void:
	var logged_in: bool = SupabaseManager.is_logged_in()
	account_status.text = "CUENTA CONECTADA" if logged_in else "MODO INVITADO"
	change_password_button.visible = logged_in
	sign_out_button.visible = logged_in
	if not logged_in:
		password_form.visible = false

func _toggle_password_form() -> void:
	password_form.visible = not password_form.visible
	password_message.text = ""
	if password_form.visible:
		new_password.grab_focus()

func _save_new_password() -> void:
	if new_password.text.length() < 8:
		_show_password_message("Usa al menos 8 caracteres.", true)
		return
	if new_password.text != confirm_password.text:
		_show_password_message("Las contraseñas no coinciden.", true)
		return
	save_password_button.disabled = true
	password_message.text = "GUARDANDO..."
	var result: Dictionary = await SupabaseManager.update_password(new_password.text)
	save_password_button.disabled = false
	if bool(result.get("ok", false)):
		new_password.text = ""
		confirm_password.text = ""
		_show_password_message("Contraseña actualizada.", false)
	else:
		_show_password_message(str(result.get("message", "No se pudo actualizar.")), true)

func _show_password_message(message: String, is_error: bool) -> void:
	password_message.text = message
	password_message.modulate = Color(1.0, 0.48, 0.38) if is_error else Color(0.55, 1.0, 0.68)

func _sign_out() -> void:
	await SupabaseManager.sign_out()
	_update_account_controls()
