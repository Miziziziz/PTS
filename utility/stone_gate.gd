extends StaticBody2D

onready var audio_player = $AudioStreamPlayer2D
onready var coll = $CollisionShape2D

onready var tile_map = get_parent().get_node("TileMap")

export var closed = true

signal opened
signal closed

func _ready():
	if tile_map != null:
		collision_layer = 0
		coll.disabled = true
	
	if closed:
		close()
	else:
		open()


func open():
	emit_signal("opened")
	audio_player.play()
	if tile_map != null:
		t_open()
		return
	collision_layer = 0
	coll.disabled = true

func close():
	emit_signal("closed")
	audio_player.play()
	if tile_map != null:
		t_close()
		return
	collision_layer = 1
	coll.disabled = false

func t_open():
	var pos = tile_map.world_to_map(global_position)
	tile_map.set_cellv(pos, -1)

func t_close():
	var pos = tile_map.world_to_map(global_position)
	tile_map.set_cellv(pos, 0)
