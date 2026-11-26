# Charis's stuff (Asar 11/25): his red car on a driveway outside, his cat, and his collector shelf (anime
# figures, his prized trading card in a thick case, a long row of manga). mart.gd calls build_outside() and
# build_inside() from _charis_house(); everything here is its own code so mart.gd only needs the two calls.
# Models are Meshy GLBs in assets/props/ (car, cat, figures); a missing GLB is just skipped.
# The card and the manga are original art on purpose: no real card art, covers or logos (copyright).
class_name CharisProps
extends RefCounted

const CAR := "res://assets/props/charis_car.glb"
const CAT := "res://assets/props/charis_cat.glb"
const FIGURES := "res://assets/props/anime_figures.glb"

const DRIVE_X := 11.8                 # driveway centre line (right of the front door, clear of the cobbles)
const DRIVE_Z0 := -14.2               # starts at the house front...
const DRIVE_Z1 := -0.9                # ...runs down to the street
const DRIVE_W := 3.0
const CAR_POS := Vector3(DRIVE_X, 0, -10.6)

# ---------------------------------------------------------------- outside
static func build_outside(lv: Node3D) -> void:
	var len := DRIVE_Z1 - DRIVE_Z0
	var mid := Vector3(DRIVE_X, 0, (DRIVE_Z0 + DRIVE_Z1) / 2.0)
	# pale stone paving with a darker curb on both sides
	Models.patch(lv, mid, Vector2(DRIVE_W, len), "monastery_stone_floor", 1.4, Color(0.72, 0.72, 0.74), 0.0, 0.08)
	var curb := Models.mat("stone_wall_03", 1.0, Color(0.55, 0.55, 0.58))
	for s in [-1.0, 1.0]:
		Models.block(lv, mid + Vector3(s * (DRIVE_W / 2.0 + 0.08), 0.06, 0), Vector3(0.16, 0.12, len), curb)
	# the car, parked nose-out toward the street
	var car := _model(lv, CAR, 4.6, CAR_POS, PI / 2.0)
	if car:
		Util.static_box(lv, CAR_POS + Vector3(0, 0.7, 0), Vector3(2.0, 1.4, 4.6))

# ---------------------------------------------------------------- inside
static func build_inside(lv: Node3D, house: Vector3) -> void:
	_collector_shelf(lv, house + Vector3(4.75, 0, 1.0), -PI / 2.0 + 0.55)
	# his cat, loafing on the rug where he can watch the fire
	_model(lv, CAT, 0.42, house + Vector3(-0.4, 0.02, 1.3), 0.5, true)

# A glass-front collector shelf: figures up top, the card in the middle with manga either side, more manga below.
static func _collector_shelf(lv: Node3D, at: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	lv.add_child(root)
	root.global_position = at
	root.rotation.y = yaw
	var wood := Models.mat("dark_wood", 1.0, Color(0.22, 0.17, 0.16))
	var W := 1.7
	var D := 0.42
	var H := 2.05
	# frame: sides, back, top, bottom, three shelves
	_box(root, Vector3(-W / 2.0, H / 2.0, 0), Vector3(0.05, H, D), wood)
	_box(root, Vector3(W / 2.0, H / 2.0, 0), Vector3(0.05, H, D), wood)
	_box(root, Vector3(0, H / 2.0, -D / 2.0 + 0.02), Vector3(W, H, 0.03), wood)
	_box(root, Vector3(0, H - 0.025, 0), Vector3(W, 0.05, D), wood)
	_box(root, Vector3(0, 0.06, 0), Vector3(W, 0.12, D), wood)
	var led := StandardMaterial3D.new()   # warm LED strips under each shelf so the collection glows
	led.albedo_color = Color(1.0, 0.85, 0.7)
	led.emission_enabled = true
	led.emission = Color(1.0, 0.82, 0.65)
	led.emission_energy_multiplier = 2.2
	for y in [0.62, 1.22, 1.82]:
		_box(root, Vector3(0, y, 0), Vector3(W - 0.08, 0.035, D - 0.04), wood)
		_box(root, Vector3(0, y - 0.025, D / 2.0 - 0.05), Vector3(W - 0.12, 0.012, 0.02), led)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.86, 0.72)
	l.light_energy = 0.9
	l.omni_range = 2.6
	l.position = Vector3(0, 1.5, D)
	root.add_child(l)
	Util.static_box(lv, at + Vector3(0, H / 2.0, 0), Vector3(W, H, D), yaw)
	# top shelf: the figures (one Meshy model of four on a shared base)
	var figs := _model(root, FIGURES, W - 0.25, Vector3(0, 1.24, 0.02), 0.0, false, true)
	# middle shelf: the card on its stand, manga either side
	_card(root, Vector3(0, 0.64, 0.03))
	_manga_row(root, Vector3(-W / 2.0 + 0.06, 0.64, -0.02), 10, 1)
	_manga_row(root, Vector3(0.28, 0.64, -0.02), 10, 11)
	# bottom shelf: the rest of the run
	_manga_row(root, Vector3(-W / 2.0 + 0.06, 0.12, -0.02), 30, 21)
	if figs == null:   # no figures GLB yet: leave the top shelf with a couple of spare volumes
		_manga_row(root, Vector3(-0.3, 1.24, -0.02), 6, 51)

# His prized card (original art, no real card image): a holo card in a thick clear extended-art case, on a stand.
static func _card(parent: Node3D, at: Vector3) -> void:
	var stand := StandardMaterial3D.new()
	stand.albedo_color = Color(0.05, 0.05, 0.06)
	stand.metallic = 0.4
	stand.roughness = 0.3
	_box(parent, at + Vector3(0, 0.02, 0.0), Vector3(0.16, 0.04, 0.1), stand)
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = at + Vector3(0, 0.17, -0.01)
	holder.rotation.x = -0.12   # leaning back a touch on the stand
	var case_mat := StandardMaterial3D.new()   # the thick clear case
	case_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.22)
	case_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	case_mat.roughness = 0.05
	case_mat.metallic_specular = 1.0
	_box(holder, Vector3.ZERO, Vector3(0.15, 0.26, 0.03), case_mat)
	var label := StandardMaterial3D.new()   # gold grading label at the top of the case
	label.albedo_color = Color(0.95, 0.75, 0.3)
	label.metallic = 0.8
	label.roughness = 0.25
	_box(holder, Vector3(0, 0.105, 0.016), Vector3(0.13, 0.035, 0.004), label)
	var card := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.115, 0.17)
	card.mesh = q
	var holo := ShaderMaterial.new()
	holo.shader = preload("res://shaders/holo_card.gdshader")
	card.material_override = holo
	card.position = Vector3(0, -0.015, 0.0)
	holder.add_child(card)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.85, 0.75, 1.0)
	glow.light_energy = 0.35
	glow.omni_range = 0.8
	glow.position = Vector3(0, 0, 0.2)
	holder.add_child(glow)

# A row of `n` manga volumes standing spine-out, numbered from `first` (plain spines: no real covers or logos).
static func _manga_row(parent: Node3D, from: Vector3, n: int, first: int) -> void:
	var cols := [Color(0.95, 0.94, 0.9), Color(0.93, 0.9, 0.86)]
	var band := [Color(0.85, 0.2, 0.2), Color(0.2, 0.45, 0.85), Color(0.95, 0.75, 0.2), Color(0.3, 0.7, 0.4)]
	var x := 0.0
	for i in n:
		var w := 0.034
		var h := 0.18 + (0.004 if i % 3 == 0 else 0.0)
		var m := StandardMaterial3D.new()
		m.albedo_color = cols[i % 2]
		m.roughness = 0.8
		_box(parent, from + Vector3(x + w / 2.0, h / 2.0, 0), Vector3(w - 0.003, h, 0.13), m)
		var b := StandardMaterial3D.new()   # coloured band + number block near the top of each spine
		b.albedo_color = band[(first + i) / 10 % band.size()]
		_box(parent, from + Vector3(x + w / 2.0, h - 0.035, 0.066), Vector3(w - 0.006, 0.03, 0.002), b)
		x += w

static func _box(parent: Node3D, pos: Vector3, size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

# Load a GLB and scale it so its longest side is `size` metres (or its height, with by_height), feet on `pos`.
# local = pos is relative to `parent` (shelf contents); otherwise a world position.
static func _model(parent: Node3D, path: String, size: float, pos: Vector3, yaw := 0.0, by_height := false, local := false) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var m: Node3D = (load(path) as PackedScene).instantiate()
	parent.add_child(m)
	var box := _bounds(m)
	var ref := box.size.y if by_height else maxf(box.size.x, maxf(box.size.y, box.size.z))
	var s := size / maxf(ref, 0.001)
	m.scale = Vector3.ONE * s
	m.rotation.y = yaw
	var lift := -box.position.y * s   # feet on the floor / shelf
	if local:
		m.position = pos + Vector3(0, lift, 0)
	else:
		m.global_position = pos + Vector3(0, lift, 0)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return m

static func _bounds(n: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		b = (mi as MeshInstance3D).transform * b
		if first:
			out = b
			first = false
		else:
			out = out.merge(b)
	return out
