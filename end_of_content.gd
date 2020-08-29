extends AudioStreamPlayer
onready var lm = get_node("/root/levelmanager")

func _ready():
	A3dView.disable_3d_view()
	connect("finished", lm, "return_to_main_menu")

