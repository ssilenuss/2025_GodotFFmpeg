extends Control

@export var timeline : HSlider
@export var texture_rect : TextureRect
@export var audio_player : AudioStreamPlayer
@export var frame_label : Label
var video : Video = Video.new()


var video_path : String = "/Users/kmt/Desktop/test2.mp4"
var is_playing: bool = false

var current_frame: int = 1
var max_frame: int = 0;
var audio_last_frame: int = 0
var file_last_frame : int = 0
var framerate: float = 0;
var frame_time : float = 0

var looping : bool = false

var time_elapsed: float = 0

var timeline_dragging : bool = false

func _ready() -> void:
	if FileAccess.file_exists(video_path) and video_path.ends_with(".mp4"):
		video.open_video(video_path)
		audio_player.stream = video.get_audio()
		
		
		framerate = video.get_avg_framerate()
		frame_time = 1.0 / framerate #in seconds
		
		file_last_frame = video.get_total_frame_nr()
		audio_last_frame = audio_player.stream.get_length()*framerate
		max_frame = file_last_frame#min(audio_last_frame, file_last_frame)
		print(file_last_frame)
		print(audio_last_frame)
		print(max_frame)

		timeline.min_value = 1
		timeline.value = 1
		timeline.max_value = max_frame
		
		video.seek_frame(current_frame)
	else:
		print("No video file at path.")
	
func seek_frame(a_frame_nr: int)->void:
	current_frame = clampi(a_frame_nr, 1, max_frame)
	texture_rect.texture.set_image(video.seek_frame(current_frame))
	audio_player.seek(current_frame/framerate)
	#print(current_frame)
	
func _process(delta: float) -> void:
	time_elapsed += delta
	
	if is_playing and time_elapsed >= frame_time:
			go_to_next_frame()

func go_to_next_frame()->void:
	while time_elapsed >= frame_time:
		time_elapsed -= frame_time
		current_frame += 1
	
	
	if current_frame >= max_frame:
		seek_frame(1)
		if not looping:
			audio_player.stop()
			is_playing = false
	else:
		var image : Image = video.next_frame()
		if not image.is_empty():
			texture_rect.texture.set_image(image)
			current_frame += 1
		
	if not timeline_dragging:
		timeline.value = current_frame
		frame_label.text = str(current_frame) + " / " + str(max_frame)

func _on_play_pause_button_pressed() -> void:
	
	is_playing = !is_playing
	if is_playing:
		audio_player.play()
	else:
		audio_player.set_stream_paused(true)


func _on_timeline_drag_ended(value_changed: bool) -> void:
	timeline_dragging = false
	if !value_changed:
		return
	seek_frame(int(timeline.value))
	


func _on_timeline_drag_started() -> void:
	timeline_dragging = true
