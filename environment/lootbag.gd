extends Area2D


export(String) var content1
export(String) var content2
export(String) var content3

signal opened

var contents = null
func _ready():
	contents = []
	set_meta("type", "loot")
	if content1 != null:
		contents.push_front(content1)
	if content2 != null:
		contents.push_front(content2)
	if content3 != null:
		contents.push_front(content3)
	#print(contents)
	

func set_contents(var new_contents):
	contents = new_contents

func pick_up():
	queue_free()
	emit_signal("opened")
	return contents

func add_item(var item_id):
	contents.push_front(item_id)
