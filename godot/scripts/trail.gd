# Area: Goblin Woods Trail (between Camp and the Goblin Village, Asar's idea). A long forest trail in the early morning:
# searchable loot spots for gold, a creek with a bridge, and Asar's Bridge Troll by his hut.
#   "It's good" → Xylo follows him into his hut, comes back, the bridge is open.
#   "Bad."      → fight (lots of gold), then loot his hut and his chest for more.
# Walk north to reach the village (first time: the village story starts). The south end leads back to camp.
extends Level

const TS = preload("res://scripts/trail_script.gd")
const START := Vector3(0, 0, 50)
const END_Z := -54.0
const BRIDGE := Vector3(0, 0, 0)          # creek runs east-west across the trail here
const TROLL_SPOT := Vector3(0.3, 0, 3.6)  # he stands at the south end of the bridge
const HUT := Vector3(7.5, 0, -6.5)
const HUT_DOOR := Vector3(5.6, 0, -5.3)
const CHEST_POS := Vector3(5.1, 0, -4.9)
# searchable spots: [kind, position, gold, item]
const LOOT := [
	["bush", Vector3(6.4, 0, 40.0), 8, ""],
	["log", Vector3(-7.0, 0, 27.0), 10, "beer"],
	["stump", Vector3(7.2, 0, 13.0), 6, ""],
	["bush", Vector3(-6.2, 0, -17.0), 12, ""],
	["rocks", Vector3(7.8, 0, -31.0), 9, "bowl"],
	["bush", Vector3(-6.6, 0, -44.0), 7, ""],
]

var stage := "walk"         # walk (free roam) / troll (his scene) / end
var troll: Unit
var blocker: StaticBody3D   # keeps you off the bridge until the troll is dealt with
var loot_nodes := []
var hut_sign: Node3D
var chest_node: Node3D

func _configure() -> void:
	if not Game.title_mode:
		Game.set_flag("campDone")
	night = false
	light_dir = Vector3(0.6, 0.3, -0.75)   # low morning sun
	clear_center = Vector2(0, 0)
	clear_radius = 3.5
	path_pts = PackedVector2Array([Vector2(0, 60), Vector2(4, 45), Vector2(-3, 31), Vector2(3, 17), Vector2(0, 6), Vector2(0, -3),
		Vector2(-1.5, -13), Vector2(-5, -24), Vector2(2, -36), Vector2(-1, -48), Vector2(0, -60)])
	path_width = 1.7
	bounds = Rect2(-15, -60, 30, 120)
	subtitle = "Scene 1.5 — Goblin Woods Trail"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [START, START + Vector3(-1, 0, 1.6), START + Vector3(1, 0, 1.6)]
	leader_id = "skorn"
	cam_locked = true
	zoom = 10.5
	cam_height = 0.36
	cam_look_h = 1.6
	checkpoint = BRIDGE + Vector3(0, 0, 8)
	talk = {
		"lykor": [{ "who": "lykor", "mood": "smug", "line": "Long walk. Good thing I look this good doing it." }], # DRAFT
		"xylo": [{ "who": "xylo", "line": "Deloye Lore warns of a troll on this trail. It is not specific about what he wants." }], # DRAFT
	}

func _build_level() -> void:
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 1522
	# forest walls: tree cards both sides of the trail, some real trunks and rocks between them
	for k in 110:
		var z := rng2.randf_range(-60, 60)
		var side := -1.0 if k % 2 == 0 else 1.0
		var x := side * rng2.randf_range(9.0, 15.0)
		if abs(z - BRIDGE.z) < 2.5:
			continue
		card("tree_%d" % (1 + k % 4), rng2.randf_range(8.0, 12.0), Vector3(x, 0, z), rng2.randf() < 0.5, true, 0.6)
	for x in range(-14, 15, 4):   # close off both ends
		for zz in [-63.0, 63.0]:
			card("tree_%d" % (1 + abs(x) % 4), rng2.randf_range(9.0, 12.0), Vector3(x + rng2.randf_range(-1, 1), 0, zz), rng2.randf() < 0.5, true, 0.6)
	for k in 26:
		var z := rng2.randf_range(-58, 58)
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng2.randf_range(5.0, 9.0), 0, z)
		if abs(z - BRIDGE.z) < 3.0 or (p.distance_to(HUT) < 4.0):
			continue
		match k % 4:
			0: card("bush_%d" % (1 + k % 3), rng2.randf_range(1.2, 1.8), p, rng2.randf() < 0.5)
			1: Models.place(self, "rock_07", p, rng2.randf() * TAU, rng2.randf_range(2.5, 4.0), true, Color(0.75, 0.72, 0.68))
			2: Models.place(self, "fern_02", p, rng2.randf() * TAU, rng2.randf_range(1.0, 1.5))
			_: Models.place(self, "dead_tree_trunk", p, rng2.randf() * TAU, rng2.randf_range(0.6, 0.9), true)
	# the creek and the bridge
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.16, 0.3, 0.34, 0.92)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.08
	water.metallic = 0.25
	water.emission_enabled = true
	water.emission = Color(0.04, 0.09, 0.11)
	var wm := PlaneMesh.new()
	wm.size = Vector2(40, 3.6)
	Util.add_mesh(self, wm, water, BRIDGE + Vector3(0, 0.03, 0))
	Models.patch(self, BRIDGE, Vector2(40, 5.4), "dark_rock", 2.0, Color(0.55, 0.48, 0.38), 0.0, 0.5)
	Util.static_box(self, Vector3(-9.0, 1, BRIDGE.z), Vector3(15.4, 2, 3.4))
	Util.static_box(self, Vector3(9.0, 1, BRIDGE.z), Vector3(15.4, 2, 3.4))
	var planks := Models.mat("weathered_planks", 1.0, Color(0.9, 0.78, 0.62))
	Models.block(self, BRIDGE + Vector3(0, 0.18, 0), Vector3(2.4, 0.14, 5.2), planks)
	for s in [-1.25, 1.25]:
		Models.block(self, BRIDGE + Vector3(s, 0.75, 0), Vector3(0.12, 0.12, 5.2), planks)
		for z in [-2.4, 0.0, 2.4]:
			Models.block(self, BRIDGE + Vector3(s, 0.45, z), Vector3(0.14, 0.9, 0.14), planks)
	# the troll's hut (log walls, scruffy thatch), his chest just inside the door
	var logs := Models.mat("wood_trunk_wall", 2.0, Color(0.7, 0.65, 0.58))
	Models.cylinder(self, HUT, 2.2, 2.2, 2.3, logs, 14)
	Models.cylinder(self, HUT + Vector3(0, 2.3, 0), 2.8, 0.15, 1.9, Models.mat("thatch_roof_angled", 1.2, Color(0.8, 0.72, 0.55)), 14)
	Util.static_cyl(self, HUT, 2.3, 2.5)
	var dir := (HUT_DOOR - HUT).normalized()
	Models.block(self, HUT + dir * 2.18 + Vector3(0, 0.9, 0), Vector3(1.1, 1.8, 0.06), Models.mat("weathered_planks", 0.8, Color(0.35, 0.28, 0.2)), atan2(dir.x, dir.z))
	Models.place(self, "wooden_bucket_02", HUT_DOOR + Vector3(0.9, 0, 0.9), 0.0, 1.0)
	Models.place(self, "dry_branches_medium_01", HUT + Vector3(-2.6, 0, 1.4), 0.0, 1.0)
	chest_node = Models.place(self, "treasure_chest", CHEST_POS, atan2(dir.x, dir.z), 0.7)
	wood_sign("sign_trail_village", "GOBLIN VILLAGE\n(NO TROLLS)", Vector3(2.6, 1.3, -50.0), 0.0, 1.6, 0.6, true)
	wood_sign("sign_trail_camp", "BACK TO CAMP", Vector3(-2.8, 1.2, 46.0), 0.25, 1.4, 0.4, true)
	# loot spots, each with a little sparkle until it's searched
	for i in LOOT.size():
		var L: Array = LOOT[i]
		var n: Node3D
		match L[0]:
			"bush": card("bush_big", 1.7, L[1])
			"log": Models.place(self, "dead_tree_trunk_02", L[1], 0.7, 0.55, true)
			"stump": Models.place(self, "tree_stump_01", L[1], 0.0, 1.0, true)
			"rocks":
				for r in 3:
					Models.place(self, "rock_09", L[1] + Vector3(r * 0.6 - 0.6, 0, (r % 2) * 0.5), r * 1.7, 2.2, false, Color(0.72, 0.68, 0.62))
		n = _sparkle(L[1] + Vector3(0, 0.9, 0))
		loot_nodes.append(n)
	# the troll + what blocks the bridge
	troll = spawn_npc("troll", "Bridge Troll", "troll", 2.2, TROLL_SPOT)
	blocker = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 2.0, 0.6)
	cs.shape = bs
	blocker.add_child(cs)
	add_child(blocker)
	blocker.global_position = BRIDGE + Vector3(0, 1.0, 2.3)

# morning light: warm low sun, soft mist
func _after_build() -> void:
	var env: Environment = world_env.environment
	env.fog_light_color = Color(0.78, 0.8, 0.78)
	env.fog_density = 0.0045
	env.volumetric_fog_density = 0.002
	env.fog_aerial_perspective = 0.35
	sun_light.light_color = Color(1.0, 0.86, 0.68)
	sun_light.light_energy = 1.3
	_apply_state()

func _sparkle(p: Vector3) -> Node3D:
	var sp := CPUParticles3D.new()
	sp.amount = 6
	sp.lifetime = 1.2
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.35
	sp.gravity = Vector3(0, 0.3, 0)
	sp.initial_velocity_min = 0.05
	sp.initial_velocity_max = 0.2
	var qm := QuadMesh.new()
	qm.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.9, 0.4)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.material = m
	sp.mesh = qm
	add_child(sp)
	sp.global_position = p
	return sp

# troll / hut / loot state from flags (also used when you come back or load a save)
func _apply_state() -> void:
	var t: String = str(Game.flags.get("trollDone", ""))
	if t != "":
		if is_instance_valid(blocker):
			blocker.queue_free()
	if t == "good":
		troll.visible = false
		if hut_sign == null:
			hut_sign = wood_sign("sign_troll_hut", "DO NOT DISTURB", HUT_DOOR + Vector3(0, 2.0, 0.15) + (HUT_DOOR - HUT).normalized() * 0.1, atan2((HUT_DOOR - HUT).x, (HUT_DOOR - HUT).z), 1.1, 0.34)
	elif t == "bad":
		troll.global_position = TROLL_SPOT + Vector3(-2.2, 0, 1.0)
		knock(troll, 90.0, 0.01)
	if Game.flag("trollChest") and chest_node:
		chest_node.rotation.x = 0.0
	for i in LOOT.size():
		if Game.flag("trailLoot%d" % i):
			loot_nodes[i].visible = false

# ---------------------------------------------------------------- story
func _begin() -> void:
	Game.set_flag("trailStarted")
	busy = true
	fade_in(1.2)
	await wait(0.8)
	await run_dialogue(TS.INTRO)
	objective("Follow the trail to the goblin village.", Vector3(0, 0, END_Z + 2))

func _level_interactables() -> Array:
	var list: Array = []
	if stage != "walk":
		return list
	for i in LOOT.size():
		if not Game.flag("trailLoot%d" % i):
			var L: Array = LOOT[i]
			list.append({ "id": "loot_%d" % i, "label": { "bush": "the bush", "log": "the hollow log", "stump": "the stump", "rocks": "the rocks" }[L[0]],
				"verb": "Search", "pos": L[1], "h": 1.4, "r": 1.9, "steps": [{ "who": "narrator", "line": TS.LOOT_LINES[L[0]] }, { "do": "loot_%d" % i }] })
	var t: String = str(Game.flags.get("trollDone", ""))
	if t == "":
		list.append({ "id": "troll", "label": "the Bridge Troll", "verb": "Talk to", "node": troll, "h": 2.4, "r": 2.6, "major": true, "steps": TS.TROLL_AGAIN })
	elif t == "bad":
		if not Game.flag("trollHut"):
			list.append({ "id": "hut", "label": "the troll's hut", "verb": "Search", "pos": HUT_DOOR, "h": 2.2, "r": 2.0, "steps": TS.HUT_SEARCH })
		if not Game.flag("trollChest"):
			list.append({ "id": "chest", "label": "the troll's chest", "verb": "Open", "pos": CHEST_POS, "h": 1.0, "r": 1.6, "steps": TS.CHEST })
	elif t == "good":
		list.append({ "id": "hut", "label": "the troll's hut", "verb": "Knock on", "pos": HUT_DOOR, "h": 2.2, "r": 2.0, "steps": TS.HUT_DOOR_GOOD })
	return list

func _level_process(_delta: float) -> void:
	if busy or stage != "walk":
		return
	if not Game.flag("trollMet") and str(Game.flags.get("trollDone", "")) == "" and leader.global_position.z < TROLL_SPOT.z + 6.0:
		Game.set_flag("trollMet")
		_troll_scene()
	elif leader.global_position.z < END_Z:
		stage = "end"
		_to_village()

func _troll_scene() -> void:
	stage = "troll"
	focus_override = (leader.global_position + TROLL_SPOT) * 0.5
	hop(troll, 0.4)
	await run_dialogue(TS.TROLL_MEET)
	focus_override = null
	stage = "walk"

func _on_action(n: String) -> void:
	if n.begins_with("loot_"):
		var i := int(n.substr(5))
		var L: Array = LOOT[i]
		Game.set_flag("trailLoot%d" % i)
		loot_nodes[i].visible = false
		Game.add_gold(L[2])
		var msg := "+%d gold" % L[2]
		if L[3] != "":
			Game.add_item(L[3], 1)
			msg += " · %s got: %s" % [CombatD.PARTY[Game.active_fighter]["name"], CombatD.ITEMS[L[3]]["name"]]
		ui_sfx.play()
		show_toast(msg, 2.2)
		await wait(0.3)
		return
	match n:
		"troll_good":
			var xylo := _member("xylo")
			follow_enabled = false
			walk_to(troll, HUT_DOOR, 0.8, 4.0)
			await walk_to(xylo, HUT_DOOR + Vector3(-0.6, 0, 0.8), 1.0, 4.0)
			await fade_out(0.6)
			troll.visible = false
			xylo.visible = false
			await wait(1.5)
			Game.set_flag("trollDone", "good")
			_apply_state()
			fade_in(0.6)
			await wait(0.7)
		"xylo_back":
			var xylo := _member("xylo")
			xylo.global_position = HUT_DOOR + (HUT_DOOR - HUT).normalized() * 0.8
			xylo.visible = true
			hop(xylo, 0.3)
			await walk_to(xylo, leader.global_position + Vector3(1.2, 0, 1.2), 1.0, 3.5)
			follow_enabled = true
		"troll_fight":
			var res := await fight("troll", { "enemies": [troll] })
			if res == "win" or res == "talked":
				Game.set_flag("trollDone", "bad")
				_apply_state()
				await run_nested(TS.TROLL_BEATEN)
				objective("Loot the troll's hut, then follow the trail to the village.", CHEST_POS)
			else:
				troll.global_position = TROLL_SPOT   # ran away or lost: he's still blocking the bridge
		"hut_loot":
			Game.set_flag("trollHut")
			Game.add_gold(15)
			Game.add_item("bowl", 1)
			ui_sfx.play()
			show_toast("+15 gold · %s got: Chipotle Bowl" % CombatD.PARTY[Game.active_fighter]["name"], 2.4)
			await wait(0.4)
		"chest_loot":
			Game.set_flag("trollChest")
			Game.add_gold(55)
			if chest_node:
				var tw := create_tween()
				tw.tween_property(chest_node, "scale", chest_node.scale * 1.12, 0.12)
				tw.tween_property(chest_node, "scale", chest_node.scale, 0.12)
			ui_sfx.play()
			show_toast("+55 gold (the troll's life savings)", 2.4)
			objective("Follow the trail to the goblin village.", Vector3(0, 0, END_Z + 2))
			await wait(0.4)

func _member(id: String) -> Unit:
	for u in party:
		if u.id == id:
			return u
	return leader

func _to_village() -> void:
	busy = true
	Game.set_flag("trailDone")
	if Game.flag("villageOpen"):   # been there: walk straight back into free roam
		await fade_out(0.6)
		Game.travel("res://village.tscn", "trail", leader.id)
		return
	await fade_out(1.0)
	Game.goto("res://village.tscn")

# ---------------------------------------------------------------- walking between areas + saves
func can_resume() -> bool:
	return stage == "walk"

func can_resume_saved() -> bool:
	return Game.flag("trailStarted")

func _resume(r: Dictionary) -> void:
	stage = "walk"
	_apply_state()
	objective("Follow the trail to the goblin village.", Vector3(0, 0, END_Z + 2))
	await super._resume(r)

func back_exit() -> Dictionary:
	if stage == "walk":
		return { "pos": Vector3(0, 0, 57.5), "r": 2.4, "scene": "res://main.tscn", "name": "The Camp" }
	return {}

func arrival(from: String) -> Array:
	if from == "village":
		return [Vector3(0, 0, END_Z + 4.5), Vector3(0, 0, 1)]
	return [START, Vector3(0, 0, -1)]

# maps: the troll's hut is the one building; the troll is a dot while he's around
func map_buildings() -> Array:
	return [{ "pos": HUT, "name": "Troll's Hut" }]

# ---------------------------------------------------------------- automated screenshots (TRAIL_CHOICE=0 good, 1 bad)
func _shot_tour() -> void:
	var choice := int(OS.get_environment("TRAIL_CHOICE")) if OS.get_environment("TRAIL_CHOICE") != "" else 1
	fade.color.a = 0.0
	busy = false
	Game.set_flag("trailStarted")
	await wait(1.5)
	await shot("t_01_start")
	place_party(LOOT[1][1] + Vector3(1.4, 0, 0), Vector3(-1, 0, 0))
	await wait(1.0)
	start(current_interactables().filter(func(i): return i["id"] == "loot_1")[0])
	await advance(1, 0.6)
	await wait(0.8)
	await shot("t_02_loot")
	place_party(TROLL_SPOT + Vector3(0, 0, 9), Vector3(0, 0, -1))
	await wait(1.2)
	place_party(TROLL_SPOT + Vector3(0, 0, 5), Vector3(0, 0, -1))
	await wait(1.2)
	await shot("t_03_troll")
	await advance(1, 0.6)
	await wait(0.8)
	await shot("t_03b_choice")
	dialogue._picked.emit(mini(choice, dialogue._choices.size() - 1))
	for k in 160:
		await advance(1, 0.8)
		if k == 2:
			await shot("t_04_after_choice")
		if Game.flags.get("trollDone", "") != "" and not dialogue.active:
			break
	await wait(2.0)
	await shot("t_05_after")
	if choice == 1:
		place_party(CHEST_POS + Vector3(-1.3, 0, 0.6), Vector3(1, 0, 0))
		await wait(1.0)
		for id in ["hut", "chest"]:
			var it: Array = current_interactables().filter(func(i): return i["id"] == id)
			if not it.is_empty():
				start(it[0])
				await advance(2, 0.6)
				await wait(0.6)
		await shot("t_06_looted")
	print("TRAIL TOUR choice=", choice, " gold=", Game.gold, " trollDone=", Game.flags.get("trollDone", ""), " xp=", Game.xp)
	get_tree().quit()
