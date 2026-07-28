extends Camera3D

@export var player: Node3D
@export var height_offset := 4.35
@export var distance_offset := 6.2
@export var horizontal_follow := 0.55

func _process(_delta):
	if player == null:
		return
	
	position.x = lerp(position.x, player.position.x * horizontal_follow, 5.0 * _delta)
	position.y = height_offset
	position.z = player.position.z + distance_offset
