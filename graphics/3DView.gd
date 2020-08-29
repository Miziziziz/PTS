extends Spatial

var zombie_obj = preload("res://graphics/instanced/Zombie.tscn")
var boss_obj = preload("res://graphics/instanced/Boss.tscn")
var chest_obj = preload("res://graphics/instanced/Chest.tscn")
var stone_gate_obj = preload("res://graphics/instanced/StoneGate.tscn")
var pressure_plate_obj = preload("res://graphics/instanced/PressurePlate.tscn")

func init_gridmap(tilemap: TileMap):
	$GridMap.clear()
	for cell_pos in tilemap.get_used_cells():
		$GridMap.set_cell_item(cell_pos.x, 0, cell_pos.y, 0)

var enemies_list = []
func init_enemies():
	enemies_list = get_tree().get_nodes_in_group("enemies")
	var ind = 0
	for enemy in enemies_list:
		var e = null
		if enemy.id == "h_zombie":
			e = instance_at_pos(zombie_obj, enemy.global_position)
		#elif enemy.id == "h_large_zombie":
		else:
			e = instance_at_pos(boss_obj, enemy.global_position)
		enemy.connect("died", e, "hide")
		enemy_instances[ind] = {"2d": enemy, "3d":e}
		ind += 1
		

var instances=[]
var enemy_instances={}
func instance_at_pos(obj, pos: Vector2):
	var obj_inst : Sprite3D = obj.instance()
	add_child(obj_inst)
	instances.append(obj_inst)
	obj_inst.global_transform.origin = pos_to_3d_pos(pos)
	return obj_inst

var player = null
func _process(_delta):
	if is_instance_valid(player):
		update_cam(player.global_position, player.global_rotation)
		if player.get_node("CombatManager").ranged:
			$Camera/Hand/AnimatedBase/Bow.show()
			$Camera/Hand/AnimatedBase/Sword.hide()
		else:
			$Camera/Hand/AnimatedBase/Bow.hide()
			$Camera/Hand/AnimatedBase/Sword.show()
	var ind = 0
	for i in enemy_instances:
		var enemy_2d = enemy_instances[i]["2d"]
		var enemy_3d = enemy_instances[i]["3d"]
		if is_instance_valid(enemy_2d):
			enemy_3d.global_transform.origin = pos_to_3d_pos(enemy_2d.global_position)

func pos_to_3d_pos(pos):
	return Vector3(pos.x / 16, 0, pos.y / 16)

func update_cam(pos: Vector2, r: float):
	$Camera.rotation.y = -(r+PI)
	$Camera.global_transform.origin = pos_to_3d_pos(pos) + Vector3.UP * .5

func enable_3d_view():
	show()
	$GridMap.show()
	set_process(true)
	
	init_enemies()
	for stonegate in get_tree().get_nodes_in_group("stonegates"):
		var st = instance_at_pos(stone_gate_obj, stonegate.global_position)
		stonegate.connect("opened", st, "hide")
		stonegate.connect("closed", st, "show")
	for pressureplate in get_tree().get_nodes_in_group("pressureplates"):
		instance_at_pos(pressure_plate_obj, pressureplate.global_position)
	for chest in get_tree().get_nodes_in_group("chests"):
		var c = instance_at_pos(chest_obj, chest.global_position)
		chest.connect("opened", c, "hide")
	
	var ladders = get_tree().get_nodes_in_group("ladders")
	if ladders.size()>0:
		$Ladder.global_transform.origin = pos_to_3d_pos(ladders[0].global_position)
	var tilemaps = get_tree().get_nodes_in_group("tilemaps")
	if tilemaps.size()>0:
		init_gridmap(tilemaps[0])
		tilemaps[0].hide()
	var _player = get_tree().get_nodes_in_group("player")
	if _player.size()>0:
		player = _player[0]
		player.get_node("CombatManager").connect("attacked", self, "play_attack_anim")

func disable_3d_view():
	hide()
	$GridMap.hide()
	set_process(false)
	for instance in instances:
		if is_instance_valid(instance):
			instance.queue_free()
	instances=[]
	player = null

func play_attack_anim():
	var anim_speed = 1 / player.get_node("CombatManager").atk_rate
	$Camera/Hand/AnimationPlayer.play("attack", 0, anim_speed)
