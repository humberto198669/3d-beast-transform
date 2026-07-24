extends Control

@export var infinite_mode_scene := "res://Scenes/World1/World1.tscn"
@export var story_mode_scene := "res://Scenes/World1/World1.tscn"

@onready var story_button: TextureButton = $StoryButton
@onready var infinite_button: TextureButton = $InfiniteButton
@onready var level_label: Label = $TopStats/Level
@onready var distance_label: Label = $TopStats/Distance
@onready var coins_label: Label = $TopStats/Coins
@onready var record_label: Label = $TopStats/Record
@onready var progress_bar: ProgressBar = $TopStats/Progress
@onready var progress_text: Label = $TopStats/ProgressText
@onready var run_gain_label: Label = $RunGain
@onready var story_hint: PanelContainer = $StoryHint

var count_start_coins: int = 0
var count_start_distance: int = 0
var count_target_coins: int = 0
var count_target_distance: int = 0
var story_locked: bool = true
var story_hint_serial: int = 0

func _ready():
	story_button.pressed.connect(_on_story_pressed)
	infinite_button.pressed.connect(_on_infinite_pressed)
	story_button.mouse_entered.connect(_on_story_hovered)
	story_button.mouse_exited.connect(_on_story_unhovered)
	_setup_main_button_animation(story_button)
	_setup_main_button_animation(infinite_button)
	var pending_run: Vector2i = Progression.take_pending_run_animation()
	if pending_run.x > 0 or pending_run.y > 0:
		_start_profile_countup(pending_run)
	else:
		_update_progress_display()

func _update_progress_display() -> void:
	_display_progress(Progression.total_distance, Progression.total_coins)

func _display_progress(display_distance: int, display_coins: int) -> void:
	var level: int = Progression.get_level_for_distance(display_distance)
	var level_start: int = Progression.get_level_start_distance(level)
	var next_level: int = Progression.get_next_level_distance(level)
	var current_progress: int = display_distance - level_start
	var required_progress: int = next_level - level_start
	level_label.text = "NIVEL\n%d" % level
	progress_bar.value = Progression.get_level_progress_for_distance(display_distance) * 100.0
	progress_text.text = "%s / %s m" % [_format_number(current_progress), _format_number(required_progress)]
	distance_label.text = "%s m" % _format_number(display_distance)
	coins_label.text = _format_number(display_coins)
	record_label.text = "%s m" % _format_number(Progression.best_distance)
	# El modo historia permanece visible, pero no se puede abrir mientras está
	# en construcción. El botón sigue recibiendo mouse/touch para mostrar el aviso.
	story_locked = true
	story_button.disabled = false
	story_button.modulate = Color(0.38, 0.38, 0.38, 0.88)
	var story_label: Label = story_button.get_node("Label") as Label
	if story_label != null:
		story_label.modulate = Color(0.76, 0.76, 0.76, 1.0)
		story_label.text = "MODO HISTORIA"

func _setup_main_button_animation(button: TextureButton) -> void:
	button.pivot_offset = button.size * 0.5
	button.mouse_entered.connect(_animate_main_button.bind(button, Vector2(1.04, 1.04)))
	button.mouse_exited.connect(_animate_main_button.bind(button, Vector2.ONE))
	button.button_down.connect(_animate_main_button.bind(button, Vector2(0.96, 0.96)))
	button.button_up.connect(_animate_main_button.bind(button, Vector2(1.04, 1.04)))

func _animate_main_button(button: TextureButton, target_scale: Vector2) -> void:
	create_tween().tween_property(button, "scale", target_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_story_hovered() -> void:
	if story_locked:
		_show_story_hint(false)

func _on_story_unhovered() -> void:
	story_hint_serial += 1
	story_hint.hide()

func _show_story_hint(auto_hide: bool) -> void:
	story_hint_serial += 1
	var current_serial: int = story_hint_serial
	story_hint.modulate.a = 0.0
	story_hint.show()
	create_tween().tween_property(story_hint, "modulate:a", 1.0, 0.16)
	if auto_hide:
		await get_tree().create_timer(2.2).timeout
		if current_serial == story_hint_serial:
			story_hint.hide()

func _start_profile_countup(run_gain: Vector2i) -> void:
	count_target_coins = Progression.total_coins
	count_target_distance = Progression.total_distance
	count_start_coins = maxi(0, count_target_coins - run_gain.x)
	count_start_distance = maxi(0, count_target_distance - run_gain.y)
	run_gain_label.text = "+%s MONEDAS   +%s m" % [
		_format_number(run_gain.x),
		_format_number(run_gain.y)
	]
	run_gain_label.visible = true
	run_gain_label.modulate.a = 0.0
	_display_progress(count_start_distance, count_start_coins)
	var gain_tween: Tween = create_tween().set_parallel(true)
	gain_tween.tween_property(run_gain_label, "modulate:a", 1.0, 0.25)
	gain_tween.tween_property(run_gain_label, "scale", Vector2(1.08, 1.08), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var count_tween: Tween = create_tween()
	count_tween.tween_method(_apply_profile_countup, 0.0, 1.0, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	count_tween.tween_callback(_finish_profile_countup)

func _apply_profile_countup(progress: float) -> void:
	var animated_coins: int = roundi(lerpf(float(count_start_coins), float(count_target_coins), progress))
	var animated_distance: int = roundi(lerpf(float(count_start_distance), float(count_target_distance), progress))
	_display_progress(animated_distance, animated_coins)

func _finish_profile_countup() -> void:
	_display_progress(count_target_distance, count_target_coins)
	var settle_tween: Tween = create_tween()
	settle_tween.tween_property(run_gain_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE)

func _format_number(value: int) -> String:
	var raw: String = str(maxi(0, value))
	var formatted := ""
	while raw.length() > 3:
		formatted = "." + raw.right(3) + formatted
		raw = raw.left(raw.length() - 3)
	return raw + formatted

func _on_story_pressed():
	if story_locked:
		_show_story_hint(true)
		return
	SceneTransition.change_scene(story_mode_scene)

func _on_infinite_pressed():
	SceneTransition.change_scene(infinite_mode_scene)
