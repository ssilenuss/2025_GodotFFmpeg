extends Control
class_name VideoController

@export var video_num_label : Label

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

var exhib_dir_a: String
var exhib_dir_b: String

var current_video: int :  
	set(value):
		current_video = wrapi(value, 0, max_videos)
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
	
		#only for foundations exhibition	
	exhib_dir_a = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)+"/Ea"
	exhib_dir_b = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)+"/Eb"
	var load0 : VideoFolderButton = $ScrollContainer/VBoxContainer/MarginContainer/Videos/HBoxContainer.get_child(0)
	load0.on_file_dialog_dir_selected(exhib_dir_a)
	#await get_tree().create_timer(1.0).timeout
	var load1 : VideoFolderButton = $ScrollContainer/VBoxContainer/MarginContainer/Videos/HBoxContainer.get_child(1)
	load1.on_file_dialog_dir_selected(exhib_dir_b)
	var w0 : VideoWindow = $Windows.get_child(0)
	var w1 : VideoWindow = $Windows.get_child(1)
	DisplayServer.window_set_current_screen(0, w0.get_window_id())
	DisplayServer.window_set_current_screen(1, w1.get_window_id())
	w0.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	w1.set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	w0.overlay.visible = false
	w1.overlay.visible = false
	_on_play_button_pressed()
	
	
	
	

		


	
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
		elif current_frame < af:
			for i in vids.size():
				#var lag : int = af- current_frame
				var img : Image
				img = vids[i].next_frame()
					
				current_frame = af
				#var img : Image = vids[i].next_frame()
				if !img.is_empty():
					textures[i].set_image(img)
				else:
					var img_black : Image = textures[i].get_image()
					img_black.fill(Color.BLACK)
					textures[i].set_image(img_black)
		#else:
			#for i in vids.size():
				#current_frame = af
				#seek_frame(current_frame)
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
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		
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
	
#func _on_video_finished()->void:
	#playing = false
	#playing = true

func seek_frame(_frame: int)->void:
	current_frame = _frame
	#current_frame = clampi(a_frame_nr, 1, max_frame)
	for i in windows.get_child_count():
		var img : Image = vids[i].seek_frame(_frame)
		if !img.is_empty():
			textures[i].set_image(img)
		else:
			var img_black : Image = textures[i].get_image()
			img_black.fill(Color.BLACK)
			textures[i].set_image(img_black)
		(audio_players.get_child(i) as AudioStreamPlayer).play()
		var audioframe: float = _frame / vids[i].get_r_framerate()
		(audio_players.get_child(i) as AudioStreamPlayer).seek(audioframe)
		(audio_players.get_child(i)).set_stream_paused(!playing)

func load_video(_idx: int)->void:
	
		
	current_frame = 1
		
	for i in vids.size():
		if _idx<(windows.get_child(i) as VideoWindow).paths.size():
			var v_path :String= (windows.get_child(i) as VideoWindow).paths[_idx]
			var v_title : String = (windows.get_child(i) as VideoWindow).titles[_idx]
			vids[i].open_video(v_path)
			(audio_players.get_child(i) as AudioStreamPlayer).stream = vids[i].get_audio()
			windows.get_child(i).title = v_title
			vids[i].seek_frame(1)
			#windows.get_child(i).size = vids[i].seek_frame(1).get_size()
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
	#print("Windows: ", windows.get_child_count(), " videos: ", vids.size(), " audios: ", audio_players.get_child_count())


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
		print("looping all videos")
	else:
		print("all open videos finished, moving on")
		current_frame = 1
		current_video += 1
		load_video(current_video)
		
func any_vid_still_playing()->bool:
	var still_playing := false
	var num_still_playing : int = 0
	for a in audio_players.get_children():
		if (a as AudioStreamPlayer).is_playing():
			still_playing = true
			num_still_playing +=1 
	print(num_still_playing, " vids still playing")
	return still_playing


func _on_overlay_timer_timeout() -> void:
	for w in $Windows.get_children():
		(w as VideoWindow).overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
