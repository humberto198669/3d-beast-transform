extends Control

@export var infinite_mode_scene := "res://Scenes/World1/World1.tscn"
@export var story_mode_scene := "res://Scenes/World1/World1.tscn"

@onready var story_button: Button = $StoryButton
@onready var infinite_button: Button = $InfiniteButton

func _ready():
	story_button.pressed.connect(_on_story_pressed)
	infinite_button.pressed.connect(_on_infinite_pressed)

func _on_story_pressed():
	get_tree().change_scene_to_file(story_mode_scene)

func _on_infinite_pressed():
	get_tree().change_scene_to_file(infinite_mode_scene)
