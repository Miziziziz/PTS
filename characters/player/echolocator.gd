extends Node2D

const PIXELS_PER_METER = 16
const MIN_CLICK_RATE = 0.2 #per second
const MAX_CLICK_RATE = 0.4 
const MAX_DISTANCE = 30 # meters

const MIN_PITCH = 1
const PITCH_DIFF_PER_TIER = 1.5

onready var ping_ray = get_node("RayCast2D")
onready var loot_ray = $RayCastLoot
onready var click_player = get_node("ClickPlayer")

const DIS_PER_TIER = [2, 8, MAX_DISTANCE]

var audio_folder = "res://audio/player/echolocation/"

var click_sounds = ["aa", "ee", "oo"]
var npc_sound = "f"
var enemy_sound = "n"
var loot_sound = "l"
var int_sound = "k"
var alternate = false

signal click

#true if pointing at an npc or interactable
var looking_at_something = false

var time_since_last_click = 0

func _ready():
	var player = get_parent()
	ping_ray.add_exception(player)
	
	ping_ray.set_cast_to(Vector2(0, MAX_DISTANCE * PIXELS_PER_METER))
# send and play echolocation pings
# delta: time since last frame
func echolocate(var delta):
	"""
	var distance = calc_distance(ping_ray)
	var distance2 = calc_distance(loot_ray)
	var ray = ping_ray
	if distance2 < distance:
		distance = distance2
		ray = loot_ray
	"""
	var ray = pick_ray()
	var distance = calc_distance(ray)
	
	var tier = calc_dis_tier(distance)
	var click_rate = calc_click_rate(distance, tier)
	time_since_last_click += delta
	if time_since_last_click >= click_rate:
		time_since_last_click -= click_rate
		play_click(tier, ray)
		tap_hit_obj()

func perform_echolocate():
	var ray = pick_ray()
	var distance = calc_distance(ray)
	var tier = calc_dis_tier(distance)
	play_click(tier, ray)
	tap_hit_obj()

func pick_ray():
	var ray = ping_ray
	return ray
	"""
	var dist = calc_distance(ray)
	var rays = [loot_ray] # ping_ray_l, ping_ray_r, 
	for r in rays:
		var d = calc_distance(r)
		if (d < dist):
			ray = r
			dist = d
	return ray
	"""

# calculate distance from player to where raycast hits
func calc_distance(var ray):
	var distance = -1
	var start_pos = global_position
	var end_point = ray.get_collision_point()
	if (ray.is_colliding()):
		distance = (end_point - start_pos).length()
	if distance < 0:
		return MAX_DISTANCE
	return distance / PIXELS_PER_METER

# calculate the tier of the distance
func calc_dis_tier(var distance):
	var size = DIS_PER_TIER.size()
	var tier = size - 1
	for i in range(size):
		if distance  < DIS_PER_TIER[i]:
			return i
	return tier

# calculate how fast to click
# faster when closer to a lower tier
# slower when closer to a higher tier
func calc_click_rate(var distance, var tier):
	var first_dist = 0
	var sec_dist = DIS_PER_TIER[tier]
	if tier != 0:
		first_dist = DIS_PER_TIER[tier - 1]
	var t = (distance - first_dist) / (sec_dist - first_dist)
	return lerp(MIN_CLICK_RATE, MAX_CLICK_RATE, t)

func _process(delta):
	looking_at_something = false
	if ping_ray.is_colliding():
		var coll = ping_ray.get_collider()
		if coll != null and coll.has_meta("type"):
			looking_at_something = true

var hit_point = Vector2()
func play_click(var tier, var ray: RayCast2D):
	"""
	if is_loot_in_front_of_enemy():
		alternate = !alternate
		if alternate:
			ray = ping_ray
		else:
			ray = loot_ray
	"""
	tier = calc_dis_tier(calc_distance(ray))
	var sound = click_sounds[tier]
	if ray.is_colliding():
		hit_point = ray.position
		var hit_obj = ray.get_collider()
		if hit_obj.has_meta("type"):
			var type = hit_obj.get_meta("type")
			print(type)
			var att = ""
			if hit_obj.has_meta("attitude"):
				att = hit_obj.get_meta("attitude")
			if type == "npc" and att == "friendly":
				sound = npc_sound + sound
			elif type == "npc" and att == "hostile":
				sound = enemy_sound + sound
			elif type == "interactable":
				sound = int_sound + sound
			elif type == "loot":
				sound = loot_sound + sound
	
	emit_signal("click", sound)
	click_player.stop()
	var path = audio_folder + sound + ".wav"
	click_player.stream = load(path)
	click_player.play()

# since loot can be walked over, I want to be able to alternate
# enemy and loot sounds
func is_loot_in_front_of_enemy():
	var distance1 = calc_distance(ping_ray)
	var distance2 = calc_distance(loot_ray)
	
	if distance1 < distance2:
		return false
	
	if ping_ray.is_colliding() and loot_ray.is_colliding():
		var hit_obj1 = ping_ray.get_collider()
		var hit_obj2 = loot_ray.get_collider()
		if hit_obj1.has_meta("type") and hit_obj2.has_meta("type"):
			var type1 = hit_obj1.get_meta("type")
			var type2 = hit_obj2.get_meta("type")
			var att = ""
			if hit_obj1.has_meta("attitude"):
				att = hit_obj1.get_meta("attitude")
			
			if att == "hostile" and type1 == "npc" and type2 == "loot":
				return true
	return false

# some objects react to being echolocated at, e.g. chimes or gongs
func tap_hit_obj():
	if (ping_ray.is_colliding()):
		var hit_obj = ping_ray.get_collider()
		if hit_obj.has_method("tap"):
			hit_obj.tap()
		#if hit_obj.is_in_group("enemies"):
			#print("enemy")
