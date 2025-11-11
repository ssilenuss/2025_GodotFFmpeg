extends Button

class_name VideoFolderButton

var video_titles : PackedStringArray = []
var video_paths : PackedStringArray = []
var file_dialog := FileDialog.new()
var status : String

var video_window : PackedScene = preload("res://FullScreenSyncronizer/VideoWindow.tscn")

var vid_offset := Vector2(200,200)

var window : VideoWindow

var playlist : VBoxContainer

var test_dir_a : String
var test_dir_b : String

@export var root_node : VideoController

var initialized := false

func _ready() -> void:
	pressed.connect(_on_pressed)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	text = "LOAD VIDEO FOLDER"
	
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	file_dialog.root_subfolder = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	
	add_child(file_dialog)
	file_dialog.dir_selected.connect(on_file_dialog_dir_selected)
	
	playlist = VBoxContainer.new()
	get_parent().add_child.call_deferred(playlist)
	print(playlist)
	

	


	
	

func _on_pressed()->void:
	file_dialog.popup_centered_ratio(0.6)

func on_file_dialog_dir_selected(path:String) -> void:
	print("folder selected: ", path)
	load_video_paths_from_folder(path)
	text = str(video_paths.size()) + " VIDEOS QUEUED"
	
	create_playlist()
	
	
	
func open_video_window()->void:
	
	var vb := VideoFolderButton.new()
	vb.root_node = root_node
	
	get_parent().add_child(vb)
	
	
	if window:
		window.queue_free()
	window = video_window.instantiate()
	window.paths = video_paths
	window.titles = video_titles
	window.root_node = root_node
	window.position = root_node.vid_position
	root_node.vid_position += vid_offset
	root_node.windows.add_child(window)
	
	var a := AudioStreamPlayer.new()
	root_node.audio_players.add_child(a)
	window.audio_player = a
	a.finished.connect(window._on_audio_finished)

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
		
	video_paths.sort()
	video_titles.sort()

	
	if video_paths.size() >= 1:
		open_video_window()
	else:
		print("An error occurred when trying to access the path: %s" % path)
		print("Error: %s" % DirAccess.get_open_error())
		
	

func create_playlist()->void:
	for each in playlist.get_children():
		each.queue_free()
	playlist.visible = true
	
	for i in video_titles.size():
		var l := Label.new()
		l.text = video_titles[i]
		playlist.add_child(l)
	
	
