extends Button

class_name VideoButton

var video_path : String = ""
var file_dialog := FileDialog.new()
var status : String

var video_window : PackedScene = preload("res://FullScreenSyncronizer/VideoWindow.tscn")

var vid_position := Vector2(800,800)

var window : Window


@export var root_node : VideoController

func _ready() -> void:
	pressed.connect(_on_pressed)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	text = "LOAD VIDEO"
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	#file_dialog.root_subfolder = OS.get_system_dir()
	file_dialog.filters = ["*.ogv ; OGV File", "*.mp4 ; MP4 File"]
	file_dialog.file_selected.connect(on_file_dialog_file_selected)
	add_child(file_dialog)
	

func _on_pressed()->void:
	file_dialog.popup_centered_ratio(0.6)

func on_file_dialog_file_selected(path:String) -> void:
	
	if path.ends_with(".ogv"):
		ogv_selected(path)
	elif path.ends_with(".mp4"):
		mp4_selected(path)
	else:
		print("No usable file selected")
		
func mp4_selected(_path:String)->void:
	if window:
		window.queue_free()
	print("MP4!!! ", _path)
	video_path = _path
	text = _path
	
	var path : String = ProjectSettings.globalize_path(root_node.ffplay_path)

	var arguments : PackedStringArray = ["-i", video_path]
	var output : Array = []
	var exit_code : int = OS.execute(path, arguments)
	if exit_code == 0:
		print("ffplay finished successfully.")
	else:
		print("ffplay encountered an error. Exit code: ", exit_code)
	
	
	
func ogv_selected(path:String)->void:
	video_path = path
	text = path
	
	var vb := VideoButton.new()
	vb.root_node = root_node
	get_parent().add_child(vb)
	

	var file:= VideoStreamTheora.new() 
	file.set_file(path)
	spawn_ogv_window(file)
	
func spawn_ogv_window(_file: VideoStreamTheora):
	
	if window:
		window.queue_free()
	window = video_window.instantiate()
	window.file = _file
	window.title = video_path
	window.root_node = root_node
	root_node.windows.add_child(window)
	

	
	
