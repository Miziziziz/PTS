extends Area2D
#script controls interacting with objects in the world,
# e.g. levers and lootbags, also dropping items into loot bags
onready var inventory = get_parent().get_node("Inventory")
onready var raycaster = $RayCast2D

var lootbag_scene = preload("res://environment/lootbag.tscn")

var process_input = true
#TODO raycast to nearby objects before interact, or just make 
# interact radius smaller than walls

func attempt_interact():
	if !process_input:
		return
	"""
	var nearby_objects = get_overlapping_areas()
	if nearby_objects.size() == 0:
		return
	var nearest_interactable_obj = nearby_objects[0]
	
	var pos = global_position
	var min_dist = 99999
	for object in nearby_objects:
		var obj_pos = object.global_position
		var dis = pos.distance_squared_to(obj_pos)
		if dis < min_dist:
			nearest_interactable_obj = object

	if nearest_interactable_obj.has_method("pick_up"):
		inventory.pickup_items(nearest_interactable_obj.pick_up())
	"""
	var nearby_objects = get_overlapping_areas()
	for coll in nearby_objects:
		if coll.has_method("pick_up"):
			inventory.pickup_items(coll.pick_up())
			return
		elif coll.has_method("use"):
			coll.use()
			return
	if raycaster.is_colliding():
		var coll = raycaster.get_collider()
		if coll.has_method("pick_up"):
			inventory.pickup_items(coll.pick_up())
		elif coll.has_method("use"):
			coll.use()

#if there's a nearby lootbag, drop item into it,
# otherwise make a new bag
func drop_item(var item_id):
	if get_tree().is_paused():
		get_tree().paused = false
		yield(get_tree(), "idle_frame")
		get_tree().paused = true
	
	var nearby_objects = get_overlapping_areas()
	for object in nearby_objects:
		if object.has_method("add_item"):
			object.add_item(item_id)
			return
	var new_bag = lootbag_scene.instance()
	get_tree().get_root().add_child(new_bag)
	new_bag.global_position = global_position
	new_bag.set_contents([item_id])


