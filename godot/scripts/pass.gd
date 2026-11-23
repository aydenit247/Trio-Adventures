# Area: The Pass (Scene 4, played as Skorn). Volcanic, red, ashy.
# Walk up → Metocin Mattias appears → the giant is asleep across the path (a real 3D canyon now) → choose:
#   A throw midtocy (if Skorn has it) · B Snore Sneak minigame · C Lore Session minigame · D fight · E cousin (goblins)
# When he wakes, the lying figure is replaced by Ebain's awake giant standing up for real.
# End of Chapter 1.
extends Level

const PS = preload("res://scripts/pass_script.gd")
const GIANT_HEAD := Vector3(4.2, 2.8, -10.0)      # his head, at the right end of where he's lying
const GIANT_STAND := Vector3(3.5, 0, -9.5)
const EXIT_POS := Vector3(14, 0, 0)

# "enter" → "mattias" done → "giant" (scene) → "after" (walk out) → "end"
var stage := "enter"
var giant_awake := false
var giant_mood := ""
var giant: Unit
var mattias: Unit
var mattias_light: OmniLight3D
var allies: Array[Unit] = []
var chief: Unit
var zzz_timer := 0.0
var snore: AudioStreamPlayer   # Asar's snoring recording, loops while he sleeps, louder the closer you get
var snore_sneak := false        # Snore Sneak minigame: full volume, and it pauses while he inhales
var mini_running := false
var mini_hold := false
var mini_pick := -1
var mini_sel := 0
var mini_opts: Array = []
var mini_labels: Array = []

func _configure() -> void:
	if not Game.title_mode:
		Game.set_flag("martDone")   # reaching the pass means the Mart is finished (also fixes older saves)
	# Golden-hour canyon (Asar: the old all-red lava haze was too much). Lava stays as glowing channels; see _after_build.
	night = false
	lava = false
	light_dir = Vector3(-0.55, 0.28, -0.8)
	clear_center = Vector2(0, -3)
	clear_radius = 6.0
	path_pts = PackedVector2Array([Vector2(0, 16), Vector2(0.5, 6), Vector2(0, 0), Vector2(2.5, -8), Vector2(0, 0), Vector2(8, 0), Vector2(16, 0)])
	path_width = 1.8
	subtitle = "Scene 4 — The Pass"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [Vector3(0, 0, 10), Vector3(-1, 0, 12), Vector3(1, 0, 12)]
	leader_id = "skorn"
	cam_locked = true
	zoom = 11.0
	cam_height = 0.32
	cam_look_h = 2.8
	talk = {
		"lykor": [{ "who": "lykor", "mood": "shocked", "line": "The ash is getting in my hair. I can feel it judging me." }], # DRAFT
	}

# Golden hour: warm low sun, soft blue-violet shade, light dusty haze instead of thick red fog
func _after_build() -> void:
	var env: Environment = world_env.environment
	env.ambient_light_color = Color(0.62, 0.6, 0.72)
	env.ambient_light_energy = 0.8
	env.tonemap_exposure = 1.0
	env.glow_intensity = 0.6
	env.glow_hdr_threshold = 1.1
	env.fog_light_color = Color(0.82, 0.68, 0.58)
	env.fog_density = 0.007
	env.volumetric_fog_density = 0.003
	env.volumetric_fog_albedo = Color(1.0, 0.9, 0.82)
	env.adjustment_saturation = 1.05
	sun_light.light_color = Color(1.0, 0.8, 0.58)
	sun_light.light_energy = 1.45
	# matte rocks: their shiny material mirrored the blue sky and looked like ice in daylight
	for m in find_children("*", "MeshInstance3D", true, false):
		for i in m.get_surface_override_material_count():
			var om = m.get_surface_override_material(i)
			if om is BaseMaterial3D:
				om.roughness = maxf(om.roughness, 0.95)
				om.metallic = 0.0
				om.metallic_specular = 0.15
				om.roughness_texture = null
	# canyon floor: dry sandstone instead of grass
	for m in find_children("*", "MeshInstance3D", false, false):
		var sm = m.material_override if m.material_override else (m.mesh.surface_get_material(0) if m.mesh and m.mesh.get_surface_count() > 0 else null)
		if sm is ShaderMaterial and sm.get_shader_parameter("dirt_tint") != null:
			sm.set_shader_parameter("dirt_tint", Color(0.82, 0.66, 0.5))
			sm.set_shader_parameter("grass_tint", Color(0.62, 0.5, 0.38))

func _build_level() -> void:
	var cliff := Color(0.58, 0.45, 0.36)
	_canyon()
	for side in [-1.0, 1.0]:   # …and real rock faces (Poly Haven) sit in front of them, darkened and lava-lit
		Models.place(self, "rock_face_01", Vector3(side * 14.0, -0.3, -11.5), (0.0 if side < 0 else PI) + side * 0.5, 3.0, false, cliff)
		Models.place(self, "rock_face_01", Vector3(side * 17.5, -0.3, -6.0), (0.0 if side < 0 else PI) + side * 1.2, 2.4, false, cliff * 0.9)
		Models.place(self, "rock_07", Vector3(side * 12.0, 0, -4.5), randf() * TAU, 20.0, true, cliff * Color(0.9, 0.85, 0.8))
	# burnt ground + dark rock patches over the path
	Models.patch(self, Vector3(0.5, 0, -2.0), Vector2(20, 28), "burned_ground_01", 2.5, Color(0.85, 0.72, 0.6), 0.0, 0.3)
	Models.patch(self, Vector3(-4.0, 0, -7.5), Vector2(8, 6), "dark_rock", 2.0, Color(0.75, 0.62, 0.52), 0.7, 0.45)
	Models.patch(self, Vector3(5.0, 0, 5.0), Vector2(7, 6), "dark_rock", 2.0, Color(0.75, 0.62, 0.52), 2.1, 0.45)
	# lava glow along the edges
	for p in [Vector3(-8, 0.5, -9), Vector3(8, 0.5, -8), Vector3(-7, 0.5, 4), Vector3(9, 0.5, 6)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.5, 0.2)
		l.light_energy = 1.1
		l.omni_range = 8.0
		l.position = p
		add_child(l)
		add_glow(p, Color(1.0, 0.55, 0.3), 7.0, func(): return 1.0)
	var rock_tint := Color(0.56, 0.4, 0.3)   # rock_07/09 textures are pale grey: tint them warm
	for k in 16:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(6.5, 13.0), 0, rng.randf_range(-11, 13))
		if p.x > 0 and abs(p.z) < 3.2:
			continue
		match k % 3:
			0: Models.place(self, "rock_07", p, rng.randf() * TAU, rng.randf_range(8.0, 13.0), true, rock_tint)
			1: Models.place(self, "rock_07", p, rng.randf() * TAU, rng.randf_range(7.0, 12.0), true, rock_tint)
			_: Models.place(self, "rock_09", p, rng.randf() * TAU, rng.randf_range(14.0, 22.0), true, rock_tint)
	# burnt logs + charred branches
	var burnt := Color(0.32, 0.25, 0.2)
	Models.place(self, "dead_tree_trunk_02", Vector3(-6.8, 0.1, 2.5), 0.5, 0.9, true, burnt)
	Models.place(self, "dead_tree_trunk_02", Vector3(7.4, 0.1, -3.6), 2.4, 0.8, true, burnt)
	for p in [Vector3(-3.5, 0, 6.5), Vector3(4.2, 0, 1.0), Vector3(-5.0, 0, -4.0), Vector3(3.0, 0, 9.5)]:
		Models.place(self, "dry_branches_medium_01", p, randf() * TAU, 1.1, false, burnt)
	_ash()
	_walls()
	card("campfire", 1.0, REST_POS)   # the rest spot
	var rest_light := OmniLight3D.new()
	rest_light.light_color = Color(1.0, 0.6, 0.3)
	rest_light.light_energy = 1.4
	rest_light.omni_range = 4.0
	rest_light.position = REST_POS + Vector3(0, 0.8, 0)
	add_child(rest_light)
	add_glow(REST_POS, Color(1.0, 0.6, 0.3), 3.5, func(): return 1.0)
	mattias = spawn_npc("mattias", "Metocin Mattias", "mattias", 1.95, Vector3(0, 0, 0.5))
	mattias.visible = false
	mattias.set_meta("tint", Color(0.75, 0.85, 1.15))
	mattias_light = OmniLight3D.new()
	mattias_light.light_color = Color(0.4, 0.6, 1.0)
	mattias_light.light_energy = 0.0
	mattias_light.omni_range = 5.0
	mattias_light.position = Vector3(0, 1.6, 1.2)
	add_child(mattias_light)
	giant = spawn_npc("giant", "Diddy Chud Giant", "giant_angry", 7.0, GIANT_STAND)
	giant.visible = false
	giant.walk_speed = 2.0
	if Game.flag("goblinAllies"):
		chief = spawn_npc("chief", "Chief Bogdrinker", "goblin_chief", 1.45, Vector3(0, 0, 14))
		chief.set_meta("follow", true)
		chief.set_meta("follow_i", 0)
		allies.append(chief)
		for i in 2:
			var g := spawn_npc("goblin", "Goblin", "goblin", rng.randf_range(1.1, 1.3), Vector3(rng.randf_range(-2, 2), 0, 15 + i))
			g.set_meta("follow", true)
			g.set_meta("follow_i", i + 1)
			allies.append(g)

# ================================================================ the canyon as a real 3D place (inspired by Ebain's paintings)
const GIANT_LIE := Vector3(1.6, 0, -10.2)          # where he's sleeping across the path
var giant_lying: Sprite3D

func _canyon() -> void:
	var rock := Color(0.6, 0.47, 0.38)    # warm sandstone (was near-black red)
	var rock2 := Color(0.56, 0.42, 0.32)
	# canyon walls: real rock faces stacked into tall dark cliffs on both sides and behind
	for i in 7:
		var z := -16.0 + i * 4.6
		for side in [-1.0, 1.0]:
			var x: float = side * (12.5 + randf_range(0.0, 2.5))
			if side > 0 and abs(z) < 4.0:
				continue   # the east exit
			var r := Models.place(self, "rock_face_01", Vector3(x, -0.5, z), (PI / 2.0 if side < 0 else -PI / 2.0) + randf_range(-0.4, 0.4), 1.0, false, rock if i % 2 == 0 else rock2)
			r.scale = Vector3(randf_range(1.6, 2.2), randf_range(2.4, 3.6), randf_range(1.6, 2.2))
			_no_shadow(r)
	for i in 6:   # the far wall behind the giant, with the path continuing up between spires
		var x := -14.0 + i * 5.6
		if abs(x - 1.0) < 2.5:
			continue
		var r := Models.place(self, "rock_face_01", Vector3(x, -0.5, -21.0 - randf_range(0, 3)), randf_range(-0.3, 0.3), 1.0, false, rock)
		r.scale = Vector3(2.0, randf_range(3.0, 4.6), 1.8)
		_no_shadow(r)
	for p in [Vector3(-7.5, 0, -15.5), Vector3(8.5, 0, -16.5), Vector3(-10.5, 0, -8.0), Vector3(11.0, 0, -9.0), Vector3(-3.5, 0, -19.0), Vector3(6.0, 0, -19.5)]:
		var sp := Models.place(self, "rock_07", p, randf() * TAU, 1.0, true, rock2)   # jagged spires
		sp.scale = Vector3(randf_range(9.0, 12.0), randf_range(26.0, 40.0), randf_range(6.0, 8.0))
		_no_shadow(sp)
	# lava: channels down both sides + a molten pool behind the giant
	_lava(Vector3(-9.6, 0.02, -2.0), Vector2(2.2, 26.0))
	_lava(Vector3(9.8, 0.02, -8.0), Vector2(2.0, 10.0))
	_lava(Vector3(9.8, 0.02, 8.5), Vector2(2.0, 9.0))
	_lava(Vector3(-2.0, 0.02, -15.5), Vector2(12.0, 3.0))
	_lava(Vector3(7.0, 0.02, -17.5), Vector2(6.0, 2.5))
	for p in [Vector3(-9.6, 0.6, -10), Vector3(-9.6, 0.6, 2), Vector3(9.8, 0.6, -8), Vector3(9.8, 0.6, 8), Vector3(-2, 0.8, -15.5), Vector3(7, 0.8, -17.5)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.45, 0.15)
		l.light_energy = 1.3
		l.omni_range = 7.5
		l.position = p
		add_child(l)
		add_glow(p, Color(1.0, 0.5, 0.25), 6.0, func(): return 1.0)
	# the sleeping giant, lying across the path (real 3D figure, not a painting)
	snore = AudioStreamPlayer.new()
	var snore_stream: AudioStreamOggVorbis = load("res://assets/sounds/giant_snore.ogg")
	snore_stream.loop = true
	snore.stream = snore_stream
	snore.volume_db = -60.0
	add_child(snore)
	snore.play()
	giant_lying = Sprite3D.new()
	giant_lying.texture = load("res://assets/characters/giant_sleep.png")   # Asar's sleeping picture (head on the right, rock pillow)
	giant_lying.pixel_size = 8.0 / giant_lying.texture.get_width()           # 8 m from feet to pillow
	giant_lying.shaded = false
	giant_lying.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	giant_lying.modulate = Color(1.0, 0.88, 0.84)
	giant_lying.position = GIANT_LIE + Vector3(0, giant_lying.texture.get_height() * giant_lying.pixel_size * 0.5 - 0.15, 0)
	add_child(giant_lying)
	Util.static_box(self, GIANT_LIE + Vector3(0, 1.5, 0), Vector3(6.6, 3.0, 2.0))
	for p in [Vector3(-1.8, 0, 0.9), Vector3(3.9, 0, 0.7), Vector3(-3.4, 0, -0.4), Vector3(5.2, 0, -0.6)]:   # rocks he's lying on
		Models.place(self, "rock_07", GIANT_LIE + p, randf() * TAU, randf_range(6.0, 9.0), false, rock2)
	if not Game.flag("giantDone"):   # coming back later: he's gone, no label
		char_label_at(GIANT_LIE + Vector3(0, 6.0, 0.4), "Diddy Chud Giant (Asleep) (Using a Rock as a Pillow)", 6.0)   # DRAFT (old art had his eyes open)

# Far scenery doesn't need to cast shadows (big savings on lower-end PCs).
func _no_shadow(n: Node) -> void:
	if n is GeometryInstance3D:
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadow(c)

func _lava(c: Vector3, size: Vector2) -> void:
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = LAVA_SHADER
	var pm := PlaneMesh.new()
	pm.size = size
	Util.add_mesh(self, pm, sm, c)

const LAVA_SHADER := """
shader_type spatial;
render_mode unshaded;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * n2(p); p *= 2.03; a *= 0.5; } return v; }
void fragment() {
	vec2 p = wpos.xz * 0.45;
	float flow = fbm(p + vec2(TIME * 0.04, TIME * 0.07));
	float crust = fbm(p * 1.7 - vec2(TIME * 0.02, 0.0) + flow);
	float hot = smoothstep(0.38, 0.62, flow + (crust - 0.5) * 0.6);
	vec3 col = mix(vec3(0.12, 0.03, 0.01), vec3(1.0, 0.36, 0.05), hot);
	col = mix(col, vec3(1.0, 0.85, 0.35), smoothstep(0.75, 0.95, hot * flow * 1.4));
	vec2 e = abs(UV - 0.5) * 2.0;
	float edge = smoothstep(0.75, 1.0, max(e.x, e.y) + (n2(wpos.xz * 1.3) - 0.5) * 0.3);
	ALBEDO = mix(col * 1.4, vec3(0.08, 0.04, 0.03), edge);
}
"""

var _giant_block_cleared := false
func _clear_giant_block() -> void:
	# the collider he was lying on goes away once he's up or rolled off
	if _giant_block_cleared:
		return
	_giant_block_cleared = true
	for c in get_children():
		if c is StaticBody3D and c.get_child_count() > 0 and c.get_child(0) is CollisionShape3D:
			var cs: CollisionShape3D = c.get_child(0)
			if cs.global_position.distance_to(GIANT_LIE + Vector3(0, 1.5, 0)) < 0.2:
				c.queue_free()

func _ash() -> void:
	var a := CPUParticles3D.new()
	a.amount = 120
	a.lifetime = 8.0
	a.mesh = Fx.quad(0.06, true)
	a.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	a.emission_box_extents = Vector3(16, 0.5, 14)
	a.direction = Vector3.UP
	a.spread = 30.0
	a.gravity = Vector3(0.15, 0.25, 0)
	a.initial_velocity_min = 0.2
	a.initial_velocity_max = 0.6
	a.color_ramp = Fx.ramp([[0.0, Color(1, 0.5, 0.2, 0)], [0.2, Color(1, 0.55, 0.25, 1)], [1.0, Color(0.5, 0.2, 0.1, 0)]])
	a.position = Vector3(0, 0.5, 0)
	add_child(a)

func _walls() -> void:
	Util.static_box(self, Vector3(-9.5, 1, 0.5), Vector3(0.5, 2, 26))
	Util.static_box(self, Vector3(9.5, 1, -6.8), Vector3(0.5, 2, 9.6))
	Util.static_box(self, Vector3(9.5, 1, 7.6), Vector3(0.5, 2, 10.8))
	Util.static_box(self, Vector3(0, 1, -12.0), Vector3(19, 2, 0.5))
	Util.static_box(self, Vector3(0, 1, 13.5), Vector3(19, 2, 0.5))
	Util.static_box(self, Vector3(13.5, 1, -2.4), Vector3(9, 2, 0.5))
	Util.static_box(self, Vector3(13.5, 1, 2.4), Vector3(9, 2, 0.5))
	Util.static_box(self, Vector3(18, 1, 0), Vector3(0.5, 2, 5))

# ---------------------------------------------------------------- per frame
# Snore volume: quiet down the path, loud right next to his head (based on the character you control)
const SNORE_NEAR := 3.0    # m from his head: loudest
const SNORE_FAR := 20.0    # m: silent (Asar: quiet from far away, only loud up close)
const SNORE_MAX_DB := -9.0 # loudest it gets (Asar: generally quieter)
func _update_snore(delta: float) -> void:
	if snore == null:
		return
	var asleep := not giant_awake and stage != "after" and stage != "end"
	var target := -60.0
	if asleep and snore_sneak:
		target = SNORE_MAX_DB + 4.0   # Snore Sneak: you're on top of him, a bit louder so you can hear the rhythm
	elif asleep and leader:
		var d := Vector2(leader.global_position.x - GIANT_HEAD.x, leader.global_position.z - GIANT_HEAD.z).length()
		var near := clampf(1.0 - (d - SNORE_NEAR) / (SNORE_FAR - SNORE_NEAR), 0.0, 1.0)
		target = linear_to_db(maxf(near * near * near, 0.001)) + SNORE_MAX_DB   # cubed: faint until you're close, then it ramps up
	snore.volume_db = move_toward(snore.volume_db, target, delta * 40.0)
	if not asleep and snore.volume_db <= -59.0 and snore.playing:
		snore.stop()

func _level_process(delta: float) -> void:
	_update_snore(delta)
	if not giant_awake and stage != "after" and stage != "end":
		zzz_timer -= delta
		if zzz_timer <= 0.0:
			zzz_timer = 1.3
			_zzz()
	if busy:
		return
	if stage == "enter" and leader.global_position.z < 5.0:
		stage = "mattias"
		_mattias()
	elif stage == "mattias" and leader.global_position.z < -3.5:
		stage = "giant"
		_giant_scene()
	elif stage == "after" and leader.global_position.distance_to(EXIT_POS) < 3.0:
		stage = "end"
		var lines := ["END OF CHAPTER 1", "", "Trio Adventures — by Ebain", ""]
		lines += story_so_far()
		lines += ["", "Chapter 2 coming soon. Thanks for playing!", "", "Press E to return to the title screen"]
		end_card(lines, "res://title.tscn")

func _zzz() -> void:
	var l := Label3D.new()
	l.text = "Z" if rng.randf() < 0.6 else "z"
	l.font_size = 90
	l.pixel_size = 0.012
	l.outline_size = 12
	l.no_depth_test = true
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1, 1, 1, 0.9)
	l.position = GIANT_HEAD + Vector3(rng.randf_range(-0.5, 0.5), 0, 0.2)
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position", l.position + Vector3(1.5, 2.5, 0), 2.4)
	tw.tween_property(l, "modulate:a", 0.0, 2.4)
	tw.chain().tween_callback(l.queue_free)

# maps: Diddy Chud Giant is a big pulsing star (Asar), asleep across the path or standing once he's up
func map_extra() -> Array:
	if not giant_awake:
		return [{ "pos": GIANT_LIE + Vector3(1.0, 0, 0), "kind": "giant", "name": "Diddy Chud Giant (asleep)" }]
	if giant and is_instance_valid(giant) and giant.visible:
		return [{ "pos": giant.global_position, "kind": "giant", "name": "Diddy Chud Giant" }]
	return []

func map_skip(u: Unit) -> bool:
	return u == giant

const REST_POS := Vector3(-4.6, 0, 8.6)   # an abandoned campfire just inside the pass (Asar: heal before the giant)

func _level_interactables() -> Array:
	return [{ "id": "rest_fire", "label": "the campfire", "verb": "Rest at", "pos": REST_POS, "h": 1.2, "r": 2.2, "rest": true, "steps": [
	] }]

# ---------------------------------------------------------------- story
func _begin() -> void:
	busy = true
	fade_in(1.5)
	await wait(0.8)
	await run_dialogue(PS.INTRO)
	objective("Head up the pass.", Vector3(1.0, 0, -5.0))

func _mattias() -> void:
	focus_override = leader.global_position + Vector3(0.8, 0, -1.0)
	zoom = 7.5
	cam_look_h = 1.2
	await run_dialogue(PS.MATTIAS)
	focus_override = null
	zoom = 11.0
	cam_look_h = 2.8
	objective("Get past the giant.", EXIT_POS)

func _giant_scene() -> void:
	focus_override = Vector3(1.5, 0, -6.0)
	await run_dialogue(PS.GIANT)

func _on_action(n: String) -> void:
	match n:
		"mattias_appears":
			mattias.global_position = leader.global_position + Vector3(2.2, 0, -1.6)
			mattias_light.global_position = mattias.global_position + Vector3(0, 1.6, 0.7)
			mattias.visible = true
			_poof(mattias.global_position, Color(0.5, 0.7, 1.0))
			whoosh_sfx.play()
			create_tween().tween_property(mattias_light, "light_energy", 3.0, 0.5)
			char_label(mattias, "Metocin Mattias (Out of Nowhere)", 3.5, 2.4, Color("#9cc4ff"))
			await wait(0.8)
		"mattias_vanish":
			_poof(mattias.global_position, Color(0.5, 0.7, 1.0))
			whoosh_sfx.play()
			mattias.visible = false
			create_tween().tween_property(mattias_light, "light_energy", 0.0, 0.6)
			await wait(0.7)
		"to_giant":
			follow_enabled = false
			for i in party.size():
				party[i].set_meta("goal", Vector3(-1.5 + i * 1.6, 0, -5.5 + (i % 2) * 0.7))
				party[i].set_meta("goal_speed", 0.8)
			for i in allies.size():
				allies[i].remove_meta("follow")
				allies[i].set_meta("goal", Vector3(-4.5 + i * 1.0, 0, -3.5))
				allies[i].set_meta("goal_speed", 0.8)
			char_label_at(GIANT_HEAD + Vector3(-2.5, -1.2, 0), "Diddy Chud Giant (Asleep, In The Way)", 4.0)
			await wait(1.4)
			for u in party + allies:
				u.remove_meta("goal")
		"throw_midtocy":
			Game.set_flag("hasMidtocy", false)
			await _throw_midtocy()
		"giant_wakes":
			await _giant_wakes(true)
		"giant_wakes_calm":
			await _giant_wakes(false)
		"giant_trip":
			giant_mood = "tripping"
			giant.set_meta("tint", Color(1.15, 0.85, 1.25))
			char_label(giant, "Diddy Chud Giant (Geeked)", 3.5, 7.4, Color("#c79bff"))
			hop(giant, 0.4)
			await wait(0.5)
		"fight_giant":
			await _fight_giant()
		"giant_leaves":
			giant.set_meta("goal", Vector3(-16, 0, -10))
			giant.set_meta("goal_speed", 1.0)
			await wait(2.5)
			giant.visible = false
			giant.remove_meta("goal")
		"sneak_game":
			var won := await _sneak_game()
			Game.set_flag("sneakWon", won)
			if not won:
				giant_mood = "enraged"
		"steal_bowls":
			Game.add_item("bowl", 2, "skorn")
			ui_sfx.play()
			show_toast("Skorn got: Chipotle Bowl ×2 (heals 60)")
			await wait(0.6)
		"lore_game":
			Game.set_flag("loreWon", await _lore_game())
		"giant_rolls_over":
			shake = 0.5
			whoosh_sfx.pitch_scale = 0.5
			whoosh_sfx.play()
			await fade_out(0.5)
			giant_lying.position += Vector3(7.5, 0, -3.0)   # rolls off into the rocks
			giant_lying.rotation.z = -0.25
			_clear_giant_block()
			giant_awake = true    # stops the Zzz (he's rolled off the path)
			fade_in(0.6)
			await wait(0.7)
			whoosh_sfx.pitch_scale = 1.0
		"skorn_slaps_giant":
			var sk := party[0]
			await walk_to(sk, Vector3(3.0, 0, -9.0), 1.4, 3.0)
			_sfx(Util.noise_burst(110, 0.6, 1.0), 0.0).play()
			shake = 0.5
			char_label_at(GIANT_HEAD + Vector3(-1, 0, 0), "*SLAP*", 1.5, Color("#ffdf4a"))
			await wait(0.6)
		"mattias_voice":
			var flash := OmniLight3D.new()
			flash.light_color = Color(0.4, 0.6, 1.0)
			flash.light_energy = 0.0
			flash.omni_range = 14.0
			flash.position = Vector3(0, 4, -8)
			add_child(flash)
			var tw := create_tween()
			tw.tween_property(flash, "light_energy", 4.0, 0.5)
			tw.tween_property(flash, "light_energy", 0.0, 1.5)
			tw.tween_callback(flash.queue_free)
			char_label_at(Vector3(0, 4.5, -10), "(a voice, echoing from further up the path)", 3.5, Color("#9cc4ff"))
			await wait(0.6)
		"leave":
			_leave()

func char_label_at(p: Vector3, text: String, secs := 3.0, color := Color("#f3e3b0")) -> void:
	var n := Node3D.new()
	n.position = p
	add_child(n)
	var l := char_label(n, text, secs, 0.0, color)
	l.pixel_size = 0.016
	if secs > 0.0:
		get_tree().create_timer(secs + 0.6).timeout.connect(n.queue_free)

func _poof(p: Vector3, color := Color(0.8, 0.7, 0.6)) -> void:
	var f := Fx.poof(color)
	f.position = p + Vector3(0, 0.6, 0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)

func _throw_midtocy() -> void:
	var m := Sprite3D.new()
	m.texture = load("res://assets/items/midtocy.png")
	m.pixel_size = 0.5 / 792.0
	m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	m.shaded = false
	add_child(m)
	m.global_position = party[0].global_position + Vector3(0.4, 1.8, 0)
	var mid := m.global_position.lerp(GIANT_HEAD, 0.5) + Vector3(0, 3.0, 0)
	_sfx(Util.noise_burst(300, 0.08, 0.7), -4.0).play()
	var tw := create_tween()
	tw.tween_property(m, "global_position", mid, 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "global_position", GIANT_HEAD, 0.4).set_ease(Tween.EASE_IN)
	await tw.finished
	m.queue_free()
	char_label_at(GIANT_HEAD + Vector3(-1, 0.5, 0), "*bonk*", 1.5, Color("#c79bff"))
	shake = 0.3
	await wait(0.5)

# Wake-up, no cut to black: he stirs, sits up (sitting picture), then rises into the standing giant.
func _giant_wakes(angry: bool) -> void:
	giant_awake = true
	_clear_giant_block()
	focus_override = Vector3(1.5, 0, -6.0)
	zoom = 13.0
	# 1. stirs
	shake = 0.35 if angry else 0.15
	_sfx(Util.noise_burst(260, 0.4, 0.5), -4.0).play()
	var tw := create_tween()
	tw.tween_property(giant_lying, "rotation:z", 0.05, 0.12)
	tw.tween_property(giant_lying, "rotation:z", -0.04, 0.12)
	tw.tween_property(giant_lying, "rotation:z", 0.0, 0.1)
	await tw.finished
	# 2. sits up
	var sit := Sprite3D.new()
	sit.texture = load("res://assets/characters/giant_sit.png")
	sit.pixel_size = 4.8 / sit.texture.get_height()
	sit.shaded = false
	sit.modulate = Color(1.0, 0.88, 0.84, 0.0)
	sit.position = Vector3((GIANT_LIE.x + GIANT_STAND.x) * 0.5, 2.4, GIANT_LIE.z + 0.1)
	add_child(sit)
	giant_lying.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED   # so it can fade
	tw = create_tween().set_parallel(true)
	tw.tween_property(giant_lying, "modulate:a", 0.0, 0.35)
	tw.tween_property(sit, "modulate:a", 1.0, 0.3)
	tw.tween_property(sit, "position:y", 2.6, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	giant_lying.visible = false
	await wait(0.45 if angry else 0.7)
	# 3. stands up
	_sfx(Util.noise_burst(900, 0.03, 1.0), 0.0).play()
	giant.global_position = GIANT_STAND
	giant.sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	giant.sprite.scale = Vector3(1.0, 0.7, 1.0)   # grows up from the ground (sprite is anchored at the feet)
	giant.set_meta("tint", Color(1, 1, 1, 0))
	giant.visible = true
	tw = create_tween().set_parallel(true)
	tw.tween_method(func(a: float): giant.set_meta("tint", Color(1, 1, 1, a)), 0.0, 1.0, 0.3)
	tw.tween_property(sit, "modulate:a", 0.0, 0.3)
	tw.tween_property(giant.sprite, "scale:y", 1.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	sit.queue_free()
	giant.sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	giant.set_meta("tint", Color.WHITE)
	hop(giant, 0.8)
	shake = 0.8 if angry else 0.2
	if angry:
		char_label(giant, "Diddy Chud Giant (Awake, Disturbed)", 3.5, 7.4, Color("#ff8a6a"))
	else:
		char_label(giant, "Diddy Chud Giant (Awake, Confused)", 3.5, 7.4)
	await wait(0.9)

func _fight_giant() -> void:
	# A: he's tripping on the midtocy · B: you woke him up mid-sneak, he's ENRAGED · C/D: just disturbed
	var mods := {}
	if giant_mood == "tripping":
		mods["enemy_tripping"] = true
	elif giant_mood == "enraged":
		mods["enraged"] = true
	await fight("giant", { "enemies": [giant], "mods": mods })
	giant.set_meta("tint", Color.WHITE)

func _leave() -> void:
	Game.set_flag("giantDone")   # the pass is open: you can walk back to the Mart and return (Asar)
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	zoom = 11.0
	for g in allies:
		g.remove_meta("goal")
		g.set_meta("follow", true)
	objective("Climb on past the giant.", EXIT_POS)

# ---------------------------------------------------------------- coming back later (Game.travel / saves)
func can_resume() -> bool:
	return stage == "after"

func can_resume_saved() -> bool:
	return Game.flag("giantDone")

func _resume(r: Dictionary) -> void:
	giant_awake = true          # no snoring, no Zzz
	giant_lying.visible = false # he's gone home (or he's sulking somewhere else)
	giant.visible = false
	mattias.visible = false
	_clear_giant_block()
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	zoom = 11.0
	objective("Climb on past the giant.", EXIT_POS)
	await super._resume(r)
	for i in allies.size():
		allies[i].visible = true
		allies[i].set_meta("follow", true)
		allies[i].global_position = leader.global_position + Vector3(-1.2 + i * 0.8, 0, 1.6)

func back_exit() -> Dictionary:
	if stage == "after":
		return { "pos": Vector3(0, 0, 12.6), "r": 1.9, "scene": "res://mart.tscn", "name": "Metocy Mart" }
	return {}

func arrival(from: String) -> Array:
	if from == "mart":
		return [Vector3(0, 0, 8.0), Vector3(0, 0, -1)]
	return super.arrival(from)

# ---------------------------------------------------------------- minigame UI helpers
func _panel(top: float, height: float, width := 760.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.offset_left = -width / 2.0; panel.offset_right = width / 2.0
	panel.offset_top = top; panel.offset_bottom = top + height
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.11, 0.94)
	sb.border_color = Color("#e8b923")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 24; sb.content_margin_right = 24; sb.content_margin_top = 16; sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	hud.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	return col

func _bar(col: VBoxContainer, label: String, color: Color) -> ProgressBar:
	col.add_child(_label(label, Vector2.ZERO, 17, color, 5))
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(0, 22)
	pb.max_value = 100
	pb.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	pb.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	bg.set_corner_radius_all(6)
	pb.add_theme_stylebox_override("background", bg)
	col.add_child(pb)
	return pb

func _input(ev: InputEvent) -> void:
	if not mini_running:
		return
	if mini_opts.size() > 0:
		if ev.is_action_pressed("move_forward") or ev.is_action_pressed("ui_up"):
			mini_sel = (mini_sel + mini_opts.size() - 1) % mini_opts.size()
			_render_opts()
		elif ev.is_action_pressed("move_back") or ev.is_action_pressed("ui_down"):
			mini_sel = (mini_sel + 1) % mini_opts.size()
			_render_opts()
		elif ev.is_action_pressed("interact"):
			mini_pick = mini_sel
		get_viewport().set_input_as_handled()

# ---- B: Snore Sneak — hold E/Space ONLY while he snores
func _sneak_game() -> bool:
	dialogue.hide_box()
	var col := _panel(24, 230)
	var title := _label("SNORE SNEAK", Vector2.ZERO, 34, Color("#ffcf4a"), 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var help := _label("Hold E / SPACE to sneak across him — ONLY while he snores", Vector2.ZERO, 18, Color.WHITE, 5)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(help)
	var cue := _label("", Vector2.ZERO, 30, Color("#7dff8a"), 7)
	cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(cue)
	var prog_bar := _bar(col, "Progress:  Legs → Belly (Squishy) → Arm (Hairy)", Color("#7dcf5a"))
	var heat_bar := _bar(col, "Snore Meter (fill it and he wakes up)", Color("#ff5a3a"))
	mini_running = true
	var prog := 0.0
	var heat := 0.0
	var phase := "snore"
	var phase_t := 1.6
	snore_sneak = true   # the real snore, loud, and it stops while he inhales
	var grace := 0.0
	var won := false
	var start_pos := []
	for u in party:
		start_pos.append(u.global_position)
	await wait(1.0)
	while true:
		await get_tree().process_frame
		var d := get_process_delta_time()
		phase_t -= d
		grace = max(0.0, grace - d)
		if phase_t <= 0.0:
			var sec := int(prog / 34.0)
			if phase == "snore":
				phase = "inhale"
				phase_t = rng.randf_range(0.8, 1.4)
				snore.stream_paused = true
			else:
				phase = "snore"
				phase_t = rng.randf_range(1.0, 1.9) / (1.0 + sec * 0.25)
				snore.stream_paused = false
				_zzz()
			grace = 0.18
		var holding := Input.is_action_pressed("interact")
		if shots_mode:
			holding = phase == "snore" and phase_t > 0.15
		if phase == "snore":
			cue.text = "ZZZ… SNORING — GO!" if phase_t > 0.45 else "zzz… (slowing down)"
			cue.add_theme_color_override("font_color", Color("#7dff8a") if phase_t > 0.45 else Color("#ffd84a"))
			if holding:
				prog += d * 24.0
		else:
			cue.text = "…inhale… FREEZE"
			cue.add_theme_color_override("font_color", Color("#ff6a5a"))
			if holding and grace <= 0.0:
				heat += d * 70.0
		heat = max(0.0, heat - d * 4.0)
		prog_bar.value = prog
		heat_bar.value = heat
		for i in party.size():
			party[i].global_position = start_pos[i].lerp(Vector3(start_pos[i].x + 4.0, 0, -9.0), prog / 100.0)
		if prog >= 100.0:
			won = true
			break
		if heat >= 100.0:
			break
	mini_running = false
	cue.text = "MADE IT ACROSS!" if won else "…he felt that."
	await wait(1.2)
	col.get_parent().queue_free()
	if won:
		for i in party.size():
			party[i].global_position = Vector3(5.0 + i * 1.3, 0, -8.0)
	dialogue.show_box()
	snore_sneak = false
	snore.stream_paused = false
	return won

# ---- C: Lore Session — pick how each page truly continues. One wrong answer and he knows.
func _lore_game() -> bool:
	dialogue.hide_box()
	var won := true
	for k in PS.LORE.size():
		var L: Dictionary = PS.LORE[k]
		var col := _panel(40, 560, 900)
		var head := _label("DELOYE LORE · Page %d of %d · %s" % [k + 1, PS.LORE.size(), L["where"]], Vector2.ZERO, 16, Color("#a49cc4"), 4)
		col.add_child(head)
		var title := _label(L["title"], Vector2.ZERO, 30, Color("#ffd27a"), 6)
		col.add_child(title)
		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.fit_content = true
		body.scroll_active = false
		body.custom_minimum_size = Vector2(850, 0)
		body.add_theme_font_size_override("normal_font_size", 19)
		body.add_theme_font_size_override("italics_font_size", 19)
		body.text = "[i]%s[/i]" % L["text"]
		col.add_child(body)
		col.add_child(_label("How does it truly continue?  (W/S to choose, E to read it aloud)", Vector2.ZERO, 16, Color("#e8b923"), 4))
		var opts: Array = [L["right"]] + L["wrong"]
		opts.shuffle()
		mini_opts = opts
		mini_labels = []
		for o in opts:
			var l := _label("", Vector2.ZERO, 19, Color.WHITE, 4)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(850, 0)
			col.add_child(l)
			mini_labels.append(l)
		mini_sel = 0
		mini_pick = -1
		_render_opts()
		mini_running = true
		while mini_pick < 0:
			await get_tree().process_frame
			if shots_mode:
				await wait(0.8)
				mini_pick = opts.find(L["right"])
		mini_running = false
		var correct: bool = opts[mini_pick] == L["right"]
		mini_labels[mini_pick].add_theme_color_override("font_color", Color("#7dff8a") if correct else Color("#ff6a5a"))
		mini_opts = []
		await wait(0.9)
		col.get_parent().queue_free()
		if not correct:
			won = false
			break
		_zzz()
		show_toast("He sinks deeper into sleep… (%d / %d)" % [k + 1, PS.LORE.size()], 1.0)
		await wait(0.6)
	dialogue.show_box()
	return won

func _render_opts() -> void:
	for i in mini_labels.size():
		mini_labels[i].text = ("> " if i == mini_sel else "   ") + mini_opts[i]
		mini_labels[i].add_theme_color_override("font_color", Color("#e8b923") if i == mini_sel else Color.WHITE)

# ---------------------------------------------------------------- automated screenshots (PASS_CHOICE=0..4)
func _shot_tour() -> void:
	var choice := int(OS.get_environment("PASS_CHOICE")) if OS.get_environment("PASS_CHOICE") != "" else 3
	Game.set_flag("hasMidtocy")
	if choice == 4:
		Game.set_flag("goblinAllies")
	var tag := "abcde"[choice]
	fade.color.a = 0.0
	busy = false
	await wait(1.5)
	await shot("p_01_enter")
	if OS.get_environment("PERF") != "":
		print("PERF prims=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME), " fps=", Engine.get_frames_per_second())
	place_party(Vector3(0, 0, 4.0), Vector3(0, 0, -1))
	await wait(1.6)
	await advance(1)
	await wait(1.0)
	await shot("p_02_mattias")
	await advance(4)
	await wait(1.5)
	place_party(Vector3(0, 0, -4.0), Vector3(0, 0, -1))
	await wait(2.5)
	await shot("p_03_giant")
	await advance(3)
	await wait(1.0)
	await shot("p_04_choice")
	dialogue._picked.emit(min(choice, dialogue._choices.size() - 1))
	await wait(1.0)
	var action_shot := false
	for k in 24:
		await advance(1, 0.7)
		if k == 3:
			await shot("p_05_%s_mid" % tag)
		if not action_shot and not dialogue.panel.visible and dialogue.active:
			action_shot = true
			await wait(3.0)
			await shot("p_06_%s_action" % tag)
			await wait(8.0)
		if k == 9:
			await shot("p_07_%s_late" % tag)
	await wait(2.0)
	await shot("p_08_%s_after" % tag)
	place_party(EXIT_POS + Vector3(-2.5, 0, 0), Vector3(1, 0, 0))
	await wait(3.0)
	await shot("p_09_%s_end" % tag)
	get_tree().quit()
