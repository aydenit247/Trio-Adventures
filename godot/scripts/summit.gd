# Area: the Summit Path and the Wizard's Lair (Asar 11/22). The last stop of Chapter 1.
# Past the giant's gorge, a long night climb up the mountain (three empty clearings are saved for future events, see
# EVENT_SPOTS), then a plaza with a huge glowing wizard tower. Walk in: a grand circular hall, and Metocin Mattias on
# his dais. Walking up to him plays SS.MATTIAS_FINALE (Asar + Ebain are writing it), then END OF CHAPTER 1.
# The hall is built off to the side at INT (like the Mart's shop room); walking through the door fades you there.
extends Level

const SS = preload("res://scripts/summit_script.gd")
const START := Vector3(0, 0, 56)
const TOWER := Vector3(0, 0, -72)               # the tower's centre (front wall at z ≈ -63.9)
const DOOR_OUT := Vector3(0, 0, -61.6)          # stand here to go in
const PLAZA := Vector3(0, 0, -52)
const INT := Vector3(400, 0, 0)                 # the hall, built off to the side
const HALL_R := 15.0
const ORB_Y := 10.5
const DAIS := INT + Vector3(0, 0, -10)
const DOOR_IN := INT + Vector3(0, 0, 12.6)
# Empty clearings along the climb for future events (Asar: "potential for other events"). Each has a little scenery
# so it reads as a place, and nothing to interact with yet. Use one by adding an interactable / trigger at its spot.
const EVENT_SPOTS := {
	"overlook": Vector3(-7.5, 0, 31),   # a ledge with a view, broken railing, a bench
	"shrine": Vector3(7.5, 0, 6),       # a little roadside shrine with candles
	"cart": Vector3(-7.5, 0, -22),      # an abandoned cart, crates spilled
}

# walk (the climb) → lair (inside, before Mattias) → finale → end.  After the chapter: free roam.
var stage := "walk"
var inside := false
var mattias: Unit
var mattias_light: OmniLight3D
var floaters: Array = []      # [node, base_y, speed, phase, spin]: bobbing crystals, candles, books, the orb
var spinners: Array = []      # [node, speed]: rune circles, orb rings
var _outdoor := {}

func _configure() -> void:
	if not Game.title_mode:
		Game.set_flag("giantDone")   # reaching the summit means the giant's handled (also fixes older saves)
	night = true
	light_dir = Vector3(0.35, 0.42, -0.84)   # the moon, up behind the tower
	clear_center = Vector2(PLAZA.x, PLAZA.z)
	clear_radius = 6.0
	path_pts = PackedVector2Array([Vector2(0, 64), Vector2(2.5, 52), Vector2(-1.5, 40), Vector2(-3, 30), Vector2(1, 18), Vector2(3.5, 6),
		Vector2(1, -6), Vector2(-3, -18), Vector2(0, -30), Vector2(1, -40), Vector2(0, -50), Vector2(0, -63)])
	path_width = 1.8
	bounds = Rect2(-13.5, -61.6, 27, 125)
	subtitle = "Scene 5 — The Summit Path"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [START, START + Vector3(-1, 0, 1.6), START + Vector3(1, 0, 1.6)]
	leader_id = "skorn"
	cam_locked = true
	zoom = 11.5
	cam_height = 0.34
	cam_look_h = 2.2
	checkpoint = START

func bounds_exempt() -> bool:
	return leader != null and leader.global_position.x > 200.0   # inside the hall

# ================================================================ the climb
func _build_level() -> void:
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 7731
	var cliff := Color(0.5, 0.5, 0.6)
	# mountain walls both sides: real rock faces stacked tall, cool moonlit stone
	for k in 20:
		var z := 66.0 - k * 6.8
		for side in [-1.0, 1.0]:
			var x: float = side * rng2.randf_range(13.5, 16.5)
			var r := Models.place(self, "rock_face_01", Vector3(x, -0.4, z), (PI / 2.0 if side < 0 else -PI / 2.0) + rng2.randf_range(-0.4, 0.4), 1.0, false, cliff * rng2.randf_range(0.8, 1.0))
			r.scale = Vector3(rng2.randf_range(1.8, 2.4), rng2.randf_range(2.6, 4.2), rng2.randf_range(1.8, 2.4))
			_no_shadow(r)
	Util.static_box(self, Vector3(-13.8, 1, 0), Vector3(0.5, 2, 130))
	Util.static_box(self, Vector3(13.8, 1, 0), Vector3(0.5, 2, 130))
	# boulders, rocks and dead trees along the way (kept off the path and out of the event clearings)
	for k in 46:
		var z := rng2.randf_range(-44, 62)
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng2.randf_range(5.8, 12.0), 0, z)
		if _near_spot(p, 5.0):
			continue
		match k % 5:
			0: Models.place(self, "namaqualand_boulder_03", p, rng2.randf() * TAU, rng2.randf_range(0.8, 1.6), true, cliff)
			1: Models.place(self, "namaqualand_boulder_05", p, rng2.randf() * TAU, rng2.randf_range(0.8, 1.5), true, cliff)
			2: Models.place(self, "rock_07", p, rng2.randf() * TAU, rng2.randf_range(10.0, 18.0), true, cliff * Color(0.85, 0.85, 0.95))
			3: Models.place(self, "dead_tree_trunk", p, rng2.randf() * TAU, rng2.randf_range(0.8, 1.1), false, Color(0.35, 0.32, 0.36))
			_: card("tree_%d" % (1 + k % 4), rng2.randf_range(6.0, 8.5), p, rng2.randf() < 0.5, true, 0.5, "props", Color(0.42, 0.4, 0.55))
	Models.patch(self, Vector3(0, 0, 10), Vector2(22, 110), "dark_rock", 3.0, Color(0.62, 0.62, 0.72), 0.0, 0.5)
	# glowing crystals by the path: a few at the bottom, more and brighter toward the lair (they lead you up)
	for k in 16:
		var z := 52.0 - k * 6.6
		var side := -1.0 if k % 2 == 0 else 1.0
		var px: float = _path_x(z) + side * rng2.randf_range(2.4, 3.6)
		var p := Vector3(px, 0, z)
		if _near_spot(p, 3.5):
			continue
		_crystal_cluster(p, 0.5 + 0.06 * k, Color(0.55, 0.4, 1.0) if k % 3 else Color(0.35, 0.65, 1.0), k > 6)
	_event_spots()
	_lair_exterior()
	_hall()

func _after_build() -> void:
	var env: Environment = world_env.environment
	env.ambient_light_color = Color(0.42, 0.4, 0.62)
	env.ambient_light_energy = 0.7
	env.fog_light_color = Color(0.32, 0.26, 0.5)
	env.fog_density = 0.008
	env.volumetric_fog_density = 0.004
	env.glow_intensity = 0.9
	sun_light.light_color = Color(0.7, 0.74, 1.0)
	sun_light.light_energy = 0.9
	for m in find_children("*", "MeshInstance3D", false, false):   # cold rocky ground instead of grass
		var sm = m.material_override if m.material_override else (m.mesh.surface_get_material(0) if m.mesh and m.mesh.get_surface_count() > 0 else null)
		if sm is ShaderMaterial and sm.get_shader_parameter("dirt_tint") != null:
			sm.set_shader_parameter("dirt_tint", Color(0.5, 0.48, 0.55))
			sm.set_shader_parameter("grass_tint", Color(0.34, 0.36, 0.42))

func _near_spot(p: Vector3, r: float) -> bool:
	for k in EVENT_SPOTS:
		if Vector2(p.x, p.z).distance_to(Vector2(EVENT_SPOTS[k].x, EVENT_SPOTS[k].z)) < r:
			return true
	return p.z < -42.0   # the plaza is built separately

func _path_x(z: float) -> float:
	for i in path_pts.size() - 1:
		var a: Vector2 = path_pts[i]
		var b: Vector2 = path_pts[i + 1]
		if z <= a.y and z >= b.y:
			return lerpf(a.x, b.x, (a.y - z) / maxf(a.y - b.y, 0.01))
	return 0.0

func _event_spots() -> void:
	var wood := Color(0.45, 0.38, 0.34)
	# overlook: a flat ledge, a bench, a broken railing at the edge
	var o: Vector3 = EVENT_SPOTS["overlook"]
	Models.patch(self, o, Vector2(6, 5), "monastery_stone_floor", 2.0, Color(0.7, 0.7, 0.78), 0.3, 0.4)
	var plank := Models.mat("dark_wooden_planks", 1.0, wood)
	for k in 4:
		Models.block(self, o + Vector3(-2.6, 0.55, -1.8 + k * 1.2), Vector3(0.14, 1.1, 0.14), plank)
	Models.block(self, o + Vector3(-2.6, 1.0, -0.6), Vector3(0.1, 0.1, 2.6), plank)
	Models.block(self, o + Vector3(0.6, 0.45, 1.2), Vector3(1.8, 0.12, 0.5), plank)
	for x in [-0.2, 1.4]:
		Models.block(self, o + Vector3(x, 0.2, 1.2), Vector3(0.12, 0.4, 0.4), plank)
	# shrine: stone posts, candles, an offering bowl
	var s: Vector3 = EVENT_SPOTS["shrine"]
	var stone := Models.mat("medieval_blocks_05", 1.0, Color(0.6, 0.6, 0.68))
	Models.block(self, s + Vector3(0, 0.6, -0.6), Vector3(1.6, 1.2, 0.8), stone, 0.0, true)
	Models.block(self, s + Vector3(0, 1.75, -0.6), Vector3(1.0, 1.1, 0.5), stone)
	Models.place(self, "wooden_bowl_01", s + Vector3(0, 1.2, -0.45), 0.0, 1.6)
	for x in [-0.55, 0.55]:
		_candle(s + Vector3(x, 1.2, -0.4), 0.9, false)
	# abandoned cart: a wheel, crates, a barrel, a basket
	var c: Vector3 = EVENT_SPOTS["cart"]
	Models.block(self, c + Vector3(0, 0.75, 0), Vector3(2.6, 0.18, 1.4), plank, 0.3, true)
	Models.place(self, "rusted_wheel_rim_01", c + Vector3(-0.6, 0.0, 0.9), 0.3, 1.4).rotation.x = PI / 2.0
	Models.place(self, "wooden_crate_01", c + Vector3(1.6, 0, 0.6), 0.6, 1.0, true)
	Models.place(self, "wooden_crate_02", c + Vector3(2.2, 0, -0.5), 1.4, 1.0, true)
	Models.place(self, "wine_barrel_01", c + Vector3(-1.8, 0, -0.8), 0.0, 0.9, true)
	Models.place(self, "wicker_basket_01", c + Vector3(0.9, 0, 1.6), 0.0, 1.0)

# ================================================================ the tower outside
func _lair_exterior() -> void:
	var brick := Models.mat("castle_brick_07", 3.0, Color(0.58, 0.54, 0.66))
	var blocks := Models.mat("medieval_blocks_05", 2.0, Color(0.62, 0.58, 0.7))
	var roof := Models.mat("grey_roof_tiles", 2.5, Color(0.36, 0.26, 0.56))
	# plaza: worn stone, a glowing rune circle, braziers with blue fire
	Models.patch(self, PLAZA + Vector3(0, 0, -3), Vector2(20, 22), "monastery_stone_floor", 2.5, Color(0.62, 0.6, 0.72), 0.0, 0.3)
	_rune_circle(PLAZA + Vector3(0, 0.04, 0), 4.5, Color(0.6, 0.4, 1.0), 0.15)
	for p in [Vector3(-3.4, 0, -45.5), Vector3(3.4, 0, -45.5), Vector3(-3.4, 0, -57.5), Vector3(3.4, 0, -57.5)]:
		_brazier(p)
	for k in 6:   # floating crystals around the plaza
		var a := TAU * k / 6.0 + 0.3
		var p := PLAZA + Vector3(cos(a) * 7.2, 2.4 + (k % 2) * 0.8, sin(a) * 6.0)
		var cr := _crystal(p, 0.9, Color(0.6, 0.45, 1.0) if k % 2 else Color(0.4, 0.7, 1.0))
		floaters.append([cr, p.y, 0.8 + k * 0.1, k * 1.3, 0.6])
	# the main tower: tall brick drum, buttresses, a band of battlements, a steep purple roof, an orb on top
	Models.cylinder(self, TOWER, 8.2, 7.4, 25.0, brick, 24)
	Util.static_cyl(self, TOWER, 8.3, 6.0)
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		var dir := Vector3(sin(a), 0, cos(a))
		if dir.z > 0.9:
			continue
		Models.block(self, TOWER + dir * 8.2 + Vector3(0, 6, 0), Vector3(1.6, 12, 1.6), blocks, a)
	for y in [0.0, 8.0, 16.0]:   # stone bands break up the drum
		Models.cylinder(self, TOWER + Vector3(0, y, 0), 8.45 - y * 0.03, 8.4 - y * 0.03, 0.9, blocks, 24)
	for h in [3.5, 12.0, 20.0]:   # purple light washing up the front
		_light(TOWER + Vector3(0, h, 11.0), Color(0.6, 0.45, 1.0), 1.4, 9.0)
	Models.cylinder(self, TOWER + Vector3(0, 24.4, 0), 8.6, 8.6, 1.6, blocks, 24)
	for k in 20:
		var a := TAU * k / 20.0
		Models.block(self, TOWER + Vector3(sin(a) * 8.3, 26.6, cos(a) * 8.3), Vector3(1.2, 1.2, 0.8), blocks, a)
	Models.cylinder(self, TOWER + Vector3(0, 26.0, 0), 8.0, 0.3, 15.0, roof, 24)
	var orb := _glow_ball(TOWER + Vector3(0, 43.0, 0), 1.3, Color(0.7, 0.5, 1.0), 6.0, 40.0)
	floaters.append([orb, 43.0, 0.6, 0.0, 0.0])
	# two smaller towers either side
	for side in [-1.0, 1.0]:
		var c: Vector3 = TOWER + Vector3(side * 10.5, 0, 5.0)
		Models.cylinder(self, c, 3.3, 3.0, 17.0, brick, 16)
		Util.static_cyl(self, c, 3.4, 6.0)
		Models.cylinder(self, c + Vector3(0, 16.6, 0), 3.6, 3.6, 1.0, blocks, 16)
		Models.cylinder(self, c + Vector3(0, 17.4, 0), 3.4, 0.2, 8.0, roof, 16)
		_glow_window(c + Vector3(0, 9.0, 3.05), Vector2(0.9, 2.2), Color(0.5, 0.4, 1.0))
	# glowing windows up the front and sides
	for row in [[6.0, 0.0], [11.0, -0.45], [11.0, 0.45], [16.0, 0.0], [20.5, -0.3], [20.5, 0.3]]:
		var a: float = row[1]
		var face := TOWER + Vector3(sin(a) * 8.0, row[0], cos(a) * 8.0)
		_glow_window(face, Vector2(1.1, 2.6), Color(0.62, 0.42, 1.0) if a == 0.0 else Color(0.4, 0.6, 1.0), a)
	# the great door: stone arch, a big castle door, two statues guarding it
	var front := TOWER + Vector3(0, 0, 8.05)
	Models.block(self, front + Vector3(-2.3, 3.0, 0.15), Vector3(1.0, 6.0, 1.0), blocks)
	Models.block(self, front + Vector3(2.3, 3.0, 0.15), Vector3(1.0, 6.0, 1.0), blocks)
	Models.block(self, front + Vector3(0, 6.3, 0.15), Vector3(5.6, 1.2, 1.1), blocks)
	Models.place(self, "large_castle_door", front + Vector3(0, 0, 0.05), 0.0, 1.8, false, Color(0.7, 0.62, 0.78))
	_glow_window(front + Vector3(0, 6.3, 0.72), Vector2(4.2, 0.35), Color(0.75, 0.5, 1.0), 0.0, false)   # a glowing rune band over the door
	for side in [-1.0, 1.0]:
		Models.place(self, "gothic_statue", front + Vector3(side * 4.6, 0, 1.6), PI, 2.2, true, Color(0.62, 0.6, 0.72))
	for k in 3:   # a few low steps up to the door (decor)
		Models.block(self, front + Vector3(0, 0.05 + k * 0.05, 2.2 - k * 0.6), Vector3(6.0 - k * 0.6, 0.1 + k * 0.1, 0.7), blocks)
	wood_sign("sign_wizard_lair", "WIZARD'S LAIR\n(NO SOLICITORS)", Vector3(5.6, 1.4, -48.5), -0.3, 1.8, 0.62, true)   # DRAFT text
	_motes(PLAZA + Vector3(0, 2.5, -4), Vector3(9, 2.5, 9), Color(0.65, 0.5, 1.0), 70)

# ================================================================ the hall inside
func _hall() -> void:
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(40, 1, 40)
	cs.shape = bs
	cs.position = INT + Vector3(0, -0.5, 0)
	floor_body.add_child(cs)
	add_child(floor_body)
	var floor_m := PlaneMesh.new()
	floor_m.size = Vector2(34, 34)
	Util.add_mesh(self, floor_m, Models.mat("marble_mosaic_tiles", 3.0, Color(0.62, 0.58, 0.7)), INT + Vector3(0, 0.001, 0))
	var void_m := Util.mat(Color(0.03, 0.02, 0.05))
	void_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var big := PlaneMesh.new()
	big.size = Vector2(120, 120)
	Util.add_mesh(self, big, void_m, INT + Vector3(0, -0.02, 0))
	Util.add_mesh(self, big, void_m, INT + Vector3(0, 16.0, 0), Vector3(PI, 0, 0))   # dark ceiling
	var wall := Models.mat("castle_brick_07", 3.0, Color(0.5, 0.46, 0.58))
	var trim := Models.mat("medieval_blocks_05", 2.0, Color(0.6, 0.56, 0.68))
	# the round wall: visible on the far side, open toward the camera (still solid all round except the door)
	for k in 24:
		var a := TAU * k / 24.0                     # 0 = straight ahead (north)
		var dir := Vector3(sin(a), 0, -cos(a))
		var p := INT + dir * HALL_R
		var rot := -a
		if dir.z < 0.95 or abs(dir.x) > 0.2:        # every segment but the doorway is solid
			Util.static_box(self, p + Vector3(0, 2, 0), Vector3(4.2, 4, 1.0), rot)
		if dir.z > 0.35:
			continue                                   # camera side: no wall mesh, so you can see in
		Models.block(self, p + Vector3(0, 7.5, 0), Vector3(4.2, 15, 1.0), wall, rot)
		Models.block(self, p + Vector3(0, 0.4, 0) - dir * 0.4, Vector3(4.3, 0.8, 0.4), trim, rot)
		Models.block(self, p + Vector3(0, 14.6, 0) - dir * 0.4, Vector3(4.3, 0.8, 0.5), trim, rot)
		if abs(dir.x) < 0.75 and k % 2 == 0:       # tall glowing windows on the far wall
			_glow_window(p + Vector3(0, 8.0, 0) - dir * 0.52, Vector2(1.6, 5.4), Color(0.45, 0.35, 0.95) if k % 4 == 0 else Color(0.3, 0.55, 1.0), rot)
		elif abs(dir.x) < 0.95:                     # purple banners between them
			Models.block(self, p + Vector3(0, 9.0, 0) - dir * 0.56, Vector3(1.5, 5.0, 0.06), Models.mat("velour_velvet", 1.0, Color(0.42, 0.18, 0.62)), rot)
	# pillars ringing the hall (none on the camera side)
	for k in 10:
		var a := TAU * k / 10.0 + PI / 10.0
		var dir := Vector3(sin(a), 0, -cos(a))
		if dir.z > 0.3:
			continue
		var p := INT + dir * 11.6
		Models.block(self, p + Vector3(0, 0.4, 0), Vector3(2.2, 0.8, 2.2), trim, -a)
		Models.cylinder(self, p, 0.85, 0.75, 13.4, trim, 14)
		Models.block(self, p + Vector3(0, 13.6, 0), Vector3(2.0, 0.8, 2.0), trim, -a)
		Util.static_cyl(self, p, 1.0, 4.0)
	# a long rug up to the dais, the rune circle in the middle, a floating orb with spinning rings over it
	Models.block(self, INT + Vector3(0, 0.02, 1.0), Vector3(3.4, 0.04, 22.0), Models.mat("quatrefoil_jacquard_fabric", 1.6, Color(0.7, 0.32, 0.55)))
	_rune_circle(INT + Vector3(0, 0.05, 1.5), 5.2, Color(0.45, 0.6, 1.0), 0.1)
	var orb := _glow_ball(INT + Vector3(0, ORB_Y, 1.5), 0.75, Color(0.5, 0.7, 1.0), 3.0, 16.0)   # high up: never in front of Mattias
	floaters.append([orb, ORB_Y, 0.7, 0.0, 0.0])
	for k in 2:
		var tm := TorusMesh.new()
		tm.inner_radius = 1.15 + k * 0.45
		tm.outer_radius = 1.25 + k * 0.45
		var ring := Util.add_mesh(self, tm, _emissive(Color(0.6, 0.5, 1.0), 2.5), INT + Vector3(0, ORB_Y, 1.5), Vector3(0.6 + k * 0.9, 0, 0.3))
		spinners.append([ring, 0.7 - k * 1.4])
	# the dais and the throne
	var marble := Models.mat("marble_tiles", 2.0, Color(0.75, 0.72, 0.82))
	for k in 3:
		Models.cylinder(self, DAIS, 6.2 - k * 1.0, 6.2 - k * 1.0, 0.35 * (k + 1), marble, 28)
	Util.static_box(self, DAIS + Vector3(0, 0.52, -0.4), Vector3(7.2, 1.05, 6.6))   # you walk up to it; Mattias stands on top
	var throne_c := DAIS + Vector3(0, 1.05, -2.4)
	var dark := Models.mat("dark_wood", 1.5, Color(0.42, 0.34, 0.4))
	var velvet := Models.mat("velour_velvet", 1.0, Color(0.48, 0.16, 0.68))
	Models.block(self, throne_c + Vector3(0, 0.45, 0), Vector3(2.4, 0.9, 1.8), dark)
	Models.block(self, throne_c + Vector3(0, 0.98, 0.1), Vector3(2.0, 0.16, 1.5), velvet)
	Models.block(self, throne_c + Vector3(0, 3.6, -0.8), Vector3(2.8, 6.2, 0.45), dark)
	Models.block(self, throne_c + Vector3(0, 3.3, -0.55), Vector3(1.9, 4.8, 0.08), velvet)
	for x in [-1.3, 1.3]:
		Models.block(self, throne_c + Vector3(x, 1.4, 0.1), Vector3(0.35, 0.3, 1.7), dark)
		Models.cylinder(self, throne_c + Vector3(x, 6.7, -0.8), 0.32, 0.02, 1.6, dark, 8)
	Models.cylinder(self, throne_c + Vector3(0, 6.7, -0.8), 0.42, 0.02, 2.4, dark, 8)
	var gem := _glow_ball(throne_c + Vector3(0, 5.8, -0.5), 0.32, Color(0.75, 0.45, 1.0), 2.0, 6.0)
	floaters.append([gem, gem.position.y, 1.1, 0.5, 0.0])
	for side in [-1.0, 1.0]:   # giant statues flanking the dais, crystal clusters at its feet
		Models.place(self, "gothic_statue", DAIS + Vector3(side * 7.4, 0, -0.6), -side * 0.5, 2.7, true, Color(0.66, 0.62, 0.76))
		_crystal_cluster(DAIS + Vector3(side * 4.8, 0, 2.6), 1.2, Color(0.55, 0.42, 1.0), true)
	# chandeliers
	var big_ch := Models.place(self, "Chandelier_03", INT + Vector3(0, 13.4, 1.5), 0.0, 4.0)
	_chain(INT + Vector3(0, 13.4, 1.5))
	_light(INT + Vector3(0, 9.4, 1.5), Color(1.0, 0.75, 0.45), 1.8, 14.0)
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var p := INT + Vector3(sin(a) * 7.5, 12.0, -cos(a) * 7.0 + 0.5)
		Models.place(self, "Chandelier_01", p, a, 2.8)
		_chain(p)
		_light(p - Vector3(0, 2.0, 0), Color(1.0, 0.72, 0.42), 0.9, 8.0)
	# bookshelves along the side walls, books floating out of them
	for k in 9:
		var a: float = deg_to_rad(-105.0 + k * 14.0) if k < 5 else deg_to_rad(105.0 - (k - 5) * 14.0)
		if abs(rad_to_deg(a)) < 45.0:
			continue
		var dir := Vector3(sin(a), 0, -cos(a))
		Models.place(self, "wooden_bookshelf_worn", INT + dir * 13.8, -a, 1.7, true, Color(0.62, 0.52, 0.56))
	for k in 10:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := INT + Vector3(side * rng.randf_range(8.5, 11.0), rng.randf_range(3.2, 6.5), rng.randf_range(-7.0, 3.0))
		var b := Models.place(self, "book_encyclopedia_set_01", p, rng.randf() * TAU, 1.8)
		b.rotation.x = rng.randf_range(-0.5, 0.5)
		floaters.append([b, p.y, 0.6 + rng.randf() * 0.5, rng.randf() * TAU, rng.randf_range(-0.6, 0.6)])
	for side in [-1.0, 1.0]:   # tall cabinets by the dais
		Models.place(self, "GothicCabinet_01", INT + Vector3(side * 10.6, 0, -8.6), side * 0.9, 1.35, true, Color(0.62, 0.55, 0.62))
	# west: the alchemy corner (cauldron on a fire pit, a table of lab gear)
	var alc := INT + Vector3(-8.6, 0, 2.5)
	Models.place(self, "round_wooden_table_01", alc, 0.4, 1.3, true, Color(0.55, 0.45, 0.48))
	Models.place(self, "chemistry_set", alc + Vector3(0, 1.31, 0), 0.4, 1.2)
	Models.place(self, "bunsen_burner", alc + Vector3(-0.5, 1.31, 0.4), 0.0, 1.6)
	Models.place(self, "vintage_microscope", alc + Vector3(0.5, 1.31, 0.45), 0.8, 1.6)
	_cauldron(INT + Vector3(-8.0, 0, -3.2))
	# east: the study (armchairs, coffee table, clock, mirror, a bust)
	var st := INT + Vector3(8.6, 0, 2.5)
	Models.place(self, "gothic_coffee_table", st, 0.0, 1.3, true, Color(0.6, 0.5, 0.55))
	Models.place(self, "brass_candleholders", st + Vector3(0, 0.73, 0), 0.4, 0.9)
	Models.place(self, "ArmChair_01", st + Vector3(-1.4, 0, 1.4), PI * 0.8, 1.4, true, Color(0.55, 0.3, 0.62))
	Models.place(self, "ArmChair_01", st + Vector3(1.6, 0, 1.2), -PI * 0.8, 1.4, true, Color(0.55, 0.3, 0.62))
	Models.place(self, "vintage_grandfather_clock_01", INT + Vector3(12.2, 0, -3.4), -PI / 2.0 - 0.3, 1.4, true)
	var mir := Models.place(self, "ornate_mirror_01", INT + Vector3(13.4, 4.2, 0.6), -PI / 2.0 - 0.15, 2.6)
	mir.rotation.y = -PI / 2.0 - 0.15
	Models.block(self, INT + Vector3(6.4, 0.6, -1.6), Vector3(0.7, 1.2, 0.7), marble, 0.0, true)
	Models.place(self, "marble_bust_01", INT + Vector3(6.4, 1.2, -1.6), -0.6, 2.0)
	# floating candles all through the hall
	for k in 22:
		var a := rng.randf() * TAU
		var r := rng.randf_range(3.5, 11.5)
		var p := INT + Vector3(sin(a) * r, rng.randf_range(4.8, 8.5), -cos(a) * r * 0.9)
		if p.z - INT.z > 6.0:
			p.z = INT.z + 6.0 - rng.randf() * 10.0
		var cnd := _candle(p, 1.4, true)
		floaters.append([cnd, p.y, 0.5 + rng.randf() * 0.6, rng.randf() * TAU, 0.0])
	_motes(INT + Vector3(0, 4.5, -1), Vector3(12, 4, 11), Color(0.55, 0.6, 1.0), 120)
	_light(INT + Vector3(0, ORB_Y, 1.5), Color(0.5, 0.65, 1.0), 2.6, 20.0)
	_light(DAIS + Vector3(0, 4.0, 0.5), Color(0.7, 0.45, 1.0), 2.2, 12.0)
	_light(INT + Vector3(0, 6.0, -12.0), Color(0.4, 0.5, 1.0), 1.4, 14.0)
	# Metocin Mattias, on his dais
	mattias = spawn_npc("mattias", "Metocin Mattias", "mattias", 2.2, DAIS + Vector3(0, 1.2, -0.6))
	mattias.set_meta("tint", Color(1.05, 1.1, 1.3))
	mattias_light = OmniLight3D.new()
	mattias_light.light_color = Color(0.45, 0.65, 1.0)
	mattias_light.light_energy = 2.2
	mattias_light.omni_range = 6.0
	mattias_light.position = DAIS + Vector3(0, 2.8, 0.8)
	add_child(mattias_light)

# ================================================================ little builders
func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _light(p: Vector3, c: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = p
	add_child(l)
	return l

func _glow_ball(p: Vector3, r: float, c: Color, energy: float, light_range: float) -> Node3D:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	var n := Util.add_mesh(self, sm, _emissive(c, energy), p)
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = 2.0
	l.omni_range = light_range
	n.add_child(l)
	return n

func _glow_window(p: Vector3, size: Vector2, c: Color, rot_y := 0.0, framed := true) -> void:
	var qm := QuadMesh.new()
	qm.size = size
	Util.add_mesh(self, qm, _emissive(c, 2.2), p, Vector3(0, rot_y, 0))
	if not framed:
		return
	var bar := Util.mat(Color(0.08, 0.06, 0.1))   # lead frame: one upright, two crossbars
	var fwd := Vector3(sin(rot_y), 0, cos(rot_y)) * 0.03
	Models.block(self, p + fwd, Vector3(0.07, size.y, 0.03), bar, rot_y)
	for y in [-0.2, 0.2]:
		Models.block(self, p + fwd + Vector3(0, size.y * y, 0), Vector3(size.x, 0.06, 0.03), bar, rot_y)
	var arch := CylinderMesh.new()   # rounded top
	arch.top_radius = size.x * 0.5
	arch.bottom_radius = size.x * 0.5
	arch.height = 0.02
	arch.radial_segments = 16
	Util.add_mesh(self, arch, _emissive(c, 2.2), p + Vector3(0, size.y * 0.5, 0), Vector3(PI / 2.0, rot_y, 0))

func _crystal(p: Vector3, size: float, c: Color) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.global_position = p
	var top := CylinderMesh.new()
	top.top_radius = 0.0
	top.bottom_radius = 0.28 * size
	top.height = 0.9 * size
	top.radial_segments = 6
	var bot := CylinderMesh.new()
	bot.top_radius = 0.28 * size
	bot.bottom_radius = 0.0
	bot.height = 0.45 * size
	bot.radial_segments = 6
	var m := _emissive(c, 1.8)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(c.r, c.g, c.b, 0.85)
	var a := MeshInstance3D.new(); a.mesh = top; a.material_override = m; a.position = Vector3(0, 0.45 * size, 0); root.add_child(a)
	var b := MeshInstance3D.new(); b.mesh = bot; b.material_override = m; b.position = Vector3(0, -0.225 * size, 0); root.add_child(b)
	return root

func _crystal_cluster(p: Vector3, size: float, c: Color, lit: bool) -> void:
	for k in 4:
		var cr := _crystal(p + Vector3((k % 2) * 0.35 - 0.18, 0.25 * size, int(k / 2) * 0.3 - 0.15), size * (1.0 - k * 0.18), c)
		cr.rotation = Vector3(randf_range(-0.35, 0.35), randf() * TAU, randf_range(-0.35, 0.35))
	if lit:
		_light(p + Vector3(0, 0.8, 0), c, 0.9, 4.0)
		add_glow(p, c, 3.0, func(): return 0.8)

func _candle(p: Vector3, size: float, floating: bool) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.global_position = p
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05 * size
	cm.bottom_radius = 0.05 * size
	cm.height = 0.3 * size
	var wax := MeshInstance3D.new()
	wax.mesh = cm
	wax.material_override = Util.mat(Color(0.92, 0.88, 0.78))
	root.add_child(wax)
	var fm := SphereMesh.new()
	fm.radius = 0.035 * size
	fm.height = 0.11 * size
	var flame := MeshInstance3D.new()
	flame.mesh = fm
	flame.material_override = _emissive(Color(1.0, 0.8, 0.45), 4.0)
	flame.position = Vector3(0, 0.2 * size, 0)
	root.add_child(flame)
	if not floating:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 0.6
		l.omni_range = 2.5
		l.position = Vector3(0, 0.3, 0)
		root.add_child(l)
	return root

func _chain(top: Vector3) -> void:
	Models.block(self, top + Vector3(0, 1.5, 0), Vector3(0.06, 3.0, 0.06), Util.mat(Color(0.2, 0.18, 0.16)))

func _brazier(p: Vector3) -> void:
	var stone := Models.mat("medieval_blocks_05", 1.0, Color(0.55, 0.52, 0.62))
	Models.cylinder(self, p, 0.42, 0.3, 1.1, stone, 10)
	Models.cylinder(self, p + Vector3(0, 1.1, 0), 0.32, 0.62, 0.35, Models.mat("rusty_metal_02", 1.0, Color(0.4, 0.38, 0.42)), 12)
	Util.static_cyl(self, p, 0.5, 2.0)
	var f := Fx.flames(0.9)
	f.color_ramp = Fx.ramp([[0.0, Color(0.85, 0.95, 1.0, 1)], [0.3, Color(0.4, 0.6, 1.0, 0.9)], [0.7, Color(0.45, 0.25, 0.9, 0.5)], [1.0, Color(0.1, 0.05, 0.3, 0)]])
	f.position = p + Vector3(0, 1.5, 0)
	add_child(f)
	_light(p + Vector3(0, 2.0, 0), Color(0.45, 0.6, 1.0), 1.6, 7.0)
	add_glow(p, Color(0.45, 0.6, 1.0), 4.0, func(): return 1.0)

func _cauldron(p: Vector3) -> void:
	Models.place(self, "stone_fire_pit", p, 0.0, 1.5)
	Models.cylinder(self, p + Vector3(0, 0.3, 0), 0.75, 1.2, 1.25, Models.mat("rusty_metal_02", 1.0, Color(0.22, 0.2, 0.24)), 16)
	var lid := CylinderMesh.new()
	lid.top_radius = 1.1
	lid.bottom_radius = 1.1
	lid.height = 0.02
	Util.add_mesh(self, lid, _emissive(Color(0.35, 1.0, 0.45), 2.4), p + Vector3(0, 1.48, 0))
	Util.static_cyl(self, p, 1.3, 2.0)
	var b := CPUParticles3D.new()
	b.amount = 26
	b.lifetime = 1.6
	b.mesh = Fx.quad(0.16, true)
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	b.emission_sphere_radius = 0.8
	b.direction = Vector3.UP
	b.gravity = Vector3(0, 0.6, 0)
	b.initial_velocity_min = 0.2
	b.initial_velocity_max = 0.5
	b.color_ramp = Fx.ramp([[0.0, Color(0.5, 1.0, 0.5, 0.9)], [1.0, Color(0.2, 0.8, 0.3, 0)]])
	b.position = p + Vector3(0, 1.55, 0)
	add_child(b)
	_light(p + Vector3(0, 2.2, 0), Color(0.35, 1.0, 0.45), 1.6, 6.0)
	_crystal_cluster(p + Vector3(-1.8, 0, 1.2), 0.8, Color(0.4, 1.0, 0.6), false)

func _motes(c: Vector3, ext: Vector3, col: Color, n: int) -> void:
	var a := CPUParticles3D.new()
	a.amount = n
	a.lifetime = 6.0
	a.mesh = Fx.quad(0.07, true)
	a.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	a.emission_box_extents = ext
	a.direction = Vector3.UP
	a.spread = 60.0
	a.gravity = Vector3(0, 0.08, 0)
	a.initial_velocity_min = 0.05
	a.initial_velocity_max = 0.25
	a.color_ramp = Fx.ramp([[0.0, Color(col.r, col.g, col.b, 0)], [0.3, col], [1.0, Color(col.r, col.g, col.b, 0)]])
	a.position = c
	add_child(a)

const RUNE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
uniform vec4 col : source_color = vec4(0.6, 0.4, 1.0, 1.0);
float ring(float r, float c, float w) { return smoothstep(w, 0.0, abs(r - c)); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float v = ring(r, 0.95, 0.025) + ring(r, 0.82, 0.015) + ring(r, 0.42, 0.02) + ring(r, 0.3, 0.012);
	float runes = step(0.82, r) * step(r, 0.95) * step(0.55, fract(a * 24.0 / 6.2832 + sin(floor(a * 24.0 / 6.2832) * 7.1) * 0.3));
	v += runes * 0.55;
	float star = 0.0;   // a seven-pointed star between the rings
	for (int i = 0; i < 7; i++) {
		float ang = float(i) * 6.2832 / 7.0;
		vec2 d = vec2(cos(ang), sin(ang));
		vec2 n = vec2(-d.y, d.x);
		star += smoothstep(0.018, 0.0, abs(dot(p, n) - 0.36)) * step(r, 0.84);
	}
	v += star * 0.8;
	float pulse = 0.75 + 0.25 * sin(TIME * 1.6);
	ALBEDO = col.rgb * v * 2.2 * pulse;
	ALPHA = clamp(v, 0.0, 1.0) * step(r, 1.0);
}
"""

func _rune_circle(p: Vector3, r: float, c: Color, spin: float) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = RUNE_SHADER
	sm.set_shader_parameter("col", c)
	var pm := PlaneMesh.new()
	pm.size = Vector2(r * 2.0, r * 2.0)
	var n := Util.add_mesh(self, pm, sm, p)
	spinners.append([n, spin])
	_light(p + Vector3(0, 0.6, 0), c, 1.0, r * 1.6)

func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadow(c)

# ================================================================ per frame
func _level_process(delta: float) -> void:
	for f in floaters:
		var n: Node3D = f[0]
		if is_instance_valid(n):
			n.position.y = f[1] + sin(t * f[2] + f[3]) * 0.18
			n.rotation.y += f[4] * delta
	for s in spinners:
		if is_instance_valid(s[0]):
			s[0].rotation.y += s[1] * delta
	if mattias_light:
		mattias_light.light_energy = 1.5 + sin(t * 2.0) * 0.35
	if busy:
		return
	if stage == "walk" and not inside and leader.global_position.z < PLAZA.z + 7.0 and not Game.flag("lairSeen"):
		Game.set_flag("lairSeen")
		_reveal_tower()
	elif stage == "lair" and inside and leader.global_position.z < DAIS.z + 6.5:
		stage = "finale"
		_finale()

# ================================================================ story
func _begin() -> void:
	Game.set_flag("summitStarted")
	busy = true
	fade_in(1.4)
	await wait(1.0)
	busy = false
	objective("Climb to the top of the mountain.", PLAZA)

# First sight of the tower: the camera pulls back and looks up at it.
func _reveal_tower() -> void:
	busy = true
	freeze_all(true)
	var z0 := zoom
	var h0 := cam_look_h
	focus_override = TOWER + Vector3(0, 0, 14)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "zoom", 22.0, 2.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "cam_look_h", 12.0, 2.4).set_trans(Tween.TRANS_SINE)
	await wait(3.4)
	tw = create_tween().set_parallel(true)
	tw.tween_property(self, "zoom", z0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "cam_look_h", h0, 1.4).set_trans(Tween.TRANS_SINE)
	focus_override = null
	await wait(1.4)
	freeze_all(false)
	busy = false
	objective("Enter the Wizard's Lair.", DOOR_OUT)

func _level_interactables() -> Array:
	var list: Array = []
	if stage == "finale" or stage == "end":
		return list
	if not inside:
		list.append({ "id": "lair_door", "label": "the Wizard's Lair", "verb": "Enter", "pos": DOOR_OUT, "h": 2.6, "r": 2.8, "steps": [{ "do": "enter_lair" }] })
	else:
		list.append({ "id": "lair_leave", "label": "the lair", "verb": "Leave", "pos": DOOR_IN, "h": 1.6, "r": 2.2, "steps": [{ "do": "leave_lair" }] })
	return list

func _on_action(n: String) -> void:
	match n:
		"enter_lair":
			await _enter_lair()
		"leave_lair":
			await _leave_lair()

func _enter_lair() -> void:
	play_sound("sfx_door", -2.0, 0.8)   # a big heavy door
	await fade_out(0.5)
	_set_inside(true)
	var spots := [DOOR_IN + Vector3(0, 0, -3.4), DOOR_IN + Vector3(-1.4, 0, -2.6), DOOR_IN + Vector3(1.4, 0, -2.6)]
	for i in party.size():
		party[i].global_position = spots[i]
		party[i].set_view("back")
	cam_target = leader.global_position
	if not Game.flag("lairEntered"):   # first time in: the hall opens up, Mattias appears on his dais in a flash
		Game.set_flag("lairEntered")
		stage = "lair"
		mattias.visible = false
		focus_override = INT + Vector3(0, 0, -4)
		zoom = 20.0
		cam_look_h = 4.5
		fade_in(0.8)
		await wait(1.6)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "zoom", 14.0, 2.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(self, "cam_look_h", 2.6, 2.2).set_trans(Tween.TRANS_SINE)
		await wait(1.6)
		mattias_light.light_energy = 8.0
		play_sound("sfx_magic", 0.0, 0.8)
		play_sound("sfx_pop", -2.0, 0.7)
		var p := Fx.poof(Color(0.6, 0.7, 1.0))
		add_child(p)
		p.global_position = mattias.global_position + Vector3(0, 1.0, 0)
		p.emitting = true
		mattias.visible = true
		shake = 0.25
		char_label(mattias, "Metocin Mattias", 3.0, 2.6, Color("#9fc0ff"))
		await wait(1.4)
		focus_override = null
		objective("Approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))
	else:
		fade_in(0.5)
		await wait(0.4)

func _leave_lair() -> void:
	play_sound("sfx_door", -2.0, 0.8)
	await fade_out(0.5)
	_set_inside(false)
	place_party(DOOR_OUT + Vector3(0, 0, 2.6), Vector3(0, 0, 1))
	fade_in(0.5)
	await wait(0.4)

func _set_inside(on: bool) -> void:
	inside = on
	follow_enabled = true
	if on:
		_outdoor = { "sun": sun_light.light_energy, "amb": world_env.environment.ambient_light_energy,
			"ambc": world_env.environment.ambient_light_color, "fog": world_env.environment.fog_density, "vfog": world_env.environment.volumetric_fog_density }
		sun_light.light_energy = 0.0
		world_env.environment.ambient_light_energy = 0.55
		world_env.environment.ambient_light_color = Color(0.36, 0.3, 0.55)
		world_env.environment.fog_density = 0.0
		world_env.environment.volumetric_fog_density = 0.0
		zoom = 14.0
		cam_height = 0.42
		cam_look_h = 2.6
	else:
		if _outdoor.has("sun"):
			sun_light.light_energy = _outdoor["sun"]
			world_env.environment.ambient_light_energy = _outdoor["amb"]
			world_env.environment.ambient_light_color = _outdoor["ambc"]
			world_env.environment.fog_density = _outdoor["fog"]
			world_env.environment.volumetric_fog_density = _outdoor["vfog"]
		zoom = 11.5
		cam_height = 0.34
		cam_look_h = 2.2

# The end of Chapter 1: Mattias's finale (SS.MATTIAS_FINALE, being written), then the end card.
func _finale() -> void:
	busy = true
	objective("")
	focus_override = (leader.global_position + mattias.global_position) * 0.5 + Vector3(0, 0, 1.0)
	zoom = 9.0
	await wait(0.6)
	if SS.MATTIAS_FINALE.is_empty():
		show_toast("(Metocin Mattias's dialogue is coming soon.)", 2.6)
		await wait(2.8)
	else:
		await run_dialogue(SS.MATTIAS_FINALE)
	Game.set_flag("chapter1Done")
	stage = "end"
	var lines := ["END OF CHAPTER 1", "", "Trio Adventures — by Ebain", ""]
	lines += story_so_far()
	lines += ["", "Chapter 2 coming soon. Thanks for playing!", "", "Press E to return to the title screen"]
	end_card(lines, "res://title.tscn")

# ================================================================ walking between areas + saves
func can_resume() -> bool:
	return stage == "walk" or stage == "lair" or Game.flag("chapter1Done")

func can_resume_saved() -> bool:
	return Game.flag("summitStarted")

func free_roam() -> bool:
	return stage == "walk" or stage == "lair"

func _resume(r: Dictionary) -> void:
	stage = "lair" if Game.flag("lairEntered") and not Game.flag("chapter1Done") else "walk"
	var was_inside: bool = r.get("pos", Vector3.INF) != Vector3.INF and not r.get("travel", false) and r["pos"].x > 200.0
	await super._resume(r)
	if was_inside:
		_set_inside(true)
	elif Game.flag("lairSeen"):
		objective("Enter the Wizard's Lair.", DOOR_OUT)
	else:
		objective("Climb to the top of the mountain.", PLAZA)
	if stage == "lair" and inside:
		objective("Approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))

func back_exit() -> Dictionary:
	if not inside and (stage == "walk" or stage == "lair"):
		return { "pos": Vector3(0, 0, 62.0), "r": 2.4, "scene": "res://pass.tscn", "name": "The Pass" }
	return {}

func arrival(from: String) -> Array:
	return [START, Vector3(0, 0, -1)]

# maps: the tower is the one building; inside the hall (off to the side) the maps say so
func map_buildings() -> Array:
	return [{ "pos": TOWER, "name": "Wizard's Lair" }]

func map_place() -> String:
	return "The Wizard's Lair" if inside else ""

func map_place_door() -> Vector3:
	return DOOR_OUT

# ================================================================ automated screenshots (SUMMIT_TOUR=1)
func _shot_tour() -> void:
	fade.color.a = 0.0
	busy = false
	Game.set_flag("summitStarted")
	await wait(1.5)
	await shot("s_01_start")
	place_party(EVENT_SPOTS["overlook"] + Vector3(3.0, 0, 3.0), Vector3(-1, 0, -1))
	await wait(1.0)
	await shot("s_02_overlook")
	place_party(EVENT_SPOTS["shrine"] + Vector3(-3.0, 0, 3.0), Vector3(1, 0, -1))
	await wait(1.0)
	await shot("s_03_shrine")
	place_party(EVENT_SPOTS["cart"] + Vector3(3.0, 0, 3.0), Vector3(-1, 0, -1))
	await wait(1.0)
	await shot("s_04_cart")
	place_party(PLAZA + Vector3(0, 0, 9.5), Vector3(0, 0, -1))
	await wait(0.6)
	place_party(PLAZA + Vector3(0, 0, 6.0), Vector3(0, 0, -1))
	await wait(2.0)
	await shot("s_05_reveal")
	await wait(4.0)
	await shot("s_06_plaza")
	place_party(DOOR_OUT + Vector3(0, 0, 1.0), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("s_07_door")
	start(current_interactables().filter(func(i): return i["id"] == "lair_door")[0])
	await wait(3.0)
	await shot("s_08_hall_reveal")
	await wait(3.5)
	await shot("s_09_hall")
	place_party(INT + Vector3(-6.0, 0, 5.0), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("s_10_alchemy")
	place_party(INT + Vector3(6.0, 0, 5.0), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("s_11_study")
	place_party(DAIS + Vector3(0, 0, 9.0), Vector3(0, 0, -1))
	await wait(0.8)
	await shot("s_12_mattias")
	place_party(DAIS + Vector3(0, 0, 6.0), Vector3(0, 0, -1))
	await wait(4.5)
	await shot("s_13_end")
	print("SUMMIT TOUR stage=", stage, " ch1=", Game.flag("chapter1Done"))
	get_tree().quit()
