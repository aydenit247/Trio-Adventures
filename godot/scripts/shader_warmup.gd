# Shader warm-up (Ebain 11/27, shipping polish). The first time Godot draws a new kind of material it has to compile it
# for the GPU, which is the little hitch you feel on the first hit of a fight, the first lightning, the first menu blur.
# Level._ready adds one of these while the loading card is still covering the screen: it draws one tiny copy of every
# effect material the fights/menus use (right in front of the camera, a few frames), then deletes itself.
# New effect with its own material setup? Add a copy to _materials() / _canvas_shaders().
extends Node3D
class_name ShaderWarmup

const FRAMES := 4

var lv: Level

func setup(level: Level) -> void:
	lv = level
	if DisplayServer.get_name() == "headless" or lv.cam == null:
		queue_free()
		return
	for i in _materials().size():
		var q := QuadMesh.new()
		q.size = Vector2(0.01, 0.01)
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = _materials()[i]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		mi.position = Vector3(-0.02 + 0.004 * i, 0, 0)
	for add in [true, false]:   # particles (Fx.quad) draw through the particle path
		var p := CPUParticles3D.new()
		p.amount = 2
		p.lifetime = 0.2
		p.mesh = Fx.quad(0.01, add)
		p.emitting = true
		add_child(p)
	var cl := CanvasLayer.new()
	cl.layer = -100
	add_child(cl)
	for code in _canvas_shaders():
		var r := ColorRect.new()
		r.size = Vector2(2, 2)
		var m := ShaderMaterial.new()
		m.shader = Shader.new()
		m.shader.code = code
		r.material = m
		cl.add_child(r)
	_run()

func _run() -> void:
	for f in FRAMES:
		if is_instance_valid(lv.cam):
			global_transform = lv.cam.global_transform.translated_local(Vector3(0, 0, -1.0))
		await get_tree().process_frame
	queue_free()

func _materials() -> Array:
	var out := []
	var tex := Util.radial_tex()
	# combat hit bursts (battle_view._burst): unshaded, billboard, alpha, vertex color
	var a := StandardMaterial3D.new()
	a.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	a.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	a.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	a.vertex_color_use_as_albedo = true
	out.append(a)
	# glow quads (lightning art, magic): additive, no culling, textured, fixed-Y billboard
	var g := StandardMaterial3D.new()
	g.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	g.cull_mode = BaseMaterial3D.CULL_DISABLED
	g.albedo_texture = tex
	g.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	out.append(g)
	var g2: StandardMaterial3D = g.duplicate()   # flat on the ground (scorch marks)
	g2.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	out.append(g2)
	# the plain lightning bolt: unshaded opaque, no culling
	var l := StandardMaterial3D.new()
	l.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	l.cull_mode = BaseMaterial3D.CULL_DISABLED
	out.append(l)
	# textured alpha cutouts (cards, signs) + a lit, transparent prop
	var c := StandardMaterial3D.new()
	c.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	c.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	c.albedo_texture = tex
	c.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	out.append(c)
	var t := StandardMaterial3D.new()
	t.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	t.albedo_color = Color(1, 1, 1, 0.5)
	out.append(t)
	return out

func _canvas_shaders() -> Array:
	return [InventoryUI.BLUR_SHADER, "shader_type canvas_item;\nvoid fragment(){ vec2 d = UV - 0.5; COLOR = vec4(0,0,0, smoothstep(0.25, 0.85, length(d)) * 0.8); }"]
