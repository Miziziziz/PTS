extends Node2D

const MOVE_SPEED = 1 # meters per second
const STEP_RATE = 0.5 #time to travel one grid place
const FOOTSTEPS = ["footstep_1", "footstep_2", "footstep_3"] #footstep sounds

const small_echo = 0.5
const large_echo = 1

var tile_map = null
const small_echo_tile_ind = 1
const large_echo_tile_ind = 2

var audio_folder = "res://characters/player/player_audio/"

var distance_since_last_step = 0

var dir_vector = Vector2()
var kine_body = null
var moving = false
var travel_time = 0
var goal_pos = Vector2()
var last_pos = Vector2()
var cur_vector = Vector2()
var col_shape = CircleShape2D.new()
const move_vecs = [
Vector2(0, 1),
Vector2(1, 0),
Vector2(0, -1),
Vector2(-1, 0),
]

onready var shape_obj = get_parent().get_node("CollisionShape2D")
onready var move_ray = $MoveRay #get_node("MoveRay") # collision checking
onready var step_player = $StepPlayer #get_node("StepPlayer")

var bus_index = 0

func _ready():
	bus_index = AudioServer.get_bus_index(step_player.bus)
	var rad = shape_obj.shape.radius
	col_shape.radius = rad
	var par = get_parent()
	var pos = par.global_position
	last_pos = global_position

# dir_vector: direction to move
# delta: time since last frame

func _physics_process(delta):
	if kine_body == null:
		return
	if !moving and dir_vector.length_squared() > 0:
		cur_vector = calc_move_vec(dir_vector.rotated(global_rotation))
		goal_pos = cur_vector * 16 + global_position
		goal_pos.x = int(goal_pos.x)
		goal_pos.y = int(goal_pos.y)
		if can_move():
			signal_new_position(goal_pos)
			moving = true
	
	if travel_time >= STEP_RATE:
		travel_time = 0
		moving = false
		kine_body.global_position = goal_pos
		shape_obj.position = Vector2()
		play_step()
	
	if moving:
		shape_obj.global_position = goal_pos
		travel_time += delta
		kine_body.move_and_collide(cur_vector * STEP_RATE)
	

# for obtaining an axis aligned vector
func calc_move_vec(var m_vec):
	var max_d = 0
	var final_vec = move_vecs[0]
	for vec in move_vecs:
		var d = vec.dot(m_vec)
		if d > max_d:
			max_d = d
			final_vec = vec
	return final_vec


func can_move():
	var space_rid = get_world_2d().space
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var motion = goal_pos - global_position
	var query = Physics2DShapeQueryParameters.new()
	query.motion = motion
	query.set_shape(col_shape)
	query.collision_layer = 1
	query.exclude = [get_parent()]
	query.transform = get_parent().transform
	var result = space_state.cast_motion(query)
	#print(result)
	#print(global_position)
	return result.size() == 2 and result[0] == 1 and result[1] == 1
	

func play_step():
	set_footstep_echo()
	var step_index = randi() % FOOTSTEPS.size()
	var sample = load(audio_folder + FOOTSTEPS[step_index] + ".wav")
	step_player.stream = sample
	step_player.play()

func set_footstep_echo():
	var reverb = AudioServer.get_bus_effect(bus_index, 0)
	reverb.dry = 1
	reverb.wet = 0
	
	if tile_map == null:
		return
	
	var t_pos = tile_map.world_to_map(global_position)
	#var t_ind = tile_map.get_cellv(t_pos)
	#print(t_pos)
	var p = 0
	if tile_map.get_cellv(t_pos + Vector2(1, 0)) < 0:
		p += 1
	if tile_map.get_cellv(t_pos + Vector2(0, 1)) < 0:
		p += 1
	if tile_map.get_cellv(t_pos + Vector2(-1, 0)) < 0:
		p += 1
	if tile_map.get_cellv(t_pos + Vector2(0, -1)) < 0:
		p += 1
	
	if p == 3:
		reverb.dry = 0.9
		reverb.wet = 0.5
		reverb.room_size = 0.4
	if p > 3:
		reverb.dry = 0.8
		reverb.wet = 1
		reverb.room_size = 1


func signal_new_position(var pos):
	#get_tree().call_group("doors", "set_player", self)
	get_tree().call_group("enemies", "update_player_pos", pos)
