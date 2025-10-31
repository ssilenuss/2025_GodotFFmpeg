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

var finished_vids : int = 0

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

func _on_final_video_end()->void:
	pass
	
func _process(_delta: float) -> void:
	var af : int = 0
	for i in audio_players.get_child_count():
		if (audio_players.get_child(i) as AudioStreamPlayer).is_playing():
			var af2: int = int((audio_players.get_child(i) as AudioStreamPlayer).get_playback_position() * vids[i].get_r_framerate())
			if af2 > af:
				af = af2
			#audio_frames.append(af)
	
	if playing and audio_players.get_child_count()>=1:
		#var af: int = int((audio_players.get_child(0) as AudioStreamPlayer).get_playback_position() * vids[0].get_r_framerate()) 
		if af == 0:
			pass
				
		elif current_frame == af:
			pass
		elif current_frame == af - 1:
			for i in vids.size():
				current_frame = af
				var img : Image = vids[i].next_frame()
				if !img.is_empty():
					textures[i].set_image(img)
		else:
			for i in vids.size():
				current_frame = af
				seek_frame(current_frame)
		#var audio_frames : PackedInt32Array = []
		#for i in audio_players.get_child_count():
			#if (audio_players.get_child(i) as AudioStreamPlayer).is_playing():
				#var af: int = int((audio_players.get_child(i) as AudioStreamPlayer).get_playback_position() * vids[i].get_r_framerate())
				#audio_frames.append(af)
		#print(audio_frames)
		#for i in vids.size():
			#var img :Image = vids[i].next_frame()
		
				
	
	if Input.is_action_just_pressed("spacebar"):
		_on_play_button_pressed()
	elif Input.is_action_just_pressed("hide_mouse"):
		mouse_hidden = !mouse_hidden
	elif Input.is_action_just_pressed("ui_left"):
		current_video -= 1
		load_video(current_video)
	elif Input.is_action_just_pressed("ui_right"):
		current_video += 1
		load_video(current_video)
	elif Input.is_action_just_pressed("ui_cancel"):
		mouse_hidden = false
		if hover_vw == null:
			pass
		else:
			if hover_vw.fullscreen:
				hover_vw.fullscreen = false
		
func _on_play_button_pressed() -> void:
	playing = !playing
	if playing:
		for i in audio_players.get_child_count():
			if (audio_players.get_child(i) as AudioStreamPlayer).is_playing():
				(audio_players.get_child(i) as AudioStreamPlayer).set_stream_paused(false)
			else:
				(audio_players.get_child(i) as AudioStreamPlayer).play()
				(audio_players.get_child(i) as AudioStreamPlayer).seek(current_frame/vids[i].get_r_framerate())
	
	else:
		for i in audio_players.get_child_count():
			(audio_players.get_child(i) as AudioStreamPlayer).set_stream_paused(true)
	
func _on_video_finished()->void:
	playing = false
	playing = true

func seek_frame(_frame: int)->void:
	current_frame = _frame
	#current_frame = clampi(a_frame_nr, 1, max_frame)
	for i in windows.get_child_count():
		var img : Image = vids[i].seek_frame(_frame)
		if !img.is_empty():
			textures[i].set_image(img)
		(audio_players.get_child(i) as AudioStreamPlayer).play()
		var audioframe: float = _frame / vids[i].get_r_framerate()
		(audio_players.get_child(i) as AudioStreamPlayer).seek(audioframe)
		(audio_players.get_child(i)).set_stream_paused(!playing)

func load_video(_idx: int)->void:
	
		
	current_frame = 1
		
	for i in vids.size():
		var v_path :String= (windows.get_child(i) as VideoWindow).paths[_idx]
		var v_title : String = (windows.get_child(i) as VideoWindow).titles[_idx]
		vids[i].open_video(v_path)
		(audio_players.get_child(i) as AudioStreamPlayer).stream = vids[i].get_audio()
		windows.get_child(i).title = v_title
		windows.get_child(i).size = vids[i].seek_frame(1).get_size()
		windows.get_child(i).video = vids[i]
		windows.get_child(i).initialize_overlay()
		
	
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
		
		
	load_video(current_video)
	print("Windows: ", windows.get_child_count(), " videos: ", vids.size(), " audios: ", audio_players.get_child_count())


func _on_looping_pressed() -> void:
	looping = !looping
	if looping:
		looping_button.text = "LOOPING"
	else:
		looping_button.text = "SINGLE PLAY"

func all_vids_over()->void:
	if looping:
		playing=true
		seek_frame(1)
	else:
		current_video += 1
		load_video(current_video)
