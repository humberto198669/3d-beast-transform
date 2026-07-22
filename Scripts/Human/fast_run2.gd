extends Node3D
func _ready():
	var anim = $AnimationPlayer
	anim.play("mixamo_com")
	anim.animation_finished.connect(_on_anim_finished)
		
func _on_anim_finished(anim_name):
	if anim_name == "mixamo_com":
		$AnimationPlayer.play("mixamo_com")
