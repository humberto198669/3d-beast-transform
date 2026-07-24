extends CanvasLayer

const FADE_OUT_TIME := 0.24
const FADE_IN_TIME := 0.32

var overlay: ColorRect
var transitioning := false

func _ready() -> void:
	layer = 1000
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.11, 0.055, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func change_scene(scene_path: String) -> void:
	if transitioning or scene_path.is_empty():
		return
	transitioning = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_out: Tween = create_tween()
	fade_out.tween_property(overlay, "color", Color(0.008, 0.075, 0.035, 1.0), FADE_OUT_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fade_out.finished
	var change_error: Error = get_tree().change_scene_to_file(scene_path)
	if change_error != OK:
		overlay.color.a = 0.0
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transitioning = false
		push_error("No se pudo abrir la escena: %s" % scene_path)
		return
	await get_tree().process_frame
	var fade_in: Tween = create_tween()
	fade_in.tween_property(overlay, "color", Color(0.015, 0.11, 0.055, 0.0), FADE_IN_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transitioning = false
