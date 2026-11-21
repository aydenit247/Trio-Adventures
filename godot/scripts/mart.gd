# Area: Metocy Mart (Scene 3, played as Xylo). Evening, foggy.
# Outside: walk up to the shop → Dulbers pops out → go inside.
# Inside: the "metocy" → choose: A everyone takes it · B Skorn first · C refuse · D Xylo inspects · E goblins (secret)
# The shop front and the shop room are Ebain's painted backgrounds standing as stage-set backdrops, so the camera
# stays facing them here (no camera turning in this area).
extends Level

const MS = preload("res://scripts/mart_script.gd")
const INT := Vector3(300, 0, 0)                    # the shop room is built off to the side
const DOOR_OUT := Vector3(-2.9, 0, -10.5)          # in front of the painted door
const COUNTER := INT + Vector3(0, 0, -3.0)
const DOOR_IN := INT + Vector3(5.2, 0, 2.8)
const EXIT_POS := Vector3(14, 0, 0)

# "outside" → "arrived" (go inside) → "inside" → "after" (walk east) → "end"
var stage := "outside"
var inside := false
var dulbers: Unit
var pill: Sprite3D
var pill_light: OmniLight3D
var room_backdrop: StandardMaterial3D
var tripping := false
var trip_overlay: ColorRect
var allies: Array[Unit] = []
var chief: Unit
var pass_sign: Node3D

func _configure() -> void:
	night = true
	light_dir = Vector3(0.5, 0.25, -0.8)
	clear_center = Vector2(0, -2)
	clear_radius = 7.0
	path_pts = PackedVector2Array([Vector2(0, 16), Vector2(0, 6), Vector2(-1.5, -4), Vector2(-2.9, -11), Vector2(0, -1), Vector2(8, 0), Vector2(16, 0)])
	path_width = 1.8
	subtitle = "Scene 3 — Metocy Mart"
	party_ids = ["xylo", "lykor"] if Game.flag("skornKing") else ["xylo", "lykor", "skorn"]
	party_start = [Vector3(0, 0, 10), Vector3(-1, 0, 12), Vector3(1, 0, 12)]
	leader_id = "xylo"
	cam_locked = true
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	talk = {
		"lykor": [{ "who": "lykor", "mood": "smug", "line": "A store in the middle of nowhere. Totally normal." }], # DRAFT
		"skorn": [{ "who": "skorn", "mood": "confused", "line": "You think they got snacks?" }], # DRAFT
	}

func _build_level() -> void:
	# ---- outside: the painted shop front as a backdrop, real props in front
	backdrop("res://assets/backdrops/mart_exterior.jpg", 24.0, Vector3(0, -0.3, -12.5), Color(0.85, 0.87, 0.95))
	add_glow(Vector3(-5.5, 1.5, -11), Color(1.0, 0.7, 0.4), 6.0, func(): return 1.0)
	add_glow(Vector3(4.0, 1.5, -11), Color(1.0, 0.7, 0.4), 6.0, func(): return 1.0)
	for p in [Vector3(-5.5, 2.5, -11.5), Vector3(4.0, 2.5, -11.5)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.4
		l.omni_range = 7.0
		l.position = p
		add_child(l)
	for k in 14:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(8.5, 16.0), 0, rng.randf_range(-11, 14))
		if p.x > 0 and abs(p.z) < 3.0:
			continue
		card("tree_%d" % (rng.randi() % 4 + 1), rng.randf_range(6.0, 9.0), p, rng.randf() < 0.5, true)
	for k in 12:
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector3(side * rng.randf_range(6.5, 9.0), 0, rng.randf_range(-9, 12))
		if p.x > 0 and abs(p.z) < 3.0:
			continue
		card("bush_%d" % (rng.randi() % 3 + 1) if rng.randf() < 0.7 else "rock_%d" % [1, 4][rng.randi() % 2], rng.randf_range(1.2, 2.0), p, rng.randf() < 0.5, true)
	_walls(Vector3.ZERO, 9.5, -11.5, 14.0, true)
	# ---- inside: the shop room
	_build_room()
	dulbers = spawn_npc("dulbers", "Dulbers Frint", "dulbers", 1.3, DOOR_OUT + Vector3(0, 0, -0.5))
	dulbers.visible = false
	if Game.flag("goblinAllies"):
		chief = spawn_npc("chief", "Chief Bogdrinker", "goblin_chief", 1.45, Vector3(0, 0, 14))
		chief.set_meta("follow", true)
		chief.set_meta("follow_i", 0)
		allies.append(chief)
		for i in 3:
			var g := spawn_npc("goblin", "Goblin", "goblin", rng.randf_range(1.1, 1.3), Vector3(rng.randf_range(-2, 2), 0, 15 + i))
			g.set_meta("follow", true)
			g.set_meta("follow_i", i + 1)
			allies.append(g)

func _walls(c: Vector3, half_x: float, back_z: float, front_z: float, east_gap: bool) -> void:
	Util.static_box(self, c + Vector3(-half_x, 1, (back_z + front_z) / 2.0), Vector3(0.5, 2, front_z - back_z))
	if east_gap:
		Util.static_box(self, c + Vector3(half_x, 1, (back_z - 2.2) / 2.0), Vector3(0.5, 2, -2.2 - back_z))
		Util.static_box(self, c + Vector3(half_x, 1, (front_z + 2.2) / 2.0), Vector3(0.5, 2, front_z - 2.2))
		Util.static_box(self, c + Vector3(18, 1, 0), Vector3(0.5, 2, 8))
		Util.static_box(self, c + Vector3(13.5, 1, -2.4), Vector3(9, 2, 0.5))
		Util.static_box(self, c + Vector3(13.5, 1, 2.4), Vector3(9, 2, 0.5))
	else:
		Util.static_box(self, c + Vector3(half_x, 1, (back_z + front_z) / 2.0), Vector3(0.5, 2, front_z - back_z))
	Util.static_box(self, c + Vector3(0, 1, back_z), Vector3(half_x * 2, 2, 0.5))
	Util.static_box(self, c + Vector3(0, 1, front_z), Vector3(half_x * 2, 2, 0.5))

func _build_room() -> void:
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(16, 1, 14)
	cs.shape = bs
	cs.position = INT + Vector3(0, -0.5, 0)
	floor_body.add_child(cs)
	add_child(floor_body)
	var fm := ShaderMaterial.new()
	fm.shader = Shader.new()
	fm.shader.code = PLANK_SHADER
	var pm := PlaneMesh.new()
	pm.size = Vector2(16, 14)
	Util.add_mesh(self, pm, fm, INT + Vector3(0, 0.001, 0))
	room_backdrop = backdrop("res://assets/backdrops/mart_interior.jpg", 14.0, INT + Vector3(0, 0, -5.0), Color(0.9, 0.85, 0.8))
	var wall_m := Util.mat(Color(0.1, 0.065, 0.045))
	wall_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var wall := PlaneMesh.new()
	wall.size = Vector2(14, 8)
	Util.add_mesh(self, wall, wall_m, INT + Vector3(-7.0, 4, 2), Vector3(0, 0, -PI / 2.0))
	Util.add_mesh(self, wall, wall_m, INT + Vector3(7.0, 4, 2), Vector3(0, 0, PI / 2.0))
	var shell := PlaneMesh.new()   # dark back wall + ceiling so no sky shows around the backdrop
	shell.size = Vector2(40, 20)
	Util.add_mesh(self, shell, wall_m, INT + Vector3(0, 6, -5.3), Vector3(PI / 2.0, 0, 0))
	Util.add_mesh(self, shell, wall_m, INT + Vector3(0, 7.6, 0), Vector3(PI, 0, 0))
	_walls(INT, 6.5, -4.2, 5.5, false)
	add_glow(INT + Vector3(0, 1, -1), Color(1.0, 0.72, 0.45), 10.0, func(): return 0.75, true)
	for p in [INT + Vector3(-4.5, 2, -3.5), INT + Vector3(4.5, 2, -3.5), INT + Vector3(0, 3, 0)]:
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.7, 0.4)
		l.light_energy = 1.6
		l.omni_range = 8.0
		l.position = p
		add_child(l)
	pill = Sprite3D.new()
	pill.texture = load("res://assets/items/metocy.png")
	pill.pixel_size = 0.5 / 447.0
	pill.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pill.shaded = false
	pill.position = COUNTER + Vector3(0, 1.4, 0.3)
	pill.visible = false
	add_child(pill)
	pill_light = OmniLight3D.new()
	pill_light.light_color = Color(0.4, 0.7, 1.0)
	pill_light.light_energy = 0.0
	pill_light.omni_range = 4.0
	pill_light.position = pill.position
	add_child(pill_light)

# ---------------------------------------------------------------- per frame
func _level_process(_delta: float) -> void:
	if pill.visible:
		pill.position.y = COUNTER.y + 1.4 + sin(t * 2.2) * 0.06
	if tripping:
		cam.rotation.z = sin(t * 0.9) * 0.05
		trip_overlay.color.a = 0.16 + sin(t * 1.7) * 0.06
		for u in party:
			if u.has_meta("tripping"):
				u.sprite.modulate = Color.from_hsv(fmod(t * 0.1 + u.global_position.x * 0.05, 1.0), 0.35, 1.0)
	if busy:
		return
	if stage == "outside" and leader.global_position.z < 1.5:
		stage = "arrived"
		_arrive()
	elif stage == "after" and leader.global_position.distance_to(EXIT_POS) < 3.0:
		stage = "end"
		_to_pass()

func _to_pass() -> void:
	busy = true
	await fade_out(1.0)
	Game.goto("res://pass.tscn")

func _level_interactables() -> Array:
	if stage == "arrived":
		return [
			{ "id": "door", "label": "Metocy Mart", "verb": "Go inside", "pos": DOOR_OUT, "h": 2.4, "r": 3.0, "steps": [{ "do": "enter_shop" }] + MS.SHOP },
			{ "id": "dulbers", "label": "Dulbers Frint", "verb": "Talk to", "node": dulbers, "h": 1.7, "r": 2.0, "steps": MS.DULBERS_WAITING },
		]
	return []

# ---------------------------------------------------------------- story
func _begin() -> void:
	busy = true
	fade_in(1.5)
	await wait(0.8)
	await run_dialogue(MS.INTRO)
	objective("Walk up to the shop.")

func _arrive() -> void:
	focus_override = Vector3(-1.5, 0, -6.5)
	await run_dialogue(MS.ARRIVE)
	focus_override = null
	objective("Go inside the Metocy Mart.")

func _on_action(n: String) -> void:
	match n:
		"dulbers_appears":
			dulbers.global_position = DOOR_OUT
			dulbers.visible = true
			_poof(DOOR_OUT, Color(0.6, 0.5, 0.9))
			hop(dulbers, 0.5)
			await walk_to(dulbers, leader.global_position + Vector3(-0.8, 0, -2.4), 1.0, 2.5)
			char_label(dulbers, "Dulbers Frint (Not Trustworthy)", 3.5, 1.7)
			await wait(0.4)
		"go_inside":
			await walk_to(dulbers, DOOR_OUT, 1.2, 3.0)
			dulbers.visible = false
		"enter_shop":
			await _enter_shop()
		"show_pill":
			pill.visible = true
			pill.scale = Vector3.ZERO
			create_tween().tween_property(pill, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			create_tween().tween_property(pill_light, "light_energy", 1.5, 0.5)
			char_label(pill, "Metocy (Allegedly)", 3.5, 0.35)
			ui_sfx.play()
			await wait(0.6)
		"skorn_bursts_in":
			var sk := add_to_party("skorn", DOOR_IN)
			shake = 0.3
			whoosh_sfx.play()
			char_label(sk, "Skorn (Former King)", 3.0)
			await walk_to(sk, INT + Vector3(2.4, 0, 1.6), 1.5, 2.5)
		"take_it":
			await _pills_to(party.map(func(u): return u))
			pill.visible = false
			pill_light.light_energy = 0.0
		"trip_start":
			Game.set_flag("skornTripped")
			await _trip(party, true)
		"skorn_trip":
			Game.set_flag("skornTripped")
			await _pills_to([_member("skorn")])
			pill.visible = false
			pill_light.light_energy = 0.0
			await _trip([_member("skorn")], false)
		"reveal_midtocy":
			pill.texture = load("res://assets/items/midtocy.png")
			pill.pixel_size = 0.6 / 792.0
			pill.visible = true
			pill_light.light_color = Color(0.7, 0.3, 0.9)
			pill_light.light_energy = 1.5
			char_label(pill, "Midtocy (Off-Brand)", 3.5, 0.4, Color("#c79bff"))
			shake = 0.2
			await wait(0.6)
		"transform":
			await _transform()
		"fight_dulbers":
			await _fight_dulbers()
		"trip_end":
			await _trip_end()
		"dulbers_vanish", "dulbers_escape":
			_poof(dulbers.global_position, Color(0.6, 0.4, 0.9))
			whoosh_sfx.play()
			dulbers.visible = false
			pill.visible = false
			pill_light.light_energy = 0.0
			if n == "dulbers_escape" or n == "dulbers_vanish":
				Game.set_flag("dulbersEscaped", n == "dulbers_escape")
			await wait(0.6)
		"skorn_pockets", "give_midtocy":
			Game.set_flag("hasMidtocy")
			pill.visible = false
			pill_light.light_energy = 0.0
			ui_sfx.play()
			show_toast("Skorn pocketed: Midtocy (throwable)")
			await wait(0.5)
		"kicked_out":
			await _kicked_out()
		"show_pass_sign":
			_show_pass_sign()
			await wait(0.8)
		"xylo_lore":
			await _xylo_lore()
		"goblins_taste":
			for g in allies:
				hop(g, 0.4)
			await wait(0.6)
		"goblin_chase":
			await _goblin_chase()
		"goblins_go_home":
			Game.set_flag("goblinAllies", false)
			for g in allies:
				g.remove_meta("follow")
				g.set_meta("goal", DOOR_IN + Vector3(1.5, 0, 0))
				g.set_meta("goal_speed", 1.0)
			await wait(1.8)
			for g in allies:
				g.visible = false
		"leave":
			await _leave()

func _member(id: String) -> Unit:
	for u in party:
		if u.id == id:
			return u
	return null

func _poof(p: Vector3, color := Color(0.8, 0.75, 0.7)) -> void:
	var f := Fx.poof(color)
	f.position = p + Vector3(0, 0.6, 0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)

func _enter_shop() -> void:
	stage = "inside"
	objective("")
	await fade_out(0.5)
	inside = true
	var spots := [INT + Vector3(0, 0, 1.2), INT + Vector3(-2.3, 0, 1.8), INT + Vector3(2.3, 0, 1.8)]
	for i in party.size():
		party[i].global_position = spots[i]
		party[i].set_view("back")
	for i in allies.size():
		allies[i].global_position = INT + Vector3(-4.5 + i * 1.2, 0, 3.6)
	follow_enabled = false
	dulbers.global_position = COUNTER + Vector3(1.4, 0, 0.4)
	dulbers.visible = true
	focus_override = INT + Vector3(0, 0, 0.0)
	cam_target = focus_override
	zoom = 8.5
	cam_height = 0.38
	cam_look_h = 1.8
	fade_in(0.5)
	await wait(0.5)

func _pills_to(targets: Array) -> void:
	for u in targets:
		var m := Sprite3D.new()
		m.texture = pill.texture
		m.pixel_size = pill.pixel_size * 0.5
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.shaded = false
		add_child(m)
		m.global_position = pill.global_position
		var tw := create_tween()
		tw.tween_property(m, "global_position", u.global_position + Vector3(0, 1.6, 0), 0.4)
		tw.tween_callback(m.queue_free)
		await wait(0.12)
	ui_sfx.play()
	await wait(0.5)

func _trip(who: Array, whole_room: bool) -> void:
	whoosh_sfx.pitch_scale = 0.5
	whoosh_sfx.play()
	shake = 0.4
	for u in who:
		var tex: Texture2D = load("res://assets/characters/%s_tweaking.png" % u.id)
		u.set_pose(tex, CHAR_HEIGHT[u.id])
		u.set_meta("tripping", true)
	if whole_room:
		room_backdrop.albedo_texture = load("res://assets/backdrops/mart_interior_trip.jpg")
	if trip_overlay == null:
		trip_overlay = ColorRect.new()
		trip_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		trip_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		trip_overlay.color = Color(0.55, 0.2, 0.85, 0.0)
		hud.add_child(trip_overlay)
		hud.move_child(trip_overlay, 0)
	tripping = true
	if not whole_room:
		trip_overlay.visible = false
	await wait(0.8)
	whoosh_sfx.pitch_scale = 1.0

func _trip_end() -> void:
	tripping = false
	cam.rotation.z = 0.0
	if trip_overlay:
		trip_overlay.color.a = 0.0
	room_backdrop.albedo_texture = load("res://assets/backdrops/mart_interior.jpg")
	for u in party:
		if u.has_meta("tripping"):
			u.remove_meta("tripping")
			u.set_pose(load("res://assets/characters/%s.png" % u.id), CHAR_HEIGHT[u.id])
			for v in ["back", "side"]:
				var p := "res://assets/characters/%s_%s.png" % [u.id, v]
				if ResourceLoader.exists(p):
					u.views[v] = load(p)
	await wait(0.4)

func _transform() -> void:
	shake = 0.8
	whoosh_sfx.pitch_scale = 0.4
	whoosh_sfx.play()
	_poof(dulbers.global_position, Color(0.5, 0.15, 0.6))
	var flash := ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.7, 0.2, 1.0, 0.8)
	hud.add_child(flash)
	create_tween().tween_property(flash, "color:a", 0.0, 0.7)
	get_tree().create_timer(0.8).timeout.connect(flash.queue_free)
	dulbers.set_pose(load("res://assets/characters/dulbers_demon.png"), 2.7)
	dulbers.set_meta("tint", Color(1.1, 0.95, 1.1))
	char_label(dulbers, "Dulbers Frint (Demon Form, Still Not Trustworthy)", 4.0, 3.0, Color("#c79bff"))
	await wait(1.0)
	whoosh_sfx.pitch_scale = 1.0

func _fight_dulbers() -> void:
	# Real turn-based combat comes to Godot next; for now the trio wins, in style.
	dialogue.hide_box()
	var ban := _label("THE PARTY vs. DULBERS FRINT", Vector2.ZERO, 50, Color("#ff6a4a"), 10)
	ban.anchor_left = 0.5; ban.anchor_right = 0.5; ban.anchor_top = 0.3
	ban.offset_left = -560; ban.offset_right = 560
	ban.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(ban)
	shake = 0.4
	for u in party + allies:
		var home := u.global_position
		await walk_to(u, dulbers.global_position + Vector3(rng.randf_range(-1.2, 1.2), 0, 1.0), 2.0, 1.2)
		_sfx(Util.noise_burst(90, 0.6, 1.0), -2.0).play()
		shake = 0.25
		hop(dulbers, 0.3)
		u.set_meta("goal", home)
		u.set_meta("goal_speed", 1.5)
	knock(dulbers, -75.0, 0.4)
	show_toast("(Real combat comes to Godot next. The trio wins for now.)", 2.2)
	await wait(2.0)
	for u in party + allies:
		u.remove_meta("goal")
	unknock(dulbers)
	ban.queue_free()
	dialogue.show_box()

func _kicked_out() -> void:
	Game.set_flag("dulbersEscaped")
	await fade_out(0.5)
	inside = false
	pill.visible = false
	pill_light.light_energy = 0.0
	dulbers.visible = false
	for g in allies:
		g.global_position = Vector3(rng.randf_range(-2, 2), 0, -5.0)
	place_party(Vector3(-1.5, 0, -6.0), Vector3(0, 0, 1))
	focus_override = Vector3(1.0, 0, -5.0)
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	shake = 0.3
	fade_in(0.5)
	await wait(0.6)

func _show_pass_sign() -> void:
	pass_sign = Node3D.new()
	pass_sign.position = Vector3(6.5, 0, -2.6)
	add_child(pass_sign)
	card("sign", 2.6, pass_sign.position)
	var s := Label3D.new()
	s.text = "GIANT'S PASS →"
	s.font_size = 44
	s.pixel_size = 0.005
	s.modulate = Color(0.15, 0.08, 0.03)
	s.outline_size = 0
	s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.position = Vector3(0, 0.75, 0.15)
	pass_sign.add_child(s)
	_poof(pass_sign.position)
	focus_override = Vector3(3.5, 0, -4.0)

func _xylo_lore() -> void:
	var xy := _member("xylo")
	char_label(xy, "Deloye Lore, Vol. ∞", 4.0, 2.4, Color("#ffd27a"))
	var runes := CPUParticles3D.new()
	runes.amount = 40
	runes.lifetime = 1.4
	runes.mesh = Fx.quad(0.12, true)
	runes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	runes.emission_sphere_radius = 1.0
	runes.direction = Vector3.UP
	runes.spread = 40.0
	runes.gravity = Vector3(0, 0.5, 0)
	runes.initial_velocity_min = 0.2
	runes.initial_velocity_max = 0.6
	runes.color_ramp = Fx.ramp([[0.0, Color(1, 0.85, 0.45, 0)], [0.3, Color(1, 0.85, 0.45, 1)], [1.0, Color(1, 0.85, 0.45, 0)]])
	runes.position = xy.global_position + Vector3(0, 1.2, 0)
	add_child(runes)
	get_tree().create_timer(6.0).timeout.connect(runes.queue_free)
	await wait(0.8)

func _goblin_chase() -> void:
	dialogue.hide_box()
	shake = 0.6
	for g in allies:
		g.remove_meta("follow")
		g.set_meta("goal", dulbers.global_position)
		g.set_meta("goal_speed", 1.6)
	await wait(0.8)
	for k in 5:
		_poof(dulbers.global_position + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-0.5, 0.5)), Color(0.75, 0.68, 0.55))
		_sfx(Util.noise_burst(90, 0.6, 1.0), -4.0).play()
		await wait(0.25)
	Game.set_flag("dulbersDead")
	dulbers.visible = false
	pill.visible = false
	pill_light.light_energy = 0.0
	await wait(0.8)
	for g in allies:
		g.remove_meta("goal")
	dialogue.show_box()

func _leave() -> void:
	if inside:
		await fade_out(0.5)
		inside = false
		for g in allies:
			if g.visible:
				g.global_position = Vector3(0, 0, -6)
		place_party(Vector3(-1.5, 0, -6.0), Vector3(0, 0, 1))
		fade_in(0.5)
	if tripping:
		await _trip_end()
	dulbers.visible = false
	pill.visible = false
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	zoom = 11.0
	cam_height = 0.3
	cam_look_h = 2.6
	if pass_sign == null:
		_show_pass_sign()
		focus_override = null
	objective("Head east toward the Giant's Pass.")

# ---------------------------------------------------------------- automated screenshots (MART_CHOICE=0..4)
func _shot_tour() -> void:
	var choice := int(OS.get_environment("MART_CHOICE")) if OS.get_environment("MART_CHOICE") != "" else 0
	if choice == 4:
		Game.set_flag("goblinAllies")
	var tag := "abcde"[choice]
	fade.color.a = 0.0
	busy = false
	await wait(1.5)
	await shot("m_01_street")
	place_party(Vector3(0, 0, 3.0), Vector3(0, 0, -1))
	await wait(0.6)
	place_party(Vector3(0, 0, 1.0), Vector3(0, 0, -1))
	await wait(1.4)
	await advance(3)
	await wait(2.0)
	await shot("m_02_dulbers")
	await advance(6)
	await wait(2.0)
	place_party(DOOR_OUT + Vector3(0, 0, 1.5), Vector3(0, 0, -1))
	await wait(1.0)
	start(current_interactables().filter(func(i): return i["id"] == "door")[0])
	await wait(2.5)
	await shot("m_03_inside")
	await advance(5, 0.6)
	await wait(1.0)
	await shot("m_04_choice")
	var opts: Array = dialogue._choices
	dialogue._picked.emit(min(choice, opts.size() - 1))
	await wait(1.0)
	for k in 26:
		await advance(1, 0.7)
		if k == 6:
			await shot("m_05_%s_mid" % tag)
		if not dialogue.panel.visible and dialogue.active:
			await wait(5.0)
			await shot("m_06_%s_action" % tag)
		if k == 12:
			await shot("m_07_%s_late" % tag)
	await wait(2.0)
	await shot("m_08_%s_after" % tag)
	place_party(EXIT_POS + Vector3(-2.5, 0, 0), Vector3(1, 0, 0))
	await wait(2.5)
	await shot("m_09_%s_end" % tag)
	get_tree().quit()

const PLANK_SHADER := """
shader_type spatial;
varying vec3 wpos;
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float h(float n) { return fract(sin(n * 91.345) * 47453.12); }
void fragment() {
	vec2 p = wpos.xz;
	float row = floor(p.y / 0.35);
	float x = p.x + h(row) * 3.0;
	float board = floor(x / 2.2);
	float grain = sin((p.y * 40.0) + sin(x * 3.0) * 2.0) * 0.5 + 0.5;
	vec3 base = mix(vec3(0.20, 0.13, 0.08), vec3(0.30, 0.20, 0.12), h(row * 7.0 + board));
	base *= 0.85 + grain * 0.15;
	float seam = smoothstep(0.0, 0.02, fract(p.y / 0.35)) * smoothstep(0.0, 0.02, fract(x / 2.2));
	ALBEDO = base * mix(0.4, 1.0, seam);
	ROUGHNESS = 0.8;
}
"""
