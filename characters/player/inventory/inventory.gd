extends Node2D
onready var lm = get_node("/root/levelmanager")
onready var db = get_node("/root/entity_database")
onready var console = get_node("/root/console")
onready var audio_controller = $AudioController
onready var interactor = get_parent().get_node("Interactor")
onready var combat_manager = get_parent().get_node("CombatManager")
onready var health = get_parent().get_node("Health")
onready var stats_manager = $Stats
var inv_open = false
var clear_on_output = true

enum Tab {PAPER_DOLL, BACKPACK, STATS, JOURNAL}
enum PDoll {WEAPON, BACKUP, CHEST}
enum Stats {STR, CON, DEX, INT}

const tabs = ["PAPER_DOLL", "BACKPACK", "STATS", "JOURNAL"]

var cur_tab = 0
var cur_row = 0

var inv = [
# Paper Doll
[], 
# Backpack
["p_hp_basic_potion"],#"w_fireball", "w_iron_sword", "w_bronze_dagger", "default_item", "a_leather_vest"],
# Stats
["melee", "ranged", "magic", "health", "experience"],
# Journal
[]
]

func _ready():
	for item in inv[Tab.PAPER_DOLL]:
		var it = db.get_item(item)
		if it["type"] == "weapon":
			combat_manager.equip_wep(it)
		if it["type"] == "armor":
			health.equip_armor(item, it["protection"])

func _input(event):
	if (Input.is_action_pressed("exit")):
		lm.return_to_main_menu()
		#TODO: require double to return to main menu
	
	if health.is_dead():
		return
	
	if Input.is_action_just_released("open_close_inventory"):
		inv_open = !inv_open
		open(inv_open)
		get_tree().paused = inv_open
	if !inv_open:
		return
	
	if Input.is_action_just_released("move_left"):
		tab_left()
	elif Input.is_action_just_released("move_right"):
		tab_right()
	elif Input.is_action_just_released("move_forward"):
		row_up()
	elif Input.is_action_just_released("move_backward"):
		row_down()
	elif Input.is_action_just_released("turn_left"):
		drop_item()
	elif Input.is_action_just_released("turn_right"):
		equip_unequip_item()
	
	if Input.is_action_just_released("interact"):
		examine_item()
	
# true: open inventory, false: close it
func open(var b):
	if b:
		console.output("inventory opened")
		#audio_controller.open()
		cur_tab = 1
		cur_row = 0
		output_inv_pos(true, true)
	else:
		console.output("inventory closed")
		audio_controller.close()

func tab_left():
	cur_tab = fposmod((cur_tab - 1), Tab.size())
	cur_row = 0
	output_inv_pos(true, true)

func tab_right():
	cur_tab = fposmod((cur_tab + 1), Tab.size())
	cur_row = 0
	output_inv_pos(true, true)

func row_up():
	cur_row -= 1
	clamp_row()
	output_pos()

func row_down():
	cur_row += 1
	clamp_row()
	output_pos()

func clamp_row():
	var orig_pos = cur_row
	var siz = inv[cur_tab].size()
	if cur_row < 0:
		cur_row += siz
	elif siz > 0:
		cur_row = fposmod(cur_row, siz)
	else:
		cur_row = 0

func get_current_slot_contents():
	if inv[cur_tab].size() > 0:
		return inv[cur_tab][cur_row]
	else:
		return null

#drop item from backpack or paper doll
func drop_item():
	if cur_tab != Tab.PAPER_DOLL and cur_tab != Tab.BACKPACK:
		return
	
	if inv[cur_tab].size() > 0:
		if cur_tab == Tab.PAPER_DOLL:
			var cur_slot = get_current_slot_contents()
			if cur_slot != null and db.get_item(cur_slot)["type"] == "weapon":
				combat_manager.unequip_wep()
		console.output("dropping " + str(inv[cur_tab][cur_row]))
		audio_controller.drop_item(inv[cur_tab][cur_row])
		interactor.drop_item(inv[cur_tab][cur_row])
		inv[cur_tab].remove(cur_row)
		clamp_row()
	else:
		console.output("nothing to drop")

# equip items from inventory or unequip item from paper doll
func equip_unequip_item():
	var cur_slot = get_current_slot_contents()
	if cur_tab == Tab.PAPER_DOLL:
		audio_controller.unequip_item(cur_slot, true)
		unequip_from_p_doll()
		
	elif cur_tab == Tab.BACKPACK:
		audio_controller.equip_item(cur_slot, true)
		equip_from_backpack()
	elif cur_tab == Tab.STATS:
		stats_manager.spend_skill_point(inv[cur_tab][cur_row])
		output_pos()
		audio_controller.play_stat("skill_points")

func unequip_from_p_doll():
	if inv[Tab.PAPER_DOLL].size() == 0:
		return
	var item = inv[Tab.PAPER_DOLL][cur_row]
	if item != "":
		if db.get_item(item)["type"] == "weapon":
			combat_manager.unequip_wep()
		if db.get_item(item)["type"] == "armor":
			health.unequip_armor(item)
		inv[Tab.BACKPACK].push_front(item)
		inv[Tab.PAPER_DOLL].remove(cur_row)
		console.output("unequipped " + item)
	else:
		console.output("nothing to unequip")

# equip item at current ro win backpack to paper doll
# if something is already equipped to the same slot 
# unequip that item and replace it
func equip_from_backpack():
	if inv[Tab.BACKPACK].size() > 0:
		var item_id = inv[Tab.BACKPACK][cur_row]
		equip_item(item_id)
	else:
		console.output("nothing to equip")

func equip_item(var item_id):
	var item_to_eq = db.get_item(item_id)
	var type = item_to_eq["type"]
	if type == "potion" and item_to_eq.has("heals"):
		health.heal(item_to_eq["heals"])
		inv[cur_tab].remove(cur_row)
		clamp_row()
		return
	
	var slot = ""
	if item_to_eq.has("slot"):
		slot = item_to_eq["slot"]
		var outp = ""
		var index = 0
		var item_to_swap = ""
		var swap = false
		for item in inv[Tab.PAPER_DOLL]:
			var cur_item = db.get_item(item)
			if cur_item["type"] == type and cur_item["slot"] == slot:
				if type == "armor":
					health.unequip_armor(item)
				inv[Tab.PAPER_DOLL].erase(item)
				swap = true
				item_to_swap = item
				#inv[BACKPACK].push_front(item)
				#row_down()
				#cur_row += 1
				#clamp_row()
				outp = "unequipped " + item + " : "
				audio_controller.unequip_item(item, false)
				break
			index += 1
		inv[Tab.PAPER_DOLL].push_front(item_id)
		inv[Tab.BACKPACK].remove(cur_row)
		if swap:
			inv[Tab.BACKPACK].insert(cur_row, item_to_swap)
		console.output(outp + "equipped " + item_id)
		
		if type == "weapon":
			combat_manager.equip_wep(item_to_eq)
		if type == "armor":
			health.equip_armor(item_id, item_to_eq["protection"])
	else:
		console.output("cannot equip this")

func pickup_items(var items_list):
	audio_controller.pickup_items(items_list)
	for item in items_list:
		insert_into_backpack(item)

func insert_into_backpack(var item_id):
	inv[Tab.BACKPACK].push_front(item_id)

func output_pos():
	output_inv_pos(true, false)

func output_inv_pos(var clear, var play_tab):
	if clear:
		audio_controller.clear_sound_queue()
	if play_tab:
		audio_controller.play_tab_sound(cur_tab)
	if cur_tab == Tab.BACKPACK or cur_tab == Tab.PAPER_DOLL:
		audio_controller.play_item_stats(get_current_slot_contents())
	if cur_tab == Tab.STATS:
		if play_tab:
			audio_controller.play_stat("skill_points")
		audio_controller.play_stat(inv[cur_tab][cur_row])
	if cur_tab == Tab.JOURNAL and inv[cur_tab].size() > 0:
		audio_controller.play_journal_entry(inv[cur_tab][cur_row])
	var item_str = "empty"
	if inv[cur_tab].size() > 0:
		item_str = str(inv[cur_tab][cur_row]) 
	
	var txt = "Inventory : "
	txt += str(tabs[cur_tab]) + " : "
	txt += item_str
	console.output(txt)

func examine_item():
	output_pos()

#for tests
func clear():
	inv[Tab.BACKPACK] = []
	inv[Tab.PAPER_DOLL] = []

func get_contents_of_backpack():
	return inv[Tab.BACKPACK]

func get_contents_of_p_doll():
	return inv[Tab.PAPER_DOLL]

func add_entry_to_journal(path):
	inv[Tab.JOURNAL].push_front(path)
	pass

#for loading and saving from/to file
func save_to_dict():
	return {
		"cur_health":health.cur_health,
		"equipment": inv[Tab.PAPER_DOLL], 
		"backpack":inv[Tab.BACKPACK],
		"stats":stats_manager.save_to_dict(),
		"journal":inv[Tab.JOURNAL]}

func load_from_dict(var dict):
	inv[Tab.JOURNAL] = dict["journal"]
	inv[Tab.BACKPACK] = dict["backpack"]
	stats_manager.load_from_dict(dict["stats"])
	for item in dict["equipment"]:
		var it = db.get_item(item)
		if it["type"] == "weapon":
			combat_manager.equip_wep(it)
		if it["type"] == "armor":
			health.equip_armor(item, it["protection"])
	inv[Tab.PAPER_DOLL] = dict["equipment"]
	health.cur_health = dict["cur_health"]
