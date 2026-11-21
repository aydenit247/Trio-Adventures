# Reusable particle effects.
extends RefCounted
class_name Fx

static func quad(size: float, additive: bool) -> QuadMesh:
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

static func ramp(stops: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(stops.map(func(s): return s[0]))
	g.colors = PackedColorArray(stops.map(func(s): return s[1]))
	return g

static func curve(points: Array) -> Curve:
	var c := Curve.new()
	for p in points:
		c.add_point(Vector2(p[0], p[1]))
	return c

static func flames(scale := 1.0) -> CPUParticles3D:
	var f := CPUParticles3D.new()
	f.amount = 80
	f.lifetime = 0.9
	f.mesh = quad(0.6 * scale, true)
	f.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	f.emission_sphere_radius = 0.22 * scale
	f.direction = Vector3.UP
	f.spread = 12.0
	f.gravity = Vector3(0, 1.8, 0)
	f.initial_velocity_min = 0.5
	f.initial_velocity_max = 1.2
	f.scale_amount_min = 0.6
	f.scale_amount_max = 1.25
	f.scale_amount_curve = curve([[0.0, 0.7], [0.25, 1.0], [1.0, 0.1]])
	f.color_ramp = ramp([[0.0, Color(1.0, 0.95, 0.6, 1)], [0.3, Color(1.0, 0.55, 0.12, 0.9)], [0.7, Color(0.8, 0.15, 0.05, 0.5)], [1.0, Color(0.2, 0.05, 0.02, 0)]])
	return f

static func embers() -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.amount = 30
	e.lifetime = 2.6
	e.mesh = quad(0.06, true)
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	e.emission_sphere_radius = 0.3
	e.direction = Vector3.UP
	e.spread = 25.0
	e.gravity = Vector3(0, 0.4, 0)
	e.initial_velocity_min = 1.0
	e.initial_velocity_max = 2.4
	e.color_ramp = ramp([[0.0, Color(1, 0.7, 0.3, 1)], [1.0, Color(1, 0.3, 0.1, 0)]])
	return e

# One-shot puff (goblins popping out of the bushes, etc.)
static func poof(color := Color(0.85, 0.8, 0.7)) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 24
	p.lifetime = 0.8
	p.mesh = quad(0.5, false)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3(0, 0.5, 0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.0
	p.scale_amount_curve = curve([[0.0, 0.5], [1.0, 1.4]])
	p.color_ramp = ramp([[0.0, Color(color, 0.7)], [1.0, Color(color, 0.0)]])
	return p
