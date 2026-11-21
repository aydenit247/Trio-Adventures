# Shared engine for every area (camp, goblin village, ...). An area script extends this and fills in:
#   _configure()            time of day, ground clearing/paths, who's in the party and where they start
#   _build_level()          props, NPCs, lights (use card(), spawn_npc(), add_glow())
#   _level_interactables()  things you can press E on (Array of dicts)
#   _on_action(name)        what a dialogue { "do": name } step does
#   _level_process(delta)   per-frame area logic (triggers, NPC behavior)
#   _begin()                what happens when the area loads (intro)
#   _shot_tour()            automated screenshot run for testing (godot ... -- --shots)
#
# Controls: WASD walk · Shift run · E/Space talk · Tab switch who you control
#           ←/→ or right-mouse drag turn the camera · mouse wheel zoom · V voices on/off
extends Node3D
class_name Level

const CHAR_HEIGHT := { "skorn": 1.95, "lykor": 1.9, "xylo": 1.95 }
const CHAR_NAME := { "skorn": "Skorn", "lykor": "Lykor", "xylo": "Xylo" }

# ---- configuration (set in _configure)
var night := true
var lava := false               # volcanic mood (the Pass): red light, ash, burnt ground
var light_dir := Vector3(-0.45, 0.32, -0.83)   # direction TOWARD the moon/sun
var clear_center := Vector2.ZERO
var clear_radius := 6.5
var path_pts := PackedVector2Array()
var path_width := 1.6
var party_ids: Array = ["skorn", "lykor", "xylo"]
var party_start: Array = []
var leader_id := "skorn"
var subtitle := ""
var talk := {}                  # id -> dialogue steps when you talk to that party member

# ---- runtime
var rng := RandomNumberGenerator.new()
var party: Array[Unit] = []
var leader: Unit
var npcs: Array[Unit] = []
var dialogue: Dialogue
var cam: Camera3D
var cam_target := Vector3.ZERO
var focus_override = null
var yaw := 0.0
var target_yaw := 0.0
var zoom := 8.0
var t := 0.0
var busy := false
var interact_cooldown := 0.0
var follow_enabled := true
var switch_enabled := true
var walk_mult := 1.0
var prompt: Label3D
var step_sfx: AudioStreamPlayer
var ui_sfx: AudioStreamPlayer
var whoosh_sfx: AudioStreamPlayer
var fade: ColorRect
var leader_lbl: Label
var leader_por: TextureRect
var toast: Label
var objective_lbl: Label
var help_lbl: Label
var hud: CanvasLayer
var shake := 0.0
var auto_dir := Vector3.ZERO
var cards: Array = []           # [material, position, dynamic]
var glows: Array = []           # light sources that tint the cutouts
var shots_mode := false
var cam_locked := false         # stage-set rooms (painted backdrops) keep the camera facing them
var cam_height := 0.6           # camera height as a fraction of zoom (lower = flatter view)
var cam_look_h := 1.1           # how high above the leader the camera aims
var _tex_cache := {}

func _ready() -> void:
	rng.seed = 7
	_configure()
	_setup_input()
	_build_environment()
	_build_ground()
	_build_level()
	_build_party()
	_build_ui()
	_after_build()
	_show_forehead()
	cam_target = leader.global_position
	_update_camera(1.0)
	var args := OS.get_cmdline_user_args()
	shots_mode = "--shots" in args
	dialogue.tts_on = Game.tts_on and not shots_mode
	if "--views" in args:
		_views_tour()
	elif shots_mode and OS.get_environment("FIGHT") != "":
		_fight_tour(OS.get_environment("FIGHT"))
	elif shots_mode:
		_shot_tour()
	else:
		_begin()

# ---------------------------------------------------------------- hooks (override in area scripts)
func _configure() -> void: pass
func _build_level() -> void: pass
func _after_build() -> void: pass
func _begin() -> void: fade_in()
func _shot_tour() -> void: get_tree().quit()
func _level_interactables() -> Array: return []
func _on_action(_n: String) -> void: pass
func _level_process(_delta: float) -> void: pass

func do_action(n: String) -> void:
	await _on_action(n)

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
	_key("party_menu", [KEY_I])
	_key("pause", [KEY_ESCAPE])

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - 0.6, 5.0, 15.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + 0.6, 5.0, 15.0)
	if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_RIGHT) and not cam_locked:
		target_yaw -= ev.relative.x * 0.006

# ---------------------------------------------------------------- environment
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = SKY_SHADER
	sm.set_shader_parameter("light_dir", light_dir.normalized())
	sm.set_shader_parameter("night", 1.0 if night else 0.0)
	sm.set_shader_parameter("lava", 1.0 if lava else 0.0)
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_bloom = 0.08
	env.fog_enabled = true
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = true           # Forward+ only
	env.ssao_enabled = true
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.1
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	if night:
		env.ambient_light_color = Color(0.22, 0.26, 0.45)
		env.ambient_light_energy = 0.75
		env.tonemap_exposure = 1.25
		env.glow_intensity = 0.9
		env.glow_hdr_threshold = 0.9
		env.fog_light_color = Color(0.05, 0.06, 0.11)
		env.fog_density = 0.02
		env.volumetric_fog_density = 0.012
		env.volumetric_fog_albedo = Color(0.6, 0.65, 0.8)
		sun.light_color = Color(0.6, 0.7, 1.0)
		sun.light_energy = 0.8
	else:
		env.ambient_light_color = Color(0.62, 0.66, 0.72)
		env.ambient_light_energy = 0.9
		env.tonemap_exposure = 1.0
		env.glow_intensity = 0.5
		env.glow_hdr_threshold = 1.2
		env.fog_light_color = Color(0.62, 0.68, 0.66)
		env.fog_density = 0.012
		env.volumetric_fog_density = 0.008
		env.volumetric_fog_albedo = Color(0.9, 0.9, 0.85)
		sun.light_color = Color(1.0, 0.93, 0.8)
		sun.light_energy = 1.5
	if lava:
		env.ambient_light_color = Color(0.55, 0.22, 0.12)
		env.ambient_light_energy = 0.8
		env.fog_light_color = Color(0.22, 0.07, 0.03)
		env.fog_density = 0.025
		env.volumetric_fog_albedo = Color(0.9, 0.5, 0.3)
		sun.light_color = Color(1.0, 0.45, 0.2)
		sun.light_energy = 0.9
	we.environment = env
	add_child(we)
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -light_dir.normalized(), Vector3.UP)

func _build_ground() -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(220, 1, 220)
	cs.shape = bs
	cs.position.y = -0.5
	body.add_child(cs)
	add_child(body)
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
	mat.set_shader_parameter("clear_center", clear_center)
	mat.set_shader_parameter("clear_radius", clear_radius)
	var pts := PackedVector2Array(path_pts)
	while pts.size() < 12:
		pts.append(pts[pts.size() - 1] if pts.size() > 0 else Vector2(999, 999))
	mat.set_shader_parameter("path_pts", pts)
	mat.set_shader_parameter("path_n", path_pts.size())
	mat.set_shader_parameter("path_w", path_width)
	mat.set_shader_parameter("brightness", 0.8 if night else 0.88)
	mat.set_shader_parameter("dirt_tint", Color(1, 1, 1) if night else Color(0.74, 0.64, 0.52))
	if lava:
		mat.set_shader_parameter("dirt_tint", Color(0.42, 0.33, 0.3))
		mat.set_shader_parameter("grass_tint", Color(0.3, 0.2, 0.16))
	Util.add_mesh(self, pm, mat, Vector3.ZERO)

# ---------------------------------------------------------------- props & lighting
# A cutout card of Ebain's art standing in the world (billboard, like the characters).
func card(name: String, height: float, pos: Vector3, flip := false, fade_near := false, collide_r := 0.0, folder := "props", tint := Color.WHITE) -> StandardMaterial3D:
	var key := folder + "/" + name
	if not _tex_cache.has(key):
		_tex_cache[key] = load("res://assets/%s/%s.png" % [folder, name])
	var tex: Texture2D = _tex_cache[key]
	var w := height * tex.get_width() / float(tex.get_height())
	var q := QuadMesh.new()
	q.size = Vector2(w, height)
	q.center_offset = Vector3(0, height / 2.0 - height * 0.03, 0)
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
	if fade_near:
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
		m.distance_fade_min_distance = 5.5
		m.distance_fade_max_distance = 10.0
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	var dynamic := false
	for g in glows:
		if pos.distance_to(g["pos"]) < g["radius"] + 3.0:
			dynamic = true
	var base := light_at(pos + Vector3(0, 0.5, 0)) if not dynamic else Color.WHITE
	if not night and not dynamic:
		base = Color(0.96, 0.95, 0.9)
	elif night and not dynamic and pos.length() > 15.0:
		base = Color(0.42, 0.47, 0.68)
	m.albedo_color = base * tint
	cards.append([m, pos, dynamic, tint])
	if collide_r > 0.0:
		Util.static_cyl(self, pos, collide_r)
	return m

# A painted backdrop (Ebain's background art) standing upright like a stage set. Faces +Z (toward the camera).
func backdrop(path: String, width: float, pos: Vector3, tint := Color.WHITE) -> StandardMaterial3D:
	var tex: Texture2D = load(path)
	var h := width * tex.get_height() / float(tex.get_width())
	var q := QuadMesh.new()
	q.size = Vector2(width, h)
	q.center_offset = Vector3(0, h / 2.0, 0)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.disable_fog = true
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return m

# A light that tints nearby cutouts (cutouts are unshaded, so this is how they get lit).
# strength: Callable returning 0..1+ (e.g. the fire's flicker)
func add_glow(pos: Vector3, color: Color, radius: float, strength: Callable, strong := false) -> void:
	glows.append({ "pos": pos, "color": color, "radius": radius, "strength": strength, "strong": strong })

func light_at(p: Vector3) -> Color:
	var col := Color(0.5, 0.56, 0.8) if night else Color(1.0, 0.97, 0.92)
	if lava:
		col = Color(0.9, 0.55, 0.42)
	for g in glows:
		var f: float = clamp(1.0 - p.distance_to(g["pos"]) / g["radius"], 0.0, 1.0)
		f = f * f * float(g["strength"].call())
		if g["strong"]:
			col = col.lerp(g["color"], clamp(f * 1.3, 0.0, 1.0)) + g["color"] * 0.35 * f
		else:
			col += g["color"] * 0.3 * f
	return Color(min(col.r, 1.25), min(col.g, 1.2), min(col.b, 1.2))

# ---------------------------------------------------------------- characters
func make_unit(id: String, display: String, tex_path: String, h: float, pos: Vector3) -> Unit:
	var u := Unit.new()
	add_child(u)
	u.setup(id, display, load(tex_path), h)
	u.global_position = pos
	return u

func _build_party() -> void:
	for i in party_ids.size():
		var id: String = party_ids[i]
		var pos: Vector3 = party_start[i] if i < party_start.size() else Vector3(i * 1.2, 0, 3)
		var u := make_unit(id, CHAR_NAME[id], "res://assets/characters/%s.png" % id, CHAR_HEIGHT[id], pos)
		u.stepped.connect(_on_step.bind(u))
		party.append(u)
	var first := party[0]
	for u in party:
		if u.id == leader_id:
			first = u
	set_leader(first)

func spawn_npc(id: String, display: String, tex: String, h: float, pos: Vector3) -> Unit:
	var u := make_unit(id, display, "res://assets/characters/%s.png" % tex, h, pos)
	npcs.append(u)
	return u

func add_to_party(id: String, pos: Vector3) -> Unit:
	var u := make_unit(id, CHAR_NAME[id], "res://assets/characters/%s.png" % id, CHAR_HEIGHT[id], pos)
	u.stepped.connect(_on_step.bind(u))
	party.append(u)
	set_leader(leader)
	return u

func remove_from_party(id: String) -> Unit:
	for u in party:
		if u.id == id:
			party.erase(u)
			npcs.append(u)
			if leader == u:
				set_leader(party[0])
			else:
				set_leader(leader)
			return u
	return null

func set_leader(u: Unit) -> void:
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
	if old and old != u and party.has(old):
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

# Move a unit to a point (for cutscenes). Awaitable.
func walk_to(u: Unit, target: Vector3, speed := 1.0, timeout := 6.0) -> void:
	var tt := 0.0
	u.set_meta("goal", target)
	u.set_meta("goal_speed", speed)
	while tt < timeout:
		var to := target - u.global_position
		to.y = 0.0
		if to.length() < 0.35:
			break
		await get_tree().process_frame
		tt += get_process_delta_time()
	u.remove_meta("goal")

# ---------------------------------------------------------------- UI
func _build_ui() -> void:
	dialogue = Dialogue.new()
	add_child(dialogue)
	hud = CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	var title := _label("TRIO ADVENTURES", Vector2(24, 16), 30, Color("#e8b923"), 8)
	hud.add_child(title)
	hud.add_child(_label(subtitle, Vector2(26, 54), 16, Color("#c9c0e8"), 5))
	objective_lbl = _label("", Vector2(26, 80), 19, Color("#ffdf8a"), 6)
	hud.add_child(objective_lbl)

	var box := HBoxContainer.new()
	box.anchor_left = 1.0; box.anchor_right = 1.0
	box.offset_left = -300; box.offset_top = 16; box.offset_right = -20
	box.alignment = BoxContainer.ALIGNMENT_END
	box.add_theme_constant_override("separation", 10)
	hud.add_child(box)
	leader_lbl = _label("", Vector2.ZERO, 18, Color.WHITE, 6)
	leader_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(leader_lbl)
	leader_por = TextureRect.new()
	leader_por.custom_minimum_size = Vector2(56, 56)
	leader_por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leader_por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	box.add_child(leader_por)
	set_leader(leader)

	help_lbl = _label("WASD walk · Shift run · E talk · Tab switch · ←/→ camera · I party · Esc menu · V voices", Vector2.ZERO, 14, Color(1, 1, 1, 0.6), 4)
	help_lbl.anchor_top = 1.0; help_lbl.anchor_bottom = 1.0; help_lbl.anchor_right = 1.0
	help_lbl.offset_top = -30; help_lbl.offset_left = 20; help_lbl.offset_right = -20
	help_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(help_lbl)

	toast = _label("", Vector2.ZERO, 22, Color.WHITE, 6)
	toast.anchor_left = 0.5; toast.anchor_right = 0.5
	toast.offset_left = -360; toast.offset_right = 360; toast.offset_top = 96
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.modulate.a = 0.0
	hud.add_child(toast)

	var post := CanvasLayer.new()
	post.layer = 4
	add_child(post)
	var pr := ColorRect.new()
	pr.set_anchors_preset(Control.PRESET_FULL_RECT)
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psm := ShaderMaterial.new()
	psm.shader = Shader.new()
	psm.shader.code = POST_SHADER
	psm.set_shader_parameter("vignette", 0.5 if night else 0.3)
	pr.material = psm
	post.add_child(pr)

	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
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

	step_sfx = _sfx(Util.noise_burst(55, 0.18, 0.7), -12.0)
	ui_sfx = _sfx(Util.chime(990.0, 180, 0.2), -10.0)
	whoosh_sfx = _sfx(Util.noise_burst(700, 0.05, 0.9), -6.0)

func _label(text: String, pos: Vector2, size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	return l

func _sfx(stream: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	add_child(p)
	return p

func fade_in(secs := 1.2) -> void:
	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, secs)

func fade_out(secs := 0.8) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, secs)
	await tw.finished

func show_toast(msg: String, secs := 1.6) -> void:
	toast.text = msg
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.2)
	tw.tween_interval(secs)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)

func objective(text: String) -> void:
	objective_lbl.text = ("Objective: " + text) if text != "" else ""
	objective_lbl.modulate.a = 0.0
	create_tween().tween_property(objective_lbl, "modulate:a", 1.0, 0.4)

# Floating joke label over someone (e.g. "Goblin (Between Jobs)"). secs <= 0 = stays.
func char_label(target: Node3D, text: String, secs := 3.0, h := 2.3, color := Color("#f3e3b0")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 40
	l.pixel_size = 0.0065
	l.outline_size = 10
	l.modulate = color
	l.position = Vector3(0, h, 0)
	target.add_child(l)
	l.scale = Vector3.ONE * 0.3
	create_tween().tween_property(l, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if secs > 0.0:
		var tw := create_tween()
		tw.tween_interval(secs)
		tw.tween_property(l, "modulate:a", 0.0, 0.4)
		tw.tween_callback(l.queue_free)
	return l

# Tip a cutout over (passing out, getting slapped). Cutouts normally always face the camera,
# so this freezes it facing the camera first, then rotates it.
func knock(u: Unit, degrees: float, secs := 0.2) -> void:
	u.sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	u.sprite.global_rotation = Vector3(0, yaw, 0)
	create_tween().tween_property(u.sprite, "rotation:z", deg_to_rad(degrees), secs).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func unknock(u: Unit) -> void:
	u.sprite.rotation = Vector3.ZERO
	u.sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

# Little jump (surprise, cheering)
func hop(u: Node3D, height := 0.5) -> void:
	var s: Node3D = u.sprite if u is Unit else u
	var tw := create_tween()
	tw.tween_property(s, "position:y", height, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "position:y", 0.0, 0.2).set_ease(Tween.EASE_IN)

# ---------------------------------------------------------------- loop
func _process(delta: float) -> void:
	t += delta
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
	if auto_dir != Vector3.ZERO:
		dir = (cam_right * auto_dir.x + cam_fwd * auto_dir.z).normalized()
	if dir.length() > 1.0:
		dir = dir.normalized()
	if leader.has_meta("goal"):
		dir = _goal_dir(leader)
	leader.drive(dir * walk_mult, Input.is_action_pressed("run") and walk_mult >= 1.0, cam_right, delta)
	leader.record_trail()
	for u in party:
		if u == leader:
			continue
		if u.has_meta("goal"):
			u.drive(_goal_dir(u), false, cam_right, delta)
			continue
		if not follow_enabled:
			u.drive(Vector3.ZERO, false, cam_right, delta)
			continue
		var tp := u.follow_point(leader, 1.8 * u.follow_slot)
		var to := tp - u.global_position
		to.y = 0.0
		var d := to.length()
		var fdir := Vector3.ZERO
		if d > 0.35:
			fdir = to.normalized() * clamp(d / 1.2, 0.3, 1.0) * walk_mult
		u.drive(fdir, d > 3.0 and walk_mult >= 1.0, cam_right, delta)
	for u in npcs:
		if u.has_meta("goal"):
			u.drive(_goal_dir(u), false, cam_right, delta)
		elif u.has_meta("follow") and u.get_meta("follow"):
			var tp2 := u.follow_point(leader, 1.8 * (party.size() + int(u.get_meta("follow_i", 0))))
			var to2 := tp2 - u.global_position
			to2.y = 0.0
			u.drive(to2.normalized() * clamp(to2.length() / 1.2, 0.0, 1.0) if to2.length() > 0.4 else Vector3.ZERO, to2.length() > 3.0, cam_right, delta)
		else:
			u.drive(Vector3.ZERO, false, cam_right, delta)
	for u in party + npcs:
		u.sprite.modulate = light_at(u.global_position) * (u.get_meta("tint") if u.has_meta("tint") else Color.WHITE)
	for c in cards:
		if c[2]:
			var lc := light_at(c[1] + Vector3(0, 0.5, 0))
			c[0].albedo_color = Color(min(lc.r, 0.92), min(lc.g, 0.8), min(lc.b, 0.78)) * 0.88 * c[3]

	_roam_process(delta)
	_level_process(delta)

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
			start(it)
			return
	if Input.is_action_just_pressed("switch"):
		if not switch_enabled or party.size() < 2:
			show_toast("%s is leading right now." % leader.display_name)
		else:
			var i := party.find(leader)
			set_leader(party[(i + 1) % party.size()])
			ui_sfx.play()
			show_toast("Now controlling %s" % leader.display_name)
	if Input.is_action_just_pressed("party_menu"):
		open_party_menu()
		return
	if Input.is_action_just_pressed("pause"):
		open_pause_menu()
		return
	if Input.is_action_just_pressed("tts"):
		dialogue.tts_on = not dialogue.tts_on
		Game.tts_on = dialogue.tts_on
		show_toast("Voices: %s" % ("ON" if dialogue.tts_on else "OFF"))

func _goal_dir(u: Unit) -> Vector3:
	var to: Vector3 = u.get_meta("goal") - u.global_position
	to.y = 0.0
	if to.length() < 0.35:
		return Vector3.ZERO
	return to.normalized() * float(u.get_meta("goal_speed", 1.0))

func _update_camera(delta: float) -> void:
	if Input.is_action_pressed("cam_left") and not cam_locked:
		target_yaw += delta * 1.8
	if Input.is_action_pressed("cam_right") and not cam_locked:
		target_yaw -= delta * 1.8
	yaw = lerp_angle(yaw, target_yaw, clamp(delta * 6.0, 0.0, 1.0))
	if cam == null:
		cam = Camera3D.new()
		cam.fov = 50.0
		add_child(cam)
		cam.current = true
		var ca := CameraAttributesPractical.new()
		ca.dof_blur_far_enabled = true
		ca.dof_blur_far_distance = 20.0
		ca.dof_blur_far_transition = 16.0
		ca.dof_blur_amount = 0.07
		cam.attributes = ca
	var focus: Vector3 = focus_override if focus_override != null else leader.global_position
	cam_target = cam_target.lerp(focus, clamp(delta * 4.0, 0.0, 1.0))
	var off := Vector3(0, zoom * cam_height, zoom).rotated(Vector3.UP, yaw)
	cam.global_position = cam_target + off
	cam.look_at(cam_target + Vector3(0, cam_look_h, 0), Vector3.UP)
	if shake > 0.0:
		shake = max(0.0, shake - delta)
		cam.h_offset = rng.randf_range(-1, 1) * shake * 0.25
		cam.v_offset = rng.randf_range(-1, 1) * shake * 0.25
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0

# ---------------------------------------------------------------- interaction
func _it_pos(it: Dictionary) -> Vector3:
	return it["node"].global_position if it.has("node") else it["pos"]

func current_interactables() -> Array:
	var list: Array = _level_interactables().duplicate()
	for u in party:
		if u != leader and talk.has(u.id):
			list.append({ "id": u.id, "label": u.display_name, "verb": "Talk to", "node": u, "h": 2.15, "r": 1.9, "steps": talk[u.id] })
	return list

func _nearest_interactable() -> Dictionary:
	var best := {}
	var best_d := 999.0
	var lp := leader.global_position
	for it in current_interactables():
		var p := _it_pos(it)
		var d := Vector2(p.x - lp.x, p.z - lp.z).length()
		if d < it["r"] and d < best_d:
			best = it
			best_d = d
	return best

func freeze_all(on: bool) -> void:
	for u in party + npcs:
		u.frozen = on

# Run a dialogue with everyone frozen. Awaitable.
func run_dialogue(steps: Array) -> void:
	busy = true
	freeze_all(true)
	await dialogue.run(steps, self)
	freeze_all(false)
	busy = false
	interact_cooldown = 0.3

func start(it: Dictionary) -> void:
	prompt.visible = false
	ui_sfx.play()
	await run_dialogue(it["steps"])

# "To be continued" style card. next_scene = scene to load when E is pressed.
func end_card(lines: Array, next_scene: String) -> void:
	busy = true
	freeze_all(true)
	var ui := ColorRect.new()
	ui.color = Color(0, 0, 0, 0)
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(ui)
	create_tween().tween_property(ui, "color:a", 0.85, 0.8)
	var l := _label("\n".join(lines), Vector2.ZERO, 26, Color("#f3e3b0"), 6)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.modulate.a = 0.0
	hud.add_child(l)
	create_tween().tween_property(l, "modulate:a", 1.0, 1.0)
	await wait(1.2)
	if shots_mode:
		return
	while not Input.is_action_just_pressed("interact"):
		await get_tree().process_frame
	if next_scene == "res://main.tscn":
		Game.reset()
	Game.goto(next_scene)

# Lines summing up the story so far (for end cards)
func story_so_far() -> Array:
	var out := []
	if Game.flag("skornKing"): out.append("Skorn was crowned the Purple King (briefly).")
	if Game.flag("chugWon"): out.append("Lykor out-drank a 400-year champion.")
	if Game.flag("foreheadLoser"): out.append("Lykor's forehead says LOSER.")
	if Game.flag("lykorDethroned"): out.append("Lykor got dethroned by Skorn.")
	if Game.flag("goblinAllies"): out.append("The goblins are tagging along.")
	if Game.flag("hasMidtocy"): out.append("Skorn has midtocy in his pocket.")
	if Game.flag("dulbersEscaped"): out.append("Dulbers Frint got away. (He'll be back.)")
	if Game.flag("dulbersDead"): out.append("Dulbers Frint was never seen again.")
	if Game.inv["beer"] > 0: out.append("Beezy: %d" % Game.inv["beer"])
	return out

# ---------------------------------------------------------------- testing helpers
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("SHOT_DIR")
	if dir.is_empty():
		dir = "user://"
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])

func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

# Skip through dialogue lines (testing)
func advance(n := 1, gap := 0.5) -> void:
	for i in n:
		await wait(gap)
		dialogue._next.emit()

func place_party(p: Vector3, facing := Vector3(0, 0, 1)) -> void:
	var side := facing.cross(Vector3.UP).normalized()
	for i in party.size():
		party[i].global_position = p if i == 0 else p - facing * 1.4 + side * (0.9 if i == 1 else -0.9)
	set_leader(party[0])
	cam_target = p

# Test a fight here: FIGHT=goblins|dulbers|giant|goblin_patrol (roaming) ... -- --shots
func _fight_tour(key: String) -> void:
	fade.color.a = 0.0
	busy = false
	if OS.get_environment("ALLIES") != "":
		Game.set_flag("goblinAllies")
		var c := spawn_npc("chief", "Chief Bogdrinker", "goblin_chief", 1.45, leader.global_position + Vector3(1.5, 0, 1.5))
		c.set_meta("follow", true)
	Game.level = int(OS.get_environment("LEVEL")) if OS.get_environment("LEVEL") != "" else 1
	Game.inv = { "beer": 2, "bowl": 1 }
	await wait(1.0)
	var shooting := [true]
	var shooter := func():
		var i := 0
		while shooting[0]:
			await wait(float(OS.get_environment("SHOT_EVERY")) if OS.get_environment("SHOT_EVERY") != "" else 4.0)
			if shooting[0]:
				await shot("f_%s_%02d" % [key, i])
				i += 1
	shooter.call()
	var res := ""
	if key == "goblin_patrol":
		var g := spawn_roamers(key, leader.global_position + Vector3(0, 0, -7), 2.0)
		await wait(2.0)
		leader.set_meta("goal", g["home"])
		leader.set_meta("goal_speed", 0.5)
		while not g["done"] and not g["busy"]:
			await wait(0.5)
		leader.remove_meta("goal")
		while g["busy"]:
			await wait(0.5)
		res = "roam done=%s" % g["done"]
		await wait(4.0)
		await shot("f_after_penalty")
	else:
		var mods := {}
		if OS.get_environment("MODS") != "":
			mods = JSON.parse_string(OS.get_environment("MODS"))
		res = await fight(key, { "mods": mods })
	shooting[0] = false
	if OS.get_environment("MENUS") != "":
		Game.give_gear("vol9")
		Game.equipped["xylo"] = "vol9"
		open_party_menu()
		await wait(1.0)
		await shot("menu_party")
		_close_menu()
		await wait(0.3)
		open_pause_menu()
		await wait(1.0)
		await shot("menu_pause")
		_close_menu()
	print("FIGHT RESULT: ", res, "  level ", Game.level, " xp ", Game.xp, " gear ", Game.gear_owned)
	await wait(1.5)
	await shot("f_%s_zz_after" % key)
	get_tree().quit()

func _views_tour() -> void:
	fade.color.a = 0.0
	place_party(party[0].global_position)
	zoom = 7.0
	await wait(1.5)
	for d in [["away", Vector3(0, 0, 1)], ["right", Vector3(1, 0, 0)], ["toward", Vector3(0, 0, -1)], ["left", Vector3(-1, 0, 0)]]:
		auto_dir = d[1]
		await wait(2.4)
		await shot("view_" + d[0])
	get_tree().quit()

# ================================================================ COMBAT
# Start a turn-based fight right where everyone is standing. Awaitable.
#   opts: enemies = [Unit] already in the world (else they're spawned) · center = Vector3 · mods = {}
#         party = [ids] to override who fights
# Story fights can't be lost for good: you get the funny penalty and try again.
# Returns "win" / "talked" / "fled" / "lose" (lose only for roaming fights).
const CombatD = preload("res://scripts/combat/combat_data.gd")
var roamers: Array = []
var checkpoint = null           # where you wake up after losing a roaming fight (default: area start)
var _forehead_lbl: Label3D

func fight(key: String, opts := {}) -> String:
	var def: Dictionary = CombatD.FIGHTS[key]
	var story: bool = def.get("story", false)
	while true:
		var units := fight_party(key, opts)
		var view := BattleView.new()
		add_child(view)
		var res: String = await view.run(key, { "party": units, "enemies": opts.get("enemies", []), "center": opts.get("center", null), "mods": opts.get("mods", {}) })
		if res == "win" and Game.forehead != "":
			Game.forehead = ""
			_show_forehead()
			show_toast("The forehead writing finally washed off.", 2.0)
		if res != "lose":
			return res
		await _defeat(story)
		if not story:
			return "lose"
	return "win"

# Who fights: the story fight's lineup if it has one, else everyone in the party (+ the Chief if he's with you)
func fight_party(key: String, opts := {}) -> Array:
	var def: Dictionary = CombatD.FIGHTS[key]
	var ids: Array = opts.get("party", def.get("party", []))
	var out := []
	if ids.is_empty():
		out = party.duplicate()
	else:
		for id in ids:
			for u in party + npcs:
				if u.id == id and u.visible and not out.has(u):
					out.append(u)
					break
	if out.is_empty():
		out = [leader]
	if Game.flag("goblinAllies") and ids.size() != 1:
		for u in npcs:
			if u.id == "chief" and u.visible and u.global_position.distance_to(out[0].global_position) < 25.0:
				out.append(u)
				break
	return out

func _defeat(story: bool) -> void:
	busy = true
	var ui := ColorRect.new()
	ui.color = Color(0.25, 0, 0, 0)
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(ui)
	create_tween().tween_property(ui, "color:a", 0.7, 0.6)
	var l := _label("YOU GOT COOKED", Vector2.ZERO, 72, Color("#ff6a5a"), 14)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud.add_child(l)
	for i in 4:   # sad trombone
		var p := _sfx(Util.chime([392.0, 370.0, 349.0, 330.0][i], 380 if i < 3 else 1100, 0.35), -2.0)
		p.play()
		await wait(0.42)
		p.queue_free()
	await wait(1.0)
	await fade_out(0.8)
	ui.queue_free()
	l.queue_free()
	# the penalty
	var opts := []
	for P in CombatD.PENALTIES:
		if P.has("lose") and Game.inv[P["lose"]] <= 0:
			continue
		opts.append(P)
	var P: Dictionary = opts[rng.randi() % opts.size()]
	var msg := ""
	if P.has("lose"):
		Game.inv[P["lose"]] -= 1
		msg = P["text"]
	else:
		var words: Array = P["forehead"]
		Game.forehead = words[rng.randi() % words.size()]
		msg = P["text"] % [Game.forehead, leader.display_name] if P["text"].count("%s") == 2 else P["text"] % leader.display_name
	if not story:
		var wake: Vector3 = checkpoint if checkpoint != null else (party_start[0] if not party_start.is_empty() else leader.global_position)
		place_party(wake, Vector3(0, 0, -1))
	_show_forehead()
	fade_in(1.0)
	show_toast(msg, 3.2)
	await wait(1.2)
	if story:
		show_toast("…and you wake up right before the fight. Again.", 2.5)
		await wait(1.6)
	busy = false

func _show_forehead() -> void:
	if _forehead_lbl:
		_forehead_lbl.queue_free()
		_forehead_lbl = null
	if Game.forehead == "" or leader == null:
		return
	_forehead_lbl = Label3D.new()
	_forehead_lbl.text = "(Forehead: \"%s\")" % Game.forehead
	_forehead_lbl.font_size = 30
	_forehead_lbl.pixel_size = 0.006
	_forehead_lbl.outline_size = 8
	_forehead_lbl.no_depth_test = true
	_forehead_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_forehead_lbl.modulate = Color("#ff9a8a")
	party[0].add_child(_forehead_lbl)
	_forehead_lbl.position = Vector3(0, party[0].height_m + 0.25, 0)

# ---------------------------------------------------------------- roaming enemies
# A group you can see wandering. Get close and they chase you (walking = harder to notice);
# touch them and the fight starts right there. Run, Talk or win to deal with them.
func spawn_roamers(fight_key: String, home: Vector3, radius := 4.0) -> Dictionary:
	var def: Dictionary = CombatD.FIGHTS[fight_key]
	var g := { "key": fight_key, "home": home, "radius": radius, "units": [], "state": "wander", "cool": 0.0, "done": false, "busy": false }
	for i in def["enemies"].size():
		var E: Dictionary = def["enemies"][i]
		var p := home + Vector3(rng.randf_range(-radius, radius) * 0.6, 0, rng.randf_range(-radius, radius) * 0.6)
		var u := spawn_npc("roam_%s_%d" % [fight_key, i], "%s %s" % [E["name"], E.get("tag", "")], E.get("roam_tex", "goblin"), E["h"], p)
		u.walk_speed = 2.2
		u.run_speed = 4.6
		var tag := Label3D.new()
		tag.text = u.display_name
		tag.font_size = 34
		tag.pixel_size = 0.008
		tag.outline_size = 8
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.modulate = Color("#ffcf9a")
		u.add_child(tag)
		tag.position = Vector3(0, E["h"] + 0.3, 0)
		u.set_meta("tag", tag)
		g["units"].append(u)
	roamers.append(g)
	return g

func _roam_process(delta: float) -> void:
	for g in roamers:
		if g["done"] or g["busy"]:
			continue
		g["cool"] = max(0.0, g["cool"] - delta)
		var units: Array = g["units"]
		if busy:
			for u in units:
				u.remove_meta("goal")
			continue
		var lp := leader.global_position
		var nearest := 999.0
		for u in units:
			nearest = min(nearest, u.global_position.distance_to(lp))
		var running := Input.is_action_pressed("run") and leader.moving
		var notice := 5.5 if running else 3.2
		match g["state"]:
			"wander":
				for u in units:
					if not u.has_meta("goal") or rng.randf() < delta * 0.25:
						u.set_meta("goal", g["home"] + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * g["radius"])
						u.set_meta("goal_speed", 0.45)
				if nearest < notice and g["cool"] <= 0.0:
					g["state"] = "chase"
					for u in units:
						char_label(u, "!", 1.2, u.height_m + 0.75, Color("#ff5a3a"))
					show_toast("%s spotted you!" % CombatD.FIGHTS[g["key"]]["title"])
			"chase":
				for u in units:
					u.set_meta("goal", lp)
					u.set_meta("goal_speed", 1.0)
				if nearest > 12.0:
					g["state"] = "wander"
					show_toast("They lost you.")
				elif nearest < 1.5:
					_roam_fight(g)

func _roam_fight(g: Dictionary) -> void:
	g["busy"] = true
	for u in g["units"]:
		u.remove_meta("goal")
		if u.has_meta("tag"): u.get_meta("tag").visible = false
	var res := await fight(g["key"], { "enemies": g["units"] })
	g["busy"] = false
	for u in g["units"]:
		if u.has_meta("tag"): u.get_meta("tag").visible = true
	match res:
		"win":
			g["done"] = true
			for u in g["units"]:
				knock(u, 80.0, 0.3)
			await wait(1.5)
			for u in g["units"]:
				_poof_out(u)
		"talked":
			g["done"] = true
			for u in g["units"]:
				u.set_meta("goal", g["home"] + Vector3(30, 0, rng.randf_range(-6, 6)))
				u.set_meta("goal_speed", 1.0)
			await wait(4.0)
			for u in g["units"]:
				_poof_out(u)
		"fled", "lose":
			g["state"] = "wander"
			g["cool"] = 6.0
			for u in g["units"]:
				u.global_position = g["home"] + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)) * g["radius"] * 0.5
			if res == "fled":
				var away: Vector3 = (leader.global_position - g["home"]).normalized()
				away.y = 0.0
				place_party(leader.global_position + away * 4.0, away)

func _poof_out(u: Unit) -> void:
	if not is_instance_valid(u):
		return
	var f := Fx.poof(Color(0.8, 0.75, 0.7))
	f.position = u.global_position + Vector3(0, 0.5, 0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)
	npcs.erase(u)
	u.queue_free()

# ---------------------------------------------------------------- menus (Esc / I)
var _menu_root: Control
var _menu_rows: Array = []
var _menu_sel := 0
var _menu_kind := ""

func _menu_panel(title: String, w := 720.0, h := 460.0) -> VBoxContainer:
	_menu_root = Control.new()
	_menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_menu_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -w / 2; panel.offset_right = w / 2; panel.offset_top = -h / 2; panel.offset_bottom = h / 2
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.11, 0.96)
	sb.border_color = Color("#e8b923")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 26; sb.content_margin_right = 26; sb.content_margin_top = 18; sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	_menu_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(_label(title, Vector2.ZERO, 30, Color("#e8b923"), 6))
	return col

func _close_menu() -> void:
	if _menu_root:
		_menu_root.queue_free()
		_menu_root = null
	_menu_kind = ""
	busy = false
	freeze_all(false)
	interact_cooldown = 0.3

# ---- Esc: pause menu
func open_pause_menu() -> void:
	busy = true
	freeze_all(true)
	_menu_kind = "pause"
	_menu_sel = 0
	var col := _menu_panel("PAUSED", 620, 380)
	_menu_rows = []
	for i in 5:
		var l := _label("", Vector2.ZERO, 22, Color.WHITE, 5)
		col.add_child(l)
		_menu_rows.append(l)
	col.add_child(_label("W/S choose · A/D or E change · Esc close", Vector2.ZERO, 14, Color(1, 1, 1, 0.55), 3))
	_render_pause()
	await get_tree().process_frame
	await get_tree().process_frame
	while _menu_kind == "pause":
		await get_tree().process_frame
		if Input.is_action_just_pressed("move_forward"): _menu_sel = (_menu_sel + 4) % 5; _render_pause()
		elif Input.is_action_just_pressed("move_back"): _menu_sel = (_menu_sel + 1) % 5; _render_pause()
		elif Input.is_action_just_pressed("move_left"): _pause_change(-1)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("interact"): _pause_change(1)
		elif Input.is_action_just_pressed("pause"): _close_menu()

func _render_pause() -> void:
	var txt := [
		"Resume",
		"Combat difficulty:  < %s >" % CombatD.DIFFICULTY[Game.difficulty]["label"],
		"Timed hits:  < %s >" % ("AUTO (they land on their own)" if Game.timed_auto else "MANUAL (press E on the ring)"),
		"Voices:  < %s >" % ("ON" if dialogue.tts_on else "OFF"),
		"Party & Gear  (I)",
	]
	for i in 5:
		_menu_rows[i].text = ("> " if i == _menu_sel else "   ") + txt[i]
		_menu_rows[i].add_theme_color_override("font_color", Color("#e8b923") if i == _menu_sel else Color.WHITE)

func _pause_change(d: int) -> void:
	ui_sfx.play()
	match _menu_sel:
		0: _close_menu(); return
		1: Game.difficulty = (Game.difficulty + d + 3) % 3
		2: Game.timed_auto = not Game.timed_auto
		3:
			dialogue.tts_on = not dialogue.tts_on
			Game.tts_on = dialogue.tts_on
		4:
			_close_menu()
			open_party_menu()
			return
	_render_pause()

# ---- I: party, level and gear
func party_ids_for_menu() -> Array:
	var ids := ["skorn", "lykor", "xylo"]
	if Game.flag("goblinAllies"):
		ids.append("chief")
	return ids

func open_party_menu() -> void:
	busy = true
	freeze_all(true)
	_menu_kind = "party"
	_menu_sel = 0
	_build_party_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var ids := party_ids_for_menu()
	while _menu_kind == "party":
		await get_tree().process_frame
		if Input.is_action_just_pressed("move_forward"): _menu_sel = (_menu_sel + ids.size() - 1) % ids.size(); _build_party_menu()
		elif Input.is_action_just_pressed("move_back"): _menu_sel = (_menu_sel + 1) % ids.size(); _build_party_menu()
		elif Input.is_action_just_pressed("move_left"): _cycle_gear(ids[_menu_sel], -1)
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("interact"): _cycle_gear(ids[_menu_sel], 1)
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("party_menu"): _close_menu()

func _build_party_menu() -> void:
	if _menu_root:
		_menu_root.queue_free()
	var lvn := Game.level
	var col := _menu_panel("PARTY  ·  Level %d  ·  XP %d%s" % [lvn, Game.xp, ("  (%d to next)" % Game.xp_to_next()) if Game.xp_to_next() > 0 else ""], 860, 520)
	col.add_child(_label("Beezy ×%d  ·  Chipotle Bowl ×%d  ·  Gear found: %d" % [Game.inv["beer"], Game.inv["bowl"], Game.gear_owned.size()], Vector2.ZERO, 17, Color("#8ad8ff"), 4))
	var ids := party_ids_for_menu()
	for i in ids.size():
		var id: String = ids[i]
		var P: Dictionary = CombatD.PARTY[id]
		var g: String = Game.equipped.get(id, "")
		var G: Dictionary = CombatD.GEAR.get(g, {})
		var hp := int(round((P["hp"] + G.get("hp", 0)) * (1.0 + 0.1 * (lvn - 1))))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var por := TextureRect.new()
		por.texture = load("res://assets/portraits/%s.png" % id)
		por.custom_minimum_size = Vector2(58, 58)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		row.add_child(por)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		var sel := i == _menu_sel
		info.add_child(_label(("> " if sel else "") + "%s   %s %d · Speed %d" % [P["name"], P["hp_label"], hp, P["spd"] + G.get("spd", 0)], Vector2.ZERO, 19, Color("#e8b923") if sel else Color.WHITE, 4))
		info.add_child(_label("Trinket:  < %s >" % (G["name"] if g != "" else "(nothing)"), Vector2.ZERO, 16, Color("#ffcf9a"), 3))
		var d := _label(G.get("desc", "Find gear by winning fights and poking around."), Vector2.ZERO, 13, Color(1, 1, 1, 0.65), 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(700, 0)
		info.add_child(d)
		row.add_child(info)
		col.add_child(row)
	col.add_child(_label("W/S pick who · A/D swap trinket · I or Esc close", Vector2.ZERO, 14, Color(1, 1, 1, 0.55), 3))

func _cycle_gear(id: String, d: int) -> void:
	var opts: Array = [""] + Game.gear_owned
	var cur: String = Game.equipped.get(id, "")
	var i := (opts.find(cur) + d + opts.size()) % opts.size()
	var nxt: String = opts[i]
	for other in Game.equipped.keys():   # one trinket, one owner
		if Game.equipped[other] == nxt and nxt != "":
			Game.equipped.erase(other)
	if nxt == "":
		Game.equipped.erase(id)
	else:
		Game.equipped[id] = nxt
	ui_sfx.play()
	_build_party_menu()


const GROUND_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D grass_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear, repeat_enable;
uniform vec2 clear_center = vec2(0.0);
uniform float clear_radius = 6.5;
uniform vec2 path_pts[12];
uniform int path_n = 0;
uniform float path_w = 1.6;
uniform float brightness = 0.8;
uniform vec3 dirt_tint : source_color = vec3(1.0);
uniform vec3 grass_tint : source_color = vec3(1.0);
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float seg_dist(vec2 p, vec2 a, vec2 b) {
	vec2 ab = b - a;
	float h = clamp(dot(p - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	return length(p - a - ab * h);
}

float worn(vec2 p) {
	float m = 1.0 - smoothstep(clear_radius - 1.5, clear_radius + 2.0, length(p - clear_center));
	for (int i = 0; i < 11; i++) {
		if (i + 1 >= path_n) { break; }
		float d = seg_dist(p, path_pts[i], path_pts[i + 1]);
		m = max(m, 1.0 - smoothstep(path_w * 0.6, path_w * 1.4, d));
	}
	return m;
}

void fragment() {
	vec2 p = wpos.xz;
	vec3 g = mix(texture(grass_tex, p * 0.16).rgb, texture(grass_tex, p * 0.047 + vec2(0.37, 0.11)).rgb, 0.4);
	vec3 d = mix(texture(dirt_tex, p * 0.22).rgb, texture(dirt_tex, p * 0.071 + vec2(0.6, 0.2)).rgb, 0.35);
	float n = texture(noise_tex, p * 0.035).r;
	float m = smoothstep(0.38, 0.62, worn(p) + (n - 0.5) * 0.7);
	float shade = 0.8 + 0.3 * texture(noise_tex, p * 0.012 + vec2(0.5)).r;
	ALBEDO = mix(g * vec3(0.85, 0.95, 0.85) * grass_tint, d * dirt_tint, m) * shade * brightness;
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
uniform vec3 light_dir = vec3(-0.45, 0.32, -0.83);
uniform float night = 1.0;
uniform float lava = 0.0;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float y = max(d.y, 0.0);
	vec3 md = normalize(light_dir);
	float m = dot(d, md);
	vec3 col;
	if (lava > 0.5) {
		col = mix(vec3(0.45, 0.12, 0.05), vec3(0.08, 0.02, 0.02), pow(y, 0.6));
		if (d.y < 0.0) { col = vec3(0.2, 0.06, 0.03); }
	} else if (night > 0.5) {
		col = mix(vec3(0.10, 0.12, 0.23), vec3(0.01, 0.014, 0.045), pow(y, 0.45));
		if (d.y < 0.0) { col = vec3(0.06, 0.07, 0.14); }
		vec3 p = d * 260.0;
		vec3 cell = floor(p);
		vec3 f = fract(p) - 0.5;
		float h = hash(cell);
		if (h > 0.97 && d.y > 0.02) {
			vec3 off = vec3(hash(cell + 3.1), hash(cell + 7.7), hash(cell + 11.3)) - 0.5;
			float s = smoothstep(0.16, 0.0, length(f - off * 0.5));
			col += vec3(0.9, 0.95, 1.0) * s * ((h - 0.97) / 0.03) * 1.6 * smoothstep(0.02, 0.25, d.y);
		}
		col += vec3(0.95, 0.97, 1.0) * smoothstep(0.99935, 0.99965, m) * 2.5;
		col += vec3(0.25, 0.3, 0.5) * pow(max(m, 0.0), 90.0) * 0.6;
	} else {
		col = mix(vec3(0.78, 0.84, 0.88), vec3(0.32, 0.52, 0.82), pow(y, 0.5));
		if (d.y < 0.0) { col = vec3(0.55, 0.6, 0.6); }
		col += vec3(1.0, 0.92, 0.75) * smoothstep(0.9990, 0.9996, m) * 3.0;
		col += vec3(1.0, 0.85, 0.6) * pow(max(m, 0.0), 30.0) * 0.35;
	}
	COLOR = col;
}
"""
