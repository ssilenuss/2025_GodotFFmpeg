extends Control
class_name VideoPlayback_UI

@export var video_playback : VideoPlayback
@export var play_button : Button
@export var timeline : HSlider
@export var container : Container
@export var total_time_label : Label
@export var current_time_label : Label

var hover = false
var timeline_dragging : bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	timeline.drag_started.connect(_on_timeline_drag_started)
	timeline.drag_ended.connect(_on_timeline_drag_ended)
	
	play_button.pressed.connect(_on_play_button_pressed)
	

func _process(_delta: float) -> void:
	if not timeline_dragging and video_playback.is_playing:
		timeline.value = video_playback.current_frame
		current_time_label.text = timebase_convert(int(timeline.value))

func _on_video_opened()->void:
	timeline.min_value = 1
	timeline.max_value = video_playback.max_frame
	timeline.value = 1
	
	total_time_label.text = " / " + timebase_convert(video_playback.max_frame)
	current_time_label.text = timebase_convert(video_playback.current_frame)
	
func timebase_convert(_frame: int)->String:
	var fr : float = video_playback.framerate
	var seconds: int = int( _frame/fr )
	var time_string: String = ""
	var h : int = int(seconds / 3600.0)
	seconds -= h * 3600
	var m : int = int(seconds / 60.0)
	seconds -= m * 60
	var s : int = seconds
	var f : int = int(fmod(_frame, fr))
	#print("framerate: ", video_playback.framerate)
	#print("_frame: ", _frame)
	#print("frame: ", f)
	#print("seconds: ", s)
	#print("min: ", m)
	#print("hours: ", h)
	time_string = "%02d" % h + ":" + "%02d" % m + ":" + "%02d" % s + ":" + "%02d" % f  #"{:02d}".format(h) + ":" + "{:02d}".format(m) + ":" + "%02d" % s
	return time_string

func _on_play_button_pressed()->void:
	print("play pressed")
	video_playback._on_play_pause()
	
func _on_timeline_drag_started()->void:
	timeline_dragging = true

func _on_timeline_drag_ended(_value_changed: bool)->void:
	timeline_dragging = false
	if !_value_changed:
		return
	video_playback.seek_frame(int(timeline.value))
	timeline.value = video_playback.current_frame
	current_time_label.text = timebase_convert(int(timeline.value))
	

func _on_mouse_entered()->void:
	hover = true
	#container.visible = hover
	
func _on_mouse_exited()->void:
	hover = false
	#container.visible = hover
	
	
