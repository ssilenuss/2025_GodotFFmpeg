extends Control
class_name VideoController

@export var video_num_label : Label
@export_global_file() var test_path: String
@export var windows : Node
@export var folder_a : VideoFolderButton
@export var folder_b : VideoFolderButton
@export var looping_button : Button
var vid_position := Vector2(200,200)
var hover_vw : VideoWindow

var looping : bool = false

var current_video: int : 
	set(value):
		current_video = clampi(value, 0, folder_a.video_paths.size()-1)
		video_num_label.text = "Current Video: " + str(current_video)


@export var playing : bool = false:
	set(value):
		playing = value
		for w in windows.get_children():
			if playing:
				w.player.play()
			else:
				w.player.stop()
				
var mouse_hidden: bool = false :
	set(value):
		mouse_hidden = value
		if mouse_hidden:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("spacebar"):
		_on_play_button_pressed()
	elif Input.is_action_just_pressed("hide_mouse"):
		mouse_hidden = !mouse_hidden
	elif Input.is_action_just_pressed("ui_left"):
		current_video -= 1
	elif Input.is_action_just_pressed("ui_right"):
		current_video += 1
	elif Input.is_action_just_pressed("ui_cancel"):
		mouse_hidden = false
		if hover_vw == null:
			pass
		else:
			if hover_vw.fullscreen:
				hover_vw.fullscreen = false
		

	


func _on_play_button_pressed() -> void:
	playing = !playing
	
func _on_video_finished()->void:
	playing = false
	playing = true


func _on_looping_pressed() -> void:
	looping = !looping
	if looping:
		looping_button.text = "LOOPING"
	else:
		looping_button.text = "SINGLE PLAY"
