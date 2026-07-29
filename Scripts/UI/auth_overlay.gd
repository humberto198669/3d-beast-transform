extends Control

signal continue_requested

enum FormMode { NONE, SIGN_UP, SIGN_IN, RECOVER }

@onready var choices: VBoxContainer = $Center/Card/Margin/Layout/Choices
@onready var form: VBoxContainer = $Center/Card/Margin/Layout/Form
@onready var main_title: Label = $Center/Card/Margin/Layout/Title
@onready var subtitle: Label = $Center/Card/Margin/Layout/Subtitle
@onready var form_title: Label = $Center/Card/Margin/Layout/Form/FormTitle
@onready var email_input: LineEdit = $Center/Card/Margin/Layout/Form/Email
@onready var password_input: LineEdit = $Center/Card/Margin/Layout/Form/Password
@onready var confirm_input: LineEdit = $Center/Card/Margin/Layout/Form/ConfirmPassword
@onready var message_label: Label = $Center/Card/Margin/Layout/Form/Message
@onready var submit_button: Button = $Center/Card/Margin/Layout/Form/Submit
@onready var recover_button: Button = $Center/Card/Margin/Layout/Form/Recover

var form_mode: FormMode = FormMode.NONE
var request_in_progress: bool = false

func _ready() -> void:
	$Center/Card/Margin/Layout/Choices/CreateAccount.pressed.connect(_show_sign_up)
	$Center/Card/Margin/Layout/Choices/SignIn.pressed.connect(_show_sign_in)
	$Center/Card/Margin/Layout/Choices/Guest.pressed.connect(_continue_as_guest)
	$Center/Card/Margin/Layout/Form/Submit.pressed.connect(_submit_form)
	$Center/Card/Margin/Layout/Form/Recover.pressed.connect(_show_recover)
	$Center/Card/Margin/Layout/Form/Back.pressed.connect(_show_choices)
	visibility_changed.connect(_on_visibility_changed)
	_show_choices()

func open() -> void:
	visible = true
	modulate.a = 0.0
	$Center/Card.scale = Vector2(0.92, 0.92)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	tween.tween_property($Center/Card, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_choices() -> void:
	form_mode = FormMode.NONE
	choices.visible = true
	form.visible = false
	main_title.text = "BIENVENIDO"
	subtitle.text = "Guarda tu aventura o entra directamente al mundo de BeastMorph."
	_clear_form()

func _show_sign_up() -> void:
	form_mode = FormMode.SIGN_UP
	_show_form("CREAR CUENTA", "CREAR MI CUENTA")
	confirm_input.visible = true
	recover_button.visible = false

func _show_sign_in() -> void:
	form_mode = FormMode.SIGN_IN
	_show_form("INICIAR SESIÓN", "ENTRAR")
	confirm_input.visible = false
	recover_button.visible = true

func _show_recover() -> void:
	form_mode = FormMode.RECOVER
	_show_form("RECUPERAR CONTRASEÑA", "ENVIAR CORREO")
	password_input.visible = false
	confirm_input.visible = false
	recover_button.visible = false
	subtitle.text = "Recibirás un correo seguro para establecer una nueva contraseña."

func _show_form(title_text: String, submit_text: String) -> void:
	choices.visible = false
	form.visible = true
	form_title.text = title_text
	submit_button.text = submit_text
	password_input.visible = true
	message_label.text = ""
	subtitle.text = "Tu progreso podrá recuperarse al reinstalar el juego."
	email_input.grab_focus()

func _submit_form() -> void:
	if request_in_progress:
		return
	var email: String = email_input.text.strip_edges()
	if not _is_valid_email(email):
		_show_message("Introduce un correo válido.", true)
		return
	if form_mode != FormMode.RECOVER:
		if password_input.text.length() < 8:
			_show_message("La contraseña debe tener al menos 8 caracteres.", true)
			return
		if form_mode == FormMode.SIGN_UP and password_input.text != confirm_input.text:
			_show_message("Las contraseñas no coinciden.", true)
			return
	_set_busy(true)
	var result: Dictionary
	match form_mode:
		FormMode.SIGN_UP:
			result = await SupabaseManager.sign_up(email, password_input.text)
		FormMode.SIGN_IN:
			result = await SupabaseManager.sign_in(email, password_input.text)
		FormMode.RECOVER:
			result = await SupabaseManager.send_password_reset(email)
		_:
			result = {"ok": false, "message": "Formulario no disponible."}
	_set_busy(false)
	if not bool(result.get("ok", false)):
		_show_message(str(result.get("message", "No se pudo completar la solicitud.")), true)
		return
	if form_mode == FormMode.RECOVER:
		_show_message("Correo enviado. Revisa también la carpeta de spam.", false)
		return
	if SupabaseManager.is_logged_in():
		_show_message("Sincronizando tu aventura...", false)
		await SupabaseManager.synchronize_progress()
		continue_requested.emit()
	else:
		_show_message("Cuenta creada. Confirma el correo y luego inicia sesión.", false)

func _continue_as_guest() -> void:
	continue_requested.emit()

func _set_busy(busy: bool) -> void:
	request_in_progress = busy
	submit_button.disabled = busy
	email_input.editable = not busy
	password_input.editable = not busy
	confirm_input.editable = not busy
	if busy:
		message_label.text = "CONECTANDO..."

func _show_message(message: String, is_error: bool) -> void:
	message_label.text = message
	message_label.modulate = Color(1.0, 0.48, 0.38) if is_error else Color(0.55, 1.0, 0.68)

func _clear_form() -> void:
	email_input.text = ""
	password_input.text = ""
	confirm_input.text = ""
	message_label.text = ""

func _is_valid_email(email: String) -> bool:
	var at_position: int = email.find("@")
	var dot_position: int = email.rfind(".")
	return at_position > 0 and dot_position > at_position + 1 and dot_position < email.length() - 1

func _on_visibility_changed() -> void:
	if visible and is_node_ready():
		_show_choices()
