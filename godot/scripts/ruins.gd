# Area: the Old Ruins (side path off the Metocy Mart road, RUINS_PLAN.md). Daytime, overgrown.
# Crumbled walls and pillars, 3 loot spots, and THE BIG SHINY CHEST in the middle: opening it drops the trio into
# the Rat Cave (cave.tscn). Afterwards the hole stays (jump back in any time). Once the rats let you out, a tunnel
# in the north-west corner connects the ruins and the colony. South edge = back to the Metocy Mart.
# Flags: ruinsStarted, ruinsLoot0..2, ruinsFell (the floor gave way), ratsDone (cave: the rat choice is made).
extends Level

const RS = preload("res://scripts/ruins_script.gd")
const START := Vector3(0, 0, 15)
const CHEST := Vector3(0, 0, -2.0)
const TUNNEL := Vector3(-10.5, 0, -12.5)
# searchable spots: [kind, position, gold, item]
const LOOT := [
	["urn", Vector3(-9.0, 0, 3.0), 12, "beer"],
	["crates", Vector3(9.0, 0, -6.0), 18, ""],
	["rubble", Vector3(4.0, 0, -12.0), 10, "bowl"],
]

var stage := "walk"          # walk (free roam) / busy / end
var chest_node: Node3D
var chest_light: OmniLight3D
var chest_sparkle: Node3D
var hole: Node3D
var loot_nodes := []

func _configure() -> void:
	night = false
	light_dir = Vector3(-0.5, 0.45, -0.7)
	clear_center = Vector2(0, -2)
	clear_radius = 10.0
	path_pts = PackedVector2Array([Vector2(0, 22), Vector2(1, 12), Vector2(0, 4)])
	path_width = 1.6
	bounds = Rect2(-15, -17, 30, 38)
	subtitle = "Side Path — The Old Ruins"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [START, START + Vector3(-1, 0, 1.6), START + Vector3(1, 0, 1.6)]
	leader_id = "skorn"
	cam_locked = true
	zoom = 11.5
	cam_height = 0.42
	cam_look_h = 1.4
	checkpoint = START
	talk = {
		"lykor": [{ "who": "lykor", "line": "Ruins are just old houses that gave up. Respect." }], # DRAFT
		"xylo": [{ "who": "xylo", "mood": "smug", "line": "These carvings predate Deloye Lore volume one. Barely." }], # DRAFT
		"skorn": [{ "who": "skorn", "line": "If I find a sword in here, I'm keeping it." }], # DRAFT
	}

func _build_level() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4417
	var brick := Models.mat("castle_brick_broken_06", 2.0, Color(0.78, 0.76, 0.7))
	var moss := Models.mat("mossy_brick", 2.0, Color(0.8, 0.85, 0.75))
	var blocks := Models.mat("medieval_blocks_05", 2.0, Color(0.8, 0.78, 0.72))
	# old stone floor + a raised dais in the middle for the chest
	Models.patch(self, Vector3(0, 0, -2), Vector2(22, 20), "monastery_stone_floor", 2.5, Color(0.8, 0.78, 0.72), 0.0, 0.25)
	Models.patch(self, Vector3(0, 0, 8), Vector2(5, 10), "cobblestone_floor_04", 2.0, Color(0.75, 0.73, 0.68), 0.0, 0.4)
	Models.block(self, CHEST + Vector3(0, 0.12, 0), Vector3(4.4, 0.24, 4.4), blocks)
	Models.block(self, CHEST + Vector3(0, 0.3, 0), Vector3(3.2, 0.14, 3.2), blocks)
	# a ring of crumbled walls (gaps south for the way in and north-west for the tunnel)
	var segs := [   # [center, length, yaw, height]
		[Vector3(-12.5, 0, -2), 12.0, PI / 2, 2.6], [Vector3(12.5, 0, -3), 14.0, PI / 2, 2.2],
		[Vector3(-3, 0, -15.5), 9.0, 0.0, 3.0], [Vector3(7.5, 0, -15.0), 8.0, 0.0, 1.8],
		[Vector3(-9.5, 0, 8.0), 6.0, 0.0, 1.4], [Vector3(9.5, 0, 8.5), 6.0, 0.0, 1.0],
	]
	for sg in segs:
		_wall(sg[0], sg[1], sg[2], sg[3], brick if r.randf() < 0.6 else moss, r)
	# pillars: some whole, some snapped off, one lying down
	for p in [Vector3(-6, 0, -7), Vector3(6, 0, -7), Vector3(-6, 0, 3), Vector3(6, 0, 3), Vector3(-3, 0, -11), Vector3(3, 0, -11)]:
		var h: float = [4.2, 1.6, 3.1, 0.9, 2.4, 3.8][int(abs(p.x * 3 + p.z)) % 6]
		Models.cylinder(self, p, 0.55, 0.5, h, moss if p.z > 0 else brick, 12)
		Models.cylinder(self, p, 0.7, 0.7, 0.3, blocks, 12)
		Util.static_cyl(self, p, 0.6, 3.0)
	var fallen := Models.cylinder(self, Vector3(-2.0, 0, 6.0), 0.5, 0.5, 3.6, brick, 12)
	fallen.rotation = Vector3(0, 0.4, PI / 2)
	fallen.position.y = 0.5
	Util.static_box(self, Vector3(-2.0, 0.5, 6.0), Vector3(3.6, 1.0, 1.0), 0.4)
	# rubble, moss and nature taking it back
	for k in 18:
		var p := Vector3(r.randf_range(-13, 13), 0, r.randf_range(-15, 12))
		if p.distance_to(CHEST) < 4.0 or abs(p.x) < 2.0 and p.z > 4.0:
			continue
		match k % 4:
			0: Models.place(self, "rock_09", p, r.randf() * TAU, r.randf_range(1.2, 2.2), false, Color(0.78, 0.76, 0.7))
			1: card("bush_%d" % (1 + k % 3), r.randf_range(1.0, 1.6), p, r.randf() < 0.5)
			2: Models.place(self, "fern_02", p, r.randf() * TAU, r.randf_range(0.9, 1.3))
			_: Models.place(self, "moss_01", p, r.randf() * TAU, r.randf_range(1.0, 2.0))
	# forest around the ruins
	for k in 46:
		var a := float(k) / 46.0 * TAU
		var p := Vector3(cos(a) * r.randf_range(16.5, 22.0), 0, sin(a) * r.randf_range(19.0, 24.0) - 1.0)
		if p.z > 14.0 and abs(p.x) < 4.0:
			continue
		card("tree_%d" % (1 + k % 4), r.randf_range(8.0, 11.0), p, r.randf() < 0.5, true, 0.6)
	# the big shiny chest (THE TRAP), gold, with a glow and sparkles
	chest_node = Models.place(self, "treasure_chest", CHEST + Vector3(0, 0.37, 0), 0.0, 1.25, false, Color(1.35, 1.15, 0.55))
	Util.static_box(self, CHEST + Vector3(0, 0.6, 0), Vector3(1.6, 1.0, 1.0))
	chest_light = OmniLight3D.new()
	chest_light.light_color = Color(1.0, 0.82, 0.4)
	chest_light.light_energy = 1.6
	chest_light.omni_range = 4.5
	chest_light.position = CHEST + Vector3(0, 1.6, 0.6)
	add_child(chest_light)
	chest_sparkle = _sparkle(CHEST + Vector3(0, 1.2, 0), 14, 0.8)
	add_glow(CHEST + Vector3(0, 1, 0), Color(1.0, 0.85, 0.45), 4.0, func(): return 0.7 if chest_node.visible else 0.0)
	# the hole (after the trap)
	hole = Node3D.new()
	add_child(hole)
	var dark := Util.mat(Color(0.01, 0.01, 0.012))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var disc := CylinderMesh.new()
	disc.top_radius = 1.5
	disc.bottom_radius = 1.5
	disc.height = 0.02
	Util.add_mesh(hole, disc, dark, CHEST + Vector3(0, 0.39, 0))
	for k in 9:   # broken floor chunks around the edge
		var a := float(k) / 9.0 * TAU
		Models.place(hole, "rock_09", CHEST + Vector3(cos(a) * 1.7, 0.25, sin(a) * 1.7), a, 0.7, false, Color(0.7, 0.68, 0.62))
	hole.visible = false
	# the tunnel up from the rat colony (north-west corner): a stone arch over darkness
	Models.block(self, TUNNEL + Vector3(-1.4, 1.3, 0), Vector3(0.7, 2.6, 0.9), blocks)
	Models.block(self, TUNNEL + Vector3(1.4, 1.3, 0), Vector3(0.7, 2.6, 0.9), blocks)
	Models.block(self, TUNNEL + Vector3(0, 2.75, 0), Vector3(3.5, 0.5, 0.9), blocks)
	var q := QuadMesh.new()
	q.size = Vector2(2.1, 2.5)
	Util.add_mesh(self, q, dark, TUNNEL + Vector3(0, 1.25, -0.2))
	Util.static_box(self, TUNNEL + Vector3(0, 1.3, -0.6), Vector3(3.4, 2.6, 0.4))
	wood_sign("sign_ruins_mart", "BACK TO THE\nMETOCY MART", Vector3(2.6, 1.2, 17.5), -0.2, 1.4, 0.5, true)
	wood_sign("sign_ruins_chest", "DEFINITELY\nNOT A TRAP", CHEST + Vector3(2.6, 1.0, 1.6), -0.3, 1.2, 0.46, true)   # DRAFT
	# loot spots
	for i in LOOT.size():
		var L: Array = LOOT[i]
		match L[0]:
			"urn":
				Models.place(self, "ceramic_vase_02", L[1], 0.0, 1.4, true, Color(0.8, 0.75, 0.68))
				Models.place(self, "ceramic_vase_03", L[1] + Vector3(0.7, 0, 0.3), 0.0, 1.1, false, Color(0.8, 0.75, 0.68))
			"crates":
				Models.place(self, "wooden_crate_01", L[1], 0.3, 1.0, true, Color(0.7, 0.62, 0.52))
				Models.place(self, "wooden_crate_02", L[1] + Vector3(0.9, 0, 0.4), -0.2, 0.9, false, Color(0.7, 0.62, 0.52))
			"rubble":
				for k in 4:
					Models.place(self, "rock_07", L[1] + Vector3((k % 2) * 0.8 - 0.4, 0, (k / 2) * 0.6 - 0.3), k * 1.3, 1.1, false, Color(0.75, 0.72, 0.66))
		loot_nodes.append(_sparkle(L[1] + Vector3(0, 0.9, 0)))

func _wall(c: Vector3, length: float, yaw_: float, h: float, m: Material, r: RandomNumberGenerator) -> void:
	# a wall that's crumbled: uneven blocks along its length
	var dir := Vector3(cos(yaw_), 0, -sin(yaw_))
	var n := int(length / 1.5)
	for i in n:
		var off := (i - (n - 1) / 2.0) * 1.5
		var hh := h * r.randf_range(0.35, 1.0)
		if r.randf() < 0.15:
			hh = 0.4
		Models.block(self, c + dir * off + Vector3(0, hh / 2.0, 0), Vector3(1.5, hh, 0.8), m, yaw_)
	Util.static_box(self, c + Vector3(0, 1.0, 0), Vector3(length, 2.0, 0.8), yaw_)

func _sparkle(p: Vector3, amount := 6, rad := 0.35) -> Node3D:
	var sp := CPUParticles3D.new()
	sp.amount = amount
	sp.lifetime = 1.2
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = rad
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

func _after_build() -> void:
	var env: Environment = world_env.environment
	env.fog_density = 0.006
	env.volumetric_fog_density = 0.003
	sun_light.light_color = Color(1.0, 0.92, 0.78)
	_apply_state()

func _apply_state() -> void:
	var fell := Game.flag("ruinsFell")
	chest_node.visible = not fell
	chest_light.visible = not fell
	chest_sparkle.visible = not fell
	hole.visible = fell
	for i in LOOT.size():
		loot_nodes[i].visible = not Game.flag("ruinsLoot%d" % i)

# ---------------------------------------------------------------- story
func _begin() -> void:
	Game.set_flag("ruinsStarted")
	busy = true
	fade_in(1.0)
	await wait(0.6)
	await run_dialogue(RS.INTRO)
	_walk_objective()

func _walk_objective() -> void:
	if not Game.flag("ruinsFell"):
		objective("Search the Old Ruins.", CHEST)
	elif not Game.flags.has("ratsDone"):
		objective("Jump back in the hole, or head back to the Metocy Mart.", CHEST)
	else:
		objective("Explore the ruins, or head back to the Metocy Mart.")

func _level_interactables() -> Array:
	var list: Array = []
	if stage != "walk":
		return list
	for i in LOOT.size():
		if not Game.flag("ruinsLoot%d" % i):
			var L: Array = LOOT[i]
			list.append({ "id": "loot_%d" % i, "label": { "urn": "the old urns", "crates": "the crates", "rubble": "the rubble" }[L[0]],
				"verb": "Search", "pos": L[1], "h": 1.4, "r": 2.0, "steps": [{ "do": "loot_%d" % i }] })
	if Game.flag("ruinsFell"):
		list.append({ "id": "hole", "label": "the hole", "verb": "Jump in", "pos": CHEST, "h": 0.8, "r": 2.6, "steps": RS.HOLE })
	else:
		list.append({ "id": "chest", "label": "the big shiny chest", "verb": "Open", "pos": CHEST, "h": 1.6, "r": 2.6, "steps": RS.BIG_CHEST })
	if Game.flags.has("ratsDone"):
		list.append({ "id": "tunnel", "label": "the tunnel (to the Rat Colony)", "verb": "Go down", "pos": TUNNEL + Vector3(0, 0, 1.0), "h": 2.6, "r": 2.0, "steps": [{ "do": "tunnel_down" }] })
	else:
		list.append({ "id": "tunnel_shut", "label": "the collapsed tunnel", "verb": "Look at", "pos": TUNNEL + Vector3(0, 0, 1.0), "h": 2.6, "r": 2.0,
			"steps": [{ "who": "xylo", "line": "It's caved in. Whatever's down there, you can't get in from this side." }] }) # DRAFT
	return list

func _on_action(n: String) -> void:
	if n.begins_with("loot_"):
		var i := int(n.substr(5))
		var L: Array = LOOT[i]
		Game.set_flag("ruinsLoot%d" % i)
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
		"trap":
			await _trap()
		"jump_hole":
			stage = "end"
			busy = true
			await fade_out(0.7)
			Game.travel("res://cave.tscn", "hole", leader.id)
		"tunnel_down":
			stage = "end"
			busy = true
			await fade_out(0.6)
			Game.travel("res://cave.tscn", "tunnel", leader.id)

# The floor gives way: a rumble, cracks, everyone drops one by one, black, then the cave.
func _trap() -> void:
	stage = "busy"
	busy = true
	freeze_all(true)
	follow_enabled = false
	var tw := create_tween()   # the lid "opens" (bounce)
	tw.tween_property(chest_node, "scale", chest_node.scale * 1.12, 0.15)
	tw.tween_property(chest_node, "scale", chest_node.scale, 0.15)
	await wait(0.5)
	show_toast("…It's empty.", 1.4)   # DRAFT
	await wait(1.0)
	play_sound("sfx_fire_explosion", -8.0, 0.45)
	shake = 0.6
	for u in party:
		char_label(u, "!", 1.2, u.height_m + 0.6, Color("#ff5a3a"))
	await wait(0.9)
	Game.set_flag("ruinsFell")
	for u in party:   # gather them on the dais, then drop them one at a time
		u.global_position = CHEST + Vector3(randf_range(-1.0, 1.0), 0.4, randf_range(-0.2, 1.2))
	chest_node.visible = false
	chest_light.visible = false
	chest_sparkle.visible = false
	hole.visible = true
	for u in party:
		var p := Fx.poof(Color(0.6, 0.55, 0.48))
		add_child(p)
		p.global_position = u.global_position + Vector3(0, 0.3, 0)
		p.emitting = true
		char_label(u, "AAAAA", 1.0, u.height_m + 0.3, Color("#ffdf8a"))   # DRAFT
		u.visible = false
		play_sound("sfx_pop", -8.0, 0.7)
		await wait(0.25)
	await fade_out(0.8)
	stage = "end"
	Game.goto("res://cave.tscn")

# ---------------------------------------------------------------- walking between areas + saves
func can_resume() -> bool:
	return stage == "walk"

func can_resume_saved() -> bool:
	return Game.flag("ruinsStarted")

func _resume(r: Dictionary) -> void:
	stage = "walk"
	_apply_state()
	_walk_objective()
	await super._resume(r)
	if r.get("from", "") == "cave":
		await run_dialogue(RS.BACK_FROM_CAVE)

func back_exit() -> Dictionary:
	if stage == "walk":
		return { "pos": Vector3(0, 0, 19.5), "r": 2.4, "scene": "res://mart.tscn", "name": "The Metocy Mart" }
	return {}

func arrival(from: String) -> Array:
	if from == "cave":
		return [TUNNEL + Vector3(0, 0, 3.0), Vector3(0, 0, 1)]
	return [START, Vector3(0, 0, -1)]

func map_buildings() -> Array:
	return [{ "pos": CHEST, "name": "The Hole" if Game.flag("ruinsFell") else "Shiny Chest" }]

# ---------------------------------------------------------------- automated screenshots
# Default: arrive, loot a spot, open the chest → the cave tour takes over (cave.gd). RUINS_TOUR=back: arrive from the cave.
func _shot_tour() -> void:
	fade.color.a = 0.0
	busy = false
	Game.set_flag("ruinsStarted")
	await wait(1.5)
	await shot("r_01_start")
	place_party(LOOT[0][1] + Vector3(1.6, 0, 0.6), Vector3(-1, 0, 0))
	await wait(0.8)
	start(current_interactables().filter(func(i): return i["id"] == "loot_0")[0])
	await wait(1.0)
	place_party(CHEST + Vector3(0, 0, 3.4), Vector3(0, 0, -1))
	await wait(1.2)
	await shot("r_02_chest")
	start(current_interactables().filter(func(i): return i["id"] == "chest")[0])
	await advance(3, 0.6)
	await wait(0.6)
	dialogue._picked.emit(0)
	await wait(2.4)
	await shot("r_03_trap")
	print("RUINS TOUR gold=", Game.gold, " fell=", Game.flag("ruinsFell"))
	if OS.get_environment("SHOTS_CHAIN") == "":   # SHOTS_CHAIN=1: let the trap load cave.tscn, whose own tour takes over
		get_tree().quit()
