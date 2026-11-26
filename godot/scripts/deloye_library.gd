# Area: the secret Deloye Lore library (DELOYE_PLAN.md). Pure easter egg: no fight, no test.
# You get here by finding all 5 Lost Deloye Lore Pages (lost_pages.gd) and flushing the village outhouse (village.gd).
# A big library you walk through (Ebain 11/24: "much bigger place you have to walk around in", Deloye = the end):
#   Atrium (south, you land here) → the Grand Stacks (long hall north) → wings: Hall of Wind (west) → Restricted
#   Section (south of it), Rock Room (east) → Reading Corner (south of it). The Reading Room at the north end (the round
#   rotunda) is behind a rune curtain until you find the 3 joint pieces (plant / papers / lighter, flags
#   libPiece_<key>): then Deloye calls you in and it opens (libGateOpen). Ebain's script 11/25: Metocin Mattias
#   teleports in on arrival (libMattias), walking banter as speech bubbles, he guides you to the first piece, then
#   "You could help me?" → he guides you to the rest (libGuideAll) and to Deloye's room. Camera is fixed facing north, so every east-west wall that has
#   walkable floor north of it is a LOW bookcase (full-height collision); only north/outer walls are tall.
# The rotunda: book walls climbing into the dark, a spiral stair, ladders, chandeliers, dust in light beams, books
# orbiting the middle. In the center Deloye himself (Ebain's art) floats and twirls on a rune dais, the giant
# Deloye Lore manuscript turning above his head with its pages flipping. Walking in the first time plays ROTUNDA
# (libRotunda). Talk to him: he gives Xylo the Deloye Lore Neuralink (flag deloyeGift, once per run). The EXIT door
# (rotunda, west) or the pipe (Atrium) go back to the village, next to the outhouse.
# Saves: free roam resumes where you stood (libEntered).
# Arriving unlocks progress "deloye_found" (secret achievement + the secret Scrapbook page).
# Music: a soft hum everywhere; Ebain's Deloye Lore song (SONG, when it exists) plays from the radio in the Reading
# Corner (Ebain 11/25), on when you arrive, E toggles it; heard up close = unlocked in the title Library.
extends Level

const DS = preload("res://scripts/deloye_script.gd")
const SONG := "res://assets/music/deloye_lore.ogg"
const R := 11.5                       # radius of the book wall
const CENTER := Vector3.ZERO
const START := Vector3(0, 0, 54.0)       # the Atrium, where the flush drops you
const ROT_IN := Vector3(0, 0, 6.5)       # just inside the rotunda
const DELOYE_H := 1.95                # his height (m), about the trio's
const DELOYE_Y := 2.0                 # how high his feet float
const BOOK_Y := 5.6
const EXIT_A := -1.62                 # angle of the EXIT door (0 = north, negative = west)
const SHELF_A := 0.95                 # the shelf you can read (east-north-east)
const TABLE := Vector3(23.5, 0, 46.0)  # reading table (the Reading Corner)
const WALL_H := 10.0                  # tall shelves outside the rotunda (multiple of 2 m)
const LOW_H := 1.3                    # low bookcases (camera side)
const LIP_H := 0.45                   # the south edge of the rooms: just a wooden lip, so it never covers the view
const GATE_Z := 11.0                  # the rune curtain across the rotunda's south opening
const GATE_HW := 3.3                  # its half width
const CHUTE := Vector3(-6.5, 0, 55.5)
const DIRECTORY := Vector3(0, 0, 47.4)
const RETURN_DESK := Vector3(6.8, 0, 55.0)
const CATALOG := Vector3(-6.2, 0, 19.0)
const STAFF := Vector3(6.2, 0, 41.5)
const WINDOW := Vector3(-29.5, 0, 31.0)
const PAGES := Vector3(-13.5, 0, 27.0)
const ROPE_Z := 40.0
const ROCK := Vector3(19.5, 0, 29.5)
const SEAT := Vector3(27.0, 0, 49.0)
const PIECES := {   # the 3 joint pieces (Ebain 11/25), each on a glowing lectern (you take it from the south side)
	"plant": Vector3(-24.0, 0, 27.5),     # the Hall of Wind
	"papers": Vector3(-24.0, 0, 46.5),    # the Restricted Section
	"lighter": Vector3(14.0, 0, 27.5),    # the Rock Room
}
const PIECE_NAMES := { "plant": "the cannabis plant", "papers": "RAW papers", "lighter": "a lighter" }
const BOOK_SPOTS := {   # readable books (LibraryBooks, BookUI): [where, "stand" = an open book on a stand / "shelf" = glowing spine]
	"prophecy_three": [Vector3(-3.4, 0, 27.0), "stand"],    # the Grand Stacks, on a stand by itself
	"on_metocy": [Vector3(-27.6, 0, 36.0), "stand"],        # the Hall of Wind, by the window
	"dulbmeethus": [Vector3(-27.0, 0, 43.4), "stand"],      # the Restricted Section, behind the rope
	"library_card": [Vector3(19.5, 0, 43.5), "shelf"],      # the Reading Corner, tucked in a book on the bookshelf
	"the_giant": [Vector3(24.5, 0, 29.0), "stand"],         # the Rock Room, near THE ROCK
	"prophecy_death": [Vector3(sin(-0.95) * (R - 1.0), 0, -cos(-0.95) * (R - 1.0)), "shelf"],   # Deloye's room
}
const LB = preload("res://scripts/library_books.gd")
const RADIO_POS := Vector3(20.2, 0, 49.4)   # the Reading Corner: plays Ebain's Deloye song (SONG)
# rooms (x0, z0, x1, z1) for floors, the maps and the explorer
const ROOMS := {
	"atrium": Rect2(-12, 46, 24, 14),
	"stacks": Rect2(-8, 8, 16, 38),
	"wind": Rect2(-30, 24, 22, 16),
	"restricted": Rect2(-30, 40, 12, 12),
	"rock": Rect2(8, 24, 22, 16),
	"corner": Rect2(18, 40, 12, 12),
}
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
var lect := {}                        # key -> [piece node, sparkle, light]
var lect_hum := {}                    # key -> the piece's magic hum (Ebain's sfx pack), stops when you take it
var mattias: Unit                     # Metocin Mattias (Ebain's script): follows you, or walks ahead to guide
var mattias_light: OmniLight3D
var guide_target = null               # Vector3 he's walking to (null = following)
var radio: AudioStreamPlayer3D        # Ebain's Deloye song, from the Reading Corner radio
var _banter_running := false
var _radio_heard := false
var curtain: MeshInstance3D
var curtain_mat: ShaderMaterial
var curtain_body: StaticBody3D
var curtains: Array = []              # the Hall of Wind's window curtains (sway)
var wood_m: Material
var books_m: StandardMaterial3D

func _configure() -> void:
	floor_kind = "hall"   # stone footsteps (Ebain's sfx pack)
	night = true
	light_dir = Vector3(-0.3, 0.8, -0.5)
	clear_center = Vector2(999, 999)
	clear_radius = 0.1
	path_width = 0.0
	bounds = Rect2(-29.4, -10.6, 58.8, 70.0)
	subtitle = "??? — The Deloye Lore Library"
	party_ids = ["lykor", "xylo"] if Game.flag("skornAway") else ["skorn", "lykor", "xylo"]
	party_start = [START, START + Vector3(-1.2, 0, 1.2), START + Vector3(1.2, 0, 1.2)]
	leader_id = "xylo"
	cam_locked = false   # Ebain 11/26: right-drag / arrow keys turn the camera, but only so far (YAW_MAX): the walls are
	                     # built low on the camera side for a north-facing view
	zoom = 11.0
	cam_height = 0.42
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
	wood_m = Models.mat("dark_wood", 1.5, Color(0.55, 0.42, 0.36))
	books_m = StandardMaterial3D.new()   # book spines (drawn texture: 2 m × 2 m, 4 shelves), mapped per shelf face
	books_m.albedo_texture = load("res://assets/textures/book_spines/albedo.jpg")
	books_m.albedo_color = Color(0.9, 0.85, 0.82)
	books_m.roughness = 0.85
	books_m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# a dark floor under everything (hides the grass), then a wooden floor per room (smaller meshes = fewer lights each)
	var under := PlaneMesh.new()
	under.size = Vector2(160, 160)
	Util.add_mesh(self, under, Util.mat(Color(0.02, 0.015, 0.015)), Vector3(0, 0.003, 25))
	var floor_m := Models.mat("old_wooden_floor_01", 3.0, Color(0.5, 0.46, 0.44))
	for k in ROOMS:
		var rc: Rect2 = ROOMS[k]
		var pm := PlaneMesh.new()
		pm.size = rc.size + Vector2(0.6, 0.6)
		Util.add_mesh(self, pm, floor_m, Vector3(rc.get_center().x, 0.006, rc.get_center().y))
	var pm2 := PlaneMesh.new()
	pm2.size = Vector2(24, 24)
	Util.add_mesh(self, pm2, floor_m, Vector3(0, 0.005, 0))
	_build_rotunda(r)
	_build_rooms(r)
	_build_book()
	_build_deloye()

func _build_rotunda(r: RandomNumberGenerator) -> void:
	var wood := wood_m
	var marble := Models.mat("marble_tiles", 1.5, Color(0.8, 0.76, 0.72))
	var books := books_m.duplicate()
	books.uv1_scale = Vector3(SHELF_W / 2.0, SHELF_H / 2.0, 1.0)
	var rug := Models.cylinder(self, CENTER + Vector3(0, 0.01, 0), 3.8, 3.8, 0.02, Models.mat("quatrefoil_jacquard_fabric", 1.2, Color(0.42, 0.36, 0.55)), 48)
	rug.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the book wall: tall shelves all the way round except the south (camera side), climbing up into the dark
	var a := -2.3
	while a <= 2.3:
		_shelf_segment(a, SHELF_H, books, wood)
		a += 0.235
	# the south: low bookcases (full-height collision) with the Reading Room's opening in the middle
	for span in [[2.33, PI - 0.29], [PI + 0.29, TAU - 2.33]]:
		var steps := 3
		for k in steps:
			var a0: float = lerpf(span[0], span[1], float(k) / steps)
			var a1: float = lerpf(span[0], span[1], float(k + 1) / steps)
			_wall(Vector2(sin(a0) * R, -cos(a0) * R), Vector2(sin(a1) * R, -cos(a1) * R), LOW_H, Vector2.ZERO, true)
	_build_gate()
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
	# west: an armchair by a lamp; east: a little desk with candles + stacks of books on the floor
	var lamp := Vector3(-6.6, 0, 2.6)
	Models.place(self, "ArmChair_01", lamp + Vector3(-1.0, 0, -0.9), 0.9, 1.4, true, Color(0.5, 0.25, 0.3))
	Models.place(self, "vintage_oil_lamp", lamp + Vector3(0.2, 0, -0.2), 0.0, 1.3)
	_light(lamp + Vector3(0.1, 1.2, -0.2), Color(1.0, 0.7, 0.4), 0.8, 5.0)
	add_glow(lamp + Vector3(0, 1.2, 0), Color(1.0, 0.72, 0.42), 4.0, func(): return 0.5)
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

# A straight bookcase wall from p0 to p1 (x/z). `face` = which side gets books (a direction), `both` = both sides.
# Collision is always full height, so low ones still stop you.
func _wall(p0: Vector2, p1: Vector2, h: float, face := Vector2.ZERO, both := false) -> void:
	var d := p1 - p0
	var L := d.length()
	var dir := Vector3(d.x, 0, d.y) / L
	var mid := Vector3((p0.x + p1.x) / 2.0, 0, (p0.y + p1.y) / 2.0)
	var rot := atan2(-dir.z, dir.x)
	var n0 := Vector3(sin(rot), 0, cos(rot))   # the block's local +z
	var blk := Models.block(self, mid + Vector3(0, h / 2.0, 0), Vector3(L + 0.1, h, 0.8), wood_m, rot)
	var hide_me: Array = [blk]
	if h >= 3.0:   # tall walls hide while they stand between the camera and you (the camera can turn now)
		_tall_walls.append({ "a": p0, "b": p1, "nodes": hide_me })
	Util.static_box(self, mid + Vector3(0, 1.5, 0), Vector3(L + 0.1, 3.0, 0.9), rot)
	if h < 3.0:   # a board on top of the low ones
		Models.block(self, mid + Vector3(0, h + 0.04, 0), Vector3(L + 0.2, 0.08, 0.95), wood_m, rot)
	if h < 0.6:   # a lip: plain wood, no books
		return
	var m: StandardMaterial3D = books_m.duplicate()
	m.uv1_scale = Vector3(L / 2.0, h / 2.0, 1.0)
	var sides: Array = [1.0, -1.0] if both else [signf(n0.dot(Vector3(face.x, 0, face.y))) if face != Vector2.ZERO else 1.0]
	for sd in sides:
		var qm := QuadMesh.new()
		qm.size = Vector2(L, h)
		var q := Util.add_mesh(self, qm, m, mid + n0 * (0.41 * sd) + Vector3(0, h / 2.0, 0), Vector3(0, rot + (0.0 if sd > 0 else PI), 0))
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hide_me.append(q)

# The Reading Room's door: two pillars, a sign, and a shimmering rune curtain (blocks you until the books are back)
const CURTAIN_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform float fade = 1.0;
void fragment() {
	vec2 p = UV;
	float bands = 0.5 + 0.5 * sin(p.y * 40.0 - TIME * 2.0 + sin(p.x * 9.0 + TIME) * 2.0);
	float runes = step(0.9, fract(sin(floor(p.x * 46.0) * 12.9898 + floor(p.y * 34.0 - TIME * 0.6) * 78.233) * 43758.5453));
	float edge = smoothstep(0.0, 0.08, p.x) * smoothstep(0.0, 0.08, 1.0 - p.x) * smoothstep(0.0, 0.15, 1.0 - p.y);
	vec3 c = vec3(1.0, 0.72, 0.38) * (0.18 + bands * 0.3 + runes * 0.5);
	ALBEDO = c * edge * fade;
	ALPHA = clamp((0.3 + runes * 0.3) * edge * fade, 0.0, 1.0);
}
"""
func _build_gate() -> void:
	var stone := Models.mat("marble_tiles", 1.0, Color(0.75, 0.7, 0.66))
	for sx in [-1.0, 1.0]:
		var pp := Vector3(sx * (GATE_HW + 0.45), 0, GATE_Z)
		Models.cylinder(self, pp + Vector3(0, 2.6, 0), 0.38, 0.32, 5.2, stone, 16)
		Models.block(self, pp + Vector3(0, 5.3, 0), Vector3(0.95, 0.25, 0.95), stone)
		Util.static_cyl(self, pp, 0.45, 3.0)
		_candle(pp + Vector3(0, 5.45, 0), 1.6)
	wood_sign("sign_reading_room", "READING ROOM", Vector3(0, 5.0, GATE_Z + 0.1), 0.0, 3.4, 0.6)
	var qm := QuadMesh.new()
	qm.size = Vector2(GATE_HW * 2.0, 4.6)
	curtain_mat = ShaderMaterial.new()
	curtain_mat.shader = Shader.new()
	curtain_mat.shader.code = CURTAIN_SHADER
	curtain = Util.add_mesh(self, qm, curtain_mat, Vector3(0, 2.3, GATE_Z))
	curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	curtain_body = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(GATE_HW * 2.0 + 0.4, 3.0, 0.6)
	cs.shape = bs
	curtain_body.add_child(cs)
	curtain_body.position = Vector3(0, 1.5, GATE_Z)
	add_child(curtain_body)
	add_glow(Vector3(0, 1.4, GATE_Z + 0.5), Color(1.0, 0.75, 0.4), 4.0, func(): return 0.0 if Game.flag("libGateOpen") else 0.7)
	_light(Vector3(0, 2.0, GATE_Z + 0.8), Color(1.0, 0.72, 0.4), 1.0, 6.0)

func _open_gate_now() -> void:   # no animation (loaded save / tours)
	if curtain:
		curtain.visible = false
	if curtain_body:
		curtain_body.queue_free()
		curtain_body = null

# Everything outside the rotunda
func _build_rooms(r: RandomNumberGenerator) -> void:
	var H := WALL_H
	# ---- tall walls (north + outer sides only)
	_wall(Vector2(-8, 8.2), Vector2(-8, 24), H, Vector2(1, 0))
	_wall(Vector2(-8, 24), Vector2(-8, 30), H, Vector2.ZERO, true)
	_wall(Vector2(-8, 38), Vector2(-8, 46), H, Vector2.ZERO, true)
	_wall(Vector2(8, 8.2), Vector2(8, 24), H, Vector2(-1, 0))
	_wall(Vector2(8, 24), Vector2(8, 30), H, Vector2.ZERO, true)
	_wall(Vector2(8, 38), Vector2(8, 46), H, Vector2.ZERO, true)
	_wall(Vector2(-30, 24), Vector2(-8, 24), H, Vector2(0, 1))
	_wall(Vector2(8, 24), Vector2(30, 24), H, Vector2(0, 1))
	_wall(Vector2(-30, 24), Vector2(-30, 28.6), H, Vector2(1, 0))
	_wall(Vector2(-30, 33.4), Vector2(-30, 52), H, Vector2(1, 0))
	_wall(Vector2(30, 24), Vector2(30, 52), H, Vector2(-1, 0))
	_wall(Vector2(-18, 40), Vector2(-18, 52), H, Vector2(-1, 0))
	_wall(Vector2(18, 40), Vector2(18, 52), H, Vector2(1, 0))
	_wall(Vector2(-12, 46), Vector2(-12, 60), H, Vector2(1, 0))
	_wall(Vector2(12, 46), Vector2(12, 60), H, Vector2(-1, 0))
	# ---- low bookcases (anything with floor north of it)
	_wall(Vector2(-30, 40), Vector2(-27, 40), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(-21, 40), Vector2(-8, 40), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(8, 40), Vector2(21, 40), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(27, 40), Vector2(30, 40), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(-30, 52), Vector2(-18, 52), LIP_H)
	_wall(Vector2(18, 52), Vector2(30, 52), LIP_H)
	_wall(Vector2(-12, 46), Vector2(-5, 46), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(5, 46), Vector2(12, 46), LOW_H, Vector2.ZERO, true)
	_wall(Vector2(-12, 60), Vector2(12, 60), LIP_H)
	# freestanding stacks in the Grand Stacks (north-south, so you look down the aisles)
	for zz in [[15.0, 22.5], [39.5, 44.0]]:   # kept clear of the wing doorways (z 30–38)
		for sx in [-1.0, 1.0]:
			_wall(Vector2(sx * 5.2, zz[0]), Vector2(sx * 5.2, zz[1]), 3.2, Vector2.ZERO, true)
	# a long rug down the middle of the hall
	var runner := Models.mat("quatrefoil_jacquard_fabric", 1.0, Color(0.42, 0.36, 0.55))
	var rb := Models.block(self, Vector3(0, 0.012, 30.0), Vector3(3.2, 0.02, 34.0), runner)
	rb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# ---- chandeliers + candles everywhere
	for c in [Vector3(0, 8.5, 22.0), Vector3(0, 8.5, 36.0), Vector3(0, 7.5, 53.0), Vector3(-19.0, 7.5, 32.0), Vector3(19.0, 7.5, 32.0)]:
		Models.place(self, "Chandelier_01", c, 0.0, 1.4, false, Color(1.0, 0.85, 0.6))
		_light(c + Vector3(0, -1.5, 0), Color(1.0, 0.72, 0.42), 1.3, 13.0)
		add_glow(c - Vector3(0, 5.5, 0), Color(1.0, 0.75, 0.45), 7.0, func(): return 0.5)
	for c in [Vector3(-24.0, 5.5, 46.0), Vector3(24.0, 5.5, 46.0)]:
		Models.place(self, "lantern_chandelier_01", c, 0.0, 1.2, false, Color(1.0, 0.85, 0.6))
		_light(c + Vector3(0, -1.2, 0), Color(1.0, 0.7, 0.42), 1.1, 10.0)
		add_glow(c - Vector3(0, 4.0, 0), Color(1.0, 0.75, 0.45), 6.0, func(): return 0.5)
	for k in 22:   # floating candles over the Grand Stacks and the Atrium
		var p := Vector3(r.randf_range(-6.5, 6.5), r.randf_range(4.5, 8.0), r.randf_range(12.0, 58.0))
		floaters.append([_candle(p, 1.3), p.y, 0.5 + r.randf() * 0.6, r.randf() * TAU])
	_motes(Vector3(0, 3.5, 30.0), Vector3(7, 3, 16), Color(1.0, 0.88, 0.6), 120)
	for bp in [Vector3(-2.0, 0, 26.0), Vector3(2.5, 0, 38.0), Vector3(-1.0, 0, 52.0)]:
		_beam(bp)
	# ---- the Atrium: the pipe you fell out of, the return desk, the directory
	var pipe_m := Models.mat("rusty_metal_02", 1.0, Color(0.55, 0.5, 0.45))
	Models.cylinder(self, CHUTE + Vector3(0, 8.0, 0), 0.9, 0.9, 9.0, pipe_m, 20)
	Models.cylinder(self, CHUTE + Vector3(0, 3.4, 0), 1.1, 1.0, 0.3, pipe_m, 20)
	var drip := CPUParticles3D.new()   # it drips. Of course it drips.
	drip.amount = 6
	drip.lifetime = 1.0
	drip.mesh = Fx.quad(0.05, true)
	drip.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	drip.emission_sphere_radius = 0.5
	drip.gravity = Vector3(0, -9.0, 0)
	drip.color_ramp = Fx.ramp([[0.0, Color(0.5, 0.7, 0.4, 0.8)], [1.0, Color(0.5, 0.7, 0.4, 0.0)]])
	drip.position = CHUTE + Vector3(0, 3.2, 0)
	add_child(drip)
	Models.block(self, RETURN_DESK + Vector3(0, 0.55, 0), Vector3(2.6, 1.1, 0.9), wood_m, 0.0, true)
	for k in 4:
		_book_stack(RETURN_DESK + Vector3(-0.9 + k * 0.6, 1.1, 0), r)
	for k in 5:
		_book_stack(RETURN_DESK + Vector3(r.randf_range(-1.6, 1.6), 0, r.randf_range(0.8, 1.6)), r)
	wood_sign("sign_returns", "RETURNS", RETURN_DESK + Vector3(0, 2.0, -0.2), 0.0, 1.6, 0.4)
	wood_sign("sign_directory", "DIRECTORY", DIRECTORY + Vector3(0, 1.4, 0), 0.0, 1.8, 1.1, true)
	_candle(RETURN_DESK + Vector3(1.1, 1.1, 0.2), 1.2)
	add_glow(RETURN_DESK + Vector3(0, 1.5, 0), Color(1.0, 0.72, 0.42), 4.0, func(): return 0.5)
	# ---- the Grand Stacks: card catalog + staff picks
	Models.place(self, "vintage_cabinet_01", CATALOG, PI / 2.0, 1.4, true, Color(0.7, 0.55, 0.45))
	Models.place(self, "wooden_display_shelves_01", STAFF, -PI / 2.0, 1.2, true, Color(0.7, 0.55, 0.45))
	wood_sign("sign_staff_picks", "STAFF PICKS", STAFF + Vector3(0, 2.4, 0), -PI / 2.0, 1.6, 0.35)
	for s in [Vector3(-3.0, 0, 44.5), Vector3(3.5, 0, 13.0), Vector3(-6.6, 0, 27.0), Vector3(6.6, 0, 25.5)]:
		_book_stack(s, r)
	# ---- the Hall of Wind (west): an open window, curtains, pages blowing around
	_window()
	for k in 6:
		_book_stack(PAGES + Vector3(r.randf_range(-1.5, 1.5), 0, r.randf_range(-1.0, 1.0)), r)
	var pages := CPUParticles3D.new()
	pages.amount = 40
	pages.lifetime = 5.0
	pages.mesh = Fx.quad(0.22, false)
	pages.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pages.emission_box_extents = Vector3(1.0, 2.0, 5.0)
	pages.direction = Vector3(1, 0.1, 0)
	pages.spread = 20.0
	pages.gravity = Vector3(0, -0.15, 0)
	pages.initial_velocity_min = 2.0
	pages.initial_velocity_max = 4.0
	pages.angular_velocity_min = -200.0
	pages.angular_velocity_max = 200.0
	pages.color_ramp = Fx.ramp([[0.0, Color(0.95, 0.9, 0.78, 0)], [0.1, Color(0.95, 0.9, 0.78, 0.9)], [0.85, Color(0.95, 0.9, 0.78, 0.9)], [1.0, Color(0.95, 0.9, 0.78, 0)]])
	pages.position = WINDOW + Vector3(1.5, 2.2, 0)
	add_child(pages)
	# ---- the Restricted Section: a velvet rope across its doorway (you step over it: no collision)
	var brass := Util.mat(Color(0.8, 0.62, 0.3))
	for x in [-26.6, -21.4]:
		Models.cylinder(self, Vector3(x, 0.5, ROPE_Z + 0.6), 0.05, 0.05, 1.0, brass, 8)
		Models.cylinder(self, Vector3(x, 1.02, ROPE_Z + 0.6), 0.09, 0.09, 0.08, brass, 10)
	var rope := Models.block(self, Vector3(-24.0, 0.85, ROPE_Z + 0.6), Vector3(5.2, 0.06, 0.06), Util.mat(Color(0.6, 0.06, 0.1)))
	rope.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wood_sign("sign_restricted", "RESTRICTED", Vector3(-24.0, 1.55, ROPE_Z + 0.65), 0.0, 1.5, 0.35)
	Models.place(self, "GothicCabinet_01", Vector3(-28.4, 0, 49.5), PI / 2.0, 1.2, true, Color(0.5, 0.4, 0.4))
	Models.place(self, "marble_bust_01", Vector3(-19.4, 0, 50.5), -PI / 2.0, 1.0, true)
	# ---- the Rock Room (east): THE rock on a pedestal
	var marble := Models.mat("marble_tiles", 1.0, Color(0.8, 0.76, 0.72))
	Models.cylinder(self, ROCK + Vector3(0, 0.45, 0), 1.0, 0.9, 0.9, marble, 24)
	Util.static_cyl(self, ROCK, 1.0, 2.0)
	var rk := Models.place(self, "rock_07", ROCK + Vector3(0, 0.9, 0), 0.6, 1.0)
	var rbb := Models.aabb(rk)
	if rbb.size.x > 0.01:
		rk.scale *= 1.3 / maxf(rbb.size.x, rbb.size.z)
	wood_sign("sign_the_rock", "THE ROCK", ROCK + Vector3(0, 0.6, 1.02), 0.0, 1.2, 0.3)
	_light(ROCK + Vector3(0, 3.5, 0.5), Color(1.0, 0.85, 0.6), 1.6, 6.0)
	add_glow(ROCK + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.6), 4.0, func(): return 0.6)
	for k in 4:
		Models.cylinder(self, ROCK + Vector3(sin(k * PI / 2.0 + 0.78) * 2.0, 0.45, cos(k * PI / 2.0 + 0.78) * 2.0), 0.04, 0.04, 0.9, brass, 8)
	# ---- the Reading Corner: the table (magnifying glass, lamp), the SAVED SEAT
	Models.place(self, "round_wooden_table_01", TABLE, 0.3, 1.2, true, Color(0.6, 0.48, 0.42))
	Models.place(self, "book_encyclopedia_set_01", TABLE + Vector3(-0.2, 1.21, 0.1), 0.6, 1.4)
	Models.place(self, "magnifying_glass_01", TABLE + Vector3(0.35, 1.21, 0.3), 1.1, 1.6)
	Models.place(self, "vintage_oil_lamp", TABLE + Vector3(0.1, 1.21, -0.4), 0.0, 1.3)
	_light(TABLE + Vector3(0.1, 1.8, -0.2), Color(1.0, 0.7, 0.4), 1.0, 5.0)
	add_glow(TABLE + Vector3(0, 1.5, 0), Color(1.0, 0.72, 0.42), 4.0, func(): return 0.6)
	Models.place(self, "ArmChair_01", SEAT, -2.4, 1.4, true, Color(0.5, 0.25, 0.3))
	wood_sign("sign_saved_seat", "SAVED SEAT", SEAT + Vector3(0, 1.3, 0.3), -0.4, 1.0, 0.25)
	Models.place(self, "vintage_grandfather_clock_01", Vector3(29.0, 0, 42.0), -PI / 2.0, 1.2, true)
	Models.place(self, "wooden_bookshelf_worn", Vector3(19.0, 0, 43.5), PI / 2.0, 1.3, true, Color(0.7, 0.55, 0.45))
	Models.place(self, "gothic_coffee_table", Vector3(26.5, 0, 46.5), 0.4, 1.0, true)
	for sp in [Vector3(20.5, 0, 49.5), Vector3(28.2, 0, 44.5), Vector3(21.0, 0, 41.5)]:
		_book_stack(sp, r)
	# the radio (Ebain 11/25): a little side table + a boxy radio; plays his Deloye song from here (SONG)
	Models.place(self, "round_wooden_table_01", RADIO_POS, 0.0, 0.8, true, Color(0.6, 0.48, 0.42))
	Models.block(self, RADIO_POS + Vector3(0, 0.98, 0), Vector3(0.5, 0.3, 0.22), Util.mat(Color(0.45, 0.28, 0.18)))
	Models.block(self, RADIO_POS + Vector3(-0.08, 0.98, 0.115), Vector3(0.24, 0.2, 0.01), Util.mat(Color(0.15, 0.12, 0.1)))
	Models.cylinder(self, RADIO_POS + Vector3(0.15, 0.98, 0.12), 0.04, 0.04, 0.02, Util.mat(Color(0.85, 0.7, 0.4)), 10).rotation.x = PI / 2.0
	Models.cylinder(self, RADIO_POS + Vector3(0.15, 1.3, -0.05), 0.006, 0.006, 0.4, Util.mat(Color(0.7, 0.7, 0.72)), 6)
	radio = AudioStreamPlayer3D.new()
	radio.position = RADIO_POS + Vector3(0, 1.0, 0)
	radio.unit_size = 9.0          # fills the Reading Corner, fades out down the halls
	radio.max_distance = 45.0
	radio.bus = &"Music"   # Settings → Audio → Music
	add_child(radio)
	# ---- the readable books
	for id in BOOK_SPOTS:
		_book_spot(BOOK_SPOTS[id][0], BOOK_SPOTS[id][1])
	# ---- the 3 joint pieces, each on a glowing lectern
	for k in PIECES:
		_lectern(k, PIECES[k], r)

func _window() -> void:
	var frame := wood_m
	var w := WINDOW + Vector3(0.45, 0, 0)
	var glass := StandardMaterial3D.new()   # night outside, somehow
	glass.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glass.albedo_color = Color(0.16, 0.24, 0.42)
	var qm := QuadMesh.new()
	qm.size = Vector2(4.6, 5.0)
	Util.add_mesh(self, qm, glass, w + Vector3(-0.05, 3.2, 0), Vector3(0, PI / 2.0, 0))
	for dz in [-2.4, 2.4]:
		Models.block(self, w + Vector3(0, 3.2, dz), Vector3(0.3, 5.4, 0.25), frame)
	for dy in [0.65, 5.8]:
		Models.block(self, w + Vector3(0, dy, 0), Vector3(0.3, 0.25, 5.0), frame)
	Models.block(self, w + Vector3(0, 3.2, 0), Vector3(0.2, 5.0, 0.12), frame)
	var cloth: StandardMaterial3D = Models.mat("velour_velvet", 1.0, Color(0.5, 0.12, 0.16)).duplicate()
	cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
	for dz in [-2.0, 2.0]:   # curtains swing from a pivot at the top
		var pivot := Node3D.new()
		add_child(pivot)
		pivot.position = w + Vector3(0.35, 5.9, dz)
		var cm := QuadMesh.new()
		cm.size = Vector2(1.4, 5.2)
		Util.add_mesh(pivot, cm, cloth, Vector3(0, -2.6, 0), Vector3(0, PI / 2.0, 0))
		curtains.append([pivot, dz])
	_light(w + Vector3(2.0, 3.5, 0), Color(0.55, 0.7, 1.0), 1.4, 9.0)
	add_glow(w + Vector3(1.5, 2.0, 0), Color(0.6, 0.75, 1.0), 6.0, func(): return 0.6)

# A lectern with one of the overdue volumes on it (glowing + sparkles until you take it)
func _lectern(key: String, p: Vector3, r: RandomNumberGenerator) -> void:
	Models.block(self, p + Vector3(0, 0.04, 0), Vector3(0.7, 0.08, 0.55), wood_m)
	Models.block(self, p + Vector3(0, 0.55, 0), Vector3(0.18, 1.0, 0.18), wood_m)
	var top := Models.block(self, p + Vector3(0, 1.1, 0), Vector3(0.8, 0.06, 0.6), wood_m)
	top.rotation.x = -0.35
	Util.static_box(self, p + Vector3(0, 0.6, 0), Vector3(0.7, 1.2, 0.55))
	var b := _piece_node(key)
	b.position = p + Vector3(0, 1.4, 0.02)
	var sp := _sparkle(p + Vector3(0, 1.4, 0))
	var l := _light(p + Vector3(0, 1.8, 0.4), Color(1.0, 0.85, 0.5), 1.0, 4.0)
	lect[key] = [b, sp, l]
	lect_hum[key] = amb_loop("amb_aura", -11.0, p + Vector3(0, 1.4, 0), 1.4, 10.0)
	add_glow(p + Vector3(0, 1.3, 0), Color(1.0, 0.85, 0.5), 3.0, func(): return 0.0 if Game.flag("libPiece_" + key) else 0.7)

# A readable book: an open book on a small stand, or a glowing spine on a shelf (both pulse a little so you notice them)
func _book_spot(p: Vector3, kind: String) -> void:
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.95, 0.9, 0.78)
	paper.emission_enabled = true
	paper.emission = Color(1.0, 0.85, 0.55)
	paper.emission_energy_multiplier = 0.35
	if kind == "stand":
		Models.block(self, p + Vector3(0, 0.03, 0), Vector3(0.5, 0.06, 0.4), wood_m)
		Models.block(self, p + Vector3(0, 0.45, 0), Vector3(0.12, 0.84, 0.12), wood_m)
		var top := Models.block(self, p + Vector3(0, 0.9, 0), Vector3(0.62, 0.05, 0.44), wood_m)
		top.rotation.x = -0.4
		Util.static_box(self, p + Vector3(0, 0.5, 0), Vector3(0.5, 1.0, 0.4))
		for sx in [-1.0, 1.0]:   # the two open pages
			var pg := Models.block(self, p + Vector3(sx * 0.13, 0.95, 0.02), Vector3(0.24, 0.015, 0.32), paper)
			pg.rotation = Vector3(-0.4, 0, sx * 0.08)
		add_glow(p + Vector3(0, 1.0, 0), Color(1.0, 0.85, 0.55), 2.0, func(): return 0.55)
	else:
		var b := Models.block(self, p + Vector3(0, 1.5, 0), Vector3(0.12, 0.36, 0.26), paper)
		b.rotation.y = atan2(p.x, p.z)
		add_glow(p + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.55), 1.6, func(): return 0.6)
	_sparkle(p + Vector3(0, 1.2 if kind == "stand" else 1.6, 0)).amount = 4

# The joint pieces, hovering over their lecterns (simple shapes, shown ~2x size so you can tell what they are)
func _piece_node(key: String) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	match key:
		"plant":
			Models.cylinder(n, Vector3(0, 0.08, 0), 0.1, 0.08, 0.16, Util.mat(Color(0.7, 0.36, 0.22)), 12)
			var leaf := Util.mat(Color(0.25, 0.62, 0.22))
			leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
			for k in 7:   # a fan of pointy leaves
				var qm := QuadMesh.new()
				qm.size = Vector2(0.06, 0.3)
				var q := Util.add_mesh(n, qm, leaf, Vector3(0, 0.3, 0), Vector3(0, k * 0.9, -0.9 + k * 0.3))
				q.position += Vector3(sin(k * 0.9), 0, cos(k * 0.9)) * 0.04
		"papers":
			Models.block(n, Vector3(0, 0.05, 0), Vector3(0.16, 0.025, 0.09), Util.mat(Color(0.85, 0.72, 0.5)))
			var l := Label3D.new()
			l.text = "RAW"
			l.font_size = 48
			l.pixel_size = 0.002
			l.modulate = Color(0.75, 0.25, 0.1)
			l.position = Vector3(0, 0.064, 0)
			l.rotation.x = -PI / 2.0
			n.add_child(l)
		"lighter":
			Models.block(n, Vector3(0, 0.07, 0), Vector3(0.04, 0.12, 0.022), Util.mat(Color(0.85, 0.12, 0.12)))
			Models.block(n, Vector3(0, 0.145, 0), Vector3(0.04, 0.03, 0.022), Util.mat(Color(0.75, 0.75, 0.8)))
	n.scale = Vector3.ONE * 2.0
	return n

func _sparkle(p: Vector3) -> CPUParticles3D:
	var sp := CPUParticles3D.new()
	sp.amount = 8
	sp.lifetime = 1.2
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = 0.35
	sp.gravity = Vector3(0, 0.3, 0)
	sp.initial_velocity_min = 0.05
	sp.initial_velocity_max = 0.2
	sp.mesh = Fx.quad(0.07, true)
	sp.color_ramp = Fx.ramp([[0.0, Color(1, 0.9, 0.4, 0)], [0.3, Color(1, 0.9, 0.4, 1)], [1.0, Color(1, 0.9, 0.4, 0)]])
	add_child(sp)
	sp.global_position = p
	return sp

func _apply_piece_state() -> void:
	for k in lect:
		var gone := Game.flag("libPiece_" + k)
		for n in lect[k]:
			n.visible = not gone
		if gone and lect_hum.get(k) and is_instance_valid(lect_hum[k]):
			lect_hum[k].queue_free()
	if Game.flag("libGateOpen"):
		_open_gate_now()

func pieces_found() -> int:
	var n := 0
	for k in PIECES:
		if Game.flag("libPiece_" + k):
			n += 1
	return n

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
	hum = play_sound("library_hum", -60.0, 1.0, true)
	if ResourceLoader.exists(SONG) and radio:   # Ebain's song plays from the Reading Corner radio (on when you arrive)
		radio.stream = load(SONG)
		if radio.stream is AudioStreamOggVorbis:
			radio.stream.loop = true
		radio.play()

# ================================================================ per frame
const YAW_MAX := 0.6   # how far the camera may turn from north (radians, ~35 degrees)
var _tall_walls: Array = []   # {a, b: Vector2 ends, nodes}: hidden while they cut the camera → leader line
func _hide_walls() -> void:
	if cam == null or leader == null:
		return
	var c := Vector2(cam.global_position.x, cam.global_position.z)
	var l := Vector2(leader.global_position.x, leader.global_position.z)
	for w in _tall_walls:
		var cut = Geometry2D.segment_intersects_segment(c, l, w["a"], w["b"])
		for n in w["nodes"]:
			n.visible = cut == null
func _level_process(delta: float) -> void:
	target_yaw = clampf(target_yaw, -YAW_MAX, YAW_MAX)
	_hide_walls()
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
	for c in curtains:   # the Hall of Wind's curtains blow inward
		c[0].rotation.z = -0.35 - sin(t * 1.7 + c[1]) * 0.18
	for k in lect:   # the overdue volumes bob a little
		var bn: Node3D = lect[k][0]
		bn.position.y = PIECES[k].y + 1.4 + sin(t * 2.0 + PIECES[k].x) * 0.04
		bn.rotation.y += delta * 0.8
	# walking into the Reading Room the first time: Deloye's "You could pass that shit?"
	if stage == "walk" and not busy and Game.flag("libGateOpen") and not Game.flag("deloyeMet") and leader.global_position.z < GATE_Z - 1.5:
		_pass_scene()
	if radio and radio.playing and leader.global_position.distance_to(RADIO_POS) < 10.0 and not _radio_heard:
		_radio_heard = true
		if LibraryUI.mark_heard(SONG):
			show_toast("New song in the Library: Deloye Lore", 2.5)
	_mattias_process()
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
	Game.set_flag("libEntered")
	_apply_piece_state()
	fade.color = Color(1, 1, 1, 1)   # white, from the flush
	for i in party.size():   # everyone drops out of the pipe
		party[i].global_position = CHUTE + Vector3(-0.4 + i * 0.4, 6.0 + i * 1.2, 0)
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
	if Game.flag("deloyeMet"):   # coming back later this run: just the library (Deloye's room is open)
		_walk()
		return
	await run_dialogue(_steps(DS.ARRIVE))
	_walk()
	_walk_banter()

func _walk() -> void:
	stage = "walk"
	busy = false
	_walk_objective()

func _walk_objective() -> void:
	if Game.flag("deloyeMet"):
		objective("Look around, or take the EXIT.")
	elif Game.flag("libGateOpen"):
		objective("Pull up to Deloye's room.", CENTER)
	elif guide_target != null and mattias and mattias.visible:
		objective("Follow Metocin Mattias.", guide_target)
	else:
		objective("Find the joint pieces (%d/%d)." % [pieces_found(), PIECES.size()])   # no star: explore

# ---------------------------------------------------------------- Metocin Mattias
func _ensure_mattias() -> void:
	if mattias:
		return
	mattias = spawn_npc("mattias", "Metocin Mattias", "mattias", 1.95, START + Vector3(2.2, 0, -1.6))
	mattias.visible = false
	mattias.set_meta("tint", Color(0.75, 0.85, 1.15))
	mattias_light = OmniLight3D.new()
	mattias_light.light_color = Color(0.4, 0.6, 1.0)
	mattias_light.light_energy = 0.0
	mattias_light.omni_range = 4.0
	mattias.add_child(mattias_light)
	mattias_light.position = Vector3(0, 1.6, 0.6)

func _mattias_show(at: Vector3) -> void:
	_ensure_mattias()
	mattias.global_position = at
	mattias.visible = true
	mattias.set_meta("follow", true)
	mattias.set_meta("follow_i", 0)
	var f := Fx.poof(Color(0.5, 0.7, 1.0))
	add_child(f)
	f.global_position = at + Vector3(0, 1.0, 0)
	f.emitting = true
	play_sound("sfx_pop", -3.0)
	create_tween().tween_property(mattias_light, "light_energy", 2.0, 0.5)

# He walks ahead to `p` and waits there (follow is paused); guide_target = null → back to following you.
# He walks the hallway waypoints (ROUTE) instead of a straight line, so he doesn't get stuck on a wall between two wings
# (Ebain 11/26: asking him for help got him stuck on the way to the lighter).
var _guide_path: Array = []
var _guide_wait := 0.0
var _coming_back := false   # walking back to you because you fell behind
var _back_to := Vector3.ZERO
func _guide(p) -> void:
	guide_target = p
	_guide_path = []
	_coming_back = false
	if mattias == null:
		return
	if p == null:
		mattias.remove_meta("goal")
		mattias.set_meta("follow", true)
	else:
		mattias.set_meta("follow", false)
		_guide_path = _nav_path(mattias.global_position, p + Vector3(1.3, 0, 1.4))
		mattias.set_meta("goal", _guide_path.pop_front())
		mattias.set_meta("goal_speed", 1.0)
	_walk_objective()

# Shortest way along the ROUTE waypoints (each one connects to the next; the same spot listed twice is one node), then `b`.
func _nav_path(a: Vector3, b: Vector3) -> Array:
	var nodes: Array = []
	var idx: Array = []   # ROUTE index → node
	for r in ROUTE:
		var q: Vector3 = r[1]
		var found := -1
		for n in nodes.size():
			if nodes[n].distance_to(q) < 1.0:
				found = n
		if found < 0:
			nodes.append(q)
			found = nodes.size() - 1
		idx.append(found)
	var adj := {}
	for i in idx.size() - 1:
		adj[idx[i]] = adj.get(idx[i], []) + [idx[i + 1]]
		adj[idx[i + 1]] = adj.get(idx[i + 1], []) + [idx[i]]
	var near := func(p: Vector3) -> int:
		var best := 0
		for n in nodes.size():
			if nodes[n].distance_to(p) < nodes[best].distance_to(p):
				best = n
		return best
	var s: int = near.call(a)
	var t: int = near.call(b)
	var prev := { s: -1 }
	var queue := [s]
	while not queue.is_empty():
		var c: int = queue.pop_front()
		if c == t:
			break
		for nb in adj.get(c, []):
			if not prev.has(nb):
				prev[nb] = c
				queue.append(nb)
	var path: Array = []
	var c := t
	while c != -1 and prev.has(c):
		path.push_front(nodes[c])
		c = prev[c]
	# skip waypoints that only lead backwards (already past the first one / the last one is beside the target)
	if path.size() >= 2 and a.distance_to(path[1]) < path[0].distance_to(path[1]):
		path.pop_front()
	if path.size() >= 2 and b.distance_to(path[-2]) < path[-1].distance_to(path[-2]):
		path.pop_back()
	if path.size() == 1 and a.distance_to(b) < a.distance_to(path[0]) + 0.5 and a.distance_to(b) < 12.0:
		path.clear()   # target is right here in the same room
	path.append(b)
	return path

func _next_guide_spot():   # the next thing to show you: a missing piece, then Deloye's room
	for k in PIECES:
		if not Game.flag("libPiece_" + k):
			return PIECES[k]
	return ROT_IN if Game.flag("libGateOpen") else Vector3(0, 0, GATE_Z + 2.0)

func _mattias_process() -> void:
	if mattias == null or not mattias.visible:
		return
	if mattias.has_meta("goal"):   # don't run off too far ahead: wait for the leader
		var g: Vector3 = mattias.get_meta("goal")
		if not _guide_path.is_empty() and Vector2(mattias.global_position.x - g.x, mattias.global_position.z - g.z).length() < 0.9:
			mattias.set_meta("goal", _guide_path.pop_front())   # next waypoint
		# You fell behind: instead of standing still (looked stuck, Asar 11/25) he walks back to you along the
		# hallway waypoints, then leads on again from there.
		var ahead := mattias.global_position.distance_to(leader.global_position)
		mattias.set_meta("goal_speed", 1.0)
		_guide_wait += get_process_delta_time()
		if guide_target != null and not _coming_back and ahead > 10.0:
			_coming_back = true
			_back_to = leader.global_position
			_guide_path = _nav_path(mattias.global_position, _back_to)
			mattias.set_meta("goal", _guide_path.pop_front())
			if _guide_wait > 12.0 and not busy and not dialogue.active:   # so you know he's coming for you
				_guide_wait = 0.0
				_bubble("mattias", "Over here, my beloved three.")   # DRAFT
		elif _coming_back and ahead < 4.0:
			_coming_back = false
			_guide_path = _nav_path(mattias.global_position, guide_target + Vector3(1.3, 0, 1.4))
			mattias.set_meta("goal", _guide_path.pop_front())
		elif _coming_back and leader.global_position.distance_to(_back_to) > 2.5:   # you moved: re-aim at you
			_back_to = leader.global_position
			_guide_path = _nav_path(mattias.global_position, _back_to)
			mattias.set_meta("goal", _guide_path.pop_front())

# Walking banter (Ebain: "while walking these voicelines commence"): speech bubbles, the game keeps going
func _walk_banter() -> void:
	if _banter_running or Game.flag("libBanter"):
		return
	_banter_running = true
	await wait(1.5)
	for st in _steps(DS.WALK_BANTER):
		if stage != "walk":
			break
		while busy or dialogue.active:   # a conversation started: wait it out
			await wait(0.3)
		await _bubble(st["who"], st["line"])
	Game.set_flag("libBanter")
	_banter_running = false
	if not Game.flag("libPiece_plant") and stage == "walk":   # "Look over here. Follow me." → the first piece
		_guide(PIECES["plant"])

func _bubble(who: String, line: String) -> void:
	var u: Unit = mattias if who == "mattias" else null
	for p in party:
		if p.id == who:
			u = p
	var secs := clampf(line.length() * 0.06, 2.4, 8.0)
	if u:
		var col: Color = Dialogue.CHARS.get(who, {}).get("color", Color("#f3e3b0"))
		var l := char_label(u, line, secs, u.height_m + 0.5, col.lightened(0.25))
		l.width = 520
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.font_size = 34
	dialogue._speak(who, line, false, true)   # the recording if there is one (or the robot voice)
	await wait(secs + 0.35)

# ---------------------------------------------------------------- Deloye's room
func _pass_scene() -> void:
	busy = true
	freeze_all(true)
	var tw := create_tween()
	tw.tween_method(func(v: float): focus_override = leader.global_position.lerp(CENTER + Vector3(0, 0, 3.0), v), 0.0, 1.0, 1.4).set_trans(Tween.TRANS_SINE)
	await tw.finished
	for i in party.size():   # gather in front of him
		party[i].global_position = CENTER + Vector3(-1.4 + i * 1.4, 0, 3.6)
	if mattias and mattias.visible:
		_guide(null)
		mattias.global_position = CENTER + Vector3(3.0, 0, 3.0)
	await run_dialogue(_steps(DS.PASS))

func _level_interactables() -> Array:
	var list: Array = []
	if stage != "walk":
		return list
	var skorn_here := "skorn" in party_ids
	# the rotunda
	if Game.flag("libGateOpen"):
		if Game.flag("deloyeMet"):
			list.append({ "id": "deloye", "label": "Deloye", "verb": "Talk to", "pos": CENTER + Vector3(0, 0, 2.5), "h": 3.6, "r": 2.2, "steps": _steps(DS.AGAIN[randi() % DS.AGAIN.size()]) })
		list.append({ "id": "book", "label": "the floating book", "verb": "Look up at", "pos": BOOK_SPOT, "h": 2.4, "r": 1.4, "steps": DS.BOOK })
		var sp := Vector3(sin(SHELF_A), 0, -cos(SHELF_A)) * (R - 1.4)
		list.append({ "id": "shelf", "label": "the shelves", "verb": "Read", "pos": sp, "h": 2.0, "r": 1.6, "steps": _steps(DS.SHELF) if skorn_here else [{ "who": "xylo", "line": "Volume 4,019: The Wind. A classic." }] }) # DRAFT
		var dp := Vector3(sin(EXIT_A), 0, -cos(EXIT_A)) * (R - 2.0)
		list.append({ "id": "exit", "label": "the EXIT", "verb": "Go through", "pos": dp, "h": 3.4, "r": 1.8, "steps": _steps(DS.EXIT_DOOR), "major": true })
	else:
		list.append({ "id": "gate", "label": "the Reading Room door", "verb": "Read", "pos": Vector3(-1.6, 0, GATE_Z + 1.4), "h": 2.6, "r": 1.6, "steps": _steps(DS.GATE_SIGN) })
	# Metocin Mattias
	if mattias and mattias.visible and not Game.flag("deloyeMet") and Game.flag("libGuided1"):
		var mst: Array = DS.MATTIAS_GUIDING if Game.flag("libGuideAll") else DS.MATTIAS_HELP
		list.append({ "id": "mattias", "label": "Metocin Mattias", "verb": "Talk to", "pos": mattias.global_position, "h": 2.4, "r": 1.6, "steps": mst })
	# the joint pieces
	for k in PIECES:
		if not Game.flag("libPiece_" + k):
			var pst: Array = [{ "do": "take:" + k }]   # (one conversation: no dialogue started inside an action)
			if pieces_found() == 0 and mattias and mattias.visible:
				pst += [{ "do": "guided1" }] + _steps(DS.PIECE_FIRST)
			if pieces_found() == PIECES.size() - 1:
				pst += _steps(DS.DELOYE_CALL)   # "You had let's burn it? Pull up my trio." → the curtain opens
			pst.append({ "do": "after_piece" })
			list.append({ "id": "piece_" + k, "label": PIECE_NAMES[k], "verb": "Take", "pos": PIECES[k] + Vector3(0, 0, 1.0), "h": 1.7, "r": 1.4, "steps": pst })
	# the readable books (Deloye's room's one only once you're in there)
	for id in BOOK_SPOTS:
		var bp: Vector3 = BOOK_SPOTS[id][0]
		if bp.z < GATE_Z and not Game.flag("libGateOpen"):
			continue
		var at := bp + (Vector3(0, 0, 0.9) if BOOK_SPOTS[id][1] == "stand" else -bp.normalized() * 0.9 if bp.z < GATE_Z else Vector3(0.9, 0, 0))
		list.append({ "id": "read_" + id, "label": LB.BOOKS[id]["title"], "verb": "Read", "pos": at, "h": 1.6, "r": 1.3, "steps": [{ "do": "read:" + id }] })
	# things to look at
	list.append({ "id": "radio", "label": "the radio", "verb": "Turn off" if radio and radio.playing else "Turn on", "pos": RADIO_POS + Vector3(0, 0, 1.2), "h": 1.4, "r": 1.4, "steps": DS.RADIO })
	list.append({ "id": "pipe", "label": "the pipe", "verb": "Look at", "pos": CHUTE + Vector3(0.6, 0, 1.4), "h": 2.4, "r": 1.6, "steps": _steps(DS.CHUTE) })
	list.append({ "id": "directory", "label": "the directory", "verb": "Read", "pos": DIRECTORY + Vector3(0, 0, 1.0), "h": 2.0, "r": 1.5, "steps": _steps(DS.DIRECTORY) })
	list.append({ "id": "desk", "label": "the return desk", "verb": "Look at", "pos": RETURN_DESK + Vector3(0, 0, 1.8), "h": 1.8, "r": 1.6, "steps": _steps(DS.RETURN_DESK) if skorn_here else [{ "who": "lykor", "line": "\"Please do not return Deloye Lore.\" Got it." }] }) # DRAFT
	list.append({ "id": "catalog", "label": "the card catalog", "verb": "Look at", "pos": CATALOG + Vector3(1.4, 0, 0.6), "h": 1.8, "r": 1.5, "steps": _steps(DS.CATALOG) })
	list.append({ "id": "staff", "label": "the staff picks", "verb": "Look at", "pos": STAFF + Vector3(-1.4, 0, 0.6), "h": 1.8, "r": 1.5, "steps": _steps(DS.STAFF_PICKS) })
	list.append({ "id": "window", "label": "the open window", "verb": "Look at", "pos": WINDOW + Vector3(2.2, 0, 0), "h": 2.6, "r": 1.8, "steps": _steps(DS.WINDOW) })
	list.append({ "id": "pages", "label": "the loose pages", "verb": "Look at", "pos": PAGES + Vector3(0, 0, 1.6), "h": 1.4, "r": 1.6, "steps": _steps(DS.PAGES) })
	list.append({ "id": "rope", "label": "the velvet rope", "verb": "Read", "pos": Vector3(-24.0, 0, ROPE_Z + 1.6), "h": 1.6, "r": 1.4, "steps": _steps(DS.ROPE) })
	list.append({ "id": "rock", "label": "THE ROCK", "verb": "Look at", "pos": ROCK + Vector3(0, 0, 2.0), "h": 2.0, "r": 1.6, "steps": _steps(DS.ROCK) if skorn_here else [{ "who": "xylo", "mood": "smug", "line": "THE rock. From Chapter 10,000." }] }) # DRAFT
	list.append({ "id": "table", "label": "the reading table", "verb": "Look at", "pos": TABLE + Vector3(0, 0, 1.6), "h": 1.6, "r": 1.6, "steps": DS.TABLE })
	list.append({ "id": "seat", "label": "the SAVED SEAT", "verb": "Look at", "pos": SEAT + Vector3(-1.2, 0, 0.8), "h": 1.6, "r": 1.5, "steps": _steps(DS.SAVED_SEAT) })
	return list

func _on_action(n: String) -> void:
	if n.begins_with("take:"):
		await _take_piece(n.get_slice(":", 1))
		return
	if n.begins_with("read:"):
		await BookUI.read(self, n.get_slice(":", 1))
		return
	match n:
		"mattias_appears":
			_mattias_show(leader.global_position + Vector3(2.2, 0, -1.6))
			Game.set_flag("libMattias")
			char_label(mattias, "Metocin Mattias (Teleported In)", 3.5, 2.5, Color("#9cc4ff"))   # DRAFT
			await wait(0.8)
		"guided1":
			Game.set_flag("libGuided1")
		"after_piece":
			_guide(_next_guide_spot() if Game.flag("libGuideAll") else null)
		"guide_all":
			Game.set_flag("libGuideAll")
			_guide(_next_guide_spot())
		"deloye_far":
			char_label_at(CENTER + Vector3(0, 6.0, 0), "(Deloye, from the Reading Room)", 3.5, Color("#d9d2ff"))   # DRAFT
			await wait(0.5)
		"deloye_faces":
			spin_speed = 0.0
			await wait(0.6)
		"give_joint":
			play_sound("sfx_grab", -6.0)
			await wait(0.4)
			play_sound_at("sfx_lighter", deloye.global_position + Vector3(0, 1.6, 0), -3.0)   # Deloye sparks it up (sfx pack)
			await wait(0.6)
		"smoke":
			await _smoke()
		"faded":
			Game.flags["fadedFights"] = 3
			play_sound("sfx_reward", -4.0)
			show_toast("Everyone is FADED: heal a little every turn and take 10% less damage, next 3 fights", 3.5)
			await wait(0.6)
		"keep_joint":
			Game.set_flag("deloyeBad")
			Game.add_item("joint", 1, "xylo" if "xylo" in party_ids else leader.id)
			play_sound("sfx_grab", -6.0)
			show_toast("You kept the Joint (use it in a fight). Deloye disapproves of Xylo now.", 3.5)
			await wait(0.6)
		"teleport_out":
			Game.set_flag("deloyeMet")
			await _teleport_out()
		"radio":
			await _radio_toggle()
		"gift":
			await _gift()
		"book_swell":
			_book_swelling = true
			get_tree().create_timer(8.0).timeout.connect(func(): _book_swelling = false)
			await wait(0.4)
		"gate_open":
			await _gate_open()
		"leave", "leave_pipe":
			stage = "end"
			busy = true
			play_sound("sfx_door" if n == "leave" else "flush", -4.0)
			await fade_out(0.7)
			Game.travel("res://village.tscn", "library", leader.id)

func char_label_at(p: Vector3, text: String, secs := 3.0, color := Color("#f3e3b0")) -> void:
	var n := Node3D.new()
	n.position = p
	add_child(n)
	var l := char_label(n, text, secs, 0.0, color)
	l.pixel_size = 0.016
	get_tree().create_timer(secs + 0.6).timeout.connect(n.queue_free)

func _take_piece(k: String) -> void:
	if Game.flag("libPiece_" + k):
		return
	Game.set_flag("libPiece_" + k)
	if lect.has(k):
		var b: Node3D = lect[k][0]
		var p := Fx.poof(Color(1.0, 0.85, 0.5))
		add_child(p)
		p.global_position = b.global_position
		p.emitting = true
		for nd in lect[k]:
			nd.visible = false
	if lect_hum.get(k) and is_instance_valid(lect_hum[k]):
		lect_hum[k].queue_free()
	play_sound("sfx_reward", -6.0)
	show_toast("Got %s (%d/%d)" % [PIECE_NAMES[k], pieces_found(), PIECES.size()], 2.2)
	await wait(0.5)

func _gate_open() -> void:
	Game.set_flag("libGateOpen")
	shake = 0.4
	play_sound("sfx_magic", -4.0, 0.7)
	if curtain_mat:
		var tw := create_tween()
		tw.tween_method(func(v: float): curtain_mat.set_shader_parameter("fade", v), 1.0, 0.0, 1.4)
		await tw.finished
	_open_gate_now()
	_walk_objective()

func _radio_toggle() -> void:
	if radio == null or radio.stream == null:
		await dialogue._run_steps(_steps(DS.RADIO_STATIC), self)
		return
	play_sound("sfx_grab", -10.0, 1.4)
	if radio.playing:
		radio.stop()
		show_toast("Radio off", 1.2)
	else:
		radio.play()
		show_toast("Radio on: Deloye Lore", 1.6)
	await wait(0.3)

# B: puff puff pass. Placeholder scene (Ebain may make a real cutscene): smoke rises, the screen goes hazy, back.
func _smoke() -> void:
	var sm := CPUParticles3D.new()
	sm.amount = 70
	sm.lifetime = 3.5
	sm.mesh = Fx.quad(0.6, false)
	sm.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sm.emission_box_extents = Vector3(2.4, 0.4, 0.8)
	sm.direction = Vector3(0, 1, 0)
	sm.spread = 25.0
	sm.gravity = Vector3(0, 0.25, 0)
	sm.initial_velocity_min = 0.3
	sm.initial_velocity_max = 0.8
	sm.scale_amount_min = 0.8
	sm.scale_amount_max = 2.4
	sm.color_ramp = Fx.ramp([[0.0, Color(0.85, 0.85, 0.85, 0)], [0.2, Color(0.85, 0.85, 0.85, 0.35)], [1.0, Color(0.85, 0.85, 0.85, 0)]])
	add_child(sm)
	sm.global_position = CENTER + Vector3(0, 1.6, 3.2)
	play_sound("sfx_lighter", -3.0)   # (Ebain's sfx pack) flick + the first pull
	await wait(1.2)
	for u in party:
		char_label(u, "*puff*", 1.6, u.height_m + 0.3, Color("#cfe8c8"))   # DRAFT
		await wait(0.55)
	char_label(deloye, "*puff*", 1.6, DELOYE_H + 0.3, Color("#d9d2ff"))   # DRAFT
	if not party.is_empty():   # somebody can't hang
		play_sound_at("sfx_cough", party[party.size() - 1].global_position + Vector3(0, 1.4, 0), -5.0)
	var haze := fade.color
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0.75, 0.9, 0.7, 0.35), 1.2)
	await wait(2.4)
	var tw2 := create_tween()
	tw2.tween_property(fade, "color", Color(haze.r, haze.g, haze.b, 0.0), 1.2)
	await wait(1.0)
	sm.emitting = false
	get_tree().create_timer(4.0).timeout.connect(sm.queue_free)

# "Alright I'm gonna catch y'all later": everyone poofs out → the goblin village, by the outhouse
func _teleport_out() -> void:
	stage = "end"
	busy = true
	for u in party + ([mattias] if mattias and mattias.visible else []):
		var f := Fx.poof(Color(0.8, 0.7, 1.0))
		add_child(f)
		f.global_position = u.global_position + Vector3(0, 1.0, 0)
		f.emitting = true
		u.visible = false
		play_sound("sfx_pop", -4.0, 1.0 + randf() * 0.3)
		await wait(0.18)
	await wait(0.6)
	await fade_out(0.6)
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
	var boot := play_sound("amb_engine", -10.0, 0.8)   # (Ebain's sfx pack) the Neuralink booting up
	if boot:
		var btw := create_tween()
		btw.tween_property(boot, "pitch_scale", 1.6, 1.6)
		btw.parallel().tween_property(boot, "volume_db", -40.0, 1.8).set_delay(0.6)
		btw.tween_callback(boot.queue_free)
	play_sound("sfx_reward", -4.0)
	show_toast("Xylo got: Deloye Lore Neuralink (equip it in Tab)", 3.0)
	await wait(0.8)

# ---------------------------------------------------------------- saves: free roam resumes where you stood
func can_resume() -> bool:
	return stage == "walk" and not busy

func can_resume_saved() -> bool:
	return Game.flag("libEntered")

func _resume(r: Dictionary) -> void:
	_apply_piece_state()
	stage = "walk"
	await super._resume(r)
	if Game.flag("libMattias") and not Game.flag("deloyeMet"):   # Mattias is still with you
		_mattias_show(leader.global_position + Vector3(1.6, 0, 1.2))
		if Game.flag("libGuideAll"):
			_guide(_next_guide_spot())
	_walk()
	if Game.flag("libMattias") and not Game.flag("libBanter"):
		_walk_banter()

func arrival(_from: String) -> Array:
	return [START, Vector3(0, 0, -1)]

func map_buildings() -> Array:
	return [
		{ "pos": Vector3(0, 0, 53), "name": "Atrium" },
		{ "pos": Vector3(0, 0, 28), "name": "Grand Stacks" },
		{ "pos": Vector3(-19, 0, 32), "name": "Hall of Wind" },
		{ "pos": Vector3(-24, 0, 46), "name": "Restricted" },
		{ "pos": Vector3(19, 0, 32), "name": "Rock Room" },
		{ "pos": Vector3(24, 0, 46), "name": "Reading Corner" },
		{ "pos": Vector3(0, 0, -2), "name": "Reading Room" },
	]

# ---------------------------------------------------------------- automated test
# Lands in the Atrium with Mattias, lets the walking banter play (he starts guiding to the plant), walks the whole route
# (checks every doorway is walkable), takes the plant (PIECE_FIRST), asks Mattias "You could help me?" (he guides),
# takes the other two (Deloye calls, the curtain opens), walks into the Reading Room and answers Deloye with
# LIB_CHOICE = 0 (A, default) / 1 (B, puff puff pass) / 2 (C, "Bad.") → teleported back to the village.
const ROUTE := [   # waypoints through every room, in the order a player would go
	["atrium", Vector3(0, 0, 50)], ["stacks", Vector3(0, 0, 34)], ["wind", Vector3(-12, 0, 34)], ["wind", Vector3(-22, 0, 33)],
	["restricted", Vector3(-24, 0, 38)], ["restricted", Vector3(-21.5, 0, 48)], ["wind", Vector3(-23, 0, 36)],
	["stacks", Vector3(-4, 0, 34)], ["rock", Vector3(12, 0, 34)], ["rock", Vector3(22, 0, 33)], ["corner", Vector3(24, 0, 38)],
	["corner", Vector3(21, 0, 48)], ["rock", Vector3(23, 0, 36)], ["stacks", Vector3(4, 0, 34)], ["stacks", Vector3(0, 0, 14)],
]
var tour_pick := 0
# LIB_GUIDE=1: ask Mattias to guide to each piece in turn while the leader walks after him; reports whether he arrives
func _guide_test() -> void:
	await _begin_quick()
	Game.set_flag("libBanter")
	Game.set_flag("libGuided1")
	Game.set_flag("libGuideAll")
	var follow_leader := OS.get_environment("LIB_GUIDE") != "far"   # "far": the player stays put at the start
	var all_ok := true
	for k in PIECES:
		_guide(PIECES[k])
		var goal: Vector3 = PIECES[k] + Vector3(1.3, 0, 1.4)   # the final stop (the meta goal is the next waypoint)
		var t := 0.0
		var arrived := false
		while t < 90.0:
			await wait(0.25)
			t += 0.25
			if follow_leader and leader.global_position.distance_to(mattias.global_position) > 4.0:
				leader.set_meta("goal", mattias.global_position)
				leader.set_meta("goal_speed", 1.6)
			else:
				leader.remove_meta("goal")
			if Vector2(mattias.global_position.x - goal.x, mattias.global_position.z - goal.z).length() < 0.7:
				arrived = true
				break
		print("LIB GUIDE ", k, " arrived=", arrived, " in ", t, "s, mattias at ", mattias.global_position, " goal ", goal, " leader at ", leader.global_position)
		all_ok = all_ok and arrived
		if not arrived and not follow_leader:
			break
		leader.remove_meta("goal")
		Game.set_flag("libPiece_" + k)   # (counts as taken)
	print("LIB GUIDE ", "ALL OK" if all_ok else "STUCK")
	get_tree().quit()

func _shot_tour() -> void:
	tour_pick = int(OS.get_environment("LIB_CHOICE")) if OS.get_environment("LIB_CHOICE") != "" else 0
	if OS.get_environment("LIB_GUIDE") != "":
		await _guide_test()
		return
	await _begin_quick()
	await shot("dl_01_atrium")
	for k in 80:   # the walking banter (bubbles), then "Follow me." → he heads for the plant
		if Game.flag("libBanter"):
			break
		await wait(0.5)
	await shot("dl_01b_mattias_guides")
	print("LIB BANTER done=", Game.flag("libBanter"), " guiding_to_plant=", guide_target == PIECES["plant"], " mattias_moving=", mattias.has_meta("goal"))
	var ok := true
	for i in ROUTE.size():   # walk it for real (collision on), like a player holding the stick
		var wp: Vector3 = ROUTE[i][1]
		await walk_to(leader, wp, 1.6, 9.0)
		var d := Vector2(leader.global_position.x - wp.x, leader.global_position.z - wp.z).length()
		if d > 1.2:
			ok = false
			print("LIB ROUTE stuck before ", ROUTE[i][0], " ", wp, " at ", leader.global_position)
			place_party(wp, Vector3(0, 0, -1))
		if i in [3, 5, 11]:
			await shot("dl_route_%02d_%s" % [i, ROUTE[i][0]])
	print("LIB ROUTE ", "ALL OK" if ok else "BLOCKED")
	if OS.get_environment("LIB_BOOKS") != "":   # read every book (the one in Deloye's room needs the gate open)
		var was := Game.flag("libGateOpen")
		Game.flags["libGateOpen"] = true
		for id in BOOK_SPOTS:
			await _tour_use("read_" + id)
		Game.flags["libGateOpen"] = was
		print("LIB BOOKS read all")
	# the gate is shut: the curtain must stop you
	place_party(Vector3(0, 0, GATE_Z + 2.0), Vector3(0, 0, -1))
	await walk_to(leader, Vector3(0, 0, 4.0), 1.6, 3.0)
	print("LIB GATE closed holds=", leader.global_position.z > GATE_Z)
	await _tour_use("piece_plant")
	await _tour_use("mattias")
	print("LIB HELP guide_all=", Game.flag("libGuideAll"), " guiding_to_papers=", guide_target == PIECES["papers"])
	await _tour_use("radio")
	await _tour_use("piece_papers")
	await _tour_use("piece_lighter")
	print("LIB PIECES found=", pieces_found(), " gate=", Game.flag("libGateOpen"), " curtain=", curtain_body == null, " guiding_to_room=", guide_target == ROT_IN)
	place_party(Vector3(0, 0, GATE_Z + 2.0), Vector3(0, 0, -1))
	walk_to(leader, ROT_IN + Vector3(0, 0, -0.5), 1.6, 6.0)
	for k in 30:
		if dialogue.active:
			break
		await wait(0.2)
	await wait(1.2)
	await shot("dl_03_pass")
	await _drain()
	for k in 20:
		if stage == "end":
			break
		await wait(0.1)
	print("DELOYE TOUR pick=", tour_pick, " met=", Game.flag("deloyeMet"), " gift=", Game.flag("deloyeGift"), " owner=", Game.gear_owner.get("neuralink", ""),
		" faded=", Game.flags.get("fadedFights", 0), " bad=", Game.flag("deloyeBad"), " joint=", Game.count("joint"), " stage=", stage)
	await wait(3.0)
	get_tree().quit()

func _drain() -> void:   # click through a conversation; choices get tour_pick
	for k in 60:
		if not dialogue.active:
			break
		await wait(0.3)
		if not dialogue._choices.is_empty():
			dialogue._picked.emit(mini(tour_pick, dialogue._choices.size() - 1))
		else:
			dialogue._next.emit()

func _tour_use(id: String) -> void:
	var it: Array = current_interactables().filter(func(i): return i["id"] == id)
	if it.is_empty():
		for i in _level_interactables():
			if i["id"] == id:
				place_party(_it_pos(i) + Vector3(0, 0, 0.4), Vector3(0, 0, -1))
				await wait(0.4)
				it = current_interactables().filter(func(j): return j["id"] == id)
				break
	if it.is_empty():
		print("LIB TOUR can't reach ", id)
		return
	var keep := tour_pick
	tour_pick = 0   # "You could help me?"
	start(it[0])
	await wait(0.4)
	await _drain()
	tour_pick = keep
	await wait(0.8)

func _begin_quick() -> void:
	fade.color.a = 0.0
	Game.unlock("deloye_found")
	Game.set_flag("libEntered")
	_apply_piece_state()
	busy = false
	await wait(1.2)
	_mattias_show(leader.global_position + Vector3(2.2, 0, -1.6))
	Game.set_flag("libMattias")
	stage = "walk"
	_walk()
	_walk_banter()
