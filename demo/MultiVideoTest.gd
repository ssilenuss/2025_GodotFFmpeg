extends Node2D
@export var tr1 : TextureRect
@export var tr2 : TextureRect
var v1 : Video
var v2 : Video

func _ready() -> void:
	v1 = Video.new()
	v1.open_video("/Users/kmt/Downloads/A/Viera_A.mp4")

	v2 = Video.new()
	v2.open_video("/Users/kmt/Downloads/B/Viera_B.mp4")

	print("Video 1 FPS:", v1.get_avg_framerate())
	print("Video 2 FPS:", v2.get_avg_framerate())

	var img1 = v1.seek_frame(20)
	var img2 = v2.seek_frame(20)

	tr1.texture = ImageTexture.create_from_image(img1)
	tr2.texture = ImageTexture.create_from_image(img2)

func _process(delta: float) -> void:
	tr1.texture.set_image(v1.next_frame())
	tr2.texture.set_image(v2.next_frame())
