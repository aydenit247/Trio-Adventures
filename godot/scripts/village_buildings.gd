# The explorable Goblin Village (after the throne scene): six places to poke around.
#   1 Chief's Hut (outside only, closed: Asar)  2 Unemployment Office & Bar (room)   3 Job Board (outside, JobBoardUI)
#   4 Shaman's Tent (room)                      5 The Outhouse (outside, door only)   + a bedroll by the Chief's Hut (rest)
# (Clank's Spoonsmithy was removed 2026-11-22, Asar. Spoon Mail now drops from the Goblin Patrol.)
# Rooms are built far off to the side (x = 400+) like the Mart interior; walking through a door fades you there.
# Everything is PLACEHOLDER art (shapes + reused cutouts) until Ebain sends hut exteriors and room backdrops.
#
# village.gd owns this node: build() in _build_level, interactables() while stage == "after",
# on_action(n) for anything village.gd doesn't handle, process(delta) every frame.
extends Node

const R = preload("res://scripts/village_rooms_script.gd")
const ROOM_W := 14.0     # x: -7..7
const BACK_Z := -4.6
const FRONT_Z := 4.6

# Outside: where each building sits and where its door is
const BUILDINGS := {
	"chief": { "name": "Chief's Hut", "pos": Vector3(-5.5, 0, -14.5), "door": Vector3(-5.2, 0, -12.0), "room": 0, "closed": true },   # can't go in (Asar)
	"bar": { "name": "Unemployment Office & Bar", "pos": Vector3(-11.0, 0, -5.0), "door": Vector3(-8.3, 0, -3.9), "room": 1 },
	"shaman": { "name": "Shaman's Tent", "pos": Vector3(7.0, 0, -15.0), "door": Vector3(6.6, 0, -12.6), "room": 2 },
}
const OUTHOUSE_POS := Vector3(12.8, 0, 7.8)
const BOARD_POS := Vector3(4.2, 0, -4.6)
const HOUSE_POS := Vector3(10.5, 0, -6.5)
const STALL_POS := Vector3(-5.6, 0, 3.4)   # Haggle's market stall in the square (Asar: the shop, instead of a Goblin Pit)
const STALL_YAW := 1.1                     # counter faces the square / campfire
const BEDROLL_POS := Vector3(-2.2, 0, -11.6)       # rest spot by the Chief's Hut (replaces his hay bed)
const CONDITIONER_POS := Vector3(-1.4, 0, -10.6)   # the Backup Conditioner used to be in the Chief's chest

var lv          # the village (Level)
var room := ""  # "" = outside, else a BUILDINGS key
var npc := {}   # name -> Unit
var gorbo_heckles := 0
var lore_wrong := 0
var conditioner_node: Node3D
var _outdoor := {}   # saved sun/ambient while indoors

func origin(id: String) -> Vector3:
	return Vector3(400.0 + BUILDINGS[id]["room"] * 40.0, 0, 0)

# ================================================================ building it all
func build() -> void:
	_outside()
	for id in BUILDINGS:
		if not BUILDINGS[id].get("closed", false):
			_room_shell(id)
	_bar_room()
	_shaman_room()

func _outside() -> void:
	var clay := Models.mat("clay_plaster", 2.5)
	var logs := Models.mat("wood_trunk_wall", 2.0)
	var stone := Models.mat("rustic_stone_wall", 2.0)
	var planks := Models.mat("weathered_planks", 1.5)
	# Chief's Hut: biggest round hut, log walls, royal banners
	var c: Dictionary = BUILDINGS["chief"]
	_round_hut(c["pos"], 2.3, 2.5, logs, c["door"])
	for s in [-1.0, 1.0]:
		_quad(c["pos"] + Vector3(s * 1.5, 1.7, 2.0), Vector2(0.55, 1.4), Color(0.6, 0.12, 0.1))
	Models.place(lv, "wooden_lantern_01", c["door"] + Vector3(1.0, 0, 0.2), 0.0, 1.0)
	# Bar: round clay hut, barrels and crates out front, a hanging sign
	var b: Dictionary = BUILDINGS["bar"]
	_round_hut(b["pos"], 2.6, 2.3, clay, b["door"])
	Models.place(lv, "wine_barrel_01", b["door"] + Vector3(-0.2, 0, 1.4), 0.4, 1.0, true)
	Models.place(lv, "wine_barrel_01", b["door"] + Vector3(0.6, 0, 1.7), 1.2, 1.0, true)
	Models.place(lv, "wooden_crate_02", b["door"] + Vector3(-1.4, 0, 1.0), 0.3, 1.0, true)
	Models.block(lv, b["door"] + Vector3(1.0, 2.2, -0.6), Vector3(1.5, 0.6, 0.06), planks)
	_label3d("OPEN 24/7\n(nobody has anywhere to be)", b["door"] + Vector3(1.0, 2.2, -0.55), 26, Color("#ffdf8a"), false)
	# Shaman: a purple cloth tent with a spooky glow
	var sh: Dictionary = BUILDINGS["shaman"]
	Models.cylinder(lv, sh["pos"], 2.4, 0.06, 3.6, Models.mat("fabric_pattern_07", 1.2, Color(0.5, 0.3, 0.68)), 12)
	Util.static_cyl(lv, sh["pos"], 2.2, 2.5)
	_door(sh["pos"], 2.15, sh["door"], 1.0)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.6, 0.3, 1.0)
	gl.light_energy = 1.4
	gl.omni_range = 4.0
	gl.position = sh["door"] + Vector3(0, 1.0, 0.3)
	lv.add_child(gl)
	Models.place(lv, "ceramic_pot", sh["door"] + Vector3(1.3, 0, 0.0), 0.5, 1.0)
	Models.place(lv, "wicker_basket_01", sh["door"] + Vector3(-1.2, 0, 0.3), 0.0, 1.4)
	# Locked house
	_round_hut(HOUSE_POS, 1.9, 2.1, clay, HOUSE_POS + Vector3(-1.3, 0, 1.6))
	# Outhouse: weathered planks, a little roof, a door with a moon
	Models.block(lv, OUTHOUSE_POS + Vector3(0, 1.15, 0), Vector3(1.3, 2.3, 1.3), planks, 0.0, true)
	Models.block(lv, OUTHOUSE_POS + Vector3(0, 2.4, 0), Vector3(1.7, 0.16, 1.7), Models.mat("weathered_planks", 1.0, Color(0.7, 0.6, 0.5)))
	Models.block(lv, OUTHOUSE_POS + Vector3(0, 1.05, 0.66), Vector3(0.82, 1.9, 0.05), Models.mat("weathered_planks", 0.8, Color(1.1, 1.0, 0.9)))
	_label3d("(moon)", OUTHOUSE_POS + Vector3(0, 1.75, 0.7), 26, Color(0.12, 0.07, 0.03), false)
	# Job Board: two posts, a plank board, papers pinned all over it
	for s in [-0.75, 0.75]:
		Models.block(lv, BOARD_POS + Vector3(s, 0.95, 0), Vector3(0.14, 1.9, 0.14), planks)
	Models.block(lv, BOARD_POS + Vector3(0, 1.35, 0), Vector3(1.8, 1.0, 0.08), planks)
	Util.static_box(lv, BOARD_POS + Vector3(0, 1, 0), Vector3(1.8, 2, 0.4))
	var paper := Color(0.72, 0.66, 0.52)
	for k in 7:
		var q := QuadMesh.new()
		q.size = Vector2(randf_range(0.22, 0.34), randf_range(0.26, 0.38))
		Util.add_mesh(lv, q, Util.mat(paper * randf_range(0.85, 1.0)), BOARD_POS + Vector3(-0.65 + k * 0.22, 1.35 + randf_range(-0.25, 0.25), 0.05), Vector3(0, 0, randf_range(-0.2, 0.2)))
	lv.wood_sign("job_board", "JOB BOARD", BOARD_POS + Vector3(0, 2.12, 0.06), 0.0, 1.7, 0.42)
	npc["grubnik"] = _goblin("grubnik", "Grubnik (Lost His Lucky Spoon)", BOARD_POS + Vector3(1.3, 0, 0.9), 1.05, Color(0.9, 1.0, 0.85))
	# little bits of village life
	Models.place(lv, "wooden_crate_01", Vector3(2.0, 0, 6.2), 0.6, 1.0, true)
	Models.place(lv, "wooden_bucket_01", Vector3(7.8, 0, 4.4), 0.0, 1.0)
	Models.place(lv, "wine_barrel_01", Vector3(-7.4, 0, 7.6), 0.0, 1.0, true)
	Models.place(lv, "wooden_crate_02", Vector3(9.0, 0, -9.6), 1.1, 1.0, true)
	# wooden name signs (Asar): over each hut's door, facing out the way the door does; the tent gets one on a post
	const SIGN_TEXT := { "chief": "CHIEF'S HUT\n(CLOSED)", "bar": "UNEMPLOYMENT\nOFFICE & BAR", "shaman": "SHAMAN'S\nTENT" }
	for id in BUILDINGS:
		var d: Dictionary = BUILDINGS[id]
		var out: Vector3 = d["door"] - d["pos"]
		out.y = 0.0
		out = out.normalized()
		var yaw := atan2(out.x, out.z)
		if id == "shaman":   # cloth tent: a sign on a post beside the door
			lv.wood_sign("sign_" + id, SIGN_TEXT[id], d["door"] + out * 0.6 + Vector3(out.z, 0, -out.x) * 1.9 + Vector3(0, 1.6, 0), yaw, 1.6, 0.75, true)
		else:
			lv.wood_sign("sign_" + id, SIGN_TEXT[id], d["door"] + out * 0.12 + Vector3(0, 2.8, 0), yaw, 2.2, 0.8)
	lv.wood_sign("sign_outhouse", "OUTHOUSE\n(SMELLS)", OUTHOUSE_POS + Vector3(0, 2.0, 0.7), 0.0, 1.1, 0.5)
	var hd: Vector3 = (HOUSE_POS + Vector3(-1.3, 0, 1.6) - HOUSE_POS).normalized()
	lv.wood_sign("sign_goblin_house", "DO NOT DISTURB\n(NAPPING)", HOUSE_POS + Vector3(-1.3, 0, 1.6) + hd * 0.1 + Vector3(0, 2.45, 0), atan2(hd.x, hd.z), 1.6, 0.6)
	_bedroll(BEDROLL_POS)
	_stall()
	if not Game.flag("conditionerFound"):
		conditioner_node = Models.place(lv, "pot_enamel_01", CONDITIONER_POS, 0.3, 0.6, false, Color(0.75, 0.9, 1.1))

# A round goblin hut: walls, a thatched cone roof with overhang, a doorway facing `door_to`
func _round_hut(c: Vector3, r: float, wall_h: float, wall_mat: Material, door_to: Vector3) -> void:
	Models.cylinder(lv, c, r, r, wall_h, wall_mat, 20)
	Models.cylinder(lv, c + Vector3(0, wall_h - 0.2, 0), r * 1.32, 0.07, r * 0.9 + 0.7, Models.mat("thatch_roof_angled", 1.4, Color(0.78, 0.64, 0.46)), 20)
	Util.static_cyl(lv, c, r + 0.05, wall_h)
	_door(c, r, door_to, 1.0)

func _door(c: Vector3, r: float, door_to: Vector3, w: float) -> void:
	var d := door_to - c
	d.y = 0.0
	d = d.normalized()
	var yaw := atan2(d.x, d.z)
	var dp := c + d * (r + 0.03)
	var dark := Util.mat(Color(0.03, 0.02, 0.015))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := QuadMesh.new()
	q.size = Vector2(w, 1.75)
	Util.add_mesh(lv, q, dark, dp + Vector3(0, 0.875, 0), Vector3(0, yaw, 0))
	var frame := Models.mat("weathered_planks", 1.0, Color(0.8, 0.7, 0.6))
	var side := Vector3(cos(yaw), 0, -sin(yaw))
	for s in [-1.0, 1.0]:
		Models.block(lv, dp + side * s * (w / 2.0 + 0.06) + Vector3(0, 0.95, 0), Vector3(0.12, 1.9, 0.12), frame, yaw)
	Models.block(lv, dp + Vector3(0, 1.85, 0), Vector3(w + 0.36, 0.14, 0.14), frame, yaw)

func _room_shell(id: String) -> void:
	var o := origin(id)
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ROOM_W + 2, 1, 12)
	cs.shape = bs
	cs.position = o + Vector3(0, -0.5, 0)
	floor_body.add_child(cs)
	lv.add_child(floor_body)
	var fm: Material = Models.mat("rustic_stone_wall", 2.0, Color(0.8, 0.75, 0.7)) if id == "smith" else Models.mat("old_wooden_floor_01", 2.0)
	var pm := PlaneMesh.new()   # floor runs on toward the camera so there's no black band at the bottom
	pm.size = Vector2(ROOM_W + 2, 24)
	Util.add_mesh(lv, pm, fm, o + Vector3(0, 0.002, 6))
	var dark := Util.mat(Color(0.05, 0.035, 0.03))
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var wm: Material = {
		"chief": Models.mat("wood_trunk_wall", 2.2),
		"bar": Models.mat("raw_plank_wall", 2.0),
		"shaman": Models.mat("fabric_pattern_07", 1.4, Color(0.42, 0.25, 0.58)),
		"smith": Models.mat("rustic_stone_wall", 2.2),
	}[id]
	var back := PlaneMesh.new()
	back.size = Vector2(ROOM_W + 2, 7)
	Util.add_mesh(lv, back, wm, o + Vector3(0, 3.5, BACK_Z - 0.3), Vector3(PI / 2.0, 0, 0))
	var side := PlaneMesh.new()
	side.size = Vector2(7, 12)
	Util.add_mesh(lv, side, wm, o + Vector3(-ROOM_W / 2.0 - 0.6, 3.5, 0), Vector3(0, 0, -PI / 2.0))
	Util.add_mesh(lv, side, wm, o + Vector3(ROOM_W / 2.0 + 0.6, 3.5, 0), Vector3(0, 0, PI / 2.0))
	var under := PlaneMesh.new()   # dark ground in front of the room so the camera never sees the void
	under.size = Vector2(60, 40)
	Util.add_mesh(lv, under, dark, o + Vector3(0, -0.02, 14))
	var shell := PlaneMesh.new()   # ceiling + far shell so no sky or village shows
	shell.size = Vector2(50, 30)
	Util.add_mesh(lv, shell, dark, o + Vector3(0, 6.6, 2), Vector3(PI, 0, 0))
	Util.add_mesh(lv, shell, dark, o + Vector3(0, 8, BACK_Z - 0.5), Vector3(PI / 2.0, 0, 0))
	for s in [-1.0, 1.0]:
		var sw := PlaneMesh.new()
		sw.size = Vector2(16, 30)
		Util.add_mesh(lv, sw, dark, o + Vector3(s * 9.0, 5, 6), Vector3(0, 0, -s * PI / 2.0))
	# walls you bump into
	Util.static_box(lv, o + Vector3(-ROOM_W / 2.0, 1, 0), Vector3(0.5, 2, 10))
	Util.static_box(lv, o + Vector3(ROOM_W / 2.0, 1, 0), Vector3(0.5, 2, 10))
	Util.static_box(lv, o + Vector3(0, 1, BACK_Z), Vector3(ROOM_W, 2, 0.5))
	Util.static_box(lv, o + Vector3(0, 1, FRONT_Z), Vector3(ROOM_W, 2, 0.5))
	# warm room light (and tints the cutouts)
	var warm: Color = { "chief": Color(1.0, 0.75, 0.5), "bar": Color(1.0, 0.7, 0.42), "shaman": Color(0.75, 0.5, 1.0), "smith": Color(1.0, 0.6, 0.35) }[id]
	lv.add_glow(o + Vector3(0, 1, 0), warm, 11.0, func(): return 0.7, true)
	for p in [Vector3(-4.5, 3, -2.5), Vector3(4.5, 3, -2.5), Vector3(0, 3.5, 1.5)]:
		var l := OmniLight3D.new()
		l.light_color = warm
		l.light_energy = 1.7
		l.omni_range = 8.5
		l.position = o + p
		lv.add_child(l)
	# doormat by the exit
	Models.block(lv, o + Vector3(0, 0.02, FRONT_Z - 0.7), Vector3(1.6, 0.03, 0.9), Models.mat("fabric_pattern_05", 0.6, Color(0.7, 0.35, 0.22)))

func _bar_room() -> void:
	var o := origin("bar")
	var planks := Models.mat("weathered_planks", 1.2)
	var dark_planks := Models.mat("weathered_planks", 1.2, Color(0.65, 0.55, 0.5))
	_label3d("THE UNEMPLOYMENT OFFICE & BAR\n\"You're not fired. You're FREE.\"", o + Vector3(0, 4.7, BACK_Z), 44, Color("#ffdf8a"))
	# counter + back shelf with real bottles
	Models.block(lv, o + Vector3(-3.2, 0.55, -2.4), Vector3(5.0, 1.1, 0.8), dark_planks, 0.0, true)
	Models.block(lv, o + Vector3(-3.2, 1.13, -2.4), Vector3(5.2, 0.08, 0.95), planks)
	Models.block(lv, o + Vector3(-3.2, 1.9, BACK_Z + 0.25), Vector3(5.0, 0.07, 0.42), planks)
	Models.block(lv, o + Vector3(-3.2, 2.7, BACK_Z + 0.25), Vector3(5.0, 0.07, 0.42), planks)
	for x in [-5.0, -3.6, -2.2]:
		Models.place(lv, "wine_bottles_01", o + Vector3(x, 1.94, BACK_Z + 0.25), 0.0, 1.0)
		Models.place(lv, "wine_bottles_01", o + Vector3(x + 0.2, 2.74, BACK_Z + 0.25), 0.0, 1.0)
	var mug_tex: Texture2D = load("res://assets/items/beer.png")
	for k in 5:   # beezy mugs on the counter
		var m := Sprite3D.new()
		m.texture = mug_tex
		m.pixel_size = 0.26 / mug_tex.get_height()
		m.shaded = false
		m.position = o + Vector3(-5.2 + k * 0.9, 1.3, -2.3)
		lv.add_child(m)
	# barrels
	Models.place(lv, "wine_barrel_01", o + Vector3(-6.0, 0, -0.6), 0.3, 1.0, true)
	Models.place(lv, "wine_barrel_01", o + Vector3(-6.0, 0, 0.5), 1.4, 1.0, true)
	Models.place(lv, "wine_barrel_01", o + Vector3(-5.2, 0, 2.7), 0.0, 1.0, true)
	Models.place(lv, "wooden_crate_01", o + Vector3(-0.2, 0, -3.8), 0.1, 1.0)
	Models.place(lv, "wooden_crate_02", o + Vector3(6.0, 0, 2.6), 0.0, 1.0, true)
	# tables + stools
	for p in [Vector3(-1.5, 0, 0.8), Vector3(1.2, 0, 1.8), Vector3(3.8, 0, 0.6)]:
		Models.place(lv, "round_wooden_table_01", o + p, randf() * TAU, 0.8, true)
		for a in [0.4, 2.5, 4.4]:
			Models.place(lv, "wooden_stool_01", o + p + Vector3(cos(a) * 0.95, 0, sin(a) * 0.95), randf() * TAU, 1.0)
	# stage
	Models.block(lv, o + Vector3(4.2, 0.2, -3.0), Vector3(3.6, 0.4, 2.2), dark_planks, 0.0, true)
	_label3d("OPEN MIC NIGHT\n(every night)", o + Vector3(4.2, 3.3, BACK_Z + 0.1), 32, Color("#ff9ad5"))
	var spot := SpotLight3D.new()
	spot.light_color = Color(1.0, 0.85, 0.6)
	spot.light_energy = 4.0
	spot.spot_range = 7.0
	spot.spot_angle = 22.0
	spot.position = o + Vector3(4.2, 5.5, -1.5)
	lv.add_child(spot)
	spot.look_at(o + Vector3(4.2, 0.4, -3.0), Vector3.UP)
	# unemployment window
	Models.block(lv, o + Vector3(-6.2, 1.0, 1.9), Vector3(0.6, 2.0, 1.6), Models.mat("clay_plaster", 1.5), 0.0, true)
	_label3d("UNEMPLOYMENT\nTAKE A NUMBER\nNOW SERVING: 3", o + Vector3(-5.85, 2.4, 1.9), 22, Color("#ffffff"))
	# people
	npc["sludge"] = _goblin("sludge", "Sludge (Bartender) (Waters Down Everything)", o + Vector3(-3.4, 0, -3.3), 1.15, Color(0.95, 0.9, 0.8))
	npc["gorbo"] = _goblin("gorbo", "Gorbo (Open Mic) (Nobody Asked)", o + Vector3(4.2, 0.5, -3.0), 1.1, Color(1.05, 0.95, 1.1))
	npc["thumbs"] = _goblin("thumbs", "Big Thumbs (Bouncer) (Has a Gym Membership)", o + Vector3(-2.6, 0, 3.3), 1.75, Color(0.85, 0.95, 0.85), "goblin_fight")
	npc["gulpo"] = _goblin("gulpo", "Gulpo (Bar Champion) (Liver of Steel)", o + Vector3(2.1, 0, 0.9), 1.25, Color(1.0, 0.92, 0.75))
	npc["clerk"] = _goblin("clerk", "Unemployment Clerk (On Break Since 1987)", o + Vector3(-5.3, 0, 1.6), 1.1, Color(0.85, 0.85, 0.9))
	npc["patron"] = _goblin("patron", "Goblin (Regular) (Very Regular)", o + Vector3(-1.0, 0, 1.9), 1.15, Color.WHITE)

func _shaman_room() -> void:
	var o := origin("shaman")
	_label3d("SHAMAN WUZZLE\nFORTUNES · PROPHECIES · NO REFUNDS EITHER", o + Vector3(0, 4.3, BACK_Z), 40, Color("#d6a8ff"))
	Models.block(lv, o + Vector3(0, 0.02, -0.4), Vector3(5.0, 0.03, 3.4), Models.mat("fabric_pattern_07", 1.0, Color(0.75, 0.35, 0.65)))   # rug
	Models.place(lv, "round_wooden_table_01", o + Vector3(0, 0, -1.3), 0.0, 0.65, true)
	var ball := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.24
	sp.height = 0.48
	ball.mesh = sp
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.5, 0.8, 1.0, 0.7)
	bm.emission_enabled = true
	bm.emission = Color(0.3, 0.6, 1.0)
	bm.emission_energy_multiplier = 2.5
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ball.material_override = bm
	ball.position = o + Vector3(0, 0.9, -1.3)
	lv.add_child(ball)
	var bl := OmniLight3D.new()
	bl.light_color = Color(0.4, 0.7, 1.0)
	bl.light_energy = 2.0
	bl.omni_range = 4.0
	bl.position = ball.position
	lv.add_child(bl)
	Models.place(lv, "wooden_bookshelf_worn", o + Vector3(4.6, 0, BACK_Z + 0.4), 0.0, 1.0, true)
	Models.place(lv, "wooden_bookshelf_worn", o + Vector3(-4.6, 0, BACK_Z + 0.4), 0.0, 1.0, true)
	Models.place(lv, "brass_pot_01", o + Vector3(-1.2, 0, -2.2), 0.0, 1.2)
	Models.place(lv, "ceramic_pot", o + Vector3(5.6, 0, 0.6), 1.0, 1.0)
	Models.place(lv, "ceramic_pot", o + Vector3(-5.6, 0, 1.8), 2.2, 0.9)
	Models.place(lv, "wicker_basket_01", o + Vector3(1.5, 0, -2.4), 0.6, 1.4)
	Models.place(lv, "wooden_lantern_01", o + Vector3(2.2, 0, -2.6), 0.0, 1.0)
	Models.place(lv, "wooden_lantern_01", o + Vector3(-2.4, 0, -2.6), 0.0, 1.0)
	for p in [Vector3(-3.4, 0, -3.8), Vector3(-3.0, 0, -3.9), Vector3(3.2, 0, -3.8), Vector3(3.6, 0, -3.6)]:   # candles
		_cyl(o + p + Vector3(0, 0.3, 0), 0.06, 0.6, Color(0.9, 0.86, 0.75))
		var c := OmniLight3D.new()
		c.light_color = Color(1.0, 0.7, 0.4)
		c.light_energy = 0.8
		c.omni_range = 2.5
		c.position = o + p + Vector3(0, 0.75, 0)
		lv.add_child(c)
	for p in [Vector3(-5.8, 0.2, -1.0), Vector3(5.9, 0.2, -0.6), Vector3(-5.6, 0.2, 0.4)]:   # skulls
		var sk := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.36
		sk.mesh = sm
		sk.material_override = Util.mat(Color(0.86, 0.82, 0.72))
		sk.position = o + p
		lv.add_child(sk)
	for k in 7:   # hanging herbs
		_box(o + Vector3(-5.0 + k * 1.6, 5.6, BACK_Z + 0.4), Vector3(0.12, 0.9, 0.12), Color(0.3, 0.45, 0.2))
	npc["wuzzle"] = _goblin("wuzzle", "Shaman Wuzzle (Sees All) (Needs Glasses)", o + Vector3(0, 0, -2.6), 1.2, Color(1.05, 0.8, 1.25))

# ================================================================ little builders
func _box(p: Vector3, size: Vector3, c: Color, solid := false) -> void:
	var m := BoxMesh.new()
	m.size = size
	Util.add_mesh(lv, m, Util.mat(c), p)
	if solid:
		Util.static_box(lv, p, size)

func _cyl(p: Vector3, r: float, h: float, c: Color, rot := Vector3.ZERO, solid := false) -> void:
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	Util.add_mesh(lv, m, Util.mat(c), p, rot)
	if solid:
		Util.static_cyl(lv, p - Vector3(0, h / 2.0, 0), r, h)

func _quad(p: Vector3, size: Vector2, c: Color) -> void:
	# cloth (banners): real fabric texture tinted to the colour
	var q := QuadMesh.new()
	q.size = size
	var m: StandardMaterial3D = Models.mat("fabric_pattern_05", 0.8, c * 1.6).duplicate()
	m.uv1_triplanar = false
	m.uv1_world_triplanar = false
	m.uv1_scale = Vector3(size.x, size.y, 1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	Util.add_mesh(lv, q, m, p)

func _label3d(text: String, p: Vector3, size: int, c: Color, billboard := true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.009 if size >= 38 else 0.006
	l.outline_size = 10 if billboard else 0
	l.modulate = c
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if billboard:
		l.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	l.position = p
	lv.add_child(l)
	return l

func _smoke(p: Vector3) -> void:
	var sm := CPUParticles3D.new()
	sm.amount = 10
	sm.lifetime = 4.0
	sm.mesh = Fx.quad(1.0, false)
	sm.direction = Vector3.UP
	sm.spread = 10.0
	sm.gravity = Vector3(0.2, 0.3, 0)
	sm.initial_velocity_min = 0.4
	sm.initial_velocity_max = 0.6
	sm.scale_amount_curve = Fx.curve([[0.0, 0.4], [1.0, 1.6]])
	sm.color_ramp = Fx.ramp([[0.0, Color(0.5, 0.5, 0.5, 0)], [0.2, Color(0.45, 0.45, 0.45, 0.25)], [1.0, Color(0.5, 0.5, 0.5, 0)]])
	sm.position = p
	lv.add_child(sm)

func _goblin(id: String, label: String, p: Vector3, h: float, tint: Color, tex := "goblin") -> Unit:
	var u: Unit = lv.spawn_npc(id, label, tex, h, p)
	u.set_meta("tint", tint)
	var l := Label3D.new()
	l.text = label
	l.font_size = 26
	l.pixel_size = 0.0055
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color("#ffcf9a")
	u.add_child(l)
	l.position = Vector3(0, h + 0.3, 0)
	return u

# Haggle's market stall: four posts, a counter, a striped awning, junk for sale, Haggle behind it
func _stall() -> void:
	var root := Node3D.new()
	lv.add_child(root)
	root.global_position = STALL_POS
	root.rotation.y = STALL_YAW
	var wood := Models.mat("weathered_planks", 1.2, Color(0.85, 0.72, 0.58))
	for x in [-1.5, 1.5]:
		for z in [-0.7, 0.7]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.14, 2.5, 0.14)
			post.mesh = pm
			post.material_override = wood
			root.add_child(post)
			post.position = Vector3(x, 1.25, z)
	var counter := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(3.2, 1.0, 0.7)
	counter.mesh = cm
	counter.material_override = wood
	root.add_child(counter)
	counter.position = Vector3(0, 0.5, 0.55)
	for i in 8:   # striped awning (red / cream), tilted toward the front
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(3.6 / 8.0, 0.05, 2.0)
		strip.mesh = sm
		strip.material_override = Util.mat(Color("#b8322a") if i % 2 == 0 else Color("#efe3c2"), 0.8)
		root.add_child(strip)
		strip.position = Vector3(-1.8 + (i + 0.5) * 3.6 / 8.0, 2.55, 0.1)
		strip.rotation.x = 0.22
	Util.static_box(lv, STALL_POS, Vector3(2.6, 2, 2.6), STALL_YAW)
	# goods on the counter (real props)
	var fwd := Vector3(sin(STALL_YAW), 0, cos(STALL_YAW))
	var side := Vector3(cos(STALL_YAW), 0, -sin(STALL_YAW))
	var top := STALL_POS + fwd * 0.55 + Vector3(0, 1.0, 0)
	Models.place(lv, "wine_bottles_01", top - side * 1.0, STALL_YAW, 0.8)
	Models.place(lv, "brass_pot_01", top - side * 0.2, STALL_YAW, 0.5)
	Models.place(lv, "wooden_bowl_01", top + side * 0.5, STALL_YAW, 1.0)
	Models.place(lv, "rock_07", top + side * 1.1, 0.0, 1.6, false, Color(0.7, 0.62, 0.55))   # the rock (pre-owned)
	Models.place(lv, "wooden_crate_01", STALL_POS - fwd * 0.2 + side * 2.1, STALL_YAW + 0.3, 1.0, true)
	Models.place(lv, "wicker_basket_01", STALL_POS + fwd * 1.3 - side * 2.0, 0.4, 1.3)
	lv.wood_sign("sign_shop", "HAGGLE'S STALL\n(NO HAGGLING)", STALL_POS + fwd * 1.1 + Vector3(0, 2.15, 0), STALL_YAW, 2.4, 0.62)
	npc["haggle"] = _goblin("haggle", "Haggle (Shopkeeper) (No Haggling)", STALL_POS - fwd * 0.25, 1.15, Color(1.0, 0.95, 0.85))

# A bedroll on the ground: a rolled-up blanket and a flat one (rest spot)
func _bedroll(p: Vector3) -> void:
	var cloth := Models.mat("fabric_pattern_07", 0.8, Color(0.55, 0.35, 0.25))
	Models.block(lv, p + Vector3(0, 0.06, 0), Vector3(0.9, 0.12, 1.9), cloth, 0.25)
	Models.cylinder(lv, p + Vector3(-0.2, 0.0, -0.85), 0.2, 0.2, 0.95, Models.mat("fabric_pattern_07", 0.8, Color(0.7, 0.5, 0.3)), 10).rotation = Vector3(0, 0.25, PI / 2.0)

# ================================================================ walking in and out
func enter(id: String) -> void:
	lv.busy = true
	lv.ui_sfx.play()
	await lv.fade_out(0.4)
	room = id
	var o := origin(id)
	_place_party(o + Vector3(0, 0, FRONT_Z - 1.2), Vector3(0, 0, -1))
	for u in lv.npcs:   # goblins following you come in too (the band waits outside the door)
		if u.has_meta("follow") and u.get_meta("follow") and not u.has_meta("band"):
			u.global_position = o + Vector3(randf_range(-2, 2), 0, FRONT_Z - 2.0)
	_indoor_light(true)
	lv.cam_locked = true
	lv.target_yaw = 0.0
	lv.yaw = 0.0
	lv.zoom = 9.0
	lv.cam_height = 0.42
	lv.cam_look_h = 1.4
	lv.cam_target = lv.leader.global_position
	lv.objective_lbl.visible = false
	lv.fade_in(0.4)
	lv.show_toast(BUILDINGS[id]["name"], 1.4)
	await lv.wait(0.4)
	lv.busy = false

func leave() -> void:
	lv.busy = true
	lv.ui_sfx.play()
	await lv.fade_out(0.4)
	var d: Dictionary = BUILDINGS[room]
	var out: Vector3 = (d["door"] - d["pos"]).normalized()
	out.y = 0.0
	_place_party(d["door"] + out * 1.2, out)
	for u in lv.npcs:
		if u.has_meta("follow") and u.get_meta("follow") and not u.has_meta("band"):
			u.global_position = d["door"] + out * 2.5
	room = ""
	_indoor_light(false)
	lv.cam_locked = false
	lv.zoom = 8.0
	lv.cam_height = 0.6
	lv.cam_look_h = 1.1
	lv.cam_target = lv.leader.global_position
	lv.objective_lbl.visible = true
	lv.fade_in(0.4)
	await lv.wait(0.4)
	lv.busy = false

# Indoors the daylight would pour through the "roof", so the sun and sky light go down while you're inside
func _indoor_light(inside: bool) -> void:
	for c in lv.get_children():
		if c is DirectionalLight3D:
			if inside:
				_outdoor["sun"] = c.light_energy
				c.light_energy = 0.0
			elif _outdoor.has("sun"):
				c.light_energy = _outdoor["sun"]
		elif c is WorldEnvironment:
			var env: Environment = c.environment
			if inside:
				_outdoor["amb"] = env.ambient_light_energy
				_outdoor["fog"] = env.fog_density
				env.ambient_light_energy = 0.35
				env.fog_density = 0.0
			elif _outdoor.has("amb"):
				env.ambient_light_energy = _outdoor["amb"]
				env.fog_density = _outdoor["fog"]

# ================================================================ what you can interact with
func interactables() -> Array:
	var list: Array = []
	if room == "":
		for id in BUILDINGS:
			var d: Dictionary = BUILDINGS[id]
			if d.get("closed", false):
				continue
			list.append({ "id": "door_" + id, "label": d["name"], "verb": "Enter", "pos": d["door"], "h": 2.4, "r": 2.3, "steps": [{ "do": "enter_" + id }] })
		list.append({ "id": "house", "label": "the door", "verb": "Knock on", "pos": HOUSE_POS + Vector3(-1.3, 0, 1.6), "h": 2.2, "r": 2.2, "steps": R.LOCKED_HOUSE })
		list.append({ "id": "outhouse", "label": "the Outhouse", "verb": "Check out", "pos": OUTHOUSE_POS + Vector3(0, 0, 0.8), "h": 2.6, "r": 2.0, "steps": R.OUTHOUSE_DONE if _outhouse_all_done() else R.OUTHOUSE })
		list.append({ "id": "board", "label": "the Job Board", "verb": "Read", "pos": BOARD_POS, "h": 2.6, "r": 2.0, "steps": [{ "do": "job_board" }] })
		list.append({ "id": "bedroll", "label": "the bedroll", "verb": "Rest on", "pos": BEDROLL_POS, "h": 0.9, "r": 1.6, "rest": true, "steps": [
		] })
		if not Game.flag("conditionerFound"):
			list.append({ "id": "conditioner", "label": "Backup Conditioner", "verb": "Pick up", "pos": CONDITIONER_POS, "h": 0.8, "r": 1.4, "steps": [{ "do": "take_conditioner" }] })
		list.append({ "id": "shop", "label": "Haggle's Stall", "verb": "Shop at", "pos": STALL_POS + Vector3(sin(STALL_YAW), 0, cos(STALL_YAW)) * 1.6, "h": 2.2, "r": 2.0,
			"steps": ([{ "who": "goblin", "name": "Haggle", "line": "Welcome to Haggle's! Everything's for sale. No haggling. It's ironic." }] if not Game.flag("haggleMet") else []) + [{ "do": "open_shop" }] }) # DRAFT
		list.append({ "id": "grubnik", "label": "Grubnik", "verb": "Talk to", "node": npc["grubnik"], "h": 1.5, "r": 1.6, "steps": _grubnik_steps() })
		return list
	var o := origin(room)
	list.append({ "id": "exit", "label": "outside", "verb": "Go", "pos": o + Vector3(0, 0, FRONT_Z - 0.6), "h": 2.0, "r": 1.4, "steps": [{ "do": "leave_room" }] })
	match room:
		"bar":
			list.append({ "id": "sludge", "label": "Sludge", "verb": "Talk to", "node": npc["sludge"], "h": 1.6, "r": 2.2, "steps": _sludge_steps() })
			list.append({ "id": "gorbo", "label": "Gorbo", "verb": "Watch", "node": npc["gorbo"], "h": 2.0, "r": 2.4, "steps": R.GORBO_AGAIN if Game.flag("gorboSeen") else R.GORBO_SET })
			list.append({ "id": "thumbs", "label": "Big Thumbs", "verb": "Talk to", "node": npc["thumbs"], "h": 2.2, "r": 1.7, "steps": R.THUMBS_BEATEN if Game.flag("thumbsBeaten") else R.THUMBS_TALK })
			list.append({ "id": "gulpo", "label": "Gulpo", "verb": "Talk to", "node": npc["gulpo"], "h": 1.7, "r": 1.7, "steps": R.GULPO_WON if Game.flag("chugRematchWon") else R.GULPO_CHALLENGE })
			list.append({ "id": "clerk", "label": "the Unemployment window", "verb": "Visit", "node": npc["clerk"], "h": 1.6, "r": 1.6, "steps": R.CLERK_TALK })
		"shaman":
			var steps: Array = R.WUZZLE_DONE if Game.flag("loreOffWon") else (R.WUZZLE_MENU if Game.flag("loreOffOpen") else R.WUZZLE_FIRST + R.WUZZLE_MENU)
			list.append({ "id": "wuzzle", "label": "Shaman Wuzzle", "verb": "Talk to", "node": npc["wuzzle"], "h": 1.7, "r": 2.4, "steps": steps })
			list.append({ "id": "ball", "label": "the crystal ball", "verb": "Look into", "pos": o + Vector3(0, 0, -0.4), "h": 1.7, "r": 1.3, "steps": R.CRYSTAL_BALL })
	return list

func _sludge_steps() -> Array:
	if not Game.flag("barTabStarted"):
		return R.SLUDGE_FIRST + R.SLUDGE_TAB
	if Game.quest_state("bar_tab") == "done":
		return R.SLUDGE_DONE
	return R.SLUDGE_TAB

func _grubnik_steps() -> Array:
	var st := Game.quest_state("lucky_spoon")
	if st == "done":
		return R.GRUBNIK_DONE
	if Game.flag("luckySpoonFound"):
		return (R.GRUBNIK_ASK.slice(0, 1) if st == "" else []) + R.GRUBNIK_RETURN
	return R.GRUBNIK_WAITING if st == "active" else R.GRUBNIK_ASK

func _outhouse_all_done() -> bool:
	var skorn_ok := Game.flag("outhouseSkornDone") or not _skorn_here()
	return skorn_ok and Game.flag("outhouseLykorDone") and Game.flag("outhouseXyloDone")

func _skorn_here() -> bool:
	for u in lv.party:
		if u.id == "skorn":
			return true
	return false

# ================================================================ per frame
# Puts whoever you're controlling at `p` and the other two a step further along `ahead` (into the room / away from the
# hut). lv.place_party() puts them BEHIND the leader, which here is inside the doorway's wall: switching to one of
# them left you stuck behind an invisible wall, and walking on dropped you off the room's floor. Keeps the leader.
func _place_party(p: Vector3, ahead: Vector3) -> void:
	var side := ahead.cross(Vector3.UP).normalized()
	var k := 0
	for u in lv.party:
		u.velocity = Vector3.ZERO
		if u == lv.leader:
			u.global_position = p
		else:
			u.global_position = p + ahead * 1.3 + side * (0.9 if k == 0 else -0.9)
			k += 1
	lv.set_leader(lv.leader)
	lv.cam_target = p

# Safety net: nobody in a room can end up outside its walls or below its floor (would fall forever).
func _keep_in_room() -> void:
	var o := origin(room)
	var hx := ROOM_W / 2.0 - 0.6
	for u in lv.party + lv.npcs:
		if not is_instance_valid(u) or not u.visible:
			continue
		if not lv.party.has(u) and not (u.has_meta("follow") and u.get_meta("follow")):
			continue   # room NPCs (barkeep etc.) stay where they were put
		var l: Vector3 = u.global_position - o
		if absf(l.x) > 30.0:   # not in this room at all (the band waiting outside, village goblins)
			continue
		if absf(l.x) > hx or l.z > FRONT_Z - 0.6 or l.z < BACK_Z + 0.6 or l.y < -0.3:
			u.global_position = o + Vector3(clampf(l.x, -hx, hx), 0.0, clampf(l.z, BACK_Z + 0.6, FRONT_Z - 0.6))
			u.velocity = Vector3.ZERO

func process(_delta: float) -> void:
	if room != "":
		_keep_in_room()
	if conditioner_node and conditioner_node.visible and Game.flag("conditionerFound"):
		conditioner_node.visible = false

# ================================================================ actions from the dialogue
func reward(xp: int, msg := "") -> void:
	var ups: Array = Game.add_xp(xp) if xp > 0 else []
	var txt := msg
	if xp > 0:
		txt += ("  ·  " if txt != "" else "") + "+%d XP" % xp
	for l in ups:
		txt += "  ·  LEVEL UP! (Level %d)" % l
	lv.ui_sfx.play()
	lv.show_toast(txt, 2.6)

func run_lines(steps: Array) -> void:
	await lv.run_nested(steps)

func on_action(n: String) -> void:
	if n.begins_with("enter_"):
		await enter(n.substr(6))
		return
	match n:
		"leave_room":
			await leave()
		"job_board":
			await JobBoardUI.show_board(lv, self)
		"open_shop":
			Game.set_flag("haggleMet")
			await ShopUI.open_shop(lv)
		# ---- by the Chief's Hut (the hut itself is closed)
		"take_conditioner":
			Game.set_flag("conditionerFound")
			Game.add_item("conditioner", 1, "lykor")
			reward(10, "Lykor got: Backup Conditioner (use it in your inventory for +15 max HP)")
			await lv.wait(0.6)
		# ---- Bar
		"start_bar_tab":
			Game.set_flag("barTabStarted")
			Game.start_quest("bar_tab", R.QUESTS["bar_tab"][0], R.QUESTS["bar_tab"][1])
		"check_beezy":
			Game.set_flag("has3Beezy", Game.count("beer") >= 3)   # the whole party chips in
		"pay_tab":
			Game.take_item("beer", 3)
			Game.finish_quest("bar_tab")
			reward(15, "Bar tab paid (−3 Beezy)")
			await lv.wait(0.5)
		"bouncer_fight":
			var res: String = await lv.fight("bouncer", { "enemies": [npc["thumbs"]] })
			npc["thumbs"].global_position = origin("bar") + Vector3(-2.6, 0, 3.3)
			if res == "win" or res == "talked":
				Game.set_flag("thumbsBeaten", res == "win")
				await run_lines(R.SLUDGE_AFTER_FIGHT)
		"tab_won":
			Game.add_item("beer", 2)
			Game.finish_quest("bar_tab")
			reward(0, "Tab cleared · Got: Beezy ×2")
			await lv.wait(0.5)
		"gorbo_laugh":
			lv.hop(npc["gorbo"], 0.4)
		"gorbo_heckle":
			gorbo_heckles += 1
			lv.char_label(npc["gorbo"], "Gorbo (Hurt)", 1.5, 1.5, Color("#ff8a6a"))
		"gorbo_end":
			Game.set_flag("gorboSeen")
			Game.set_flag("gorboRoasted", gorbo_heckles >= 2)
			if gorbo_heckles >= 2:
				reward(15, "Roasted a comedian")
			else:
				var who := Game.add_item("beer", 1)
				reward(5, "%s got: Beezy (from the tip jar)" % who.capitalize())
		"gulpo_chug":
			if Game.quest_state("chug_rematch") == "":
				Game.start_quest("chug_rematch", R.QUESTS["chug_rematch"][0], R.QUESTS["chug_rematch"][1])
			var won: bool = await lv._chug_game("Gulpo (Bar Champion, Liver of Steel)", 1.1)
			if won:
				Game.set_flag("chugRematchWon")
				Game.finish_quest("chug_rematch")
				Game.add_item("beer", 2, "lykor")
				reward(25, "Beat Gulpo · Lykor got: Beezy ×2")
				await run_lines([{ "who": "goblin", "name": R.GULPO, "line": "No… my liver… it's never lost… it's crying…" }]) # DRAFT
			else:
				await run_lines([{ "who": "goblin", "name": R.GULPO, "line": "STEEL. LIVER. Night night, pretty boy." }]) # DRAFT
				lv.knock(lv.leader, -80.0, 0.4)
				await lv.fade_out(0.8)
				lv.unknock(lv.leader)
				Game.forehead = "GULPO WAS HERE"
				lv._show_forehead()
				lv.fade_in(0.8)
				lv.show_toast("Somebody wrote on your forehead while you were out.", 2.4)
				await lv.wait(0.8)
		# ---- Job Board
		"start_lucky_spoon":
			Game.start_quest("lucky_spoon", R.QUESTS["lucky_spoon"][0], R.QUESTS["lucky_spoon"][1])
			lv.objective("Get Grubnik's lucky spoon back from the Goblin Patrol (east road).", Vector3(21, 0, -1.5))
		"finish_lucky_spoon":
			Game.start_quest("lucky_spoon", R.QUESTS["lucky_spoon"][0], R.QUESTS["lucky_spoon"][1])
			Game.finish_quest("lucky_spoon")
			Game.give_gear("weighted_d6")
			reward(30, "Got: Weighted d6 (Crash Out can't roll a 1)")
			lv.objective("Head east to the Metocy Mart.", Vector3(30, 0, -2))   # village EXIT_POS
			await lv.wait(0.6)
		# ---- Shaman
		"start_lore_off":
			Game.set_flag("loreOffOpen")
			Game.start_quest("lore_off", R.QUESTS["lore_off"][0], R.QUESTS["lore_off"][1])
		"fortune":
			await run_lines([{ "who": "goblin", "name": R.WUZZLE, "line": R.FORTUNES[randi() % R.FORTUNES.size()] }])
		"lore_off":
			await run_lines(R.LORE_OFF)
		"lore_reset":
			lore_wrong = 0
		"lore_right":
			lv.char_label(lv.leader, "Correct (Unfortunately)", 1.2, lv.leader.height_m + 0.5, Color("#7dff8a"))
		"lore_wrong":
			lore_wrong += 1
			lv.char_label(npc["wuzzle"], "HA!", 1.2, 1.6, Color("#ff8a6a"))
		"lore_end":
			Game.set_flag("loreOffWon", lore_wrong == 0)
		"lore_reward":
			Game.add_item("vol9", 1, "xylo")
			Game.finish_quest("lore_off")
			reward(40, "Got: Deloye Lore Vol. 9 (Signed) (read it in your inventory for +15% meter gain)")
			await lv.wait(0.5)
		# ---- Outhouse
		"outhouse_check":
			Game.set_flag("outhouseSkorn", _skorn_here() and not Game.flag("outhouseSkornDone"))
			Game.set_flag("outhouseLykor", not Game.flag("outhouseLykorDone"))
			Game.set_flag("outhouseXylo", not Game.flag("outhouseXyloDone"))
		"outhouse_skorn":
			await _outhouse_trip("skorn")
			Game.set_flag("outhouseSkornDone")
			Game.add_item("bowl", 1, "skorn")
			reward(5, "Skorn got: Chipotle Bowl (sealed) (allegedly)")
		"outhouse_lykor":
			await _outhouse_trip("lykor")
			Game.set_flag("outhouseLykorDone")
			lv.char_label(_member("lykor"), "Lykor (Hair: Ruined) (Temporarily)", 8.0, 2.4, Color("#ff8a6a"))
			reward(10)
		"outhouse_xylo":
			await _outhouse_trip("xylo")
			Game.set_flag("outhouseXyloDone")
			reward(20, "Read the outhouse graffiti")

func _member(id: String) -> Unit:
	for u in lv.party + lv.npcs:
		if u.id == id:
			return u
	return lv.leader

func _outhouse_trip(id: String) -> void:
	var u := _member(id)
	lv.dialogue.hide_box()
	await lv.walk_to(u, OUTHOUSE_POS + Vector3(0, 0, 0.9), 1.0, 3.0)
	u.visible = false
	lv.whoosh_sfx.play()
	for k in 3:
		await lv.wait(0.5)
		lv.shake = 0.25
		var p: AudioStreamPlayer = lv._sfx(Util.noise_burst(160, 0.4, 0.8), -6.0)
		p.pitch_scale = randf_range(0.6, 1.4)
		p.play()
		get_tree().create_timer(1.0).timeout.connect(p.queue_free)
	await lv.wait(0.6)
	u.visible = true
	lv.hop(u, 0.4)
	lv.dialogue.show_box()

# ================================================================ automated tour (VILLAGE_TOUR=buildings)
func find_it(id: String) -> Dictionary:
	for it in lv.current_interactables():
		if it["id"] == id:
			return it
	return {}

func auto_talk(id: String, picks := [], shot_name := "", shot_after := 2) -> void:
	var it := find_it(id)
	if it.is_empty():
		print("TOUR: no interactable ", id)
		return
	var p: Vector3 = it["node"].global_position if it.has("node") else it["pos"]
	lv.leader.global_position = p + Vector3(0, 0, 1.2)
	await lv.wait(0.3)
	lv.start(it)
	var n := 0
	var guard := 0
	await lv.wait(0.4)
	while lv.busy and guard < 260:
		guard += 1
		await lv.wait(0.5)
		if not lv.dialogue.active or not lv.dialogue.panel.visible:
			continue
		if lv.dialogue._choices.size() > 0:
			var pick: int = picks.pop_front() if not picks.is_empty() else 0
			lv.dialogue._picked.emit(mini(pick, lv.dialogue._choices.size() - 1))
		else:
			n += 1
			if shot_name != "" and n == shot_after:
				await lv.shot(shot_name)
			lv.dialogue._next.emit()

func tour() -> void:
	lv.fade.color.a = 0.0
	lv.stage = "after"
	lv.busy = false
	lv.follow_enabled = true
	lv.switch_enabled = true
	lv.chief.visible = true
	lv.chief.global_position = lv.THRONE_POS + Vector3(2.0, 0, 1.0)
	Game.bags = {}
	Game.add_item("beer", 3, "lykor")
	var part := OS.get_environment("TOUR_PART")
	await lv.wait(1.0)
	if part == "" or part == "1":
		lv.place_party(Vector3(0, 0, 3), Vector3(0, 0, -1))
		lv.target_yaw = 0.0
		await lv.wait(1.5)
		await lv.shot("b_00_village")
		await auto_talk("board", [], "b_01_board", 2)
		await auto_talk("grubnik", [], "b_02_grubnik", 2)
		await auto_talk("conditioner", [], "b_03_conditioner", 1)
		Game.gold = 40
		await auto_talk("shop", [], "b_03b_shop_talk", 1)
		await auto_talk("bedroll", [], "b_04_bedroll", 1)
		await auto_talk("door_bar")
		await lv.wait(1.0)
		await lv.shot("b_06_bar_room")
		await auto_talk("gorbo", [1, 1, 0], "b_07_gorbo", 1)
		await auto_talk("sludge", [2], "b_08_sludge", 3)
		await lv.shot("b_09_after_fight")
		await auto_talk("gulpo", [0])
		await lv.shot("b_10_after_chug")
		await auto_talk("exit")
	if part == "" or part == "2":
		await auto_talk("door_shaman")
		await lv.wait(1.0)
		await lv.shot("b_11_shaman_room")
		await auto_talk("wuzzle", [1, 0, 1, 2], "b_12_wuzzle", 2)
		await auto_talk("ball")
		await auto_talk("exit")
		await auto_talk("outhouse", [0], "b_16_outhouse", 1)
		await auto_talk("outhouse", [0])
		Game.set_flag("luckySpoonFound")
		await auto_talk("grubnik", [], "b_17_grubnik_return", 2)
		lv.open_party_menu()
		await lv.wait(1.0)
		await lv.shot("b_18_party_quests")
		lv._close_menu()
	print("TOUR DONE  xp=", Game.xp, " level=", Game.level, " gear=", Game.gear_owned, " quests=", Game.quests, " bags=", Game.bags)
	get_tree().quit()
