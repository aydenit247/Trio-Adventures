# A rigged 3D body for one of the trio (Meshy model, Mixamo skeleton, clips baked into the GLB), used for
# walking around: stand / walk / run, idle clip after 15 s still. Unit creates one when res://assets/characters3d/<id>.glb exists.
# Fights and posed moments stay on the original 2D art (Asar's call): Unit swaps back to the billboard then.
extends Node3D
class_name Char3D

const DIR := "res://assets/characters3d/%s.glb"
const BLEND := 0.18
const RUN_SPEED := 5.2     # flat m/s above which the run clip plays
const IDLE_AFTER := 15.0   # seconds standing still before the idle clip starts (Asar); until then: hold still

# Clip names as Meshy exported them (same for all three).
const CLIPS := { "idle": "Idle", "walk": "Walking", "run": "Running", "down": "dying_backwards" }
# "down" (falling over backward) is only in Skorn's GLB for now: his tent nap in camp (Asar). Others stay 2D on a knock.

var id := ""
var model: Node3D
var anim: AnimationPlayer
var clips := {}             # role → clip present in this GLB
var _mats: Array[StandardMaterial3D] = []
var _fill := Color(-1, 0, 0)
var _walk_ref := 1.5        # m/s the walk clip covers at speed 1 (scaled with the body)
var _run_ref := 4.2
var _still := 0.0           # seconds since we last moved
var down := false           # lying on the ground (fell over); locomotion waits

static func has_model(_id: String) -> bool:
	return ResourceLoader.exists(DIR % _id)

func setup(_id: String, height: float) -> void:
	id = _id
	name = "Char3D"
	model = (load(DIR % _id) as PackedScene).instantiate()
	add_child(model)
	# Scale to the unit's height (Meshy exports ~1.7 m tall, feet at 0).
	var s := height / maxf(_bounds(model).size.y, 0.1)
	model.scale = Vector3.ONE * s
	_walk_ref *= s / 1.12
	_run_ref *= s / 1.12
	for m: MeshInstance3D in _meshes(model):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# Own material copies so set_fill() tints this body only
		for i in m.mesh.get_surface_count():
			var mat: Material = m.get_active_material(i)
			if mat is StandardMaterial3D:
				var mm: StandardMaterial3D = mat.duplicate()
				mm.emission_enabled = true
				mm.emission_texture = mm.albedo_texture
				mm.emission = Color.BLACK
				m.set_surface_override_material(i, mm)
				_mats.append(mm)
	anim = _find_anim(model)
	if anim == null:
		push_warning("Char3D %s: no AnimationPlayer in the GLB" % _id)
		return
	var have := anim.get_animation_list()
	for role in CLIPS:
		if CLIPS[role] in have:
			clips[role] = CLIPS[role]
			anim.get_animation(CLIPS[role]).loop_mode = Animation.LOOP_NONE if role == "down" else Animation.LOOP_LINEAR
	if clips.has("idle"):   # start standing still (no idle motion at launch)
		anim.play(clips["idle"])
		anim.seek(0.0, true)
		anim.speed_scale = 0.0

# Every frame from Unit.drive(): turn toward the way we're going, pick idle / walk / run, match the pace.
func locomote(vel: Vector3, delta: float) -> void:
	var flat := Vector3(vel.x, 0, vel.z)
	var spd := flat.length()
	if spd > 0.4:
		rotation.y = lerp_angle(rotation.y, atan2(flat.x, flat.z), clampf(delta * 12.0, 0.0, 1.0))
	if anim == null or down:
		return
	if spd > 0.4:
		_still = 0.0
	if spd > RUN_SPEED and clips.has("run"):
		_loop("run", clampf(spd / _run_ref, 0.7, 1.8))
	elif spd > 0.4:
		_loop("walk", clampf(spd / _walk_ref, 0.6, 2.2))
	else:
		_still += delta
		_stand(_still)

func can_fall() -> bool:
	return clips.has("down")

# level.knock() → fall over backward and stay down; unknock → stand back up. instant = already lying there
# (e.g. the camp reloading in the morning with Skorn still face-down).
func set_down(on: bool, instant := false) -> void:
	if on == down or not clips.has("down"):
		return
	down = on
	if on:
		anim.play(clips["down"], 0.1)
		anim.speed_scale = 1.0
		if instant:
			anim.seek(anim.current_animation_length, true)
	else:
		_still = 0.0
		anim.play(clips["idle"], 0.3)
		anim.seek(0.0, true)
		anim.speed_scale = 1.0

# Standing: blend into the idle clip's first pose and hold it still; after IDLE_AFTER seconds let it play.
func _stand(t: float) -> void:
	if not clips.has("idle"):
		return
	if anim.current_animation != clips["idle"]:
		anim.play(clips["idle"], BLEND)
		anim.seek(0.0, true)
		anim.speed_scale = 1.0
	if t >= IDLE_AFTER:
		anim.speed_scale = 1.0
	elif t > BLEND:
		anim.speed_scale = 0.0   # blend from walking is done: freeze on the standing pose

# The billboards get lit by level.light_at() (campfire, moon, torches) instead of real lights, and night
# scenes are tuned for that. Unit passes that colour in night areas as a soft glow of the model's own
# texture so the 3D trio isn't a black shape away from the fire (Color.BLACK = off, used in daylight).
const FILL := 0.18
func set_fill(c: Color) -> void:
	if c.is_equal_approx(_fill):
		return
	_fill = c
	var e := Color(c.r * FILL, c.g * FILL, c.b * FILL)
	for mm in _mats:
		mm.emission = e

func _loop(role: String, spd := 1.0) -> void:
	if not clips.has(role):
		return
	if anim.current_animation != clips[role]:
		anim.play(clips[role], BLEND)
	anim.speed_scale = spd

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var a := _find_anim(c)
		if a:
			return a
	return null

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out

func _bounds(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m: MeshInstance3D in _meshes(n):
		box = m.get_aabb() if first else box.merge(m.get_aabb())
		first = false
	return box
