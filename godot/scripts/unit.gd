# A character standing in the 3D world as a 2D cutout (2.5D).
# The cutout always turns to face the camera, gets lit by the campfire/moon and casts a shadow.
extends CharacterBody3D
class_name Unit

signal stepped

var id := ""
var display_name := ""
var sprite: Sprite3D
var height_m := 1.9
var walk_speed := 4.2
var run_speed := 7.0
var moving := false
var frozen := false

# following
var follow_slot := 0          # 0 = leader, 1/2 = followers
var trail: Array[Vector3] = []  # leader's breadcrumb trail (newest first)

var _bob := 0.0
var _idle := randf() * TAU
var _last_step_sign := 1.0
const GRAVITY := 20.0

func setup(_id: String, _name: String, tex: Texture2D, h: float) -> void:
	id = _id
	display_name = _name
	height_m = h
	collision_layer = 2   # units don't push each other
	collision_mask = 1    # but do bump into the world

	sprite = Sprite3D.new()
	sprite.texture = tex
	sprite.pixel_size = h / float(tex.get_height())
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.shaded = false   # lit by main.gd → light_at() instead (reads better for cutouts)
	sprite.double_sided = true
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	sprite.offset = Vector2(0, tex.get_height() / 2.0)
	add_child(sprite)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.4
	col.shape = cap
	col.position.y = 0.7
	add_child(col)

	add_child(Util.blob_shadow(0.5 + h * 0.12))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5
	move_and_slide()

# Called every frame by main.gd with the wanted horizontal direction (length 0..1)
func drive(dir: Vector3, running: bool, cam_right: Vector3, delta: float) -> void:
	if frozen:
		dir = Vector3.ZERO
	var spd := run_speed if running else walk_speed
	var target := dir * spd
	velocity.x = lerp(velocity.x, target.x, clamp(delta * 12.0, 0.0, 1.0))
	velocity.z = lerp(velocity.z, target.z, clamp(delta * 12.0, 0.0, 1.0))
	var flat := Vector2(velocity.x, velocity.z).length()
	moving = flat > 0.4

	# Face left/right relative to the camera
	var side := Vector3(velocity.x, 0, velocity.z).dot(cam_right)
	if side < -0.6:
		sprite.flip_h = true
	elif side > 0.6:
		sprite.flip_h = false

	# Bouncy cutout walk + idle breathing
	if moving:
		_bob += delta * flat * 2.4
		var s := sin(_bob)
		sprite.position.y = abs(s) * 0.09
		sprite.scale = Vector3(1.0 + abs(s) * 0.02, 1.0 - abs(s) * 0.03, 1.0)
		var sg := signf(s)
		if sg != _last_step_sign:
			_last_step_sign = sg
			stepped.emit()
	else:
		_idle += delta * 2.0
		sprite.position.y = lerp(sprite.position.y, 0.0, delta * 10.0)
		sprite.scale = Vector3(1.0, 1.0 + sin(_idle) * 0.008, 1.0)

# Leader keeps a breadcrumb trail; followers walk to a point on it
func record_trail() -> void:
	var p := global_position
	if trail.is_empty() or trail[0].distance_to(p) > 0.25:
		trail.push_front(p)
		if trail.size() > 80:
			trail.pop_back()

func follow_point(leader: Unit, dist: float) -> Vector3:
	var acc := 0.0
	var prev := leader.global_position
	for p in leader.trail:
		acc += prev.distance_to(p)
		if acc >= dist:
			return p
		prev = p
	return leader.trail.back() if not leader.trail.is_empty() else leader.global_position
