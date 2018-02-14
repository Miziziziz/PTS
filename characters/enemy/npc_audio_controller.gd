extends AudioStreamPlayer

enum states {IDLE, CHASE}
var state = 0

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
		if state == IDLE:
			play_rnd_sound(sounds["idle"])
		elif state == CHASE:
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
	for key in sound_dict.keys():
		if key == "path":
			continue
		var new_sound = sound_dict["path"]
		new_sound += "_" + key
		for i in sound_dict[key]:
			var tmp = new_sound + str(i) + ".wav"
			sounds[key].append(tmp)
			#print(tmp)