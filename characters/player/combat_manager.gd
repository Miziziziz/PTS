extends RayCast2D

onready var audio_player = $AudioStreamPlayer
onready var stats_manager = get_parent().get_node("Inventory/Stats")
var explosion = preload("res://utility/explosion.tscn")

var fist_dmg = 10
var fist_speed = 0.4
var fist_hit_snd = "res://audio/weapons/punch.wav"
var fist_swing_snd = "res://audio/weapons/punch.wav"

var damage = fist_dmg
var atk_rate = fist_speed
var atk_radius = 0

var prep_sound = null
var atk_sound = fist_swing_snd
var atk_hit_sound = fist_hit_snd
var prep_sound_time = 0
var ranged = false
var attack_type = "melee"

var played_prep = false

var time_since_atk = 0

signal attacked

func _process(delta):
	if Input.is_action_pressed("attack"):
		if prep_sound != null and !played_prep and !audio_player.is_playing():
			audio_player.stream = prep_sound
			audio_player.play()
			played_prep = true
		time_since_atk += delta
		attempt_attack()
		emit_signal("attacked")
	else:
		if prep_sound != null and audio_player.stream == prep_sound:
			audio_player.stop()
		played_prep = false
		time_since_atk = 0
		
	"""
	if prep_sound != "" and !audio_player.playing and !played_prep:
		audio_player.stream = load(prep_sound)
		played_prep = true
		audio_player.play()
	"""

func unequip_wep():
	damage = fist_dmg
	atk_rate = fist_speed
	prep_sound = null
	atk_sound = fist_swing_snd
	atk_hit_sound = fist_hit_snd
	ranged = false
	attack_type = "melee"
	prep_sound_time = 0

#pass dictionary from database
func equip_wep(var item_to_eq):
	
	damage = item_to_eq["damage"]
	atk_rate = item_to_eq["attack_rate"] / 10.0
	atk_sound = item_to_eq["sounds"]["swing"]
	atk_hit_sound = item_to_eq["sounds"]["hit"]
	if item_to_eq["sounds"]["prep"] == "":
		prep_sound = null
	else:
		prep_sound = load(item_to_eq["sounds"]["prep"])
	attack_type = item_to_eq["attack_type"]
	ranged = attack_type == "range" or attack_type == "magic"
	if attack_type == "range":
		damage += stats_manager.stats["ranged"]
	elif attack_type == "melee":
		damage += stats_manager.stats["melee"] 
	elif attack_type == "magic":
		damage += stats_manager.stats["magic"] 
		atk_radius = item_to_eq["attack_radius"]
	


func attempt_attack():
	if time_since_atk >= atk_rate:
		played_prep = false
		time_since_atk -= atk_rate
		var snd_to_play = atk_sound
		var coll = get_collider()
		var hit_pnt = get_collision_point()
		if is_colliding():
			var rn = global_position.distance_squared_to(hit_pnt)
			if ranged or rn < 32 * 32:
				if attack_type == "magic":
					var spell_pos = hit_pnt
					if coll.has_method("deal_damage"):
						spell_pos = coll.global_position
					cast_spell(spell_pos)
				elif coll.has_method("deal_damage"):
					coll.deal_damage(damage)
					snd_to_play = atk_hit_sound
		audio_player.stream = load(snd_to_play)
		audio_player.play()
		played_prep = false
		

func cast_spell(var pos):
	var spell = explosion.instance()
	get_tree().get_root().add_child(spell)
	spell.init_expl(damage, atk_radius, pos)
