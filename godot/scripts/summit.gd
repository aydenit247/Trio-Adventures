# Area: the Summit Path and the Wizard's Lair (Asar 11/22). The last stop of Chapter 1.
# Past the giant's gorge, a long night climb up the mountain (three empty clearings are saved for future events, see
# EVENT_SPOTS), then a plaza with a huge glowing wizard tower. Walk in: a grand circular hall, and Metocin Mattias on
# his dais. Walking up to him plays SS.MATTIAS_FINALE, then one of the Chapter 1 endings.
# The hall is built off to the side at INT (like the Mart's shop room); walking through the door fades you there.
# Finale (Ebain's SUMMIT_FINALE_PLAN.md, 11/24): arrival lines → the hymn → halfway: Mattias's echo → Dulbers' ambush
# (only if he's still alive on this run) → the castle: the metocy, 5 choices → endings: "Bad." (hard cut), cooked by
# Mattias (lose the sucker-punch fight), the normal end, or the goblin metocy party (built off to the side at PARTY_POS).
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
const OG_POS := INT + Vector3(6.4, 0, -1.6)     # the OG Metocy's case, on the old marble bust's pedestal (Asar 11/23)
const OG_CASE_Y := 1.56                         # middle of the glass case
const OG_YAW := -0.6                            # Inspect camera: from the south-west, clear of the study's armchairs
const HALFWAY_Z := 8.0                          # Mattias's echo + Dulbers' ambush trigger here (by the shrine)
const PARTY_POS := Vector3(-400, 0, 0)          # the goblin metocy party (ending), built off to the other side
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
var hymn: AreaMusic          # "The Hymn of Metocin Mattias" (Asar): starts when you arrive, plays once through
var music_gain := 0.0        # hymn.gain_db aims here (the ambush ducks it to background, the castle silences it)
var wind: AudioStreamPlayer
var hall_lights: Array = []  # [light, energy]: the castle torches flare one by one
var dulbers: Unit            # regular-size Dulbers (ambush)
var mattias_out: Unit        # Mattias outside (called for help in the ambush)
var pill: Sprite3D           # the metocy, hovering in front of Mattias
var bowl: Sprite3D
var ending := "normal"       # bad / cooked / normal / party (set by the finale's choices)
var tripping: Array = []     # units on metocy (hue cycle + floating)
var trip_fx: ColorRect       # screen hue shift + wobble
var letterbox: Array = []
var dancers: Array = []      # goblin party: [unit, phase]
var orbit := false

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
	return leader != null and absf(leader.global_position.x) > 200.0   # inside the hall / the goblin party

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
	# Asar's hymn: plays once from the moment you arrive (no loop), on through the climb and into the lair.
	# Mattias won't start his finale until it's done ("Peep the song first folk").
	hymn = AreaMusic.new()
	hymn.track = load("res://assets/music/the_hymn_of_metocin_mattias.ogg")
	hymn.stages = PackedStringArray(["walk", "lair", "finale"])   # not "arrive": the arrival lines come first (Ebain)
	hymn.volume_db = -5.0
	hymn.duck_db = -16.0
	hymn.fade_in_db_per_s = 25.0
	hymn.force_once = true   # (Asar 11/23) never loops: one time through, then quiet
	add_child(hymn)
	# arrival mood: cold wind on the climb, a few embers drifting up the path
	wind = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/sounds/amb_wind.ogg"):   # Ebain's wind howling (sfx pack 11/26)
		var ws: AudioStreamOggVorbis = load("res://assets/sounds/amb_wind.ogg").duplicate()
		ws.loop = true
		wind.stream = ws
	else:
		wind.stream = _wind_loop()
	wind.volume_db = -22.0
	add_child(wind)
	if not Game.title_mode:
		wind.play()
	_motes(Vector3(0, 2.0, 30), Vector3(10, 2.0, 32), Color(1.0, 0.55, 0.25), 36)

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
	var first_child := get_child_count()
	_hall_build()
	for i in range(first_child, get_child_count()):   # the hall's own lights (torches) flare one by one at the finale
		var c := get_child(i)
		if c is OmniLight3D and c != mattias_light:
			hall_lights.append([c, c.light_energy])

func _hall_build() -> void:
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
		# every segment is solid, the doorway too (Asar 11/24): you come and go with the E prompts, and walking out
		# through the gap used to drop you off the end of the floor
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
	# (Asar 11/23) straight walls carry on from the round wall toward the camera, so walking to the door you
	# can't see past the sides; the floor runs on under them. (11/24) They start where the round wall ends and fade
	# out when the camera is close, so walking along the hall's sides they don't cover the screen or hide you.
	var wall_far: BaseMaterial3D = wall.duplicate()
	wall_far.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	wall_far.distance_fade_min_distance = 2.5
	wall_far.distance_fade_max_distance = 6.0
	var trim_far: BaseMaterial3D = trim.duplicate()
	trim_far.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	trim_far.distance_fade_min_distance = 2.5
	trim_far.distance_fade_max_distance = 6.0
	for sgn in [-1.0, 1.0]:
		var wp := PlaneMesh.new()
		wp.size = Vector2(15.0, 20.0)
		Util.add_mesh(self, wp, wall_far, INT + Vector3(sgn * 14.2, 7.5, 24.0), Vector3(0, 0, sgn * PI / 2.0))   # faces inward
		Models.block(self, INT + Vector3(sgn * 13.95, 0.4, 24.0), Vector3(0.4, 0.8, 20.0), trim_far)
		Models.block(self, INT + Vector3(sgn * 13.95, 14.6, 24.0), Vector3(0.5, 0.8, 20.0), trim_far)
	var floor_more := PlaneMesh.new()
	floor_more.size = Vector2(28.4, 22)
	Util.add_mesh(self, floor_more, Models.mat("marble_mosaic_tiles", 3.0, Color(0.62, 0.58, 0.7)), INT + Vector3(0, 0.0015, 27.0))
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
	Models.block(self, OG_POS + Vector3(0, 0.6, 0), Vector3(0.7, 1.2, 0.7), marble, 0.0, true)   # the bust's pedestal, kept
	_og_case()   # (Asar 11/23) the OG Metocy in a glass case instead of the Greek head
	amb_loop("amb_aura", -9.0, OG_POS + Vector3(0, 1.4, 0), 1.6, 9.0)   # it hums (Ebain's sfx pack)
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
# ---------------------------------------------------------------- the OG Metocy (Asar 11/23)
var og_pill: Sprite3D

func _og_case() -> void:
	var base := OG_POS + Vector3(0, 1.2, 0)
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.78, 0.6, 0.3)
	brass.metallic = 0.85
	brass.roughness = 0.3
	Models.block(self, base + Vector3(0, 0.03, 0), Vector3(0.66, 0.06, 0.66), brass)   # brass base plate
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.8, 0.9, 1.0, 0.13)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.4
	glass.roughness = 0.04
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 0.72, 0.6)
	Util.add_mesh(self, bm, glass, base + Vector3(0, 0.42, 0))
	for x in [-0.3, 0.3]:   # brass edges + lid
		for z in [-0.3, 0.3]:
			Models.block(self, base + Vector3(x, 0.42, z), Vector3(0.03, 0.72, 0.03), brass)
	Models.block(self, base + Vector3(0, 0.79, 0), Vector3(0.64, 0.04, 0.64), brass)
	og_pill = Sprite3D.new()
	og_pill.texture = load("res://assets/props/og_metocy.png")
	og_pill.pixel_size = 0.44 / 640.0
	og_pill.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	og_pill.shaded = false
	og_pill.transparent = true
	og_pill.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	og_pill.position = OG_POS + Vector3(0, OG_CASE_Y, 0)
	add_child(og_pill)
	floaters.append([og_pill, OG_CASE_Y, 1.1, 0.0, 0.0])
	_light(OG_POS + Vector3(0, OG_CASE_Y, 0.2), Color(1.0, 0.6, 0.25), 0.7, 2.6)
	# small brass plaque on the pedestal: "OG Metocy"
	Models.block(self, OG_POS + Vector3(0, 0.88, 0.36), Vector3(0.46, 0.15, 0.02), brass)
	var plaque := Label3D.new()
	plaque.text = "OG Metocy"
	plaque.font_size = 48
	plaque.pixel_size = 0.0016
	plaque.modulate = Color(0.16, 0.1, 0.05)
	plaque.outline_size = 0
	plaque.shaded = false
	plaque.position = OG_POS + Vector3(0, 0.88, 0.375)
	add_child(plaque)

const FOCUS_BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 center = vec2(0.5);   // the case, in screen UV
uniform vec2 radius = vec2(0.16, 0.26);
uniform float amount = 0.0;        // 0 = sharp everywhere, 1 = full blur outside the case
void fragment() {
	float d = length((SCREEN_UV - center) / radius);
	float m = smoothstep(0.75, 1.35, d) * amount;
	vec3 sharp = texture(screen_tex, SCREEN_UV).rgb;
	vec2 px = SCREEN_PIXEL_SIZE * 3.0;
	vec3 c = vec3(0.0);
	float w = 0.0;
	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			float k = exp(-float(x * x + y * y) / 10.0);
			c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px).rgb * k;
			w += k;
		}
	}
	vec3 blurred = c / w * 0.78;
	COLOR = vec4(mix(sharp, blurred, m), 1.0);
}
"""

# Inspect: the camera glides in to the case, the room blurs around it, a caption fades up. E / Esc steps back.
func _inspect_og() -> void:
	busy = true
	freeze_all(true)
	_cinematic_hud(false)
	var z0 := zoom
	var h0 := cam_look_h
	var c0 := cam_height
	var case_c := OG_POS + Vector3(0, OG_CASE_Y, 0)
	# (Ebain 11/24) "you can't get a good look at it": the party (standing right in front of the case) and the study's
	# armchairs were between the camera and the case. Hide the party for the close-up and swing the camera round to
	# the open, hall-centre side (south-west) so nothing's in the way.
	var yaw0 := target_yaw
	var hidden: Array = []
	for u in party + npcs:
		if u.visible and u != mattias and u.global_position.distance_to(OG_POS) < 6.0:
			u.visible = false
			hidden.append(u)
	target_yaw = OG_YAW
	focus_override = cam_target
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "focus_override", OG_POS, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "zoom", 2.3, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "cam_look_h", OG_CASE_Y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "cam_height", 0.22, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# the blur + caption layer
	var layer := CanvasLayer.new()
	layer.layer = 60
	add_child(layer)
	var blur := ColorRect.new()
	blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = FOCUS_BLUR_SHADER
	blur.material = sm
	layer.add_child(blur)
	var box := VBoxContainer.new()
	box.anchor_left = 0.0; box.anchor_right = 1.0; box.anchor_top = 1.0; box.anchor_bottom = 1.0
	box.offset_top = -150; box.offset_bottom = -30
	box.alignment = BoxContainer.ALIGNMENT_END
	box.modulate.a = 0.0
	layer.add_child(box)
	for row in [[SS.OG_METOCY_TITLE, 40, Color("#e8b923")], [SS.OG_METOCY_TEXT, 22, Color("#f3e3b0")], ["[E] / Esc to step back", 15, Color(1, 1, 1, 0.55)]]:
		var l := Label.new()
		l.text = row[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", row[1])
		l.add_theme_color_override("font_color", row[2])
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", 8)
		box.add_child(l)
	var follow_case := func():   # keep the sharp spot on the case while the camera moves
		if cam and is_instance_valid(blur):
			var vp := get_viewport().get_visible_rect().size
			sm.set_shader_parameter("center", cam.unproject_position(case_c) / vp)
	var t2 := create_tween().set_parallel(true)
	t2.tween_method(func(v): sm.set_shader_parameter("amount", v); follow_case.call(), 0.0, 1.0, 1.0).set_delay(0.3)
	t2.tween_property(box, "modulate:a", 1.0, 0.6).set_delay(0.9)
	play_sound("sfx_magic", -10.0, 1.4)
	await tw.finished
	if shots_mode:
		await wait(0.8)
		await shot("s_og_metocy")
	else:
		while true:   # wait for E / Esc (a fresh press)
			follow_case.call()
			await get_tree().process_frame
			if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_accept"):
				break
	var back := create_tween().set_parallel(true)
	back.tween_method(func(v): sm.set_shader_parameter("amount", v); follow_case.call(), 1.0, 0.0, 0.6)
	back.tween_property(box, "modulate:a", 0.0, 0.4)
	back.tween_property(self, "focus_override", leader.global_position, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(self, "zoom", z0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(self, "cam_look_h", h0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(self, "cam_height", c0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	target_yaw = yaw0
	await back.finished
	for u in hidden:
		if is_instance_valid(u):
			u.visible = true
	focus_override = null
	layer.queue_free()
	_cinematic_hud(true)
	interact_cooldown = 0.4
	freeze_all(false)
	busy = false

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
	_hall_camera(delta)
	if hymn:
		hymn.gain_db = move_toward(hymn.gain_db, music_gain, delta * 30.0)
		_hymn_watch(delta)
	if wind:
		wind.volume_db = move_toward(wind.volume_db, -60.0 if (inside or stage == "end") else -22.0, delta * 40.0)
	_trip_process(delta)
	_party_process(delta)
	if busy:
		return
	if stage == "walk" and not inside and leader.global_position.z < HALFWAY_Z and leader.global_position.z > PLAZA.z + 7.0:
		if not Game.flag("summitHalfway"):
			_halfway()
		elif _ambush_due():   # loaded a save between Mattias's echo and the ambush
			_ambush()
	elif stage == "walk" and not inside and leader.global_position.z < PLAZA.z + 7.0 and not Game.flag("lairSeen"):
		Game.set_flag("lairSeen")
		_reveal_tower()
	elif stage == "lair" and inside and leader.global_position.z < DAIS.z + 6.5:
		if hymn_playing():
			_peep_the_song()
		else:
			stage = "finale"
			_finale()

# ================================================================ story
func _begin() -> void:
	# A. Arriving: a slow dolly up toward the tower while the trio catches its breath. The hymn waits for the toast.
	busy = true
	stage = "arrive"
	freeze_all(true)
	for u in party:
		u.set_view("back")
	var z0 := zoom
	var h0 := cam_look_h
	focus_override = START + Vector3(0, 0, -4)
	cam_target = START
	zoom = 8.5
	cam_look_h = 1.8
	fade_in(1.4)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "zoom", 15.0, 9.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "cam_look_h", 7.0, 9.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "focus_override", START + Vector3(0, 0, -16), 9.0).set_trans(Tween.TRANS_SINE)
	await wait(1.6)
	await run_dialogue(_fill(SS.ARRIVE))
	busy = true
	freeze_all(true)
	tw.kill()
	tw = create_tween().set_parallel(true)
	tw.tween_property(self, "zoom", z0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "cam_look_h", h0, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "focus_override", leader.global_position, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished   # (Asar 11/23) not wait(1.4): the tween's last frame used to land after this and pin the camera
	focus_override = null
	# (Asar 11/25: dropped the "Don't walk yet if you want to hear the song." toast)
	await wait(0.4)
	stage = "walk"   # → the hymn starts
	Game.set_flag("summitStarted")   # (after the intro: a save from before it replays the arrival)
	freeze_all(false)
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
		list.append({ "id": "og_metocy", "label": "the OG Metocy", "verb": "Inspect", "pos": OG_POS, "h": 2.1, "r": 1.9, "steps": [{ "do": "inspect_og" }] })
	return list

func _on_action(n: String) -> void:
	match n:
		"inspect_og":
			await _inspect_og()
		"enter_lair":
			await _enter_lair()
		"leave_lair":
			await _leave_lair()
		# ---- B / C: halfway + the ambush
		"mattias_voice":
			await _mattias_voice()
		"dulbers_sprint":
			await _dulbers_sprint()
		"dulbers_leaves":
			char_label(dulbers, "Dulbers Frint (Satisfied)", 2.5, 1.9, Color("#c79bff"))   # DRAFT label
			await _send_off(dulbers, 1.0)
		"dulbers_cries_off":
			if dulbers:
				knock(dulbers, 8.0)
				char_label(dulbers, "Dulbers Frint (Crying)", 2.5, 1.9, Color("#c79bff"))   # DRAFT label
				await _send_off(dulbers, 2.0)
		"dulbers_fentocy":
			await _fentocy()
		"ambush_fight":
			await fight("dulbers_ambush", { "enemies": [dulbers] })
		"mattias_arrives":
			await _mattias_arrives()
		"ambush_fight_mattias":
			var hall_vis := mattias.visible
			mattias.visible = false   # fight_party() takes the first visible "mattias": make sure it's the one out here
			await fight("dulbers_ambush", { "enemies": [dulbers], "party": ["skorn", "lykor", "xylo", "mattias"] })
			mattias.visible = hall_vis
			Game.set_flag("foughtWithMattias")
		"mattias_leaves":
			if mattias_out:
				_poof_at(mattias_out.global_position + Vector3(0, 1.0, 0), Color(0.6, 0.4, 1.0))
				play_sound("sfx_pop", -4.0, 0.8)
				mattias_out.visible = false
				await wait(0.6)
		# ---- D / E: the castle
		"castle_hush":
			await _castle_hush()
		"show_pill":
			await _show_pill()
		"bowl_appears":
			await _bowl_appears()
		"take_metocy":
			await _take_metocy(false)
		"take_metocy_all":
			await _take_metocy(true)
		"sucker_punch":
			await _sucker_punch()
		"ending_bad", "ending_cooked", "ending_normal", "ending_party":
			ending = n.get_slice("_", 1)

func _enter_lair() -> void:
	play_sound("sfx_door", -2.0, 0.8)   # a big heavy door
	await fade_out(0.5)
	_set_inside(true)
	var spots := [DOOR_IN + Vector3(0, 0, -3.4), DOOR_IN + Vector3(-1.4, 0, -2.6), DOOR_IN + Vector3(1.4, 0, -2.6)]
	for i in party.size():
		party[i].global_position = spots[i]
		party[i].set_view("back")
		party[i].trail.clear()   # (Asar 11/23) or the other two run back toward the old outdoor trail (off to the left)
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
		_lair_objective()
		fade_in(0.5)
		await wait(0.4)

func _leave_lair() -> void:
	play_sound("sfx_door", -2.0, 0.8)
	await fade_out(0.5)
	_set_inside(false)
	place_party(DOOR_OUT + Vector3(0, 0, 2.6), Vector3(0, 0, 1))
	for u in party:
		u.trail.clear()
	_lair_objective()
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

# Is Asar's hymn still going? (Mattias makes you listen to the whole thing.)
# (Asar 11/23) You only have to hear it through once, ever: summit.gd counts how long it has actually played
# (_hymn_watch), then sets hymnHeard (this save) + Game.unlock("hymn_heard") (every playthrough after).
func hymn_playing() -> bool:
	if hymn_heard():
		return false
	return hymn != null and hymn.player != null and hymn.player.playing

func hymn_heard() -> bool:
	return Game.flag("hymnHeard") or Game.progress.has("hymn_heard")

var _hymn_secs := 0.0
func _hymn_watch(delta: float) -> void:
	if hymn == null or hymn.player == null or hymn_heard():
		return
	if hymn.player.playing and not hymn.player.stream_paused:
		_hymn_secs += delta
		var length: float = hymn.player.stream.get_length() if hymn.player.stream else 165.0
		if _hymn_secs >= length - 1.0 or hymn.played_once:
			Game.set_flag("hymnHeard")
			Game.unlock("hymn_heard")
			if inside and stage == "lair":
				objective("Approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))

# (Asar 11/24) inside the hall the camera trails ~15 m back, so near the side and back walls it ended up outside the
# round wall looking at the dark outside of it, and you couldn't see yourself. Pull it in so it stays inside the hall.
const HALL_ZOOM := 14.0
func _hall_camera(delta: float) -> void:
	if not inside or busy or focus_override != null or cam == null or leader == null:
		return
	var lp := Vector2(leader.global_position.x - INT.x, leader.global_position.z - INT.z)
	var back := Vector2(cam.global_position.x - leader.global_position.x, cam.global_position.z - leader.global_position.z)
	if back.length() < 0.5:
		return
	var per_zoom := back.length() / maxf(zoom, 0.1)   # horizontal metres of camera distance per unit of zoom
	var d := back.normalized()
	var r := HALL_R - 1.5
	var bd := lp.dot(d)                                # ray lp + t*d meets the circle |x| = r
	var t_hit := -bd + sqrt(maxf(0.0, bd * bd - (lp.length_squared() - r * r)))
	var want := clampf(t_hit / per_zoom, 6.0, HALL_ZOOM)
	zoom = move_toward(zoom, want, delta * 8.0)

# (Asar 11/24) the star follows you in and out of the hall: inside it points at Mattias, outside at the door
var _peeped := false
func _lair_objective() -> void:
	if Game.flag("chapter1Done"):
		return
	if inside:
		if _peeped and not hymn_heard():
			objective("Listen to the hymn, then approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))
		else:
			objective("Approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))
	else:
		objective("Enter the Wizard's Lair.", DOOR_OUT)

func _peep_the_song() -> void:
	_peeped = true
	busy = true
	freeze_all(true)
	await run_dialogue(SS.PEEP_THE_SONG)
	for i in party.size():   # step back off the dais steps so it doesn't fire again straight away
		party[i].global_position = DAIS + Vector3(-1.2 + i * 1.2, 0, 9.0 + (i % 2) * 0.6)
	objective("Listen to the hymn, then approach Metocin Mattias.", DAIS + Vector3(0, 0, 4))
	freeze_all(false)
	busy = false

# ================================================================ the finale (Ebain's SUMMIT_FINALE_PLAN.md, 11/24)
# D. The castle: Mattias's finale (SS.MATTIAS_FINALE), then the ending its choices picked.
func _finale() -> void:
	busy = true
	objective("")
	focus_override = (leader.global_position + mattias.global_position) * 0.5 + Vector3(0, 0, 1.0)
	zoom = 9.0
	await wait(0.6)
	ending = "normal"
	await run_dialogue(_fill(SS.MATTIAS_FINALE))
	busy = true
	freeze_all(true)
	Game.set_flag("chapter1Done")
	Game.set_flag("ending" + ending.capitalize())   # endingBad / endingCooked / endingNormal / endingParty (achievements)
	stage = "end"
	match ending:
		"bad":
			await _hard_end()
			return
		"party":
			await _goblin_party()
	end_card(_end_lines(), "res://title.tscn")

func _end_lines() -> Array:
	var lines := ["END OF CHAPTER 1", "", "Trio Adventures — by Ebain", ""]
	var so := story_so_far()
	if Game.flag("dulbersDead"):
		so.erase("Dulbers Frint got away. (He'll be back.)")
	match str(Game.flags.get("way_ambush", "")):   # DRAFT recap lines
		"apologize": so.append("The trio swore loyalty to Dulbmeethus. (Good boys.)")
		"fight": so.append("Dulbers Frint cried on a mountain.")
		"fentocy": so.append("Dulbers Frint took the fentocy.")
		"mattias": so.append("Metocin Mattias pulled up on Dulbers.")
	if ending == "cooked":
		so.append("Metocin Mattias cooked the trio.")
	elif Game.flag("mattiasBeaten"):
		so.append("The trio beat Metocin Mattias. Somehow.")
	if Game.flag("tookMetocy"):
		so.append("All four of them took the metocy." if str(Game.flags.get("way_castle", "")) == "too" else "The trio finally took the metocy.")
	if ending == "party":
		so.append("Every goblin got metocy.")
	lines += so
	lines += ["", "Outcomes found: %d / %d  ·  %d%% complete" % [Game.outcomes_found(), Game.outcomes_total(), Game.completion_pct()]]
	lines += ["", "Chapter 2 coming soon. Thanks for playing!", "", "Press E to return to the title screen"]
	return lines

# Fills in the lines that change with how this run went ("dyn" steps, see summit_script.gd). Returns a copy.
func _fill(steps: Array) -> Array:
	var out := []
	for st in steps:
		var c: Dictionary = st.duplicate(true)
		if c.has("dyn"):
			c["line"] = _dyn_line(c["dyn"])
		if c.has("steps"):
			c["steps"] = _fill(c["steps"])
		if c.has("choice"):
			var opts := []
			for o in c["choice"]:
				var oc: Dictionary = o.duplicate(true)
				oc["steps"] = _fill(oc["steps"])
				opts.append(oc)
			c["choice"] = opts
		out.append(c)
	return out

func _dyn_line(key: String) -> String:
	match key:
		"xylo_arrive":
			return SS.XYLO_ARRIVE_START + _pick(SS.DYN_XYLO_ARRIVE)
		"dulbers_ambush":
			if str(Game.flags.get("way_mart", "")) == "" and Game.flag("hasMidtocy"):   # saves from before way_ flags
				return SS.DYN_DULBERS_AMBUSH[0][2]
			return _pick(SS.DYN_DULBERS_AMBUSH)
		"mattias_welcome":
			var mid := _pick(SS.DYN_MATTIAS_WELCOME)
			return SS.WELCOME_START + mid + ("" if mid.ends_with("That's OD.") else SS.WELCOME_END)
	return ""

# First entry whose flag matches: [flag, value, text]; value "" = the flag is just set.
func _pick(list: Array) -> String:
	for e in list:
		if e[0] == "":
			return e[2]
		var v = Game.flags.get(e[0], false)
		if e[1] == "":
			if (v is bool and v) or (v is String and v != ""):
				return e[2]
		elif v is String and v == e[1]:
			return e[2]
	return ""

func _member(id: String) -> Unit:
	for u in party:
		if u.id == id:
			return u
	return leader

# ---------------------------------------------------------------- B. halfway, C. the ambush
func _ambush_due() -> bool:
	return Game.flag("dulbersEscaped") and not Game.flag("dulbersDead") and str(Game.flags.get("way_ambush", "")) == ""

func _halfway() -> void:
	busy = true
	await run_dialogue(SS.HALFWAY)
	Game.set_flag("summitHalfway")
	if _ambush_due():
		await _ambush()

func _ambush() -> void:
	busy = true
	freeze_all(true)
	if hymn:   # Asar 11/25: the song pauses while Dulbers is here and picks up where it left off once he's gone
		hymn.paused = true   # (was Ebain's: drop it to the background)
	await run_dialogue(_fill(SS.AMBUSH))
	busy = true
	target_yaw = 0.0
	focus_override = null
	if hymn:
		hymn.paused = false
	await wait(0.7)
	busy = false
	interact_cooldown = 0.3

func _mattias_voice() -> void:
	dialogue.hide_box()   # first step of its dialogue: don't show the previous line's text meanwhile
	var at := leader.global_position + Vector3(0, 4.0, -12.0)
	var flash := _light(at, Color(0.4, 0.6, 1.0), 0.0, 14.0)
	var tw := create_tween()
	tw.tween_property(flash, "light_energy", 4.0, 0.5)
	tw.tween_property(flash, "light_energy", 0.0, 1.5)
	tw.tween_callback(flash.queue_free)
	play_sound("sfx_magic", -10.0, 0.6)
	var n := Node3D.new()
	add_child(n)
	n.global_position = at + Vector3(0, 0.5, 0)
	var l := char_label(n, "(a voice, echoing from further up the path)", 3.5, 0.0, Color("#9cc4ff"))
	l.pixel_size = 0.016
	get_tree().create_timer(4.0).timeout.connect(n.queue_free)
	await wait(0.6)
	dialogue.show_box()

# Regular-size Dulbers sprints up the trail behind them: footsteps, the camera whips around, dust behind him.
func _dulbers_sprint() -> void:
	dialogue.hide_box()
	var lp := leader.global_position
	var from := Vector3(clampf(lp.x, -9.0, 9.0), 0, minf(lp.z + 18.0, 60.0))
	if dulbers == null:
		dulbers = spawn_npc("dulbers", "Dulbers Frint", "dulbers", 1.3, from)
	dulbers.global_position = from
	dulbers.visible = true
	dulbers.frozen = false
	for i in 6:   # footsteps, getting closer
		_blip(Util.noise_burst(55, 0.45, 0.9), -16.0 + i * 2.0, 0.9 + randf() * 0.2)
		await wait(0.16)
	target_yaw = PI   # whip around to look back down the path
	focus_override = lp.lerp(from, 0.3)
	shake = 0.25
	for u in party:
		u.set_view("back")
	var dust := CPUParticles3D.new()
	dust.amount = 36
	dust.lifetime = 0.9
	dust.mesh = Fx.quad(0.35, false)
	dust.direction = Vector3.UP
	dust.spread = 60.0
	dust.gravity = Vector3(0, 0.4, 0)
	dust.initial_velocity_min = 0.3
	dust.initial_velocity_max = 0.9
	dust.color_ramp = Fx.ramp([[0.0, Color(0.6, 0.55, 0.5, 0.55)], [1.0, Color(0.6, 0.55, 0.5, 0.0)]])
	dust.position = Vector3(0, 0.2, 0)
	dulbers.add_child(dust)
	dulbers.walk_speed = 4.2
	await walk_to(dulbers, lp + Vector3(0, 0, 3.4), 2.2, 4.0)
	dust.emitting = false
	get_tree().create_timer(1.2).timeout.connect(dust.queue_free)
	dulbers.frozen = true
	dulbers.set_view("front")
	shake = 0.15
	focus_override = lp.lerp(dulbers.global_position, 0.5)
	char_label(dulbers, "Dulbers Frint (Regular Size) (Followed You)", 3.0, 1.9, Color("#c79bff"))   # DRAFT label
	await wait(0.5)
	dialogue.show_box()

# Someone walks back down the trail and is gone.
func _send_off(u: Unit, speed: float) -> void:
	if u == null:
		return
	dialogue.hide_box()
	u.frozen = false
	await walk_to(u, u.global_position + Vector3(0, 0, 14.0), speed, 3.0)
	u.visible = false
	u.frozen = true
	dialogue.show_box()

func _fentocy() -> void:
	dialogue.hide_box()
	var sk := _member("skorn")
	var p := Sprite3D.new()   # looks just like midtocy (that's the point)
	p.texture = load("res://assets/items/midtocy.png")
	p.pixel_size = 0.4 / 792.0
	p.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	p.shaded = false
	add_child(p)
	p.global_position = sk.global_position + Vector3(0, 1.4, 0)
	var to := dulbers.global_position + Vector3(0, 1.0, 0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(p, "global_position:x", to.x, 0.6)
	tw.tween_property(p, "global_position:z", to.z, 0.6)
	tw.tween_property(p, "global_position:y", to.y + 1.2, 0.3).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(p, "global_position:y", to.y, 0.3).set_ease(Tween.EASE_IN)
	await tw.finished
	p.queue_free()
	play_sound("sfx_chug_loop", -8.0, 1.6)   # (gulp)
	await wait(0.7)
	var sp := dulbers.sprite
	var wob := create_tween()
	for k in 4:
		wob.tween_property(sp, "rotation:z", 0.25 if k % 2 == 0 else -0.25, 0.22)
	wob.tween_property(sp, "modulate", Color(0.7, 1.0, 0.7), 0.3)
	await wob.finished
	sp.rotation.z = 0.0
	knock(dulbers, 90.0, 0.4)
	shake = 0.2
	await wait(1.4)
	_poof_at(dulbers.global_position + Vector3(0, 0.5, 0), Color(0.6, 0.4, 0.9))
	play_sound("sfx_pop", -4.0, 0.7)
	dulbers.visible = false
	sp.modulate = Color.WHITE
	unknock(dulbers)
	Game.set_flag("dulbersDead")
	await wait(0.6)
	dialogue.show_box()

func _mattias_arrives() -> void:
	dialogue.hide_box()
	var p := leader.global_position + Vector3(2.4, 0, 1.6)
	if mattias_out == null:
		mattias_out = spawn_npc("mattias", "Metocin Mattias", "mattias", 2.2, p)
		mattias_out.set_meta("tint", Color(1.05, 1.1, 1.3))
	mattias_out.global_position = p
	mattias_out.visible = false
	mattias_out.frozen = true
	_poof_at(p + Vector3(0, 1.0, 0), Color(0.6, 0.35, 1.0))
	_poof_at(p + Vector3(0, 1.8, 0), Color(0.75, 0.5, 1.0))
	_choir_hit()
	play_sound("sfx_magic", -2.0, 0.7)
	mattias_out.visible = true
	shake = 0.3
	Engine.time_scale = 0.3   # half a second of slow-mo
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = 1.0
	char_label(mattias_out, "Metocin Mattias (Was Called)", 3.0, 2.6, Color("#9fc0ff"))   # DRAFT label
	await wait(0.5)
	dialogue.show_box()

# ---------------------------------------------------------------- D. the castle
func _castle_hush() -> void:
	dialogue.hide_box()   # first step of the finale: no stale text from the last conversation
	music_gain = -60.0   # the music drops to silence on "Welcome to da crib folk"
	for L in hall_lights:
		L[0].light_energy = L[1] * 0.08
	await wait(0.9)
	for L in hall_lights:   # torches flare back one by one
		create_tween().tween_property(L[0], "light_energy", L[1], 0.25)
		_blip(Util.noise_burst(90, 0.2, 0.5), -14.0, 0.8 + randf() * 0.4)
		await wait(0.14)
	var tw := create_tween().set_parallel(true)   # slow push in while he talks
	tw.tween_property(self, "zoom", 6.2, 22.0).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "cam_look_h", 2.5, 22.0).set_trans(Tween.TRANS_SINE)
	dialogue.show_box()

func _show_pill() -> void:
	if pill == null:
		pill = Sprite3D.new()
		pill.texture = load("res://assets/items/metocy.png")
		pill.pixel_size = 0.55 / float(pill.texture.get_width())
		pill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		pill.shaded = false
		add_child(pill)
		var l := OmniLight3D.new()
		l.name = "Glow"
		l.light_color = Color(0.35, 0.6, 1.0)
		l.light_energy = 0.0
		l.omni_range = 5.0
		pill.add_child(l)
		create_tween().tween_property(l, "light_energy", 3.0, 0.8)
		var sp := CPUParticles3D.new()
		sp.amount = 30
		sp.lifetime = 1.2
		sp.mesh = Fx.quad(0.08, true)
		sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		sp.emission_sphere_radius = 0.4
		sp.gravity = Vector3(0, 0.3, 0)
		sp.color_ramp = Fx.ramp([[0.0, Color(0.5, 0.75, 1.0, 0)], [0.3, Color(0.5, 0.75, 1.0, 1)], [1.0, Color(0.5, 0.75, 1.0, 0)]])
		pill.add_child(sp)
	dialogue.hide_box()
	var at := DAIS + Vector3(0, 2.5, 3.0)
	pill.global_position = at
	pill.visible = true
	floaters.append([pill, at.y, 2.0, 0.0, 0.0])
	_poof_at(at, Color(0.5, 0.7, 1.0))
	play_sound("sfx_magic", -4.0, 1.3)
	char_label(pill, "Metocy (The Real One)", 3.0, 0.5, Color("#8ad8ff"))   # DRAFT label
	await wait(0.8)
	dialogue.show_box()

func _bowl_appears() -> void:
	dialogue.hide_box()
	if bowl == null:
		bowl = Sprite3D.new()
		bowl.texture = load("res://assets/items/chipotle_bowl.png")
		bowl.pixel_size = 0.75 / float(bowl.texture.get_width())
		bowl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bowl.shaded = false
		add_child(bowl)
	bowl.global_position = pill.global_position + Vector3(0, -0.45, 0.05)
	bowl.visible = true
	_poof_at(bowl.global_position, Color(0.95, 0.8, 0.5))
	play_sound("sfx_pop", -3.0, 1.1)
	char_label(bowl, "Chipotle Bowl (Out Of Nowhere)", 2.5, 0.5)   # DRAFT label
	await wait(0.9)
	dialogue.show_box()

# Taking the metocy: the Mart's trip look, a screen hue-shift, a choir sting, everyone floats up a little.
func _take_metocy(with_mattias: bool) -> void:
	dialogue.hide_box()
	if pill:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(pill, "global_position", leader.global_position + Vector3(0, 1.6, 0), 0.6)
		tw.tween_property(pill, "pixel_size", pill.pixel_size * 0.3, 0.6)
		await tw.finished
		pill.visible = false
	if bowl:
		bowl.visible = false
	_choir_hit()
	play_sound("sfx_magic", -3.0, 0.5)
	shake = 0.35
	var who: Array = party.duplicate()
	if with_mattias:
		who.append(mattias)
	for u in who:
		var p := "res://assets/characters/%s_tweaking.png" % u.id
		if ResourceLoader.exists(p):
			u.set_pose(load(p), u.base_h)
		if not tripping.has(u):
			tripping.append(u)
		create_tween().tween_property(u.sprite, "position:y", 0.35, 1.6).set_trans(Tween.TRANS_SINE)
	if trip_fx == null:
		trip_fx = ColorRect.new()
		trip_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sm := ShaderMaterial.new()
		sm.shader = Shader.new()
		sm.shader.code = TRIP_SHADER
		trip_fx.material = sm
		hud.add_child(trip_fx)
		trip_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hud.move_child(trip_fx, 0)
	create_tween().tween_method(func(v: float): trip_fx.material.set_shader_parameter("amount", v), 0.0, 1.0, 2.0)
	Game.set_flag("tookMetocy")
	await wait(1.6)
	dialogue.show_box()

func _trip_process(_delta: float) -> void:
	if tripping.is_empty():
		return
	for u in tripping:
		if is_instance_valid(u):
			u.sprite.modulate = Color.from_hsv(fmod(t * 0.12 + u.global_position.x * 0.05, 1.0), 0.4, 1.0)
	if cam and not orbit:
		cam.rotation.z = sin(t * 0.9) * 0.04

const TRIP_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount = 0.0;
vec3 hue(vec3 c, float a) {
	const vec3 k = vec3(0.57735);
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}
void fragment() {
	vec2 uv = SCREEN_UV + amount * 0.006 * vec2(sin(SCREEN_UV.y * 14.0 + TIME * 2.1), cos(SCREEN_UV.x * 11.0 + TIME * 1.7));
	vec3 c = texture(screen_tex, uv).rgb;
	c = hue(c, amount * 1.6 * sin(TIME * 0.6));   // swing the hues back and forth (mixing a rotated copy in turns it grey)
	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(max(mix(vec3(lum), c, 1.0 + 0.6 * amount), 0.0), 1.0);
}
"""

# Sucker punch: hit-stop freeze frame, zoom on the impact, letterbox bars, then the near-impossible boss.
# Losing is its own ending (lose_ends), not a retry.
func _sucker_punch() -> void:
	dialogue.hide_box()
	var sk := _member("skorn")
	sk.frozen = false
	await walk_to(sk, DAIS + Vector3(0.4, 0, 3.6), 1.6, 3.0)
	hop(sk, 0.9)
	var tw := create_tween()
	tw.tween_property(sk, "global_position", mattias.global_position + Vector3(-0.5, 0.0, 1.0), 0.3)
	await tw.finished
	sk.set_pose(load("res://assets/characters/skorn_slap.png"), sk.base_h * 0.85)
	play_sound("sfx_punch", 3.0, 0.75)
	var flash := ColorRect.new()
	flash.color = Color(1, 1, 1, 0.85)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	focus_override = mattias.global_position + Vector3(0, 0.6, 0)
	zoom = 4.2
	cam_target = focus_override
	Engine.time_scale = 0.03   # hit-stop
	await get_tree().create_timer(0.45, true, false, true).timeout
	Engine.time_scale = 1.0
	create_tween().tween_property(flash, "color:a", 0.0, 0.35)
	get_tree().create_timer(0.5).timeout.connect(flash.queue_free)
	shake = 0.6
	knock(mattias, 10.0, 0.1)
	_letterbox(true)
	var heart := play_sound("sfx_heartbeat", -5.0, 1.0, true)   # Ebain's heartbeat, right before the boss fight
	await wait(0.6)
	unknock(mattias)
	char_label(mattias, "Metocin Mattias (Unbothered)", 3.0, 2.6, Color("#9fc0ff"))   # DRAFT label
	await wait(0.9)
	sk.restore_views()
	sk.global_position = DAIS + Vector3(0, 0, 6.5)
	sk.frozen = true
	zoom = 9.0
	focus_override = null
	if heart:
		create_tween().tween_property(heart, "volume_db", -40.0, 0.5).finished.connect(heart.queue_free)
	var res := await fight("mattias", { "enemies": [mattias], "center": DAIS + Vector3(0, 0, 7.5), "lose_ends": true })
	Game.set_flag("mattiasBeaten", res == "win")
	if res == "win":
		play_sound("sfx_bell", -3.0)   # the church bell: he's done
	_letterbox(false)
	focus_override = (leader.global_position + mattias.global_position) * 0.5 + Vector3(0, 0, 1.0)
	zoom = 8.0
	await wait(0.6)
	dialogue.show_box()

func _letterbox(on: bool) -> void:
	if on and letterbox.is_empty():
		for top in [true, false]:
			var r := ColorRect.new()
			r.color = Color.BLACK
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hud.add_child(r)
			r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
			if top:
				r.offset_bottom = 0.0
				create_tween().tween_property(r, "offset_bottom", 78.0, 0.35)
			else:
				r.offset_top = 0.0
				create_tween().tween_property(r, "offset_top", -78.0, 0.35)
			letterbox.append(r)
	elif not on:
		for r in letterbox:
			var tw := create_tween()
			tw.tween_property(r, "modulate:a", 0.0, 0.3)
			tw.tween_callback(r.queue_free)
		letterbox.clear()

# ---------------------------------------------------------------- endings
# "Bad.": hard cut to black, no music, END OF CHAPTER 1 in plain text. The silence is the joke.
func _hard_end() -> void:
	music_gain = -60.0
	if hymn and hymn.player:
		hymn.player.stop()
	dialogue.stop_voice()
	fade.color.a = 1.0
	_cinematic_hud(false)
	if trip_fx:
		trip_fx.visible = false
	await wait(1.3)
	var l := _label("END OF CHAPTER 1", Vector2.ZERO, 30, Color.WHITE, 0)
	hud.add_child(l)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	await wait(1.2)
	if shots_mode:
		return
	while not Input.is_action_just_pressed("interact"):
		await get_tree().process_frame
	Game.title_mode = true
	Game.goto("res://title.tscn")

# Yes to metocy for every goblin: cut to the goblin village dancing (a little set built off to the side), then credits.
func _goblin_party() -> void:
	await fade_out(0.6)
	music_gain = -60.0
	_set_inside(false)   # outdoor night light again
	_cinematic_hud(false)
	_build_party_set()
	var ring: Array = party.duplicate()
	ring.append(mattias)
	for i in ring.size():
		var a := -0.6 + i * 0.4
		var u: Unit = ring[i]
		u.visible = true
		unknock(u)
		u.global_position = PARTY_POS + Vector3(sin(a) * 3.0, 0.0, cos(a) * 3.0)
		u.set_view("front")
		dancers.append([u, randf() * TAU])
	var song := AudioStreamPlayer.new()
	song.stream = load("res://assets/music/the_mogging_elf.ogg")
	song.volume_db = -6.0
	add_child(song)
	song.play()
	play_sound("sfx_goblin_cheer", -7.0)   # the whole village going off (sfx pack)
	focus_override = PARTY_POS + Vector3(0, 0, 0.5)
	cam_target = focus_override
	zoom = 13.0
	cam_height = 0.38
	cam_look_h = 1.6
	orbit = true
	if cam:
		cam.rotation.z = 0.0
	fade_in(0.8)
	show_toast("Meanwhile, back at the Goblin Village…", 3.0)   # DRAFT
	await wait(9.0)

func _build_party_set() -> void:
	var c := PARTY_POS
	var fl := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(70, 1, 70)
	cs.shape = bs
	cs.position = c + Vector3(0, -0.5, 0)
	fl.add_child(cs)
	add_child(fl)
	var gm := StandardMaterial3D.new()
	gm.albedo_texture = load("res://assets/textures/grass.jpg")
	gm.albedo_color = Color(0.55, 0.6, 0.45)
	gm.uv1_scale = Vector3(24, 24, 1)
	var pm := PlaneMesh.new()
	pm.size = Vector2(70, 70)
	Util.add_mesh(self, pm, gm, c + Vector3(0, 0.001, 0))
	Models.patch(self, c, Vector2(12, 12), "burned_ground_01", 2.0, Color(0.6, 0.55, 0.5), 0.0, 0.5)
	Models.place(self, "stone_fire_pit", c, 0.0, 1.6)
	var f := Fx.flames(1.0)
	f.position = c + Vector3(0, 0.3, 0)
	add_child(f)
	_light(c + Vector3(0, 1.6, 0), Color(1.0, 0.6, 0.3), 3.2, 16.0)
	add_glow(c, Color(1.0, 0.6, 0.3), 9.0, func(): return 1.0, true)
	for k in 16:   # forest all round
		var a := TAU * k / 16.0
		card("tree_%d" % (1 + k % 4), 8.0 + (k % 3), c + Vector3(sin(a) * 17.0, 0, cos(a) * 17.0), k % 2 == 0, false, 0.0, "props", Color(0.5, 0.5, 0.6))
	for k in 4:
		var a := TAU * k / 4.0 + 0.6
		card("tent_green" if k % 2 == 0 else "tent_purple", 3.0, c + Vector3(sin(a) * 10.0, 0, cos(a) * 10.0), k % 2 == 1, false, 0.0, "props", Color(0.75, 0.7, 0.75))
	var gob_tex := ["goblin", "goblin_fight", "goblin", "goblin_chief", "goblin", "goblin_fight", "goblin", "goblin"]
	for k in 8:   # the goblins, dancing round the fire
		var a := PI * 0.55 + TAU * k / 11.0
		var g := spawn_npc("party_goblin_%d" % k, "Goblin", gob_tex[k], 1.45 if gob_tex[k] == "goblin_chief" else 1.2 + (k % 3) * 0.08, c + Vector3(sin(a) * 4.8, 0, cos(a) * 4.8))
		g.frozen = true
		dancers.append([g, randf() * TAU])
	for k in 3:   # the band
		var b := spawn_npc("party_band_%d" % k, "Goblin Band", ["band_drummer", "band_horn", "band_lute"][k], 1.3, c + Vector3(-6.5 + k * 1.4, 0, -5.5))
		b.frozen = true
		dancers.append([b, randf() * TAU])
	var conf := CPUParticles3D.new()   # confetti
	conf.amount = 160
	conf.lifetime = 4.0
	conf.mesh = Fx.quad(0.12, false)
	conf.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	conf.emission_box_extents = Vector3(8, 0.5, 8)
	conf.direction = Vector3.DOWN
	conf.gravity = Vector3(0, -1.2, 0)
	conf.initial_velocity_min = 0.2
	conf.initial_velocity_max = 0.8
	conf.angular_velocity_min = -180.0
	conf.angular_velocity_max = 180.0
	conf.color = Color(1.0, 0.35, 0.35)
	conf.hue_variation_min = -1.0
	conf.hue_variation_max = 1.0
	conf.position = c + Vector3(0, 7.0, 0)
	add_child(conf)

# Endings are cutscenes: hide the minimap, area title, controls and "Controlling:" box.
func _cinematic_hud(on: bool) -> void:
	for n in [minimap, title_box, help_lbl, leader_lbl, leader_por, objective_lbl]:
		if n:
			n.visible = on

func _party_process(delta: float) -> void:
	if orbit:
		target_yaw += delta * 0.32
	for d in dancers:
		var u: Unit = d[0]
		if is_instance_valid(u):
			var ph: float = t * 6.0 + d[1]
			u.sprite.position.y = absf(sin(ph)) * 0.32
			u.sprite.flip_h = sin(ph * 0.5) > 0.0

# ---------------------------------------------------------------- little sound/fx helpers
func _poof_at(p: Vector3, col: Color) -> void:
	var f := Fx.poof(col)
	add_child(f)
	f.global_position = p
	f.emitting = true
	get_tree().create_timer(2.0).timeout.connect(f.queue_free)

func _blip(stream: AudioStream, db: float, pitch := 1.0) -> void:
	var a := _sfx(stream, db)
	a.pitch_scale = pitch
	a.finished.connect(a.queue_free)
	a.play()

var _choir: AudioStreamWAV
# A low "aah" choir hit (synthesized: an A chord with vowel-ish formants).
func _choir_hit() -> void:
	if _choir == null:
		_choir = _make_choir()
	_blip(_choir, -4.0)

func _make_choir() -> AudioStreamWAV:
	var rate := 11025
	var n := int(rate * 1.3)
	var notes := [110.0, 138.6, 164.8, 220.0]
	var parts := []   # [freq, weight]
	for f in notes:
		for k in range(1, 9):
			var fk: float = f * k
			if fk > rate * 0.45:
				break
			var w: float = exp(-pow((fk - 700.0) / 320.0, 2.0)) + 0.6 * exp(-pow((fk - 1150.0) / 300.0, 2.0)) + 0.35 / k
			parts.append([fk, w])
	var data := PackedByteArray()
	data.resize(n * 2)
	var peak := 0.001
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var tt := float(i) / rate
		var vib := 1.0 + 0.004 * sin(TAU * 5.0 * tt)
		var v := 0.0
		for pr in parts:
			v += sin(TAU * pr[0] * vib * tt) * pr[1]
		var env := minf(tt / 0.04, 1.0) * exp(-tt * 2.2)
		buf[i] = v * env
		peak = maxf(peak, absf(buf[i]))
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w

# Cold mountain wind: filtered noise with slow gusts, crossfaded so it loops without a click.
func _wind_loop() -> AudioStreamWAV:
	var rate := 11025
	var n := rate * 4
	var fade_n := rate / 2
	var raw := PackedFloat32Array()
	raw.resize(n + fade_n)
	var y := 0.0
	var y2 := 0.0
	for i in raw.size():
		y += (randf() * 2.0 - 1.0 - y) * 0.06
		y2 += (y - y2) * 0.2
		var tt := float(i) / rate
		raw[i] = y2 * (0.55 + 0.45 * sin(TAU * tt / 4.0 + 1.3)) * 3.0
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v: float = raw[i]
		if i < fade_n:   # blend the tail into the head
			var k := float(i) / fade_n
			v = raw[i] * k + raw[n + i] * (1.0 - k)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w

func _exit_tree() -> void:
	Engine.time_scale = 1.0   # never leave the game in slow-mo

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
	if OS.get_environment("SUMMIT_TOUR") == "finale":
		await _finale_tour()
		return
	if OS.get_environment("SUMMIT_TOUR") == "og":   # just the OG Metocy close-up (Ebain 11/24)
		fade.color.a = 0.0
		busy = false
		await _enter_lair()
		await wait(1.0)
		place_party(OG_POS + Vector3(-0.6, 0, 1.6), Vector3(0, 0, -1))
		await wait(1.0)
		await _inspect_og()
		get_tree().quit()
		return
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
	place_party(DOOR_IN + Vector3(0, 0, -0.6), Vector3(0, 0, -1))   # (Asar 11/23) by the door: no seeing past the walls
	await wait(1.2)
	await shot("s_09b_by_the_door")
	place_party(INT + Vector3(-6.0, 0, 5.0), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("s_10_alchemy")
	place_party(INT + Vector3(6.0, 0, 5.0), Vector3(0, 0, -1))
	await wait(1.0)
	await shot("s_11_study")
	place_party(OG_POS + Vector3(-0.6, 0, 1.6), Vector3(0, 0, -1))   # (Asar 11/23) inspect the OG Metocy
	await wait(0.8)
	await shot("s_11b_og_case")
	var og_it: Array = current_interactables().filter(func(i): return i["id"] == "og_metocy")
	if not og_it.is_empty():
		await _inspect_og()
	place_party(DAIS + Vector3(0, 0, 9.0), Vector3(0, 0, -1))
	await wait(0.8)
	await shot("s_12_mattias")
	place_party(DAIS + Vector3(0, 0, 6.0), Vector3(0, 0, -1))   # hymn still playing: "Peep the song first folk"
	await wait(1.2)
	await shot("s_13_peep_the_song")
	await advance(1, 0.6)
	await wait(1.0)
	print("SUMMIT peep: stage=", stage, " hymn_playing=", hymn_playing())
	hymn.player.stop()   # pretend the hymn finished
	hymn.played_once = true
	place_party(DAIS + Vector3(0, 0, 6.0), Vector3(0, 0, -1))
	await wait(4.5)
	await shot("s_14_end")
	print("SUMMIT TOUR stage=", stage, " ch1=", Game.flag("chapter1Done"), "  (the finale itself: SUMMIT_TOUR=finale)")
	get_tree().quit()

# SUMMIT_TOUR=finale: the whole finale with auto-advanced lines (prints every line + pick).
#   SUMMIT_FLAGS="dulbersEscaped,hasMidtocy,way_mart=xylo,way_pass=lore"  (this run's story so far)
#   SUMMIT_PICKS="3,0,0"  choice indexes in order (ambush, castle, after; 0 = first option)   AUTO_LOSE=1: lose the boss
var _tour_on := false
var shot_trip := false
func _finale_tour() -> void:
	for f in OS.get_environment("SUMMIT_FLAGS").split(",", false):
		if "=" in f:
			Game.set_flag(f.get_slice("=", 0), f.get_slice("=", 1))
		else:
			Game.set_flag(f)
	var picks := []
	for p in OS.get_environment("SUMMIT_PICKS").split(",", false):
		picks.append(int(p))
	Game.dev_autowin = OS.get_environment("AUTOWIN") != ""   # AUTOWIN=1: fights count as won (tests the win branches)
	_tour_on = true
	_autopilot(picks)
	await _begin()
	print("SUMMIT stage after arrival: ", stage, " started=", Game.flag("summitStarted"))
	await shot("fin_01_arrived")
	place_party(Vector3(0, 0, HALFWAY_Z - 1.0), Vector3(0, 0, -1))
	await wait(0.4)
	var spins := 0
	while (not Game.flag("summitHalfway") or busy) and spins < 600:
		if spins == 30:
			await shot("fin_02_halfway")
		if dulbers and dulbers.visible and spins % 40 == 0:
			await shot("fin_03_ambush_%d" % spins)
		await wait(0.25)
		spins += 1
	print("SUMMIT after ambush: way_ambush=", Game.flags.get("way_ambush", ""), " dulbersDead=", Game.flag("dulbersDead"), " withMattias=", Game.flag("foughtWithMattias"))
	place_party(DOOR_OUT + Vector3(0, 0, 1.0), Vector3(0, 0, -1))
	await wait(0.5)
	start(current_interactables().filter(func(i): return i["id"] == "lair_door")[0])
	await wait(7.0)
	if hymn.player:
		hymn.player.stop()
	hymn.played_once = true
	place_party(DAIS + Vector3(0, 0, 6.0), Vector3(0, 0, -1))
	spins = 0
	while stage != "end" and spins < 1200:
		if spins in [12, 40, 70]:
			await shot("fin_04_castle_%d" % spins)
		if Game.flag("tookMetocy") and not shot_trip:
			shot_trip = true
			await wait(1.5)
			await shot("fin_04_tripping")
		await wait(0.25)
		spins += 1
	await wait(2.0)
	await shot("fin_05_ending_" + ending)
	if ending == "party":
		await wait(4.0)
		await shot("fin_06_party")
	print("SUMMIT TOUR ending=", ending, " ch1=", Game.flag("chapter1Done"), " way_castle=", Game.flags.get("way_castle", ""), " beaten=", Game.flag("mattiasBeaten"), " took=", Game.flag("tookMetocy"))
	for l in _end_lines():
		print("  CARD ", l)
	_tour_on = false
	get_tree().quit()

func _autopilot(picks: Array) -> void:
	var k := 0
	var last := ""
	while _tour_on:
		await wait(0.3)
		if not dialogue._choices.is_empty():
			var i: int = mini(picks[k] if k < picks.size() else 0, dialogue._choices.size() - 1)
			k += 1
			print("PICK ", dialogue._choices[i]["text"])
			await wait(0.2)
			dialogue._picked.emit(i)
		elif dialogue.active and dialogue.panel.visible and dialogue.text_lbl.visible:
			var txt: String = dialogue.text_lbl.text
			if txt != last:
				last = txt
				print("LINE ", dialogue.name_lbl.text if dialogue.get("name_lbl") else "", ": ", txt)
			dialogue._next.emit()

# footsteps (Ebain's sfx pack): stone hall inside the tower, ground outside
func floor_at(p: Vector3) -> String:
	return "hall" if p.x > 200.0 else "grass"
