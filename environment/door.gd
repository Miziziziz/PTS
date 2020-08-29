extends StaticBody2D

onready var sample_player = get_node("SamplePlayer2D")
signal opened

func open_door():
	print("opening")
	#sample_player.play
	set_collision_mask(0)
	#set_layer_mask(0)
	collision_mask=0
	collision_layer=0
	emit_signal("opened")
