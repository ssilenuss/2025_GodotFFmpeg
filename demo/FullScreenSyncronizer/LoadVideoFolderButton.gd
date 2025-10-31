extends Button

class_name VideoFolderButton

var video_titles : PackedStringArray = []
var video_paths : PackedStringArray = []
var file_dialog := FileDialog.new()
var status : String

var video_window : PackedScene = preload("res://FullScreenSyncronizer/VideoWindow.tscn")

var vid_offset := Vector2(200,200)

var window : VideoWindow


@export var root_node : VideoController

func _ready() -> void:
	pressed.connect(_on_pressed)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	text = "LOAD VIDEO FOLDER"
	
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	
	add_child(file_dialog)
	file_dialog.dir_selected.connect(on_file_dialog_dir_selected)
	
	

func _on_pressed()->void:
	file_dialog.popup_centered_ratio(0.6)

func on_file_dialog_dir_selected(path:String) -> void:
	print("folder selected: ", path)
	load_video_paths_from_folder(path)
	text = str(video_paths.size()) + " VIDEOS QUEUED"
	
	
	
func open_video_window()->void:
	
	var vb := VideoFolderButton.new()
	vb.root_node = root_node
	vb.position = root_node.vid_position
	root_node.vid_position += vid_offset
	get_parent().add_child(vb)
	
	
	if window:
		window.queue_free()
	window = video_window.instantiate()
	window.paths = video_paths
	window.titles = video_titles
	window.root_node = root_node
	root_node.windows.add_child(window)

	root_node.init_videos()

func _recursive_dir_search(_dir: DirAccess, _dir_path: String)->void:
	var file_name = _dir.get_next()
	if file_name == "":
		
		return
	else:
		if file_name.ends_with(".mp4") or file_name.ends_with(".mov") or file_name.ends_with(".ogv"):
			video_titles.append(file_name)
			file_name = _dir_path.path_join(file_name)
			video_paths.append(file_name)
			
		_recursive_dir_search(_dir, _dir_path)
		
		

func load_video_paths_from_folder(path: String) -> void:
	video_paths = []
	video_titles = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		_recursive_dir_search(dir, path)
	
	if video_paths.size() >= 1:
		open_video_window()
	else:
		print("An error occurred when trying to access the path: %s" % path)
		print("Error: %s" % DirAccess.get_open_error())

	
