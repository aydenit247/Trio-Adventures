# The explorable Goblin Village (after the throne scene): six places to poke around.
#   1 Chief's Hut (room)          2 Unemployment Office & Bar (room)   3 Job Board (outside)
#   4 Shaman's Tent (room)        5 Spoonsmith (room)                  6 The Outhouse (outside, door only)
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
	"chief": { "name": "Chief's Hut", "pos": Vector3(-5.5, 0, -14.5), "door": Vector3(-5.2, 0, -12.0), "room": 0 },
	"bar": { "name": "Unemployment Office & Bar", "pos": Vector3(-11.0, 0, -5.0), "door": Vector3(-8.3, 0, -3.9), "room": 1 },
	"shaman": { "name": "Shaman's Tent", "pos": Vector3(7.0, 0, -15.0), "door": Vector3(6.6, 0, -12.6), "room": 2 },
	"smith": { "name": "Clank's Spoonsmithy", "pos": Vector3(-11.5, 0, 5.5), "door": Vector3(-9.2, 0, 4.4), "room": 3 },
}
const OUTHOUSE_POS := Vector3(12.8, 0, 7.8)
const BOARD_POS := Vector3(4.2, 0, -4.6)
const HOUSE_POS := Vector3(10.5, 0, -6.5)
const SPOONS := [Vector3(-13.6, 0, -1.5), Vector3(8.4, 0, 0.6), Vector3(14.6, 0, 9.2), Vector3(-2.5, 0, -16.8), Vector3(11.8, 0, -10.6)]

var lv          # the village (Level)
var room := ""  # "" = outside, else a BUILDINGS key
var npc := {}   # name -> Unit
var chief_outside := Vector3.ZERO
var gorbo_heckles := 0
var lore_wrong := 0
var spoon_nodes := []
var _outdoor := {}   # saved sun/ambient while indoors

func origin(id: String) -> Vector3:
	return Vector3(400.0 + BUILDINGS[id]["room"] * 40.0, 0, 0)

# ================================================================ building it all
func build() -> void:
	_outside()
	for id in BUILDINGS:
		_room_shell(id)
	_chief_room()
	_bar_room()
	_shaman_room()
	_smith_room()

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
	# Spoonsmith: stone hut, chimney with smoke, forge glow, an anvil + buckets out front
	var sm: Dictionary = BUILDINGS["smith"]
	_round_hut(sm["pos"], 2.3, 2.3, stone, sm["door"])
	Models.cylinder(lv, sm["pos"] + Vector3(-0.8, 0, -0.9), 0.45, 0.4, 4.2, stone, 10)
	_smoke(sm["pos"] + Vector3(-0.8, 4.4, -0.9))
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.5, 0.2)
	fl.light_energy = 1.6
	fl.omni_range = 4.5
	fl.position = sm["door"] + Vector3(0, 1.0, 0.4)
	lv.add_child(fl)
	Models.block(lv, sm["door"] + Vector3(1.4, 0.35, 0.6), Vector3(0.7, 0.7, 0.4), Models.mat("metal_plate", 0.6, Color(0.45, 0.45, 0.5)), 0.0, true)
	Models.place(lv, "cross_pein_hammer", sm["door"] + Vector3(1.4, 0.73, 0.6), 0.0, 1.6).rotation = Vector3(PI / 2.0, 0.4, 0)
	Models.place(lv, "wooden_bucket_01", sm["door"] + Vector3(-1.1, 0, 0.9), 0.0, 1.0)
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
	_label3d("JOB BOARD", BOARD_POS + Vector3(0, 2.05, 0.06), 34, Color("#ffdf8a"))
	npc["grubnik"] = _goblin("grubnik", "Grubnik (Lost His Lucky Spoon)", BOARD_POS + Vector3(1.3, 0, 0.9), 1.05, Color(0.9, 1.0, 0.85))
	# little bits of village life
	Models.place(lv, "wooden_crate_01", Vector3(2.0, 0, 6.2), 0.6, 1.0, true)
	Models.place(lv, "wooden_bucket_01", Vector3(7.8, 0, 4.4), 0.0, 1.0)
	Models.place(lv, "wine_barrel_01", Vector3(-7.4, 0, 7.6), 0.0, 1.0, true)
	Models.place(lv, "wooden_crate_02", Vector3(9.0, 0, -9.6), 1.1, 1.0, true)
	# name signs over every building
	for id in BUILDINGS:
		var d: Dictionary = BUILDINGS[id]
		_label3d(d["name"], d["pos"] + Vector3(0, 4.6 if id != "smith" else 4.9, 0), 40, Color("#f3e3b0"))
	_label3d("Outhouse (Smells)", OUTHOUSE_POS + Vector3(0, 3.0, 0), 36, Color("#f3e3b0"))
	_label3d("Goblin House (Locked) (Napping)", HOUSE_POS + Vector3(0, 3.9, 0), 34, Color("#f3e3b0"))
	# shiny spoons lying around
	for i in SPOONS.size():
		spoon_nodes.append(_spoon(SPOONS[i]))

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

func _chief_room() -> void:
	var o := origin("chief")
	var planks := Models.mat("weathered_planks", 1.2)
	_label3d("BOGDRINKER MANOR\n(it's a hut)", o + Vector3(0, 4.6, BACK_Z), 46, Color("#ffdf4a"))
	for x in [-5.5, 5.5]:
		_quad(o + Vector3(x, 3.0, BACK_Z + 0.05), Vector2(1.0, 2.8), Color(0.6, 0.12, 0.1))
	# portrait of the Chief, painted by the Chief (his cutout in a gold frame)
	Models.block(lv, o + Vector3(0, 2.4, BACK_Z + 0.05), Vector3(1.9, 2.3, 0.08), Models.mat("metal_plate", 0.8, Color(1.0, 0.78, 0.35)))
	var pic := Sprite3D.new()
	pic.texture = load("res://assets/characters/goblin_chief.png")
	pic.pixel_size = 2.0 / pic.texture.get_height()
	pic.shaded = false
	pic.modulate = Color(1.1, 1.0, 0.9)
	pic.position = o + Vector3(0, 2.4, BACK_Z + 0.12)
	lv.add_child(pic)
	# the belt, on a little plank stand
	Models.block(lv, o + Vector3(-3.2, 0.6, BACK_Z + 0.6), Vector3(1.2, 1.2, 0.6), planks, 0.0, true)
	Models.block(lv, o + Vector3(-3.2, 1.45, BACK_Z + 0.6), Vector3(0.9, 0.3, 0.12), Models.mat("metal_plate", 0.5, Color(1.0, 0.8, 0.35)))
	_label3d("CHUG CHAMP", o + Vector3(-3.2, 1.45, BACK_Z + 0.7), 22, Color(0.2, 0.1, 0.02), false)
	# royal chest (a real one)
	Models.place(lv, "treasure_chest", o + Vector3(4.2, 0, BACK_Z + 1.0), 0.0, 1.3, true)
	# hay bed on a plank frame + crates of royal junk
	Models.block(lv, o + Vector3(-4.8, 0.15, 0.8), Vector3(2.1, 0.3, 2.7), planks, 0.0, true)
	Models.block(lv, o + Vector3(-4.8, 0.42, 0.8), Vector3(1.9, 0.25, 2.5), Models.mat("thatch_roof_angled", 0.8, Color(1.1, 1.0, 0.75)))
	Models.place(lv, "wooden_crate_02", o + Vector3(5.6, 0, 1.6), 0.2, 1.0, true)
	Models.place(lv, "wooden_crate_01", o + Vector3(5.5, 0.46, 1.6), 0.5, 0.9)
	Models.place(lv, "wooden_lantern_01", o + Vector3(-2.0, 0, BACK_Z + 0.7), 0.0, 1.0)
	Models.place(lv, "wooden_lantern_01", o + Vector3(2.2, 0, BACK_Z + 0.7), 0.0, 1.0)
	# the emergency spoon pile (real spoons)
	for k in 12:
		var sp := Models.place(lv, "wooden_spoon", o + Vector3(2.6 + randf_range(-0.55, 0.55), 0.02 + k * 0.012, 1.8 + randf_range(-0.35, 0.35)), randf() * TAU, 1.6)
		sp.rotation.z = randf_range(-0.2, 0.2)
	_label3d("Emergency Spoons", o + Vector3(2.6, 0.7, 1.8), 24, Color("#f3e3b0"))

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

func _smith_room() -> void:
	var o := origin("smith")
	var planks := Models.mat("weathered_planks", 1.2)
	var stone := Models.mat("rustic_stone_wall", 1.5, Color(0.8, 0.75, 0.72))
	_label3d("CLANK'S SPOONSMITHY\nSPOONS ONLY. DON'T ASK.", o + Vector3(0, 4.6, BACK_Z), 44, Color("#ffcf9a"))
	# stone forge with a fire in it
	Models.block(lv, o + Vector3(-4.2, 0.7, -3.4), Vector3(2.2, 1.4, 1.4), stone, 0.0, true)
	Models.block(lv, o + Vector3(-4.2, 3.4, -3.8), Vector3(1.2, 4.0, 0.8), stone)
	var fl := Fx.flames(0.6)
	fl.position = o + Vector3(-4.2, 1.45, -3.0)
	lv.add_child(fl)
	var fo := OmniLight3D.new()
	fo.light_color = Color(1.0, 0.45, 0.15)
	fo.light_energy = 3.0
	fo.omni_range = 6.0
	fo.position = o + Vector3(-4.2, 2.0, -2.6)
	lv.add_child(fo)
	# anvil on a stump-block, hammers on it
	Models.block(lv, o + Vector3(-1.4, 0.32, -1.6), Vector3(0.6, 0.64, 0.6), planks, 0.0, true)
	Models.block(lv, o + Vector3(-1.4, 0.75, -1.6), Vector3(1.0, 0.24, 0.42), Models.mat("metal_plate", 0.6, Color(0.45, 0.45, 0.5)))
	Models.place(lv, "cross_pein_hammer", o + Vector3(-1.2, 0.88, -1.55), 0.0, 1.3).rotation = Vector3(PI / 2.0, 0.6, 0)
	Models.place(lv, "sledgehammer_01", o + Vector3(-0.5, 0.75, -1.9), 0.3, 1.0)
	Models.place(lv, "wooden_bucket_01", o + Vector3(-2.6, 0, -1.2), 0.0, 1.0)
	# spoon rack on the back wall, hung with real spoons
	Models.block(lv, o + Vector3(3.2, 2.0, BACK_Z + 0.08), Vector3(4.0, 1.8, 0.1), planks)
	for k in 12:
		var s := Models.place(lv, "wooden_spoon", o + Vector3(1.6 + k * 0.29, 2.0, BACK_Z + 0.2), 0.0, 2.2)
		s.rotation = Vector3(-PI / 2.0, 0, randf_range(-0.12, 0.12))
	_label3d("FOR SALE", o + Vector3(3.2, 3.15, BACK_Z + 0.15), 28, Color("#ffdf8a"))
	Models.place(lv, "wine_barrel_01", o + Vector3(5.6, 0, 0.2), 0.0, 1.0, true)
	for k in 6:
		var s2 := Models.place(lv, "wooden_spoon", o + Vector3(5.6 + randf_range(-0.15, 0.15), 0.9, 0.2 + randf_range(-0.15, 0.15)), randf() * TAU, 2.0)
		s2.rotation.x = -PI / 2.0 + randf_range(-0.3, 0.3)
	_label3d("Barrel of Spoons", o + Vector3(5.6, 1.6, 0.2), 24, Color("#f3e3b0"))
	Models.place(lv, "wooden_crate_02", o + Vector3(5.8, 0, 2.6), 0.0, 1.0, true)
	npc["clank"] = _goblin("clank", "Clank (Spoonsmith) (Only Makes Spoons)", o + Vector3(-2.4, 0, -2.4), 1.2, Color(0.95, 0.85, 0.75))

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

func _spoon(p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	lv.add_child(n)
	var m := CylinderMesh.new()
	m.top_radius = 0.03
	m.bottom_radius = 0.03
	m.height = 0.45
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.95)
	mat.metallic = 0.9
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 1.0)
	mat.emission_energy_multiplier = 0.6
	Util.add_mesh(n, m, mat, Vector3(0, 0.05, 0), Vector3(PI / 2.0, 0.6, 0))
	var sp := SphereMesh.new()
	sp.radius = 0.08
	sp.height = 0.05
	Util.add_mesh(n, sp, mat, Vector3(0.12, 0.06, -0.18))
	var sparkle := CPUParticles3D.new()
	sparkle.amount = 6
	sparkle.lifetime = 1.2
	sparkle.mesh = Fx.quad(0.07, true)
	sparkle.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparkle.emission_sphere_radius = 0.3
	sparkle.gravity = Vector3(0, 0.3, 0)
	sparkle.color_ramp = Fx.ramp([[0.0, Color(1, 1, 1, 0)], [0.3, Color(1, 1, 0.8, 1)], [1.0, Color(1, 1, 1, 0)]])
	sparkle.position = Vector3(0, 0.3, 0)
	n.add_child(sparkle)
	return n

# ================================================================ walking in and out
func enter(id: String) -> void:
	lv.busy = true
	lv.ui_sfx.play()
	await lv.fade_out(0.4)
	room = id
	var o := origin(id)
	lv.place_party(o + Vector3(0, 0, FRONT_Z - 1.2), Vector3(0, 0, -1))
	for u in lv.npcs:   # goblins following you come in too
		if u.has_meta("follow") and u.get_meta("follow"):
			u.global_position = o + Vector3(randf_range(-2, 2), 0, FRONT_Z - 2.0)
	if id == "chief" and lv.chief.visible and not lv.chief.has_meta("follow"):
		chief_outside = lv.chief.global_position
		lv.chief.global_position = o + Vector3(1.2, 0, -2.0)
		lv.chief.set_meta("at_home", true)
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
	lv.place_party(d["door"] + out * 1.2, out)
	for u in lv.npcs:
		if u.has_meta("follow") and u.get_meta("follow"):
			u.global_position = d["door"] + out * 2.5
	if lv.chief.has_meta("at_home"):
		lv.chief.global_position = chief_outside
		lv.chief.remove_meta("at_home")
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
			list.append({ "id": "door_" + id, "label": d["name"], "verb": "Enter", "pos": d["door"], "h": 2.4, "r": 2.3, "steps": [{ "do": "enter_" + id }] })
		list.append({ "id": "house", "label": "the door", "verb": "Knock on", "pos": HOUSE_POS + Vector3(-1.3, 0, 1.6), "h": 2.2, "r": 2.2, "steps": R.LOCKED_HOUSE })
		list.append({ "id": "outhouse", "label": "the Outhouse", "verb": "Check out", "pos": OUTHOUSE_POS + Vector3(0, 0, 0.8), "h": 2.6, "r": 2.0, "steps": R.OUTHOUSE_DONE if _outhouse_all_done() else R.OUTHOUSE })
		list.append({ "id": "board", "label": "the Job Board", "verb": "Read", "pos": BOARD_POS, "h": 2.6, "r": 2.0, "steps": R.JOB_BOARD })
		list.append({ "id": "grubnik", "label": "Grubnik", "verb": "Talk to", "node": npc["grubnik"], "h": 1.5, "r": 1.6, "steps": _grubnik_steps() })
		for i in SPOONS.size():
			if not Game.flag("spoon_%d" % i):
				list.append({ "id": "spoon_%d" % i, "label": "Shiny Spoon", "verb": "Pick up", "pos": SPOONS[i], "h": 0.7, "r": 1.6, "steps": [R.SHINY_SPOON[0], { "do": "pick_spoon_%d" % i }] })
		return list
	var o := origin(room)
	list.append({ "id": "exit", "label": "outside", "verb": "Go", "pos": o + Vector3(0, 0, FRONT_Z - 0.6), "h": 2.0, "r": 1.4, "steps": [{ "do": "leave_room" }] })
	match room:
		"chief":
			if lv.chief.has_meta("at_home"):
				list.append({ "id": "chief", "label": "Chief Bogdrinker", "verb": "Talk to", "node": lv.chief, "h": 1.9, "r": 1.9, "steps": R.CHIEF_HOME_AGAIN if Game.flag("chiefHomeSeen") else R.CHIEF_HOME + [{ "do": "chief_home_seen" }] })
			list.append({ "id": "belt", "label": "the belt", "verb": "Look at", "pos": o + Vector3(-3.2, 0, BACK_Z + 1.2), "h": 2.0, "r": 1.5, "steps": R.BELT })
			list.append({ "id": "portrait", "label": "the portrait", "verb": "Look at", "pos": o + Vector3(0, 0, BACK_Z + 0.9), "h": 3.8, "r": 1.6, "steps": R.PORTRAIT })
			list.append({ "id": "chest", "label": "the royal chest", "verb": "Open", "pos": o + Vector3(4.2, 0, BACK_Z + 1.6), "h": 1.4, "r": 1.5, "steps": R.CHEST_EMPTY if Game.flag("chestLooted") else R.CHEST })
			list.append({ "id": "bed", "label": "the hay bed", "verb": "Lie on", "pos": o + Vector3(-4.8, 0, 2.3), "h": 1.1, "r": 1.6, "steps": R.HAY_BED_AGAIN if Game.flag("xyloNapped") else R.HAY_BED })
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
		"smith":
			var cs: Array = R.CLANK_FIRST if not Game.flag("smithMet") else (R.CLANK_DONE if int(Game.flags.get("spoons_turned", 0)) >= SPOONS.size() else R.CLANK_TURN_IN)
			list.append({ "id": "clank", "label": "Clank", "verb": "Talk to", "node": npc["clank"], "h": 1.7, "r": 2.0, "steps": cs })
			list.append({ "id": "forge", "label": "the forge", "verb": "Look at", "pos": o + Vector3(-4.2, 0, -2.2), "h": 1.9, "r": 1.6, "steps": R.FORGE })
			list.append({ "id": "rack", "label": "the spoon rack", "verb": "Look at", "pos": o + Vector3(3.2, 0, BACK_Z + 1.0), "h": 3.2, "r": 1.6, "steps": R.SPOON_RACK })
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
func process(_delta: float) -> void:
	for i in spoon_nodes.size():
		var n: Node3D = spoon_nodes[i]
		if n.visible and Game.flag("spoon_%d" % i):
			n.visible = false
		elif n.visible:
			n.rotation.y += _delta * 1.5

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
	if n.begins_with("pick_spoon_"):
		var i := int(n.substr(11))
		Game.set_flag("spoon_%d" % i)
		Game.flags["spoons_found"] = int(Game.flags.get("spoons_found", 0)) + 1
		reward(0, "Shiny Spoon (%d / %d)" % [Game.flags["spoons_found"], SPOONS.size()])
		await lv.wait(0.3)
		return
	match n:
		"leave_room":
			await leave()
		# ---- Chief's Hut
		"chief_home_seen":
			Game.set_flag("chiefHomeSeen")
		"take_conditioner":
			Game.set_flag("chestLooted")
			Game.inv["conditioner"] = int(Game.inv.get("conditioner", 0)) + 1
			reward(10, "Got: Backup Conditioner (use it in your inventory for +15 max HP)")
			await lv.wait(0.6)
		"xylo_nap":
			Game.set_flag("xyloNapped")
			await lv.fade_out(0.6)
			await lv.wait(1.2)
			lv.fade_in(0.6)
			reward(10)
			await lv.wait(0.5)
		# ---- Bar
		"start_bar_tab":
			Game.set_flag("barTabStarted")
			Game.start_quest("bar_tab", R.QUESTS["bar_tab"][0], R.QUESTS["bar_tab"][1])
		"check_beezy":
			Game.set_flag("has3Beezy", Game.inv["beer"] >= 3)
		"pay_tab":
			Game.inv["beer"] -= 3
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
			Game.inv["beer"] += 2
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
				Game.inv["beer"] += 1
				reward(5, "Got: Beezy (from the tip jar)")
		"gulpo_chug":
			if Game.quest_state("chug_rematch") == "":
				Game.start_quest("chug_rematch", R.QUESTS["chug_rematch"][0], R.QUESTS["chug_rematch"][1])
			var won: bool = await lv._chug_game("Gulpo (Bar Champion, Liver of Steel)", 1.1)
			if won:
				Game.set_flag("chugRematchWon")
				Game.finish_quest("chug_rematch")
				Game.inv["beer"] += 2
				reward(25, "Beat Gulpo · Got: Beezy ×2")
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
			lv.objective("Get Grubnik's lucky spoon back from the Goblin Patrol (east road).")
		"finish_lucky_spoon":
			Game.start_quest("lucky_spoon", R.QUESTS["lucky_spoon"][0], R.QUESTS["lucky_spoon"][1])
			Game.finish_quest("lucky_spoon")
			Game.give_gear("weighted_d6")
			reward(30, "Got: Weighted d6 (Crash Out can't roll a 1)")
			lv.objective("Head east to the Metocy Mart.")
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
			Game.inv["vol9"] = int(Game.inv.get("vol9", 0)) + 1
			Game.finish_quest("lore_off")
			reward(40, "Got: Deloye Lore Vol. 9 (Signed) (read it in your inventory for +15% meter gain)")
			await lv.wait(0.5)
		# ---- Spoonsmith
		"start_shiny_spoons":
			Game.set_flag("smithMet")
			Game.start_quest("shiny_spoons", R.QUESTS["shiny_spoons"][0], R.QUESTS["shiny_spoons"][1])
		"smith_turn_in":
			await _smith_turn_in()
		# ---- Outhouse
		"outhouse_check":
			Game.set_flag("outhouseSkorn", _skorn_here() and not Game.flag("outhouseSkornDone"))
			Game.set_flag("outhouseLykor", not Game.flag("outhouseLykorDone"))
			Game.set_flag("outhouseXylo", not Game.flag("outhouseXyloDone"))
		"outhouse_skorn":
			await _outhouse_trip("skorn")
			Game.set_flag("outhouseSkornDone")
			Game.inv["bowl"] += 1
			reward(5, "Got: Chipotle Bowl (sealed) (allegedly)")
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

func _smith_turn_in() -> void:
	var found := int(Game.flags.get("spoons_found", 0))
	var turned := int(Game.flags.get("spoons_turned", 0))
	if found <= turned:
		await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "No new spoons? Look around. Behind huts. By the fire. Near the outhouse. Wash that one." }]) # DRAFT
		return
	Game.flags["spoons_turned"] = found
	await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "%d spoons! Beautiful. Each one a little shinier than the last. Let me work…" % found }]) # DRAFT
	lv.dialogue.hide_box()
	for k in 4:
		var p: AudioStreamPlayer = lv._sfx(Util.chime(1200.0 + k * 80.0, 160, 0.3), -6.0)
		p.play()
		get_tree().create_timer(0.5).timeout.connect(p.queue_free)
		lv.hop(npc["clank"], 0.2)
		await lv.wait(0.35)
	lv.dialogue.show_box()
	if turned < 3 and found >= 3:
		if Game.give_gear("spoon"):
			reward(20, "Got: Spoon of Destiny (+10% damage)")
			await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "The Spoon of Destiny. I forged destiny into a spoon. It's still a spoon." }]) # DRAFT
		else:
			Game.inv["bowl"] += 2
			reward(20, "Got: Chipotle Bowl ×2")
			await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "You already got the Spoon of Destiny? Fine. I made you two bowls. They're spoon-shaped. Don't ask." }]) # DRAFT
	if turned < 5 and found >= 5:
		Game.give_gear("spoon_mail")
		Game.finish_quest("shiny_spoons")
		reward(30, "Got: Spoon Mail Armor (+3 armor)")
		await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "SPOON MAIL. Armor made of spoons. Every time you get hit it goes 'clink.' That's the sound of protection." }]) # DRAFT
	elif found < 5:
		await run_lines([{ "who": "goblin", "name": R.CLANK, "line": "Bring me %d more and I'll make you armor. Spoon armor. The best armor. The only armor I make." % (SPOONS.size() - found) }]) # DRAFT

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
	Game.inv = { "beer": 3, "bowl": 0 }
	var part := OS.get_environment("TOUR_PART")
	await lv.wait(1.0)
	if part == "" or part == "1":
		lv.place_party(Vector3(0, 0, 3), Vector3(0, 0, -1))
		lv.target_yaw = 0.0
		await lv.wait(1.5)
		await lv.shot("b_00_village")
		await auto_talk("board", [], "b_01_board", 2)
		await auto_talk("grubnik", [], "b_02_grubnik", 2)
		await auto_talk("door_chief")
		await lv.wait(1.0)
		await lv.shot("b_03_chief_room")
		await auto_talk("chief", [], "b_04_chief", 1)
		await auto_talk("chest", [], "b_05_chest", 2)
		await auto_talk("bed")
		await auto_talk("exit")
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
		for i in SPOONS.size():
			await auto_talk("spoon_%d" % i)
		await lv.shot("b_13_spoons")
		await auto_talk("door_smith")
		await lv.wait(1.0)
		await lv.shot("b_14_smith_room")
		await auto_talk("clank", [], "b_15_clank", 2)
		await auto_talk("clank")
		await auto_talk("exit")
		await auto_talk("outhouse", [0], "b_16_outhouse", 1)
		await auto_talk("outhouse", [0])
		Game.set_flag("luckySpoonFound")
		await auto_talk("grubnik", [], "b_17_grubnik_return", 2)
		lv.open_party_menu()
		await lv.wait(1.0)
		await lv.shot("b_18_party_quests")
		lv._close_menu()
	print("TOUR DONE  xp=", Game.xp, " level=", Game.level, " gear=", Game.gear_owned, " quests=", Game.quests, " inv=", Game.inv)
	get_tree().quit()
