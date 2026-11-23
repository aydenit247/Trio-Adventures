# Area: Goblin Village (Scene 2, played as Lykor). Daytime.
# Walk in → goblin ambush → THE MOGGING ELF → follow the chief to the throne → crowned → pick a way out:
#   A royal speech · B chug-off (mash minigame) · C crown Skorn · D sneak out (you actually sneak) · E Skorn "negotiates"
# Then head east toward the Metocy Mart.
#
# Huts and throne are placeholders until Ebain makes the art (see HANDOFF.md for the Grok prompts).
extends Level

const VS = preload("res://scripts/village_script.gd")
const VB = preload("res://scripts/village_buildings.gd")
const THRONE_POS := Vector3(0, 0, -9)
const SEAT_POS := Vector3(0, 0, -8.2)
const FIRE_POS := Vector3(6.5, 0, 2.5)
const EXIT_POS := Vector3(30, 0, -2)
const GOBLIN_TAGS := ["(Unemployed)", "(Also Unemployed)", "(Between Jobs)", "(Laid Off)", "(Freelance)", "(Looking for Work)"]

# "enter" → "ambushed" (follow the chief) → "throne" (scene) → "after" (free roam, exit east) → "end"
var stage := "enter"
var goblins: Array[Unit] = []
var roam_group := {}
var vb   # the explorable buildings (village_buildings.gd)
var band: GoblinBand   # the goblin band (drummer, horn, lute); added when free roam starts
var chief: Unit
var fire_light: OmniLight3D
var noise := FastNoiseLite.new()
var mug: Sprite3D
var chug_ui: Control
var chug_you := 0.0
var chug_rival := 0.0
var chug_running := false
var forehead: Label3D
var king_label: Label3D

func _configure() -> void:
	night = false
	light_dir = Vector3(0.4, 0.75, 0.35)
	clear_center = Vector2(0, -2)
	clear_radius = 11.0
	path_pts = PackedVector2Array([Vector2(0, 34), Vector2(0.8, 24), Vector2(-0.6, 16), Vector2(0, 8), Vector2(10, -1), Vector2(20, -2.5), Vector2(32, -2)])
	path_width = 1.9
	subtitle = "Scene 2 — Goblin Village (later that morning)"
	party_ids = ["lykor", "xylo", "skorn"]
	party_start = [Vector3(0, 0, 27), Vector3(-1.0, 0, 29), Vector3(1.0, 0, 29)]
	if not Game.title_mode:
		Game.set_flag("skornAway", Game.flag("skornKing") and not Game.flag("martDone"))   # who's around to talk (village_rooms_script)
		Game.set_flag("campDone")   # reaching the village means camp is finished (also fixes older saves)
	bounds = Rect2(-21, -22, 57, 55)   # x -21..36 (exit east at x = 30), z -22..33 (entrance road at z = 27-29)
	leader_id = "lykor"
	switch_enabled = false
	noise.frequency = 1.0
	talk = {
		"skorn": [{ "who": "skorn", "mood": "angry", "line": "Why they always pick HIM, bro." }], # DRAFT
		"xylo": [{ "who": "xylo", "mood": "unimpressed", "line": "Cause they think he sexy as hell… like, yep." }], # DRAFT
	}

func _build_level() -> void:
	_build_fire()
	add_glow(FIRE_POS, Color(1.0, 0.75, 0.5), 6.0, func(): return fire_light.light_energy / 2.0)
	_build_forest()
	vb = VB.new()
	vb.lv = self
	add_child(vb)
	_build_village()
	vb.build()
	_build_throne()
	for i in 6:
		var g := spawn_npc("goblin", "Goblin " + GOBLIN_TAGS[i], "goblin", rng.randf_range(1.1, 1.3), Vector3(rng.randf_range(-9, 9), 0, rng.randf_range(-12, 4)))
		g.walk_speed = 3.0
		g.visible = false
		goblins.append(g)
	chief = spawn_npc("chief", "Chief Bogdrinker", "goblin_chief", 1.45, THRONE_POS + Vector3(1.8, 0, 1.0))
	chief.walk_speed = 1.8
	chief.visible = false

func _build_fire() -> void:
	card("campfire", 1.37, FIRE_POS)
	var fl := Fx.flames(0.75)
	fl.position = FIRE_POS + Vector3(0, 0.4, 0.45)
	add_child(fl)
	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.6, 0.3)
	fire_light.light_energy = 2.0
	fire_light.omni_range = 7.0
	fire_light.position = FIRE_POS + Vector3(0, 0.9, 0)
	add_child(fire_light)
	Util.static_cyl(self, FIRE_POS, 1.5, 1.0)
	# cooking smoke drifting up (light grey in daylight)
	var sm := CPUParticles3D.new()
	sm.amount = 14
	sm.lifetime = 5.0
	sm.mesh = Fx.quad(1.4, false)
	sm.direction = Vector3.UP
	sm.spread = 8.0
	sm.gravity = Vector3(0.2, 0.3, 0)
	sm.initial_velocity_min = 0.4
	sm.initial_velocity_max = 0.6
	sm.scale_amount_curve = Fx.curve([[0.0, 0.4], [1.0, 1.8]])
	sm.color_ramp = Fx.ramp([[0.0, Color(0.85, 0.85, 0.85, 0)], [0.2, Color(0.85, 0.85, 0.85, 0.18)], [1.0, Color(0.85, 0.85, 0.85, 0)]])
	sm.position = FIRE_POS + Vector3(0, 1.6, 0)
	add_child(sm)

func _on_path(p: Vector3, w := 3.4) -> bool:
	for i in path_pts.size() - 1:
		var a := Vector3(path_pts[i].x, 0, path_pts[i].y)
		var b := Vector3(path_pts[i + 1].x, 0, path_pts[i + 1].y)
		var ab := b - a
		var h: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		if (p - a - ab * h).length() < w:
			return true
	return false

func _build_forest() -> void:
	var placed := 0
	var tries := 0
	while placed < 170 and tries < 4000:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(15.5, 48.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r - 2.0)
		if _on_path(p, 4.0):
			continue
		card("tree_%d" % (rng.randi() % 4 + 1), rng.randf_range(6.5, 10.0), p, rng.randf() < 0.5, true, 0.5 if r < 34.0 else 0.0)
		placed += 1
	for k in 45:
		var a := rng.randf() * TAU
		var r := rng.randf_range(12.0, 40.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r - 2.0)
		if _on_path(p):
			continue
		var big := rng.randf() < 0.25
		card("bush_big" if big else "bush_%d" % (rng.randi() % 3 + 1), rng.randf_range(1.6, 2.3) if big else rng.randf_range(1.3, 2.2), p, rng.randf() < 0.5, true)
	for k in 10:
		var a := rng.randf() * TAU
		var r := rng.randf_range(13.0, 30.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r - 2.0)
		if _on_path(p):
			continue
		card("rock_%d" % [1, 2, 4][rng.randi() % 3], rng.randf_range(1.2, 2.4), p, rng.randf() < 0.5, true, 0.45)

func _build_village() -> void:
	# The huts are now real places — see village_buildings.gd (placeholder art until the hut art arrives)
	# junk & seating
	card("log", 0.8, Vector3(4.2, 0, 5.2), true)
	Util.static_box(self, Vector3(4.2, 0.3, 5.2), Vector3(1.6, 0.6, 0.5), 0.3)
	card("log", 0.8, Vector3(9.0, 0, 4.6))
	Util.static_box(self, Vector3(9.0, 0.3, 4.6), Vector3(1.6, 0.6, 0.5), -0.4)
	card("sign", 2.6, Vector3(13.5, 0, -4.2))
	Util.static_cyl(self, Vector3(13.2, 0, -4.2), 0.2)
	wood_sign("sign_metocy_mart", "METOCY MART →\n(PROBABLY)", Vector3(14.6, 1.35, -2.9), -0.35, 1.6, 0.65, true)   # facing the village, arrow east

func _bone(parent: Node3D, pos: Vector3, yaw: float, size: float, m: Material) -> void:
	var b := Node3D.new()
	b.position = pos + Vector3(0, 0.06 * size, 0)
	b.rotation.y = yaw
	b.scale = Vector3.ONE * size
	parent.add_child(b)
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.035
	shaft.bottom_radius = 0.04
	shaft.height = 0.55
	shaft.radial_segments = 10
	Util.add_mesh(b, shaft, m, Vector3.ZERO, Vector3(0, 0, PI / 2.0))
	var knob := SphereMesh.new()
	knob.radius = 0.06
	knob.height = 0.11
	knob.radial_segments = 10
	knob.rings = 6
	for end in [-0.28, 0.28]:
		for side in [-0.04, 0.04]:
			Util.add_mesh(b, knob, m, Vector3(end, 0.0, side))

# The throne: a real chair, one (1) rusty wagon wheel, a fan of giant spoons, and bones (Poly Haven models + shapes)
func _build_throne() -> void:
	var root := Node3D.new()
	root.position = THRONE_POS
	add_child(root)
	var planks := Models.mat("weathered_planks", 1.0, Color(0.75, 0.65, 0.55))
	Models.block(self, THRONE_POS + Vector3(0, 0.12, 0), Vector3(2.2, 0.24, 1.6), planks)   # little stage
	var chair := Models.place(self, "painted_wooden_chair_01", THRONE_POS + Vector3(0, 0.24, 0), PI, 1.5, false, Color(0.42, 0.3, 0.2))
	chair.name = "ThroneChair"
	var wheel := Models.place(self, "rusted_wheel_rim_01", THRONE_POS + Vector3(0, 1.85, -0.7), 0.0, 4.2)
	wheel.rotation.z = 0.12
	for k in 7:
		var sp := Models.place(self, "wooden_spoon", THRONE_POS + Vector3(-0.9 + k * 0.3, 2.25 - absi(k - 3) * 0.12, -0.55), 0.0, 5.0)
		sp.rotation = Vector3(PI / 2.0, 0, (k - 3) * 0.16)
	# old bones scattered around the stage: a shaft with two knobs at each end, aged and dirty
	var bone := Models.mat("clay_plaster", 6.0, Color(0.78, 0.7, 0.55))
	var spots := [Vector3(-1.45, 0, 0.55), Vector3(1.4, 0, 0.4), Vector3(-0.7, 0, 1.15), Vector3(0.85, 0, 1.2),
		Vector3(-1.25, 0, -0.5), Vector3(0.25, 0.24, 0.55)]
	for p in spots:
		_bone(root, p, rng.randf() * TAU, rng.randf_range(0.8, 1.15), bone)
	_bone(root, Vector3(-0.9, 0.09, 1.2), 0.9, 0.9, bone)   # one crossed over another, for that throne-room look
	Util.static_box(self, THRONE_POS + Vector3(0, 0.6, -0.3), Vector3(1.4, 1.2, 1.0))
	wood_sign("sign_throne", "THRONE\n(SPOONS, BONES, 1 WHEEL)", THRONE_POS + Vector3(0, 0.62, 0.62), 0.0, 1.35, 0.5)   # plaque on the base

# ---------------------------------------------------------------- per frame
func _level_process(_delta: float) -> void:
	fire_light.light_energy = 2.0 * (1.0 + noise.get_noise_1d(t * 9.0) * 0.3)
	vb.process(_delta)
	if band:
		$Music.gain_db = band.gain_db   # the village song only plays while the band is with you
		if $Music.played_once and band.state == "playing" and not busy:   # Music: Play once, song's over: the band packs up
			band.leave()
	if not roam_group.is_empty() and roam_group["done"] and not Game.flag("luckySpoonFound"):
		Game.set_flag("luckySpoonFound")
		Game.key_owner["lucky_spoon"] = Game.active_fighter
		show_toast("The patrol dropped something: Grubnik's Lucky Spoon! (%s has it)" % leader.display_name, 2.6)
	if mug and mug.get_meta("owner", null):
		var o: Unit = mug.get_meta("owner")
		mug.global_position = o.global_position + Vector3(0.45, 1.05, 0.1)
	if busy:
		return
	if stage == "enter" and leader.global_position.z < 12.0:
		stage = "ambushed"
		_ambush()
	elif stage == "after" and vb.room == "" and leader.global_position.distance_to(EXIT_POS) < 3.5:
		stage = "end"
		_end_card()

# maps: the buildings you can walk into, the throne and the outhouse; inside one, the maps say where you are
func map_buildings() -> Array:
	var out := []
	for id in VB.BUILDINGS:
		out.append({ "pos": VB.BUILDINGS[id]["pos"], "name": VB.BUILDINGS[id]["name"] })
	out.append({ "pos": THRONE_POS, "name": "The Throne" })
	out.append({ "pos": VB.OUTHOUSE_POS, "name": "Outhouse" })
	out.append({ "pos": VB.STALL_POS, "name": "Haggle's Stall (shop)" })
	return out

func map_place() -> String:
	return VB.BUILDINGS[vb.room]["name"] if vb and vb.room != "" else ""

func map_place_door() -> Vector3:
	return VB.BUILDINGS[vb.room]["door"] if vb and vb.room != "" else Vector3.INF

func _level_interactables() -> Array:
	var list: Array = []
	if stage == "ambushed":
		list.append({ "id": "throne", "label": "the throne", "verb": "Sit on", "pos": THRONE_POS, "h": 2.6, "r": 2.8, "steps": VS.THRONE })
		list.append({ "id": "chief", "label": "Chief Bogdrinker", "verb": "Talk to", "node": chief, "h": 1.9, "r": 2.0, "steps": VS.CHIEF_WAITING })
	elif stage == "after":
		if chief.visible and not chief.has_meta("at_home"):
			list.append({ "id": "chief", "label": "Chief Bogdrinker", "verb": "Talk to", "node": chief, "h": 1.9, "r": 2.0, "steps": VS.CHIEF_AFTER })
		for g in goblins:
			if g.visible and not g.has_meta("follow"):
				list.append({ "id": "goblin", "label": g.display_name, "verb": "Talk to", "node": g, "h": 1.6, "r": 1.6, "steps": VS.GOBLIN_AFTER })
		for u in npcs:
			if u.id == "skorn":
				list.append({ "id": "skorn_king", "label": "King Skorn", "verb": "Talk to", "node": u, "h": 2.2, "r": 2.2, "steps": VS.CHIEF_AFTER_SKORN })
		list.append({ "id": "campfire", "label": "Campfire", "verb": "Rest at", "pos": FIRE_POS, "h": 1.6, "r": 2.6, "rest": true, "steps": [
		] })
		if vb.room != "":
			list = []
		elif band:
			list += band.interactables()
		list += vb.interactables()
	return list

# ---------------------------------------------------------------- story
func _begin() -> void:
	busy = true
	fade_in(1.5)
	target_yaw = 0.0
	await wait(0.8)
	await run_dialogue(VS.INTRO)
	objective("Head into the goblin village.", Vector3(0, 0, 11))

func _ambush() -> void:
	focus_override = leader.global_position + Vector3(0, 0, -2.5)
	await run_dialogue(VS.AMBUSH)
	focus_override = null
	objective("Follow Chief Bogdrinker to the throne.", THRONE_POS)

func _on_action(n: String) -> void:
	match n:
		"goblins_appear":
			await _goblins_appear()
		"goblins_kneel":
			var kneel: Texture2D = load("res://assets/characters/goblin_kneel.png")
			for g in goblins:
				g.set_pose(kneel, 0.75)
				hop(g, 0.25)
			char_label(leader, "Lykor (The Mogging Elf)", 3.0)
			await wait(0.6)
		"chief_appears":
			chief.global_position = leader.global_position + Vector3(0.6, 0, -6.0)
			chief.visible = true
			_poof(chief.global_position)
			await walk_to(chief, leader.global_position + Vector3(0.4, 0, -2.6), 1.0, 3.0)
			char_label(chief, "Chief Bogdrinker", 3.0, 2.0)
			await wait(0.5)
		"follow_chief":
			var stand: Texture2D = load("res://assets/characters/goblin.png")
			for i in goblins.size():
				goblins[i].set_pose(stand, rng.randf_range(1.1, 1.3))
				goblins[i].set_meta("goal", THRONE_POS + Vector3(-4.5 + i * 1.8, 0, 3.2 + (i % 2) * 0.8))
				goblins[i].set_meta("goal_speed", 0.8)
			chief.set_meta("goal", THRONE_POS + Vector3(1.9, 0, 1.0))
			chief.set_meta("goal_speed", 0.9)
		"to_throne":
			await _to_throne()
		"crown":
			king_label = char_label(leader, "Lykor (King, Apparently)", -1.0, 2.3, Color("#ffdf4a"))
			ui_sfx.play()
			await wait(0.4)
		"beezy":
			_give_mug(leader)
			await wait(0.5)
		"goblins_block":
			for i in goblins.size():
				var a := PI * (0.15 + 0.7 * i / 5.0)
				goblins[i].set_meta("goal", SEAT_POS + Vector3(-cos(a) * 3.0, 0, sin(a) * 3.0))
				goblins[i].set_meta("goal_speed", 1.0)
			await wait(1.2)
		"gift_beezy":
			await _gift_beezy()
		"goblins_cry":
			for k in 3:
				for g in goblins:
					if g.visible:
						hop(g, 0.35)
				await wait(0.35)
		"chug_game":
			var won: bool = await _chug_game()
			Game.set_flag("chugWon", won)
		"pass_out":
			await _pass_out()
		"wake_outside":
			await _wake_outside()
		"crown_skorn":
			await _crown_skorn()
		"sneak":
			await _sneak()
		"goblins_join":
			Game.set_flag("goblinAllies")
			for i in 3:
				goblins[i].set_meta("follow", true)
				goblins[i].set_meta("follow_i", i)
				goblins[i].remove_meta("goal")
			for g in goblins:
				hop(g, 0.35)
			char_label(goblins[1], "Goblins (Coming Along, Unfortunately)", 3.5, 1.7)
			await wait(0.5)
		"skorn_slap":
			await _skorn_slap()
		"fight_goblins":
			await _fight_goblins()
		"dethrone":
			Game.set_flag("lykorDethroned")
			if king_label:
				king_label.text = "Lykor (Dethroned)"
			var sk := _member("skorn")
			char_label(sk, "Skorn (Respected now)", 3.0)
			if mug:
				mug.set_meta("owner", sk)
			hop(sk, 0.4)
			await wait(0.4)
		"leave":
			_leave()
		_:
			if n.begins_with("band_") and band:
				await band.on_action(n)
			else:
				await vb.on_action(n)

func _member(id: String) -> Unit:
	for u in party + npcs:
		if u.id == id:
			return u
	return null

func _poof(p: Vector3) -> void:
	var f := Fx.poof(Color(0.55, 0.65, 0.35))
	f.position = p + Vector3(0, 0.5, 0)
	add_child(f)
	f.emitting = true
	get_tree().create_timer(1.5).timeout.connect(f.queue_free)

func _goblins_appear() -> void:
	var c := leader.global_position
	whoosh_sfx.play()
	shake = 0.3
	for i in goblins.size():
		var a := PI * (0.1 + 0.8 * i / 5.0)
		var p := c + Vector3(-cos(a) * 3.4, 0, -sin(a) * 3.0 - 0.5)
		goblins[i].global_position = p
		goblins[i].visible = true
		_poof(p)
		hop(goblins[i], 0.5)
		await wait(0.12)
	for i in goblins.size():
		char_label(goblins[i], "Goblin " + GOBLIN_TAGS[i], 3.0, 1.6)
	await wait(0.4)

func _to_throne() -> void:
	stage = "throne"
	objective("")
	await fade_out(0.4)
	leader.global_position = SEAT_POS
	leader.set_view("front")
	for u in party:
		if u.id == "xylo":
			u.global_position = SEAT_POS + Vector3(-2.6, 0, 2.2)
		elif u.id == "skorn":
			u.global_position = SEAT_POS + Vector3(2.8, 0, 2.4)
	follow_enabled = false
	for i in goblins.size():
		goblins[i].remove_meta("goal")
		goblins[i].global_position = THRONE_POS + Vector3(-4.5 + i * 1.8, 0, 4.4 + (i % 2) * 0.8)
	chief.remove_meta("goal")
	chief.global_position = SEAT_POS + Vector3(1.6, 0, 0.9)
	focus_override = SEAT_POS + Vector3(0, 0, 2.0)
	target_yaw = 0.0
	zoom = 8.5
	fade_in(0.5)
	await wait(0.5)

func _give_mug(owner: Unit) -> void:
	if mug == null:
		mug = Sprite3D.new()
		mug.texture = load("res://assets/items/beer.png")
		mug.pixel_size = 0.32 / 508.0
		mug.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mug.shaded = false
		mug.no_depth_test = true
		add_child(mug)
	mug.set_meta("owner", owner)
	mug.scale = Vector3.ZERO
	create_tween().tween_property(mug, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ui_sfx.play()

func _gift_beezy() -> void:
	for k in 3:
		var m := Sprite3D.new()
		m.texture = load("res://assets/items/beer.png")
		m.pixel_size = 0.3 / 508.0
		m.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		m.shaded = false
		m.no_depth_test = true
		add_child(m)
		m.global_position = chief.global_position + Vector3(0, 1.2, 0)
		var tw := create_tween()
		tw.tween_property(m, "global_position", leader.global_position + Vector3(0, 1.4, 0), 0.4).set_delay(k * 0.15)
		tw.tween_callback(m.queue_free)
	ui_sfx.play()
	Game.add_item("beer", 3, "lykor")
	show_toast("Lykor got: Beezy ×3")
	await wait(0.9)

# ---- B: chug-off (mash E / Space)
func _chug_game(rival := "Chief Bogdrinker (400-year champ)", rival_speed := 1.0) -> bool:
	dialogue.hide_box()
	chug_ui = Control.new()
	chug_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	chug_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(chug_ui)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5
	panel.offset_left = -360; panel.offset_right = 360; panel.offset_top = 140; panel.offset_bottom = 400
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.11, 0.93)
	sb.border_color = Color("#e8b923")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 24; sb.content_margin_right = 24; sb.content_margin_top = 18; sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	chug_ui.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var title := _label("BEEZY CHUG-OFF", Vector2.ZERO, 34, Color("#e8b923"), 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var hint := _label("Mash E / SPACE to chug!", Vector2.ZERO, 20, Color.WHITE, 5)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)
	var bars := []
	for who in [[leader.display_name, Color("#ffd86a")], [rival, Color("#9bc25a")]]:
		col.add_child(_label(who[0], Vector2.ZERO, 18, who[1], 5))
		var pb := ProgressBar.new()
		pb.custom_minimum_size = Vector2(0, 26)
		pb.max_value = 100
		pb.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = who[1]
		fill.set_corner_radius_all(6)
		pb.add_theme_stylebox_override("fill", fill)
		col.add_child(pb)
		bars.append(pb)
	var timer_lbl := _label("", Vector2.ZERO, 18, Color("#a49cc4"), 4)
	timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(timer_lbl)
	chug_you = 0.0
	chug_rival = 0.0
	chug_running = true
	var time_left := 8.0
	while chug_running:
		await get_tree().process_frame
		var d := get_process_delta_time()
		time_left -= d
		chug_rival += d * rng.randf_range(10.0, 26.0) * rival_speed   # about 18/sec on average → done in ~5.5s
		if shots_mode and fmod(t, 0.12) < d:
			_chug_press()
		bars[0].value = chug_you
		bars[1].value = chug_rival
		timer_lbl.text = "%.1f" % max(time_left, 0.0)
		if chug_you >= 100.0 or chug_rival >= 100.0 or time_left <= 0.0:
			chug_running = false
	var won := chug_you >= 100.0 and chug_you >= chug_rival
	hint.text = "LEGEND!" if won else "%s wins. %s is not okay." % [rival.get_slice(" (", 0), leader.display_name]
	hint.add_theme_color_override("font_color", Color("#7dff8a") if won else Color("#ff8a6a"))
	await wait(1.4)
	chug_ui.queue_free()
	dialogue.show_box()
	return won

func _chug_press() -> void:
	if not chug_running:
		return
	chug_you = min(100.0, chug_you + 3.2)
	hop(leader, 0.12)

func _input(ev: InputEvent) -> void:
	if chug_running and ev.is_action_pressed("interact"):
		_chug_press()
		get_viewport().set_input_as_handled()

func _pass_out() -> void:
	shake = 0.3
	knock(leader, -80.0, 0.5)
	await wait(0.6)
	if mug:
		mug.visible = false
	await fade_out(0.8)

func _wake_outside() -> void:
	Game.set_flag("foreheadLoser")
	for g in goblins:
		g.visible = false
	chief.visible = false
	if king_label:
		king_label.queue_free()
	unknock(leader)
	place_party(EXIT_POS + Vector3(-9, 0, 1.5), Vector3(1, 0, 0))
	for u in party:
		if u != leader:
			pass
	focus_override = null
	follow_enabled = true
	fade_in(0.8)
	await wait(0.8)
	forehead = char_label(leader, "METOCY MART, EAST. LOSER.", -1.0, 2.05, Color("#ff8a6a"))

# ---- C: crown Skorn
func _crown_skorn() -> void:
	Game.set_flag("skornKing")
	Game.set_flag("skornAway")   # he's on the throne now (not in the party) until the Mart
	var sk := _member("skorn")
	# Lykor gets off the throne FIRST and stands to its left (Asar: he used to stay on the seat, right on top of Skorn).
	# Left side, because the Chief stands on the right and Xylo further left in front.
	var lykor_spot := SEAT_POS + Vector3(-1.9, 0, 0.7)
	hop(leader, 0.4)
	await walk_to(leader, lykor_spot, 1.2, 1.2)
	leader.global_position = lykor_spot   # make sure, even if the walk got stuck
	leader.set_view("front")
	await walk_to(sk, SEAT_POS + Vector3(0, 0, 0.3), 1.0, 3.0)
	sk.global_position = SEAT_POS
	sk.set_view("front")
	ui_sfx.play()
	char_label(sk, "The Purple King (Downgrade)", 4.0)
	if king_label:
		king_label.text = "King (Former)"
	var kneel: Texture2D = load("res://assets/characters/goblin_kneel.png")
	for g in goblins:
		g.set_pose(kneel, 0.75)
	await wait(0.6)

# ---- D: sneak out (you actually control Lykor, slowly… and they catch you anyway)
func _sneak() -> void:
	dialogue.hide_box()
	objective("Sneak out of the village… slow… quiet…")
	walk_mult = 0.32
	follow_enabled = false
	focus_override = null
	interact_cooldown = 999.0   # no talking to people mid-sneak
	busy = false
	freeze_all(false)
	for g in goblins:   # goblins stand around looking the other way
		g.remove_meta("goal")
	var start_pos := leader.global_position
	var tt := 0.0
	while leader.global_position.distance_to(start_pos) < 5.0 and tt < 25.0:
		await get_tree().process_frame
		tt += get_process_delta_time()
		if shots_mode:
			auto_dir = Vector3(0, 0, -1)
	auto_dir = Vector3.ZERO
	busy = true
	freeze_all(true)
	walk_mult = 1.0
	interact_cooldown = 0.3
	# CAUGHT: every goblin pops up right around him
	whoosh_sfx.play()
	shake = 0.4
	var c := leader.global_position
	for i in goblins.size():
		var a := TAU * i / goblins.size()
		goblins[i].global_position = c + Vector3(cos(a) * 1.7, 0, sin(a) * 1.7)
		_poof(goblins[i].global_position)
		hop(goblins[i], 0.4)
	chief.global_position = c + Vector3(0.5, 0, -2.4)
	hop(leader, 0.6)
	focus_override = c
	objective("")
	await wait(0.5)
	dialogue.show_box()

# ---- E: Skorn negotiates
func _skorn_slap() -> void:
	var sk := _member("skorn")
	var g := goblins[0]
	for gg in goblins:
		if gg.global_position.distance_to(sk.global_position) < g.global_position.distance_to(sk.global_position):
			g = gg
	await walk_to(sk, g.global_position + (sk.global_position - g.global_position).normalized() * 1.0, 1.4, 2.0)
	var slap := Util.noise_burst(90, 0.6, 1.0)
	var p := _sfx(slap, -2.0)
	p.play()
	shake = 0.3
	knock(g, 70.0)
	await wait(0.6)
	unknock(g)
	await wait(0.2)

func _fight_goblins() -> void:
	# Skorn vs. 3 goblins, turn-based, right there in front of the throne
	await fight("goblins", { "enemies": goblins.slice(0, 3) })
	var kneel: Texture2D = load("res://assets/characters/goblin_kneel.png")
	for g in goblins:
		g.set_pose(kneel, 0.75)

func _leave() -> void:
	stage = "after"
	focus_override = null
	follow_enabled = true
	switch_enabled = true
	if Game.flag("skornKing") and not Game.flag("martDone"):   # after the Mart he travels with you again
		var sk := remove_from_party("skorn")
		sk.global_position = SEAT_POS
	var stand: Texture2D = load("res://assets/characters/goblin.png")
	for g in goblins:
		if g.visible and not Game.flag("skornKing"):
			g.set_pose(stand, rng.randf_range(1.1, 1.3))
	objective("Explore the village (Tab = inventory & quests) · or head east to the Metocy Mart.", EXIT_POS)
	if not Game.flag("villageOpen"):
		Game.set_flag("villageOpen")
		if not shots_mode:
			Game.save_game.call_deferred("auto", self)   # free roam starts: checkpoint
	if band == null:   # the village song starts: here comes the band (back again on every visit / loaded save)
		band = GoblinBand.new()
		band.lv = self
		band.bar_door = VB.BUILDINGS["bar"]["door"]
		add_child(band)
		band.arrive()
	# optional: a goblin patrol wanders the east road (fight it, sneak past it, or talk your way out)
	if roam_group.is_empty():
		roam_group = spawn_roamers("goblin_patrol", Vector3(21, 0, -1.5), 2.5)
		checkpoint = THRONE_POS + Vector3(0, 0, 4.0)

func bounds_exempt() -> bool:
	return vb != null and vb.room != ""   # building interiors are built far away (x = 400+)

# ---------------------------------------------------------------- saves: resume village free roam
func can_resume() -> bool:
	return stage == "after" and vb.room == ""

func free_roam() -> bool:   # inside the buildings counts too (Esc can end side conversations there)
	return stage == "after"

func can_resume_saved() -> bool:
	return Game.flag("villageOpen")

func _resume(r: Dictionary) -> void:
	stage = "after"
	var stand: Texture2D = load("res://assets/characters/goblin.png")
	if not Game.flag("foreheadLoser"):
		for i in goblins.size():
			goblins[i].global_position = THRONE_POS + Vector3(-3.6 + i * 1.6, 0, 3.4 + (i % 2) * 0.8)
			goblins[i].visible = true
			goblins[i].set_pose(stand, 1.15)
		chief.visible = true
		chief.global_position = THRONE_POS + Vector3(2.4, 0, 1.6)
		if Game.flag("goblinAllies"):
			for i in 3:
				goblins[i].set_meta("follow", true)
				goblins[i].set_meta("follow_i", i)
	_leave()
	if Game.flag("foreheadLoser") and forehead == null:
		forehead = char_label(leader, "METOCY MART, EAST. LOSER.", -1.0, 2.05, Color("#ff8a6a"))
	await super._resume(r)

func _end_card() -> void:
	if Game.flag("martDone"):   # been to the Mart already: walk straight back into it
		await fade_out(0.6)
		Game.travel("res://mart.tscn", "village", leader.id)
		return
	await fade_out(1.0)
	Game.goto("res://mart.tscn")

# ---- walking between areas: the entrance road leads back to camp; arriving from the Mart puts you at the east exit
func back_exit() -> Dictionary:
	if stage == "after" and vb.room == "":
		return { "pos": Vector3(0, 0, 31.0), "r": 2.4, "scene": "res://trail.tscn", "name": "Goblin Woods Trail" }
	return {}

func arrival(from: String) -> Array:
	if from == "camp" or from == "trail":
		return [Vector3(0, 0, 25.0), Vector3(0, 0, -1)]
	if from == "mart":
		return [EXIT_POS + Vector3(-1.5, 0, 4.5), Vector3(-1, 0, 0)]   # outside the exit trigger, clear of the Goblin Patrol's spot (21, -1.5)
	return super.arrival(from)

# ---------------------------------------------------------------- automated screenshots
# Pick a path with env var VILLAGE_CHOICE=0..4 (A..E)
func _shot_tour() -> void:
	if OS.get_environment("VILLAGE_TOUR") == "band":
		await _band_tour()
		return
	if OS.get_environment("VILLAGE_TOUR") == "buildings":
		roam_group = spawn_roamers("goblin_patrol", Vector3(21, 0, -1.5), 2.5)
		await vb.tour()
		return
	var choice := int(OS.get_environment("VILLAGE_CHOICE")) if OS.get_environment("VILLAGE_CHOICE") != "" else 0
	var tag := "abcde"[choice]
	fade.color.a = 0.0
	busy = false
	await wait(1.5)
	await shot("v_01_enter")
	place_party(Vector3(0, 0, 13.5), Vector3(0, 0, -1))
	await wait(0.8)
	place_party(Vector3(0, 0, 11.5), Vector3(0, 0, -1))
	await wait(1.6)
	await advance(1)
	await wait(1.2)
	await shot("v_02_ambush")
	await advance(4)
	await wait(1.0)
	await shot("v_03_kneel")
	await advance(4)
	await wait(2.4)
	await shot("v_04_chief")
	await advance(6)
	await wait(3.0)
	place_party(THRONE_POS + Vector3(0, 0, 3.0), Vector3(0, 0, -1))
	await wait(1.5)
	await shot("v_05_throne_area")
	start(current_interactables().filter(func(i): return i["id"] == "throne")[0])
	await wait(2.0)
	await advance(9, 0.6)
	await wait(1.5)
	await shot("v_06_throne")
	await advance(4)
	await wait(1.0)
	await shot("v_07_choice")
	dialogue._picked.emit(choice)
	await wait(1.0)
	await shot("v_08_%s_1" % tag)
	for k in 14:
		await advance(1, 0.7)
		if k == 3:
			await shot("v_09_%s_2" % tag)
		if chug_running or (stage == "throne" and not dialogue.panel.visible):
			await wait(9.0 if chug_running else 6.0)
			await shot("v_10_%s_mid" % tag)
	await wait(2.0)
	await shot("v_11_%s_after" % tag)
	place_party(EXIT_POS + Vector3(-2.5, 0, 0), Vector3(1, 0, 0))
	await wait(2.5)
	await shot("v_12_%s_end" % tag)
	get_tree().quit()

# VILLAGE_TOUR=band: the goblin band shows up, follows, waits at a door, keeps playing, then gets told to get lost.
func _band_tour() -> void:
	fade.color.a = 0.0
	busy = false
	chief.visible = true
	chief.global_position = THRONE_POS + Vector3(2.0, 0, 1.0)
	place_party(Vector3(0, 0, 3), Vector3(0, 0, -1))
	target_yaw = 0.0
	_leave()
	print("BAND ", band.state, " units=", band.units.size(), " gain=", band.gain_db)
	await wait(0.6)
	await shot("band_01_arrive")
	await wait(2.5)
	await shot("band_02_caught_up")
	auto_dir = Vector3(1, 0, 0)   # walk right, then away from the camera: they should trail behind
	await wait(2.0)
	auto_dir = Vector3(0, 0, -1)
	await wait(2.5)
	auto_dir = Vector3.ZERO
	await wait(0.6)
	await shot("band_03_following")
	await vb.auto_talk("door_bar")
	await wait(1.0)
	print("BAND inside: music ", $Music.state, " band at ", band.units[0].global_position.round(), " room=", vb.room)
	await shot("band_04_inside_bar")
	await wait(7.0)   # they walk over to the door meanwhile
	await vb.auto_talk("exit")
	await wait(1.2)
	await shot("band_05_waited_outside")
	await vb.auto_talk("band", [0], "band_06_talk", 1)
	print("BAND after fire mud: ", band.state)
	await wait(0.5)
	await vb.auto_talk("band", [1], "band_07_get_lost", 2)
	await wait(1.5)
	print("BAND leaving: ", band.state, " gain=", snappedf(band.gain_db, 0.1))
	await shot("band_08_walking_off")
	await wait(9.0)
	print("BAND end: ", band.state, " gain=", band.gain_db, " music=", snappedf($Music.player.volume_db, 0.1), " npcs=", npcs.filter(func(u): return is_instance_valid(u) and u.has_meta("band")).size())
	await shot("band_09_gone")
	get_tree().quit()
