extends Window
class_name VideoWindow

var paths : PackedStringArray
var titles : PackedStringArray
var root_node : VideoController
var video : Video
var audio_player : AudioStreamPlayer
@export var video_texture : TextureRect
@export var overlay: VideoPlayback_UI

@export var vid_idx : int :
	set(value):
		vid_idx = clamp(value, 0, paths.size())
		

var fullscreen := false :
	set(value):
		fullscreen = value
		if fullscreen:
			set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
			#fullscreen_button.text = "MINIMIZE"
			
		else:
			set_mode(Window.MODE_WINDOWED)
			#fullscreen_button.text = "FULLSCREEN"

func initialize_overlay()->void:
	overlay.initialize()

func _ready() -> void:
	video_texture.texture = ImageTexture.new()
	pass
	#player = VideoStreamPlayer.new()
	#if file:
		##player data
		#
		#player.set_stream(file)
		#
		#
	#player.set_expand(true)
	##player.set_autoplay(true)
	#$VideoHolder.add_child(player)
	#
	#
	#player.play()
	#print("stream: ", player.get_stream())
	#var video_size : Vector2 = player.get_video_texture().get_size()
	#size = video_size
	#
#
	#
	##window data
	##title = player.get_stream_name()
#
#
	#visible = true
	#root_node.vid_position += size/2.0
	#position =  root_node.vid_position
	#player.finished.connect(root_node._on_video_finished)
#
#func _process(_delta: float) -> void:
	#if frame == 0:
		#frame +=1
	#elif frame == 1:
		#player.stop()
		#frame += 1
		#
	#
func _on_close_requested() -> void:
	audio_player.queue_free()
	root_node.vids.erase(video)
	root_node.textures.erase(video_texture.texture)
	self.queue_free()
#
#
func _on_size_changed() -> void:
	if video_texture:
		video_texture.set_custom_minimum_size(size)
		#print(size, player.size)
#
#
func _on_mouse_entered() -> void:
	root_node.hover_vw = self
	
	if root_node.mouse_hidden:
		return
	#
	overlay.visible = true
#
#
func _on_mouse_exited() -> void:
	overlay.visible = false
#
#
func _on_fullscreen_pressed() -> void:
	fullscreen = !fullscreen
	
func _on_audio_finished()->void:
	audio_player.stop()
	root_node.finished_vids += 1
	if root_node.finished_vids >= root_node.vids.size():
		root_node.all_vids_over()
	
