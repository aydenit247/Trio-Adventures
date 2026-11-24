# Area: the secret Deloye Lore library (DELOYE_PLAN.md). Pure easter egg: no fight, no test.
# You get here by finding all 5 Lost Deloye Lore Pages (lost_pages.gd) and flushing the village outhouse (village.gd).
# A huge round hall: book walls climbing into the dark, a spiral stair, ladders, chandeliers, dust in light beams,
# books orbiting the middle. In the center Deloye himself (Ebain's art) floats and twirls on a rune dais, the giant
# Deloye Lore manuscript turning above his head with its pages flipping. Talk to him: he gives Xylo the
# Deloye Lore Neuralink (flag deloyeGift, once per run). The EXIT door goes back to the village, next to the outhouse.
# Arriving unlocks progress "deloye_found" (secret achievement + the secret Scrapbook page).
# Music: Ebain's Deloye Lore song when it exists (SONG, an AreaMusic made in code); until then a soft hum.
extends Level

const DS = preload("res://scripts/deloye_script.gd")
const SONG := "res://assets/music/deloye_lore.ogg"
const R := 11.5                       # radius of the book wall
const CENTER := Vector3.ZERO
const START := Vector3(0, 0, 6.5)
const DELOYE_H := 1.95                # his height (m), about the trio's
const DELOYE_Y := 2.0                 # how high his feet float
const BOOK_Y := 5.6
const EXIT_A := -1.62                 # angle of the EXIT door (0 = north, negative = west)
const SHELF_A := 0.95                 # the shelf you can read (east-north-east)
const TABLE := Vector3(-6.4, 0, 2.6)  # reading table (west)
const BOOK_SPOT := Vector3(-2.7, 0, 0.9)   # where you stand to look up at the book (front-left of the dais, clear of Deloye's spot)
const SHELF_W := 2.8                  # one shelf segment of the book wall
const SHELF_H := 18.0                 # (a multiple of 2 m: the book texture is 2 m tall)

var stage := "busy"                   # busy / walk / end
var deloye: Node3D                    # root (char_label target)
var deloye_spr: Sprite3D
var views := {}                       # front / side / back textures
var spin := 0.0                       # his twirl angle
var spin_speed := 1.4                 # rad/s; 0 while he's talking to you (eases to facing front)
var book: Node3D
var flip_pages: Array = []            # [pivot, phase]
var orbiters: Array = []              # [node, radius, height, speed, angle, tilt]
var floaters: Array = []              # [node, base_y, speed, phase]
var hum: AudioStreamPlayer
var swell := 0.0                      # 1 = hum/song at full (by the book)
var music: Node                       # AreaMusic, only if Ebain's song is in

func _configure() -> void:
	night = true
	light_dir = Vector3(-0.3, 0.8, -0.5)
	clear_center = Vector2(0, 0)
	clear_radius = 3.0
	path_width = 0.0
	bounds = Rect2(-10.6, -10.6, 21.2, 20.0)
	subtitle = "??? — The Deloye Lore Library"
	party_ids = ["lykor", "xylo"] if Game.flag("skornAway") else ["skorn", "lykor", "xylo"]
	party_start = [START, START + Vector3(-1.2, 0, 1.2), START + Vector3(1.2, 0, 1.2)]
	leader_id = "xylo"
	cam_locked = true
	zoom = 11.0
	cam_height = 0.38
	cam_look_h = 2.0
	checkpoint = START
	for id in DS.TALK:
		if id in party_ids:
			talk[id] = _steps(DS.TALK[id])

# Skorn's lines drop out on runs where he's still on the goblin throne
func _steps(arr: Array) -> Array:
	if not Game.flag("skornAway"):
		return arr
	return arr.filter(func(s): return s.get("who", "") != "skorn")

# Dim and warm, lit by the candles, chandeliers, the dais and the book (cutouts only see these glows)
func light_at(p: Vector3) -> Color:
	var col := Color(0.55, 0.5, 0.5)
	for g in glows:
		var f: float = clamp(1.0 - p.distance_to(g["pos"]) / g["radius"], 0.0, 1.0)
		f = f * f * float(g["strength"].call())
		col = col.lerp(g["color"], clamp(f * 1.2, 0.0, 1.0)) + g["color"] * 0.25 * f
	return Color(min(col.r, 1.2), min(col.g, 1.15), min(col.b, 1.1))

# ================================================================ building
func _build_level() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1777
	var wood := Models.mat("dark_wood", 1.5, Color(0.55, 0.42, 0.36))
	var marble := Models.mat("marble_tiles", 1.5, Color(0.8, 0.76, 0.72))
	var books := StandardMaterial3D.new()   # book spines (drawn texture: 2 m × 2 m, 4 shelves), mapped per shelf face
	books.albedo_texture = load("res://assets/textures/book_spines/albedo.jpg")
	books.albedo_color = Color(0.9, 0.85, 0.82)
	books.roughness = 0.85
	books.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	books.uv1_scale = Vector3(SHELF_W / 2.0, SHELF_H / 2.0, 1.0)
	# floor over the whole hall (hides the grass) + a round rug under the dais
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	Util.add_mesh(self, pm, Models.mat("old_wooden_floor_01", 3.0, Color(0.5, 0.46, 0.44)), Vector3(0, 0.005, 0))
	var rug := Models.cylinder(self, CENTER + Vector3(0, 0.01, 0), 3.8, 3.8, 0.02, Models.mat("quatrefoil_jacquard_fabric", 1.2, Color(0.42, 0.36, 0.55)), 48)
	rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the book wall: tall shelves all the way round except the camera side, climbing up into the dark
	var a := -2.3
	while a <= 2.5:
		_shelf_segment(a, SHELF_H, books, wood)
		a += 0.235
	# the camera side: a low wooden rail (full-height collision) so the hall stays round
	a = 2.74
	while a < TAU - 2.74:
		var p := Vector3(sin(a) * R, 0, -cos(a) * R)
		Models.block(self, p + Vector3(0, 0.45, 0), Vector3(2.8, 0.12, 0.25), wood, -a)
		Models.block(self, p + Vector3(0, 0.22, 0), Vector3(0.2, 0.45, 0.2), wood, -a)
		Util.static_box(self, p + Vector3(0, 1.5, 0), Vector3(2.9, 3.0, 0.6), -a)
		a += 0.235
	# the dais in the middle: marble steps + a slowly turning rune circle
	Models.cylinder(self, CENTER + Vector3(0, 0.12, 0), 2.3, 2.3, 0.24, marble, 40)
	Models.cylinder(self, CENTER + Vector3(0, 0.3, 0), 1.7, 1.7, 0.16, marble, 40)
	Util.static_cyl(self, CENTER, 1.8, 2.0)
	_rune_circle(CENTER + Vector3(0, 0.42, 0), 1.65, Color(1.0, 0.75, 0.4))
	add_glow(CENTER + Vector3(0, 1.5, 0), Color(1.0, 0.8, 0.5), 5.5, func(): return 0.9)
	# a spiral stair (east) and two ladders against the shelves
	_spiral(Vector3(sin(1.25) * 9.0, 0, -cos(1.25) * 9.0), wood)
	_ladder(-0.75, wood)
	_ladder(1.85, wood)
	# chandeliers
	for c in [Vector3(0, 9.5, -4.0), Vector3(-6.0, 8.5, 1.0), Vector3(6.0, 8.5, 1.0)]:
		Models.place(self, "Chandelier_01", c, 0.0, 1.6, false, Color(1.0, 0.85, 0.6))
		_light(c + Vector3(0, -1.0, 0), Color(1.0, 0.72, 0.42), 1.4, 11.0)
		add_glow(c - Vector3(0, 5.5, 0), Color(1.0, 0.75, 0.45), 6.0, func(): return 0.45)
	# the reading table (west): books, a magnifying glass, an oil lamp, an armchair
	Models.place(self, "round_wooden_table_01", TABLE, 0.3, 1.2, true, Color(0.6, 0.48, 0.42))
	Models.place(self, "book_encyclopedia_set_01", TABLE + Vector3(-0.2, 1.21, 0.1), 0.6, 1.4)
	Models.place(self, "magnifying_glass_01", TABLE + Vector3(0.35, 1.21, 0.3), 1.1, 1.6)
	Models.place(self, "vintage_oil_lamp", TABLE + Vector3(0.1, 1.21, -0.4), 0.0, 1.3)
	Models.place(self, "ArmChair_01", TABLE + Vector3(-1.4, 0, -0.9), 0.9, 1.4, true, Color(0.5, 0.25, 0.3))
	_light(TABLE + Vector3(0.1, 1.8, -0.2), Color(1.0, 0.7, 0.4), 1.0, 5.0)
	add_glow(TABLE + Vector3(0, 1.5, 0), Color(1.0, 0.72, 0.42), 4.0, func(): return 0.6)
	# east: a little desk with candles + stacks of books on the floor
	var desk := Vector3(6.6, 0, 3.4)
	Models.place(self, "round_wooden_table_01", desk, 1.2, 1.0, true, Color(0.6, 0.48, 0.42))
	for k in 3:
		Models.place(self, "wooden_candlestick", desk + Vector3(-0.3 + k * 0.3, 1.0, 0.1 * k), 0.0, 1.2)
		_candle(desk + Vector3(-0.3 + k * 0.3, 1.32, 0.1 * k), 1.0)
	add_glow(desk + Vector3(0, 1.4, 0), Color(1.0, 0.75, 0.45), 4.0, func(): return 0.6)
	_light(desk + Vector3(0, 1.8, 0), Color(1.0, 0.72, 0.42), 0.9, 5.0)
	for s in [Vector3(-4.2, 0, -6.5), Vector3(4.6, 0, -6.2), Vector3(-8.4, 0, -2.5), Vector3(3.2, 0, 6.8)]:
		_book_stack(s, r)
	# floating candles + books orbiting the middle
	for k in 16:
		var ang := r.randf() * TAU
		var rr := r.randf_range(3.5, 9.5)
		var p := Vector3(sin(ang) * rr, r.randf_range(5.0, 9.0), -cos(ang) * rr * 0.9)
		var cn := _candle(p, 1.3)
		floaters.append([cn, p.y, 0.5 + r.randf() * 0.6, r.randf() * TAU])
	for k in 12:
		var b := _small_book(r)
		orbiters.append([b, r.randf_range(3.2, 7.0), r.randf_range(2.4, 6.5), r.randf_range(0.12, 0.3) * (1.0 if k % 3 else -1.0), r.randf() * TAU, r.randf_range(-0.4, 0.4)])
	# dust drifting in three light beams from somewhere far above
	for bp in [Vector3(-2.5, 0, -2.0), Vector3(3.0, 0, -1.0), Vector3(0.5, 0, 3.0)]:
		_beam(bp)
	_motes(Vector3(0, 4.0, -1.0), Vector3(9, 4, 8), Color(1.0, 0.88, 0.6), 110)
	# the EXIT door (west) + a sign
	var dp := Vector3(sin(EXIT_A) * (R - 0.55), 0, -cos(EXIT_A) * (R - 0.55))
	var door := Models.place(self, "large_castle_door", dp, -EXIT_A, 1.0, false, Color(0.75, 0.62, 0.55))
	var bb := Models.aabb(door)
	if bb.size.y > 0.01:
		door.scale *= 3.2 / bb.size.y
	wood_sign("sign_library_exit", "EXIT", dp + Vector3(0, 3.6, 0) + Vector3(-sin(EXIT_A), 0, cos(EXIT_A)) * 0.3, -EXIT_A, 1.0, 0.45)
	_light(dp + Vector3(-sin(EXIT_A), 0, cos(EXIT_A)) * 1.2 + Vector3(0, 2.6, 0), Color(1.0, 0.7, 0.45), 0.8, 5.0)
	add_glow(dp + Vector3(0, 1.6, 0), Color(1.0, 0.72, 0.45), 3.5, func(): return 0.5)
	_build_book()
	_build_deloye()

# one tall shelf: book faces, shelf boards every 1.9 m, posts on the sides
func _shelf_segment(a: float, h: float, books: StandardMaterial3D, wood: Material) -> void:
	var dir := Vector3(sin(a), 0, -cos(a))
	var p := dir * R
	var w := SHELF_W
	Models.block(self, p + Vector3(0, h / 2.0, 0), Vector3(w + 0.1, h, 0.8), wood, -a)
	var qm := QuadMesh.new()   # the book face, facing the middle
	qm.size = Vector2(w, h)
	var face := Util.add_mesh(self, qm, books, p - dir * 0.41 + Vector3(0, h / 2.0, 0), Vector3(0, -a, 0))
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var side := Vector3(cos(a), 0, sin(a))   # along the shelf
	Models.block(self, p - dir * 0.45 + side * (w / 2.0) + Vector3(0, h / 2.0, 0), Vector3(0.16, h, 0.2), wood, -a)
	Util.static_box(self, p + Vector3(0, 1.5, 0), Vector3(w + 0.1, 3.0, 1.0), -a)

func _spiral(base: Vector3, wood: Material) -> void:
	Models.cylinder(self, base + Vector3(0, 6.5, 0), 0.16, 0.16, 13.0, wood, 10)
	Util.static_cyl(self, base, 0.9, 3.0)
	for k in 30:
		var ang := k * 0.42
		var off := Vector3(cos(ang), 0, sin(ang)) * 0.6
		Models.block(self, base + off + Vector3(0, 0.25 + k * 0.42, 0), Vector3(1.2, 0.08, 0.45), wood, -ang)

func _ladder(a: float, wood: Material) -> void:
	var dir := Vector3(sin(a), 0, -cos(a))
	var foot := dir * (R - 1.4)
	var root := Node3D.new()
	add_child(root)
	root.position = foot
	root.rotation = Vector3(0, -a, 0)
	for s in [-0.3, 0.3]:
		Models.block(root, Vector3(s, 3.2, 0), Vector3(0.07, 6.6, 0.07), wood)
	for k in 16:
		Models.block(root, Vector3(0, 0.3 + k * 0.4, 0), Vector3(0.6, 0.05, 0.05), wood)
	root.rotate_object_local(Vector3.RIGHT, -0.18)   # leaning on the shelf

func _book_stack(p: Vector3, r: RandomNumberGenerator) -> void:
	var y := 0.0
	for k in r.randi_range(3, 6):
		var h := r.randf_range(0.06, 0.1)
		var c := Color.from_hsv(r.randf_range(0.0, 0.12) if r.randf() < 0.7 else r.randf_range(0.55, 0.7), 0.55, r.randf_range(0.3, 0.55))
		Models.block(self, p + Vector3(r.randf_range(-0.04, 0.04), y + h / 2.0, 0), Vector3(0.42, h, 0.3), Util.mat(c), r.randf_range(-0.4, 0.4))
		y += h

func _small_book(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var c := Color.from_hsv(r.randf_range(0.0, 0.12) if r.randf() < 0.7 else r.randf_range(0.55, 0.75), 0.6, r.randf_range(0.35, 0.6))
	var cover := Models.mat("fabric_leather_01", 3.0, c)
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.09, 0.5)
	Util.add_mesh(root, bm, cover, Vector3.ZERO)
	var pg := BoxMesh.new()
	pg.size = Vector3(0.33, 0.07, 0.47)
	Util.add_mesh(root, pg, Util.mat(Color(0.9, 0.85, 0.72)), Vector3(0.02, 0, 0))
	return root

func _candle(p: Vector3, size: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	root.position = p
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05 * size
	cm.bottom_radius = 0.05 * size
	cm.height = 0.3 * size
	Util.add_mesh(root, cm, Util.mat(Color(0.92, 0.88, 0.78)), Vector3.ZERO)
	var fm := SphereMesh.new()
	fm.radius = 0.035 * size
	fm.height = 0.11 * size
	Util.add_mesh(root, fm, _emissive(Color(1.0, 0.8, 0.45), 4.0), Vector3(0, 0.2 * size, 0))
	return root

func _beam(p: Vector3) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 1.6
	cm.height = 16.0
	cm.cap_top = false
	cm.cap_bottom = false
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1.0, 0.85, 0.55, 0.03)
	var n := Util.add_mesh(self, cm, m, p + Vector3(0, 8.0, 0))
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _motes(c: Vector3, ext: Vector3, col: Color, n: int) -> void:
	var a := CPUParticles3D.new()
	a.amount = n
	a.lifetime = 7.0
	a.mesh = Fx.quad(0.05, true)
	a.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	a.emission_box_extents = ext
	a.direction = Vector3.UP
	a.spread = 70.0
	a.gravity = Vector3(0, 0.03, 0)
	a.initial_velocity_min = 0.03
	a.initial_velocity_max = 0.15
	a.color_ramp = Fx.ramp([[0.0, Color(col.r, col.g, col.b, 0)], [0.3, col], [1.0, Color(col.r, col.g, col.b, 0)]])
	a.position = c
	add_child(a)

func _light(p: Vector3, c: Color, energy: float, rng_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = energy
	l.omni_range = rng_m
	l.position = p
	add_child(l)
	return l

func _emissive(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

const RUNE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.75, 0.4, 1.0);
float ring(float r, float c, float w) { return smoothstep(w, 0.0, abs(r - c)); }
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float v = ring(r, 0.95, 0.03) + ring(r, 0.8, 0.018) + ring(r, 0.35, 0.02);
	v += step(0.8, r) * step(r, 0.95) * step(0.6, fract(a * 20.0 / 6.2832 + sin(floor(a * 20.0 / 6.2832) * 5.3) * 0.3)) * 0.6;
	float lines = 0.0;   // open-book shapes between the rings
	for (int i = 0; i < 5; i++) {
		float ang = float(i) * 6.2832 / 5.0;
		vec2 d = vec2(cos(ang), sin(ang));
		lines += smoothstep(0.02, 0.0, abs(dot(p, vec2(-d.y, d.x)))) * step(0.35, r) * step(r, 0.8);
	}
	v += lines * 0.7;
	float pulse = 0.75 + 0.25 * sin(TIME * 1.3);
	ALBEDO = col.rgb * v * 2.0 * pulse;
	ALPHA = clamp(v, 0.0, 1.0) * step(r, 1.0);
}
"""
var rune: Node3D
func _rune_circle(p: Vector3, rad: float, c: Color) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = RUNE_SHADER
	sm.set_shader_parameter("col", c)
	var pm := PlaneMesh.new()
	pm.size = Vector2(rad * 2.0, rad * 2.0)
	rune = Util.add_mesh(self, pm, sm, p)
	_light(p + Vector3(0, 0.8, 0), c, 1.2, rad * 3.0)

# The giant Deloye Lore manuscript: open, glowing, turning slowly, pages flipping by themselves
func _build_book() -> void:
	book = Node3D.new()
	add_child(book)
	book.position = CENTER + Vector3(0, BOOK_Y, 0)
	var cover := Models.mat("fabric_leather_01", 2.0, Color(0.45, 0.12, 0.12))
	var paper := StandardMaterial3D.new()   # written pages, softly glowing
	paper.albedo_texture = load("res://assets/props/book_page.png")
	paper.albedo_color = Color(0.8, 0.72, 0.58)
	paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for s in [-1.0, 1.0]:   # two halves in a shallow V
		var half := Node3D.new()
		book.add_child(half)
		half.rotation.z = s * -0.18
		var cb := BoxMesh.new()
		cb.size = Vector3(1.3, 0.08, 1.8)
		Util.add_mesh(half, cb, cover, Vector3(s * 0.65, -0.05, 0))
		var pb := BoxMesh.new()
		pb.size = Vector3(1.2, 0.16, 1.7)
		Util.add_mesh(half, pb, paper, Vector3(s * 0.62, 0.06, 0))
	for k in 3:   # flipping pages: pivot on the spine, swing right → left
		var pivot := Node3D.new()
		book.add_child(pivot)
		pivot.position = Vector3(0, 0.16, 0)
		var qm := QuadMesh.new()
		qm.size = Vector2(1.15, 1.65)
		var pgm := paper.duplicate()
		pgm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var q := Util.add_mesh(pivot, qm, pgm, Vector3(0.6, 0, 0))
		q.rotation.x = -PI / 2.0
		flip_pages.append([pivot, k / 3.0])
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.55)
	l.light_energy = 2.2
	l.omni_range = 7.0
	l.position = Vector3(0, 0.6, 0)
	book.add_child(l)
	var sp := CPUParticles3D.new()   # glowing letters drifting off the pages
	sp.amount = 24
	sp.lifetime = 2.5
	sp.mesh = Fx.quad(0.06, true)
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sp.emission_box_extents = Vector3(1.1, 0.1, 0.8)
	sp.direction = Vector3.UP
	sp.gravity = Vector3(0, 0.15, 0)
	sp.initial_velocity_min = 0.1
	sp.initial_velocity_max = 0.35
	sp.color_ramp = Fx.ramp([[0.0, Color(1, 0.85, 0.5, 0)], [0.25, Color(1, 0.85, 0.5, 1)], [1.0, Color(1, 0.85, 0.5, 0)]])
	sp.position = Vector3(0, 0.3, 0)
	book.add_child(sp)
	add_glow(book.position, Color(1.0, 0.85, 0.55), 5.0, func(): return 0.7 + swell * 0.3)

# Deloye: a billboard that turns front → side → back → side, so it reads as twirling in place
func _build_deloye() -> void:
	for v in ["", "_side", "_back"]:
		views[v] = load("res://assets/characters/deloye%s.png" % v)
	deloye = Node3D.new()
	add_child(deloye)
	deloye.position = CENTER + Vector3(0, DELOYE_Y, 0)
	deloye_spr = Sprite3D.new()
	deloye_spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	deloye_spr.shaded = false
	deloye_spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	deloye_spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	deloye_spr.offset = Vector2(0, 0)
	deloye_spr.centered = true
	deloye.add_child(deloye_spr)
	_set_view("", false)
	var sh := Util.blob_shadow(0.6)   # a faint shadow on the dais so he reads as floating
	add_child(sh)
	sh.position = CENTER + Vector3(0, 0.41, 0)
	var under := CPUParticles3D.new()   # a soft swirl of light under his feet
	under.amount = 30
	under.lifetime = 1.8
	under.mesh = Fx.quad(0.07, true)
	under.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	under.emission_ring_radius = 0.55
	under.emission_ring_inner_radius = 0.35
	under.emission_ring_height = 0.05
	under.emission_ring_axis = Vector3.UP
	under.direction = Vector3.UP
	under.gravity = Vector3(0, 0.4, 0)
	under.initial_velocity_min = 0.1
	under.initial_velocity_max = 0.3
	under.orbit_velocity_min = 0.3
	under.orbit_velocity_max = 0.5
	under.color_ramp = Fx.ramp([[0.0, Color(1, 0.85, 0.55, 0)], [0.3, Color(1, 0.85, 0.55, 1)], [1.0, Color(1, 0.85, 0.55, 0)]])
	under.position = Vector3(0, -0.1, 0)
	deloye.add_child(under)
	add_glow(CENTER + Vector3(0, DELOYE_Y + 1.0, 0), Color(0.85, 0.8, 1.0), 2.5, func(): return 0.6)

func _set_view(v: String, flip: bool) -> void:
	var tex: Texture2D = views[v]
	if deloye_spr.texture != tex:
		deloye_spr.texture = tex
		deloye_spr.pixel_size = DELOYE_H / tex.get_height()
		deloye_spr.position = Vector3(0, DELOYE_H / 2.0, 0)
	deloye_spr.flip_h = flip

func _after_build() -> void:
	var env: Environment = world_env.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0)
	env.ambient_light_color = Color(0.5, 0.46, 0.5)
	env.ambient_light_energy = 0.8
	env.tonemap_exposure = 1.25
	env.fog_light_color = Color(0.03, 0.02, 0.02)
	env.fog_density = 0.02
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(1.0, 0.85, 0.6)
	env.glow_intensity = 0.9
	sun_light.light_energy = 0.0
	sun_light.shadow_enabled = false
	sun_light.visible = false
	if ResourceLoader.exists(SONG):   # Ebain's song: a normal AreaMusic (unlocks it in the Library once heard)
		music = load("res://scripts/area_music.gd").new()
		music.track = load(SONG)
		music.stages = PackedStringArray(["walk"])
		add_child(music)
	else:
		hum = play_sound("library_hum", -60.0, 1.0, true)

# ================================================================ per frame
func _level_process(delta: float) -> void:
	# Deloye twirls; while he's talking to you he eases round to face front
	if spin_speed > 0.0:
		spin = fmod(spin + spin_speed * delta, TAU)
	else:
		var target: float = round(spin / TAU) * TAU
		spin = move_toward(spin, target, delta * 3.0)
	var q := fmod(spin + PI / 4.0, TAU)       # quarter turns: front, side, back, side (mirrored)
	var idx := int(q / (PI / 2.0)) % 4
	_set_view(["", "_side", "_back", "_side"][idx], idx == 3)
	var phase := fmod(q, PI / 2.0) - PI / 4.0  # squash at each quarter so the turn reads
	deloye_spr.scale = Vector3(0.45 + 0.55 * absf(cos(phase * 2.0)), 1.0, 1.0)
	deloye.position.y = DELOYE_Y + sin(t * 1.3) * 0.15
	deloye_spr.modulate = light_at(deloye.global_position + Vector3(0, 1.0, 0)) * Color(1.05, 1.0, 1.0)
	# the book turns, pages flip, the rune turns the other way
	book.rotation.y += delta * 0.25
	book.position.y = BOOK_Y + sin(t * 0.9) * 0.12
	for f in flip_pages:
		var ph: float = fmod(t * 0.35 + f[1], 1.0)
		f[0].rotation.z = clampf(ph * 1.3, 0.0, 1.0) * PI * 0.92 + 0.15
	if rune:
		rune.rotation.y -= delta * 0.15
	for o in orbiters:
		o[4] += o[3] * delta
		var n: Node3D = o[0]
		n.position = CENTER + Vector3(sin(o[4]) * o[1], o[2] + sin(t * 0.8 + o[4]) * 0.25, -cos(o[4]) * o[1])
		n.rotation = Vector3(o[5], -o[4] + PI / 2.0, 0.2)
	for f in floaters:
		f[0].position.y = f[1] + sin(t * f[2] + f[3]) * 0.18
	# the hum swells near the middle (and all the way at the book)
	var d := Vector2(leader.global_position.x, leader.global_position.z).length()
	var want := clampf(1.0 - (d - 2.5) / 7.0, 0.0, 1.0) * 0.6
	swell = move_toward(swell, 1.0 if _book_swelling else want, delta * 0.8)
	if hum:
		hum.volume_db = lerpf(-28.0, -12.0, swell) - (6.0 if dialogue.active else 0.0)

var _book_swelling := false

# ================================================================ story
func _begin() -> void:
	busy = true
	freeze_all(true)
	follow_enabled = false
	Game.unlock("deloye_found")   # secret achievement + the Scrapbook page
	fade.color = Color(1, 1, 1, 1)   # white, from the flush
	for i in party.size():   # everyone drops in from above
		party[i].global_position = START + Vector3(-0.8 + i * 0.8, 6.0 + i * 1.2, -0.3 + (i % 2) * 0.6)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 0.9)
	for i in party.size():
		var u: Unit = party[i]
		var land := START + Vector3(-0.6 + i * 0.6, 0, (i % 2) * 0.5)
		var ft := create_tween()
		ft.tween_property(u, "global_position", land, 0.45 + i * 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await ft.finished
		knock(u, 85.0 if i % 2 == 0 else -85.0, 0.1)
		play_sound("sfx_punch", -10.0, 0.8 + i * 0.1)
		shake = 0.25
	await wait(0.9)
	for u in party:
		unknock(u)
		hop(u, 0.3)
	await wait(0.5)
	fade.color = Color(0, 0, 0, 0)
	follow_enabled = true
	freeze_all(false)
	await run_dialogue(_steps(DS.ARRIVE))
	_walk()

func _walk() -> void:
	stage = "walk"
	busy = false
	if Game.flag("deloyeMet"):
		objective("Look around, or take the EXIT.")
	else:
		objective("Talk to the guy spinning in the middle.", CENTER)

func _level_interactables() -> Array:
	var list: Array = []
	if stage != "walk":
		return list
	var deloye_steps: Array = DS.AGAIN[randi() % DS.AGAIN.size()] if Game.flag("deloyeMet") else DS.MEET
	list.append({ "id": "deloye", "label": "Deloye", "verb": "Talk to", "pos": CENTER + Vector3(0, 0, 2.5), "h": 3.6, "r": 2.2, "steps": _steps(deloye_steps) })
	list.append({ "id": "book", "label": "the floating book", "verb": "Look up at", "pos": BOOK_SPOT, "h": 2.4, "r": 1.4, "steps": DS.BOOK })
	list.append({ "id": "table", "label": "the reading table", "verb": "Look at", "pos": TABLE + Vector3(1.2, 0, 0.6), "h": 1.6, "r": 1.6, "steps": DS.TABLE })
	var sp := Vector3(sin(SHELF_A), 0, -cos(SHELF_A)) * (R - 1.4)
	list.append({ "id": "shelf", "label": "the shelves", "verb": "Read", "pos": sp, "h": 2.0, "r": 1.6, "steps": _steps(DS.SHELF) if "skorn" in party_ids else [{ "who": "xylo", "line": "Volume 4,019: The Wind. A classic." }] }) # DRAFT
	var dp := Vector3(sin(EXIT_A), 0, -cos(EXIT_A)) * (R - 2.0)
	list.append({ "id": "exit", "label": "the EXIT", "verb": "Go through", "pos": dp, "h": 3.4, "r": 1.8, "steps": _steps(DS.EXIT_DOOR), "major": true })
	return list

func _on_action(n: String) -> void:
	match n:
		"earbud_out":
			spin_speed = 0.0
			char_label(deloye, "*takes one earbud out*", 2.2, DELOYE_H + 0.3, Color("#d9d2ff"))   # DRAFT
			await wait(0.9)
		"earbud_in":
			char_label(deloye, "*earbud back in*", 2.2, DELOYE_H + 0.3, Color("#d9d2ff"))   # DRAFT
			Game.set_flag("deloyeMet")
			await wait(0.6)
			spin_speed = 1.4
			objective("Look around, or take the EXIT.")
		"gift":
			await _gift()
		"book_swell":
			_book_swelling = true
			get_tree().create_timer(8.0).timeout.connect(func(): _book_swelling = false)
			await wait(0.4)
		"leave":
			stage = "end"
			busy = true
			play_sound("sfx_door", -4.0)
			await fade_out(0.7)
			Game.travel("res://village.tscn", "library", leader.id)

func _gift() -> void:
	if Game.flag("deloyeGift"):   # already got it this run (came back on a loaded save)
		show_toast("Xylo already has the Deloye Lore Neuralink.", 2.0)
		await wait(0.4)
		return
	Game.set_flag("deloyeGift")
	Game.give_gear("neuralink", "xylo")
	var x: Unit = null
	for u in party:
		if u.id == "xylo":
			x = u
	if x:
		var p := Fx.poof(Color(0.8, 0.7, 1.0))
		add_child(p)
		p.global_position = x.global_position + Vector3(0, 1.6, 0)
		p.emitting = true
		hop(x, 0.4)
		char_label(x, "Xylo (Plugged In)", 3.0, x.height_m + 0.3, Color("#ffdf4a"))   # DRAFT
	play_sound("sfx_reward", -4.0)
	show_toast("Xylo got: Deloye Lore Neuralink (equip it in Tab)", 3.0)
	await wait(0.8)

# ---------------------------------------------------------------- saves: a save in here restarts the visit (lands again)
func arrival(_from: String) -> Array:
	return [START, Vector3(0, 0, -1)]

# ---------------------------------------------------------------- automated test
# Arrive, talk to Deloye (gift), look at the book, leave through the EXIT → the village (its tour doesn't run on travel).
func _shot_tour() -> void:
	await _begin_quick()
	await shot("dl_01_arrive")
	place_party(CENTER + Vector3(0, 0, 3.6), Vector3(0, 0, -1))
	await wait(0.8)
	await shot("dl_02_deloye")
	var it: Array = current_interactables().filter(func(i): return i["id"] == "deloye")
	start(it[0])
	await wait(0.4)
	for k in 30:
		if not dialogue.active:
			break
		await advance(1, 0.25)
	await wait(0.6)
	print("DELOYE TOUR met=", Game.flag("deloyeMet"), " gift=", Game.flag("deloyeGift"), " owner=", Game.gear_owner.get("neuralink", ""),
		" found=", Game.progress.has("deloye_found"), " ach=", Game.ach.got.has("lore_accurate"))
	place_party(BOOK_SPOT + Vector3(-0.4, 0, 0.6), Vector3(1, 0, -1))
	await wait(0.6)
	start(current_interactables().filter(func(i): return i["id"] == "book")[0])
	for k in 10:
		if not dialogue.active:
			break
		await advance(1, 0.25)
	await shot("dl_03_book")
	if OS.get_environment("DELOYE_EXIT") != "":
		var dp := Vector3(sin(EXIT_A), 0, -cos(EXIT_A)) * (R - 2.6)
		place_party(dp, Vector3(-1, 0, 0))
		await wait(0.6)
		start(current_interactables().filter(func(i): return i["id"] == "exit")[0])
		for k in 6:
			await advance(1, 0.3)
		print("DELOYE TOUR exit stage=", stage)
		await wait(3.0)
	get_tree().quit()

func _begin_quick() -> void:
	fade.color.a = 0.0
	Game.unlock("deloye_found")
	busy = false
	await wait(1.2)
	stage = "walk"
	_walk()
