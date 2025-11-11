extends TextureRect
class_name VideoPlayback

var video : Video 
@export var video_path : String 
@export var window_parent :VideoWindow

var audio_player : AudioStreamPlayer 
var is_playing: bool = false
var current_frame: int = 1
var current_audio_frame : int = 1
var max_frame: int = 0;
var framerate: float = 0;
var frame_time : float = 0

var looping : bool = false

var time_elapsed: float = 0

var video_size : Vector2

signal video_opened

func _ready() -> void:
	#create audiostream player
	video = Video.new()
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.finished.connect(_on_audio_stream_player_finished)
	
	video_path = window_parent.paths[0]
	open_video(video_path)
	
func open_video(_path: String)->void:
	if FileAccess.file_exists(video_path):
		if not video_path.ends_with(".mp4") or video_path.ends_with(".mov") or video_path.ends_with(".ogv"):
			print("file not a mp4, mov, or ogv")
			return
			
		video.open_video(video_path)
		
		framerate = video.get_fps()
		frame_time = 1.0 / framerate #in seconds
		
		audio_player.stream = video.get_audio()
		audio_player.play()
		seek_frame(1)
		
		video_size = texture.get_size()
		window_parent.size = video_size
		
		audio_player.set_stream_paused(true)
		
		
		
		max_frame = video.get_total_frames()
		
		video_opened.emit()
		
	else:
		print("no file at path.")
		
func seek_frame(a_frame_nr: int)->void:
	current_frame = clampi(a_frame_nr, 1, max_frame)
	texture.set_image(video.seek_frame(current_frame))
	audio_player.play()
	audio_player.seek(current_frame/framerate)
	audio_player.set_stream_paused(!is_playing)

func seek_frame_to_audio()->void:
	current_frame = current_audio_frame
	texture.set_image(video.seek_frame(current_frame))
	
func _process(delta: float) -> void:
	time_elapsed += delta
	
	if is_playing and time_elapsed >= frame_time:
		go_to_next_frame()
	
	current_audio_frame = int(audio_player.get_playback_position() * framerate)
	if abs(current_audio_frame-current_frame)> 2:
		print("out of sync!!!! ", current_audio_frame ,":" ,current_frame )
		seek_frame_to_audio()
	
	#print(current_frame, " : ", current_audio_frame)
#
func go_to_next_frame()->void:

	while time_elapsed >= frame_time:
		time_elapsed -= frame_time
	
	var image : Image = video.next_frame()
	current_frame += 1
	if not image.is_empty():
		modulate = Color.WHITE
		texture.set_image(image)
	else:
		modulate = Color.RED

func _on_play_pause()->void:
	is_playing = !is_playing
	if is_playing:
		#audio_player.seek(current_frame/framerate)
		if audio_player.is_playing():
			audio_player.set_stream_paused(false)
		else:
			audio_player.play()
			audio_player.seek(current_frame/framerate)
	else:
		audio_player.set_stream_paused(true)
	
#
#
func _on_audio_stream_player_finished() -> void:
	seek_frame(1)
	if not looping:
		audio_player.stop()
		is_playing = false
