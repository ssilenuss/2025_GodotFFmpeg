extends Control

@export var timeline : HSlider
@export var texture_rect : TextureRect
@export var audio_player : AudioStreamPlayer
@export var frame_label : Label
var video : Video = Video.new()


var video_path : String = "/Users/kmt/Desktop/gangwisch_bodybloxXR_short.mp4"
var is_playing: bool = false

var current_frame: int = 1
var max_frame: int = 0;
var framerate: float = 0;
var frame_time : float = 0

func _ready() -> void:
	if FileAccess.file_exists(video_path) and video_path.ends_with(".mp4"):
		video.open_video(video_path)
		audio_player.stream = video.get_audio()
		
		max_frame = video.get_total_frame_nr()
		framerate = video.get_avg_framerate()
		frame_time = 1.0 / framerate #in seconds

		timeline.min_value = 1
		timeline.value = 1
		timeline.max_value = max_frame
		
		video.seek_frame(current_frame)
	else:
		print("No video file at path.")
	
func seek_frame(a_frame_nr: int)->void:
	current_frame = a_frame_nr
	texture_rect.texture.set_image(video.seek_frame(current_frame))
	#print(current_frame)
func _process(_delta: float) -> void:
	if is_playing:
		if current_frame >= max_frame:
			pass
		else:
			texture_rect.texture.set_image(video.next_frame())
			current_frame += 1
		timeline.value = current_frame
		frame_label.text = str(current_frame) + " / " + str(max_frame)
func _on_play_pause_button_pressed() -> void:
	
	is_playing = !is_playing
	audio_player.set_stream_paused(is_playing)


func _on_timeline_drag_ended(value_changed: bool) -> void:
	if !value_changed:
		print("test")
		return
	seek_frame(int(timeline.value))
