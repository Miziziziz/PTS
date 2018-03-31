extends Node2D

const MOVE_SPEED = 1 # meters per second
const STEP_RATE = 0.5 #time to travel one grid place
const FOOTSTEPS = ["footstep_1", "footstep_2", "footstep_3"] #footstep sounds

var audio_folder = "res://characters/player/player_audio/"

var distance_since_last_step = 0

var dir_vector = Vector2()
var kine_body = null
var moving = false
var travel_time = 0
var goal_pos = Vector2()
var last_pos = Vector2()
var cur_vector = Vector2()
const move_vecs = [
Vector2(0, 1),
Vector2(1, 0),
Vector2(0, -1),
Vector2(-1, 0),
]

onready var shape_obj = get_parent().get_node("CollisionShape2D")
onready var move_ray = $MoveRay #get_node("MoveRay") # collision checking
onready var step_player = $StepPlayer #get_node("StepPlayer")

func _ready():
	last_pos = global_position

# dir_vector: direction to move
# delta: time since last frame

func _physics_process(delta):
	if kine_body == null:
		return
	
	if !moving and dir_vector.length_squared() > 0:
		cur_vector = calc_move_vec(dir_vector.rotated(global_rotation))
		goal_pos = cur_vector * 16 + global_position
		if can_move():
			signal_new_position(goal_pos)
			moving = true
	
	if moving:
		travel_time += delta
		kine_body.move_and_collide(cur_vector * STEP_RATE)
	
	if travel_time >= STEP_RATE:
		travel_time = 0
		moving = false
		kine_body.global_position = goal_pos
		play_step()
"""
func move_body(var kine_body, var dir_vector, var delta):
	
	
	var start_pos = global_position
	var rot = atan2(dir_vector.x, dir_vector.y)
	var our_rot = global_rotation
	
	if can_move(rot) && dir_vector.length_squared() > 0:
		signal_new_position()
		kine_body.move_and_collide(dir_vector.rotated(our_rot) * MOVE_SPEED)
		attempt_step()
	#print("cur: %s last: %s" % [cur_pos, last_pos])
	var cur_pos = global_position
	
	if made_invalid_move():
		kine_body.global_position = last_pos
		cur_pos = last_pos
	else:
		distance_since_last_step += cur_pos.distance_to(start_pos)
	
	last_pos = cur_pos
"""

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
	query.set_shape(shape_obj.shape)
	query.collision_layer = 1
	query.transform = shape_obj.transform
	var result = space_state.cast_motion(query)
	print(result)
	return true
	"""
	detector.global_position = goal_pos
	#yield(get_tree(), "idle_frame")
	print("check:", detector.get_overlapping_bodies())
	return detector.get_overlapping_bodies().size() == 0
	"""
	"""
	move_ray.rotation = rot * -1
	return !move_ray.is_colliding()
	"""

func attempt_step():
	if (distance_since_last_step >= STEP_RATE):
		var before = distance_since_last_step
		distance_since_last_step -= STEP_RATE
		#distance_since_last_step = fposmod(distance_since_last_step, STEP_RATE)
		play_step()

func play_step():
	var step_index = randi() % FOOTSTEPS.size()
	var sample = load(audio_folder + FOOTSTEPS[step_index] + ".wav")
	step_player.stream = sample
	step_player.play()

func signal_new_position(var pos):
	get_tree().call_group("doors", "set_player", self)
	get_tree().call_group("enemies", "update_player_pos", pos)
