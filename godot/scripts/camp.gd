# Area: the camp, the night before the quest (Scene 1, playable).
# Fire's out → walk Skorn to Lykor's bag → grab the map → burn it in the pit → rest of Scene 1 → free roam.
# The path north leads to the Goblin Village.
extends Level

const CampScript = preload("res://scripts/camp_script.gd")
const FIRE_POS := Vector3.ZERO
const GOBLIN_HOME := Vector3(9, 0, -6)
const EXIT_POS := Vector3(0, 0, -25)
const SKORN_TENT := Vector3(-5.4, 0, -3.6)
const LYKOR_TENT := Vector3(5.6, 0, -3.9)
const LANTERN := Vector3(3.3, 0.75, -1.9)   # the lantern on the crate by Lykor's tent

# Scene 1 progress: "start" (no fire) → "has_map" (carrying the paper) → "lit" (free roam)
var stage := "start"
var fire_light: OmniLight3D
var fire_base := 0.0
var flames: CPUParticles3D
var embers: CPUParticles3D
var coal_mat: StandardMaterial3D
var scrap_mesh: MeshInstance3D
var amb: Ambience
var paper: Sprite3D
var goblin: Unit
var goblin_goal := GOBLIN_HOME
var goblin_timer := 0.0
var noise := FastNoiseLite.new()
var leaving := false

func _configure() -> void:
	night = true
	light_dir = Vector3(-0.45, 0.32, -0.83)
	clear_radius = 6.5
	for i in 12:
		var z := -4.5 - i * 2.2
		path_pts.append(Vector2(sin(z * 0.42) * 1.1, z))
	subtitle = "Scene 1 — Camp, the night before the quest"
	party_ids = ["skorn", "lykor", "xylo"]
	party_start = [Vector3(2.0, 0, 2.9), Vector3(cos(2.3) * 3.9, 0, sin(2.3) * 3.9), Vector3(cos(0.75) * 3.9, 0, sin(0.75) * 3.9)]
	leader_id = "skorn"
	follow_enabled = false     # Lykor & Xylo hang by the logs until the fire's lit
	switch_enabled = false
	talk = CampScript.TALK
	noise.frequency = 1.0
	bounds = Rect2(-17, -28, 34, 45)   # camp clearing + the path north (exit at z = -25)

func _build_level() -> void:
	_build_fire()   # first, so props near the fire know they get its light
	add_glow(FIRE_POS, Color(1.0, 0.72, 0.48), 11.0, func(): return fire_light.light_energy / 3.0, true)
	add_glow(LANTERN, Color(0.83, 0.53, 0.27), 4.5, func(): return 1.0)
	_build_forest()
	_build_camp()
	goblin = spawn_npc("goblin", "Goblin (Between Jobs)", "goblin", 1.25, GOBLIN_HOME)
	goblin.walk_speed = 1.4
	amb = Ambience.new()
	add_child(amb)
	amb.setup(FIRE_POS)
	amb.fire_player.volume_db = -80.0

func _build_forest() -> void:
	var placed := 0
	var tries := 0
	while placed < 170 and tries < 3000:
		tries += 1
		var a := rng.randf() * TAU
		var r := rng.randf_range(10.0, 46.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 3.6 and p.z < -6.0 and p.z > -30.0:
			continue
		if p.distance_to(GOBLIN_HOME) < 3.0:
			continue
		card("tree_%d" % (rng.randi() % 4 + 1), rng.randf_range(6.0, 9.5), p, rng.randf() < 0.5, true, 0.5 if r < 32.0 else 0.0)
		placed += 1
	for k in 55:
		var a := rng.randf() * TAU
		var r := rng.randf_range(7.8, 40.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 2.6 and p.z < -6.0 and p.z > -30.0:
			continue
		var big := rng.randf() < 0.25
		card("bush_big" if big else "bush_%d" % (rng.randi() % 3 + 1), rng.randf_range(1.6, 2.3) if big else rng.randf_range(1.3, 2.2), p, rng.randf() < 0.5, true)
	for k in 16:
		var a := rng.randf() * TAU
		var r := rng.randf_range(8.0, 32.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 3.0 and p.z < -6.0 and p.z > -30.0:
			continue
		Models.place(self, "boulder_01", p + Vector3(0, -0.1, 0), rng.randf() * TAU, rng.randf_range(0.7, 1.5), true)
	Models.place(self, "boulder_01", Vector3(-2.8, -0.1, -15.0), 0.6, 1.6, true)
	# big mossy rock clusters at the edge of the clearing
	Models.place(self, "rock_moss_set_01", Vector3(-13.5, 0, -11.0), 0.4, 0.85)
	Models.place(self, "rock_moss_set_02", Vector3(14.0, 0, 7.5), 2.2, 0.85)
	Models.place(self, "rock_moss_set_02", Vector3(-12.0, 0, 11.5), 4.0, 0.7)
	# ferns + fallen branches on the ground
	for k in 18:
		var a := rng.randf() * TAU
		var r := rng.randf_range(6.8, 14.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 2.8 and p.z < -5.0:
			continue
		Models.place(self, "fern_02", p, rng.randf() * TAU, rng.randf_range(0.7, 1.2))
	for k in 6:
		var a := rng.randf() * TAU
		var r := rng.randf_range(5.0, 11.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if abs(p.x) < 2.8 and p.z < -5.0:
			continue
		Models.place(self, "dry_branches_medium_01", p, rng.randf() * TAU, rng.randf_range(0.8, 1.3))
	_mountains()
	_fireflies()

func _mountains() -> void:
	var mtn_m := Util.mat(Color(0.03, 0.035, 0.06))
	for k in 16:
		var a := k / 16.0 * TAU + rng.randf_range(-0.15, 0.15)
		var r := rng.randf_range(85, 110)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = rng.randf_range(22, 38)
		cm.height = rng.randf_range(22, 42)
		cm.radial_segments = 6
		Util.add_mesh(self, cm, mtn_m, Vector3(cos(a) * r, cm.height / 2.0 - 3.0, sin(a) * r), Vector3(0, rng.randf() * TAU, 0))

func _fireflies() -> void:
	var ff := CPUParticles3D.new()
	ff.amount = 50
	ff.lifetime = 7.0
	ff.mesh = Fx.quad(0.07, true)
	ff.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ff.emission_box_extents = Vector3(26, 1.5, 26)
	ff.gravity = Vector3.ZERO
	ff.direction = Vector3.UP
	ff.spread = 180.0
	ff.initial_velocity_min = 0.1
	ff.initial_velocity_max = 0.4
	ff.color_ramp = Fx.ramp([[0.0, Color(0.8, 1.0, 0.4, 0)], [0.3, Color(0.8, 1.0, 0.4, 1)], [0.7, Color(0.8, 1.0, 0.4, 1)], [1.0, Color(0.8, 1.0, 0.4, 0)]])
	ff.position = Vector3(0, 1.4, 0)
	add_child(ff)

func _build_camp() -> void:
	card("tent_green", 3.0, SKORN_TENT)
	Util.static_box(self, SKORN_TENT + Vector3(0, 1, 0), Vector3(4.4, 2, 2.8), 0.6)
	card("tent_purple", 3.3, LYKOR_TENT)
	Util.static_box(self, LYKOR_TENT + Vector3(0, 1, 0), Vector3(4.4, 2, 2.8), -0.6)
	var lan := OmniLight3D.new()
	lan.light_color = Color(1.0, 0.72, 0.4)
	lan.light_energy = 0.9
	lan.omni_range = 4.5
	lan.position = LANTERN
	add_child(lan)
	card("campfire", 1.37, FIRE_POS)
	# camp life — real props (Poly Haven, CC0); the tents, fire, bag and sign stay Ebain's art
	for lg in [[Vector3(-3.5, 0.0, 2.7), -0.95], [Vector3(3.6, 0.0, 2.9), 0.85]]:          # sitting logs (made chunkier)
		var log := Models.place(self, "dead_tree_trunk", lg[0], lg[1], 1.0)
		log.scale = Vector3(0.7, 1.9, 1.9)
		Util.static_box(self, lg[0] + Vector3(0, 0.25, 0), Vector3(2.1, 0.5, 0.55), lg[1])
	Models.place(self, "tree_stump_01", Vector3(-7.6, 0, 1.4), 0.3, 1.0, true)
	var axe := Models.place(self, "wooden_axe", Vector3(-7.45, 0.55, 1.35), 0.0, 1.6)
	axe.rotation = Vector3(0.0, 0.8, -0.35)                                                 # stuck in the stump
	for k in 5:                                                                            # firewood pile
		Models.place(self, "dead_tree_trunk", Vector3(-6.9 + (k % 3) * 0.05, 0.12 + (k / 3) * 0.22, -0.4 + (k % 3) * 0.24), 0.2, 0.32)
	Models.place(self, "pot_enamel_01", Vector3(1.45, 0, 1.25), 0.4, 1.6)
	Models.place(self, "wooden_bowl_01", Vector3(1.95, 0, 0.75), 0.0, 1.3)
	Models.place(self, "wooden_bowl_01", Vector3(-1.9, 0, 1.6), 1.0, 1.3)
	Models.place(self, "wooden_bucket_02", Vector3(3.9, 0, -1.4), 0.0, 1.0)
	Models.place(self, "wooden_bucket_01", Vector3(-3.8, 0, -1.5), 0.6, 1.0)
	Models.place(self, "wooden_crate_02", Vector3(-7.6, 0, -2.6), 1.3, 1.0, true)
	Models.place(self, "wooden_crate_01", Vector3(-7.6, 0.46, -2.6), 1.1, 0.95)
	Models.place(self, "wooden_crate_01", Vector3(3.3, 0, -1.9), 0.4, 1.0, true)
	Models.place(self, "wooden_lantern_01", Vector3(3.3, 0.34, -1.9), 0.0, 1.0)
	card("bag", 0.55, Vector3(-2.7, 0, -1.6))
	card("sign", 2.6, Vector3(2.7, 0, -8.4))
	Util.static_cyl(self, Vector3(2.4, 0, -8.4), 0.2)
	var scrap := PlaneMesh.new()
	scrap.size = Vector2(0.5, 0.36)
	var sm := Util.mat(Color(0.08, 0.06, 0.05))
	sm.emission_enabled = true
	sm.emission = Color(1.0, 0.35, 0.1)
	sm.emission_energy_multiplier = 0.6
	scrap_mesh = Util.add_mesh(self, scrap, sm, Vector3(1.5, 0.03, 1.4), Vector3(0, 0.7, 0))
	scrap_mesh.visible = false

func _build_fire() -> void:
	var coal := SphereMesh.new()
	coal.radius = 0.3
	coal.height = 0.2
	coal_mat = Util.mat(Color(0.3, 0.1, 0.02))
	coal_mat.emission_enabled = true
	coal_mat.emission = Color(1.0, 0.35, 0.08)
	coal_mat.emission_energy_multiplier = 0.0
	Util.add_mesh(self, coal, coal_mat, FIRE_POS + Vector3(0, 0.06, 0))
	flames = Fx.flames()
	flames.emitting = false
	add_child(flames)
	embers = Fx.embers()
	embers.emitting = false
	add_child(embers)
	fire_light = OmniLight3D.new()
	fire_light.light_color = Color(1.0, 0.55, 0.22)
	fire_light.light_energy = 0.0
	fire_light.omni_range = 14.0
	fire_light.omni_attenuation = 1.1
	fire_light.shadow_enabled = true
	fire_light.light_volumetric_fog_energy = 2.0
	fire_light.position = FIRE_POS + Vector3(0, 0.9, 0)
	add_child(fire_light)
	Util.static_cyl(self, FIRE_POS, 1.5, 1.0)

# ---------------------------------------------------------------- per frame
func _level_process(delta: float) -> void:
	fire_light.light_energy = fire_base * (1.0 + noise.get_noise_1d(t * 9.0) * 0.33 + noise.get_noise_1d(t * 31.0) * 0.13)
	var to_cam := cam.global_position - FIRE_POS
	to_cam.y = 0.0
	var front := FIRE_POS + to_cam.normalized() * 0.45
	flames.global_position = front + Vector3(0, 0.38, 0)
	embers.global_position = front + Vector3(0, 0.6, 0)
	if paper and paper.get_parent() == party[0]:
		paper.position.y = 1.15 + sin(t * 3.0) * 0.04
		paper.modulate = light_at(party[0].global_position)
	# goblin wanders around his spot
	goblin_timer -= delta
	if goblin_timer <= 0.0 and not goblin.has_meta("goal"):
		goblin_timer = rng.randf_range(2.5, 5.0)
		goblin.set_meta("goal", GOBLIN_HOME + Vector3(rng.randf_range(-1.8, 1.8), 0, rng.randf_range(-1.8, 1.8)))
		goblin.set_meta("goal_speed", 1.0)
	if goblin.has_meta("goal") and goblin.global_position.distance_to(goblin.get_meta("goal")) < 0.4:
		goblin.remove_meta("goal")
	# heading out
	if stage == "lit" and not busy and not leaving and leader.global_position.distance_to(EXIT_POS) < 3.5:
		leaving = true
		_leave_camp()

# maps: the two tents are the camp's "buildings"
func map_buildings() -> Array:
	return [{ "pos": SKORN_TENT, "name": "Skorn's Tent" }, { "pos": LYKOR_TENT, "name": "Lykor's Tent" }]

func _level_interactables() -> Array:
	if stage == "lit":
		return [
			{ "id": "fire", "label": "Campfire", "verb": "Rest at", "pos": FIRE_POS, "h": 1.8, "r": 2.9, "steps": CampScript.OBJECTS["fire"], "rest": true },
			{ "id": "map", "label": "Charred paper", "verb": "Look at", "pos": Vector3(1.5, 0, 1.4), "h": 0.7, "r": 1.4, "steps": CampScript.OBJECTS["map"] },
			{ "id": "bag", "label": "Lykor's bag", "verb": "Look at", "pos": Vector3(-2.7, 0, -1.6), "h": 1.0, "r": 1.6, "steps": CampScript.OBJECTS["bag"] },
			{ "id": "tent", "label": "Tent", "verb": "Look at", "pos": SKORN_TENT, "h": 3.2, "r": 3.4, "steps": CampScript.OBJECTS["tent"] },
			{ "id": "goblin", "label": "Goblin (Between Jobs)", "verb": "Talk to", "node": goblin, "h": 1.6, "r": 2.2, "steps": CampScript.OBJECTS["goblin"] },
		]
	var pre := CampScript.PRE_FIRE
	var list: Array = [
		{ "id": "pit", "label": "Fire pit", "verb": ("Put the paper in the" if stage == "has_map" else "Look at"), "pos": FIRE_POS, "h": 1.4, "r": 2.9, "steps": pre["pit_with_map"] if stage == "has_map" else pre["pit"] },
		{ "id": "tent", "label": "Tent", "verb": "Search", "pos": SKORN_TENT, "h": 3.2, "r": 3.4, "steps": pre["tent"] },
		{ "id": "goblin", "label": "Goblin (Between Jobs)", "verb": "Talk to", "node": goblin, "h": 1.6, "r": 2.2, "steps": pre["goblin"] },
		{ "id": "lykor", "label": "Lykor", "verb": "Talk to", "node": party[1], "h": 2.15, "r": 1.9, "steps": pre["lykor"] },
		{ "id": "xylo", "label": "Xylo", "verb": "Talk to", "node": party[2], "h": 2.15, "r": 1.9, "steps": pre["xylo"] },
	]
	if stage == "start":
		list.append({ "id": "bag", "label": "Lykor's bag", "verb": "Search", "pos": Vector3(-2.7, 0, -1.6), "h": 1.0, "r": 1.6, "steps": pre["bag"] })
	return list

func current_interactables() -> Array:
	return _level_interactables() if stage != "lit" else super()

# ---------------------------------------------------------------- dialogue actions
func _on_action(n: String) -> void:
	match n:
		"check_bag":
			Game.set_flag("bag_checked")
		"grab_map":
			await _grab_map()
		"burn_map":
			await _burn_map()
		"freakout":
			shake = 0.35
			hop(party[1], 0.6)
			hop(party[2], 0.6)
			await wait(0.4)
		"party_up":
			stage = "lit"
			follow_enabled = true
			switch_enabled = true
			set_leader(party[0])
			objective("Explore the camp, then head north up the path. (The goblins are up north.)", EXIT_POS)
			Game.set_flag("campLit")
			if not shots_mode:
				Game.save_game("auto", self)   # free roam starts: checkpoint

func _paper_tex() -> ImageTexture:
	var img := Image.create(64, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.86, 0.78, 0.6))
	for y in [10, 18, 26, 34]:
		for x in range(8, 56):
			if (x * 7 + y * 3) % 11 < 7:
				img.set_pixel(x, y + int(sin(x * 0.7) * 2.0), Color(0.3, 0.2, 0.15))
	return ImageTexture.create_from_image(img)

func _grab_map() -> void:
	var sk := party[0]
	var tw := create_tween()
	tw.tween_property(sk.sprite, "scale", Vector3(1.05, 0.85, 1.0), 0.15)
	tw.tween_property(sk.sprite, "scale", Vector3.ONE, 0.15)
	await tw.finished
	paper = Sprite3D.new()
	paper.texture = _paper_tex()
	paper.pixel_size = 0.009
	paper.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	paper.shaded = false
	paper.no_depth_test = true
	paper.position = Vector3(0.45, 1.15, 0.1)
	sk.add_child(paper)
	paper.scale = Vector3.ZERO
	create_tween().tween_property(paper, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ui_sfx.pitch_scale = 1.3
	ui_sfx.play()
	stage = "has_map"
	Game.set_flag("hasMap")   # shows as "Metocy Map (firestarter)" in the inventory until it's burned
	objective("Put the paper in the fire pit.", FIRE_POS)
	await wait(0.3)
	ui_sfx.pitch_scale = 1.0

func _burn_map() -> void:
	Game.set_flag("hasMap", false)
	var sk := party[0]
	var start_pos := paper.global_position
	sk.remove_child(paper)
	add_child(paper)
	paper.global_position = start_pos
	var tw := create_tween()
	tw.tween_property(paper, "global_position", start_pos.lerp(FIRE_POS, 0.5) + Vector3(0, 1.2, 0), 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(paper, "global_position", FIRE_POS + Vector3(0, 0.2, 0), 0.25).set_ease(Tween.EASE_IN)
	await tw.finished
	paper.queue_free()
	paper = null
	whoosh_sfx.pitch_scale = 0.6
	whoosh_sfx.play()
	shake = 0.6
	flames.emitting = true
	embers.emitting = true
	scrap_mesh.visible = true
	var lt := create_tween()
	lt.tween_property(self, "fire_base", 7.0, 0.12)
	lt.tween_property(self, "fire_base", 3.0, 0.8)
	create_tween().tween_property(coal_mat, "emission_energy_multiplier", 2.5, 0.6)
	create_tween().tween_property(amb.fire_player, "volume_db", -4.0, 1.2)
	objective("")
	await wait(1.3)
	whoosh_sfx.pitch_scale = 1.0

# ---------------------------------------------------------------- title screen + saves
func _light_fire_now() -> void:
	fire_base = 3.0
	flames.emitting = true
	embers.emitting = true
	scrap_mesh.visible = true
	coal_mat.emission_energy_multiplier = 2.5
	amb.fire_player.volume_db = -4.0

func _title_backdrop() -> void:
	_light_fire_now()
	amb.fire_player.volume_db = -8.0
	party[0].global_position = Vector3(-2.3, 0, 2.6)   # Skorn joins the other two around the fire
	focus_override = FIRE_POS + Vector3(0.6, 0, 0.4)
	zoom = 9.5
	cam_height = 0.42
	cam_look_h = 1.4
	yaw = 0.35
	target_yaw = 0.35
	_update_camera(1.0)

func can_resume() -> bool:
	return stage == "lit" and not leaving

func can_resume_saved() -> bool:
	return Game.flag("campLit")

func _resume(r: Dictionary) -> void:
	_light_fire_now()
	stage = "lit"
	follow_enabled = true
	switch_enabled = true
	objective("Explore the camp, then head north up the path. (The goblins are up north.)", EXIT_POS)
	await super._resume(r)

func _leave_camp() -> void:
	if Game.flag("campDone"):   # walked back here earlier: just head on to the village (no leaving scene again)
		busy = true
		await fade_out(0.6)
		Game.travel("res://village.tscn", "camp", leader.id)
		return
	await run_dialogue(CampScript.LEAVE)
	Game.set_flag("campDone")
	await fade_out(1.0)
	Game.goto("res://village.tscn")

# walking back from the village: arrive at the top of the north path, facing back into camp
func arrival(from: String) -> Array:
	if from == "village":
		return [EXIT_POS + Vector3(0, 0, 6.5), Vector3(0, 0, 1)]
	return super.arrival(from)

# Shown once when a new game starts (Ebain's note: off the main menu, on at the start instead)
func _chapter_card() -> void:
	title_box.visible = false
	minimap.visible = false
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.add_child(box)   # on top of the black fade-in (the hud sits under it)
	var cz := FontVariation.new()
	cz.base_font = load("res://assets/fonts/Cinzel.ttf")
	cz.variation_embolden = 0.8
	var a := _label("CHAPTER 1", Vector2.ZERO, 30, Color("#c9c0e8"), 6)
	var b := _label("The Quest for the Metocy", Vector2.ZERO, 56, Color("#e8b923"), 10)
	for l in [a, b]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_override("font", cz)
		l.modulate.a = 0.0
		box.add_child(l)
	var tw := create_tween()
	tw.tween_property(a, "modulate:a", 1.0, 0.6)
	tw.tween_property(b, "modulate:a", 1.0, 0.8)
	tw.tween_interval(1.8 if not shots_mode else 0.2)
	tw.set_parallel(true)
	tw.tween_property(a, "modulate:a", 0.0, 0.7)
	tw.tween_property(b, "modulate:a", 0.0, 0.7)
	await tw.finished
	box.queue_free()
	title_box.visible = true
	minimap.visible = true

func _begin() -> void:
	busy = true
	fade.color.a = 1.0
	await _chapter_card()
	zoom = 17.0
	yaw = 0.9
	target_yaw = 0.9
	_update_camera(1.0)
	create_tween().tween_property(fade, "color:a", 0.0, 2.2)
	create_tween().tween_property(self, "zoom", 8.0, 4.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(self, "target_yaw", 0.0, 4.5).set_trans(Tween.TRANS_SINE)
	await wait(1.6)
	await run_dialogue(CampScript.INTRO)
	objective("Get the fire going.", FIRE_POS)

# ---------------------------------------------------------------- automated screenshots
func _shot_tour() -> void:
	if OS.get_environment("LOOK") != "":   # LOOK="x,z,yaw;x,z,yaw" → close-up screenshots of spots (fire lit)
		fade.color.a = 0.0
		fire_base = 2.6
		flames.emitting = true
		embers.emitting = true
		var i := 0
		for spot in OS.get_environment("LOOK").split(";"):
			var v := spot.split(",")
			place_party(Vector3(float(v[0]), 0, float(v[1])), Vector3(0, 0, -1))
			target_yaw = float(v[2])
			zoom = 6.0
			await wait(1.5)
			await shot("look_%d" % i)
			i += 1
		get_tree().quit()
		return
	busy = true
	fade.color.a = 0.0
	objective("Get the fire going.", FIRE_POS)
	target_yaw = 0.7
	await wait(2.0)
	await shot("camp_01_unlit")
	party[0].global_position = Vector3(-2.0, 0, -0.6)
	cam_target = party[0].global_position
	await wait(1.5)
	busy = false
	start(current_interactables().filter(func(i): return i["id"] == "bag")[0])
	await wait(1.6)
	await shot("camp_02_got_paper")
	await advance(3)
	await wait(1.0)
	party[0].global_position = Vector3(1.9, 0, 2.2)
	cam_target = party[0].global_position
	await wait(1.5)
	start(current_interactables().filter(func(i): return i["id"] == "pit")[0])
	await wait(2.2)
	await shot("camp_03_lit")
	await advance(13)
	await wait(1.5)
	await shot("camp_04_free_roam")
	place_party(EXIT_POS + Vector3(0, 0, 3), Vector3(0, 0, -1))
	await wait(2.5)
	await shot("camp_05_leaving")
	await advance(3)
	await wait(2.0)
	get_tree().quit()
