# "The Tale of Diddy Chud" (Ebain's song, Asar's idea): a music-video cutscene the first time the trio reach the
# Pass, before Mattias shows up. Camera cuts, lava pulses, volcano eruptions, lava bombs, geysers and screen shake
# all run off the SONG'S OWN CLOCK (playback position, beats in BEATS from a librosa beat track), so nothing drifts
# even if the game lags. Hold E to skip (same ring as the troll's love & light).
#
# Song map (seconds): 0 monk intro · 26.0 hush · 27.0 DROP 1 · 54.2 verse (bass cuts = hits) · 80.2 DROP 2 ·
# 107.4 silent break · 110.6 solo/build · 123.4 hush · 124.2 FINAL DROP · 137.3 monk outro · 151.2 end.
# The volcanoes are built for the whole Pass (build_volcanoes, called from pass.gd) and only erupt in here.
#
# Tests: NO_CUTSCENE or headless skips it. In --shots tours it's skipped unless CHUD_SHOTS="27.5,81,125" is set:
# then it jumps to each time, lets it run a moment, saves chud_<t>.png and quits.
class_name ChudMusical
extends Node

const SONG_ID := "the_tale_of_diddy_chud"
const SONG := "res://assets/music/the_tale_of_diddy_chud.ogg"
const LENGTH := 151.2
const HEAD := Vector3(4.2, 2.8, -10.0)     # = pass.gd GIANT_HEAD
const BODY := Vector3(1.6, 2.0, -10.2)
const PARTY_AT := Vector3(0, 0, 4.6)

const DROP1 := 27.0
const VERSE := 54.2
const DROP2 := 80.2
const BREAK := 107.4
const SOLO := 110.6
const HUSH := 123.4
const FINAL := 124.2
const OUTRO := 137.3
const SECTIONS := [[0.0, "intro"], [26.0, "hush"], [DROP1, "drop1"], [VERSE, "verse"], [DROP2, "drop2"],
	[BREAK, "break"], [SOLO, "solo"], [HUSH, "hush"], [FINAL, "final"], [OUTRO, "outro"]]
# where the bass drops out for a moment (librosa, < 30 dB under 150 Hz). Each one's end is a hit.
const BASS_CUTS := [[36.54, 37.46], [43.38, 44.28], [50.0, 50.9], [56.06, 57.52], [62.68, 64.14], [69.62, 70.76],
	[72.54, 73.04], [75.86, 77.38], [103.16, 104.08]]

# [base position, height]: far behind the canyon, north of the gorge
const VOLCANOES := [[Vector3(-34, -1, -62), 44.0], [Vector3(8, -1, -88), 64.0], [Vector3(40, -1, -60), 40.0]]
# lava channels (pass.gd _canyon) where geysers shoot up
const GEYSERS := [Vector3(-9.6, 0.1, -10), Vector3(-9.6, 0.1, -3), Vector3(-9.6, 0.1, 5), Vector3(9.8, 0.1, -8),
	Vector3(9.8, 0.1, 8), Vector3(-5.6, 0.1, -15.5), Vector3(7.4, 0.1, -17.5), Vector3(-9.6, 0.1, 10)]

# every beat of the song (librosa beat_track, ~143.5 bpm; half-time feel, so 4 beats = one big bar)
const BEATS := [1.07, 1.49, 1.90, 2.35, 2.79, 3.18, 3.60, 4.02, 4.46, 4.88, 5.27, 5.67, 6.06, 6.46, 6.87, 7.29, 7.71, 8.10, 8.52, 8.92, 9.31, 9.71, 10.12, 10.52, 10.91, 11.33, 11.70, 12.07, 12.52, 12.91, 13.33, 13.75, 14.16, 14.61, 15.00, 15.39, 15.79, 16.21, 16.63, 17.04, 17.46, 17.86, 18.25, 18.65, 19.06, 19.50, 19.92, 20.34, 20.76, 21.18, 21.62, 22.04, 22.48, 22.92, 23.34, 23.75, 24.17, 24.57, 24.98, 25.38, 25.77, 26.19, 26.61, 27.00, 27.45, 27.91, 28.37, 28.82, 29.23, 29.65, 30.07, 30.49, 30.88, 31.30, 31.72, 32.14, 32.55, 32.95, 33.37, 33.79, 34.20, 34.62, 35.04, 35.43, 35.85, 36.27, 36.69, 37.11, 37.50, 37.92, 38.34, 38.75, 39.17, 39.64, 40.10, 40.59, 41.03, 41.45, 41.84, 42.26, 42.66, 43.10, 43.51, 43.93, 44.35, 44.77, 45.16, 45.58, 46.00, 46.39, 46.81, 47.23, 47.65, 48.07, 48.48, 48.88, 49.27, 49.71, 50.13, 50.55, 50.97, 51.39, 51.78, 52.20, 52.59, 53.01, 53.43, 53.85, 54.27, 54.68, 55.10, 55.50, 55.91, 56.33, 56.75, 57.17, 57.56, 57.98, 58.40, 58.82, 59.23, 59.65, 60.07, 60.46, 60.88, 61.30, 61.72, 62.11, 62.53, 62.95, 63.37, 63.79, 64.20, 64.60, 65.02, 65.43, 65.85, 66.27, 66.69, 67.08, 67.50, 67.92, 68.34, 68.75, 69.17, 69.57, 69.98, 70.40, 70.82, 71.24, 71.66, 72.05, 72.47, 72.89, 73.28, 73.70, 74.12, 74.54, 74.95, 75.37, 75.79, 76.18, 76.60, 77.02, 77.44, 77.86, 78.27, 78.69, 79.09, 79.51, 79.92, 80.34, 80.74, 81.15, 81.57, 81.99, 82.41, 82.83, 83.24, 83.64, 84.06, 84.47, 84.89, 85.31, 85.73, 86.12, 86.54, 86.96, 87.38, 87.79, 88.21, 88.61, 89.03, 89.44, 89.86, 90.26, 90.67, 91.07, 91.49, 91.90, 92.35, 92.74, 93.16, 93.58, 93.99, 94.41, 94.83, 95.25, 95.71, 96.18, 96.64, 97.08, 97.50, 97.92, 98.34, 98.75, 99.17, 99.59, 100.01, 100.40, 100.82, 101.24, 101.66, 102.05, 102.47, 102.89, 103.31, 103.72, 104.12, 104.54, 104.95, 105.37, 105.79, 106.21, 106.63, 107.04, 107.44, 107.83, 108.25, 108.62, 109.04, 109.46, 109.88, 110.29, 110.71, 111.13, 111.55, 111.99, 112.41, 112.83, 113.24, 113.66, 114.06, 114.47, 114.89, 115.31, 115.73, 116.15, 116.56, 116.96, 117.38, 117.79, 118.21, 118.63, 119.05, 119.44, 119.86, 120.28, 120.70, 121.09, 121.51, 121.93, 122.35, 122.76, 123.25, 123.76, 124.18, 124.60, 125.02, 125.43, 125.83, 126.27, 126.69, 127.11, 127.52, 127.92, 128.34, 128.75, 129.17, 129.59, 129.99, 130.40, 130.82, 131.24, 131.66, 132.05, 132.45, 132.89, 133.31, 133.72, 134.12, 134.54, 134.95, 135.37, 135.77, 136.19, 136.60]

const SKIP_FILL_S := 1.2
const SKIP_DRAIN_S := 3.0

# ================================================================ volcanoes (always there, built by pass.gd)
static func build_volcanoes(lv: Node3D) -> Array:
	var out := []
	for v in VOLCANOES:
		var base: Vector3 = v[0]
		var h: float = v[1]
		var cone := CylinderMesh.new()
		cone.height = h
		cone.bottom_radius = h * 0.95
		cone.top_radius = h * 0.13
		cone.radial_segments = 28
		cone.rings = 6
		var sm := ShaderMaterial.new()
		sm.shader = Shader.new()
		sm.shader.code = VOLCANO_SHADER
		sm.set_shader_parameter("height", h)
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.material_override = sm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = base + Vector3(0, h * 0.5, 0)
		lv.add_child(mi)
		var top := base + Vector3(0, h, 0)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.45, 0.12)
		light.light_energy = 2.0
		light.omni_range = h * 0.6
		light.position = top + Vector3(0, 3, 0)
		lv.add_child(light)
		var smoke := CPUParticles3D.new()   # lazy ash plume, always on
		smoke.amount = 26
		smoke.lifetime = 14.0
		smoke.preprocess = 14.0
		smoke.mesh = Fx.quad(h * 0.32, false)
		smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		smoke.emission_sphere_radius = h * 0.08
		smoke.direction = Vector3.UP
		smoke.spread = 12.0
		smoke.gravity = Vector3(0.9, 0.6, 0)
		smoke.initial_velocity_min = 2.0
		smoke.initial_velocity_max = 3.5
		smoke.scale_amount_curve = Fx.curve([[0.0, 0.5], [1.0, 1.8]])
		smoke.color_ramp = Fx.ramp([[0.0, Color(0.25, 0.2, 0.18, 0)], [0.15, Color(0.3, 0.25, 0.22, 0.55)], [1.0, Color(0.45, 0.4, 0.38, 0)]])
		smoke.position = top + Vector3(0, 2, 0)
		lv.add_child(smoke)
		var burst := _blob_burst(h * 0.05, 90, 5.0, h * 0.45, h * 0.85, 24.0, h * 0.25)
		burst.position = top
		lv.add_child(burst)
		var puff := CPUParticles3D.new()   # dark ash cloud on an eruption
		puff.one_shot = true
		puff.emitting = false
		puff.explosiveness = 0.85
		puff.amount = 24
		puff.lifetime = 7.0
		puff.mesh = Fx.quad(h * 0.45, false)
		puff.direction = Vector3.UP
		puff.spread = 35.0
		puff.gravity = Vector3(0.6, 1.5, 0)
		puff.initial_velocity_min = h * 0.15
		puff.initial_velocity_max = h * 0.3
		puff.damping_min = 2.0
		puff.damping_max = 4.0
		puff.scale_amount_curve = Fx.curve([[0.0, 0.4], [1.0, 2.0]])
		puff.color_ramp = Fx.ramp([[0.0, Color(0.9, 0.45, 0.15, 0.9)], [0.12, Color(0.22, 0.18, 0.16, 0.85)], [1.0, Color(0.3, 0.27, 0.25, 0)]])
		puff.position = top
		lv.add_child(puff)
		var fountain := CPUParticles3D.new()   # the fire column: big additive glow, reads from far away
		fountain.one_shot = true
		fountain.emitting = false
		fountain.explosiveness = 0.55
		fountain.amount = 60
		fountain.lifetime = 2.6
		fountain.local_coords = false
		fountain.mesh = Fx.quad(h * 0.2, true)
		fountain.direction = Vector3.UP
		fountain.spread = 9.0
		fountain.initial_velocity_min = h * 0.35
		fountain.initial_velocity_max = h * 0.7
		fountain.gravity = Vector3(0, -h * 0.2, 0)
		fountain.scale_amount_curve = Fx.curve([[0.0, 0.6], [0.4, 1.2], [1.0, 0.3]])
		fountain.color_ramp = Fx.ramp([[0.0, Color(1, 0.95, 0.7, 1)], [0.3, Color(1, 0.55, 0.12, 0.9)], [1.0, Color(0.6, 0.12, 0.02, 0)]])
		fountain.position = top
		lv.add_child(fountain)
		out.append({ "fountain": fountain, "top": top, "h": h, "mat": sm, "light": light, "burst": burst, "puff": puff, "heat": 0.0 })
	return out

# glowing lava blobs flung out of a point (volcano craters, geysers, bomb splashes)
static func _blob_burst(radius: float, amount: int, life: float, v_min: float, v_max: float, spread: float, grav: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.explosiveness = 0.92
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.mesh = Fx.quad(radius * 3.2, true)   # glowing sparks, not flat dots
	p.direction = Vector3.UP
	p.spread = spread
	p.initial_velocity_min = v_min
	p.initial_velocity_max = v_max
	p.gravity = Vector3(0, -grav, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	p.color_ramp = Fx.ramp([[0.0, Color(1.0, 0.95, 0.6)], [0.25, Color(1.0, 0.5, 0.1)], [1.0, Color(0.35, 0.06, 0.02)]])
	return p

const VOLCANO_SHADER := """
shader_type spatial;
uniform float height = 40.0;
uniform float heat = 0.0;   // 0 calm .. 1+ erupting
varying vec3 lp;
void vertex() { lp = VERTEX; }
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * n2(p); p *= 2.03; a *= 0.5; } return v; }
void fragment() {
	float y = clamp(lp.y / height + 0.5, 0.0, 1.0);
	float ang = atan(lp.x, lp.z);
	float n = fbm(vec2(ang * 4.0, lp.y * 0.12));
	float rivers = smoothstep(0.6, 0.68, fbm(vec2(ang * 7.0 + n * 2.5, lp.y * 0.03 - TIME * 0.05)));
	rivers *= smoothstep(0.25, 0.95, y) * (0.35 + heat * 0.9);
	vec3 rock = mix(vec3(0.09, 0.065, 0.055), vec3(0.3, 0.22, 0.17), n) * mix(0.75, 1.0, y);
	ALBEDO = rock;
	ROUGHNESS = 1.0;
	float crater = smoothstep(0.985, 1.0, y);
	EMISSION = vec3(1.0, 0.33, 0.05) * rivers * 2.2 + vec3(1.0, 0.45, 0.1) * crater * (1.5 + heat * 5.0);
}
"""

# ================================================================ the cutscene
var lv          # the Pass level (pass.gd)
var t := 0.0    # song time
var player: AudioStreamPlayer
var cam: Camera3D
var layer: CanvasLayer
var ring: SkipRing
var flash: ColorRect
var bars: Array[ColorRect] = []
var title: Label
var shots: Array = []
var shot_i := 0
var events: Array = []
var ev_i := 0
var beat_i := 0
var sec_first_beat := {}   # section start time -> index of its first beat (for downbeats)
var trauma := 0.0          # screen shake
var pulse := 0.0           # lava glow pulse on the beat
var dim := 1.0             # lava/volcano light level (dips in the hushes)
var dim_target := 1.0
var geysers: Array = []    # [particles, light]
var bombs := 0
var next_volcano := 0
var lava_base := []        # [light, energy]
var rng := RandomNumberGenerator.new()
var skipped := false
var sfx_db := 0.0
var wall := 0.0   # real time since the song started
var fog_saved := [0.007, 0.003]

func run(level) -> void:
	lv = level
	Game.set_flag("chudMusical")
	var test := OS.get_environment("CHUD_SHOTS")
	if DisplayServer.get_name() == "headless" or OS.get_environment("NO_CUTSCENE") != "" or (lv.shots_mode and test == ""):
		return
	rng.seed = 6767
	lv.busy = true
	lv.auto_dir = Vector3.ZERO
	await lv.fade_out(0.7)
	_setup()
	if test != "":
		await _test_shots(test)
		return
	player.play()
	lv.fade_in(3.0)
	var tw := create_tween()
	for b in bars:
		tw.parallel().tween_property(b, "anchor_bottom" if b.anchor_top == 0.0 else "anchor_top", 0.1 if b.anchor_top == 0.0 else 0.9, 2.0)
	while t < LENGTH and not skipped:
		var dt := get_process_delta_time()
		_advance_clock(dt)
		_tick(dt)
		if Input.is_action_pressed("interact"):
			ring.progress = minf(1.0, ring.progress + dt / SKIP_FILL_S)
		else:
			ring.progress = maxf(0.0, ring.progress - dt / SKIP_DRAIN_S)
		ring.queue_redraw()
		if ring.progress >= 1.0:
			skipped = true
		await get_tree().process_frame
	if skipped:
		create_tween().tween_property(player, "volume_db", -40.0, 0.7)
		await lv.fade_out(0.7)
	elif lv.fade.color.a < 0.99:
		await lv.fade_out(0.4)
	_teardown()
	lv.interact_cooldown = 0.5
	await lv.wait(0.3)
	lv.fade_in(1.2)

func _advance_clock(dt: float) -> void:
	wall += dt
	if player.playing:   # the song's real position (no sound card: falls back to frame time)
		var pos := player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		t = maxf(t, minf(pos, wall + 0.3))   # never ahead of real time (the dummy audio driver races ahead)
	else:
		t += dt

func _setup() -> void:
	player = AudioStreamPlayer.new()
	player.bus = &"Music"
	player.stream = load(SONG)
	add_child(player)
	if LibraryUI.mark_heard(SONG_ID):
		pass   # unlocked in the Library (no toast: it would sit on top of the video)
	var sfx := AudioServer.get_bus_index("SFX")   # hush the canyon's wind/lava loops under the song
	if sfx >= 0:
		sfx_db = AudioServer.get_bus_volume_db(sfx)
		AudioServer.set_bus_volume_db(sfx, sfx_db - 14.0)
	lv.musical = true   # pass.gd: snoring off
	lv.place_party(PARTY_AT, Vector3(0, 0, -1))
	for u in lv.party:
		u.velocity = Vector3.ZERO
	var env: Environment = lv.world_env.environment
	fog_saved = [env.fog_density, env.volumetric_fog_density]
	env.fog_density = 0.0025
	env.volumetric_fog_density = 0.0008
	cam = Camera3D.new()
	cam.fov = 55.0
	lv.add_child(cam)
	cam.current = true
	lv.hud.visible = false
	for l in lv.lava_lights:
		lava_base.append([l, l.light_energy])
	for p in GEYSERS:
		var g := _blob_burst(0.16, 34, 1.7, 7.0, 12.0, 9.0, 12.0)
		g.position = p
		lv.add_child(g)
		var gl := OmniLight3D.new()
		gl.light_color = Color(1.0, 0.5, 0.15)
		gl.light_energy = 0.0
		gl.omni_range = 7.0
		gl.position = p + Vector3(0, 2.0, 0)
		lv.add_child(gl)
		geysers.append([g, gl])
	_build_ui()
	_build_shots()
	_build_events()
	for s in SECTIONS:
		sec_first_beat[s[0]] = _beat_at(s[0])

func _teardown() -> void:
	player.stop()
	var env: Environment = lv.world_env.environment
	env.fog_density = fog_saved[0]
	env.volumetric_fog_density = fog_saved[1]
	cam.current = false
	lv.cam.current = true
	cam.queue_free()
	lv.hud.visible = true
	lv.musical = false
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx >= 0:
		AudioServer.set_bus_volume_db(sfx, sfx_db)
	for lb in lava_base:
		lb[0].light_energy = lb[1]
	for m in lv.lava_mats:
		m.set_shader_parameter("pulse", 0.0)
	for v in lv.volcanoes:
		v["mat"].set_shader_parameter("heat", 0.0)
		v["light"].light_energy = 2.0
	for g in geysers:
		g[0].queue_free()
		g[1].queue_free()
	layer.queue_free()
	lv.busy = false

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 85
	add_child(layer)
	for top in [true, false]:   # letterbox bars slide in
		var b := ColorRect.new()
		b.color = Color.BLACK
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.anchor_left = 0.0; b.anchor_right = 1.0
		b.anchor_top = 0.0 if top else 1.0
		b.anchor_bottom = 0.0 if top else 1.0
		layer.add_child(b)
		bars.append(b)
	flash = ColorRect.new()
	flash.color = Color(1.0, 0.85, 0.6, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(flash)
	title = Label.new()
	title.text = "The Tale of Diddy Chud"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.0; title.anchor_right = 1.0; title.anchor_top = 0.72; title.anchor_bottom = 0.8
	title.add_theme_font_size_override("font_size", 58)
	title.add_theme_color_override("font_color", Color("#f3e3b0"))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.02))
	title.add_theme_constant_override("outline_size", 14)
	title.modulate.a = 0.0
	layer.add_child(title)
	ring = SkipRing.new()
	ring.anchor_left = 1.0; ring.anchor_right = 1.0; ring.anchor_top = 1.0; ring.anchor_bottom = 1.0
	ring.offset_left = -300; ring.offset_right = -36; ring.offset_top = -92; ring.offset_bottom = -36
	ring.key_text = Keybinds.key_name(Keybinds.key_of("interact")) if Keybinds.key_of("interact") > 0 else "E"
	layer.add_child(ring)

# ---------------------------------------------------------------- camera shots
# {t0, t1, p0, l0, p1, l1, f0, f1, ease}: position/look-at/fov move from 0 to 1 across the shot. A new shot = a cut.
func _shot(t0: float, t1: float, p0: Vector3, l0: Vector3, p1: Vector3, l1: Vector3, f0 := 50.0, f1 := -1.0, smooth := true) -> void:
	shots.append({ "t0": t0, "t1": t1, "p0": p0, "l0": l0, "p1": p1, "l1": l1, "f0": f0, "f1": f0 if f1 < 0 else f1, "smooth": smooth })

func _vtop(i: int) -> Vector3:
	return VOLCANOES[i][0] + Vector3(0, VOLCANOES[i][1], 0)

# the angles the drops cut between
func _drop_set() -> Array:
	return [
		[Vector3(1.5, 0.7, 3.0), Vector3(1.8, 9.0, -40.0), 62.0],       # low hero shot up past the giant to the volcanoes
		[Vector3(-8.5, 8.5, 4.0), Vector3(2.0, 2.5, -11.0), 48.0],      # high left over the lava
		[Vector3(6.0, 3.4, -4.4), HEAD, 44.0],                          # his face
		[Vector3(0.5, 6.0, 2.0), _vtop(1) + Vector3(0, 6, 0), 20.0],    # telephoto on the big volcano
		[Vector3(11.0, 4.5, -1.5), Vector3(1.0, 3.0, -12.0), 50.0],     # right side
		[Vector3(-4.0, 4.0, 3.0), Vector3(-9.4, 0.5, -12.0), 56.0],     # down the lava channel
		[Vector3(1.0, 13.0, 9.0), Vector3(2.0, 0.0, -11.0), 50.0],      # from up high
		[Vector3(0.5, 6.0, 2.0), _vtop(0) + Vector3(0, 6, 0), 22.0],    # telephoto on the left volcano
		[Vector3(3.5, 1.4, 8.5), Vector3(1.6, 5.0, -20.0), 56.0],       # behind the trio
	]

func _cuts(t0: float, t1: float, every_beats: int, start: int) -> void:
	var set := _drop_set()
	var i0 := _beat_at(t0)
	var times: Array = [t0]
	var k := i0 + every_beats
	while k < BEATS.size() and BEATS[k] < t1 - 0.4:
		times.append(BEATS[k])
		k += every_beats
	times.append(t1)
	for j in times.size() - 1:
		var s: Array = set[(start + j) % set.size()]
		var p: Vector3 = s[0]
		var l: Vector3 = s[1]
		var drift := (l - p).normalized() * minf(2.0, p.distance_to(l) * 0.12)   # a slow push in during the shot
		_shot(times[j], times[j + 1], p, l, p + drift, l, s[2], s[2] * 0.94, false)

func _build_shots() -> void:
	# intro: the monks. Slow, wide, then creep in on the sleeping giant.
	_shot(0.0, 9.0, Vector3(-2.0, 10.0, 12.0), Vector3(1, 7, -40), Vector3(-1.0, 7.5, 7.0), Vector3(1, 12, -60), 55.0, 52.0)
	_shot(9.0, 17.6, Vector3(-8.0, 1.3, 11.0), Vector3(-6.5, 1.0, -8.0), Vector3(-7.6, 2.2, -2.5), Vector3(2.0, 3.0, -11.0), 55.0, 50.0)
	_shot(17.6, 26.0, Vector3(7.0, 3.8, -0.5), HEAD, Vector3(5.6, 3.3, -5.4), HEAD, 46.0, 42.0)
	_shot(26.0, DROP1, Vector3(5.0, 3.1, -7.2), HEAD, Vector3(4.8, 3.0, -7.7), HEAD, 40.0, 38.0)
	_cuts(DROP1, VERSE, 16, 0)
	# verse: sneaking. Cuts land where the bass comes back in.
	_shot(VERSE, 57.52, Vector3(-1.2, 1.1, 9.8), Vector3(2.0, 2.4, -10.0), Vector3(-0.6, 1.1, 7.8), Vector3(2.0, 2.4, -10.0), 45.0)
	_shot(57.52, 64.14, Vector3(-4.5, 3.2, 5.0), Vector3(-9.4, 0.6, -6.0), Vector3(-4.0, 3.6, -0.5), Vector3(-3.0, 2.5, -12.0), 55.0)
	_shot(64.14, 70.76, Vector3(3.8, 4.2, -2.6), Vector3(2.6, 2.0, -10.2), Vector3(3.2, 3.6, -4.4), Vector3(2.6, 2.0, -10.2), 50.0)
	_shot(70.76, 77.38, Vector3(3.5, 1.0, 8.5), Vector3(0.0, 1.2, 3.5), Vector3(2.0, 1.0, 8.0), Vector3(1.0, 2.5, -8.0), 50.0)
	_shot(77.38, DROP2, Vector3(1.0, 2.6, 4.0), HEAD, Vector3(3.4, 3.0, -3.5), HEAD, 50.0, 38.0)
	_cuts(DROP2, BREAK, 8, 3)
	# the break: dead quiet, slow push onto his face
	_shot(BREAK, SOLO, Vector3(5.4, 3.3, -5.0), HEAD, Vector3(4.7, 3.0, -7.6), HEAD, 42.0, 34.0)
	# solo: one long sweep across the front of him (he's a flat picture: stay in front)
	_shot(SOLO, HUSH, Vector3(-11.0, 6.0, 1.5), Vector3(1.6, 3.0, -12.0), Vector3(13.0, 7.5, 0.5), Vector3(1.6, 3.0, -12.0), 52.0, 48.0)
	_shot(HUSH, FINAL, Vector3(4.8, 3.0, -7.5), HEAD, Vector3(4.7, 3.0, -7.8), HEAD, 34.0, 32.0)
	_cuts(FINAL, OUTRO, 4, 6)
	# outro: the monks again, pull all the way back
	_shot(OUTRO, LENGTH + 1.0, Vector3(1.5, 3.2, 1.5), Vector3(1.6, 3.0, -12.0), Vector3(-1.0, 9.0, 11.0), Vector3(1, 12, -60), 50.0, 55.0)

func _update_camera() -> void:
	while shot_i < shots.size() - 1 and t >= shots[shot_i]["t1"]:
		shot_i += 1
	while shot_i > 0 and t < shots[shot_i]["t0"]:
		shot_i -= 1
	var s: Dictionary = shots[shot_i]
	var u := clampf((t - s["t0"]) / maxf(0.01, s["t1"] - s["t0"]), 0.0, 1.0)
	if s["smooth"]:
		u = u * u * (3.0 - 2.0 * u)
	var p: Vector3 = s["p0"].lerp(s["p1"], u)
	var l: Vector3 = s["l0"].lerp(s["l1"], u)
	cam.fov = lerpf(s["f0"], s["f1"], u)
	cam.global_position = p
	cam.look_at(l, Vector3.UP)
	var k := trauma * trauma   # screen shake
	if k > 0.0001:
		cam.h_offset = rng.randf_range(-1.0, 1.0) * k * 0.7
		cam.v_offset = rng.randf_range(-1.0, 1.0) * k * 0.7
		cam.rotate_object_local(Vector3.FORWARD, rng.randf_range(-1.0, 1.0) * k * 0.06)
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0

# ---------------------------------------------------------------- timed events
func _at(time: float, f: Callable) -> void:
	events.append([time, f])

func _build_events() -> void:
	_at(2.5, func(): create_tween().tween_property(title, "modulate:a", 1.0, 1.5))
	_at(8.0, func(): create_tween().tween_property(title, "modulate:a", 0.0, 1.5))
	_at(11.7, func(): _kick(0.25))   # the big snore in the intro
	_at(26.0, func(): dim_target = 0.35)
	_at(DROP1, func(): _drop(1.0))
	for c in BASS_CUTS:
		_at(c[0], func(): dim_target = 0.45)
		_at(c[1], func(): _hit())
	_at(DROP2, func(): _drop(1.1))
	_at(BREAK, func(): dim_target = 0.25)
	_at(SOLO, func(): dim_target = 1.0; _kick(0.6); _erupt(1))
	_at(HUSH, func(): dim_target = 0.15)
	_at(FINAL, func(): _drop(1.25))
	_at(OUTRO, func(): dim_target = 0.7)
	_at(149.6, func(): lv.fade_out(1.4))
	events.sort_custom(func(a, b): return a[0] < b[0])

func _drop(strength: float) -> void:
	dim_target = 1.0
	dim = 1.0
	for i in lv.volcanoes.size():
		_erupt(i)
	for g in geysers.size():
		_geyser(g)
	_kick(strength)
	flash.color.a = 0.55
	create_tween().tween_property(flash, "color:a", 0.0, 0.35)

func _hit() -> void:   # the bass slams back in after a cut
	dim_target = 1.0
	_erupt(next_volcano)
	next_volcano = (next_volcano + 1) % lv.volcanoes.size()
	for k in 3:
		_geyser(rng.randi() % geysers.size())
	_kick(0.55)

func _kick(a: float) -> void:
	trauma = minf(1.25, trauma + a)

func _erupt(i: int) -> void:
	var v: Dictionary = lv.volcanoes[i]
	v["burst"].restart()
	v["fountain"].restart()
	v["puff"].restart()
	v["heat"] = 1.4
	var l: OmniLight3D = v["light"]
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 16.0, 0.08)
	tw.tween_property(l, "light_energy", 2.0, 1.8)

func _geyser(i: int) -> void:
	var g: Array = geysers[i]
	g[0].restart()
	var tw := create_tween()
	tw.tween_property(g[1], "light_energy", 5.0, 0.06)
	tw.tween_property(g[1], "light_energy", 0.0, 1.2)

# a lava bomb arcs from a volcano and splashes down at the edge of the canyon
func _bomb() -> void:
	if bombs >= 10:
		return
	bombs += 1
	var vi: int = rng.randi() % lv.volcanoes.size()
	var a: Vector3 = lv.volcanoes[vi]["top"]
	var side := -1.0 if rng.randf() < 0.5 else 1.0
	var b := Vector3(side * rng.randf_range(7.0, 12.0), 0.2, rng.randf_range(-19.0, 7.0))
	var rock := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.7
	sph.height = 1.4
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.6, 0.2)
	sph.material = m
	rock.mesh = sph
	lv.add_child(rock)
	var trail := CPUParticles3D.new()
	trail.amount = 40
	trail.lifetime = 0.7
	trail.local_coords = false
	trail.mesh = Fx.quad(1.1, true)
	trail.gravity = Vector3(0, 1.0, 0)
	trail.initial_velocity_max = 0.5
	trail.scale_amount_curve = Fx.curve([[0.0, 1.0], [1.0, 0.2]])
	trail.color_ramp = Fx.ramp([[0.0, Color(1, 0.75, 0.3, 0.9)], [0.5, Color(0.9, 0.3, 0.05, 0.5)], [1.0, Color(0.3, 0.2, 0.2, 0)]])
	rock.add_child(trail)
	var arc := a.distance_to(b) * 0.35
	var dur := rng.randf_range(1.6, 2.3)
	var tw := create_tween()
	tw.tween_method(func(u: float): rock.global_position = a.lerp(b, u) + Vector3(0, arc * 4.0 * u * (1.0 - u), 0), 0.0, 1.0, dur)
	tw.tween_callback(func():
		_splash(b)
		bombs -= 1
		rock.queue_free())

func _splash(p: Vector3) -> void:
	var s := _blob_burst(0.14, 28, 1.4, 4.0, 8.0, 40.0, 12.0)
	s.position = p
	lv.add_child(s)
	s.restart()
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.15)
	l.omni_range = 8.0
	l.position = p + Vector3(0, 1.5, 0)
	lv.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "light_energy", 6.0, 0.05)
	tw.tween_property(l, "light_energy", 0.0, 0.9)
	tw.tween_callback(l.queue_free)
	get_tree().create_timer(2.0).timeout.connect(s.queue_free)
	_kick(0.18)

# ---------------------------------------------------------------- beats
func _beat_at(time: float) -> int:   # first beat at or after time (a little slack)
	for i in BEATS.size():
		if BEATS[i] >= time - 0.08:
			return i
	return BEATS.size() - 1

func _section(time: float) -> Array:
	var cur: Array = SECTIONS[0]
	for s in SECTIONS:
		if time >= s[0] - 0.08:
			cur = s
	return cur

func _on_beat(i: int) -> void:
	var bt: float = BEATS[i]
	var sec := _section(bt)
	var n: int = i - int(sec_first_beat.get(sec[0], i))
	var down := n % 4 == 0
	match sec[1]:
		"drop1":
			pulse = 1.0
			_kick(0.12 + (0.14 if down else 0.0))
			if down:
				_geyser(rng.randi() % geysers.size())
				_geyser(rng.randi() % geysers.size())
				_bomb()
				if n > 0 and n % 16 == 0:
					_erupt(next_volcano)
					next_volcano = (next_volcano + 1) % lv.volcanoes.size()
		"verse":
			pulse = 0.45
			if down:
				_kick(0.07)
				if n % 8 == 0:
					_geyser(rng.randi() % geysers.size())
		"drop2":
			pulse = 1.1
			_kick(0.15 + (0.16 if down else 0.0))
			if n % 2 == 0:
				_bomb()
			if down:
				_geyser(rng.randi() % geysers.size())
				_geyser(rng.randi() % geysers.size())
				if n > 0 and n % 8 == 0:
					_erupt(next_volcano)
					next_volcano = (next_volcano + 1) % lv.volcanoes.size()
		"solo":   # builds toward the final drop
			var k := clampf((bt - SOLO) / (HUSH - SOLO), 0.0, 1.0)
			pulse = 0.5 + 0.6 * k
			_kick((0.04 + 0.2 * k) * (1.0 if down else 0.5))
			if down:
				for j in 1 + int(k * 2.5):
					_geyser(rng.randi() % geysers.size())
				if k > 0.5:
					_bomb()
		"final":
			pulse = 1.3
			_kick(0.2 + (0.18 if down else 0.0))
			_bomb()
			_geyser(rng.randi() % geysers.size())
			if down and n > 0 and n % 8 == 0:
				_erupt(next_volcano)
				next_volcano = (next_volcano + 1) % lv.volcanoes.size()

func _tick(dt: float) -> void:
	while ev_i < events.size() and events[ev_i][0] <= t:
		events[ev_i][1].call()
		ev_i += 1
	while beat_i < BEATS.size() and BEATS[beat_i] <= t:
		if BEATS[beat_i] > t - 0.25:   # (skip beats we jumped past)
			_on_beat(beat_i)
		beat_i += 1
	trauma = maxf(0.0, trauma - dt * 1.7)
	pulse = maxf(0.0, pulse - dt * 3.2)
	dim = move_toward(dim, dim_target, dt * 1.6)
	var calm := 0.12 + 0.08 * sin(t * 1.4)   # the intro/outro: a slow breathing glow
	var glow := maxf(calm, pulse) * dim
	for m in lv.lava_mats:
		m.set_shader_parameter("pulse", glow * 0.7 - (1.0 - dim) * 0.5)
	for lb in lava_base:
		lb[0].light_energy = lb[1] * (0.3 + 0.7 * dim) * (1.0 + glow * 1.3)
	for v in lv.volcanoes:
		v["heat"] = maxf(0.0, v["heat"] - dt * 0.5)
		v["mat"].set_shader_parameter("heat", maxf(v["heat"], glow * 0.4))
	_update_camera()

# CHUD_SHOTS="27.5,81,125": jump to each time, let it play out a moment, screenshot, quit
func _test_shots(list: String) -> void:
	lv.fade_in(0.1)
	for b in bars:
		if b.anchor_top == 0.0:
			b.anchor_bottom = 0.1
		else:
			b.anchor_top = 0.9
	title.visible = false
	for s in list.split(","):
		var target := float(s)
		t = target
		ev_i = 0
		while ev_i < events.size() and events[ev_i][0] < t - 1.0:
			ev_i += 1
		beat_i = _beat_at(t - 0.2)
		var end_ms := Time.get_ticks_msec() + 2500
		while Time.get_ticks_msec() < end_ms:
			_tick(minf(get_process_delta_time(), 0.1))
			await get_tree().process_frame
		await lv.shot("chud_%05.1f" % target)
	get_tree().quit()

class SkipRing extends Control:
	var progress := 0.0
	var key_text := "E"
	func _draw() -> void:
		var r := 20.0
		var c := Vector2(size.x - r - 6.0, size.y * 0.5)
		draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.22), 5.0, true)
		if progress > 0.0:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, Color("#e8b923"), 5.0, true)
		var f := get_theme_default_font()
		var txt := "Hold [%s] to skip" % key_text
		var fs := 22
		var w := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2(c.x - r - 14.0 - w, c.y + fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.85))
