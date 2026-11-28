# Ambient particles + a soft color grade per area (Ebain 11/27, AAA batch). Level._ready adds one to every area,
# next to AreaSfx; Level.apply_graphics() calls apply() whenever graphics settings change.
#   Particles follow the leader (world-space, so they stay put while you walk through them). They complement what
#   areas already have (camp fireflies, Pass ash, library/summit motes) instead of doubling them:
#     camp by day: pollen · trail: falling leaves + pollen · village: pollen + a few leaves · Mart street: fireflies
#     ruins: dust in the sun + leaves · cave: dust in the torchlight · Pass: a few bright embers · summit: snow flurries
#   Hidden indoors (Mart shop, Charis's house, village rooms, Mattias's hall). Amount scales with Graphics quality.
#   Settings → Display → Ambient particles (Game.ambient_fx).
# Color grade: a gentle shadows/highlights tint through Environment.adjustment_color_correction (a per-channel curve)
# plus tiny contrast/saturation nudges on top of the area's own values. Ebain: "visually pleasant", NOT the old
# too-red Pass, so the Pass grade actually pulls red DOWN a touch. Settings → Display → Color grading (Game.color_grade).
extends Node3D
class_name AreaFx

# area look -> [shadow tint (added at black), highlight tint (multiplied at white), contrast delta, saturation delta]
const GRADES := {
	"day":     [Color(0.0, 0.008, 0.016), Color(1.0, 0.985, 0.95), 0.02, 0.03],    # warm sun, a hint of teal shade
	"night":   [Color(0.0, 0.01, 0.035), Color(0.98, 0.985, 1.0), 0.02, 0.0],      # moonlit blue shadows
	"mart":    [Color(0.012, 0.0, 0.025), Color(1.0, 0.975, 0.94), 0.03, 0.02],    # purple dusk, amber lamps
	"pass":    [Color(0.0, 0.006, 0.022), Color(0.975, 0.985, 0.985), 0.02, -0.06], # cooler shadows, less red
	"summit":  [Color(0.0, 0.012, 0.04), Color(0.97, 0.98, 1.0), 0.03, -0.02],     # cold mountain night
	"cave":    [Color(0.004, 0.002, 0.01), Color(1.0, 0.97, 0.92), 0.03, 0.0],     # warm torchlight
	"library": [Color(0.01, 0.0, 0.02), Color(1.0, 0.98, 0.93), 0.02, 0.0],        # old gold
	"ruins":   [Color(0.0, 0.006, 0.012), Color(1.0, 0.975, 0.93), 0.02, 0.02],    # dusty afternoon
}

var lv: Level
var _fx: Array = []          # [CPUParticles3D, base amount]
var _base := {}              # the area's own contrast/saturation/color correction
var _indoor_last := false

func setup(level: Level) -> void:
	lv = level
	var env := _env()
	if env:
		_base = { "c": env.adjustment_contrast, "s": env.adjustment_saturation, "cc": env.adjustment_color_correction }
	match lv.area_key():
		"camp":
			if not lv.night:
				_add(_pollen())
		"trail":
			_add(_leaves(Color(0.75, 0.55, 0.2), Color(0.55, 0.6, 0.18), 34))
			_add(_pollen())
		"village":
			_add(_pollen())
			_add(_leaves(Color(0.7, 0.5, 0.2), Color(0.6, 0.45, 0.2), 14))
		"mart":
			_add(_fireflies())
		"ruins":
			_add(_dust(Color(1.0, 0.92, 0.72, 0.5), 50))
			_add(_leaves(Color(0.62, 0.48, 0.25), Color(0.5, 0.42, 0.22), 12))
		"cave":
			_add(_dust(Color(1.0, 0.8, 0.55, 0.35), 40))
		"pass":
			_add(_embers())
		"summit":
			_add(_snow())
	apply()

func _env() -> Environment:
	return lv.world_env.environment if lv and lv.world_env else null

func _look() -> String:
	var k := lv.area_key()
	if GRADES.has(k):
		return k
	if k == "camp" and lv.night:
		return "night"
	return "night" if lv.night else "day"

# Called on setup and from Level.apply_graphics() (settings changed).
func apply() -> void:
	var q: float = [0.4, 0.7, 1.0, 1.3][clampi(Game.quality, 0, 3)]
	for f in _fx:
		var p: CPUParticles3D = f[0]
		p.amount = maxi(4, int(f[1] * q))
		p.emitting = Game.ambient_fx and not _indoor_last
		p.visible = Game.ambient_fx and not _indoor_last
	var env := _env()
	if env == null or _base.is_empty():
		return
	if not Game.color_grade:
		env.adjustment_contrast = _base["c"]
		env.adjustment_saturation = _base["s"]
		env.adjustment_color_correction = _base["cc"]
		return
	var g: Array = GRADES[_look()]
	env.adjustment_enabled = true
	env.adjustment_contrast = _base["c"] + g[2]
	env.adjustment_saturation = _base["s"] + g[3]
	env.adjustment_color_correction = _curve(g[0], g[1])

# A per-channel lookup curve (Godot reads a 1D texture's R, G and B separately): lifts black toward `lo`, scales white
# toward `hi`, straight line in between. Strength is tiny on purpose.
static func _curve(lo: Color, hi: Color) -> GradientTexture1D:
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 1.0])
	gr.colors = PackedColorArray([Color(lo.r, lo.g, lo.b, 1.0), Color(hi.r, hi.g, hi.b, 1.0)])
	var t := GradientTexture1D.new()
	t.gradient = gr
	t.width = 256
	t.use_hdr = false
	return t

func _process(_d: float) -> void:
	if lv == null or lv.leader == null or _fx.is_empty():
		return
	var p := lv.leader.global_position
	for f in _fx:
		f[0].global_position = Vector3(p.x, f[0].global_position.y, p.z)
	var indoor := _indoors()
	if indoor != _indoor_last:
		_indoor_last = indoor
		for f in _fx:
			f[0].visible = Game.ambient_fx and not indoor
			f[0].emitting = Game.ambient_fx and not indoor

func _indoors() -> bool:
	if lv.get("inside") == true or lv.get("in_house") == true:
		return true
	var vb = lv.get("vb")
	if vb and str(vb.get("room")) != "":
		return true
	return false

# ---------------------------------------------------------------- the particle kinds
func _add(p: CPUParticles3D) -> void:
	p.local_coords = false
	p.preprocess = p.lifetime   # already drifting when you arrive
	add_child(p)
	_fx.append([p, p.amount])

func _base_p(n: int, life: float, ext: Vector3, y: float, mesh: Mesh) -> CPUParticles3D:
	var a := CPUParticles3D.new()
	a.amount = n
	a.lifetime = life
	a.mesh = mesh
	a.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	a.emission_box_extents = ext
	a.position = Vector3(0, y, 0)
	a.randomness = 0.5
	return a

func _pollen() -> CPUParticles3D:   # tiny warm specks hanging in the sunlight
	var a := _base_p(60, 9.0, Vector3(14, 2.2, 14), 1.8, Fx.quad(0.035, true))
	a.gravity = Vector3(0.04, 0.01, 0.02)
	a.direction = Vector3.UP
	a.spread = 180.0
	a.initial_velocity_min = 0.03
	a.initial_velocity_max = 0.12
	var c := Color(1.0, 0.95, 0.75)
	a.color_ramp = Fx.ramp([[0.0, Color(c, 0)], [0.25, Color(c, 0.55)], [0.75, Color(c, 0.55)], [1.0, Color(c, 0)]])
	return a

func _dust(c: Color, n: int) -> CPUParticles3D:   # slow motes (ruins sunbeams, cave torchlight)
	var a := _base_p(n, 10.0, Vector3(10, 1.8, 10), 1.6, Fx.quad(0.03, true))
	a.gravity = Vector3(0, -0.005, 0)
	a.direction = Vector3.UP
	a.spread = 180.0
	a.initial_velocity_min = 0.02
	a.initial_velocity_max = 0.08
	a.color_ramp = Fx.ramp([[0.0, Color(c, 0)], [0.3, c], [0.7, c], [1.0, Color(c, 0)]])
	return a

func _fireflies() -> CPUParticles3D:   # the Mart street at dusk (camp night already has its own)
	var a := _base_p(36, 7.0, Vector3(14, 1.2, 14), 1.3, Fx.quad(0.07, true))
	a.gravity = Vector3.ZERO
	a.direction = Vector3.UP
	a.spread = 180.0
	a.initial_velocity_min = 0.08
	a.initial_velocity_max = 0.3
	var c := Color(0.85, 1.0, 0.45)
	a.color_ramp = Fx.ramp([[0.0, Color(c, 0)], [0.2, c], [0.35, Color(c, 0.2)], [0.5, c], [0.8, Color(c, 0.9)], [1.0, Color(c, 0)]])   # blinks
	return a

func _embers() -> CPUParticles3D:   # a few bright sparks rising off the lava (the Pass has its own ash)
	var a := _base_p(18, 4.0, Vector3(12, 0.3, 12), 0.2, Fx.quad(0.05, true))
	a.gravity = Vector3(0.1, 0.35, 0)
	a.direction = Vector3.UP
	a.spread = 25.0
	a.initial_velocity_min = 0.4
	a.initial_velocity_max = 1.0
	a.color_ramp = Fx.ramp([[0.0, Color(1, 0.75, 0.3, 0)], [0.15, Color(1, 0.8, 0.4, 1)], [1.0, Color(1, 0.35, 0.1, 0)]])
	return a

func _snow() -> CPUParticles3D:   # light flurries blowing across the summit
	var a := _base_p(110, 6.0, Vector3(16, 0.5, 16), 7.0, Fx.quad(0.05, false))
	a.gravity = Vector3(0.6, -0.9, 0.15)
	a.direction = Vector3(1, -0.3, 0)
	a.spread = 20.0
	a.initial_velocity_min = 0.3
	a.initial_velocity_max = 0.9
	var c := Color(0.92, 0.95, 1.0)
	a.color_ramp = Fx.ramp([[0.0, Color(c, 0)], [0.15, Color(c, 0.8)], [0.85, Color(c, 0.8)], [1.0, Color(c, 0)]])
	return a

func _leaves(c1: Color, c2: Color, n: int) -> CPUParticles3D:   # flat, tumbling, drifting down
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_texture = Util.radial_tex()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	var a := _base_p(n, 9.0, Vector3(14, 0.5, 14), 6.5, q)
	a.gravity = Vector3(0.25, -0.45, 0.1)
	a.direction = Vector3(1, 0, 0)
	a.spread = 60.0
	a.initial_velocity_min = 0.1
	a.initial_velocity_max = 0.4
	a.angle_min = 0.0
	a.angle_max = 360.0
	a.angular_velocity_min = -90.0
	a.angular_velocity_max = 90.0
	a.scale_amount_min = 0.7
	a.scale_amount_max = 1.3
	a.color_initial_ramp = Fx.ramp([[0.0, c1], [1.0, c2]])
	a.color_ramp = Fx.ramp([[0.0, Color(1, 1, 1, 0)], [0.1, Color(1, 1, 1, 0.9)], [0.85, Color(1, 1, 1, 0.9)], [1.0, Color(1, 1, 1, 0)]])
	return a
