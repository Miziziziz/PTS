extends Node2D

#plays sequence of notes, requires that sequence 
#to be entered to complete

onready var music_player = $MusicPlayer
onready var note_player = $NotePlayer

export var music_seq_ind = 0
var music_seqs = [
	[0, 1, 2],
	[0, 2, 1],
	[0, 2, 2]
] 
var correct_music_comb = []
var cur_music_comb = []

const audio_path = "res://puzzles/music_puzzle/"
var loud_notes_list = [
	audio_path + "chime_d3.wav",
	audio_path + "chime_g3.wav",
	audio_path + "chime_b3.wav"
]
var quiet_notes_list = [
	audio_path + "quiet_chime_d3.wav",
	audio_path + "quiet_chime_g3.wav",
	audio_path + "quiet_chime_b3.wav"
]

var solved = false

var cur_note_id = 0
var time_since_last_played = 0
const note_play_rate = 4.0

signal completed

func _ready():
	correct_music_comb = music_seqs[music_seq_ind]
	for child in get_children():
		if child.get_signal_list()[0]["name"] == "activated":
			child.connect("activated", self, "add_note")

func add_note(id):
	if solved:
		return
	
	music_player.stop()
	time_since_last_played = 0
	play_note(note_player, loud_notes_list, id)
	
	cur_music_comb.push_back(id)
	if cur_music_comb.size() > correct_music_comb.size():
		cur_music_comb.pop_front()
	if cur_music_comb == correct_music_comb:
		print ("correct")
		solved = true
		emit_signal("completed")

func play_note(var player, var notes_list, var id):
	if id >= notes_list.size():
		return
	player.stream = load(notes_list[id])
	player.play()

func _process(delta):
	if solved:
		music_player.stop()
		set_process(false)
		return
	
	if time_since_last_played >= note_play_rate:
		play_note(music_player, quiet_notes_list, correct_music_comb[cur_note_id])
		cur_note_id += 1
		if cur_note_id >= correct_music_comb.size():
			cur_note_id = 0
			#cur_wait_time = time_between_playing
		time_since_last_played -= note_play_rate
		
		
	
	time_since_last_played += delta
