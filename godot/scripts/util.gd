# Small helpers for building the world in code.
extends RefCounted
class_name Util

static func mat(color: Color, rough := 0.9) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m

# Soft round white→clear texture (for glows, particles and blob shadows)
static func radial_tex(size := 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t

# Dark soft circle on the ground under a character, so cutouts feel planted
static func blob_shadow(radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(radius * 2.0, radius * 1.4)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0, 0.55)
	m.albedo_texture = radial_tex()
	mi.material_override = m
	mi.position.y = 0.03
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi

static func add_mesh(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func static_box(parent: Node3D, pos: Vector3, size: Vector3, rot_y := 0.0) -> void:
	var b := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	c.shape = s
	b.add_child(c)
	b.position = pos
	b.rotation.y = rot_y
	parent.add_child(b)

static func static_cyl(parent: Node3D, pos: Vector3, radius: float, height := 3.0) -> void:
	var b := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := CylinderShape3D.new()
	s.radius = radius
	s.height = height
	c.shape = s
	c.position.y = height / 2.0
	b.add_child(c)
	b.position = pos
	parent.add_child(b)

# Short procedural sound effects (no audio files needed yet)
static func noise_burst(ms := 70, lowpass := 0.25, vol := 0.6) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * ms / 1000.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	var y := 0.0
	for i in n:
		var env := pow(1.0 - float(i) / n, 2.0)
		y += (randf() * 2.0 - 1.0 - y) * lowpass
		var v := int(clamp(y * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w

static func chime(freq := 880.0, ms := 300, vol := 0.25) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * ms / 1000.0)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 9.0)
		var v := (sin(TAU * freq * t) + 0.5 * sin(TAU * freq * 1.5 * t)) * env * vol
		data.encode_s16(i * 2, int(clamp(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w
