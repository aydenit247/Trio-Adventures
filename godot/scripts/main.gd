# Trio Adventures — 2.5D test: the camp, the night before the quest.
# The whole level is built in code so it's easy to tweak numbers (and for Claude to edit).
# 3D world (ground, forest, tents, fire, moon, fog) + 2D cutout characters (see unit.gd).
#
# Controls: WASD walk · Shift run · E/Space talk · Tab switch who you control
#           ←/→ or right-mouse drag turn the camera · mouse wheel zoom · V voices on/off
extends Node3D

const CampScript = preload("res://scripts/camp_script.gd")
const MOON_DIR := Vector3(-0.45, 0.32, -0.83)
const FIRE_POS := Vector3.ZERO
const MATTIAS_POS := Vector3(0, 0, -21)
const GOBLIN_HOME := Vector3(9, 0, -6)

var flags := {}
var party: Array[Unit] = []
var leader: Unit
var goblin: Unit
var dialogue: Dialogue
var cam: Camera3D
var cam_target := Vector3.ZERO
var focus_override = null
var yaw := 0.0
var target_yaw := 0.0
var zoom := 8.0
var fire_light: OmniLight3D
var noise := FastNoiseLite.new()
var t := 0.0
var interactables: Array = []
var prompt: Label3D
var busy := false
var interact_cooldown := 0.0
var step_sfx: AudioStreamPlayer
var ui_sfx: AudioStreamPlayer
var whoosh_sfx: AudioStreamPlayer
var fade: ColorRect
var leader_lbl: Label
var leader_por: TextureRect
var toast: Label
var mattias_sprite: Sprite3D
var mattias_light: OmniLight3D
var mattias_done := false
var goblin_goal := GOBLIN_HOME
var goblin_timer := 0.0
var rng := RandomNumberGenerator.new()
var shots_mode := false
# Scene 1 progress: "start" (no fire) → "has_map" (carrying the paper) → "lit" (free roam)
var stage := "start"
var flames: CPUParticles3D
var embers: CPUParticles3D
var smoke: CPUParticles3D
var coal_mat: StandardMaterial3D
var scrap_mesh: MeshInstance3D
var amb: Ambience
var paper: Sprite3D
var objective_lbl: Label
var shake := 0.0
var fire_base := 0.0

func _ready() -> void:
	rng.seed = 7
	noise.frequency = 1.0
	_setup_input()
	_build_environment()
	_build_ground()
	_build_forest()
	_build_camp()
	_build_fire()
	_build_characters()
	_build_ui()
	amb = Ambience.new()
	add_child(amb)
	amb.setup(FIRE_POS)
	amb.fire_player.volume_db = -80.0
	cam_target = leader.global_position
	shots_mode = "--shots" in OS.get_cmdline_user_args()
	if shots_mode:
		_shot_tour()
	else:
		_intro()

# ---------------------------------------------------------------- input
func _key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

func _setup_input() -> void:
	_key("move_forward", [KEY_W])
	_key("move_back", [KEY_S])
	_key("move_left", [KEY_A])
	_key("move_right", [KEY_D])
	_key("run", [KEY_SHIFT])
	_key("interact", [KEY_E, KEY_SPACE, KEY_ENTER])
	_key("switch", [KEY_TAB])
	_key("cam_left", [KEY_LEFT])
	_key("cam_right", [KEY_RIGHT])
	_key("tts", [KEY_V])

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - 0.6, 5.0, 15.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + 0.6, 5.0, 15.0)
	if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		target_yaw -= ev.relative.x * 0.006

# ---------------------------------------------------------------- world
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = SKY_SHADER
	sm.set_shader_parameter("moon_dir", MOON_DIR.normalized())
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.26, 0.45)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.25
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.11)
	env.fog_density = 0.02
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = true           # Forward+ only: the fire glows through the haze
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.6, 0.65, 0.8)
	env.ssao_enabled = true
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.6, 0.7, 1.0)
	moon.light_energy = 0.8
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	moon.look_at_from_position(Vector3.ZERO, -MOON_DIR.normalized(), Vector3.UP)

func _noise_tex(a: Color, b: Color, freq := 0.03) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.frequency = freq
	n.fractal_octaves = 4
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	var tex := NoiseTexture2D.new()
	tex.noise = n
	tex.color_ramp = g
	tex.seamless = true
	tex.width = 256
	tex.height = 256
	return tex

func _build_ground() -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(200, 1, 200)
	cs.shape = bs
	cs.position.y = -0.5
	body.add_child(cs)
	add_child(body)

	# Photo textures blended by a shader: grass everywhere, gravel in the clearing and along the path,
	# with a noisy edge so there's no hard circle.
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = GROUND_SHADER
	mat.set_shader_parameter("grass_tex", load("res://assets/textures/grass.jpg"))
	mat.set_shader_parameter("dirt_tex", load("res://assets/textures/gravel.jpg"))
	var n := FastNoiseLite.new()
	n.frequency = 0.02
	n.fractal_octaves = 3
	var nt := NoiseTexture2D.new()
	nt.noise = n
	nt.seamless = true
	nt.width = 512
	nt.height = 512
	mat.set_shader_parameter("noise_tex", nt)
	Util.add_mesh(self, pm, mat, Vector3.ZERO)

# A prop from Ebain's art: a cutout card standing in the world (same trick as the characters).
# Returns its material so the lighting can tint it.
var cards: Array = []   # [material, position, near_fire]
var _tex_cache := {}

func _card(name: String, height: float, pos: Vector3, flip := false, fade_near := false, collide_r := 0.0) -> StandardMaterial3D:
	if not _tex_cache.has(name):
		_tex_cache[name] = load("res://assets/props/%s.png" % name)
	var tex: Texture2D = _tex_cache[name]
	var w := height * tex.get_width() / float(tex.get_height())
	var q := QuadMesh.new()
	q.size = Vector2(w, height)
	q.center_offset = Vector3(0, height / 2.0 - height * 0.03, 0)   # sink the drawn ground patch a touch
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.uv1_scale = Vector3(-1 if flip else 1, 1, 1)
	if fade_near:   # dissolve when right in front of the camera
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		m.distance_fade_min_distance = 5.5
		m.distance_fade_max_distance = 10.0
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	var near := pos.distance_to(FIRE_POS) < 15.0
	m.albedo_color = Color(0.5, 0.56, 0.8) if near else Color(0.42, 0.47, 0.68)
	cards.append([m, pos, near])
	if collide_r > 0.0:
		Util.static_cyl(self, pos, collide_r)
	return m

func _build_forest() -> void:
	# Trees
	var placed := 0
	var tries := 0
	while placed < 170 and tries < 3000:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(10.0, 46.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 3.6 and p.z < -6.0 and p.z > -26.0:
			continue
		if p.distance_to(GOBLIN_HOME) < 3.0 or p.distance_to(MATTIAS_POS) < 4.0:
			continue
		_card("tree_%d" % (rng.randi() % 4 + 1), rng.randf_range(6.0, 9.5), p, rng.randf() < 0.5, true, 0.5 if r < 32.0 else 0.0)
		placed += 1
	# Bushes, between the trees and around the edge of camp
	for k in 55:
		var a := rng.randf() * TAU
		var r := rng.randf_range(7.8, 40.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 2.6 and p.z < -6.0 and p.z > -26.0:
			continue
		var big := rng.randf() < 0.25
		_card("bush_big" if big else "bush_%d" % (rng.randi() % 3 + 1), rng.randf_range(1.6, 2.3) if big else rng.randf_range(1.3, 2.2), p, rng.randf() < 0.5, true)
	# Standing rocks (the rune stone goes by the dark path)
	for k in 16:
		var a := rng.randf() * TAU
		var r := rng.randf_range(8.0, 32.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 3.0 and p.z < -6.0 and p.z > -26.0:
			continue
		_card("rock_%d" % [1, 2, 4][rng.randi() % 3], rng.randf_range(1.2, 2.6), p, rng.randf() < 0.5, true, 0.45)
	_card("rock_3", 2.4, Vector3(-2.6, 0, -15.0), false, false, 0.45)

	# Distant mountains (silhouettes against the sky)
	var mtn_m := Util.mat(Color(0.03, 0.035, 0.06))
	for k in 16:
		var a := k / 16.0 * TAU + rng.randf_range(-0.15, 0.15)
		var r := rng.randf_range(85, 110)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = rng.randf_range(22, 38)
		cm.height = rng.randf_range(22, 42)
		cm.radial_segments = 6
		Util.add_mesh(self, cm, mtn_m, Vector3(cos(a) * r, cm.height / 2.0 - 3.0, sin(a) * r), Vector3(0, rng.randf() * TAU, 0))

	# Fireflies
	var ff := CPUParticles3D.new()
	ff.amount = 50
	ff.lifetime = 7.0
	ff.mesh = _quad(0.07, Color.WHITE, true)
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(26, 1.5, 26)
	ff.gravity = Vector3.ZERO
	ff.direction = Vector3.UP
	ff.spread = 180.0
	ff.initial_velocity_min = 0.1
	ff.initial_velocity_max = 0.4
	ff.color_ramp = _ramp([[0.0, Color(0.8, 1.0, 0.4, 0)], [0.3, Color(0.8, 1.0, 0.4, 1)], [0.7, Color(0.8, 1.0, 0.4, 1)], [1.0, Color(0.8, 1.0, 0.4, 0)]])
	ff.position = Vector3(0, 1.4, 0)
	add_child(ff)

const SKORN_TENT := Vector3(-5.4, 0, -3.6)
const LYKOR_TENT := Vector3(5.6, 0, -3.9)
const LANTERN := Vector3(4.9, 1.3, -3.0)

func _build_camp() -> void:
	_card("tent_green", 3.0, SKORN_TENT)
	Util.static_box(self, SKORN_TENT + Vector3(0, 1, 0), Vector3(4.4, 2, 2.8), 0.6)
	_card("tent_purple", 3.3, LYKOR_TENT)
	Util.static_box(self, LYKOR_TENT + Vector3(0, 1, 0), Vector3(4.4, 2, 2.8), -0.6)
	var lan := OmniLight3D.new()   # the lanterns drawn in Lykor's tent actually glow
	lan.light_color = Color(1.0, 0.72, 0.4)
	lan.light_energy = 0.9
	lan.omni_range = 4.5
	lan.position = LANTERN
	add_child(lan)

	_card("campfire", 1.1, FIRE_POS + Vector3(0, 0, 0.05))
	_card("log", 0.8, Vector3(-3.4, 0, 2.8), false, false)
	Util.static_box(self, Vector3(-3.4, 0.3, 2.8), Vector3(1.6, 0.6, 0.5), 0.9)
	_card("bag", 0.55, Vector3(-2.7, 0, -1.6))
	_card("sign", 2.6, Vector3(2.7, 0, -8.4))
	Util.static_cyl(self, Vector3(2.4, 0, -8.4), 0.2)

	# The charred map scrap (appears after the fire)
	var scrap := PlaneMesh.new()
	scrap.size = Vector2(0.5, 0.36)
	var sm := Util.mat(Color(0.08, 0.06, 0.05))
	sm.emission_enabled = true
	sm.emission = Color(1.0, 0.35, 0.1)
	sm.emission_energy_multiplier = 0.6
	scrap_mesh = Util.add_mesh(self, scrap, sm, Vector3(1.5, 0.03, 1.4), Vector3(0, 0.7, 0))
	scrap_mesh.visible = false

func _quad(size: float, _c: Color, additive: bool) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = Util.radial_tex()
	q.material = m
	return q

func _ramp(stops: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return s[1]))
	return g

func _curve(points: Array) -> Curve:
	var c := Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	return c

func _build_fire() -> void:
	var stick := CylinderMesh.new()
	stick.top_radius = 0.06
	stick.bottom_radius = 0.09
	stick.height = 1.0
	stick.radial_segments = 6
	var char_m := Util.mat(Color(0.12, 0.07, 0.04))
	for k in 5:
		var a := k / 5.0 * TAU
		var mi := Util.add_mesh(self, stick, char_m, FIRE_POS + Vector3(cos(a) * 0.22, 0.35, sin(a) * 0.22))
		mi.rotation = Vector3(0, -a, 0)
		mi.rotate_object_local(Vector3.FORWARD, 0.55)
	var coal := SphereMesh.new()
	coal.radius = 0.3
	coal.height = 0.2
	var coal_m := Util.mat(Color(0.3, 0.1, 0.02))
	coal_m.emission_enabled = true
	coal_m.emission = Color(1.0, 0.35, 0.08)
	coal_m.emission_energy_multiplier = 2.5
	Util.add_mesh(self, coal, coal_m, FIRE_POS + Vector3(0, 0.06, 0))
	coal_mat = coal_m
	coal_m.emission_energy_multiplier = 0.0

	var flames_p := CPUParticles3D.new()
	flames_p.amount = 80
	flames_p.lifetime = 0.9
	flames_p.mesh = _quad(0.6, Color.WHITE, true)
	flames_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames_p.emission_sphere_radius = 0.22
	flames_p.direction = Vector3.UP
	flames_p.spread = 12.0
	flames_p.gravity = Vector3(0, 1.8, 0)
	flames_p.initial_velocity_min = 0.5
	flames_p.initial_velocity_max = 1.2
	flames_p.scale_amount_min = 0.6
	flames_p.scale_amount_max = 1.25
	flames_p.scale_amount_curve = _curve([[0.0, 0.7], [0.25, 1.0], [1.0, 0.1]])
	flames_p.color_ramp = _ramp([[0.0, Color(1.0, 0.95, 0.6, 1)], [0.3, Color(1.0, 0.55, 0.12, 0.9)], [0.7, Color(0.8, 0.15, 0.05, 0.5)], [1.0, Color(0.2, 0.05, 0.02, 0)]])
	flames_p.position = FIRE_POS + Vector3(0, 0.25, 0)
	flames_p.emitting = false
	add_child(flames_p)
	flames = flames_p

	var embers_p := CPUParticles3D.new()
	embers_p.amount = 30
	embers_p.lifetime = 2.6
	embers_p.mesh = _quad(0.06, Color.WHITE, true)
	embers_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers_p.emission_sphere_radius = 0.3
	embers_p.direction = Vector3.UP
	embers_p.spread = 25.0
	embers_p.gravity = Vector3(0, 0.4, 0)
	embers_p.initial_velocity_min = 1.0
	embers_p.initial_velocity_max = 2.4
	embers_p.color_ramp = _ramp([[0.0, Color(1, 0.7, 0.3, 1)], [1.0, Color(1, 0.3, 0.1, 0)]])
	embers_p.position = FIRE_POS + Vector3(0, 0.4, 0)
	embers_p.emitting = false
	add_child(embers_p)
	embers = embers_p

	var smoke_p := CPUParticles3D.new()
	smoke_p.amount = 18
	smoke_p.lifetime = 4.0
	smoke_p.mesh = _quad(1.2, Color.WHITE, false)
	smoke_p.direction = Vector3.UP
	smoke_p.spread = 10.0
	smoke_p.gravity = Vector3(0.15, 0.25, 0)
	smoke_p.initial_velocity_min = 0.4
	smoke_p.initial_velocity_max = 0.7
	smoke_p.scale_amount_curve = _curve([[0.0, 0.4], [1.0, 1.6]])
	smoke_p.color_ramp = _ramp([[0.0, Color(0.45, 0.45, 0.5, 0)], [0.3, Color(0.45, 0.45, 0.5, 0.1)], [1.0, Color(0.45, 0.45, 0.5, 0)]])
	smoke_p.position = FIRE_POS + Vector3(0, 1.3, 0)
	smoke_p.emitting = false
	add_child(smoke_p)
	smoke = smoke_p

	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.55, 0.22)
	fire_light.light_energy = 0.0
	fire_light.omni_range = 14.0
	fire_light.omni_attenuation = 1.1
	fire_light.shadow_enabled = true
	fire_light.light_volumetric_fog_energy = 2.0
	fire_light.position = FIRE_POS + Vector3(0, 0.9, 0)
	add_child(fire_light)
	Util.static_cyl(self, FIRE_POS, 1.5, 1.0)

func _build_characters() -> void:
	var defs := [["skorn", "Skorn", 1.95, Vector3(2.0, 0, 2.9)], ["lykor", "Lykor", 1.9, Vector3(cos(2.3) * 3.9, 0, sin(2.3) * 3.9)], ["xylo", "Xylo", 1.95, Vector3(cos(0.75) * 3.9, 0, sin(0.75) * 3.9)]]
	for d in defs:
		var u := Unit.new()
		add_child(u)
		u.setup(d[0], d[1], load("res://assets/characters/%s.png" % d[0]), d[2])
		u.global_position = d[3]
		u.stepped.connect(_on_step.bind(u))
		party.append(u)
	_set_leader(party[0])

	goblin = Unit.new()
	add_child(goblin)
	goblin.setup("goblin", "Goblin (Between Jobs)", load("res://assets/characters/goblin.png"), 1.25)
	goblin.walk_speed = 1.4
	goblin.global_position = GOBLIN_HOME

	# Metocin Mattias, standing in the fog down the dark path
	mattias_sprite = Sprite3D.new()
	var mt: Texture2D = load("res://assets/characters/mattias.png")
	mattias_sprite.texture = mt
	mattias_sprite.pixel_size = 1.95 / mt.get_height()
	mattias_sprite.offset = Vector2(0, mt.get_height() / 2.0)
	mattias_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	mattias_sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	mattias_sprite.shaded = false
	mattias_sprite.modulate = Color(0.55, 0.65, 0.9)
	mattias_sprite.position = MATTIAS_POS
	add_child(mattias_sprite)
	mattias_light = OmniLight3D.new()
	mattias_light.light_color = Color(0.4, 0.6, 1.0)
	mattias_light.light_energy = 1.4
	mattias_light.omni_range = 5.0
	mattias_light.position = MATTIAS_POS + Vector3(0, 1.4, 0.8)
	add_child(mattias_light)

	interactables = [
		{ "id": "fire", "label": "Campfire", "verb": "Look at", "pos": FIRE_POS, "h": 1.8, "r": 2.9, "steps": CampScript.OBJECTS["fire"] },
		{ "id": "map", "label": "Charred paper", "verb": "Look at", "pos": Vector3(1.5, 0, 1.4), "h": 0.7, "r": 1.4, "steps": CampScript.OBJECTS["map"] },
		{ "id": "bag", "label": "Lykor's bag", "verb": "Look at", "pos": Vector3(-2.7, 0, -1.6), "h": 1.0, "r": 1.6, "steps": CampScript.OBJECTS["bag"] },
		{ "id": "tent", "label": "Tent", "verb": "Look at", "pos": SKORN_TENT, "h": 3.2, "r": 3.4, "steps": CampScript.OBJECTS["tent"] },
		{ "id": "goblin", "label": "Goblin (Between Jobs)", "verb": "Talk to", "node": goblin, "h": 1.6, "r": 2.2, "steps": CampScript.OBJECTS["goblin"] },
	]

func _set_leader(u: Unit) -> void:
	var old := leader
	leader = u
	var order: Array[Unit] = [u]
	for p in party:
		if p != u:
			order.append(p)
	for i in order.size():
		order[i].follow_slot = i
	u.trail.clear()
	u.trail.append(u.global_position)
	if old and old != u:
		u.trail.append(old.global_position)
	for p in order.slice(1):
		u.trail.append(p.global_position)
	if leader_lbl:
		leader_lbl.text = "Controlling: %s" % u.display_name
		leader_por.texture = load("res://assets/portraits/%s.png" % u.id)

func _on_step(u: Unit) -> void:
	if u == leader and step_sfx:
		step_sfx.pitch_scale = rng.randf_range(0.8, 1.15)
		step_sfx.play()

# ---------------------------------------------------------------- UI
func _build_ui() -> void:
	dialogue = Dialogue.new()
	add_child(dialogue)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var title := Label.new()
	title.text = "TRIO ADVENTURES"
	title.position = Vector2(24, 16)
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e8b923"))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 8)
	hud.add_child(title)
	var sub := Label.new()
	sub.text = "2.5D test — Camp, the night before the quest"
	sub.position = Vector2(26, 54)
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color("#c9c0e8"))
	sub.add_theme_color_override("font_outline_color", Color.BLACK)
	sub.add_theme_constant_override("outline_size", 5)
	hud.add_child(sub)
	objective_lbl = Label.new()
	objective_lbl.position = Vector2(26, 80)
	objective_lbl.add_theme_font_size_override("font_size", 19)
	objective_lbl.add_theme_color_override("font_color", Color("#ffdf8a"))
	objective_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	objective_lbl.add_theme_constant_override("outline_size", 6)
	hud.add_child(objective_lbl)

	var box := HBoxContainer.new()
	box.anchor_left = 1.0; box.anchor_right = 1.0
	box.offset_left = -280; box.offset_top = 16; box.offset_right = -20
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 10)
	hud.add_child(box)
	leader_lbl = Label.new()
	leader_lbl.add_theme_font_size_override("font_size", 18)
	leader_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	leader_lbl.add_theme_constant_override("outline_size", 6)
	leader_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(leader_lbl)
	leader_por = TextureRect.new()
	leader_por.custom_minimum_size = Vector2(56, 56)
	leader_por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leader_por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(leader_por)
	_set_leader(leader)

	var help := Label.new()
	help.text = "WASD walk · Shift run · E talk · Tab switch character · ←/→ or right-drag camera · wheel zoom · V voices"
	help.anchor_top = 1.0; help.anchor_bottom = 1.0; help.anchor_right = 1.0
	help.offset_top = -30; help.offset_left = 20; help.offset_right = -20
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	help.add_theme_color_override("font_outline_color", Color.BLACK)
	help.add_theme_constant_override("outline_size", 4)
	hud.add_child(help)

	toast = Label.new()
	toast.anchor_left = 0.5; toast.anchor_right = 0.5
	toast.offset_left = -300; toast.offset_right = 300; toast.offset_top = 90
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 22)
	toast.add_theme_color_override("font_outline_color", Color.BLACK)
	toast.add_theme_constant_override("outline_size", 6)
	toast.modulate.a = 0.0
	hud.add_child(toast)

	# Film grain + vignette over the 3D view (under the HUD)
	var post := CanvasLayer.new()
	post.layer = 4
	add_child(post)
	var pr := ColorRect.new()
	pr.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psm := ShaderMaterial.new()
	psm.shader = Shader.new()
	psm.shader.code = POST_SHADER
	pr.material = psm
	post.add_child(pr)

	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(fade)

	prompt = Label3D.new()
	prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt.no_depth_test = true
	prompt.font_size = 40
	prompt.pixel_size = 0.0055
	prompt.outline_size = 10
	prompt.modulate = Color("#ffdf8a")
	prompt.visible = false
	add_child(prompt)

	step_sfx = AudioStreamPlayer.new()
	step_sfx.stream = Util.noise_burst(55, 0.18, 0.7)
	step_sfx.volume_db = -12.0
	add_child(step_sfx)
	ui_sfx = AudioStreamPlayer.new()
	ui_sfx.stream = Util.chime(990.0, 180, 0.2)
	ui_sfx.volume_db = -10.0
	add_child(ui_sfx)
	whoosh_sfx = AudioStreamPlayer.new()
	whoosh_sfx.stream = Util.noise_burst(700, 0.05, 0.9)
	whoosh_sfx.volume_db = -6.0
	add_child(whoosh_sfx)

func _toast(msg: String) -> void:
	toast.text = msg
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(1.4)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)

# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
	t += delta
	fire_light.light_energy = fire_base * (1.0 + noise.get_noise_1d(t * 9.0) * 0.33 + noise.get_noise_1d(t * 31.0) * 0.13)
	_update_camera(delta)
	var cam_right := cam.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()
	var cam_fwd := -cam.global_transform.basis.z
	cam_fwd.y = 0.0
	cam_fwd = cam_fwd.normalized()

	var input := Vector2.ZERO
	if not busy:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var dir := cam_right * input.x + cam_fwd * input.y
	if dir.length() > 1.0:
		dir = dir.normalized()
	leader.drive(dir, Input.is_action_pressed("run"), cam_right, delta)
	leader.record_trail()
	for u in party:
		if u == leader:
			continue
		if stage != "lit":
			u.drive(Vector3.ZERO, false, cam_right, delta)
			continue
		var tp := u.follow_point(leader, 1.8 * u.follow_slot)
		var to := tp - u.global_position
		to.y = 0.0
		var d := to.length()
		var fdir := Vector3.ZERO
		if d > 0.35:
			fdir = to.normalized() * clamp(d / 1.2, 0.3, 1.0)
		u.drive(fdir, d > 3.0, cam_right, delta)
	_goblin_ai(delta, cam_right)
	for u in party + [goblin]:
		u.sprite.modulate = light_at(u.global_position)
	for c in cards:
		if c[2]:
			var lc := light_at(c[1] + Vector3(0, 0.5, 0))
			c[0].albedo_color = Color(min(lc.r, 0.92), min(lc.g, 0.8), min(lc.b, 0.78)) * 0.88
	if paper and paper.visible and paper.get_parent() == party[0]:
		paper.position.y = 1.15 + sin(t * 3.0) * 0.04
		paper.modulate = light_at(party[0].global_position)

	interact_cooldown = max(0.0, interact_cooldown - delta)
	if busy:
		prompt.visible = false
		return
	var it := _nearest_interactable()
	if it.is_empty():
		prompt.visible = false
	else:
		prompt.visible = true
		prompt.text = "[E]  %s %s" % [it["verb"], it["label"]]
		prompt.global_position = _it_pos(it) + Vector3(0, it["h"] + 0.35, 0)
		if Input.is_action_just_pressed("interact") and interact_cooldown <= 0.0:
			_start(it)
			return
	if Input.is_action_just_pressed("switch") and stage != "lit":
		_toast("Skorn's on fire duty right now.")
	elif Input.is_action_just_pressed("switch"):
		var i := party.find(leader)
		_set_leader(party[(i + 1) % party.size()])
		ui_sfx.play()
		_toast("Now controlling %s" % leader.display_name)
	if Input.is_action_just_pressed("tts"):
		dialogue.tts_on = not dialogue.tts_on
		_toast("Voices: %s" % ("ON" if dialogue.tts_on else "OFF"))
	if stage == "lit" and not mattias_done and leader.global_position.distance_to(MATTIAS_POS) < 6.5:
		mattias_done = true
		_mattias_event()

# Fake lighting for the cutouts: moonlit blue everywhere, warm orange near the fire (flickers with it),
# a little glow near the lantern and near Mattias.
func light_at(p: Vector3) -> Color:
	var col := Color(0.5, 0.56, 0.8)
	var f: float = clamp(1.0 - p.distance_to(FIRE_POS) / 11.0, 0.0, 1.0)
	f = f * f * (fire_light.light_energy / 3.0)
	col = col.lerp(Color(1.0, 0.72, 0.48), clamp(f * 1.3, 0.0, 1.0)) + Color(0.35, 0.18, 0.05) * f
	var l: float = clamp(1.0 - p.distance_to(LANTERN) / 4.5, 0.0, 1.0)
	col += Color(0.25, 0.16, 0.08) * l * l
	if mattias_sprite.visible:
		var m: float = clamp(1.0 - p.distance_to(MATTIAS_POS) / 6.0, 0.0, 1.0)
		col += Color(0.1, 0.18, 0.35) * m * (mattias_light.light_energy / 1.4)
	return Color(min(col.r, 1.25), min(col.g, 1.2), min(col.b, 1.2))

func _update_camera(delta: float) -> void:
	if Input.is_action_pressed("cam_left"):
		target_yaw += delta * 1.8
	if Input.is_action_pressed("cam_right"):
		target_yaw -= delta * 1.8
	yaw = lerp_angle(yaw, target_yaw, clamp(delta * 6.0, 0.0, 1.0))
	if cam == null:
		cam = Camera3D.new()
		cam.fov = 50.0
		add_child(cam)
		cam.current = true
		var ca := CameraAttributesPractical.new()   # depth of field: soft background (Forward+)
		ca.dof_blur_far_enabled = true
		ca.dof_blur_far_distance = 20.0
		ca.dof_blur_far_transition = 16.0
		ca.dof_blur_amount = 0.07
		cam.attributes = ca
	var focus: Vector3 = focus_override if focus_override != null else leader.global_position
	cam_target = cam_target.lerp(focus, clamp(delta * 4.0, 0.0, 1.0))
	var off := Vector3(0, zoom * 0.6, zoom).rotated(Vector3.UP, yaw)
	cam.global_position = cam_target + off
	cam.look_at(cam_target + Vector3(0, 1.1, 0), Vector3.UP)
	if shake > 0.0:
		shake = max(0.0, shake - delta)
		cam.h_offset = rng.randf_range(-1, 1) * shake * 0.25
		cam.v_offset = rng.randf_range(-1, 1) * shake * 0.25
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0

func _goblin_ai(delta: float, cam_right: Vector3) -> void:
	goblin_timer -= delta
	if goblin_timer <= 0.0:
		goblin_timer = rng.randf_range(2.5, 5.0)
		goblin_goal = GOBLIN_HOME + Vector3(rng.randf_range(-1.8, 1.8), 0, rng.randf_range(-1.8, 1.8))
	var to := goblin_goal - goblin.global_position
	to.y = 0.0
	goblin.drive(to.normalized() if to.length() > 0.3 else Vector3.ZERO, false, cam_right, delta)

func _it_pos(it: Dictionary) -> Vector3:
	return it["node"].global_position if it.has("node") else it["pos"]

func _current_interactables() -> Array:
	if stage == "lit":
		var list := interactables.duplicate()
		for u in party:
			if u != leader:
				list.append({ "id": u.id, "label": u.display_name, "verb": "Talk to", "node": u, "h": 2.15, "r": 1.9, "steps": CampScript.TALK[u.id] })
		return list
	var pre := CampScript.PRE_FIRE
	var list2: Array = [
		{ "id": "pit", "label": "Fire pit", "verb": ("Put the paper in the" if stage == "has_map" else "Look at"), "pos": FIRE_POS, "h": 1.4, "r": 2.9, "steps": pre["pit_with_map"] if stage == "has_map" else pre["pit"] },
		{ "id": "tent", "label": "Tent", "verb": "Search", "pos": SKORN_TENT, "h": 3.2, "r": 3.4, "steps": pre["tent"] },
		{ "id": "goblin", "label": "Goblin (Between Jobs)", "verb": "Talk to", "node": goblin, "h": 1.6, "r": 2.2, "steps": pre["goblin"] },
		{ "id": "lykor", "label": "Lykor", "verb": "Talk to", "node": party[1], "h": 2.15, "r": 1.9, "steps": pre["lykor"] },
		{ "id": "xylo", "label": "Xylo", "verb": "Talk to", "node": party[2], "h": 2.15, "r": 1.9, "steps": pre["xylo"] },
	]
	if stage == "start":
		list2.append({ "id": "bag", "label": "Lykor's bag", "verb": "Search", "pos": Vector3(-2.7, 0, -1.6), "h": 1.0, "r": 1.6, "steps": pre["bag"] })
	return list2

func _nearest_interactable() -> Dictionary:
	var list := _current_interactables()
	var best := {}
	var best_d := 999.0
	var lp := leader.global_position
	for it in list:
		var p := _it_pos(it)
		var d := Vector2(p.x - lp.x, p.z - lp.z).length()
		if d < it["r"] and d < best_d:
			best = it
			best_d = d
	return best

func _start(it: Dictionary) -> void:
	busy = true
	prompt.visible = false
	for u in party:
		u.frozen = true
	goblin.frozen = true
	ui_sfx.play()
	await dialogue.run(it["steps"], self)
	for u in party:
		u.frozen = false
	goblin.frozen = false
	busy = false
	interact_cooldown = 0.3

# Actions that dialogue can trigger with { "do": "name" }
func do_action(n: String) -> void:
	match n:
		"check_bag":
			flags["bag_checked"] = true
		"mattias_vanish":
			await _mattias_vanish()
		"grab_map":
			await _grab_map()
		"burn_map":
			await _burn_map()
		"freakout":
			await _freakout()
		"party_up":
			stage = "lit"
			_set_leader(party[0])
			_objective("Explore the camp. (The goblins are up north.)")

func _objective(text: String) -> void:
	objective_lbl.text = "Objective: " + text
	objective_lbl.modulate.a = 0.0
	create_tween().tween_property(objective_lbl, "modulate:a", 1.0, 0.4)

func _paper_tex() -> ImageTexture:
	var img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.86, 0.78, 0.6))
	for y in [10, 18, 26, 34]:
		for x in range(8, 56):
			if (x * 7 + y * 3) % 11 < 7:
				img.set_pixel(x, y + int(sin(x * 0.7) * 2.0), Color(0.3, 0.2, 0.15))
	for x in 64:
		img.set_pixel(x, 0, Color(0.5, 0.4, 0.3)); img.set_pixel(x, 47, Color(0.5, 0.4, 0.3))
	return ImageTexture.create_from_image(img)

func _grab_map() -> void:
	var sk := party[0]
	sk.sprite.flip_h = sk.global_position.x > -2.7
	var tw := create_tween()
	tw.tween_property(sk.sprite, "scale", Vector3(1.05, 0.85, 1.0), 0.15)
	tw.tween_property(sk.sprite, "scale", Vector3.ONE, 0.15)
	await tw.finished
	paper = Sprite3D.new()
	paper.texture = _paper_tex()
	paper.pixel_size = 0.009
	paper.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	paper.shaded = false
	paper.no_depth_test = true
	paper.position = Vector3(0.45, 1.15, 0.1)
	sk.add_child(paper)
	paper.scale = Vector3.ZERO
	create_tween().tween_property(paper, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ui_sfx.pitch_scale = 1.3
	ui_sfx.play()
	stage = "has_map"
	_objective("Put the paper in the fire pit.")
	await get_tree().create_timer(0.3).timeout
	ui_sfx.pitch_scale = 1.0

func _burn_map() -> void:
	var sk := party[0]
	# Paper flies into the pit
	var start := paper.global_position
	sk.remove_child(paper)
	add_child(paper)
	paper.global_position = start
	var tw := create_tween()
	tw.tween_property(paper, "global_position", start.lerp(FIRE_POS, 0.5) + Vector3(0, 1.2, 0), 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "global_position", FIRE_POS + Vector3(0, 0.2, 0), 0.25).set_ease(Tween.EASE_IN)
	await tw.finished
	paper.queue_free()
	paper = null
	# IGNITION
	whoosh_sfx.pitch_scale = 0.6
	whoosh_sfx.play()
	shake = 0.6
	flames.emitting = true
	embers.emitting = true
	pass  # smoke disabled (rendered as a dark blob)
	scrap_mesh.visible = true
	var lt := create_tween()
	lt.tween_property(self, "fire_base", 7.0, 0.12)
	lt.tween_property(self, "fire_base", 3.0, 0.8)
	create_tween().tween_property(coal_mat, "emission_energy_multiplier", 2.5, 0.6)
	create_tween().tween_property(amb.fire_player, "volume_db", -4.0, 1.2)
	objective_lbl.text = ""
	await get_tree().create_timer(1.3).timeout
	whoosh_sfx.pitch_scale = 1.0

func _freakout() -> void:
	shake = 0.35
	for u in [party[1], party[2]]:
		var tw := create_tween()
		tw.tween_property(u.sprite, "position:y", 0.6, 0.15).set_ease(Tween.EASE_OUT)
		tw.tween_property(u.sprite, "position:y", 0.0, 0.2).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.4).timeout

func _mattias_event() -> void:
	busy = true
	for u in party:
		u.frozen = true
	focus_override = (leader.global_position + MATTIAS_POS) / 2.0
	whoosh_sfx.play()
	var tw := create_tween()
	tw.tween_property(mattias_light, "light_energy", 4.0, 0.5)
	await get_tree().create_timer(0.8).timeout
	await dialogue.run(CampScript.MATTIAS, self)
	focus_override = null
	for u in party:
		u.frozen = false
	busy = false
	interact_cooldown = 0.3

func _mattias_vanish() -> void:
	whoosh_sfx.play()
	var burst := CPUParticles3D.new()
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 60
	burst.lifetime = 1.4
	burst.mesh = _quad(0.18, Color.WHITE, true)
	burst.direction = Vector3.UP
	burst.spread = 180.0
	burst.gravity = Vector3(0, 0.6, 0)
	burst.initial_velocity_min = 1.0
	burst.initial_velocity_max = 3.0
	burst.color_ramp = _ramp([[0.0, Color(0.5, 0.7, 1.0, 1)], [1.0, Color(0.3, 0.4, 1.0, 0)]])
	burst.position = MATTIAS_POS + Vector3(0, 1.0, 0)
	add_child(burst)
	burst.emitting = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(mattias_sprite, "modulate:a", 0.0, 0.6)
	tw.tween_property(mattias_light, "light_energy", 0.0, 0.9)
	await get_tree().create_timer(1.0).timeout
	mattias_sprite.visible = false

func _intro() -> void:
	busy = true
	fade.color.a = 1.0
	zoom = 17.0
	yaw = 0.9
	target_yaw = 0.9
	_update_camera(1.0)
	create_tween().tween_property(fade, "color:a", 0.0, 2.2)
	create_tween().tween_property(self, "zoom", 8.0, 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(self, "target_yaw", 0.0, 4.5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.6).timeout
	await dialogue.run(CampScript.INTRO, self)
	_objective("Get the fire going.")
	busy = false
	interact_cooldown = 0.3

# ---------------------------------------------------------------- automated screenshots (godot -- --shots)
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("SHOT_DIR")
	if dir.is_empty():
		dir = "user://"
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _place_party(p: Vector3, facing := Vector3(0, 0, 1)) -> void:
	var side := facing.cross(Vector3.UP).normalized()
	party[0].global_position = p
	party[1].global_position = p - facing * 1.4 + side * 0.9
	party[2].global_position = p - facing * 1.4 - side * 0.9
	_set_leader(party[0])
	cam_target = p

func _advance(n := 1) -> void:
	for i in n:
		await _wait(0.5)
		dialogue._next.emit()

func _shot_tour() -> void:
	busy = true
	dialogue.tts_on = false
	_objective("Get the fire going.")
	target_yaw = 0.7
	zoom = 8.0
	await _wait(2.0)
	await _shot("01_unlit")
	# Walk to the bag and grab the paper
	party[0].global_position = Vector3(-2.0, 0, -0.6)
	cam_target = party[0].global_position
	target_yaw = 0.2
	await _wait(1.5)
	_start(_current_interactables().filter(func(i): return i["id"] == "bag")[0])
	await _wait(1.6)
	await _shot("02_got_paper")
	await _advance(3)
	await _wait(0.8)
	# Carry it to the fire pit
	party[0].global_position = Vector3(1.9, 0, 2.2)
	cam_target = party[0].global_position
	target_yaw = 0.7
	await _wait(1.5)
	await _shot("03_carrying")
	_start(_current_interactables().filter(func(i): return i["id"] == "pit")[0])
	await _wait(0.75)
	await _shot("04_ignite")
	await _wait(1.6)
	await _shot("05_lit_dialogue")
	await _advance(5)
	await _wait(0.6)
	await _shot("06_freakout")
	await _advance(8)
	await _wait(2.0)
	await _shot("07_free_roam")
	get_tree().quit()

const GROUND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float worn(vec2 p) {
	float clearing = 1.0 - smoothstep(5.0, 8.5, length(p));
	float wiggle = sin(p.y * 0.42) * 1.1;
	float path = (1.0 - smoothstep(1.0, 2.3, abs(p.x - wiggle)));
	path *= smoothstep(-4.0, -6.0, p.y) * smoothstep(-29.0, -24.0, p.y);
	return max(clearing, path);
}

void fragment() {
	vec2 p = wpos.xz;
	// two scales of each texture so the repeat is hard to spot
	vec3 g = mix(texture(grass_tex, p * 0.16).rgb, texture(grass_tex, p * 0.047 + vec2(0.37, 0.11)).rgb, 0.4);
	vec3 d = mix(texture(dirt_tex, p * 0.22).rgb, texture(dirt_tex, p * 0.071 + vec2(0.6, 0.2)).rgb, 0.35);
	float n = texture(noise_tex, p * 0.035).r;
	float m = smoothstep(0.38, 0.62, worn(p) + (n - 0.5) * 0.7);
	float shade = 0.8 + 0.3 * texture(noise_tex, p * 0.012 + vec2(0.5)).r;
	ALBEDO = mix(g * vec3(0.85, 0.95, 0.85), d, m) * shade * 0.8;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
"""

const POST_SHADER := """
shader_type canvas_item;
uniform float grain = 0.045;
uniform float vignette = 0.5;

float rand(vec2 c) { return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float v = smoothstep(0.95, 0.3, length((uv - 0.5) * vec2(1.25, 1.0)));
	float n = rand(floor(uv * vec2(640.0, 360.0)) + fract(TIME * 7.0) * 100.0) - 0.5;
	float a = (1.0 - v) * vignette;
	vec3 col = mix(vec3(0.5 + n), vec3(0.0), clamp(a / max(a + abs(n) * grain, 0.0001), 0.0, 1.0));
	COLOR = vec4(col, clamp(a + abs(n) * grain, 0.0, 1.0));
}
"""

const SKY_SHADER := """
shader_type sky;
uniform vec3 top_color = vec3(0.01, 0.014, 0.045);
uniform vec3 horizon_color = vec3(0.10, 0.12, 0.23);
uniform vec3 moon_dir = vec3(-0.45, 0.32, -0.83);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = max(d.y, 0.0);
	vec3 col = mix(horizon_color, top_color, pow(y, 0.45));
	if (d.y < 0.0) { col = horizon_color * 0.6; }
	vec3 p = d * 260.0;
	vec3 cell = floor(p);
	vec3 f = fract(p) - 0.5;
	float h = hash(cell);
	if (h > 0.97 && d.y > 0.02) {
		vec3 off = vec3(hash(cell + 3.1), hash(cell + 7.7), hash(cell + 11.3)) - 0.5;
		float s = smoothstep(0.16, 0.0, length(f - off * 0.5));
		col += vec3(0.9, 0.95, 1.0) * s * ((h - 0.97) / 0.03) * 1.6 * smoothstep(0.02, 0.25, d.y);
	}
	vec3 md = normalize(moon_dir);
	float m = dot(d, md);
	col += vec3(0.95, 0.97, 1.0) * smoothstep(0.99935, 0.99965, m) * 2.5;
	col += vec3(0.25, 0.3, 0.5) * pow(max(m, 0.0), 90.0) * 0.6;
	COLOR = col;
}
"""
