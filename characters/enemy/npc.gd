extends KinematicBody2D

onready var db = get_node("/root/entity_database")
export var id = ""

#same for everyone
const attack_range = 20
const sight_range = 480

#initialize to default values
var npc_name = "default npc"
var attitude = "friendly"
var move_speed = 2
var attack_rate = 1.0
var base_damage = 30
var inventory = []
var equipped = {}
var xp = 1


var player_pos = Vector2(0, 0)
onready var rc = get_node("RayCast2D")
onready var health = get_node("Health")
onready var audio_controller = $NPCAudioController

var time_since_attack = 9999

var saw_player = false
var player_visible = false
var last_saw_player = []

onready var tile_map = get_parent().get_node("TileMap")

signal died

func _ready():
	init_npc()
	set_meta("attitude", attitude)
	set_meta("type", "npc")


func init_npc():
	var npc_data = db.get_npc(id)
	if npc_data.has("sounds"):
		audio_controller.init_sounds(npc_data["sounds"])
		#TODO
		health.death_sounds = []
		health.hurt_sounds = []
	npc_name = npc_data["name"]
	attitude = npc_data["attitude"]
	move_speed = npc_data["move_speed"]
	attack_rate = npc_data["attack_rate"] * 1.0
	base_damage = npc_data["base_damage"]
	health.set_max_health(npc_data["health"])
	if npc_data.has("xp"):
		xp = npc_data["xp"]
	inventory = npc_data["inventory"]
	equipped = npc_data["equipped"]
	
	if equipped.has("main hand"):
		var weapon = db.get_item(equipped["main hand"])
		base_damage = weapon["damage"]
		attack_rate = weapon["attack_rate"]
	
	if attitude == "hostile":
		add_to_group("enemies")

func _process(delta):
	audio_controller.muffle(player_visible)

func _draw():
	pass
	#if can_see_player():
		#draw_circle(to_local(last_saw_player), 6, Color(1,0,0))

func _physics_process(delta):
	if attitude != "hostile":
		return
	#if !player_is_in_sight_range():
	#	return
	#seek_and_attack_player(delta)
	#if Input.is_action_just_pressed("ui_accept"):
	t_seek_player(delta)
	
	time_since_attack += delta

var last_pos = null
var cur_dir = Vector2()
func t_seek_player(delta):
	var t_range = 30
	var t_pos = tile_map.world_to_map(global_position)
	var p_pos = tile_map.world_to_map(player_pos)
	
	if !t_in_tile():
		move_and_collide(cur_dir * move_speed * delta)
		return
	
	player_visible = true
	var dir = t_get_dir(t_pos, p_pos)
	
	if dir == null:
		player_visible = false
		if last_pos == null:
			#print("fis")
			return
		else:
			
			dir = t_get_dir(t_pos, last_pos)
			#print("nxt ", dir)
			p_pos = last_pos
			if dir == null:
				return
	
	
	
	if !t_can_see_p(t_pos, p_pos, dir, t_range):
		player_visible = false
		return
	
	rc.cast_to = dir * attack_range
	var hit_som = rc.is_colliding() and rc.get_collider() != null 
	if hit_som:
		var is_player = hit_som and rc.get_collider().has_meta("type") and rc.get_collider().get_meta("type") == "player"
		if is_player:
			attack()
			return
	cur_dir = dir
	last_pos = p_pos
	#if last_pos != null:
		#print(last_pos)
	#print(dir)
	move_and_collide(dir * move_speed * delta)

func t_in_tile():
	var rad = 7
	var pos1 = tile_map.world_to_map(global_position + Vector2(0, rad))
	var pos2 = tile_map.world_to_map(global_position + Vector2(0, -rad))
	var pos3 = tile_map.world_to_map(global_position + Vector2(rad, 0))
	var pos4 = tile_map.world_to_map(global_position + Vector2(-rad, 0))
	
	return pos1 == pos2 and pos2 == pos3 and pos3 == pos4

func t_can_see_p(t_pos, p_pos, dir, iter):
	var i = 0
	
	while i < iter:
		t_pos += dir
		if tile_map.get_cellv(t_pos) >= 0:
			return false
		
		if int(t_pos.x) == int(p_pos.x) and int(t_pos.y) == int(p_pos.y):
			return true
		i += 1
	
	return false

func t_get_dir(t_pos, p_pos):
	var same_col = int(t_pos.y) == int(p_pos.y) 
	var same_row = int(t_pos.x) == int(p_pos.x)
	#print(same_col,same_row)
	# check if on same column or row as player
	if !same_col and !same_row:
		return null
	#print(t_pos, p_pos)
	var dir = Vector2(0, 1) * sign(p_pos.y - t_pos.y)
	if same_col:
		dir = Vector2(1, 0) * sign(p_pos.x - t_pos.x)
	return dir


func seek_and_attack_player(var delta):
	
	if player_is_in_sight_range() and can_see_player():
		if !saw_player:
			saw_player = true
			audio_controller.state = 1
			audio_controller.alert()
		if player_is_in_attack_range():
			attack()
		else:
			move_to_pos(player_pos, delta)
	if !can_see_player() and last_saw_player != []:
		move_to_pos(last_saw_player, delta)

func player_is_in_sight_range():
	var pos = global_position
	var dis = player_pos.distance_squared_to(pos)
	if dis < sight_range * sight_range:
		return true
	return false

func player_is_in_attack_range():
	var pos = global_position
	var dis = player_pos.distance_squared_to(pos)
	if dis < attack_range * attack_range:
		return true
	return false

func move_to_pos(var p_pos, var delta):
	var t_pos = tile_map.world_to_map(p_pos)
	t_pos = tile_map.map_to_world(t_pos) + tile_map.cell_size / 2
	var pos = global_position
	var dir = (t_pos - pos).normalized()
	move_and_collide(dir * move_speed * delta)

func can_see_player():
	var t_pos = tile_map.world_to_map(player_pos)
	t_pos = tile_map.map_to_world(t_pos) + tile_map.cell_size / 2
	
	rc.set_cast_to(t_pos - global_position)
	var se = rc.is_colliding() and rc.get_collider() != null and rc.get_collider().has_meta("type") and rc.get_collider().get_meta("type") == "player"
	if se:
		last_saw_player = t_pos
	return se

func attack():
	if time_since_attack > attack_rate:
		time_since_attack = 0
		audio_controller.attack()
		if rc.is_colliding() and rc.get_collider().has_method("deal_damage"):
			rc.get_collider().deal_damage(base_damage)
	

func update_player_pos(var p_pos):
	player_pos = p_pos

func deal_damage(var dmg):
	audio_controller.hurt()
	if attitude != "hostile":
		attitude = "hostile"
		add_to_group("enemies")
		set_meta("attitude", attitude)
	health.damage(dmg)

func death():
	get_tree().call_group("stats", "increase_exp", xp)
	emit_signal("died")
	queue_free()
