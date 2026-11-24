# Area: the Rat Cave under the Old Ruins (RUINS_PLAN.md). Dark, torch-lit.
#   Landing chamber (where the trap drops you, under the hole) → a tunnel with loot + roaming rat patrols →
#   THE THREE SEALS puzzle chamber → the Rat Colony (Rat King on a junk pile, Scrounge's stall, the 5-way choice) →
#   a tunnel up and out to the ruins (+ a secret shortcut to the Mart road on the "lore" outcome).
# The puzzle: 3 boulders slide on a grid until they hit something. Each has a symbol (spoon/book/bowl) and must
#   stop on the plate with the same symbol. Only Skorn can push the BIG one; only Lykor fits through the crack to
#   the side room whose lever drops the rubble in front of the third boulder; only Xylo can read the wall carving,
#   which brings back the plates' worn-off symbols (the door won't open until it's read). A rope resets the boulders.
# Flags: caveEntered, caveLoot0..1, sealsRead, sealsLever, sealsSolved, ratsDone ("fight"/"king"/"trade"/"lore"/"mog"),
#   ratPet (the mog outcome: a tiny rat follows the party everywhere, level.gd spawn_pet).
extends Level

const RS = preload("res://scripts/ruins_script.gd")
const LANDING := Vector3(0, 0, 33)
const TUNNEL_OUT := Vector3(9.0, 0, -37.5)    # up to the ruins
const SHORTCUT := Vector3(-10.0, 0, -37.5)    # "rats_lore": straight to the Mart road
const KING_POS := Vector3(0, 0, -30.0)
const STALL := Vector3(-8.0, 0, -26.0)
const COLONY_Z := -13.5                       # walking past this (north of the door) starts the colony scene
const LOOT := [   # [kind, position, gold, item, gear]
	["crate", Vector3(-3.2, 0, 22.0), 15, "", "lucky_crumb"],
	["junk", Vector3(3.2, 0, 13.0), 20, "bowl", ""],
]

# ---- the Three Seals (grid: col 0..6 west→east, row 0..5 north→south)
const PZ := Vector3(0, 0, -4)
const CELL := 1.6
const COLS := 7
const ROWS := 6
const PILLARS := [Vector2i(2, 0), Vector2i(5, 1), Vector2i(1, 5), Vector2i(0, 4), Vector2i(4, 3)]
const PLATES := { "spoon": Vector2i(2, 1), "book": Vector2i(0, 3), "bowl": Vector2i(6, 0) }
const B_START := { "spoon": Vector2i(6, 5), "book": Vector2i(4, 2), "bowl": Vector2i(7, 3) }   # bowl starts in the alcove
const BOWL_ROLLED := Vector2i(5, 3)        # where the bowl boulder ends up after the lever (rolls west until the pillar)
const CRACK := Vector3(7.0, 0, -0.6)       # in the east wall
const SIDE_IN := Vector3(11.0, 0, -0.6)    # the little room behind it
const LEVER_POS := Vector3(14.2, 0, -2.4)
const CARVING := Vector3(-7.0, 0, -4.0)    # west wall
const ROPE := Vector3(-6.4, 0, 1.8)        # reset rope
const DOOR := Vector3(0, 0, -10.4)

var stage := "walk"        # walk / busy / end
var boulders := {}         # sym -> { node, cell, big }
var plate_marks := {}      # sym -> Node3D (glowing symbol, shown after reading)
var rubble: Node3D
var lever: Node3D
var door: Node3D
var door_body: StaticBody3D
var torches: Array = []    # [OmniLight3D, base energy]
var lead_light: OmniLight3D
var lead_glow: Dictionary
var progress_t := 0.0      # seconds since the last puzzle progress (a hint every HINT_EVERY)
var puzzle_t := 0.0        # total seconds spent in the chamber while it's unsolved (skip offered after SKIP_AFTER)
var hint_level := 0        # 0 = none yet, 1 = the general hint was said, 2+ = concrete next-move hints
var skip_offered := false
var push_ghost: Node3D     # glowing ring where the boulder in reach would stop
const HINT_EVERY := 30.0   # (Ebain 11/24: was 90)
const SKIP_AFTER := 180.0
var hinted_at := 0.0
var not_read_said := false
var in_side_room := false
var king: Unit
var trader: Unit
var crowd: Array[Unit] = []
var shortcut_node: Node3D
var loot_nodes := []

func _configure() -> void:
	night = true
	light_dir = Vector3(0.2, 0.9, -0.3)
	clear_center = Vector2(999, 999)
	clear_radius = 0.1
	bounds = Rect2(-14, -41, 31, 83)
	subtitle = "Side Path — The Rat Cave"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [LANDING, LANDING + Vector3(-1, 0, 1.4), LANDING + Vector3(1, 0, 1.4)]
	leader_id = "skorn"
	cam_locked = true
	zoom = 10.0
	cam_height = 0.62
	cam_look_h = 1.0
	checkpoint = LANDING
	talk = {
		"lykor": [{ "who": "lykor", "mood": "angry", "line": "It smells like cheese and bad decisions down here." }], # DRAFT
		"xylo": [{ "who": "xylo", "line": "Rats are mentioned in Deloye Lore exactly once. As a font." }], # DRAFT
		"skorn": [{ "who": "skorn", "mood": "smug", "line": "Best hole I ever fell in." }], # DRAFT
	}

# Cave light: very dark, everything is lit by the torches and the light around the leader.
func light_at(p: Vector3) -> Color:
	var col := Color(0.3, 0.28, 0.33)
	for g in glows:
		var f: float = clamp(1.0 - p.distance_to(g["pos"]) / g["radius"], 0.0, 1.0)
		f = f * f * float(g["strength"].call())
		col = col.lerp(g["color"], clamp(f * 1.2, 0.0, 1.0)) + g["color"] * 0.25 * f
	return Color(min(col.r, 1.2), min(col.g, 1.15), min(col.b, 1.1))

# ================================================================ building the cave
var _rock: Material
var _rock_dark: Material

func _build_level() -> void:
	_rock = Models.mat("rock_wall_10", 3.0, Color(0.55, 0.5, 0.46))
	_rock_dark = Models.mat("dark_rock", 2.5, Color(0.72, 0.66, 0.6))
	# rock floor over the whole cave (hides the grass ground)
	var pm := PlaneMesh.new()
	pm.size = Vector2(36, 90)
	Util.add_mesh(self, pm, _rock_dark, Vector3(1.5, 0.012, 0))
	# --- walls. Walls between the camera and the party (south sides) are low lips with full-height collision.
	# landing chamber x -7..7, z 28..40
	_wall_x(-7.0, 28.0, 40.0)
	_wall_x(7.0, 28.0, 40.0)
	_wall_z(40.0, -7.0, 7.0, true)
	_wall_z(28.0, -7.0, -4.5)
	_wall_z(28.0, 4.5, 7.0)
	# tunnel x -4.5..4.5, z 3..28
	_wall_x(-4.5, 3.0, 28.0)
	_wall_x(4.5, 3.0, 28.0)
	# puzzle chamber x -7.5..7.5, z -10.4..3
	_wall_x(-7.5, -10.4, 3.0)
	_wall_x(7.5, -10.4, 3.0)
	_wall_z(3.0, -7.5, -4.5, true)
	_wall_z(3.0, 4.5, 7.5, true)
	_wall_z(-10.4, -7.5, -1.6, false, 2.0)   # kept lowish: from the colony it's between the camera and you
	_wall_z(-10.4, 1.6, 7.5, false, 2.0)
	# colony x -13..13, z -40..-10.4
	_wall_x(-13.0, -40.0, -10.4)
	_wall_x(13.0, -40.0, -10.4)
	_wall_z(-40.0, -13.0, 13.0)
	_wall_z(-10.4, -13.0, -7.5, true)
	_wall_z(-10.4, 7.5, 13.0, true)
	# side room (behind the crack) x 9..16, z -5..3
	_wall_x(16.0, -5.0, 3.0)
	_wall_z(-5.0, 7.5, 16.0)
	_wall_z(3.0, 7.5, 16.0, true)
	# rocks along the walls so they don't look like boxes
	var r := RandomNumberGenerator.new()
	r.seed = 911
	for k in 34:
		var p: Vector3
		match k % 5:
			0: p = Vector3(-6.4 * (1 if k % 2 else -1), 0, r.randf_range(29, 39))
			1: p = Vector3(3.9 * (1 if k % 2 else -1), 0, r.randf_range(5, 27))
			2: p = Vector3(12.2 * (1 if k % 2 else -1), 0, r.randf_range(-39, -12))
			3: p = Vector3(r.randf_range(-12, 12), 0, -39.3)
			_: p = Vector3(-6.9, 0, r.randf_range(-9.5, 2.0))
		if p.distance_to(TUNNEL_OUT) < 2.5 or p.distance_to(SHORTCUT) < 2.5 or p.distance_to(CARVING) < 1.8 or p.distance_to(STALL) < 2.5:
			continue
		Models.place(self, "rock_07", p, r.randf() * TAU, r.randf_range(1.6, 2.6), false, Color(0.6, 0.55, 0.5))
	# --- landing: light coming down from the hole, a rope hanging out of reach, rubble from the floor that fell
	var shaft := SpotLight3D.new()
	shaft.light_color = Color(1.0, 0.92, 0.75)
	shaft.light_energy = 4.0
	shaft.spot_range = 14.0
	shaft.spot_angle = 18.0
	shaft.position = LANDING + Vector3(0, 10, -1.5)
	shaft.rotation.x = -PI / 2
	add_child(shaft)
	add_glow(LANDING + Vector3(0, 0.5, -1.5), Color(1.0, 0.9, 0.7), 4.0, func(): return 0.9, true)
	Models.block(self, LANDING + Vector3(0.3, 3.4, -1.5), Vector3(0.05, 4.0, 0.05), Models.mat("rough_linen", 0.5, Color(0.7, 0.6, 0.45)))
	for k in 6:
		Models.place(self, "rock_09", LANDING + Vector3(r.randf_range(-2.4, 2.4), 0, r.randf_range(-3, -0.2)), r.randf() * TAU, r.randf_range(0.8, 1.3), false, Color(0.72, 0.7, 0.64))
	_torch(Vector3(-6.6, 1.8, 31.0))
	_torch(Vector3(6.6, 1.8, 31.0))
	# --- the tunnel: torches, loot, some junk
	for z in [24.0, 16.0, 8.0]:
		_torch(Vector3(-4.1 if int(z) % 16 == 0 else 4.1, 1.8, z))
	for i in LOOT.size():
		var L: Array = LOOT[i]
		if L[0] == "crate":
			Models.place(self, "wooden_crate_01", L[1], 0.4, 1.0, true, Color(0.6, 0.52, 0.42))
		else:
			Models.place(self, "wine_barrel_01", L[1], 0.0, 0.8, true, Color(0.6, 0.5, 0.4))
			Models.place(self, "rusted_wheel_rim_01", L[1] + Vector3(-0.8, 0, 0.5), 1.2, 0.7)
		loot_nodes.append(_sparkle(L[1] + Vector3(0, 1.0, 0)))
	Models.place(self, "wooden_bucket_02", Vector3(-3.4, 0, 9.0), 0.0, 0.9)
	# --- the puzzle chamber
	_build_puzzle()
	# --- the colony
	_build_colony()
	_lead_light()

func _wall_x(x: float, z0: float, z1: float, low := false) -> void:
	var h := 0.7 if low else 3.4
	Models.block(self, Vector3(x, h / 2.0, (z0 + z1) / 2.0), Vector3(1.0, h, z1 - z0), _rock)
	Util.static_box(self, Vector3(x, 1.5, (z0 + z1) / 2.0), Vector3(1.0, 3.0, z1 - z0))

func _wall_z(z: float, x0: float, x1: float, low := false, h := 3.4) -> void:
	if low:
		h = 0.7
	Models.block(self, Vector3((x0 + x1) / 2.0, h / 2.0, z), Vector3(x1 - x0, h, 1.0), _rock)
	Util.static_box(self, Vector3((x0 + x1) / 2.0, 1.5, z), Vector3(x1 - x0, 3.0, 1.0))

func _torch(p: Vector3) -> void:
	var wood := Models.mat("weathered_planks", 0.5, Color(0.4, 0.3, 0.22))
	var stick := Models.block(self, p + Vector3(0, -0.35, 0), Vector3(0.09, 0.6, 0.09), wood)
	stick.rotation.z = 0.25 if p.x < 0 else -0.25
	var fl := Fx.flames(0.32)
	fl.position = p
	add_child(fl)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.62, 0.3)
	l.light_energy = 2.4
	l.omni_range = 9.5
	l.position = p + Vector3(0, 0.2, 0)
	add_child(l)
	var i := torches.size()
	torches.append([l, 2.4])
	add_glow(p - Vector3(0, 1.2, 0), Color(1.0, 0.68, 0.38), 6.5, func(): return 0.8 + 0.12 * sin(t * 9.0 + i * 1.7), true)

func _lead_light() -> void:
	lead_light = OmniLight3D.new()
	lead_light.light_color = Color(1.0, 0.85, 0.65)
	lead_light.light_energy = 1.5
	lead_light.omni_range = 7.5
	add_child(lead_light)
	lead_glow = { "pos": Vector3.ZERO, "color": Color(1.0, 0.86, 0.66), "radius": 4.0, "strength": func(): return 0.6, "strong": true }
	glows.append(lead_glow)

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

# ---------------------------------------------------------------- the Three Seals
func cell_pos(c: Vector2i) -> Vector3:
	return PZ + Vector3((c.x - 3) * CELL, 0, (c.y - 2.5) * CELL)

func _build_puzzle() -> void:
	var stone := Models.mat("monastery_stone_floor", 1.6, Color(0.6, 0.57, 0.52))
	# the worn floor area the boulders slide on (raised lip around it)
	Models.block(self, PZ + Vector3(0, 0.02, 0), Vector3(COLS * CELL, 0.04, ROWS * CELL), stone)
	for c in COLS:
		for rr in ROWS:
			if (c + rr) % 2 == 0:
				Models.block(self, cell_pos(Vector2i(c, rr)) + Vector3(0, 0.045, 0), Vector3(CELL - 0.08, 0.01, CELL - 0.08), Models.mat("slate_floor_02", 1.6, Color(0.55, 0.53, 0.5)))
	# pillars (stalagmites)
	for pc in PILLARS:
		var n := Models.place(self, "rock_07", cell_pos(pc), float(pc.x * 7 + pc.y), 1.0, false, Color(0.62, 0.58, 0.52))
		var box := Models.aabb(n)
		var s := 1.2 / maxf(0.01, maxf(box.size.x, box.size.z))
		n.scale = Vector3(s, s * 2.4, s)
		Util.static_cyl(self, cell_pos(pc), 0.62, 3.0)
	# plates (worn smooth: the symbols only glow once Xylo reads the carving)
	for sym in PLATES:
		var pp := cell_pos(PLATES[sym])
		Models.cylinder(self, pp, 0.66, 0.62, 0.06, Models.mat("marble_tiles", 1.0, Color(0.7, 0.68, 0.62)), 24)
		var mark := Node3D.new()
		mark.position = pp + Vector3(0, 0.08, 0)
		add_child(mark)
		var ring := Util.mat(Color(1.0, 0.8, 0.35))
		ring.emission_enabled = true
		ring.emission = Color(1.0, 0.7, 0.3)
		ring.emission_energy_multiplier = 1.6
		var tm := TorusMesh.new()
		tm.inner_radius = 0.5
		tm.outer_radius = 0.6
		Util.add_mesh(mark, tm, ring, Vector3.ZERO)
		var lbl := Label3D.new()
		lbl.text = sym.to_upper()
		lbl.font_size = 64
		lbl.pixel_size = 0.006
		lbl.outline_size = 10
		lbl.modulate = Color("#ffd27a")
		lbl.rotation = Vector3(-PI / 2, 0, 0)
		lbl.position = Vector3(0, 0.02, 0)
		mark.add_child(lbl)
		var pl := OmniLight3D.new()
		pl.light_color = Color(1.0, 0.75, 0.35)
		pl.light_energy = 0.8
		pl.omni_range = 2.2
		pl.position = Vector3(0, 0.5, 0)
		mark.add_child(pl)
		mark.visible = false
		plate_marks[sym] = mark
	# boulders, each with its symbol on top
	for sym in B_START:
		var big: bool = sym == "spoon"
		var root := Node3D.new()
		add_child(root)
		var rock := Models.place(root, "rock_07", Vector3.ZERO, float(sym.length()), 1.0, false, Color(0.5, 0.46, 0.42) if big else Color(0.68, 0.64, 0.58))
		var box := Models.aabb(rock)
		var size := 1.5 if big else 1.25
		var sc := size / maxf(0.01, maxf(box.size.x, box.size.z))
		rock.scale = Vector3(sc, sc * 0.9, sc)
		rock.position.y = -box.position.y * sc * 0.9
		var top := box.size.y * sc * 0.9
		match sym:
			"spoon":
				var sp := Models.place(root, "wooden_spoon", Vector3(0, top + 0.05, 0), 0.6, 1.0)
				var sb := Models.aabb(sp)
				sp.scale = Vector3.ONE * (0.7 / maxf(0.01, maxf(sb.size.x, maxf(sb.size.y, sb.size.z))))
				sp.rotation = Vector3(PI / 2, 0.6, 0)
			"bowl":
				var bw := Models.place(root, "wooden_bowl_01", Vector3(0, top - 0.02, 0), 0.0, 1.0)
				var bb := Models.aabb(bw)
				bw.scale = Vector3.ONE * (0.55 / maxf(0.01, maxf(bb.size.x, bb.size.z)))
			"book":
				Models.block(root, Vector3(0, top + 0.06, 0), Vector3(0.5, 0.12, 0.38), Models.mat("fabric_leather_01", 0.5, Color(0.55, 0.15, 0.12)))
				Models.block(root, Vector3(0.02, top + 0.06, 0), Vector3(0.47, 0.1, 0.36), Util.mat(Color(0.92, 0.88, 0.78)))
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(size * 0.95, 2.0, size * 0.95)
		cs.shape = bs
		cs.position.y = 1.0
		body.add_child(cs)
		root.add_child(body)
		var tag := Label3D.new()   # joke label
		tag.text = { "spoon": "Boulder (BIG) (Skorn Only)", "book": "Boulder (Reads)", "bowl": "Boulder (Stuck)" }[sym]   # DRAFT
		tag.font_size = 30
		tag.pixel_size = 0.0065
		tag.outline_size = 8
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.modulate = Color("#ffcf9a")
		tag.position = Vector3(0, top + 0.6, 0)
		tag.no_depth_test = true
		root.add_child(tag)
		boulders[sym] = { "node": root, "cell": B_START[sym], "big": big }
		root.global_position = cell_pos(B_START[sym])
	# rubble in front of the alcove boulder (the lever drops it)
	rubble = Node3D.new()
	add_child(rubble)
	for k in 5:
		Models.place(rubble, "rock_09", cell_pos(B_START["bowl"]) + Vector3(-0.7 + (k % 2) * 0.3, 0.1 * (k / 2), -0.9 + k * 0.45), k * 1.1, 1.2, false, Color(0.62, 0.58, 0.52))
	var rb := StaticBody3D.new()
	var rcs := CollisionShape3D.new()
	var rbs := BoxShape3D.new()
	rbs.size = Vector3(1.0, 2.0, 2.4)
	rcs.shape = rbs
	rcs.position = cell_pos(B_START["bowl"]) + Vector3(-0.7, 1.0, 0)
	rb.add_child(rcs)
	rubble.add_child(rb)
	# the crack in the east wall + the side room with the lever
	var dark := Util.mat(Color(0.0, 0.0, 0.0))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := QuadMesh.new()
	q.size = Vector2(0.35, 2.2)
	Util.add_mesh(self, q, dark, CRACK + Vector3(-0.49, 1.1, 0), Vector3(0, -PI / 2, 0))
	_torch(Vector3(15.6, 1.8, -1.0))
	lever = Node3D.new()
	lever.position = LEVER_POS
	add_child(lever)
	Models.block(lever, Vector3(0, 0.4, 0), Vector3(0.5, 0.8, 0.5), _rock)
	var arm := Models.block(lever, Vector3(0, 1.1, 0), Vector3(0.08, 0.8, 0.08), Models.mat("rusty_metal_02", 0.5))
	arm.rotation.z = 0.5
	lever.set_meta("arm", arm)
	# the carving on the west wall
	var slab := Models.block(self, CARVING + Vector3(0.05, 1.6, 0), Vector3(0.12, 1.6, 2.4), Models.mat("medieval_blocks_05", 1.0, Color(0.7, 0.66, 0.6)))
	slab.name = "Carving"
	var runes := Label3D.new()
	runes.text = "<o>  =|=  ]-[\n~~ ^^ ~~ vv ~~"
	runes.font_size = 56
	runes.pixel_size = 0.006
	runes.modulate = Color(0.25, 0.2, 0.15)
	runes.rotation.y = PI / 2
	runes.position = CARVING + Vector3(0.13, 1.7, 0)
	add_child(runes)
	wood_sign("sign_seals_rope", "RESET\n(PULL)", ROPE + Vector3(0, 1.2, -0.3), 0.0, 0.9, 0.46, true)   # DRAFT
	Models.block(self, ROPE + Vector3(0.6, 1.8, -0.2), Vector3(0.05, 3.2, 0.05), Models.mat("rough_linen", 0.5, Color(0.7, 0.6, 0.45)))
	_torch(Vector3(-7.0, 1.8, -8.0))
	_torch(Vector3(7.0, 1.8, -8.0))
	_torch(Vector3(-7.0, 1.8, 1.0))
	# the sealed rat door
	door = Node3D.new()
	door.position = DOOR
	add_child(door)
	Models.block(door, Vector3(0, 1.6, 0), Vector3(3.2, 3.2, 0.6), Models.mat("castle_brick_07", 1.2, Color(0.55, 0.5, 0.45)))
	var dsign := Label3D.new()
	dsign.text = "NO HUMANS\n(ORCS, ELVES, DRAGONS ALSO NO)"   # DRAFT
	dsign.font_size = 40
	dsign.pixel_size = 0.005
	dsign.outline_size = 6
	dsign.modulate = Color("#e9d7a8")
	dsign.position = Vector3(0, 2.0, 0.32)
	door.add_child(dsign)
	door_body = StaticBody3D.new()
	var dcs := CollisionShape3D.new()
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(3.2, 3.0, 0.8)
	dcs.shape = dbs
	dcs.position = Vector3(0, 1.5, 0)
	door_body.add_child(dcs)
	door.add_child(door_body)
	# where the boulder you're next to would stop (Ebain 11/24: the puzzle was hard to read)
	push_ghost = Node3D.new()
	add_child(push_ghost)
	var gm := Util.mat(Color(0.6, 0.9, 1.0, 0.8))
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.emission_enabled = true
	gm.emission = Color(0.5, 0.85, 1.0)
	gm.emission_energy_multiplier = 1.4
	var gt := TorusMesh.new()
	gt.inner_radius = 0.55
	gt.outer_radius = 0.66
	Util.add_mesh(push_ghost, gt, gm, Vector3(0, 0.1, 0))
	var arrow := Label3D.new()
	arrow.text = "stops here"
	arrow.font_size = 30
	arrow.pixel_size = 0.006
	arrow.outline_size = 8
	arrow.modulate = Color("#9fe3ff")
	arrow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.no_depth_test = true
	arrow.position = Vector3(0, 0.6, 0)
	push_ghost.add_child(arrow)
	push_ghost.visible = false

func _free(c: Vector2i, moving: String) -> bool:
	if c.x < 0 or c.x >= COLS or c.y < 0 or c.y >= ROWS:
		return false
	if PILLARS.has(c):
		return false
	for s in boulders:
		if s != moving and boulders[s]["cell"] == c:
			return false
	return true

# Where a boulder pushed in `dir` would stop (slides until something stops it)
func slide_target(sym: String, dir: Vector2i) -> Vector2i:
	var c: Vector2i = boulders[sym]["cell"]
	while _free(c + dir, sym):
		c += dir
	return c

func push(sym: String, dir: Vector2i) -> bool:
	var b: Dictionary = boulders[sym]
	var to := slide_target(sym, dir)
	if to == b["cell"]:
		show_toast("It won't slide that way.", 1.4)   # DRAFT
		return false
	var steps: int = absi(to.x - b["cell"].x) + absi(to.y - b["cell"].y)
	b["cell"] = to
	progress_t = 0.0
	hint_level = mini(hint_level, 1)   # progress: next hint is about the new state
	not_read_said = false
	play_sound("sfx_door", -6.0, 0.45)
	var tw := create_tween()
	tw.tween_property(b["node"], "global_position", cell_pos(to), 0.13 * steps).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	shake = 0.15
	for u in party:   # nobody gets stuck inside a boulder
		if Vector2(u.global_position.x - b["node"].global_position.x, u.global_position.z - b["node"].global_position.z).length() < 0.95:
			u.global_position = leader.global_position if u != leader else leader.global_position - Vector3(dir.x, 0, dir.y) * 1.2
	return true

func all_on_plates() -> bool:
	for s in boulders:
		if boulders[s]["cell"] != PLATES[s]:
			return false
	return true

func _apply_puzzle_state() -> void:
	if Game.flag("sealsSolved"):
		for s in boulders:
			boulders[s]["cell"] = PLATES[s]
	elif Game.flag("sealsLever") and boulders["bowl"]["cell"] == B_START["bowl"]:
		boulders["bowl"]["cell"] = BOWL_ROLLED
	for s in boulders:
		boulders[s]["node"].global_position = cell_pos(boulders[s]["cell"])
	rubble.visible = not Game.flag("sealsLever")
	if Game.flag("sealsLever"):
		for b in rubble.find_children("*", "StaticBody3D", true, false):
			b.queue_free()
		(lever.get_meta("arm") as Node3D).rotation.z = -0.5
	for s in plate_marks:
		plate_marks[s].visible = Game.flag("sealsRead")
	if Game.flag("sealsSolved"):
		door.position.y = -3.3
		if is_instance_valid(door_body):
			door_body.queue_free()

# ---------------------------------------------------------------- the colony
func _build_colony() -> void:
	# the junk pile throne behind the king
	var jp := KING_POS + Vector3(0, 0, -3.0)
	var junk := [["wooden_crate_01", Vector3(-1.4, 0, 0), 1.2], ["wooden_crate_02", Vector3(1.3, 0, 0.2), 1.1], ["wine_barrel_01", Vector3(0, 0, -0.6), 1.2],
		["wooden_crate_01", Vector3(-0.5, 1.1, -0.2), 0.9], ["compost_bag_02", Vector3(2.4, 0, 0.6), 1.2], ["rusted_wheel_rim_01", Vector3(-2.5, 0, 0.4), 1.2],
		["wine_bottles_01", Vector3(0.9, 1.0, 0.1), 1.0], ["wooden_bucket_01", Vector3(-2.0, 0, 1.2), 0.9], ["wicker_basket_01", Vector3(2.0, 0, 1.5), 0.9]]
	for j in junk:
		Models.place(self, j[0], jp + j[1], randf() * TAU, j[2], false, Color(0.7, 0.62, 0.52))
	Util.static_box(self, jp + Vector3(0, 1, -0.2), Vector3(5.6, 2, 2.0))
	_torch(Vector3(-12.5, 1.8, -20.0))
	_torch(Vector3(12.5, 1.8, -20.0))
	_torch(Vector3(-12.5, 1.8, -33.0))
	_torch(Vector3(12.5, 1.8, -33.0))
	_torch(KING_POS + Vector3(-3.4, 2.2, -2.2))
	_torch(KING_POS + Vector3(3.4, 2.2, -2.2))
	# Scrounge's stall: crates, a shelf of junk, a lantern
	Models.place(self, "wooden_crate_02", STALL + Vector3(-0.8, 0, -0.9), 0.1, 1.0, true, Color(0.7, 0.62, 0.52))
	Models.place(self, "wooden_crate_02", STALL + Vector3(0.6, 0, -0.9), -0.1, 1.0, true, Color(0.7, 0.62, 0.52))
	Models.place(self, "wooden_display_shelves_01", STALL + Vector3(0, 0, -2.0), 0.0, 0.8, false, Color(0.7, 0.62, 0.52))
	Models.place(self, "wooden_lantern_01", STALL + Vector3(0.6, 0.75, -0.9), 0.0, 0.8)
	wood_sign("sign_scrounge", "SCROUNGE'S\nJUNK EMPORIUM", STALL + Vector3(0, 2.3, -1.4), 0.0, 1.8, 0.56)   # DRAFT
	var sl := OmniLight3D.new()
	sl.light_color = Color(1.0, 0.75, 0.45)
	sl.light_energy = 1.1
	sl.omni_range = 4.5
	sl.position = STALL + Vector3(0.6, 1.5, -0.6)
	add_child(sl)
	add_glow(STALL + Vector3(0, 1, 0), Color(1.0, 0.75, 0.45), 4.0, func(): return 0.7, true)
	# the tunnel up and out (daylight at the top of some steps)
	for k in 4:
		Models.block(self, TUNNEL_OUT + Vector3(0, 0.15 + k * 0.3, -0.6 - k * 0.6), Vector3(2.4, 0.3 + k * 0.6, 0.6), _rock_dark)
	var day := OmniLight3D.new()
	day.light_color = Color(1.0, 0.95, 0.85)
	day.light_energy = 2.2
	day.omni_range = 6.0
	day.position = TUNNEL_OUT + Vector3(0, 3.0, -2.0)
	add_child(day)
	add_glow(TUNNEL_OUT + Vector3(0, 1, -0.5), Color(1.0, 0.95, 0.85), 4.5, func(): return 0.8, true)
	# the secret shortcut (hidden behind junk until the "lore" outcome)
	shortcut_node = Node3D.new()
	add_child(shortcut_node)
	var dark := Util.mat(Color(0, 0, 0))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.4)
	Util.add_mesh(shortcut_node, q, dark, SHORTCUT + Vector3(0, 1.2, -1.4))
	var sq := Label3D.new()
	sq.text = "SECRET LORE TUNNEL\n(METOCY MART ROAD)"   # DRAFT
	sq.font_size = 34
	sq.pixel_size = 0.0055
	sq.outline_size = 8
	sq.modulate = Color("#c9b8ff")
	sq.position = SHORTCUT + Vector3(0, 2.8, -1.3)
	shortcut_node.add_child(sq)
	shortcut_node.visible = false
	# the Rat King, Scrounge and the colony
	king = spawn_npc("rat_king", "King Nibbsworth III", "rat_king", 1.45, KING_POS)
	king.set_meta("tag", _tag(king, "King Nibbsworth III (Rat King) (Musty)", 1.75))   # DRAFT
	trader = spawn_npc("rat_trader", "Scrounge", "rat_trader", 1.1, STALL + Vector3(0, 0, 0.2))
	trader.set_meta("tag", _tag(trader, "Scrounge (Licensed Trader) (License Is Fake)", 1.4))   # DRAFT
	var spots := [Vector3(-4.5, 0, -24), Vector3(4.2, 0, -23.5), Vector3(-2.6, 0, -27.5), Vector3(2.8, 0, -28.0), Vector3(-6.0, 0, -31),
		Vector3(6.4, 0, -30.5), Vector3(-9.5, 0, -20.5), Vector3(9.2, 0, -21.5), Vector3(5.5, 0, -35.0), Vector3(-5.0, 0, -35.5),
		Vector3(9.6, 0, -27.0), Vector3(-1.0, 0, -21.0)]
	var kinds := ["rat", "rat_fat", "rat", "rat_tiny", "rat", "rat_fat", "rat", "rat_tiny", "rat", "rat", "rat_fat", "rat_tiny"]
	var tags := ["Rat (Royal Guard)", "Rat (Royal Snack Taster)", "Rat (Unpaid Guard)", "Rat (Nephew)", "Rat (Cheese Sommelier)", "Rat (Big Back)",
		"Rat (Has a Podcast)", "Rat (Scared)", "Rat (Owes Scrounge Money)", "Rat (Just Vibing)", "Rat (Professional Squeaker)", "Rat (Smol)"]   # DRAFT
	for i in spots.size():
		var h: float = { "rat": 0.95, "rat_fat": 1.05, "rat_tiny": 0.62 }[kinds[i]]
		var u := spawn_npc(kinds[i], tags[i], kinds[i], h, spots[i])
		u.set_meta("tag", _tag(u, tags[i], h + 0.25))
		crowd.append(u)

func _tag(u: Unit, text: String, h: float) -> Label3D:
	var tag := Label3D.new()
	tag.text = text
	tag.font_size = 28
	tag.pixel_size = 0.0065
	tag.outline_size = 8
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate = Color("#ffcf9a")
	tag.position = Vector3(0, h, 0)
	u.add_child(tag)
	return tag

func _apply_colony_state() -> void:
	var done: String = str(Game.flags.get("ratsDone", ""))
	shortcut_node.visible = done == "lore"
	if done == "fight":
		king.global_position = KING_POS + Vector3(1.2, 0, 0.4)
		knock(king, 85.0, 0.01)
		trader.visible = false
		for u in crowd:
			u.visible = false
	elif done == "king":
		king.global_position = KING_POS + Vector3(-2.2, 0, 0.6)

# ---------------------------------------------------------------- after build
func _after_build() -> void:
	var env: Environment = world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_color = Color(0.42, 0.36, 0.38)
	env.ambient_light_energy = 0.75
	env.tonemap_exposure = 1.3
	env.fog_light_color = Color(0.02, 0.02, 0.025)
	env.fog_density = 0.018
	env.volumetric_fog_density = 0.018
	env.volumetric_fog_albedo = Color(0.9, 0.75, 0.6)
	env.glow_intensity = 0.8
	sun_light.light_energy = 0.0
	sun_light.shadow_enabled = false
	sun_light.visible = false
	_apply_puzzle_state()
	_apply_colony_state()
	for i in LOOT.size():
		loot_nodes[i].visible = not Game.flag("caveLoot%d" % i)
	var done: String = str(Game.flags.get("ratsDone", ""))
	if done == "" or done == "fight":   # the colony's patrols (friendly once you've made peace)
		spawn_roamers("rats", Vector3(0, 0, 19.0), 2.6)
		spawn_roamers("rats", Vector3(0, 0, 9.5), 2.2)

# ================================================================ story + play
func _begin() -> void:
	# fell through the floor of the ruins: everyone face-down in the landing chamber
	Game.set_flag("caveEntered")
	busy = true
	freeze_all(true)
	for u in party:
		knock(u, 85.0, 0.01)
	play_sound("sfx_punch", -2.0, 0.55)
	shake = 0.5
	fade_in(1.4)
	await wait(1.6)
	for u in party:
		unknock(u)
		hop(u, 0.25)
		await wait(0.2)
	await run_dialogue(RS.LANDED)
	_walk_objective()
	stage = "walk"

func _walk_objective() -> void:
	if Game.flags.has("ratsDone"):
		objective("Explore the colony, or take the tunnel up to the ruins.", TUNNEL_OUT)
	elif not Game.flag("sealsSolved"):
		if leader and leader.global_position.z < 4.0:
			objective("Open the sealed door: get each boulder onto its plate.", DOOR)
		else:
			objective("Find a way out of the cave.", PZ)
	else:
		objective("Go through the rat door.", DOOR + Vector3(0, 0, -4))

func _push_dir(sym: String) -> Vector2i:
	var d: Vector3 = boulders[sym]["node"].global_position - leader.global_position
	if absf(d.x) > absf(d.z):
		return Vector2i(1 if d.x > 0 else -1, 0)
	return Vector2i(0, 1 if d.z > 0 else -1)

func _level_interactables() -> Array:
	var list: Array = []
	if stage != "walk":
		return list
	var lp := leader.global_position
	if in_side_room:
		list.append({ "id": "lever", "label": "the lever", "verb": "Pull", "pos": LEVER_POS, "h": 1.6, "r": 1.8, "steps": RS.LEVER if not Game.flag("sealsLever") else [{ "do": "crack_out" }] })
		list.append({ "id": "crack_back", "label": "the crack", "verb": "Squeeze back through", "pos": SIDE_IN + Vector3(-1.2, 0, 0), "h": 1.8, "r": 1.6, "steps": [{ "do": "crack_out" }] })
		return list
	for i in LOOT.size():
		if not Game.flag("caveLoot%d" % i):
			list.append({ "id": "loot_%d" % i, "label": "the crate" if LOOT[i][0] == "crate" else "the junk", "verb": "Search", "pos": LOOT[i][1], "h": 1.4, "r": 2.0, "steps": [{ "do": "loot_%d" % i }] })
	if lp.z > 27.0:
		list.append({ "id": "rope_up", "label": "the rope", "verb": "Look at", "pos": LANDING + Vector3(0.3, 0, -1.5), "h": 1.4, "r": 2.0, "steps": RS.ROPE_UP })
	# the puzzle
	if not Game.flag("sealsSolved") and lp.z < 4.0 and lp.z > -11.0:
		for sym in boulders:
			var b: Dictionary = boulders[sym]
			if b["cell"].x >= COLS:   # still stuck in the alcove behind the rubble
				continue
			var steps: Array = [{ "do": "push_" + sym }]
			if b["big"] and leader.id != "skorn":
				steps = RS.BIG_NO[leader.id] + [{ "do": "hint_switch" }]
			list.append({ "id": "boulder_" + sym, "label": "the %s boulder" % ("BIG" if b["big"] else sym), "verb": "Push", "node": b["node"], "h": 1.9, "r": 1.75, "steps": steps })
		list.append({ "id": "carving", "label": "the carving", "verb": "Read" if leader.id == "xylo" else "Look at", "pos": CARVING + Vector3(0.6, 0, 0), "h": 2.4, "r": 1.8,
			"steps": RS.CARVING_AGAIN if Game.flag("sealsRead") else RS.CARVING[leader.id] })
		list.append({ "id": "rope", "label": "the reset rope", "verb": "Pull", "pos": ROPE, "h": 1.8, "r": 1.6, "steps": _rope_steps() })
		list.append({ "id": "door_look", "label": "the sealed door", "verb": "Look at", "pos": DOOR + Vector3(0, 0, 0.8), "h": 3.0, "r": 1.9, "steps": RS.DOOR_LOOK })
		if not Game.flag("sealsLever"):
			list.append({ "id": "crack", "label": "the crack in the wall", "verb": "Squeeze through" if leader.id == "lykor" else "Look at", "pos": CRACK, "h": 2.0, "r": 1.5,
				"steps": RS.CRACK_LYKOR if leader.id == "lykor" else RS.CRACK_NO[leader.id] })
	# the colony
	var done: String = str(Game.flags.get("ratsDone", ""))
	if done != "":
		if done != "fight":
			list.append({ "id": "king", "label": "King Nibbsworth III", "verb": "Talk to", "node": king, "h": 1.9, "r": 2.2, "steps": RS.KING_TALK.get(done, RS.KING_TALK["trade"]) })
			list.append({ "id": "trader", "label": "Scrounge's Junk Emporium", "verb": "Shop at", "node": trader, "h": 1.6, "r": 2.2, "steps": [{ "do": "shop" }] })
			for i in crowd.size():
				if crowd[i].visible:
					list.append({ "id": "rat_%d" % i, "label": crowd[i].display_name, "verb": "Talk to", "node": crowd[i], "h": crowd[i].height_m + 0.4, "r": 1.4, "steps": RS.RAT_CHATTER[i % RS.RAT_CHATTER.size()] })
		else:
			list.append({ "id": "stall", "label": "Scrounge's stall", "verb": "Look at", "pos": STALL, "h": 1.6, "r": 2.2, "steps": RS.TRADER_GONE })
		list.append({ "id": "tunnel_out", "label": "the tunnel up", "verb": "Climb", "pos": TUNNEL_OUT, "h": 2.4, "r": 2.0, "steps": RS.TUNNEL_OUT })
		if done == "lore":
			list.append({ "id": "shortcut", "label": "the secret lore tunnel", "verb": "Take", "pos": SHORTCUT, "h": 2.6, "r": 2.0, "steps": RS.SHORTCUT })
	if is_instance_valid(pet):
		list.append({ "id": "pet", "label": "Lil Nibbs", "verb": "Talk to", "node": pet, "h": 1.0, "r": 1.2, "steps": RS.PET_CHATTER[0] })
	return list

func _level_process(delta: float) -> void:
	for i in torches.size():
		torches[i][0].light_energy = torches[i][1] * (0.85 + 0.1 * sin(t * 11.0 + i * 2.3) + 0.05 * sin(t * 23.0 + i))
	var near_colony := leader != null and leader.global_position.z < -8.0   # colony name tags only once you're close
	for u in crowd + [king, trader]:
		u.get_meta("tag").visible = near_colony
	if leader:
		lead_light.global_position = leader.global_position + Vector3(0, 2.2, 0.4)
		lead_glow["pos"] = leader.global_position + Vector3(0, 1.0, 0)
	if busy or stage != "walk" or in_side_room:
		return
	var lp := leader.global_position
	var in_chamber: bool = not Game.flag("sealsSolved") and lp.z < 4.0 and lp.z > -11.0
	_followers_wait(in_chamber)
	_update_ghost(in_chamber)
	if in_chamber:   # in the puzzle chamber: a hint every 30 s stuck, the skip after 3 min
		progress_t += delta
		puzzle_t += delta
		if objective_lbl.text.find("Find a way") >= 0:
			_walk_objective()
		if puzzle_t > SKIP_AFTER and not skip_offered:
			skip_offered = true
			progress_t = 0.0
			run_dialogue(_skip_offer())
		elif progress_t > HINT_EVERY:
			progress_t = 0.0
			hint_level += 1
			run_dialogue(RS.HINT[leader.id] if hint_level == 1 else _next_move_hint())
	if Game.flag("sealsSolved") and not Game.flags.has("ratsDone") and lp.z < COLONY_Z:
		_colony_scene()

func _on_action(n: String) -> void:
	if n.begins_with("loot_"):
		var i := int(n.substr(5))
		var L: Array = LOOT[i]
		Game.set_flag("caveLoot%d" % i)
		loot_nodes[i].visible = false
		Game.add_gold(L[2])
		var msg := "+%d gold" % L[2]
		if L[3] != "":
			Game.add_item(L[3], 1)
			msg += " · %s got: %s" % [CombatD.PARTY[Game.active_fighter]["name"], CombatD.ITEMS[L[3]]["name"]]
		if L[4] != "":
			Game.give_gear(L[4])
			msg += " · %s got: %s" % [CombatD.PARTY[Game.active_fighter]["name"], CombatD.GEAR[L[4]]["name"]]
		ui_sfx.play()
		show_toast(msg, 2.6)
		await wait(0.3)
		return
	if n.begins_with("push_"):
		var sym := n.substr(5)
		await push(sym, _push_dir(sym))
		await _check_solved()
		return
	match n:
		"hint_switch":
			show_toast("Only Skorn can push this one. (Q switches who you control)", 2.4)
		"read_carving":
			Game.set_flag("sealsRead")
			progress_t = 0.0
			for s in plate_marks:
				plate_marks[s].visible = true
				hop(plate_marks[s], 0.2)
			play_sound("sfx_magic", -6.0)
			await wait(0.8)
			if all_on_plates():
				await _solved()
		"reset":
			await _reset()
		"skip_puzzle":
			await _skip_puzzle()
		"crack_in":
			await _crack_in()
		"crack_out":
			await _crack_out()
		"pull_lever":
			await _pull_lever()
		"door_open":
			await _door_open()
		"colony_fight":
			await _colony_fight()
		"crown_skorn":
			Game.set_flag("ratsDone", "king")
			var sk := _member("skorn")
			walk_to(king, KING_POS + Vector3(-2.2, 0, 0.6), 1.0, 3.0)
			await walk_to(sk, KING_POS, 1.0, 4.0)
			sk.global_position = KING_POS
			char_label(sk, "(Rat King)", 0.0, sk.height_m + 0.35, Color("#ffd27a"))
			Game.give_gear("bottlecap_crown", "skorn")
			show_toast("Skorn got: Bottle-Cap Crown", 2.2)
			for u in crowd:
				hop(u, 0.35)
			play_sound("sfx_reward", -4.0)
			await wait(0.6)
		"trade_deal":
			Game.set_flag("ratsDone", "trade")
			hop(trader, 0.4)
			show_toast("Scrounge opened the good shelf.", 2.0)
			await wait(0.4)
		"lore_win":
			Game.set_flag("ratsDone", "lore")
			Game.add_gold(40)
			show_toast("+40 gold (the King paid for the lecture)", 2.2)
			await _poof(SHORTCUT + Vector3(0, 1, 0))
			shortcut_node.visible = true
			focus_override = SHORTCUT
			await wait(1.4)
			focus_override = (KING_POS + leader.global_position) * 0.5
		"mog_rats":
			Game.set_flag("ratsDone", "mog")
			var ly := _member("lykor")
			ly.set_pose(load("res://assets/characters/lykor_mog.png"), 1.95)
			play_sound("sfx_magic", -4.0, 0.8)
			focus_override = ly.global_position
			zoom = 6.0
			await wait(1.6)
			for u in crowd + [king, trader]:
				char_label(u, "(Mogged)", 2.2, u.height_m + 0.3, Color("#ff9ad5"))
				hop(u, 0.3)
			await wait(1.2)
			ly.restore_views()
			zoom = 10.0
			focus_override = (KING_POS + leader.global_position) * 0.5
		"pet_joins":
			Game.set_flag("ratPet")
			spawn_pet()
			if is_instance_valid(pet):
				pet.global_position = leader.global_position + Vector3(1.0, 0, 1.0)
				hop(pet, 0.4)
			show_toast("Lil Nibbs joined the party. (He's not a fighter. He's a fan.)", 2.6)   # DRAFT
		"colony_after":
			focus_override = null
			follow_enabled = true
			switch_enabled = true
			stage = "walk"
			_walk_objective()
			if not shots_mode:
				Game.save_game("auto", self)
		"shop":
			await _open_shop()
		"tunnel_out":
			stage = "end"
			busy = true
			await fade_out(0.6)
			Game.travel("res://ruins.tscn", "cave", leader.id)
		"shortcut_out":
			stage = "end"
			busy = true
			await fade_out(0.6)
			Game.travel("res://mart.tscn", "ruins", leader.id)

func _member(id: String) -> Unit:
	for u in party:
		if u.id == id:
			return u
	return leader

func _poof(p: Vector3) -> void:
	var f := Fx.poof(Color(0.6, 0.55, 0.5))
	add_child(f)
	f.global_position = p
	f.emitting = true
	play_sound("sfx_pop", -6.0)
	await wait(0.3)

# ---- puzzle actions
func _check_solved() -> void:
	if not all_on_plates():
		return
	if Game.flag("sealsRead"):
		await _solved()
	elif not not_read_said:
		not_read_said = true
		await run_nested(RS.NOT_READ)

func _solved() -> void:
	if Game.flag("sealsSolved"):
		return
	await run_nested(RS.SOLVED)

# ---- puzzle help (Ebain 11/24: "honestly couldn't figure out the boulder puzzle")
# Followers wait by the entrance while you're in the chamber, so they're not in the way of the boulders.
const WAIT_SPOTS := [Vector3(-5.6, 0, 2.3), Vector3(5.6, 0, 2.3)]
func _followers_wait(on: bool) -> void:
	var i := 0
	for u in party:
		if u == leader:
			if u.has_meta("waiting"):
				u.remove_meta("waiting"); u.remove_meta("goal")
			continue
		if on:
			u.set_meta("waiting", true)
			u.set_meta("goal", WAIT_SPOTS[i % 2])
			u.set_meta("goal_speed", 0.8)
		elif u.has_meta("waiting"):
			u.remove_meta("waiting"); u.remove_meta("goal")
		i += 1

# The ring that shows where the boulder you're next to would stop if you pressed E now.
func _update_ghost(on: bool) -> void:
	push_ghost.visible = false
	if not on or busy:
		return
	var it := _nearest_interactable()
	var id: String = it.get("id", "")
	if not id.begins_with("boulder_"):
		return
	var sym := id.substr(8)
	if boulders[sym]["big"] and leader.id != "skorn":
		return
	var to := slide_target(sym, _push_dir(sym))
	if to == boulders[sym]["cell"]:
		return
	push_ghost.global_position = cell_pos(to)
	push_ghost.visible = true

# Shortest way from here to all-on-plates (breadth-first over boulder positions, ~2.5k states). Returns
# [sym, dir] for the next push, or [] if there's no way from this state (time to pull the reset rope).
func solve_next() -> Array:
	var syms: Array = []
	for s in boulders:
		if boulders[s]["cell"].x < COLS:
			syms.append(s)
	var start: Array = syms.map(func(s): return boulders[s]["cell"])
	var goal: Array = syms.map(func(s): return PLATES[s])
	if start == goal:
		return []
	var prev := { str(start): null }
	var q: Array = [start]
	var found := false
	while not q.is_empty():
		var st: Array = q.pop_front()
		for i in syms.size():
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var behind: Vector2i = st[i] - d
				if PILLARS.has(behind) or st.has(behind):   # you have to stand on the other side to push
					continue
				var c: Vector2i = st[i]
				while _free_in(c + d, st, i):
					c += d
				if c == st[i]:
					continue
				var n := st.duplicate()
				n[i] = c
				var key := str(n)
				if prev.has(key):
					continue
				prev[key] = [st, i, d]
				if n == goal:
					found = true
					break
				q.append(n)
			if found: break
		if found: break
	if not found:
		return []
	var k := str(goal)
	var step: Array = prev[k]
	while prev[str(step[0])] != null:
		step = prev[str(step[0])]
	return [syms[step[1]], step[2]]

func _free_in(c: Vector2i, st: Array, moving: int) -> bool:
	if c.x < 0 or c.x >= COLS or c.y < 0 or c.y >= ROWS or PILLARS.has(c):
		return false
	for j in st.size():
		if j != moving and st[j] == c:
			return false
	return true

const DIR_WORD := { Vector2i(0, -1): "toward the door", Vector2i(0, 1): "toward the entrance", Vector2i(-1, 0): "left (west)", Vector2i(1, 0): "right (east)" }
const SIDE_WORD := { Vector2i(0, -1): "the entrance side", Vector2i(0, 1): "the door side", Vector2i(-1, 0): "its right side", Vector2i(1, 0): "its left side" }
func _next_move_hint() -> Array:
	var who: String = leader.id
	if not Game.flag("sealsRead"):
		return [{ "who": who, "line": "Somebody gotta read that carving on the west wall first. That's a Xylo job." }]   # DRAFT
	if not Game.flag("sealsLever"):
		return [{ "who": who, "line": "The bowl boulder's stuck behind that rubble. There's a crack in the east wall only Lykor fits through." }]   # DRAFT
	var mv := solve_next()
	if mv.is_empty():
		return [{ "who": who, "line": "Yeah, we cooked it. A boulder's stuck where it can't come back. Pull the reset rope." }]   # DRAFT
	var sym: String = mv[0]
	var d: Vector2i = mv[1]
	var name := "BIG spoon boulder" if boulders[sym]["big"] else "%s boulder" % sym
	var line := "Next move: push the %s %s. Stand on %s and press E." % [name, DIR_WORD[d], SIDE_WORD[d]]   # DRAFT
	if boulders[sym]["big"] and who != "skorn":
		line += " That one's Skorn's. Q to switch."
	return [{ "who": who, "line": line }]

func _skip_offer() -> Array:
	return [
		{ "who": leader.id, "line": "We been at these rocks a minute. Want to just… not?" },   # DRAFT
		{ "choice": [
			{ "text": "Skip the puzzle", "steps": [{ "do": "skip_puzzle" }] },
			{ "text": "Keep trying (the reset rope can skip it later)", "steps": [] },
		] },
	]

func _rope_steps() -> Array:
	if puzzle_t < SKIP_AFTER:
		return RS.RESET
	return [{ "choice": [
		{ "text": "Reset the boulders", "steps": RS.RESET },
		{ "text": "Skip the puzzle", "steps": [{ "do": "skip_puzzle" }] },
		{ "text": "Never mind", "steps": [] },
	] }]

func _skip_puzzle() -> void:
	Game.set_flag("sealsRead")
	Game.set_flag("sealsLever")
	for s in boulders:
		boulders[s]["cell"] = PLATES[s]
	await _poof(PZ + Vector3(0, 1, 0))
	_apply_puzzle_state()
	push_ghost.visible = false
	await _solved()

func _reset() -> void:
	var rat := spawn_npc("rat_tiny", "Rat (Reset Guy)", "rat_tiny", 0.62, ROPE + Vector3(0.9, 0, -0.6))
	hop(rat, 0.4)
	play_sound("sfx_pop", -6.0)
	for s in boulders:
		var to: Vector2i = B_START[s]
		if s == "bowl" and Game.flag("sealsLever"):
			to = BOWL_ROLLED
		boulders[s]["cell"] = to
		var tw := create_tween()
		tw.tween_property(boulders[s]["node"], "global_position", cell_pos(to), 0.5)
	not_read_said = false
	progress_t = 0.0
	await wait(0.6)
	_rat_leaves(rat)   # not awaited: it hangs around for its "skill issue" line, then goes

func _rat_leaves(rat: Unit) -> void:
	await wait(3.5)
	if is_instance_valid(rat):
		npcs.erase(rat)
		rat.queue_free()

func _crack_in() -> void:
	busy = true
	await fade_out(0.4)
	var ly := _member("lykor")
	follow_enabled = false
	switch_enabled = false
	in_side_room = true
	set_leader(ly)
	ly.global_position = SIDE_IN
	cam_target = SIDE_IN
	fade_in(0.4)
	objective("Pull the lever.", LEVER_POS)
	busy = false

func _crack_out() -> void:
	busy = true
	await fade_out(0.4)
	in_side_room = false
	leader.global_position = CRACK + Vector3(-1.1, 0, 0)
	cam_target = leader.global_position
	follow_enabled = true
	switch_enabled = true
	fade_in(0.4)
	_walk_objective()
	busy = false

func _pull_lever() -> void:
	var arm: Node3D = lever.get_meta("arm")
	var tw := create_tween()
	tw.tween_property(arm, "rotation:z", -0.5, 0.3)
	play_sound("sfx_door", -4.0, 0.6)
	await wait(0.6)
	Game.set_flag("sealsLever")
	progress_t = 0.0
	await fade_out(0.4)
	in_side_room = false
	leader.global_position = CRACK + Vector3(-1.1, 0, 1.2)
	cam_target = leader.global_position
	focus_override = cell_pos(Vector2i(6, 3))
	fade_in(0.4)
	await wait(0.5)
	# the rubble drops into a crack in the floor, the boulder rolls out of its alcove
	play_sound("sfx_fire_explosion", -10.0, 0.6)
	shake = 0.4
	await _poof(cell_pos(B_START["bowl"]) + Vector3(-0.7, 0.5, 0))
	rubble.visible = false
	for b in rubble.find_children("*", "StaticBody3D", true, false):
		b.queue_free()
	await push("bowl", Vector2i(-1, 0))
	await wait(0.4)
	follow_enabled = true
	switch_enabled = true
	await run_nested(RS.LEVER_DONE)
	focus_override = null
	_walk_objective()

func _door_open() -> void:
	Game.set_flag("sealsSolved")
	focus_override = DOOR + Vector3(0, 0, 2)
	play_sound("sfx_fire_explosion", -8.0, 0.4)
	shake = 0.8
	var tw := create_tween()
	tw.tween_property(door, "position:y", -3.3, 2.2).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(door_body):
		door_body.queue_free()
	await tw.finished
	for u in crowd.slice(0, 3):   # rats on the other side scatter
		hop(u, 0.4)
	focus_override = null
	_walk_objective()

# ---- the colony scene
func _colony_scene() -> void:
	stage = "busy"
	busy = true
	follow_enabled = false
	focus_override = (KING_POS + leader.global_position) * 0.5
	for u in crowd:
		char_label(u, "!", 1.0, u.height_m + 0.5, Color("#ff5a3a"))
	await run_dialogue(RS.COLONY)
	if stage != "walk":   # the choice's own steps end with colony_after; this is just a safety net
		_on_action("colony_after")

func _colony_fight() -> void:
	var guards: Array = [crowd[0], crowd[1]]
	for u in crowd.slice(2):   # the rest of the colony runs off to watch from a safe distance
		u.set_meta("goal", u.global_position + Vector3(0, 0, -4))
	for i in 2:
		guards[i].global_position = KING_POS + Vector3(-1.6 + i * 3.2, 0, 1.2)
	var res := await fight("rat_colony", { "enemies": [king, guards[0], guards[1]] })
	Game.set_flag("ratsDone", "fight")
	for u in crowd:
		u.remove_meta("goal")
	if res == "talked":
		show_toast("The rats are too busy eating to care anymore.", 2.4)
	knock(king, 85.0, 0.3)
	await wait(1.0)
	for u in crowd:
		if u.visible:
			var f := Fx.poof()
			add_child(f)
			f.global_position = u.global_position + Vector3(0, 0.4, 0)
			f.emitting = true
			u.visible = false
	trader.visible = false
	play_sound("sfx_pop", -6.0)

func _open_shop() -> void:
	var done: String = str(Game.flags.get("ratsDone", ""))
	var stock := [["beer", "item", 6], ["bowl", "item", 12], ["cave_cheese", "item", 40],
		["thimble_helm", "gear", 90], ["toothpick_spear", "gear", 160], ["bottlecap_mail", "gear", 210]]
	if done == "trade":   # the good shelf
		stock += [["lucky_crumb", "gear", 120], ["corncob_scepter", "gear", 300]]
	await ShopUI.open_shop(self, {
		"stock": stock,
		"title": "SCROUNGE'S JUNK EMPORIUM",   # DRAFT
		"broke": "Scrounge: \"No gold? I also accept crumbs. You don't have crumbs.\"",   # DRAFT
		"discount": 0.5 if done == "king" else 1.0,
	})

# ---------------------------------------------------------------- walking between areas + saves
func can_resume() -> bool:
	return stage == "walk" and not in_side_room

func can_resume_saved() -> bool:
	return Game.flag("caveEntered")

func _resume(r: Dictionary) -> void:
	stage = "walk"
	_walk_objective()
	await super._resume(r)
	_walk_objective()
	if r.get("from", "") == "hole":
		knock(leader, 85.0, 0.01)
		play_sound("sfx_punch", -2.0, 0.55)
		shake = 0.4
		await wait(0.8)
		unknock(leader)
		await run_dialogue(RS.HOLE_AGAIN)

func arrival(from: String) -> Array:
	if from == "tunnel":
		return [TUNNEL_OUT + Vector3(-1.0, 0, 3.5), Vector3(0, 0, 1)]
	return [LANDING, Vector3(0, 0, -1)]

func map_buildings() -> Array:
	return [{ "pos": DOOR, "name": "The Three Seals" }, { "pos": STALL, "name": "Scrounge's" }, { "pos": KING_POS, "name": "Rat King" }]

func map_skip(u: Unit) -> bool:
	return crowd.has(u)

# ---------------------------------------------------------------- automated screenshots
# RUINS_CHOICE=0..4 picks the rat choice (fight / king / trade / lore / mog).
# Solves the puzzle with scripted pushes, the way a player would (switching to Skorn / Lykor / Xylo).
func _shot_tour() -> void:
	var choice := int(OS.get_environment("RUINS_CHOICE")) if OS.get_environment("RUINS_CHOICE") != "" else 1
	fade.color.a = 0.0
	Game.set_flag("caveEntered")
	for g in roamers:   # keep the patrols out of the scripted walk
		g["done"] = true
		for u in g["units"]: u.visible = false
	busy = false
	stage = "walk"
	await wait(1.5)
	await shot("c_01_landing")
	place_party(Vector3(0, 0, 14), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("c_02_tunnel")
	place_party(PZ + Vector3(0, 0, 5.2), Vector3(0, 0, -1))
	await wait(1.2)
	await shot("c_03_puzzle")
	# Xylo reads the carving
	_tour_lead("xylo", CARVING + Vector3(1.2, 0, 0))
	await _tour_use("carving", 3)
	print("CAVE read=", Game.flag("sealsRead"))
	# Lykor through the crack, lever
	_tour_lead("lykor", CRACK + Vector3(-0.9, 0, 0))
	await _tour_use("crack", 1)
	await wait(1.2)
	await _tour_use("lever", 1)
	await wait(1.0)
	for k in 6:
		await advance(1, 0.5)
	await wait(1.0)
	await shot("c_04_lever")
	print("CAVE lever=", Game.flag("sealsLever"), " bowl=", boulders["bowl"]["cell"])
	# the pushes: [who, boulder, direction]
	var plan := [["xylo", "book", Vector2i(-1, 0)], ["xylo", "book", Vector2i(0, 1)], ["skorn", "spoon", Vector2i(-1, 0)],
		["skorn", "spoon", Vector2i(0, -1)], ["lykor", "bowl", Vector2i(0, -1)], ["lykor", "bowl", Vector2i(1, 0)], ["lykor", "bowl", Vector2i(0, -1)]]
	for st in plan:
		var b: Dictionary = boulders[st[1]]
		var behind: Vector3 = b["node"].global_position - Vector3(st[2].x, 0, st[2].y) * 1.3
		_tour_lead(st[0], behind)
		await wait(0.3)
		if _push_dir(st[1]) != st[2]:
			print("CAVE push dir mismatch ", st)
		start(current_interactables().filter(func(i): return i["id"] == "boulder_" + st[1])[0])
		await wait(1.6)
		for k in 8:
			if dialogue.active: await advance(1, 0.5)
		print("CAVE pushed ", st[1], " -> ", b["cell"])
	await wait(2.5)
	for k in 8:
		if dialogue.active: await advance(1, 0.5)
	await wait(1.0)
	await shot("c_05_solved")
	print("CAVE solved=", Game.flag("sealsSolved"))
	if not Game.flag("sealsSolved"):
		get_tree().quit()
		return
	place_party(Vector3(0, 0, -15.0), Vector3(0, 0, -1))
	await wait(1.5)
	for k in 7:
		await advance(1, 0.6)
	await wait(0.6)
	await shot("c_06_colony")
	dialogue._picked.emit(mini(choice, dialogue._choices.size() - 1))
	for k in 300:   # the colony fight can run a while
		await advance(1, 0.7)
		if k == 3:
			await shot("c_07_choice_%d" % choice)
		if Game.flags.has("ratsDone") and stage == "walk" and not dialogue.active:
			break
	await wait(1.5)
	await shot("c_08_after_%d" % choice)
	if choice != 0:
		place_party(STALL + Vector3(0, 0, 2.0), Vector3(0, 0, -1))
		await wait(0.8)
		await _tour_use("trader", 0)
		await wait(0.5)
	print("CAVE TOUR choice=", choice, " ratsDone=", Game.flags.get("ratsDone", ""), " pet=", Game.flag("ratPet"), " gold=", Game.gold, " xp=", Game.xp,
		" crown=", Game.gear_owned.has("bottlecap_crown"))
	get_tree().quit()

func _tour_lead(id: String, p: Vector3) -> void:
	var u := _member(id)
	if u != leader:
		set_leader(u)
	u.global_position = p
	cam_target = p

func _tour_use(id: String, lines: int) -> void:
	await wait(0.4)
	var its: Array = current_interactables().filter(func(i): return i["id"] == id)
	if its.is_empty():
		print("CAVE missing interactable ", id)
		return
	start(its[0])
	await advance(lines, 0.6)
	await wait(0.8)
