# Real 3D props and photo textures (Poly Haven, CC0) for the environment.
# Characters stay 2D cutouts; the world around them can be real models.
#   Models.place(parent, "wooden_crate_01", pos, rot_y, scale, collide)
#   Models.mat("weathered_planks", tile_m, tint)   → a world-space (triplanar) material: works on any box/cylinder
#   Models.block(parent, pos, size, material, rot_y, collide)
# Download more with: python3 tools/fetch_polyhaven.py model|texture <id>
class_name Models

static var _scenes := {}
static var _mats := {}

static func place(parent: Node, id: String, pos: Vector3, rot_y := 0.0, scl := 1.0, collide := false, recolor := Color.WHITE) -> Node3D:
	if not _scenes.has(id):
		_scenes[id] = load("res://assets/models/%s/%s.gltf" % [id, id])
	var n: Node3D = _scenes[id].instantiate()
	parent.add_child(n)
	n.global_position = pos
	n.rotation.y = rot_y
	n.scale = Vector3.ONE * scl
	if recolor != Color.WHITE:
		tint(n, recolor)
	if collide:
		var box := aabb(n)
		var c := box.get_center()
		Util.static_box(parent, n.global_transform * c, box.size * scl, rot_y)
	return n

# Recolor a placed model (multiplies its albedo), e.g. turn a white-painted chair into dark old wood
static func tint(n: Node3D, c: Color) -> void:
	for m in n.find_children("*", "MeshInstance3D", true, false):
		for i in m.mesh.get_surface_count():
			var src: Material = m.get_active_material(i)
			if src is BaseMaterial3D:
				var dup: BaseMaterial3D = src.duplicate()
				dup.albedo_color = dup.albedo_color * c
				m.set_surface_override_material(i, dup)

# Bounding box of a placed model in its own (unscaled) space
static func aabb(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var t := Transform3D.IDENTITY
		var q: Node = m
		while q != null and q != n:
			if q is Node3D:
				t = q.transform * t
			q = q.get_parent()
		var a: AABB = t * m.get_aabb()
		box = a if first else box.merge(a)
		first = false
	return box

static func mat(id: String, tile := 2.0, tint := Color.WHITE) -> StandardMaterial3D:
	var k := "%s|%s|%s" % [id, tile, tint]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	var dir := "res://assets/textures/%s/" % id
	m.albedo_texture = load(dir + "albedo.jpg")
	m.albedo_color = tint
	if ResourceLoader.exists(dir + "normal.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(dir + "normal.jpg")
	if ResourceLoader.exists(dir + "rough.jpg"):
		m.roughness_texture = load(dir + "rough.jpg")
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / tile
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[k] = m
	return m

static func block(parent: Node, pos: Vector3, size: Vector3, material: Material, rot_y := 0.0, collide := false) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := Util.add_mesh(parent, bm, material, pos, Vector3(0, rot_y, 0))
	if collide:
		Util.static_box(parent, pos, size, rot_y)
	return mi

static func cylinder(parent: Node, pos: Vector3, r_bottom: float, r_top: float, h: float, material: Material, sides := 16) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.bottom_radius = r_bottom
	cm.top_radius = r_top
	cm.height = h
	cm.radial_segments = sides
	return Util.add_mesh(parent, cm, material, pos + Vector3(0, h / 2.0, 0))

# A patch of real ground texture laid on the terrain with soft, ragged edges (cobblestones in front of a shop,
# burnt ground at the Pass…). size = metres, tile = metres per texture repeat.
static func patch(parent: Node, center: Vector3, size: Vector2, id: String, tile := 2.0, tint := Color.WHITE, rot_y := 0.0, soft := 0.35) -> MeshInstance3D:
	var sm := ShaderMaterial.new()
	sm.shader = _patch_shader()
	var dir := "res://assets/textures/%s/" % id
	sm.set_shader_parameter("albedo", load(dir + "albedo.jpg"))
	if ResourceLoader.exists(dir + "normal.jpg"):
		sm.set_shader_parameter("normal_tex", load(dir + "normal.jpg"))
	sm.set_shader_parameter("tile", tile)
	sm.set_shader_parameter("tint", tint)
	sm.set_shader_parameter("soft", soft)
	var pm := PlaneMesh.new()
	pm.size = size
	return Util.add_mesh(parent, pm, sm, center + Vector3(0, 0.015, 0), Vector3(0, rot_y, 0))

static var _patch_sh: Shader
static func _patch_shader() -> Shader:
	if _patch_sh == null:
		_patch_sh = Shader.new()
		_patch_sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tile = 2.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float soft = 0.35;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 uv = wpos.xz / tile;
	vec4 c = texture(albedo, uv);
	ALBEDO = c.rgb * tint.rgb;
	NORMAL_MAP = texture(normal_tex, uv).rgb;
	ROUGHNESS = 0.9;
	vec2 e = abs(UV - 0.5) * 2.0;
	float d = length(max(e - 0.35, 0.0)) / 0.65;
	d += (n2(wpos.xz * 0.9) - 0.5) * 0.35;
	ALPHA = 1.0 - smoothstep(1.0 - soft, 1.0, d);
}
"""
	return _patch_sh
