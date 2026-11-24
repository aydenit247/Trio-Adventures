# Area: Metocy Mart (Scene 3, played as Xylo). Evening, foggy.
# Outside: walk up to the shop → Dulbers pops out → go inside.
# Inside: the "metocy" → choose: A everyone takes it · B Skorn first · C refuse · D Xylo inspects · E goblins (secret)
# The shop front and the shop room are real 3D builds based on Ebain's paintings (mart_exterior.jpg /
# mart_interior.jpg in assets/backdrops are the reference). Camera stays facing the shop (no camera turning here).
extends Level

const MS = preload("res://scripts/mart_script.gd")
const INT := Vector3(300, 0, 0)                    # the shop room is built off to the side
const DOOR_OUT := Vector3(-2.9, 0, -10.5)          # in front of the painted door
const COUNTER := INT + Vector3(0, 0, -3.0)
const DOOR_IN := INT + Vector3(5.2, 0, 2.8)
const EXIT_POS := Vector3(14, 0, 0)

# "outside" → "arrived" (go inside) → "inside" → "after" (walk east) → "end"
var stage := "outside"
var inside := false
var dulbers: Unit
var pill: Sprite3D
var pill_light: OmniLight3D
var tripping := false
var trip_overlay: ColorRect
var allies: Array[Unit] = []
var chief: Unit
var pass_sign: Node3D

func _configure() -> void:
	night = true
	light_dir = Vector3(0.5, 0.25, -0.8)
	clear_center = Vector2(0, -2)
	clear_radius = 7.0
	path_pts = PackedVector2Array([Vector2(0, 16), Vector2(0, 6), Vector2(-1.5, -4), Vector2(-2.9, -11), Vector2(0, -1), Vector2(8, 0), Vector2(16, 0)])
	path_width = 1.8
	subtitle = "Scene 3 — Metocy Mart"
	party_ids = ["xylo", "lykor"] if Game.flag("skornKing") and not Game.flag("martDone") else ["xylo", "lykor", "skorn"]
	party_start = [Vector3(0, 0, 10), Vector3(-1, 0, 12), Vector3(1, 0, 12)]
	leader_id = "xylo"
	cam_locked = true
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	talk = {
		"lykor": [{ "who": "lykor", "mood": "smug", "line": "A store in the middle of nowhere. Totally normal." }], # DRAFT
		"skorn": [{ "who": "skorn", "mood": "confused", "line": "You think they got snacks?" }], # DRAFT
	}

func _build_level() -> void:
	# ---- outside: the shop as a real 3D building, built from Ebain's painting
	_shop_exterior()
	for k in 14:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(8.5, 16.0), 0, rng.randf_range(-11, 14))
		if p.x > 0 and abs(p.z) < 3.0:
			continue
		card("tree_%d" % (rng.randi() % 4 + 1), rng.randf_range(6.0, 9.0), p, rng.randf() < 0.5, true)
	for k in 12:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(6.5, 9.0), 0, rng.randf_range(-9, 12))
		if p.x > 0 and abs(p.z) < 3.0:
			continue
		if rng.randf() < 0.7:
			card("bush_%d" % (rng.randi() % 3 + 1), rng.randf_range(1.2, 2.0), p, rng.randf() < 0.5, true)
		else:
			Models.place(self, "namaqualand_boulder_05", p, rng.randf() * TAU, rng.randf_range(1.0, 1.6), true, Color(0.6, 0.62, 0.7))
	_walls(Vector3.ZERO, 9.5, -11.5, 14.0, true)
	_mart_props()
	# ---- inside: the shop room
	_build_room()
	dulbers = spawn_npc("dulbers", "Dulbers Frint", "dulbers", 1.3, DOOR_OUT + Vector3(0, 0, -0.5))
	dulbers.visible = false
	if Game.flag("goblinAllies"):
		chief = spawn_npc("chief", "Chief Bogdrinker", "goblin_chief", 1.45, Vector3(0, 0, 14))
		chief.set_meta("follow", true)
		chief.set_meta("follow_i", 0)
		allies.append(chief)
		for i in 3:
			var g := spawn_npc("goblin", "Goblin", "goblin", rng.randf_range(1.1, 1.3), Vector3(rng.randf_range(-2, 2), 0, 15 + i))
			g.set_meta("follow", true)
			g.set_meta("follow_i", i + 1)
			allies.append(g)

func _walls(c: Vector3, half_x: float, back_z: float, front_z: float, east_gap: bool) -> void:
	Util.static_box(self, c + Vector3(-half_x, 1, (back_z + front_z) / 2.0), Vector3(0.5, 2, front_z - back_z))
	if east_gap:
		Util.static_box(self, c + Vector3(half_x, 1, (back_z - 2.2) / 2.0), Vector3(0.5, 2, -2.2 - back_z))
		Util.static_box(self, c + Vector3(half_x, 1, (front_z + 2.2) / 2.0), Vector3(0.5, 2, front_z - 2.2))
		Util.static_box(self, c + Vector3(18, 1, 0), Vector3(0.5, 2, 8))
		Util.static_box(self, c + Vector3(13.5, 1, -2.4), Vector3(9, 2, 0.5))
		Util.static_box(self, c + Vector3(13.5, 1, 2.4), Vector3(9, 2, 0.5))
	else:
		Util.static_box(self, c + Vector3(half_x, 1, (back_z + front_z) / 2.0), Vector3(0.5, 2, front_z - back_z))
	Util.static_box(self, c + Vector3(0, 1, back_z), Vector3(half_x * 2, 2, 0.5))
	Util.static_box(self, c + Vector3(0, 1, front_z), Vector3(half_x * 2, 2, 0.5))

# ================================================================ the shop as a real building (inspired by Ebain's painting)
const SHOP_X := -1.5          # centre of the shop front
const SHOP_FRONT := -11.3     # z of the front wall
var room_lights: Array = []   # interior lights (they go wild when everyone trips)
var glow_jars: Array = []     # blue jar material (turns pink when tripping)

func _shop_exterior() -> void:
	var planks := Models.mat("weathered_planks", 1.4, Color(0.75, 0.66, 0.58))
	var beam := Models.mat("weathered_planks", 1.0, Color(0.42, 0.33, 0.27))
	var stone := Models.mat("rustic_stone_wall", 1.6, Color(0.7, 0.7, 0.75))
	var roof := Models.mat("grey_roof_tiles", 1.4, Color(0.62, 0.64, 0.7))
	var f := SHOP_FRONT
	var w := 11.0
	var d := 6.0
	var c := Vector3(SHOP_X, 0, f - d / 2.0)
	# stone footing + plank body
	Models.block(self, c + Vector3(0, 0.15, 0), Vector3(w + 0.3, 0.3, d + 0.3), stone, 0.0, true)
	Models.block(self, c + Vector3(0, 0.3 + 1.7, 0), Vector3(w, 3.4, d), planks)
	Util.static_box(self, c + Vector3(0, 1.5, 0), Vector3(w, 3.0, d))
	# timber frame on the front: posts + beams
	for x in [-w / 2.0, -2.6, -0.5, w / 2.0]:
		Models.block(self, Vector3(SHOP_X + x, 2.0, f + 0.08), Vector3(0.24, 3.4, 0.2), beam)
	for y in [0.45, 3.6]:
		Models.block(self, Vector3(SHOP_X, y, f + 0.1), Vector3(w + 0.2, 0.22, 0.22), beam)
	# gable roof (ridge runs left-right) + overhang
	var pitch := deg_to_rad(36.0)
	var run := d / 2.0 + 0.7
	var slope := run / cos(pitch)
	for s in [-1.0, 1.0]:
		var rp := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w + 1.2, 0.16, slope)
		rp.mesh = bm
		rp.material_override = roof
		rp.position = c + Vector3(0, 3.7 + tan(pitch) * run / 2.0, s * run / 2.0)
		rp.rotation.x = s * pitch
		add_child(rp)
	for s in [-1.0, 1.0]:   # gable ends (triangles filled with planks)
		var tri := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(d, tan(pitch) * d / 2.0, 0.2)
		tri.mesh = pm
		tri.material_override = planks
		tri.position = c + Vector3(s * w / 2.0, 3.7 + tan(pitch) * d / 4.0, 0)
		tri.rotation.y = PI / 2.0
		add_child(tri)
	Models.cylinder(self, c + Vector3(-3.6, 3.6, -1.2), 0.45, 0.42, 3.0, stone, 10)   # chimney
	_smoke_at(c + Vector3(-3.6, 6.7, -1.2))
	# the door (a real one) + step
	var door := Models.place(self, "large_castle_door", Vector3(DOOR_OUT.x, 0.28, f + 0.05), 0.0, 0.72)
	door.name = "ShopDoor"
	Models.block(self, Vector3(DOOR_OUT.x, 0.12, f + 0.45), Vector3(1.8, 0.24, 0.6), stone)
	# window right of the door: glowing blue shelves behind a lattice
	_shop_window(Vector3(SHOP_X + 0.6, 1.75, f), Vector2(1.7, 1.25))
	# display window with a canvas awning and a ledge of bottles
	_shop_window(Vector3(SHOP_X + 3.3, 1.65, f), Vector2(2.0, 1.4))
	Models.block(self, Vector3(SHOP_X + 3.3, 0.85, f + 0.35), Vector3(2.4, 0.1, 0.6), beam)
	Models.place(self, "wine_bottles_01", Vector3(SHOP_X + 2.5, 0.9, f + 0.35), 0.0, 1.0)
	Models.place(self, "ceramic_vase_01", Vector3(SHOP_X + 3.9, 0.9, f + 0.3), 0.0, 1.0)
	Models.place(self, "brass_vase_01", Vector3(SHOP_X + 4.3, 0.9, f + 0.4), 0.0, 0.7)
	var canvas := Models.mat("fabric_pattern_05", 1.2, Color(0.72, 0.66, 0.52))
	var aw := MeshInstance3D.new()
	var am := BoxMesh.new()
	am.size = Vector3(3.0, 0.05, 1.8)
	aw.mesh = am
	aw.material_override = canvas
	aw.position = Vector3(SHOP_X + 3.3, 2.75, f + 0.85)
	aw.rotation.x = deg_to_rad(22.0)
	add_child(aw)
	for x in [1.9, 4.7]:
		Models.block(self, Vector3(SHOP_X + x, 1.25, f + 1.7), Vector3(0.12, 2.5, 0.12), beam, 0.0, true)
	# hanging sign on a bracket over the door
	Models.block(self, Vector3(DOOR_OUT.x - 0.9, 3.25, f + 0.75), Vector3(0.1, 0.1, 1.5), beam)
	var sign_board := Models.block(self, Vector3(DOOR_OUT.x - 0.9, 2.75, f + 1.35), Vector3(0.08, 0.75, 1.6), planks)
	sign_board.rotation.y = 0.0
	for side in [-1.0, 1.0]:
		var t := Label3D.new()
		t.text = "METOCY\nMART"
		t.font_size = 64
		t.pixel_size = 0.005
		t.modulate = Color(0.95, 0.85, 0.55)
		t.outline_size = 6
		t.outline_modulate = Color(0.1, 0.06, 0.03)
		t.position = Vector3(DOOR_OUT.x - 0.9 + side * 0.05, 2.78, f + 1.35)
		t.rotation.y = side * PI / 2.0
		add_child(t)
	var front_sign := Label3D.new()   # painted lettering over the door, facing the street
	front_sign.text = "METOCY MART  ·  NO REFUNDS"
	front_sign.font_size = 56
	front_sign.pixel_size = 0.006
	front_sign.modulate = Color(0.95, 0.82, 0.5)
	front_sign.outline_size = 8
	front_sign.outline_modulate = Color(0.08, 0.05, 0.02)
	front_sign.position = Vector3(SHOP_X, 3.25, f + 0.22)
	add_child(front_sign)
	# oil lamps by the door
	for x in [DOOR_OUT.x - 0.95, DOOR_OUT.x + 1.0]:
		Models.block(self, Vector3(x, 2.6, f + 0.25), Vector3(0.06, 0.06, 0.4), beam)
		Models.place(self, "vintage_oil_lamp", Vector3(x, 1.85, f + 0.42), 0.0, 0.9)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.68, 0.38)
		l.light_energy = 1.6
		l.omni_range = 5.5
		l.position = Vector3(x, 2.3, f + 0.6)
		add_child(l)
		add_glow(l.position, Color(1.0, 0.7, 0.4), 5.0, func(): return 0.9)
	# the old stone town behind it
	_house(Vector3(-12.5, 0, -16.5), Vector3(6.5, 6.5, 6.0), 0.15)
	_house(Vector3(9.5, 0, -17.0), Vector3(7.0, 5.8, 6.0), -0.1)
	_house(Vector3(-1.0, 0, -24.0), Vector3(12.0, 8.0, 6.0), 0.0)
	_house(Vector3(-20.0, 0, -12.0), Vector3(6.0, 5.5, 6.0), 0.5)
	# big dead trees framing it like the painting
	card("tree_2", 11.0, Vector3(-8.6, 0, -15.0), false, false)
	card("tree_4", 10.0, Vector3(6.2, 0, -16.0), true, false)

func _shop_window(p: Vector3, size: Vector2) -> void:
	var beam := Models.mat("weathered_planks", 1.0, Color(0.4, 0.31, 0.25))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.25, 0.5, 0.95)
	glass.emission_enabled = true
	glass.emission = Color(0.3, 0.6, 1.0)
	glass.emission_energy_multiplier = 1.6
	glow_jars.append(glass)
	var q := QuadMesh.new()
	q.size = size
	Util.add_mesh(self, q, glass, p + Vector3(0, 0, 0.12))
	for i in 3:   # bottle silhouettes on two little shelves behind the glass
		for row in 2:
			var b := CylinderMesh.new()
			b.top_radius = 0.035
			b.bottom_radius = 0.06
			b.height = 0.22
			Util.add_mesh(self, b, Util.mat(Color(0.05, 0.08, 0.15)), p + Vector3(-size.x * 0.3 + i * size.x * 0.3, -0.3 + row * 0.5, 0.15))
	for k in [-1.0, 1.0]:   # lattice + frame
		Models.block(self, p + Vector3(k * size.x / 2.0, 0, 0.18), Vector3(0.12, size.y + 0.2, 0.1), beam)
		Models.block(self, p + Vector3(0, k * size.y / 2.0, 0.18), Vector3(size.x + 0.2, 0.12, 0.1), beam)
	Models.block(self, p + Vector3(0, 0, 0.19), Vector3(0.05, size.y, 0.05), beam)
	Models.block(self, p + Vector3(0, 0, 0.19), Vector3(size.x, 0.05, 0.05), beam)
	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 0.6, 1.0)
	l.light_energy = 1.4
	l.omni_range = 4.0
	l.position = p + Vector3(0, 0, 0.9)
	add_child(l)

func _house(c: Vector3, size: Vector3, rot: float) -> void:
	var stone := Models.mat("castle_wall_slates", 2.0, Color(0.55, 0.57, 0.65))
	var roof := Models.mat("grey_roof_tiles", 1.6, Color(0.5, 0.52, 0.58))
	var root := Node3D.new()
	root.position = c
	root.rotation.y = rot
	add_child(root)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	body.mesh = bm
	body.material_override = stone
	body.position = Vector3(0, size.y / 2.0, 0)
	root.add_child(body)
	var rf := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(size.x + 0.6, size.y * 0.45, size.z + 0.6)
	rf.mesh = pm
	rf.material_override = roof
	rf.position = Vector3(0, size.y + size.y * 0.225, 0)
	root.add_child(rf)
	for k in 4:   # windows, one or two lit
		var lit := k == 1 or (k == 3 and size.x > 8.0)
		var wm := Util.mat(Color(1.0, 0.7, 0.35) if lit else Color(0.04, 0.04, 0.06))
		if lit:
			wm.emission_enabled = true
			wm.emission = Color(1.0, 0.65, 0.3)
			wm.emission_energy_multiplier = 1.2
		var q := QuadMesh.new()
		q.size = Vector2(0.8, 1.1)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = wm
		mi.position = Vector3(-size.x * 0.32 + (k % 2) * size.x * 0.64, size.y * (0.35 if k < 2 else 0.72), size.z / 2.0 + 0.02)
		root.add_child(mi)
	Util.static_box(self, c + Vector3(0, size.y / 2.0, 0), size, rot)

func _smoke_at(p: Vector3) -> void:
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
	sm.color_ramp = Fx.ramp([[0.0, Color(0.5, 0.5, 0.55, 0)], [0.2, Color(0.45, 0.45, 0.5, 0.25)], [1.0, Color(0.5, 0.5, 0.55, 0)]])
	sm.position = p
	add_child(sm)

# The shop room: plank walls, tall shelves of jars (some glowing blue), books, hanging herbs, candles
func _shop_interior() -> void:
	var dark := Models.mat("weathered_planks", 1.0, Color(0.5, 0.42, 0.36))
	var wall := Models.mat("raw_plank_wall", 2.0, Color(0.7, 0.62, 0.55))
	Models.block(self, INT + Vector3(0, 3.5, -5.0), Vector3(14, 7, 0.3), wall)                  # back wall
	for x in [-6.9, 6.9]:
		Models.block(self, INT + Vector3(x, 3.5, 0), Vector3(0.3, 7, 11), wall)                   # side walls
	for z in [-3.5, -0.5, 2.5]:                                                                     # ceiling beams
		Models.block(self, INT + Vector3(0, 5.2, z), Vector3(14, 0.3, 0.3), dark)
	# tall shelves along the back wall, packed with jars
	for x in [-5.0, -2.6, 2.6, 5.0]:
		_shelf(INT + Vector3(x, 0, -4.55), 2.1, 3.4)
	_shelf(INT + Vector3(-6.45, 0, -1.8), 2.1, 3.0, PI / 2.0)
	_shelf(INT + Vector3(6.45, 0, -1.2), 2.1, 3.0, -PI / 2.0)
	# hanging herbs + a couple of skull-ish jars of… something
	for k in 9:
		var hx := -5.5 + k * 1.35
		Models.block(self, INT + Vector3(hx, 4.65, -3.5), Vector3(0.03, 0.8, 0.03), dark)
		_box_c(INT + Vector3(hx, 4.15, -3.5), Vector3(0.22, 0.45, 0.22), Color(0.32, 0.4, 0.2) if k % 2 == 0 else Color(0.45, 0.32, 0.18))
	# counter clutter: scale-ish vase, magnifying glass (for Xylo), books, oil lamp
	Models.place(self, "book_encyclopedia_set_01", COUNTER + Vector3(-0.9, 1.06, -0.45), 0.2, 1.0)
	Models.place(self, "magnifying_glass_01", COUNTER + Vector3(0.6, 1.07, -0.35), 0.0, 1.2).rotation = Vector3(-PI / 2.0, 0.5, 0)
	Models.place(self, "vintage_oil_lamp", COUNTER + Vector3(1.15, 1.06, -0.5), 0.0, 0.7)
	Models.place(self, "antique_ceramic_vase_01", INT + Vector3(-3.8, 0, -3.9), 0.0, 1.4)
	Models.place(self, "brass_vase_01", INT + Vector3(3.8, 0, -3.9), 0.0, 1.2)

func _shelf(base: Vector3, w: float, h: float, rot := 0.0) -> void:
	var wood := Models.mat("weathered_planks", 0.9, Color(0.42, 0.32, 0.25))
	var root := Node3D.new()
	root.position = base
	root.rotation.y = rot
	add_child(root)
	var parts := []
	for s in [-1.0, 1.0]:
		parts.append([Vector3(s * w / 2.0, h / 2.0, 0), Vector3(0.08, h, 0.45)])
	var rows := 5
	for r in rows:
		parts.append([Vector3(0, 0.15 + r * (h - 0.3) / (rows - 1), 0), Vector3(w, 0.05, 0.45)])
	parts.append([Vector3(0, h / 2.0, -0.21), Vector3(w, h, 0.03)])
	for pt in parts:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = pt[1]
		mi.mesh = bm
		mi.material_override = wood
		mi.position = pt[0]
		root.add_child(mi)
	for r in rows - 1:   # jars on every shelf
		var y: float = 0.175 + r * (h - 0.3) / (rows - 1)
		var x := -w / 2.0 + 0.2
		while x < w / 2.0 - 0.15:
			var jh := randf_range(0.18, 0.42)
			var jr := randf_range(0.06, 0.12)
			var glow := randf() < 0.3
			var cm := CylinderMesh.new()
			cm.top_radius = jr * 0.85
			cm.bottom_radius = jr
			cm.height = jh
			var m: StandardMaterial3D
			if glow:
				m = _blue_glass()
			else:
				m = Util.mat([Color(0.35, 0.25, 0.15), Color(0.2, 0.25, 0.18), Color(0.45, 0.4, 0.32), Color(0.15, 0.12, 0.1)][randi() % 4])
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = m
			mi.position = Vector3(x, y + jh / 2.0, randf_range(-0.05, 0.08))
			root.add_child(mi)
			x += jr * 2.0 + randf_range(0.04, 0.12)
	Util.static_box(self, base + Vector3(0, h / 2.0, 0), Vector3(w, h, 0.5), rot)

var _blue_mat: StandardMaterial3D
func _blue_glass() -> StandardMaterial3D:
	if _blue_mat == null:
		_blue_mat = StandardMaterial3D.new()
		_blue_mat.albedo_color = Color(0.3, 0.6, 1.0)
		_blue_mat.emission_enabled = true
		_blue_mat.emission = Color(0.25, 0.55, 1.0)
		_blue_mat.emission_energy_multiplier = 2.2
		glow_jars.append(_blue_mat)
	return _blue_mat

func _box_c(p: Vector3, size: Vector3, c: Color) -> void:
	var bm := BoxMesh.new()
	bm.size = size
	Util.add_mesh(self, bm, Util.mat(c), p)

# Tripping: the room's lights and glowing jars go purple/pink instead of swapping a painting
func _trip_room(on: bool) -> void:
	for l in room_lights:
		l.light_color = Color(0.85, 0.35, 1.0) if on else Color(1.0, 0.7, 0.4)
	for m in glow_jars:
		m.emission = Color(1.0, 0.3, 0.8) if on else Color(0.25, 0.55, 1.0)
		m.albedo_color = Color(1.0, 0.4, 0.85) if on else Color(0.3, 0.6, 1.0)

# Real props in front of the shop (Poly Haven, CC0): cobblestones, barrels, crates, sacks, lantern posts
func _mart_props() -> void:
	Models.patch(self, Vector3(-0.5, 0, -8.0), Vector2(19, 9), "cobblestone_floor_04", 2.2, Color(0.32, 0.33, 0.4))
	var sack := Color(0.95, 0.8, 0.6)
	Models.place(self, "wine_barrel_01", Vector3(-7.4, 0, -10.0), 0.4, 1.0, true)
	Models.place(self, "wine_barrel_01", Vector3(-6.6, 0, -9.3), 1.7, 0.95, true)
	Models.place(self, "wooden_crate_02", Vector3(-5.6, 0, -10.2), 1.5, 1.0, true)
	Models.place(self, "wooden_crate_01", Vector3(-5.6, 0.46, -10.2), 1.4, 0.95)
	Models.place(self, "compost_bag_02", Vector3(-6.0, 0, -8.9), 0.6, 1.1, false, sack)
	Models.place(self, "compost_bag_02", Vector3(-6.4, 0, -8.5), 2.3, 1.0, false, sack)
	Models.place(self, "wine_barrel_01", Vector3(6.4, 0, -10.0), 0.9, 1.0, true)
	Models.place(self, "wooden_crate_02", Vector3(7.6, 0, -9.4), 0.2, 1.0, true)
	Models.place(self, "compost_bag_02", Vector3(5.6, 0, -9.0), 1.2, 1.1, false, sack)
	Models.place(self, "wooden_crate_01", Vector3(4.6, 0, -9.8), 0.3, 1.0, true)
	Models.place(self, "wooden_bucket_01", Vector3(5.0, 0, -8.6), 0.0, 1.0)
	var post := Models.mat("weathered_planks", 1.0, Color(0.6, 0.5, 0.42))
	for x in [-4.6, 1.6]:   # lantern posts flanking the path to the door
		Models.block(self, Vector3(x, 1.1, -8.4), Vector3(0.16, 2.2, 0.16), post, 0.0, true)
		Models.block(self, Vector3(x + 0.25, 2.15, -8.4), Vector3(0.6, 0.1, 0.1), post)
		Models.place(self, "wooden_lantern_01", Vector3(x + 0.5, 1.65, -8.4), 0.0, 0.9)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.2
		l.omni_range = 5.0
		l.position = Vector3(x + 0.5, 1.9, -8.4)
		add_child(l)
		add_glow(l.position, Color(1.0, 0.7, 0.4), 4.0, func(): return 0.8)

func _room_props() -> void:
	var dark := Models.mat("weathered_planks", 1.0, Color(0.55, 0.45, 0.4))
	Models.block(self, INT + Vector3(0, 0.5, -3.45), Vector3(3.4, 1.0, 0.7), dark, 0.0, true)       # the counter
	Models.block(self, INT + Vector3(0, 1.03, -3.45), Vector3(3.6, 0.06, 0.85), Models.mat("weathered_planks", 1.0))
	Models.place(self, "wooden_candlestick", INT + Vector3(-1.4, 1.06, -3.5), 0.0, 1.3)
	Models.place(self, "wooden_candlestick", INT + Vector3(1.3, 1.06, -3.4), 0.0, 1.3)
	for x in [-1.4, 1.3]:
		var c := OmniLight3D.new()
		c.light_color = Color(1.0, 0.72, 0.4)
		c.light_energy = 0.9
		c.omni_range = 3.0
		c.position = INT + Vector3(x, 1.5, -3.3)
		add_child(c)
	Models.place(self, "wine_barrel_01", INT + Vector3(-5.6, 0, -3.3), 0.3, 1.0, true)
	Models.place(self, "wine_barrel_01", INT + Vector3(-5.8, 0, -2.2), 1.4, 0.95, true)
	Models.place(self, "wine_barrel_01", INT + Vector3(5.7, 0, -3.1), 2.0, 1.0, true)
	Models.place(self, "wooden_candlestick", INT + Vector3(5.7, 0.87, -3.1), 0.0, 1.3)
	Models.place(self, "compost_bag_02", INT + Vector3(-5.4, 0, 0.4), 0.4, 1.1, false, Color(0.95, 0.8, 0.6))
	Models.place(self, "compost_bag_02", INT + Vector3(-5.9, 0, 1.0), 1.9, 1.0, false, Color(0.95, 0.8, 0.6))
	Models.place(self, "wooden_crate_02", INT + Vector3(5.4, 0, 1.6), 0.0, 1.0, true)
	Models.place(self, "wooden_crate_01", INT + Vector3(5.4, 0.46, 1.6), 0.3, 0.95)
	Models.place(self, "wooden_bookshelf_worn", INT + Vector3(-6.0, 0, -0.9), PI / 2.0, 1.0, true)
	Models.place(self, "wine_bottles_01", INT + Vector3(-5.95, 0.95, -1.2), PI / 2.0, 1.0)
	Models.place(self, "wine_bottles_01", INT + Vector3(-5.95, 1.45, -1.3), PI / 2.0, 1.0)
	Models.place(self, "brass_pot_01", INT + Vector3(-1.2, 0, 2.6), 0.0, 1.2)
	Models.place(self, "ceramic_pot", INT + Vector3(3.9, 0, -3.6), 0.6, 1.0)

func _build_room() -> void:
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(16, 1, 14)
	cs.shape = bs
	cs.position = INT + Vector3(0, -0.5, 0)
	floor_body.add_child(cs)
	add_child(floor_body)
	var pm := PlaneMesh.new()
	pm.size = Vector2(16, 24)
	Util.add_mesh(self, pm, Models.mat("old_wooden_floor_01", 2.0, Color(0.75, 0.65, 0.58)), INT + Vector3(0, 0.001, 5))
	_shop_interior()
	var wall_m := Util.mat(Color(0.1, 0.065, 0.045))
	wall_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var wall := PlaneMesh.new()
	wall.size = Vector2(14, 8)
	Util.add_mesh(self, wall, wall_m, INT + Vector3(-7.0, 4, 2), Vector3(0, 0, -PI / 2.0))
	Util.add_mesh(self, wall, wall_m, INT + Vector3(7.0, 4, 2), Vector3(0, 0, PI / 2.0))
	var shell := PlaneMesh.new()   # dark back wall + ceiling so no sky shows around the backdrop
	shell.size = Vector2(40, 20)
	Util.add_mesh(self, shell, wall_m, INT + Vector3(0, 6, -5.3), Vector3(PI / 2.0, 0, 0))
	Util.add_mesh(self, shell, wall_m, INT + Vector3(0, 7.6, 0), Vector3(PI, 0, 0))
	_walls(INT, 6.5, -4.2, 5.5, false)
	_room_props()
	add_glow(INT + Vector3(0, 1, -1), Color(1.0, 0.72, 0.45), 10.0, func(): return 0.75, true)
	for p in [INT + Vector3(-4.5, 2, -3.5), INT + Vector3(4.5, 2, -3.5), INT + Vector3(0, 3, 0)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.6
		l.omni_range = 8.0
		l.position = p
		add_child(l)
		room_lights.append(l)
	pill = Sprite3D.new()
	pill.texture = load("res://assets/items/metocy.png")
	pill.pixel_size = 0.5 / 447.0
	pill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pill.shaded = false
	pill.position = COUNTER + Vector3(0, 1.4, 0.3)
	pill.visible = false
	add_child(pill)
	pill_light = OmniLight3D.new()
	pill_light.light_color = Color(0.4, 0.7, 1.0)
	pill_light.light_energy = 0.0
	pill_light.omni_range = 4.0
	pill_light.position = pill.position
	add_child(pill_light)

# ---------------------------------------------------------------- per frame
func _level_process(_delta: float) -> void:
	if pill.visible:
		pill.position.y = COUNTER.y + 1.4 + sin(t * 2.2) * 0.06
	if tripping:
		cam.rotation.z = sin(t * 0.9) * 0.05
		trip_overlay.color.a = 0.16 + sin(t * 1.7) * 0.06
		for u in party:
			if u.has_meta("tripping"):
				u.sprite.modulate = Color.from_hsv(fmod(t * 0.1 + u.global_position.x * 0.05, 1.0), 0.35, 1.0)
	if busy:
		return
	if stage == "outside" and leader.global_position.z < 1.5:
		stage = "arrived"
		_arrive()
	elif stage == "after" and leader.global_position.distance_to(EXIT_POS) < 3.0:
		stage = "end"
		_to_pass()

func _to_pass() -> void:
	busy = true
	if Game.flag("giantDone"):   # the giant's already handled: walk straight back into the pass
		await fade_out(0.6)
		Game.travel("res://pass.tscn", "mart", leader.id)
		return
	await fade_out(1.0)
	Game.goto("res://pass.tscn")

# maps: the shop is the one building; inside it (built off to the side at INT) the maps say so
func map_buildings() -> Array:
	return [{ "pos": Vector3(SHOP_X, 0, SHOP_FRONT - 3.0), "name": "Metocy Mart" }]

func map_place() -> String:
	return "Metocy Mart" if leader and leader.global_position.x > 200.0 else ""

func map_place_door() -> Vector3:
	return DOOR_OUT

func _level_interactables() -> Array:
	if stage == "after":
		if inside:
			return [{ "id": "shop_exit", "label": "outside", "verb": "Go", "pos": DOOR_IN, "h": 2.2, "r": 1.8, "steps": [{ "do": "shop_out" }] }]
		return [{ "id": "door", "label": "Metocy Mart", "verb": "Go inside", "pos": DOOR_OUT, "h": 2.4, "r": 2.6, "steps": [{ "do": "shop_in" }] }]
	if stage == "arrived":
		return [
			{ "id": "door", "label": "Metocy Mart", "verb": "Go inside", "pos": DOOR_OUT, "h": 2.4, "r": 3.0, "steps": [{ "do": "enter_shop" }] + MS.SHOP },
			{ "id": "dulbers", "label": "Dulbers Frint", "verb": "Talk to", "node": dulbers, "h": 1.7, "r": 2.0, "steps": MS.DULBERS_WAITING },
		]
	return []

# ---------------------------------------------------------------- story
func _begin() -> void:
	busy = true
	fade_in(1.5)
	await wait(0.8)
	await run_dialogue(MS.INTRO)
	objective("Walk up to the shop.", DOOR_OUT)

func _arrive() -> void:
	focus_override = Vector3(-1.5, 0, -6.5)
	await run_dialogue(MS.ARRIVE)
	focus_override = null
	objective("Go inside the Metocy Mart.", DOOR_OUT)

func _on_action(n: String) -> void:
	match n:
		"shop_in":
			await _shop_in()
		"shop_out":
			await _shop_out()
		"dulbers_appears":
			dulbers.global_position = DOOR_OUT
			dulbers.visible = true
			_poof(DOOR_OUT, Color(0.6, 0.5, 0.9))
			hop(dulbers, 0.5)
			await walk_to(dulbers, leader.global_position + Vector3(-0.8, 0, -2.4), 1.0, 2.5)
			char_label(dulbers, "Dulbers Frint (Not Trustworthy)", 3.5, 1.7)
			await wait(0.4)
		"go_inside":
			await walk_to(dulbers, DOOR_OUT, 1.2, 3.0)
			dulbers.visible = false
		"enter_shop":
			await _enter_shop()
		"show_pill":
			pill.visible = true
			pill.scale = Vector3.ZERO
			create_tween().tween_property(pill, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			create_tween().tween_property(pill_light, "light_energy", 1.5, 0.5)
			char_label(pill, "Metocy (Allegedly)", 3.5, 0.35)
			ui_sfx.play()
			await wait(0.6)
		"skorn_bursts_in":
			var sk := add_to_party("skorn", DOOR_IN)
			shake = 0.3
			whoosh_sfx.play()
			char_label(sk, "Skorn (Former King)", 3.0)
			await walk_to(sk, INT + Vector3(2.4, 0, 1.6), 1.5, 2.5)
		"take_it":
			await _pills_to(party.map(func(u): return u))
			pill.visible = false
			pill_light.light_energy = 0.0
		"trip_start":
			Game.set_flag("skornTripped")
			await _trip(party, true)
		"skorn_trip":
			Game.set_flag("skornTripped")
			await _pills_to([_member("skorn")])
			pill.visible = false
			pill_light.light_energy = 0.0
			await _trip([_member("skorn")], false)
		"reveal_midtocy":
			pill.texture = load("res://assets/items/midtocy.png")
			pill.pixel_size = 0.6 / 792.0
			pill.visible = true
			pill_light.light_color = Color(0.7, 0.3, 0.9)
			pill_light.light_energy = 1.5
			char_label(pill, "Midtocy (Off-Brand)", 3.5, 0.4, Color("#c79bff"))
			shake = 0.2
			await wait(0.6)
		"transform":
			await _transform()
		"fight_dulbers":
			await _fight_dulbers()
		"trip_end":
			await _trip_end()
		"dulbers_vanish", "dulbers_escape":
			_poof(dulbers.global_position, Color(0.6, 0.4, 0.9))
			whoosh_sfx.play()
			dulbers.visible = false
			pill.visible = false
			pill_light.light_energy = 0.0
			if n == "dulbers_escape" or n == "dulbers_vanish":
				Game.set_flag("dulbersEscaped", n == "dulbers_escape")
			await wait(0.6)
		"skorn_pockets", "give_midtocy":
			Game.set_flag("hasMidtocy")
			pill.visible = false
			pill_light.light_energy = 0.0
			ui_sfx.play()
			show_toast("Skorn pocketed: Midtocy (throwable)")
			await wait(0.5)
		"kicked_out":
			await _kicked_out()
		"show_pass_sign":
			_show_pass_sign()
			await wait(0.8)
		"xylo_lore":
			await _xylo_lore()
		"goblins_taste":
			for g in allies:
				hop(g, 0.4)
			await wait(0.6)
		"goblin_chase":
			await _goblin_chase()
		"goblins_go_home":
			Game.set_flag("goblinAllies", false)
			for g in allies:
				g.remove_meta("follow")
				g.set_meta("goal", DOOR_IN + Vector3(1.5, 0, 0))
				g.set_meta("goal_speed", 1.0)
			await wait(1.8)
			for g in allies:
				g.visible = false
		"leave":
			await _leave()

func _member(id: String) -> Unit:
	for u in party:
		if u.id == id:
			return u
	return null

func _poof(p: Vector3, color := Color(0.8, 0.75, 0.7)) -> void:
	play_sound("sfx_pop", -4.0)
	var f := Fx.poof(color)
	f.position = p + Vector3(0, 0.6, 0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)

func _enter_shop() -> void:
	stage = "inside"
	objective("")
	play_sound("sfx_door", -4.0)
	await fade_out(0.5)
	inside = true
	var spots := [INT + Vector3(0, 0, 1.2), INT + Vector3(-2.3, 0, 1.8), INT + Vector3(2.3, 0, 1.8)]
	for i in party.size():
		party[i].global_position = spots[i]
		party[i].set_view("back")
	for i in allies.size():
		allies[i].global_position = INT + Vector3(-4.5 + i * 1.2, 0, 3.6)
	follow_enabled = false
	dulbers.global_position = COUNTER + Vector3(1.4, 0, 0.4)
	dulbers.visible = true
	focus_override = INT + Vector3(0, 0, 0.0)
	cam_target = focus_override
	zoom = 8.5
	cam_height = 0.38
	cam_look_h = 1.8
	fade_in(0.5)
	await wait(0.5)

func _pills_to(targets: Array) -> void:
	for u in targets:
		var m := Sprite3D.new()
		m.texture = pill.texture
		m.pixel_size = pill.pixel_size * 0.5
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.shaded = false
		add_child(m)
		m.global_position = pill.global_position
		var tw := create_tween()
		tw.tween_property(m, "global_position", u.global_position + Vector3(0, 1.6, 0), 0.4)
		tw.tween_callback(m.queue_free)
		await wait(0.12)
	ui_sfx.play()
	await wait(0.5)

func _trip(who: Array, whole_room: bool) -> void:
	whoosh_sfx.pitch_scale = 0.5
	whoosh_sfx.play()
	shake = 0.4
	for u in who:
		var tex: Texture2D = load("res://assets/characters/%s_tweaking.png" % u.id)
		u.set_pose(tex, CHAR_HEIGHT[u.id])
		u.set_meta("tripping", true)
	if whole_room:
		_trip_room(true)
	if trip_overlay == null:
		trip_overlay = ColorRect.new()
		trip_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		trip_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trip_overlay.color = Color(0.55, 0.2, 0.85, 0.0)
		hud.add_child(trip_overlay)
		hud.move_child(trip_overlay, 0)
	tripping = true
	if not whole_room:
		trip_overlay.visible = false
	await wait(0.8)
	whoosh_sfx.pitch_scale = 1.0

func _trip_end() -> void:
	tripping = false
	cam.rotation.z = 0.0
	if trip_overlay:
		trip_overlay.color.a = 0.0
	_trip_room(false)
	for u in party:
		if u.has_meta("tripping"):
			u.remove_meta("tripping")
			u.set_pose(load("res://assets/characters/%s.png" % u.id), CHAR_HEIGHT[u.id])
			for v in ["back", "side"]:
				var p := "res://assets/characters/%s_%s.png" % [u.id, v]
				if ResourceLoader.exists(p):
					u.views[v] = load(p)
	await wait(0.4)

func _transform() -> void:
	shake = 0.8
	whoosh_sfx.pitch_scale = 0.4
	whoosh_sfx.play()
	_poof(dulbers.global_position, Color(0.5, 0.15, 0.6))
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.7, 0.2, 1.0, 0.8)
	hud.add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.7)
	get_tree().create_timer(0.8).timeout.connect(flash.queue_free)
	dulbers.set_pose(load("res://assets/characters/dulbers_demon.png"), 2.7)
	dulbers.set_meta("tint", Color(1.1, 0.95, 1.1))
	char_label(dulbers, "Dulbers Frint (Demon Form, Still Not Trustworthy)", 4.0, 3.0, Color("#c79bff"))
	await wait(1.0)
	whoosh_sfx.pitch_scale = 1.0

func _fight_dulbers() -> void:
	# Whoever took the midtocy fights tripping (path A: everyone, path B: just Skorn)
	var all_trip := true
	for u in party:
		if not u.has_meta("tripping"):
			all_trip = false
	var mods := { "tripping": "party" if all_trip else "skorn" }
	await fight("dulbers", { "enemies": [dulbers], "mods": mods })
	Game.set_flag("dulbersDead")   # Ebain 11/24: beating him here counts as killing him (no summit ambush on this run)
	dulbers.set_pose(load("res://assets/characters/dulbers_demon.png"), 2.7)

func _kicked_out() -> void:
	Game.set_flag("dulbersEscaped")
	await fade_out(0.5)
	inside = false
	pill.visible = false
	pill_light.light_energy = 0.0
	dulbers.visible = false
	for g in allies:
		g.global_position = Vector3(rng.randf_range(-2, 2), 0, -5.0)
	place_party(Vector3(-1.5, 0, -6.0), Vector3(0, 0, 1))
	focus_override = Vector3(1.0, 0, -5.0)
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	shake = 0.3
	fade_in(0.5)
	await wait(0.6)

func _show_pass_sign() -> void:
	pass_sign = Node3D.new()
	pass_sign.position = Vector3(6.5, 0, -2.6)
	add_child(pass_sign)
	card("sign", 2.6, pass_sign.position)
	var s := Label3D.new()
	s.text = "GIANT'S PASS →"
	s.font_size = 44
	s.pixel_size = 0.005
	s.modulate = Color(0.15, 0.08, 0.03)
	s.outline_size = 0
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.position = Vector3(0, 0.75, 0.15)
	pass_sign.add_child(s)
	_poof(pass_sign.position)
	focus_override = Vector3(3.5, 0, -4.0)

func _xylo_lore() -> void:
	var xy := _member("xylo")
	char_label(xy, "Deloye Lore, Vol. ∞", 4.0, 2.4, Color("#ffd27a"))
	var runes := CPUParticles3D.new()
	runes.amount = 40
	runes.lifetime = 1.4
	runes.mesh = Fx.quad(0.12, true)
	runes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	runes.emission_sphere_radius = 1.0
	runes.direction = Vector3.UP
	runes.spread = 40.0
	runes.gravity = Vector3(0, 0.5, 0)
	runes.initial_velocity_min = 0.2
	runes.initial_velocity_max = 0.6
	runes.color_ramp = Fx.ramp([[0.0, Color(1, 0.85, 0.45, 0)], [0.3, Color(1, 0.85, 0.45, 1)], [1.0, Color(1, 0.85, 0.45, 0)]])
	runes.position = xy.global_position + Vector3(0, 1.2, 0)
	add_child(runes)
	get_tree().create_timer(6.0).timeout.connect(runes.queue_free)
	await wait(0.8)

func _goblin_chase() -> void:
	dialogue.hide_box()
	shake = 0.6
	for g in allies:
		g.remove_meta("follow")
		g.set_meta("goal", dulbers.global_position)
		g.set_meta("goal_speed", 1.6)
	await wait(0.8)
	for k in 5:
		_poof(dulbers.global_position + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-0.5, 0.5)), Color(0.75, 0.68, 0.55))
		_sfx(Util.noise_burst(90, 0.6, 1.0), -4.0).play()
		await wait(0.25)
	Game.set_flag("dulbersDead")
	dulbers.visible = false
	pill.visible = false
	pill_light.light_energy = 0.0
	await wait(0.8)
	for g in allies:
		g.remove_meta("goal")
	dialogue.show_box()

func _leave() -> void:
	if inside:
		await fade_out(0.5)
		inside = false
		for g in allies:
			if g.visible:
				g.global_position = Vector3(0, 0, -6)
		place_party(Vector3(-1.5, 0, -6.0), Vector3(0, 0, 1))
		fade_in(0.5)
	if tripping:
		await _trip_end()
	dulbers.visible = false
	pill.visible = false
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	if pass_sign == null:
		_show_pass_sign()
		focus_override = null
	objective("Head east toward the Giant's Pass.", EXIT_POS)
	Game.set_flag("martDone")

# ---------------------------------------------------------------- coming back later (Game.travel / saves)
# Dulbers is gone (escaped, beaten or vanished) in every ending, so the shop is just empty and you can walk in.
func can_resume() -> bool:
	return stage == "after" and not inside

func free_roam() -> bool:
	return stage == "after"

func can_resume_saved() -> bool:
	return Game.flag("martDone")

func _resume(r: Dictionary) -> void:
	inside = false
	dulbers.visible = false
	pill.visible = false
	pill_light.light_energy = 0.0
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	if pass_sign == null:
		_show_pass_sign()
		focus_override = null
	objective("Head east toward the Giant's Pass.", EXIT_POS)
	await super._resume(r)
	for i in allies.size():
		allies[i].global_position = leader.global_position + Vector3(-1.2 + i * 0.8, 0, 1.6)

func back_exit() -> Dictionary:
	if stage == "after" and not inside:
		return { "pos": Vector3(0, 0, 13.0), "r": 2.2, "scene": "res://village.tscn", "name": "Goblin Village" }
	return {}

func arrival(from: String) -> Array:
	if from == "village":
		return [Vector3(0, 0, 8.5), Vector3(0, 0, -1)]
	if from == "pass":
		return [EXIT_POS + Vector3(-5.5, 0, 0), Vector3(-1, 0, 0)]
	return super.arrival(from)

# the empty shop: walk in and out freely once Dulbers is gone
func _shop_in() -> void:
	busy = true
	await fade_out(0.4)
	inside = true
	place_party(INT + Vector3(0, 0, 1.8), Vector3(0, 0, -1))
	for i in allies.size():
		allies[i].global_position = INT + Vector3(-4.5 + i * 1.2, 0, 3.6)
	focus_override = null
	zoom = 8.5
	cam_height = 0.38
	cam_look_h = 1.8
	cam_target = leader.global_position
	fade_in(0.4)
	show_toast("Metocy Mart (Dulbers is gone) (still NO REFUNDS)", 2.0)
	busy = false

func _shop_out() -> void:
	busy = true
	await fade_out(0.4)
	inside = false
	place_party(DOOR_OUT + Vector3(0, 0, 1.6), Vector3(0, 0, 1))
	for i in allies.size():
		allies[i].global_position = DOOR_OUT + Vector3(-1.5 + i * 0.9, 0, 2.6)
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	cam_target = leader.global_position
	fade_in(0.4)
	busy = false

# ---------------------------------------------------------------- automated screenshots (MART_CHOICE=0..4)
func _shot_tour() -> void:
	var choice := int(OS.get_environment("MART_CHOICE")) if OS.get_environment("MART_CHOICE") != "" else 0
	if choice == 4:
		Game.set_flag("goblinAllies")
	var tag := "abcde"[choice]
	fade.color.a = 0.0
	busy = false
	await wait(1.5)
	await shot("m_01_street")
	place_party(Vector3(0, 0, 3.0), Vector3(0, 0, -1))
	await wait(0.6)
	place_party(Vector3(0, 0, 1.0), Vector3(0, 0, -1))
	await wait(1.4)
	await advance(3)
	await wait(2.0)
	await shot("m_02_dulbers")
	await advance(6)
	await wait(2.0)
	place_party(DOOR_OUT + Vector3(0, 0, 1.5), Vector3(0, 0, -1))
	await wait(1.0)
	start(current_interactables().filter(func(i): return i["id"] == "door")[0])
	await wait(2.5)
	await shot("m_03_inside")
	await advance(5, 0.6)
	await wait(1.0)
	await shot("m_04_choice")
	var opts: Array = dialogue._choices
	dialogue._picked.emit(min(choice, opts.size() - 1))
	await wait(1.0)
	for k in 26:
		await advance(1, 0.7)
		if k == 6:
			await shot("m_05_%s_mid" % tag)
		if not dialogue.panel.visible and dialogue.active:
			await wait(5.0)
			await shot("m_06_%s_action" % tag)
		if k == 12:
			await shot("m_07_%s_late" % tag)
	await wait(2.0)
	await shot("m_08_%s_after" % tag)
	place_party(EXIT_POS + Vector3(-2.5, 0, 0), Vector3(1, 0, 0))
	await wait(2.5)
	await shot("m_09_%s_end" % tag)
	get_tree().quit()

const PLANK_SHADER := """
shader_type spatial;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float h(float n) { return fract(sin(n * 91.345) * 47453.12); }
void fragment() {
	vec2 p = wpos.xz;
	float row = floor(p.y / 0.35);
	float x = p.x + h(row) * 3.0;
	float board = floor(x / 2.2);
	float grain = sin((p.y * 40.0) + sin(x * 3.0) * 2.0) * 0.5 + 0.5;
	vec3 base = mix(vec3(0.20, 0.13, 0.08), vec3(0.30, 0.20, 0.12), h(row * 7.0 + board));
	base *= 0.85 + grain * 0.15;
	float seam = smoothstep(0.0, 0.02, fract(p.y / 0.35)) * smoothstep(0.0, 0.02, fract(x / 2.2));
	ALBEDO = base * mix(0.4, 1.0, seam);
	ROUGHNESS = 0.8;
}
"""
