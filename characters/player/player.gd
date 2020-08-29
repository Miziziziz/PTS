extends KinematicBody2D

onready var lm = get_node("/root/levelmanager")
const SAVE_PATH = "user://savegame.save"

onready var echolocator = get_node("Echolocator")
onready var mover = get_node("Mover")
onready var rotator = get_node("Rotator")
onready var health = get_node("Health")
onready var inventory = get_node("Inventory")
onready var interactor = get_node("Interactor")
onready var combat_manager = get_node("CombatManager")

var turning = false
var inventory_open = false

const KEYBOARD_TURN_SPEED = 3
var rot_speed = 0.03
var mouse_sens = 0.1

func _ready():
	mover.kine_body = self
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_meta("type", "player")
	
	var t_map = get_parent().get_node("TileMap")
	mover.tile_map = t_map
	
	load_char()
	A3dView.enable_3d_view()


func _input(ev):
	if ev.is_action_pressed("interact"):
		interactor.attempt_interact()
	
	if ev is InputEventMouseMotion:
		var r = ev.relative.x * mouse_sens
		rotator.rotate_body(self, r, !Input.is_action_pressed("align"))

func _process(delta):
	turning = false
	if health.is_dead():
		get_tree().reload_current_scene()
		return
	#read out digits of player health
	if Input.is_action_just_pressed("health_read"):
		var hlth_num = health.cur_health
		inventory.get_node("AudioController").play_number(hlth_num)
	if Input.is_action_just_pressed("prot_read"):
		var prot_num = health.protection
		inventory.get_node("AudioController").play_number(prot_num)
	
	if inventory_open:
		return
	
	var align = !Input.is_action_pressed("align")
	var r = 0
	if (Input.is_action_pressed("turn_right")):
		r += KEYBOARD_TURN_SPEED
	if (Input.is_action_pressed("turn_left")):
		r += -KEYBOARD_TURN_SPEED
	rotator.rotate_body(self, r, align)
	
	if align and Input.is_action_just_pressed("turn_right"):
		rotator.snap_turn(self, 1)
	if align and Input.is_action_just_pressed("turn_left"):
		rotator.snap_turn(self, -1)
	
	if (Input.is_action_pressed("ping")):
		echolocator.echolocate(delta)

	

func _physics_process(delta):
	if inventory_open or health.is_dead():
		return
	
	var move_vec = Vector2(0,0)
	if (Input.is_action_pressed("move_forward")):
		move_vec.y += 1
	if (Input.is_action_pressed("move_backward")):
		move_vec.y += -1
	if (Input.is_action_pressed("move_right")):
		move_vec.x += -1
	if (Input.is_action_pressed("move_left")):
		move_vec.x += 1
	
	#mover.move_body(self, move_vec, delta)
	mover.dir_vector = move_vec
	

func deal_damage(var dmg):
	health.damage(dmg)

func add_entry_to_journal(path):
	inventory.add_entry_to_journal(path)

func save_char():
	var save_game = File.new()
	
	save_game.open(SAVE_PATH, File.WRITE)
	save_game.store_line(lm.get_cur_scene_name())
	var dict = inventory.save_to_dict()
	save_game.store_line(to_json(dict))
	save_game.close()


func load_char():
	var save_game = File.new()
	if not save_game.file_exists(SAVE_PATH):
		return
	save_game.open(SAVE_PATH, File.READ)
	save_game.get_line()
	var dict = parse_json(save_game.get_line())
	inventory.load_from_dict(dict)
	save_game.close()
