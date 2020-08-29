extends Control

onready var lm = get_node("/root/levelmanager")
onready var audio_player = $AudioStreamPlayer
const SAVE_PATH = "user://savegame.save"

const AUDIO_PATH = "res://audio/main_menu/"

var menu_stream = "menu_intro.wav"
var confirm_stream = "confirm_new_game.wav"
var controls_stream = "menu_controls.wav"
var credits_stream = "credits.wav"

var rq_confirm = false

func _ready():
	A3dView.disable_3d_view()
	get_tree().paused = false
	reset_audio_pl()

func _process(delta):
	if !audio_player.playing:
		reset_audio_pl()

func reset_audio_pl():
	audio_player.stream = load(AUDIO_PATH + menu_stream)
	audio_player.play()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_1:
			new_game()
		if event.scancode == KEY_2:
			load_game()
		if event.scancode == KEY_3:
			play_controls()
		if event.scancode == KEY_4:
			play_credits()
		if event.scancode == KEY_ENTER and rq_confirm:
			new_game_erase_old()
		if event.scancode == KEY_ESCAPE:
			exit()

func new_game():
	var save_game = File.new()
	
	if save_game.file_exists(SAVE_PATH):
		rq_confirm = true
		audio_player.stream = load(AUDIO_PATH + confirm_stream)
		audio_player.play()
		return
	lm.load_level(0)

func new_game_erase_old():
	var dir = Directory.new()
	dir.remove(SAVE_PATH)
	lm.load_level(0)

func load_game():
	var save_game = File.new()
	if not save_game.file_exists(SAVE_PATH):
		lm.load_level(0)
		return
	
	save_game.open(SAVE_PATH, File.READ)
	var lvl = save_game.get_line()
	lm.load_level(lvl)
	save_game.close()

func play_controls():
	audio_player.stream = load(AUDIO_PATH + controls_stream)
	audio_player.play()

func play_credits():
	audio_player.stream = load(AUDIO_PATH + credits_stream)
	audio_player.play()

func exit():
	get_tree().quit()
