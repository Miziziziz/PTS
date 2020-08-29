extends AudioStreamPlayer2D

enum states {IDLE, CHASE}
var state = 0

var reg_vol = 1
var muffled_vol = -30

var sounds = {
	"idle":[],
	"chase":[],
	"hurt":[],
	"attack":[],
	"alert":[]
}

var idle_play_rate = 2.0
var time_since_last_play = 0

func _process(delta):
	time_since_last_play += delta
	if time_since_last_play > idle_play_rate:
		time_since_last_play -= idle_play_rate
		if state == states.IDLE:
			play_rnd_sound(sounds["idle"])
		elif state == states.CHASE:
			play_rnd_sound(sounds["chase"])

func alert():
	play_rnd_sound(sounds["alert"])
	
func hurt():
	play_rnd_sound(sounds["hurt"])

func attack():
	play_rnd_sound(sounds["attack"])

func play_rnd_sound(var list):
	if list.size() <= 0:
		return
	var index = randi() % list.size()
	stream = load(list[index])
	time_since_last_play = 0
	play()

func init_sounds(var sound_dict):
	var dir_path = sound_dict["direct_path"]
	
	for key in sound_dict.keys():
		if key == "path" or key == "direct_path":
			continue
		var new_sound = sound_dict["path"]
		new_sound += "_" + key
		if dir_path:
			
			sounds[key].append(sound_dict["path"] + sound_dict[key] + ".wav")
		else:
			for i in sound_dict[key]:
				var tmp = new_sound + str(i) + ".wav"
				sounds[key].append(tmp)


func muffle(var b):
	
	if b:
		volume_db = reg_vol
		attenuation = 1
	else:
		volume_db = muffled_vol
		attenuation = 2
