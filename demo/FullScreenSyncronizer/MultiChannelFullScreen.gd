extends Control
class_name VideoController

@export var video_num_label : Label
@export_global_file() var test_path: String
@export var windows : Node
@export var looping_button : Button
@export var audio_players : Node

var vids : Array [Video] = []

var textures : Array[ImageTexture] = []

var vid_position := Vector2(200,200)
var hover_vw : VideoWindow

var looping : bool = false

var max_videos : int = 0

var current_video: int :  
	set(value):
		current_video = clampi(value, 0, max_videos)
		video_num_label.text = "Current Video: " + str(current_video)
		
var current_frame : int = 1


@export var playing : bool = false:
	set(value):
		playing = value
				
var mouse_hidden: bool = false :
	set(value):
		mouse_hidden = value
		if mouse_hidden:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _ready() -> void:
	get_viewport().set_embedding_subwindows(false)
	
	current_video = 0


	
func _process(_delta: float) -> void:
	
	if playing:
		for i in vids.size():
			var img :Image = vids[i].next_frame()
		
				
	
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

func seek_frame(_frame: int)->void:
	#current_frame = clampi(a_frame_nr, 1, max_frame)
	for i in windows.get_child_count():
		textures[i].set_image(vids[i].seek_frame(_frame))
		(audio_players.get_child(i) as AudioStreamPlayer).play()
		var audioframe: float = _frame / vids[i].get_r_framerate()
		(audio_players.get_child(i) as AudioStreamPlayer).seek(audioframe)
		(audio_players.get_child(i)).set_stream_paused(!playing)

func load_video(_idx: int)->void:
	
	#if vids.size() != windows.get_child_count():
		#print("wrong num videos / windows!  can't load videos!")
		#return
		
	current_frame = 1
		
	for i in vids.size():
		var v_path :String= (windows.get_child(i) as VideoWindow).paths[_idx]
		var v_title : String = (windows.get_child(i) as VideoWindow).titles[_idx]
		vids[i].open_video(v_path)
		(audio_players.get_child(i) as AudioStreamPlayer).stream = vids[i].get_audio()
		windows.get_child(i).title = v_title
	
	seek_frame(1)
		
	
func init_videos()->void:
	textures = []
	vids = []
	max_videos = 0
	current_video = 0
	for w in windows.get_children():
		vids.append(Video.new())
		textures.append(w.video_texture.texture)
		max_videos = max(max_videos, w.paths.size())
		
		var a := AudioStreamPlayer.new()
		audio_players.add_child(a)
	load_video(current_video)


func _on_looping_pressed() -> void:
	looping = !looping
	if looping:
		looping_button.text = "LOOPING"
	else:
		looping_button.text = "SINGLE PLAY"
