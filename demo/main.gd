extends Control

@export var timeline : HSlider
@export var texture : TextureRect

var is_playing: bool = false

func _on_play_pause_button_pressed() -> void:
	is_playing = !is_playing
