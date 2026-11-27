# In-world battle presentation. The fight happens right where you are: party lines up on the left,
# enemies on the right, the camera swings to a battle angle and the menus go on top.
# battle.gd decides everything; this file only asks the player and animates the events.
#
#   var view := BattleView.new()
#   level.add_child(view)
#   var result: String = await view.run("goblins", { party = [units], enemies = [units], center = Vector3 })
#   → "win" / "lose" / "fled" / "talked"
class_name BattleView
extends Node

const D = preload("res://scripts/combat/combat_data.gd")
const BattleT = preload("res://scripts/combat/battle.gd")
const PORTRAIT := { "goblin": "goblin", "dulbers": "dulbers_demon", "giant": "giant_angry", "rat": "rat", "rat_king": "rat_king" }
const GOLD := Color("#e8b923")
const RED := Color("#ff6a5a")
const GREEN := Color("#7dff8a")
const PURPLE := Color("#c79bff")

var lv: Level
var b: Battle
var music: BattleMusic   # Ebain's fight/boss themes (battle_music.gd)
var key := ""
var fdef: Dictionary
var nodes := {}          # battle unit key -> Unit
var spots := {}          # battle unit key -> Vector3
var base_tint := {}      # battle unit key -> Color
var saved_pose := {}     # Unit -> [views, height_m, view]
var spawned: Array = []
var center := Vector3.ZERO
var right := Vector3.RIGHT
var fwd := Vector3.FORWARD
var cinematic := false
var speed := 1.0
var saved := {}
var sounds := {}
var auto_play := false
# Dulbmeethus' strike cutscene (Ebain 11/25): a full-screen video that ends on a white-out. See _strike_cutscene().
const STRIKE_VIDEO := "res://assets/video/dulbmeethus_strike.ogv"   # Godot only plays Ogg Theora (.ogv), not mp4/mov
const STRIKE_SOUND := "res://assets/sounds/dulbmeethus_attack.ogg"
var _strike_vp: VideoStreamPlayer = null
var _strike_skip := false
var _strike_t0 := 0

# UI
var root: Control
var log_lbl: Label
var banner: Label
var timeline: HBoxContainer
var enemy_box: VBoxContainer
var party_box: HBoxContainer
var menu_panel: PanelContainer
var menu_title: Label
var menu_list: VBoxContainer
var menu_desc: Label
var hint: Label
var flash_rect: ColorRect
var ebars := {}          # key -> { hp, hp_lbl, st, name }
var overhead: Control    # (Asar 11/23) small red HP bars floating over each enemy's head
var head_bars := {}      # key -> { box, fill, lag, w }
var pbars := {}          # key -> { hp, hp_lbl, meter, st, card }
var actor_marker: MeshInstance3D
var target_marker: MeshInstance3D

# menu state
var _menu_opts: Array = []
var _menu_sel := 0
var _menu_btns: Array = []
var _menu_active := false
signal _menu_done(value)

# Asar 11/25: no "Talk" option in fights (the TALK options in combat_data stay, flip this to bring it back).
const TALK_IN_FIGHTS := false

func _init() -> void:
	name = "BattleView"

# ================================================================== entry
func run(fight_key: String, o: Dictionary = {}) -> String:
	lv = get_parent()
	key = fight_key
	fdef = D.FIGHTS[key]
	cinematic = fdef.get("boss", false)
	speed = (1.0 if cinematic else 0.7) * Game.BATTLE_SPEED[Game.battle_speed][1]   # Settings → Battle speed
	auto_play = lv.shots_mode
	mog_cam_test = auto_play
	shi_cam_test = auto_play
	throw_test = auto_play
	var party_units: Array = o.get("party", [])
	var ids := []
	for u in party_units:
		ids.append(u.id)
	var gear := {}
	for id in ids:
		if id in ["skorn", "lykor", "xylo", "chief"]:
			gear[id] = Game.gear_stats(id)   # all 7 slots added up
	b = BattleT.new(key, {
		"party": ids, "mods": o.get("mods", {}), "level": Game.level, "inv": Game.fight_bags(ids),
		"difficulty": Game.difficulty, "used67": Game.used67, "gear": gear, "hurt": Game.hurt,
		"faded": int(Game.flags.get("fadedFights", 0)) > 0, "lore_nerf": Game.flag("deloyeBad"), "dulbmeethus": Game.dev_dulbmeethus,   # the Deloye library
	})
	if auto_play and OS.get_environment("AUTO_LOSE") != "":
		for p in b.party:
			p["hp"] = 1
		for id in b.bags: b.bags[id] = { "beer": 0, "bowl": 0, "joint": 0 }
		b.emergency_given = true
		b.used67 = true
	_make_sounds()
	music = BattleMusic.new()
	add_child(music)
	music.start(key)
	_save_state()
	_place(party_units, o.get("enemies", []), o.get("center", null))
	if "skorn" in ids:
		_spawn_pile()   # real stuff for Skorn's Throw Anything (Asar: throw objects, not words)
	_build_ui()
	await _intro()
	await CombatTutorial.offer_first(lv)   # 11/26: first fight of a save offers the tutorial (Esc menu / H replays it)
	var res := await _loop()
	music.stop()
	_heartbeat(false)
	await _outro(res)
	return res

# ================================================================== setup
func _save_state() -> void:
	saved = {
		"busy": lv.busy, "follow": lv.follow_enabled, "switch": lv.switch_enabled, "zoom": lv.zoom,
		"cam_height": lv.cam_height, "cam_look_h": lv.cam_look_h, "focus": lv.focus_override,
		"locked": lv.cam_locked, "box": lv.dialogue.panel.visible, "objective": lv.objective_lbl.visible,
	}
	lv.busy = true
	lv.follow_enabled = false
	lv.switch_enabled = false
	lv.cam_locked = true
	lv.objective_lbl.visible = false
	lv.help_lbl.visible = false
	lv.title_box.visible = false   # title + minimap step aside in fights (the turn order uses the top middle)
	lv.minimap.visible = false
	lv.prompt.visible = false
	if saved["box"]:
		lv.dialogue.hide_box()

func _place(party_units: Array, enemy_units: Array, c) -> void:
	right = Vector3.RIGHT.rotated(Vector3.UP, lv.yaw)
	fwd = Vector3.FORWARD.rotated(Vector3.UP, lv.yaw)
	var giant := key == "giant"
	# enemies: reuse the ones standing in the world, or spawn them
	var enemy_nodes := []
	for i in b.enemies.size():
		var e: Dictionary = b.enemies[i]
		var n: Unit
		if i < enemy_units.size():
			n = enemy_units[i]
		else:
			var E: Dictionary = e["E"]
			var start: Vector3 = (c if c != null else lv.leader.global_position) + right * 9.0 + fwd * (i - 1) * 1.4
			n = lv.spawn_npc("enemy_%d" % i, E["name"], E["tex"], E["h"], start)
			spawned.append(n)
		enemy_nodes.append(n)
	if c == null:
		var a: Vector3 = party_units[0].global_position
		var m := Vector3.ZERO
		for n in enemy_nodes:
			m += n.global_position
		m /= max(1, enemy_nodes.size())
		c = a.lerp(m, 0.5)
		c.y = 0.0
	var np := party_units.size()
	var ne := enemy_nodes.size()
	# (Ebain 11/24) fit the lineup between the walls: in a narrow tunnel the old fixed spacing put units inside the rock
	var fit := _fit_lineup(c, 1.9 + (np - 1) * 1.15, 1.9 + (ne - 1) * 1.15 if not giant else 4.6)
	c = fit[0]
	var sc: float = fit[1]
	var stagger := 0.55 if sc > 0.85 else 1.0   # squeezed: stagger more in depth so they don't overlap
	center = c
	for i in np:
		var u: Unit = party_units[i]
		var k: String = b.party[i]["key"]
		nodes[k] = u
		spots[k] = center - right * (1.9 + i * 1.15) * sc + fwd * (stagger if i % 2 == 1 else 0.0)
	for i in ne:
		var k: String = b.enemies[i]["key"]
		nodes[k] = enemy_nodes[i]
		if giant:
			spots[k] = center + right * 4.6 * sc + fwd * 1.8
		else:
			spots[k] = center + right * (1.9 + i * 1.15) * sc + fwd * (stagger if i % 2 == 1 else 0.0)
	for k in nodes:
		var u: Unit = nodes[k]
		base_tint[k] = u.get_meta("tint") if u.has_meta("tint") else Color.WHITE
		var eu := _unit_by_key(k)   # enemy roles get a tint (11/26: shaman green, shield blue, bomber orange)
		if eu.get("side", "") == "enemy" and eu["E"].has("tint"):
			base_tint[k] = Color(eu["E"]["tint"])
			u.set_meta("tint", base_tint[k])
		saved_pose[u] = [u.views.duplicate(), u.height_m]
		u.frozen = false
		u.remove_meta("follow")
		u.set_meta("goal", spots[k])
		u.set_meta("goal_speed", 1.3)
	# enemies switch to their fight art
	for i in ne:
		var E: Dictionary = b.enemies[i]["E"]
		var u: Unit = enemy_nodes[i]
		var tex := _tex(E["tex"])
		if tex and u.sprite.texture != tex:
			u.set_pose(tex, E["h"])

# How much room is there left and right of `c` (raycasts against the world, layer 1)? Returns [new center, spacing
# scale]: the center slides over if one side is short, and the spacing shrinks if both are.
func _fit_lineup(c: Vector3, need_l: float, need_r: float) -> Array:
	var space := lv.get_world_3d().direct_space_state
	var room := func(dir: Vector3) -> float:
		var from := c + Vector3(0, 1.0, 0)
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 12.0, 1)
		var hit := space.intersect_ray(q)
		return 12.0 if hit.is_empty() else maxf(0.0, from.distance_to(hit["position"]) - 0.7)
	var rl: float = room.call(-right)
	var rr: float = room.call(right)
	need_l += 0.3
	need_r += 0.3
	if rl >= need_l and rr >= need_r:
		return [c, 1.0]
	if rl + rr >= need_l + need_r:   # enough room in total: slide toward the open side
		var shift := (need_l - rl) if rl < need_l else -(need_r - rr)
		return [c + right * shift, 1.0]
	var sc := maxf(0.35, (rl + rr) / (need_l + need_r))
	return [c + right * (need_l * sc - rl), sc]   # left end touches the left wall, right end the right one

# a jagged bolt from the sky onto a unit (unshaded, bright), gone after a moment
func _bolt(n: Node3D) -> void:
	if n == null:
		return
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.9, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	lv.add_child(mi)
	var base: Vector3 = n.global_position
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var p := base + Vector3(randf_range(-0.6, 0.6), 14.0, 0)
	var w := 0.12
	while p.y > base.y + 0.2:
		var q := Vector3(base.x + randf_range(-0.5, 0.5), maxf(base.y, p.y - randf_range(1.0, 2.2)), base.z)
		for v in [p + Vector3(-w, 0, 0), p + Vector3(w, 0, 0), q + Vector3(w, 0, 0), p + Vector3(-w, 0, 0), q + Vector3(w, 0, 0), q + Vector3(-w, 0, 0)]:
			im.surface_add_vertex(v)
		p = q
	im.surface_end()
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 0.8, 1.0)
	l.light_energy = 6.0
	l.omni_range = 8.0
	l.position = base + Vector3(0, 2.0, 0)
	lv.add_child(l)
	get_tree().create_timer(0.35).timeout.connect(func():
		mi.queue_free()
		l.queue_free())

# ---- Ebain's lightning art (11/25): the real pictures for Dulbmeethus' hits. Each enemy gets an additive (glow-only,
# the black parts add nothing) bolt from the sky, an impact flash and a glowing scorch on the ground that fades slowly.
# _bolt_art() returns false when the pictures are missing, and the plain bolt above is used instead.
var _vfx_tex := {}

func _vfx(vname: String) -> Texture2D:
	if not _vfx_tex.has(vname):
		var p := "res://assets/vfx/%s.png" % vname
		_vfx_tex[vname] = load(p) if ResourceLoader.exists(p) else null
	return _vfx_tex[vname]

# one additive picture in the 3D world: upright and facing the camera, or lying flat on the ground
func _glow_quad(tex: Texture2D, size: Vector2, pos: Vector3, flat := false) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_texture = tex
	m.albedo_color = Color(0, 0, 0, 1)
	if not flat:
		m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	if flat:
		mi.rotation_degrees = Vector3(-90, randf_range(0, 360), 0)
	lv.add_child(mi)
	return mi

# brightness steps (each held 0.05 s: a flicker), then a fade to black over `tail` seconds, then it removes itself.
# The tween belongs to the picture itself, so nothing is left behind if the fight scene goes away early.
func _fade_glow(mi: MeshInstance3D, steps: Array, tail: float) -> void:
	var m: StandardMaterial3D = mi.material_override
	var tw := mi.create_tween()
	for v in steps:
		tw.tween_property(m, "albedo_color", Color(v, v, v, 1), 0.05)
	tw.tween_property(m, "albedo_color", Color(0, 0, 0, 1), tail)
	tw.tween_callback(mi.queue_free)

func _bolt_art(n: Node3D) -> bool:
	if n == null:
		return true
	var tex := _vfx("bolt_%d" % (randi() % 3 + 1))
	if tex == null:
		return false
	var base: Vector3 = n.global_position
	var cam := get_viewport().get_camera_3d()
	var toward := Vector3.ZERO
	if cam != null:   # a little toward the camera, so the glow sits in front of the enemy card
		toward = ((cam.global_position - base) * Vector3(1, 0, 1)).normalized() * 0.5
	var h := 11.0   # the bolt's tip lands at the enemy's feet
	var bolt := _glow_quad(tex, Vector2(h * tex.get_width() / tex.get_height(), h), base + toward + Vector3(0, h * 0.5 - 0.2, 0))
	_fade_glow(bolt, [2.0, 0.6, 1.8, 0.5, 1.4], 0.45)
	var burst := _vfx("impact")
	if burst != null:   # the burst where it lands: pops out as it fades
		var fl := _glow_quad(burst, Vector2(3.4, 3.4), base + toward + Vector3(0, 0.9, 0))
		_fade_glow(fl, [1.6, 1.3], 0.5)
		fl.scale = Vector3(0.4, 0.4, 0.4)
		fl.create_tween().tween_property(fl, "scale", Vector3(1.5, 1.5, 1.5), 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	var burn := _vfx("scorch")
	if burn != null:   # the burn left on the ground, fades over ~3 s
		var sc := _glow_quad(burn, Vector2(3.6, 3.6 * burn.get_height() / burn.get_width()), Vector3(base.x, base.y + 0.04, base.z), true)
		_fade_glow(sc, [1.2, 1.0, 0.9, 1.0, 0.8], 3.2)
	var l := OmniLight3D.new()
	l.light_color = Color(0.95, 0.6, 1.0)
	l.light_energy = 8.0
	l.omni_range = 9.0
	l.position = base + Vector3(0, 2.0, 0)
	lv.add_child(l)
	var lt := l.create_tween()
	lt.tween_property(l, "light_energy", 0.0, 0.7)
	lt.tween_callback(l.queue_free)
	return true

func _tex(n: String) -> Texture2D:
	var p := "res://assets/characters/%s.png" % n
	return load(p) if ResourceLoader.exists(p) else null

func _make_sounds() -> void:
	var defs := {
		"hit": Util.noise_burst(80, 0.5, 0.9), "slap": Util.noise_burst(110, 0.6, 1.0), "bonk": Util.chime(520, 140, 0.35),
		"blast": Util.noise_burst(260, 0.15, 0.8), "lore": Util.chime(330, 400, 0.3), "fire": Util.noise_burst(420, 0.07, 0.8),
		"sparkle": Util.chime(1600, 280, 0.2), "mog": Util.chime(196, 500, 0.35), "sit": Util.noise_burst(600, 0.025, 1.0),
		"stomp": Util.noise_burst(320, 0.035, 1.0), "miss": Util.noise_burst(140, 0.9, 0.35), "crit": Util.chime(1320, 320, 0.3),
		"roar": Util.noise_burst(750, 0.05, 0.9), "gulp": Util.chime(280, 220, 0.3), "throw": Util.noise_burst(100, 0.9, 0.5),
		"grab": Util.chime(880, 160, 0.25), "ready": Util.chime(1175, 450, 0.25), "select": Util.chime(990, 90, 0.15),
		"move": Util.chime(660, 50, 0.08), "heal": Util.chime(784, 350, 0.22), "dice": Util.noise_burst(60, 0.9, 0.4),
		"low": Util.chime(110, 900, 0.4),
	}
	for k in defs:
		sounds[k] = lv._sfx(defs[k], -4.0)
	# Asar's sound effects pack (11/22): recorded versions where they fit
	for pair in [["slap", "sfx_punch", 0.0], ["hit", "sfx_punch", -3.0], ["fire", "sfx_fire_explosion", -2.0], ["blast", "sfx_magic", -2.0],
			["lore", "sfx_magic", -4.0], ["crit", "sfx_timed_success", -2.0], ["heal", "sfx_heal", -2.0], ["bonk", "sfx_sword", -4.0]]:
		var st = load("res://assets/sounds/%s.ogg" % pair[1])
		if st:
			sounds[pair[0]].stream = st
			sounds[pair[0]].volume_db = pair[2]
	# Ebain's sfx pack (11/26): the boing on a fumble, record scratches, rat squeaks, real dice, the heartbeat
	for pair in [["boing", "sfx_boing", -4.0], ["awkward", "sfx_vinyl_awkward", -5.0], ["rewind", "sfx_vinyl_rewind", -5.0],
			["squeak", "sfx_rat_squeak", -6.0], ["squeak2", "sfx_rat_squeak2", -4.0], ["dice_real", "sfx_dice", -5.0],
			["tiger", "sfx_tiger_roar", -3.0], ["gob_laugh", "sfx_goblin_evil_laugh", -4.0], ["heart", "sfx_heartbeat", -9.0]]:
		var p2 := "res://assets/sounds/%s.ogg" % pair[1]
		if ResourceLoader.exists(p2):
			var st2: AudioStream = load(p2)
			if pair[0] == "heart":
				st2 = st2.duplicate()
				st2.loop = true
			sounds[pair[0]] = lv._sfx(st2, pair[2])
	# 11/26 AAA pass: layered combat sounds (assets/sounds/cmb_*.ogg, mixed from CC0 packs: Kenney, rubberduck, starninjas)
	for c in ["cmb_hit_phys_1", "cmb_hit_phys_2", "cmb_hit_phys_3", "cmb_hit_aura_1", "cmb_hit_aura_2", "cmb_hit_lore_1", "cmb_hit_lore_2",
			"cmb_hit_big", "cmb_perfect", "cmb_whoosh_1", "cmb_whoosh_2", "cmb_whoosh_3", "cmb_block", "cmb_block_perfect", "cmb_break",
			"cmb_weak", "cmb_downed", "cmb_revive", "cmb_grade_slam", "cmb_meter_full", "cmb_explode", "cmb_ui_move", "cmb_ui_select", "cmb_ui_back"]:
		var cp := "res://assets/sounds/%s.ogg" % c
		if ResourceLoader.exists(cp):
			sounds[c] = lv._sfx(load(cp), -3.0)
	if sounds.has("cmb_ui_move"): sounds["move"] = sounds["cmb_ui_move"]
	if sounds.has("cmb_ui_select"): sounds["select"] = sounds["cmb_ui_select"]
	if sounds.has("cmb_explode"): sounds["explode"] = sounds["cmb_explode"]
	sounds["shi"] = lv._sfx(load("res://assets/voices/lykor/on_some_type_shit.mp3"), linear_to_db(maxf(Game.voice_vol, 0.01)))   # Asar's Lykor take (same file as his Mart line), at the Voice volume
	var strike_st = load(STRIKE_SOUND) if ResourceLoader.exists(STRIKE_SOUND) else null
	if strike_st:
		sounds["strike"] = lv._sfx(strike_st, 0.0)   # Ebain's clip for the moment Dulbmeethus actually attacks (played plain, no pitch change)

# (Ebain's sfx pack) heartbeat loop while anyone on our side is at 25% HP or less
func _heartbeat(on: bool) -> void:
	if not sounds.has("heart"):
		return
	var h: AudioStreamPlayer = sounds["heart"]
	if on and not h.playing:
		h.play()
	elif not on and h.playing:
		h.stop()

func sfx(k: String, pitch := 1.0) -> void:
	if sounds.has(k):
		var p: AudioStreamPlayer = sounds[k]
		p.pitch_scale = pitch * randf_range(0.94, 1.06)
		p.play()

# ================================================================== UI
func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.hud.add_child(root)

	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_rect)

	timeline = HBoxContainer.new()
	timeline.anchor_left = 0.5; timeline.anchor_right = 0.5
	timeline.offset_left = -260; timeline.offset_right = 260; timeline.offset_top = 14
	timeline.alignment = BoxContainer.ALIGNMENT_CENTER
	timeline.add_theme_constant_override("separation", 6)
	root.add_child(timeline)

	log_lbl = lv._label("", Vector2.ZERO, 21, Color.WHITE, 7)
	log_lbl.anchor_left = 0.5; log_lbl.anchor_right = 0.5
	log_lbl.offset_left = -470; log_lbl.offset_right = 470; log_lbl.offset_top = 76
	log_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(log_lbl)

	banner = lv._label("", Vector2.ZERO, 56, RED, 12)
	banner.add_theme_font_override("font", UITheme.head_font())
	banner.anchor_left = 0.5; banner.anchor_right = 0.5; banner.anchor_top = 0.32
	banner.offset_left = -600; banner.offset_right = 600
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.modulate.a = 0.0
	root.add_child(banner)

	overhead = Control.new()
	overhead.set_anchors_preset(Control.PRESET_FULL_RECT)
	overhead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overhead)   # under the timeline, log, panels and menus
	for e in b.enemies:
		head_bars[e["key"]] = _head_bar(e)

	enemy_box = VBoxContainer.new()
	enemy_box.anchor_left = 1.0; enemy_box.anchor_right = 1.0
	enemy_box.offset_left = -330; enemy_box.offset_right = -18; enemy_box.offset_top = 92
	enemy_box.add_theme_constant_override("separation", 6)
	root.add_child(enemy_box)
	for e in b.enemies:
		_enemy_row(e)

	party_box = HBoxContainer.new()
	party_box.anchor_top = 1.0; party_box.anchor_bottom = 1.0
	party_box.offset_left = 18; party_box.offset_top = -138; party_box.offset_bottom = -40
	party_box.add_theme_constant_override("separation", 8)
	root.add_child(party_box)
	for p in b.party:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(196, 0)
		card.add_theme_stylebox_override("panel", _card_box())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)
		var por := TextureRect.new()
		por.texture = load("res://assets/portraits/%s.png" % p["id"])
		por.custom_minimum_size = Vector2(48, 48)
		por.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		por.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		por.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(por)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var pn := _pl(p["name"] if p["id"] != "chief" else "The Chief", 16, UITheme.c("accent", _th()), 4)
		pn.add_theme_font_override("font", UITheme.row_font())
		col.add_child(pn)
		var hp_lbl := _pl("", 12, Color(1, 1, 1, 0.85), 3)
		col.add_child(hp_lbl)
		var hp := _bar(GREEN, Vector2(120, 10), true)
		hp.max_value = p["max_hp"]
		col.add_child(hp)
		var meter := _bar(Color("#ffb13a"), Vector2(120, 7))
		meter.max_value = 100
		col.add_child(meter)
		var st := _status_row(12)
		st.set_meta("panel", true)   # inside a party card: chips use _pl
		col.add_child(st)
		party_box.add_child(card)
		pbars[p["key"]] = { "hp": hp, "hp_lbl": hp_lbl, "meter": meter, "st": st, "card": card }

	menu_panel = PanelContainer.new()
	menu_panel.anchor_left = 1.0; menu_panel.anchor_right = 1.0; menu_panel.anchor_top = 1.0; menu_panel.anchor_bottom = 1.0
	menu_panel.offset_left = -400; menu_panel.offset_right = -18; menu_panel.offset_bottom = -40
	menu_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN   # long move names widen it leftward, not off-screen (Asar 11/25)
	var mp := UITheme.panel(0.95, _th())
	mp.content_margin_left = 22; mp.content_margin_right = 22; mp.content_margin_top = 20; mp.content_margin_bottom = 14
	menu_panel.add_theme_stylebox_override("panel", mp)
	var mcol := VBoxContainer.new()
	mcol.add_theme_constant_override("separation", 2)
	menu_panel.add_child(mcol)
	menu_title = _pl("", 19, UITheme.c("accent", _th()), 5)
	menu_title.add_theme_font_override("font", UITheme.head_font())
	mcol.add_child(menu_title)
	menu_list = VBoxContainer.new()
	menu_list.add_theme_constant_override("separation", 0)
	mcol.add_child(menu_list)
	menu_desc = _pl("", 14, UITheme.c("note", _th()), 3)
	menu_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_desc.custom_minimum_size = Vector2(350, 0)
	mcol.add_child(menu_desc)
	menu_panel.visible = false
	root.add_child(menu_panel)

	hint = lv._label("", Vector2.ZERO, 13, Color(1, 1, 1, 0.55), 3)
	hint.anchor_left = 1.0; hint.anchor_right = 1.0; hint.anchor_top = 1.0; hint.anchor_bottom = 1.0
	hint.offset_left = -640; hint.offset_right = -18; hint.offset_top = -32
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(hint)
	_update_hint()

	actor_marker = _marker(Color("#7dff8a"))
	target_marker = _marker(GOLD)
	_refresh()

# One enemy's row in the top-right panel (name + HP x/x, red bar, status chips). Also used for adds that join mid-fight.
func _enemy_row(e: Dictionary) -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 1)
	var head := HBoxContainer.new()   # name on the left, HP x/x on the right (Asar 11/23)
	head.add_theme_constant_override("separation", 8)
	var nm := lv._label("%s %s" % [e["name"], e["tag"]], Vector2.ZERO, 17, Color("#ffcf9a"), 5)
	nm.add_theme_font_override("font", UITheme.row_font())
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.clip_text = true
	head.add_child(nm)
	var hp_lbl := lv._label("", Vector2.ZERO, 15, Color(1, 1, 1, 0.9), 4)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(hp_lbl)
	col.add_child(head)
	var hp := _bar(RED, Vector2(300, 14), true)
	hp.max_value = e["max_hp"]
	hp.value = e["hp"]
	col.add_child(hp)
	var brk: ProgressBar = null
	if e.has("brk_max"):   # boss break bar (11/26): fills as you hit him, full = BROKEN
		brk = _bar(Color("#ffc23a"), Vector2(300, 6))
		brk.max_value = e["brk_max"]
		brk.value = e["brk"]
		brk.tooltip_text = "BREAK BAR: fills as you hit him (perfect hits, Distracted, HYPED and weak spots fill it faster). Full = BROKEN: he loses a turn and takes 50% more damage."
		col.add_child(brk)
	var st := _status_row(14)
	col.add_child(st)
	enemy_box.add_child(col)
	ebars[e["key"]] = { "hp": hp, "hp_lbl": hp_lbl, "st": st, "name": nm, "col": col, "brk": brk }

# Adds joining mid-fight (Dulbers' employees, 11/26): spawn them next to the boss, slide them in, give them bars
func _add_enemy(e: Dictionary, j: int) -> void:
	var boss_spot: Vector3 = spots[b.enemies[0]["key"]]
	var spot: Vector3 = boss_spot - right * 1.6 + fwd * (1.6 if j % 2 == 0 else -1.4)
	var E: Dictionary = e["E"]
	var n: Unit = lv.spawn_npc("enemy_%s" % e["key"], E["name"], E["tex"], E["h"], spot + right * 6.0)
	spawned.append(n)
	nodes[e["key"]] = n
	spots[e["key"]] = spot
	base_tint[e["key"]] = Color.WHITE
	saved_pose[n] = [n.views.duplicate(), n.height_m]
	n.frozen = false
	var tex := _tex(E["tex"])
	if tex: n.set_pose(tex, E["h"])
	n.set_view("front")
	n.sprite.flip_h = true
	n.set_meta("in_fight", true)
	var tw := create_tween()
	tw.tween_property(n, "global_position", spot, 0.5 * speed)
	head_bars[e["key"]] = _head_bar(e)
	_enemy_row(e)

func _update_hint() -> void:
	hint.text = "W/S choose · E select · Q back · T timed hits: %s · H tutorial · L log" % ("AUTO" if Game.timed_auto else "MANUAL")

# Combat panels use UITheme and follow Settings → Menu theme, Parchment too (Ebain 11/24: "always follow menu theme").
# Text INSIDE a panel goes through _pl()/_ink() so light fight colors turn into dark ink on Parchment. Text over the
# 3D world (log, banner, floating numbers, enemy names/bars on the right) keeps light colors + black outline.
func _th() -> int:
	return Game.ui_theme

func _parch() -> bool:
	return UITheme.c("outline", _th()).a < 0.05

# A fight color made readable on the current panel: on Parchment, near-white → the theme's text color, any other
# color → a deep shade of the same hue (gold → dark gold, green → dark green). Dark themes: unchanged.
func _ink(c: Color) -> Color:
	if not _parch():
		return c
	if c.s < 0.25:
		return Color(UITheme.c("text", _th()), c.a)
	return Color.from_hsv(c.h, maxf(c.s, 0.7), 0.42, c.a)

# Label that sits inside a fight panel (cards, menu, tips, results). No outline on Parchment.
func _pl(text: String, size: int, color: Color, outline: int) -> Label:
	var l := lv._label(text, Vector2.ZERO, size, _ink(color), outline)
	if _parch():
		l.add_theme_constant_override("outline_size", 0)
	return l

func _card_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(UITheme.c("bg", _th()), 0.88)
	sb.border_color = Color(UITheme.c("edge2", _th()), 0.9)
	sb.set_border_width_all(2)
	sb.border_width_top = 3
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 8; sb.content_margin_bottom = 8
	sb.shadow_color = Color(0, 0, 0, 0.35); sb.shadow_size = 6
	return sb

func _tip_box() -> StyleBoxFlat:
	var sb := _card_box()
	sb.bg_color = Color(UITheme.c("bg2", _th()), 0.97)
	sb.border_color = UITheme.c("edge", _th())
	return sb

func _box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb

func _bar(color: Color, sz: Vector2, ghost := false) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = sz
	pb.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	pb.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(4)
	if ghost:   # 11/26: a pale "ghost" bar behind it that drains a moment later, so you see how much a hit took
		var g := ProgressBar.new()
		g.show_percentage = false
		g.show_behind_parent = true
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.set_anchors_preset(Control.PRESET_FULL_RECT)
		var gf := StyleBoxFlat.new()
		gf.bg_color = Color(1, 0.95, 0.8, 0.75)
		gf.set_corner_radius_all(4)
		g.add_theme_stylebox_override("fill", gf)
		g.add_theme_stylebox_override("background", bg)
		pb.add_child(g)
		pb.set_meta("ghost", g)
		pb.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	else:
		pb.add_theme_stylebox_override("background", bg)
	return pb

# HP bars: the bar snaps down fast, its ghost catches up after a beat (healing just fills both)
func _drain(bar: ProgressBar, v: float) -> void:
	var g: ProgressBar = bar.get_meta("ghost") if bar.has_meta("ghost") else null
	if bar.has_meta("to") and is_equal_approx(float(bar.get_meta("to")), v):
		return
	bar.set_meta("to", v)
	create_tween().tween_property(bar, "value", v, 0.15 if v < bar.value else 0.3)
	if g == null:
		return
	g.max_value = bar.max_value
	if v < g.value:
		var t := create_tween()
		t.tween_interval(0.45)
		t.tween_property(g, "value", v, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	else:
		g.value = v

func _marker(color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.32, 0.32, 0.08)
	m.mesh = pm
	m.rotation_degrees = Vector3(0, 0, 180)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.no_depth_test = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.material_override = mat
	m.visible = false
	lv.add_child(m)
	return m

func _process(_d: float) -> void:
	for mk in [actor_marker, target_marker]:
		if mk and mk.visible and mk.has_meta("over"):
			var u: Unit = mk.get_meta("over")
			mk.global_position = u.global_position + Vector3(0, u.height_m + 0.45 + sin(lv.t * 5.0) * 0.07, 0)
	_place_head_bars()

# ---- (Asar 11/23) small red HP bar over each enemy: a dark frame, a pale "just lost" strip that drains a beat
# after a hit, and the red fill on top. Lives in the HUD and follows the enemy's head on screen every frame.
const HEAD_BAR_W := 74.0
const HEAD_BAR_H := 7.0
func _head_bar(e: Dictionary) -> Dictionary:
	var w := HEAD_BAR_W * (1.6 if key == "giant" or e.get("boss", false) else 1.0)
	var box := Panel.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size = Vector2(w + 2.0, HEAD_BAR_H + 2.0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.02, 0.02, 0.8)
	sb.border_color = Color(0, 0, 0, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	box.add_theme_stylebox_override("panel", sb)
	var lag := ColorRect.new()
	lag.color = Color(1.0, 0.86, 0.72, 0.85)
	lag.position = Vector2(1, 1)
	lag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(lag)
	var fill := ColorRect.new()
	fill.color = Color("#e8382b")
	fill.position = Vector2(1, 1)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(fill)
	var shine := ColorRect.new()   # thin highlight along the top so it reads as a bar, not a line
	shine.color = Color(1, 1, 1, 0.22)
	shine.position = Vector2(0, 0)
	shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_child(shine)
	var ratio := clampf(float(e["hp"]) / maxf(1.0, e["max_hp"]), 0.0, 1.0)
	fill.size = Vector2(w * ratio, HEAD_BAR_H)
	lag.size = fill.size
	shine.size = Vector2(fill.size.x, 2)
	box.visible = false
	overhead.add_child(box)
	return { "box": box, "fill": fill, "lag": lag, "shine": shine, "w": w, "ratio": ratio }

func _set_head_bar(e: Dictionary) -> void:
	var hb: Dictionary = head_bars.get(e["key"], {})
	if hb.is_empty() or not is_instance_valid(hb["box"]):
		return
	var ratio := clampf(float(e["hp"]) / maxf(1.0, e["max_hp"]), 0.0, 1.0)
	if is_equal_approx(ratio, hb["ratio"]):
		return
	var w: float = hb["w"]
	var to := Vector2(w * ratio, HEAD_BAR_H)
	var t := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(hb["fill"], "size", to, 0.25)
	t.tween_property(hb["shine"], "size", Vector2(to.x, 2), 0.25)
	if ratio < hb["ratio"]:   # took damage: the pale strip waits, then catches up
		create_tween().tween_property(hb["lag"], "size", to, 0.5).set_delay(0.45)
	else:                     # healed: the strip jumps ahead with the fill
		hb["lag"].size = to
	hb["ratio"] = ratio

func _place_head_bars() -> void:
	if overhead == null or not is_instance_valid(overhead) or lv.cam == null:
		return
	var vp := overhead.get_viewport_rect().size
	for e in b.enemies:
		var hb: Dictionary = head_bars.get(e["key"], {})
		if hb.is_empty():
			continue
		var box: Panel = hb["box"]
		var n = nodes.get(e["key"])
		var show: bool = e["hp"] > 0 and n != null and is_instance_valid(n) and n.visible
		var top := Vector3.ZERO
		if show:
			top = n.global_position + Vector3(0, n.height_m + 0.2, 0)
			show = not lv.cam.is_position_behind(top)
		box.visible = show
		if show:
			var p := lv.cam.unproject_position(top)
			p.x = clampf(p.x, box.size.x * 0.5 + 6.0, vp.x - box.size.x * 0.5 - 6.0)
			p.y = clampf(p.y, 10.0, vp.y - 10.0)   # the giant's head is off the top of the screen: pin it to the edge
			box.position = (p - Vector2(box.size.x * 0.5, box.size.y)).round()

func _point(mk: MeshInstance3D, u) -> void:
	if u == null:
		mk.visible = false
		mk.remove_meta("over")
	else:
		mk.visible = true
		mk.set_meta("over", u)

func _refresh() -> void:
	for p in b.party:
		var pb: Dictionary = pbars[p["key"]]
		_drain(pb["hp"], p["hp"])
		pb["hp_lbl"].text = "%s %d/%d" % [p["P"]["hp_label"], p["hp"], p["max_hp"]]
		create_tween().tween_property(pb["meter"], "value", p["meter"], 0.3)
		pb["meter"].tooltip_text = p["P"]["meter_label"]
		var down_chip := ["DOWNED  %d/3 passes · %d/3 fails" % [mini(3, p.get("saves", [0, 0])[0]), mini(3, p.get("saves", [0, 0])[1])], "Rolling death saves each turn (d20, 10+ passes). 3 passes = back up at 1 HP, nat 20 = up at half HP, 3 fails = dead for this fight. A Beezy, a Bowl or a teammate's Help Up brings them back now.", false]
		if p.get("dead", false):
			down_chip = ["DEAD", "Failed 3 death saves. Out for the rest of this fight (back up at 1 HP after).", false]
		_set_status(pb["st"], _status_chips(p) if p["hp"] > 0 else [down_chip])
		var fill: StyleBoxFlat = pb["meter"].get_theme_stylebox("fill")
		fill.bg_color = Color("#fff07a") if p["meter"] >= 100 else Color("#ffb13a")
		pb["card"].modulate = Color(1, 1, 1, 1) if p["hp"] > 0 else Color(0.6, 0.6, 0.6, 0.8)
	_heartbeat(b.result() == "" and b.party.any(func(p): return p["hp"] > 0 and float(p["hp"]) <= float(p["max_hp"]) * 0.25))
	for e in b.enemies:
		if not ebars.has(e["key"]):   # an add the summon event hasn't shown yet
			continue
		var eb: Dictionary = ebars[e["key"]]
		_drain(eb["hp"], e["hp"])
		eb["hp_lbl"].text = "HP %d/%d" % [maxi(0, e["hp"]), e["max_hp"]]
		if eb.get("brk") != null:
			eb["brk"].max_value = e["brk_max"]
			create_tween().tween_property(eb["brk"], "value", e["brk"], 0.3)
		_set_head_bar(e)
		var chips := _status_chips(e)
		var W: Dictionary = D.WEAKNESS.get(e.get("ai", ""), {})   # 11/26: weaknesses are shown, not guessed
		if W.has("resist"): chips.push_front(["RESISTS: %s" % D.DTYPE_NAME[W["resist"]], "Takes 30%% less from %s moves (%s)." % [D.DTYPE_NAME[W["resist"]], _who_type(W["resist"])], false])
		if W.has("weak"): chips.push_front(["WEAK: %s" % D.DTYPE_NAME[W["weak"]], "Takes 30%% more from %s moves (%s), and they fill the break bar faster." % [D.DTYPE_NAME[W["weak"]], _who_type(W["weak"])], true])
		if e.get("eat_pending", false): chips.push_front(["HOLDING A CHIPOTLE BOWL", "He's about to eat it and heal. Stun or charm him first and he drops it.", false])
		if e.get("sit_pending", false): chips.push_front(["GETTING READY TO SIT", "He sits on someone next turn. Stun or charm him first and he sits on his own foot.", false])
		if e.get("sale_pending", false): chips.push_front(["CLEARANCE SALE", "Next turn he hits everyone hard. Defend, block it, or stun/charm him first to cancel it.", false])
		if e.get("stampede_pending", false): chips.push_front(["CALLING A STAMPEDE", "Next turn every rat runs over the party. Defend, block it, or stun/charm him first to cancel it.", false])
		_set_status(eb["st"], chips)
		eb["col"].modulate = Color(1, 1, 1, 1) if e["hp"] > 0 else Color(1, 1, 1, 0.35)
	_timeline()

# ---- status chips: each status is its own word you can hover to see what it does
# who hits with a damage type ("lore" → "Xylo"), for the weakness chips
func _who_type(t: String) -> String:
	var who := []
	for p in b.party:
		if D.DTYPE.get(p["id"], "") == t:
			who.append(p["name"])
	return " / ".join(who) if not who.is_empty() else "nobody here"

func _status_chips(u: Dictionary) -> Array:   # [[label, description, good], ...]
	var out := []
	for k in u["st"]:
		if D.STATUS.has(k):
			var lab: String = D.STATUS[k]["label"]
			if k == "lore": lab = "LORE ×%d" % int(u["st"][k])
			out.append([lab, D.STATUS[k]["desc"], D.STATUS[k]["good"]])
	if u.get("defending", false): out.append(["DEFENDING", "Bracing. Takes half damage, but enemies usually go after them.", true])
	if u.get("tripping", false): out.append(["TRIPPING", "Moves can misfire (22%), but sometimes land a Tweak Crit for double damage.", false])
	if u["side"] == "party" and b.hype > 0: out.append(["HYPED ×%d" % b.hype, "The party's next %d attacks do +25%% damage and double break damage." % b.hype, true])
	if u["side"] == "party" and b.shi_discount and u["hp"] > 0: out.append(["TEAM-UP HALF PRICE", "\"on some type shi\": the next team-up costs half meter.", true])
	return out

func _status_row(size: int) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 0)
	row.set_meta("size", size)
	return row

func _set_status(row: HFlowContainer, chips: Array) -> void:
	var sig := str(chips)
	if row.get_meta("sig", "") == sig:
		return
	row.set_meta("sig", sig)
	for c in row.get_children():
		c.queue_free()
	for c in chips:
		var l: Label
		if row.get_meta("panel", false):
			l = _pl(c[0], row.get_meta("size"), GREEN if c[2] else PURPLE, 3)
		else:
			l = lv._label(c[0], Vector2.ZERO, row.get_meta("size"), GREEN if c[2] else PURPLE, 3)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.mouse_default_cursor_shape = Control.CURSOR_HELP
		var chip: Array = c
		l.mouse_entered.connect(func(): _show_status_tip(l, chip))
		l.mouse_exited.connect(func(): if status_tip: status_tip.visible = false)
		row.add_child(l)

var status_tip: PanelContainer

func _show_status_tip(over: Control, chip: Array) -> void:
	if not is_instance_valid(over):
		return
	if status_tip == null:
		status_tip = PanelContainer.new()
		status_tip.add_theme_stylebox_override("panel", _tip_box())
		status_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_tip.z_index = 20
		var tc := VBoxContainer.new()
		tc.add_theme_constant_override("separation", 2)
		status_tip.add_child(tc)
		tc.add_child(_pl("", 18, GOLD, 4))
		var d := _pl("", 15, Color.WHITE, 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(260, 0)
		tc.add_child(d)
		root.add_child(status_tip)
	var tc: VBoxContainer = status_tip.get_child(0)
	tc.get_child(0).text = chip[0]
	tc.get_child(0).add_theme_color_override("font_color", _ink(GREEN if chip[2] else PURPLE))
	tc.get_child(1).text = chip[1]
	status_tip.visible = true
	status_tip.reset_size()
	var vp := get_viewport().get_visible_rect().size
	var at := over.global_position + Vector2(0, -status_tip.size.y - 6)   # party (bottom left): above the word
	if over.global_position.x > vp.x * 0.5:   # enemies (right side): to the left, so it doesn't cover their name/bar
		at = Vector2(over.get_parent().global_position.x - status_tip.size.x - 12, over.global_position.y - status_tip.size.y * 0.5 + over.size.y * 0.5)
	if at.y < 8: at.y = over.global_position.y + over.size.y + 6
	status_tip.global_position = at.clamp(Vector2(8, 8), vp - status_tip.size - Vector2(8, 8))

func _portrait_tex(u: Dictionary) -> Texture2D:
	var n: String = u["id"] if u["side"] == "party" else u["E"].get("portrait", PORTRAIT.get(u["ai"], "goblin"))
	if u["side"] == "enemy" and u.get("disguise", "") != "":
		n = u["disguise"]
	return load("res://assets/portraits/%s.png" % n)

var _tl_shown := {}
var _tl_first := ""
func _timeline(tl := {}) -> void:
	for c in timeline.get_children():
		c.queue_free()
	var pv := b.preview_with(8, tl.get("bumps", {}), tl.get("skips", {})) if not tl.is_empty() else b.preview(8)
	# 11/26: when the turn moves on, the bar slides in (portraits fade in one after another, the new first one pops)
	var first_key: String = pv[0]["u"]["key"] if not pv.is_empty() else ""
	var slide := tl.is_empty() and first_key != _tl_first and not auto_play
	_tl_first = first_key
	for i in pv.size():
		var u: Dictionary = pv[i]["u"]
		var pc := PanelContainer.new()
		var sz := 54 if i == 0 else 42
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(UITheme.c("bg2", _th()), 0.75)
		sb.border_color = UITheme.c("edge", _th()) if u["side"] == "party" else RED
		if pv[i].get("moved", false): sb.border_color = Color("#ffd84a")   # changed by the hovered move
		sb.set_border_width_all(3 if i == 0 else 2)
		sb.set_corner_radius_all(6)
		pc.add_theme_stylebox_override("panel", sb)
		var tr := TextureRect.new()
		tr.texture = _portrait_tex(u)
		tr.custom_minimum_size = Vector2(sz, sz)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if pv[i]["skip"]:
			tr.modulate = Color(0.5, 0.5, 0.5, 0.7)
		pc.add_child(tr)
		pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		timeline.add_child(pc)
		if slide:
			pc.modulate.a = 0.0
			var tw := pc.create_tween()
			tw.tween_interval(0.03 * i)
			tw.tween_property(pc, "modulate:a", 1.0, 0.18)
			if i == 0:
				pc.pivot_offset = Vector2(30, 30)
				pc.scale = Vector2(1.25, 1.25)
				tw.parallel().tween_property(pc, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ================================================================== flow
func _intro() -> void:
	await lv.wait(0.9 * speed)
	for k in nodes:
		var u: Unit = nodes[k]
		u.global_position = spots[k]
		u.remove_meta("goal")
		u.set_view("front")
		u.sprite.flip_h = b.enemies.any(func(e): return e["key"] == k)
		u.set_meta("in_fight", true)
		if not u.sprite.flip_h:   # our side: the 3D trio stands facing the enemies, 3/4 to the camera (Asar 11/25)
			u.set_meta("fight_face", (right - fwd * 0.7).normalized())
	lv.focus_override = center + fwd * 0.3
	lv.cam_height = 0.36
	var widest := maxi(b.party.size(), b.enemies.size())
	if key == "giant":
		lv.zoom = 12.5
		lv.cam_look_h = 3.0
		lv.focus_override = center + right * 0.6 + fwd * 0.3
	elif key == "dulbers":
		lv.zoom = 9.5
		lv.cam_look_h = 1.6
	else:
		lv.zoom = 6.8 + widest * 0.85
		lv.cam_look_h = 1.15
	var home_focus = lv.focus_override
	var ais: Array = b.enemies.map(func(e): return e.get("ai", ""))
	if ("rat" in ais or "rat_king" in ais) and sounds.has("tiger"):
		sfx("tiger", 1.0)   # (sfx pack) a tiny rat, a full tiger roar
	elif "goblin" in ais and key != "goblins" and sounds.has("gob_laugh"):
		sfx("gob_laugh", 1.0)   # (the throne fight already got its laugh in village.gd)
	else:
		sfx("roar", 0.8)
	lv.shake = 0.35
	if cinematic:
		var boss: Unit = nodes[b.enemies[0]["key"]]
		var keep := lv.zoom
		lv.focus_override = boss.global_position
		lv.zoom = keep * 0.55
		await _banner(fdef["title"], RED, 2.0)
		lv.focus_override = home_focus
		lv.zoom = keep
	else:
		await _banner(fdef["title"], Color("#ffcf4a"), 1.2)
	_say("Fight! %s" % ("(Story fight — no running.)" if fdef.get("story", false) else "(You can Talk or Run.)"))

func _loop() -> String:
	var guard := 0
	while b.result() == "" and guard < 500:
		guard += 1
		_refresh()
		var r: Dictionary = b.next_actor()
		var u: Dictionary = r["u"]
		await _play(r["events"])
		music.watch(b)
		if b.result() != "":
			break
		if r["skip"]:
			await lv.wait(0.25 * speed)
			continue
		_refresh()
		if u["side"] == "party":
			await _party_turn(u)
		else:
			await _enemy_turn(u)
	_point(actor_marker, null)
	_point(target_marker, null)
	return b.result() if b.result() != "" else "win"

# ------------------------------------------------------------------ party turn
func _party_turn(u: Dictionary) -> void:
	var n: Unit = nodes[u["key"]]
	_point(actor_marker, n)
	lv.hop(n, 0.2)
	var a := await _choose(u)
	_point(actor_marker, null)
	_point(target_marker, null)
	var o := {}
	match a["type"]:
		"move":
			var move: Dictionary = u["moves"][a["slot"]]
			if move["kind"] == "crashout":
				var r := await _roll_dice(u, 1)
				if r[0] == 6 and not b.used67 and await _ask_67():
					r[0] = 7
				o["roll"] = r[0]
			elif move["kind"] == "fullcrash":
				var rolls := await _roll_dice(u, 2)
				o["rolls"] = rolls
				if rolls[0] == 6 and rolls[1] == 6 and not b.used67:
					o["accept67"] = await _ask_67()
			_lean(nodes[u["key"]])
			await _windup(u, move, a.get("target", {}))
			var shi: bool = u["id"] == "lykor" and move["kind"] == "buff"   # "on some type shi"
			var mog: bool = move.get("fx", "") == "mog" or move["kind"] == "mogsupreme" or shi
			if mog:
				await _mog_cam(u, move, a["slot"] == "ult", shi)   # Lykor's close-up (Ebain's note; Asar added the shi one)
			if move.get("timed", false) and not a.get("target", {}).is_empty():
				o["timing"] = await _timed(nodes[a["target"]["key"]], "attack")
			if a["slot"] == "ult" and not mog:
				await _ult_cam(u, move)
		"combo":
			await _combo_cam(a["combo"])
			o["timing"] = await _timed(nodes[a["target"]["key"]], "attack")
		"flee":
			o["roll"] = randi_range(1, 6)
	var evs := b.party_act(u, a, o)
	await _play(evs)
	_unlean()
	await _recover(u)

func _choose(u: Dictionary) -> Dictionary:
	if auto_play:
		await lv.wait(0.4)
		return _auto_action(u)
	while true:
		var opts := []
		var mv: Dictionary = u["moves"]
		opts.append({ "text": "Attack: " + mv["main"]["name"], "desc": mv["main"]["desc"], "v": "main", "tl": _tl_for(u, mv["main"]) })
		for slot in ["special", "bonus", "extra"]:
			if not mv.has(slot):
				continue
			var cd: int = u["cds"].get(slot, 0)
			var label: String = { "special": "Special", "bonus": "Bonus", "extra": "New" }[slot]
			opts.append({ "text": "%s: %s%s" % [label, mv[slot]["name"], "  (ready in %d)" % cd if cd > 0 else ""], "desc": mv[slot]["desc"], "v": slot, "off": cd > 0, "tl": _tl_for(u, mv[slot]) })
		if u["meter"] >= 100:
			opts.append({ "text": "ULTIMATE: " + mv["ult"]["name"], "desc": mv["ult"]["desc"], "v": "ult", "hot": true, "tl": _tl_for(u, mv["ult"]) })
		else:
			opts.append({ "text": "Ultimate: %s  (%d%%)" % [mv["ult"]["name"], u["meter"]], "desc": "Fill %s to 100 by dealing damage, landing timed hits and taking hits. " % u["P"]["meter_label"] + mv["ult"]["desc"], "v": "ult", "off": true })
		var combos := b.combos_for(u)
		if not combos.is_empty():
			opts.append({ "text": "Team-Up!", "desc": "Spend meter with a friend for a combo move.", "v": "combo", "hot": true })
		var nb := b.item_count(u["id"], "beer")
		var nw := b.item_count(u["id"], "bowl")
		var ntot := 0
		for k in D.FIGHT_ITEMS:
			ntot += b.item_count(u["id"], k)
		var nother := ntot - nb - nw
		opts.append({ "text": "Items  (Beezy %d · Bowl %d%s)" % [nb, nw, " · +%d more" % nother if nother > 0 else ""], "desc": "Heal, revive, cleanse or power up someone with %s's own items." % u["name"], "v": "item", "off": ntot == 0 })
		var dn := b.downed()
		if not dn.is_empty():   # 11/26: pick a Downed teammate back up (costs your turn)
			opts.append({ "text": "Help Up", "desc": "Spend your turn pulling a Downed teammate back up (%d%% of their HP)." % int(D.BALANCE["help_up"] * 100), "v": "help", "hot": true })
		opts.append({ "text": "Defend", "desc": "Half damage, enemies aim at you, cooldowns tick faster, +meter.", "v": "defend" })
		if TALK_IN_FIGHTS and not b.talk_options(u).is_empty():
			opts.append({ "text": "Talk", "desc": "Try talking your way through this.", "v": "talk" })
		if b.can_flee():
			opts.append({ "text": "Run", "desc": "Roll a d6. 4+ and you get away (no XP).", "v": "flee" })
		var pick = await _menu("%s's turn" % u["name"], opts, false)
		var act := {}
		match pick:
			"main", "special", "bonus", "extra", "ult":
				var move: Dictionary = mv[pick]
				if move["kind"] in ["buff", "healall"] or (move["kind"] == "mogsupreme"):
					act = { "type": "move", "slot": pick, "target": b.alive(b.enemies)[0] }
				elif move["kind"] == "healone":
					var t = await _pick_target(_livable(), true)
					if t != null: act = { "type": "move", "slot": pick, "target": t }
				else:
					var t = await _pick_target(b.alive(b.enemies), false, func(x): return _est_text(u, move, x))
					if t != null: act = { "type": "move", "slot": pick, "target": t }
			"combo":
				var copts := []
				for c in combos:
					copts.append({ "text": "%s (%d meter each)" % [c["name"], b.combo_cost(c)], "desc": c["desc"], "v": c })
				var c = await _menu("Team-Up", copts, true)
				if c != null:
					var t = b.alive(b.enemies)[0] if c.get("aoe", false) else await _pick_target(b.alive(b.enemies), false, func(x): return _est_text(u, c.merged({ "kind": "combo" }), x))
					if t != null: act = { "type": "combo", "combo": c, "target": t }
			"item":
				var iopts := []
				for k in D.FIGHT_ITEMS:
					if b.item_count(u["id"], k) > 0:
						iopts.append({ "text": "%s ×%d" % [D.ITEMS[k]["name"], b.item_count(u["id"], k)], "desc": D.ITEMS[k]["desc"], "v": k })
				var it = await _menu("Items", iopts, true)
				if it == "joint":   # the whole party, no target
					act = { "type": "item", "item": it, "target": u }
				elif it != null:
					var t = await _pick_target(_livable(), true)
					if t != null: act = { "type": "item", "item": it, "target": t }
			"help":
				var t = await _pick_target(b.downed(), true)
				if t != null: act = { "type": "help", "target": t }
			"defend":
				act = { "type": "defend" }
			"talk":
				var topts := []
				for tk in b.talk_options(u):
					topts.append({ "text": tk["text"] + ("" if tk["ok"] else "  (need a %s)" % D.ITEMS[tk["need"]]["name"]), "desc": "", "v": tk["id"], "off": not tk["ok"] })
				var tid = await _menu("Talk", topts, true)
				if tid != null: act = { "type": "talk", "talk": tid }
			"flee":
				act = { "type": "flee" }
		if not act.is_empty():
			sfx("select")
			return act
	return {}

# Damage preview line for the target picker (11/26): "~18-30 damage · WEAK SPOT · +12 break (40 to BREAK)"
func _est_text(u: Dictionary, move: Dictionary, t: Dictionary) -> String:
	var es := b.estimate(u, move, t)
	if not es.get("ok", false):
		return "Damage: " + (", ".join(es["notes"]) if not es.get("notes", []).is_empty() else "—")
	var bits := ["~%d-%d damage" % [es["lo"], es["hi"]] if es["lo"] != es["hi"] else "~%d damage" % es["lo"]]
	if es["kills"]: bits.append("FINISHES THEM")
	if es["weak"] == "weak": bits.append("WEAK SPOT")
	elif es["weak"] == "resist": bits.append("they RESIST this")
	bits += es["notes"]
	if es["brk"] > 0:
		bits.append("+%d break%s" % [es["brk"], " → BREAK!" if es["brk"] >= es["brk_left"] else " (%d to BREAK)" % es["brk_left"]])
	return " · ".join(bits)

# Turn-order preview data for a move (11/26): who gets pushed back / skipped if you use it (on the likely target)
func _tl_for(u: Dictionary, move: Dictionary) -> Dictionary:
	var foes := b.alive(b.enemies)
	if foes.is_empty():
		return {}
	var t: Dictionary = foes[0]
	for f in foes:
		if f.get("boss", false): t = f
	var bumps := {}
	var skips := {}
	if move.has("delay"):
		bumps[t["key"]] = b.delay(t) * move["delay"]
	if move.get("kind", "") == "chudout" and b.can_cc(t):
		skips[t["key"]] = 1
	var es := b.estimate(u, move, t)
	if es.get("ok", false) and es["brk"] > 0 and es["brk"] >= es["brk_left"]:
		skips[t["key"]] = int(skips.get(t["key"], 0)) + 1
	if bumps.is_empty() and skips.is_empty():
		return {}
	return { "bumps": bumps, "skips": skips }

# ---- battle log (11/26): every line said this fight, L or a click on the log toggles the history
var _log_lines: Array = []
var _log_panel: PanelContainer = null
func _toggle_log() -> void:
	if _log_panel != null:
		_log_panel.queue_free()
		_log_panel = null
		return
	_log_panel = PanelContainer.new()
	_log_panel.add_theme_stylebox_override("panel", UITheme.panel(0.94, _th()))
	_log_panel.anchor_left = 0.5; _log_panel.anchor_right = 0.5
	_log_panel.offset_left = -480; _log_panel.offset_right = 480; _log_panel.offset_top = 110; _log_panel.offset_bottom = 470
	_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_panel.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.add_child(_pl("BATTLE LOG  (L to close)", 16, UITheme.c("accent", _th()), 3))
	for line in _log_lines:
		var l := _pl(line, 15, Color.WHITE, 3)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(900, 0)
		v.add_child(l)
	root.add_child(_log_panel)
	await get_tree().process_frame
	if is_instance_valid(sc): sc.scroll_vertical = int(sc.get_v_scroll_bar().max_value)

# ---- impact (11/26): a tiny freeze on big hits, a camera punch-in on big moments
func _hitstop(secs := 0.06) -> void:
	if auto_play: return
	Engine.time_scale = 0.05
	await get_tree().create_timer(secs, true, false, true).timeout
	Engine.time_scale = 1.0

func _punch(n: Unit, amt := 0.78, secs := 0.45) -> void:
	if n == null or auto_play: return
	var keep := lv.zoom
	var kf = lv.focus_override
	lv.focus_override = n.global_position.lerp(center, 0.4)
	lv.zoom = keep * amt
	await lv.wait(secs)
	lv.zoom = keep
	lv.focus_override = kf

func _squash(n: Unit) -> void:   # bosses have no hurt art: a quick squash-and-stretch instead
	if n == null or n.sprite == null: return
	var s0: Vector3 = n.sprite.scale
	var tw := create_tween()
	tw.tween_property(n.sprite, "scale", Vector3(s0.x * 1.1, s0.y * 0.88, s0.z), 0.06)
	tw.tween_property(n.sprite, "scale", s0, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---- 11/26 AAA pass helpers
# Layered hit sound by the attacker's damage type, + a heavy layer on big hits and a bright one on PERFECT
func _impact(ev: Dictionary) -> void:
	var snd: String = ev.get("sound", "hit")
	var t: String = D.DTYPE.get(ev.get("by", ""), "physical")
	var key := "cmb_hit_phys_%d" % randi_range(1, 3)
	if t == "aura": key = "cmb_hit_aura_%d" % randi_range(1, 2)
	elif t == "lore": key = "cmb_hit_lore_%d" % randi_range(1, 2)
	sfx(key)
	if not snd in ["hit", "slap", "blast", "lore", "bonk", "mog"]:
		sfx(snd)   # keep special sounds (fire, roar, the explosion) on top
	if ev["amt"] >= 30 or ev.get("shake", false): sfx("cmb_hit_big")
	if ev.get("label", "") == "PERFECT!": sfx("cmb_perfect")

# A burst of particles on a hit: dust (Physical), sparkles (Aura), runes (Lore), sparks (block), shards (break)
func _burst(n: Unit, kind: String, big := false) -> void:
	if n == null or auto_play or lv.shots_mode: return
	var col: Color = { "physical": Color("#d9b38c"), "aura": Color("#ff8ad8"), "lore": Color("#6ff5d0"), "block": Color("#bfe3ff"), "break": Color("#ffc23a") }.get(kind, Color("#ffe9c4"))
	var ps := CPUParticles3D.new()
	ps.one_shot = true
	ps.explosiveness = 0.95
	ps.amount = (36 if big else 18) * (2 if kind == "break" else 1)
	ps.lifetime = 0.7 if kind != "lore" else 1.0
	var qm := QuadMesh.new()
	qm.size = Vector2(0.09, 0.09) * (1.6 if kind == "break" else 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	qm.material = mat
	ps.mesh = qm
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	ps.emission_sphere_radius = 0.25
	ps.direction = Vector3(0, 1, 0)
	ps.spread = 70.0 if kind != "physical" else 50.0
	ps.initial_velocity_min = 2.0 if kind != "lore" else 0.6
	ps.initial_velocity_max = (5.5 if big else 3.5) if kind != "lore" else 1.6
	ps.gravity = Vector3(0, -9.0, 0) if kind in ["physical", "break", "block"] else Vector3(0, 0.6, 0)
	ps.scale_amount_min = 0.6
	ps.scale_amount_max = 1.4
	var grad := Gradient.new()
	grad.set_color(0, col)
	grad.set_color(1, Color(col.r, col.g, col.b, 0.0))
	ps.color_ramp = grad
	lv.add_child(ps)
	ps.global_position = n.global_position + Vector3(0, n.height_m * 0.55, 0)
	ps.emitting = true
	get_tree().create_timer(ps.lifetime + 0.3).timeout.connect(ps.queue_free)

# BROKEN: cracked-glass lines across the screen for a moment
func _crack_screen() -> void:
	if auto_play or lv.shots_mode: return
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(c)
	var vp := get_viewport().get_visible_rect().size
	var ctr := vp * Vector2(0.62, 0.42)
	for i in 9:
		var l := Line2D.new()
		l.width = randf_range(1.5, 3.5)
		l.default_color = Color(1, 1, 1, 0.85)
		var pt := ctr
		var ang := TAU * i / 9.0 + randf_range(-0.2, 0.2)
		l.add_point(pt)
		for k in 4:
			ang += randf_range(-0.35, 0.35)
			pt += Vector2(cos(ang), sin(ang)) * randf_range(60, 140)
			l.add_point(pt)
		c.add_child(l)
	var t := c.create_tween()
	t.tween_interval(0.35)
	t.tween_property(c, "modulate:a", 0.0, 0.5)
	t.tween_callback(c.queue_free)

# The camera leans a little toward whoever is acting, then settles back
var _lean_base = null
var _leaning := false
func _lean(n: Unit) -> void:
	if n == null or auto_play or lv.shots_mode: return
	if not _leaning:
		_lean_base = lv.focus_override
		_leaning = true
	lv.focus_override = center.lerp(n.global_position, 0.22)

func _unlean() -> void:
	if not _leaning: return
	_leaning = false
	lv.focus_override = _lean_base

# The grade letter slams onto the results panel
func _slam_in(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(3.2, 3.2)
	c.modulate.a = 0.0
	var t := create_tween()
	t.tween_interval(0.35)
	t.tween_callback(func(): c.pivot_offset = c.size / 2.0)
	t.tween_property(c, "modulate:a", 1.0, 0.06)
	t.parallel().tween_property(c, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		sfx("cmb_grade_slam")
		lv.shake = 0.5)

# teammates an item/heal can still reach (the dead are out for this fight)
func _livable() -> Array:
	return b.party.filter(func(p): return not p.get("dead", false))

func _auto_action(u: Dictionary) -> Dictionary:
	var foes := b.alive(b.enemies)
	var t: Dictionary = foes[0]
	for f in foes:
		if f["hp"] < t["hp"]: t = f
	for p in b.party:
		if p["hp"] < p["max_hp"] * 0.3 and not p.get("dead", false):
			if b.item_count(u["id"], "bowl") > 0: return { "type": "item", "item": "bowl", "target": p }
			if b.item_count(u["id"], "beer") > 0: return { "type": "item", "item": "beer", "target": p }
	var dn := b.downed()
	if not dn.is_empty(): return { "type": "help", "target": dn[0] }
	if u["meter"] >= 100: return { "type": "move", "slot": "ult", "target": t }
	var combos := b.combos_for(u)
	if not combos.is_empty(): return { "type": "combo", "combo": combos.back(), "target": t }
	if u["cds"]["special"] == 0 and u["moves"]["special"]["kind"] != "healone": return { "type": "move", "slot": "special", "target": t }
	if u["cds"]["bonus"] == 0:
		if u["moves"]["bonus"]["kind"] == "healone":   # Mattias (ally): heals go on the most hurt teammate
			var low := b.alive(b.party)
			low.sort_custom(func(a, c): return float(a["hp"]) / a["max_hp"] < float(c["hp"]) / c["max_hp"])
			if low[0]["hp"] < low[0]["max_hp"] * 0.7:
				return { "type": "move", "slot": "bonus", "target": low[0] }
		else:
			return { "type": "move", "slot": "bonus", "target": t }
	return { "type": "move", "slot": "main", "target": t }

# Step toward the target and strike a pose
func _windup(u: Dictionary, move: Dictionary, t: Dictionary) -> void:
	var n: Unit = nodes[u["key"]]
	var melee: bool = move.get("fx", "") == "slap" or move["kind"] in ["crashout", "fullcrash", "chudout"]
	var dest: Vector3 = spots[u["key"]] + right * 0.8
	if melee and not t.is_empty():
		dest = nodes[t["key"]].global_position - right * (1.3 + (1.5 if key == "giant" else 0.0))
	n.set_meta("attacking", true)   # 3D trio: 2D art for the whole move (Unit._sync_body)
	var tw := create_tween()
	tw.tween_property(n, "global_position", dest, 0.22 * speed + (0.12 if melee else 0.0))
	await tw.finished
	if move.has("pose"):
		var tex := _tex(move["pose"])
		if tex:
			n.set_pose(tex, n.base_h * move.get("ph", 1.0))
			n.sprite.flip_h = move.get("flip", false)
	if move["kind"] == "chudout":
		lv.hop(n, 1.2)
	await lv.wait(0.12)

func _recover(u: Dictionary) -> void:
	await lv.wait(0.25 * speed)
	var n: Unit = nodes[u["key"]]
	if u["hp"] > 0:
		_stand(n)
	var tw := create_tween()
	tw.tween_property(n, "global_position", spots[u["key"]], 0.25 * speed)
	await tw.finished
	n.remove_meta("attacking")

func _stand(n: Unit) -> void:
	if n.views.get("front") != saved_pose[n][0].get("front"):
		n.views = saved_pose[n][0].duplicate()
		n.height_m = saved_pose[n][1]
		n.view = ""
		n.set_view("front")
	n.sprite.flip_h = b.enemies.any(func(e): return nodes[e["key"]] == n)

func _ult_cam(u: Dictionary, move: Dictionary) -> void:
	var n: Unit = nodes[u["key"]]
	var keep := lv.zoom
	var keep_f = lv.focus_override
	lv.focus_override = n.global_position
	lv.zoom = keep * 0.5
	flash(0.5, Color(1, 0.9, 0.5))
	sfx("ready", 0.8)
	await _banner(move["name"], Color("#ffdf4a"), 1.0 if cinematic else 0.7)
	lv.focus_override = keep_f
	lv.zoom = keep

# Push the camera right up to Lykor's face for about a second, then back to the fight.
var mog_cam_test := false   # set by the --shots tour: takes a screenshot at the close-up
var shi_cam_test := false
var throw_test := false
func _mog_cam(u: Dictionary, move: Dictionary, ult: bool, shi := false) -> void:
	var n: Unit = nodes[u["key"]]
	var hidden := []   # everyone else steps out of the shot so nobody (Skorn) blocks Lykor
	for k in nodes:
		var o: Unit = nodes[k]
		if is_instance_valid(o) and o != n and o.visible:
			o.visible = false
			hidden.append(o)
	var keep := { "zoom": lv.zoom, "cam_height": lv.cam_height, "cam_look_h": lv.cam_look_h }
	var keep_f = lv.focus_override
	var face_h: float = n.height_m * 0.86
	var close := 1.35
	lv.focus_override = n.global_position
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(lv, "zoom", close, 0.3)
	tw.tween_property(lv, "cam_height", face_h / close, 0.3)
	tw.tween_property(lv, "cam_look_h", face_h, 0.3)
	for box in [party_box, enemy_box, menu_panel, overhead]:
		if box: tw.tween_property(box, "modulate:a", 0.0, 0.2)
	if shi:
		sounds["shi"].pitch_scale = 1.0
		sounds["shi"].play()
	else:
		sfx("sparkle", 0.7)
	await tw.finished
	flash(0.25, Color(1, 1, 1))
	if not shi:
		sfx("mog", 1.0)
	_banner(move["name"] if ult or shi else "*chiseled jawline*", Color("#ffdf4a"), 0.9 if ult or shi else 0.7)
	if mog_cam_test or (shi and shi_cam_test):
		await lv.wait(0.35)
		await lv.shot("fight_%s_%s_cam" % [key, "shi" if shi else "mog"])
		if shi: shi_cam_test = false
		else: mog_cam_test = false   # one picture per fight
	var hold := 1.0 if cinematic or ult else 0.75
	if shi: hold = maxf(hold, sounds["shi"].stream.get_length() - 0.3)   # let the line finish while we're close
	await lv.wait(hold * speed)
	lv.focus_override = keep_f
	var back := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for k in keep:
		back.tween_property(lv, k, keep[k], 0.3)
	for box in [party_box, enemy_box, menu_panel, overhead]:
		if box: back.tween_property(box, "modulate:a", 1.0, 0.25)
	await back.finished
	for o in hidden:
		if is_instance_valid(o): o.visible = true

func _combo_cam(c: Dictionary) -> void:
	for id in c["who"]:
		var p := b.member(id)
		lv.hop(nodes[p["key"]], 0.5)
	flash(0.4, Color(1, 0.85, 0.4))
	sfx("ready", 1.2)
	_say(c["desc"])
	await _banner("TEAM-UP: " + c["name"], Color("#ffdf4a"), 1.0)

# ------------------------------------------------------------------ enemy turn
func _enemy_turn(e: Dictionary) -> void:
	var n: Unit = nodes[e["key"]]
	_point(actor_marker, n)
	await _play(b.roll_chaos())
	if b.result() != "":
		return
	# 11/26: phase-2 bosses get a free (lighter) second action; Dulbers' shapeshifts don't use one up
	var acts := b.enemy_actions(e)
	var done := 0
	var guard := 0
	while done < acts and guard < 6 and b.result() == "" and e["hp"] > 0:
		guard += 1
		if done > 0 and not b.alive(b.party).is_empty():
			_float(n, "BONUS ACTION", Color("#ff9a3a"), 0.8, 0.5)
			await lv.wait(0.35 * speed)
		b.begin_action(e, done)
		var it := b.enemy_plan(e)
		await _enemy_act(e, it)
		if not it.get("free", false):
			done += 1
	_point(actor_marker, null)

func _enemy_act(e: Dictionary, it: Dictionary) -> void:
	var n: Unit = nodes[e["key"]]
	_lean(n)
	var block := ""
	if it["kind"] == "hit":
		_say(it["text"])
		var tgt: Dictionary = it["targets"][0]
		var tn: Unit = nodes[tgt["key"]]
		var aoe: bool = it.get("aoe", false)
		var melee: bool = not aoe and key != "giant"
		var home: Vector3 = spots[e["key"]]
		if melee:
			var tw := create_tween()
			tw.tween_property(n, "global_position", tn.global_position + right * 1.3, 0.3 * speed)
			await tw.finished
		else:
			lv.hop(n, 0.6 if key == "giant" else 0.35)
		if it.get("tex", "") != "":
			var tex := _tex(it["tex"])
			if tex: n.set_pose(tex, e["E"]["h"] * 0.78)
		if it.get("big", false):   # the telegraphed big hit landing (Clearance Sale, stampede)
			lv.shake = 0.8
			flash(0.35, Color(1, 0.5, 0.3))
		block = await _timed(tn if not aoe else nodes[b.alive(b.party)[0]["key"]], "block")
		await _play(b.enemy_resolve(e, it, block))
		await lv.wait(0.15)
		var tw2 := create_tween()
		tw2.tween_property(n, "global_position", home, 0.25 * speed)
		await tw2.finished
	else:
		lv.hop(n, 0.3)
		await _play(b.enemy_resolve(e, it, ""))
	_unlean()

# ================================================================== events
func _play(evs: Array) -> void:
	for ev in evs:
		await _event(ev)
		_refresh()

func _node(u) -> Unit:
	if u is Dictionary and u.has("key") and nodes.has(u["key"]):
		return nodes[u["key"]]
	return null

func _event(ev: Dictionary) -> void:
	var n := _node(ev.get("u"))
	var q: bool = ev.get("quick", false)
	match ev["t"]:
		"say":
			_say(ev["text"])
			if ev.has("sound"): sfx(ev["sound"])
			await lv.wait(ev.get("ms", 1100) / 1000.0 * speed)
		"dmg":
			if ev["text"] != "": _say(ev["text"])
			_impact(ev)
			_burst(n, D.DTYPE.get(ev.get("by", ""), ""), ev["amt"] >= 30 or ev.get("label", "") == "PERFECT!")
			lv.shake = maxf(lv.shake, clampf(ev["amt"] / 90.0, 0.06, 0.55))
			if str(ev["u"].get("ai", "")).begins_with("rat"):
				sfx("squeak" if randf() < 0.5 else "squeak2", randf_range(0.95, 1.25))
			flash_unit(n, Color(2.5, 2.5, 2.5), 0.12)
			_kick(n)
			var perfect: bool = ev.get("label", "") == "PERFECT!"
			_float(n, "-%d" % ev["amt"], Color("#ffe14a") if perfect else (Color("#ffd27a") if not q else Color("#ffe8b0")), 1.35 if perfect else (1.0 if not q else 0.8))
			if ev["u"].get("boss", false): _squash(n)
			if perfect or ev["amt"] >= 30 or ev.get("shake", false): _hitstop(0.07 if ev["amt"] >= 30 else 0.05)
			if ev.get("label", "") != "":
				_float(n, ev["label"], GREEN if ev["label"] == "PERFECT!" else Color.WHITE, 0.8, 0.6)
			if ev.get("weak", "") == "weak":
				_float(n, "WEAK SPOT!", Color("#ffc23a"), 0.8, 0.45)
				sfx("cmb_weak")
				flash(0.12, Color(1, 0.85, 0.3))
			elif ev.get("weak", "") == "resist": _float(n, "RESISTED", Color(0.75, 0.75, 0.8), 0.7, 0.45)
			if ev.get("shake", false): lv.shake = 0.5
			await lv.wait((0.22 if q else 0.65) * speed)
		"hurt":
			var blk0: String = ev.get("block", "")
			if blk0 == "perfect":
				sfx("cmb_block_perfect")
				_burst(n, "block", true)
			elif blk0 == "good":
				sfx("cmb_block")
				_burst(n, "block", false)
			else:
				sfx("cmb_hit_phys_%d" % randi_range(1, 3), 0.85)
				if ev["amt"] >= 30: sfx("cmb_hit_big", 0.9)
				_burst(n, "physical", ev["amt"] >= 30)
			lv.shake = maxf(lv.shake, clampf(ev["amt"] / 70.0, 0.08, 0.6) * (0.4 if blk0 == "perfect" else 1.0))
			flash_unit(n, Color(2.2, 0.6, 0.6), 0.18)
			_kick(n, -1.0)
			_float(n, "-%d" % ev["amt"], RED)
			var blk: String = ev.get("block", "")
			if blk == "perfect": _float(n, "PERFECT BLOCK!", GREEN, 0.75, 0.6)
			elif blk == "good": _float(n, "BLOCKED", Color.WHITE, 0.75, 0.6)
			var hurt_tex := _tex("%s_hurt" % ev["u"].get("id", "")) if ev["u"]["side"] == "party" else null
			if hurt_tex and ev["hp"] > 0:
				n.set_pose(hurt_tex, n.base_h * 0.9)
				get_tree().create_timer(0.5).timeout.connect(_unhurt.bind(n, ev["u"]))
			await lv.wait((0.25 if q else 0.6) * speed)
		"self_hit":
			_say(ev["text"])
			sfx("hit", 0.7)
			flash_unit(n, Color(2.2, 0.6, 0.6), 0.2)
			_float(n, "-%d" % ev["amt"], RED)
			await lv.wait(1.0 * speed)
		"heal":
			if ev.get("text", "") != "": _say(ev["text"])
			sfx(ev.get("sound", "heal"))
			flash_unit(n, Color(0.8, 2.0, 0.9), 0.25)
			_float(n, "+%d" % ev["amt"], GREEN)
			await lv.wait((0.25 if q else 0.8) * speed)
		"status":
			if not ev.get("quiet", false): _say(ev["text"])
			var S: Dictionary = D.STATUS.get(ev["name"], { "label": ev["name"].to_upper(), "good": false })
			var bad_for_us: bool = (ev["u"]["side"] == "party") != S["good"]
			_float(n, S["label"], RED if bad_for_us and ev["u"]["side"] == "party" else (PURPLE if not S["good"] else Color("#ff9a5a")), 0.8, 0.4)
			sfx("sparkle", 0.7)
			await lv.wait((0.4 if ev.get("quiet", false) else 1.0) * speed)
		"down":
			sfx("sit", 1.4)
			lv.knock(n, 80.0, 0.35)
			flash_unit(n, Color(0.6, 0.6, 0.6), 99.0)
			if ev.get("fake", false):
				await lv.wait(0.8)
			else:
				_say("%s is down!" % ev["u"]["name"])
				await lv.wait(0.6 * speed)
		"revive":
			lv.unknock(n)
			_restore_tint(ev["u"])
			_stand(n)
			_say(ev["text"])
			sfx("cmb_revive")
			_burst(n, "aura", true)
			lv.hop(n, 0.4)
			await lv.wait(1.0 * speed)
		"ko":   # 11/26: Downed, not out (death saves)
			sfx("cmb_downed")
			lv.knock(n, -80.0, 0.35)
			flash_unit(n, Color(0.55, 0.55, 0.6), 99.0)
			_say("%s is DOWN! (Death saves start on their turn.)" % ev["u"]["name"])
			await lv.wait(0.9 * speed)
		"save":
			_say("%s rolls a death save… (d20, 10+ passes)" % ev["u"]["name"])
			await _show_dice([ev["roll"]], 20)
			if ev["roll"] == 20: _punch(n, 0.75, 0.6)
			_say(ev["text"])
			_float(n, "PASS" if ev["roll"] >= 10 else ("NAT 1" if ev["roll"] == 1 else "FAIL"), GREEN if ev["roll"] >= 10 else RED, 0.9, 0.5)
			await lv.wait(0.9 * speed)
		"broken":   # break bar emptied (11/26)
			_punch(n, 0.7, 0.6)
			sfx("cmb_break")
			_crack_screen()
			_burst(n, "break", true)
			lv.shake = 0.6
			flash(0.4, Color(1, 0.85, 0.3))
			flash_unit(n, Color(1.8, 1.5, 0.6), 0.5)
			_say(ev["text"])
			await _banner("BROKEN!", Color("#ffc23a"), 1.1)
		"save_fail":
			_say(ev["text"])
			_float(n, "FAILED SAVE", RED, 0.8, 0.5)
			sfx("hit", 0.6)
			await lv.wait(0.8 * speed)
		"dead":
			sfx("low", 0.6)
			flash_unit(n, Color(0.3, 0.3, 0.35), 99.0)
			_float(n, "DEAD", RED, 1.1, 0.6)
			_say(ev["text"])
			await lv.wait(1.4 * speed)
		"summon":
			_say(ev["text"])
			if sounds.has("gob_laugh"): sfx("gob_laugh", 1.1)
			for j in ev["us"].size():
				_add_enemy(ev["us"][j], j)
			await lv.wait(1.4 * speed)
		"meter_full":
			sfx("cmb_meter_full")
			if pbars.has(ev["u"]["key"]):   # the meter bar flashes
				var mb: ProgressBar = pbars[ev["u"]["key"]]["meter"]
				var mt := create_tween()
				mt.tween_property(mb, "modulate", Color(2.2, 2.2, 1.4), 0.08)
				mt.tween_property(mb, "modulate", Color.WHITE, 0.4)
			_float(n, "ULT READY!", Color("#fff07a"), 0.9, 0.7)
			if ev.has("text"): _say(ev["text"])
			await lv.wait(0.35 * speed)
		"bark":
			var who: String = ev["u"].get("id", ev["u"].get("ai", ""))
			lv.char_label(n, "\"%s\"" % ev["line"], 2.2, n.height_m + 0.55, Color("#fff4c9"))
			if lv.dialogue.tts_on:
				lv.dialogue._speak(who, ev["line"], false)
			await lv.wait(0.5 * speed)
		"misfire":
			var tw_tex := _tex("%s_tweaking" % ev["u"]["id"])
			if tw_tex: n.set_pose(tw_tex, n.base_h)
			_say(ev["text"])
			sfx("miss")
			await lv.wait(ev.get("ms", 1500) / 1000.0 * speed)
		"float":
			_float(n, ev["text"], Color(ev.get("color", "#ffffff")), 0.9)
			if ev.has("sound"): sfx(ev["sound"])
			await lv.wait(0.4)
		"throw_thing":
			await _throw(n, _node(ev["target"]), ev["thing"])
		"six_seven":
			Game.achieve("six_seven")
			flash(0.7, Color(1, 0.95, 0.6))
			sfx("crit", 0.67)
			for p in b.alive(b.party):
				lv.hop(nodes[p["key"]], 0.7)
			await _banner("6 - 7", Color("#ffdf4a"), 1.4)
			for p in b.alive(b.party):
				lv.hop(nodes[p["key"]], 0.7)
		"hype":
			_say(ev["text"])
			if ev["u"].get("id", "") != "lykor": sfx("roar", 1.4)   # Lykor's own voice line already played in the close-up
			for p in b.alive(b.party):
				_float(nodes[p["key"]], "HYPED", GOLD, 0.8, 0.3)
				flash_unit(nodes[p["key"]], Color(1.6, 1.4, 0.8), 0.3)
			await lv.wait(1.2 * speed)
		"mog_supreme":
			flash(0.9, Color(1, 1, 1))
			sfx("mog", 0.8)
			lv.shake = 0.4
			await lv.wait(0.5)
		"chud_out":
			sfx("sit", 0.6)
			await lv.wait(0.3)
		"combo":
			pass
		"rally":
			await _rally(ev["count"])
		"item":
			Game.ach.bump(ev["item"])   # Crunk (3 beezy) / Slopbowl Consumer (3 bowls)
			_float(_node(ev["target"]), D.ITEMS[ev["item"]]["name"], Color("#8ad8ff"), 0.8, 0.5)
			sfx("gulp")
			await lv.wait(0.4)
		"chaos":
			var c: Dictionary = ev["c"]
			flash(0.5, Color(0.8, 0.6, 1.0))
			_say(c["title"])
			await _banner("DULBMEETHUS" if c["id"] == "dulbmeethus_bolt" else "CHAOS EVENT", PURPLE, 1.6)
		"lightning":   # Dulbmeethus smites the enemy side: Ebain's cutscene, then the white-out fades into a bolt on every enemy
			Game.achieve("hear_me_doe")
			var cover: ColorRect = await _strike_cutscene()   # null when there's no video (headless tests, missing file)
			if sounds.has("strike"):
				sounds["strike"].play()   # the attack clip: starts as the white fades and the bolts land
			else:
				sfx("blast", 0.6)
			if cover != null:
				_strike_reveal(cover)
			for e in ev["us"]:
				var eu = _node(e)
				if not _bolt_art(eu):   # Ebain's lightning pictures; the plain bolt if they're missing
					_bolt(eu)
				lv.shake = 1.2
				await lv.wait(0.12)
			flash(0.8, Color(1, 1, 1))
			lv.shake = 1.2
			await lv.wait(0.9 if cover != null else 0.5)
		"attack":
			sfx(ev.get("sound", "hit"))
			if ev.get("sit", false):
				lv.shake = 1.0
				flash(0.4, Color(0.6, 0.4, 0.3))
			else:
				lv.shake = 0.3
			await lv.wait(0.15)
		"tex":
			var tex := _tex(ev["tex"])
			if tex: n.set_pose(tex, ev["u"]["E"]["h"])
		"telegraph":
			sfx("low", 1.5)
			if ev.get("tex", "") != "":
				var tt := _tex(ev["tex"])
				if tt: n.set_pose(tt, ev["u"]["E"]["h"] * 0.78)
			lv.hop(n, 0.3)
			_say(ev["text"])
			await _banner("WATCH OUT", Color("#ff9a3a"), 1.2)
			await lv.wait(0.8 * speed)
		"phase":
			var keep := lv.zoom
			var kf = lv.focus_override
			if not ev.get("quick", false):
				lv.focus_override = n.global_position
				lv.zoom = keep * 0.6
				lv.shake = 0.9
				flash(0.6, Color(1, 0.4, 0.3))
				sfx("roar", 0.6)
			if ev.get("disguise", "") != "":
				var dt := _tex(ev["disguise"])
				if dt:
					n.set_pose(dt, D.FIGHTS[key]["enemies"][0]["h"] * 0.75)
					n.set_meta("tint", Color(1.25, 0.75, 1.35))
					base_tint[ev["u"]["key"]] = Color(1.25, 0.75, 1.35)
				lv.char_label(n, "%s (Bootleg)" % D.PARTY[ev["disguise"]]["name"], 2.5, n.height_m + 0.3, PURPLE)
			_say(ev["text"])
			if not ev.get("quick", false):
				await _banner("PHASE 2", RED, 1.4)
				lv.focus_override = kf
				lv.zoom = keep
			else:
				await lv.wait(1.2)
		"miss":
			_float(n, "MISS", Color.WHITE, 0.8)
			_say(ev["text"])
			sfx("miss")
			await lv.wait(0.9 * speed)
		"talk":
			_say(ev["text"])
			lv.hop(n, 0.25)
			await lv.wait(1.4 * speed)
		"talked":
			_say(ev["text"])
			sfx("heal")
			await _banner("TALKED IT OUT", GREEN, 1.6)
		"fled":
			Game.ach.bump("fled")   # Tactical retreat (5 fights)
			_say(ev["text"])
			sfx("rewind" if sounds.has("rewind") else "throw", 1.0)   # (sfx pack) record rewind: we were never here
			await _banner("GOT AWAY", Color("#8ad8ff"), 1.2)
		"dice":
			_say(ev["text"])
			await _show_dice(ev["rolls"])

# ------------------------------------------------------------------ little effects
func _say(text: String) -> void:
	log_lbl.text = text
	if text != "" and (_log_lines.is_empty() or _log_lines[-1] != text):
		_log_lines.append(text)
		if _log_lines.size() > 80: _log_lines.pop_front()

func flash(secs: float, c: Color) -> void:
	flash_rect.color = Color(c.r, c.g, c.b, 0.55)
	create_tween().tween_property(flash_rect, "color:a", 0.0, secs)

func flash_unit(n: Unit, c: Color, secs: float) -> void:
	if n == null: return
	n.set_meta("tint", c)
	if secs < 50.0:
		get_tree().create_timer(secs).timeout.connect(_unflash.bind(n, c))

func _unflash(n: Unit, c: Color) -> void:
	if not is_instance_valid(n) or n.get_meta("tint") != c:
		return
	for k in nodes:
		if nodes[k] == n:
			var u := _unit_by_key(k)
			if u.is_empty() or u["hp"] > 0:
				n.set_meta("tint", base_tint[k])

func _unhurt(n: Unit, u: Dictionary) -> void:
	if is_instance_valid(n) and u["hp"] > 0:
		_stand(n)

func _unit_by_key(k: String) -> Dictionary:
	for u in b.party + b.enemies:
		if u["key"] == k:
			return u
	return {}

func _restore_tint(u: Dictionary) -> void:
	nodes[u["key"]].set_meta("tint", base_tint[u["key"]])

func _kick(n: Unit, dir := 1.0) -> void:
	if n == null: return
	var p := n.global_position
	var tw := create_tween()
	tw.tween_property(n, "global_position", p + right * 0.35 * dir, 0.06)
	tw.tween_property(n, "global_position", p, 0.14)

func _float(n: Unit, text: String, c: Color, size := 1.0, up := 0.0) -> void:
	if n == null: return
	var l := Label3D.new()
	l.text = text
	l.font_size = int(64 * size)
	l.pixel_size = 0.007 * (1.6 if key == "giant" else 1.0)
	l.outline_size = 14
	l.no_depth_test = true
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = c
	lv.add_child(l)
	l.global_position = n.global_position + Vector3(randf_range(-0.25, 0.25), n.height_m + 0.2 + up, 0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "global_position", l.global_position + Vector3(0, 0.9, 0), 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)

func _banner(text: String, c: Color, secs: float) -> void:
	banner.text = text
	banner.add_theme_color_override("font_color", c)
	banner.scale = Vector2(1.3, 1.3)
	banner.pivot_offset = Vector2(600, 40)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(banner, "modulate:a", 1.0, 0.15)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await lv.wait(secs * (1.0 if cinematic else 0.8))
	create_tween().tween_property(banner, "modulate:a", 0.0, 0.25)

# ---- Throw Anything: a little pile of real props beside the party, themed to the area. Skorn picks one up and
# throws it; it smashes on the enemy. When the pile runs out a new one appears.
#   [model id, what the text calls it, longest side in meters]
const PILES := {
	"camp": [["wooden_bucket_01", "a bucket", 0.5], ["rock_07", "a rock that looked at him funny", 0.5], ["wooden_bowl_01", "an empty bowl", 0.35], ["dry_branches_medium_01", "a bundle of sticks", 0.7], ["tree_stump_01", "a tree stump", 0.7]],
	"trail": [["rock_07", "a rock", 0.5], ["dry_branches_medium_01", "a bundle of sticks", 0.7], ["tree_stump_01", "a tree stump", 0.7], ["wooden_bucket_02", "the troll's bucket", 0.5], ["dead_tree_trunk_02", "half a log", 0.8]],
	"village": [["wooden_stool_01", "a goblin's stool", 0.6], ["wooden_bucket_02", "a bucket", 0.5], ["wooden_crate_02", "a crate", 0.6], ["wine_barrel_01", "a barrel", 0.8], ["wooden_spoon", "a spoon", 0.45]],
	"mart": [["wine_bottles_01", "a crate of bottles", 0.5], ["ceramic_vase_01", "a vase (NO REFUNDS)", 0.5], ["brass_pot_01", "a brass pot", 0.45], ["wooden_crate_01", "a crate", 0.6], ["book_encyclopedia_set_01", "an encyclopedia", 0.45]],
	"ruins": [["rock_07", "a chunk of ancient wall", 0.55], ["wooden_crate_01", "an ancient crate", 0.6], ["rock_09", "a rock (historical)", 0.6], ["dry_branches_medium_01", "a bundle of sticks", 0.7], ["wooden_bucket_01", "a bucket", 0.5]],
	"cave": [["rock_07", "a stalagmite", 0.55], ["wooden_crate_02", "a rat's crate", 0.55], ["wine_bottles_01", "a crate of bottles", 0.5], ["rock_09", "a cave rock", 0.6], ["wooden_bucket_02", "a rat's bucket", 0.5]],
	"pass": [["rock_07", "a rock", 0.55], ["rock_09", "a chunk of the mountain", 0.7], ["rock_07", "a rock that looked at him funny", 0.45], ["dry_branches_medium_01", "a burnt branch", 0.8], ["boulder_01", "a boulder (small)", 0.7]],
}
var pile: Array = []   # [{ "node": Node3D, "name": String }]

func _pile_defs() -> Array:
	var k: String = lv.area_key() if lv.has_method("area_key") else "camp"
	return PILES.get(k, PILES["camp"])

func _spawn_pile() -> void:
	for p in pile:
		if is_instance_valid(p["node"]): p["node"].queue_free()
	pile = []
	var defs := _pile_defs()
	var base: Vector3 = center - right * (1.9 + b.party.size() * 1.15 + 1.2) - fwd * 0.6
	for i in defs.size():
		var d: Array = defs[i]
		var n: Node3D = Models.place(lv, d[0], Vector3.ZERO, randf() * TAU, 1.0, false, Color(0.75, 0.62, 0.5) if d[0].begins_with("rock") or d[0] == "boulder_01" else Color.WHITE)
		var box := Models.aabb(n)
		var sc: float = d[2] * 1.9 / maxf(0.01, maxf(box.size.x, maxf(box.size.y, box.size.z)))   # ×1.9: readable at fight zoom
		n.scale = Vector3.ONE * sc
		var at := base + right * ((i % 3) - 1) * 1.0 + fwd * (int(i / 3) * 1.1 + randf_range(-0.1, 0.1))
		n.global_position = Vector3(at.x, -box.position.y * sc, at.z)
		n.set_meta("rest_y", n.global_position.y)
		pile.append({ "node": n, "name": d[1] })
	b.throwables = pile.map(func(p): return p["name"])

func _throw(from: Unit, to: Unit, thing: String) -> void:
	var pick := -1
	for i in pile.size():
		if pile[i]["name"] == thing and is_instance_valid(pile[i]["node"]):
			pick = i
			break
	if pick < 0 and not pile.is_empty():
		pick = 0
	if pick < 0:   # no pile (Skorn joined late?): fall back to a floating word
		_float(to, thing.to_upper(), GOLD, 0.8, 0.2)
		sfx("throw")
		await lv.wait(0.4)
		return
	var n: Node3D = pile[pick]["node"]
	pile.remove_at(pick)
	b.throwables = pile.map(func(p): return p["name"])
	var hand := from.global_position + Vector3(0, from.height_m * 0.85, 0) + right * 0.25
	var z := to.global_position + Vector3(0, to.height_m * 0.55, 0)
	# grab it
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "global_position", hand, 0.2)
	await tw.finished
	sfx("throw")
	# throw it: arc + spin
	var spin := Vector3(randf_range(6, 10), randf_range(-4, 4), randf_range(6, 10))
	var top := hand.lerp(z, 0.5) + Vector3(0, 1.6, 0)
	tw = create_tween().set_parallel(true)
	tw.tween_property(n, "rotation", n.rotation + spin, 0.5)
	var arc := create_tween()
	arc.tween_property(n, "global_position", top, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(n, "global_position", z, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if throw_test:   # --shots tour: one picture mid-air
		throw_test = false
		await lv.wait(0.22)
		await lv.shot("fight_%s_throw" % key)
	await arc.finished
	# smash
	sfx("hit", 0.8)
	lv.shake = maxf(lv.shake, 0.25)
	var pop := create_tween().set_parallel(true)
	pop.tween_property(n, "scale", n.scale * 1.4, 0.08)
	pop.chain().tween_property(n, "scale", Vector3.ONE * 0.01, 0.14)
	await pop.finished
	n.queue_free()
	if pile.is_empty():   # Skorn finds more junk
		_spawn_pile()
		for p in pile:
			var pn: Node3D = p["node"]
			var s0: Vector3 = pn.scale
			pn.scale = Vector3.ONE * 0.01
			create_tween().tween_property(pn, "scale", s0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _rally(count: int) -> void:
	var tex: Texture2D = load("res://assets/characters/goblin.png")
	for i in mini(count, 5):
		var s := Sprite3D.new()
		s.texture = tex
		s.pixel_size = 1.15 / tex.get_height()
		s.offset = Vector2(0, tex.get_height() / 2.0)
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		s.shaded = false
		s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		lv.add_child(s)
		var z := fwd * randf_range(-1.6, 1.6)
		s.global_position = center - right * 7.0 + z
		var tw := create_tween()
		tw.tween_property(s, "global_position", center + right * 2.0 + z * 0.5, 0.45 + i * 0.06)
		tw.tween_property(s, "global_position", center + right * 9.0 + z, 0.5)
		tw.tween_callback(s.queue_free)
		sfx("bonk", 1.0 + i * 0.1)
		await lv.wait(0.12)
	await lv.wait(0.35)

# ================================================================== player input bits
func _menu(title: String, opts: Array, can_back: bool):
	menu_title.text = title
	for c in menu_list.get_children():
		c.queue_free()
	_menu_btns = []
	_menu_opts = opts
	if can_back:
		_menu_opts = opts + [{ "text": "< Back", "desc": "", "v": null }]
	for i in _menu_opts.size():
		var o: Dictionary = _menu_opts[i]
		var bt := Button.new()
		bt.text = o["text"]
		bt.flat = true
		bt.focus_mode = Control.FOCUS_NONE
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.add_theme_font_size_override("font_size", 17)
		bt.add_theme_font_override("font", UITheme.row_font())
		bt.gui_input.connect(func(ev):   # only real mouse movement moves the highlight (UITheme.hover_moved)
			if UITheme.hover_moved(ev) and _menu_sel != i:
				_menu_sel = i
				sfx("move")
				_render_menu())
		bt.pressed.connect(func(): _menu_sel = i; _confirm_menu())
		menu_list.add_child(bt)
		_menu_btns.append(bt)
	# Reserve room for the longest description in this menu, so the box doesn't grow/shrink (and jump under the
	# mouse) while you move between options.
	var font: Font = menu_desc.get_theme_font("font")
	var fsize: int = menu_desc.get_theme_font_size("font_size")
	var tallest := 0.0
	for o in _menu_opts:
		var t: String = o.get("desc", "")
		if t != "":
			tallest = maxf(tallest, font.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, 350, fsize).y)
	menu_desc.custom_minimum_size = Vector2(350, ceilf(tallest) + 12)   # + headroom: the label draws a few px taller than measured
	_menu_sel = 0
	while _menu_sel < _menu_opts.size() - 1 and _menu_opts[_menu_sel].get("off", false):
		_menu_sel += 1
	_render_menu()
	menu_panel.visible = true
	_menu_active = true
	set_meta("can_back", can_back)
	var v = await _menu_done
	_menu_active = false
	menu_panel.visible = false
	return v

var _last_menu_sel := -1
func _render_menu() -> void:
	var T := _th()
	for i in _menu_btns.size():
		var o: Dictionary = _menu_opts[i]
		var bt: Button = _menu_btns[i]
		var col := UITheme.c("text", T)
		if o.get("off", false): col = UITheme.c("faint", T)
		elif o.get("hot", false): col = _ink(Color("#fff07a"))
		if i == _menu_sel: col = UITheme.c("accent", T) if not o.get("off", false) else Color(UITheme.c("accent", T), 0.5)
		bt.text = o["text"]
		for st in ["normal", "hover", "pressed", "focus"]:
			bt.add_theme_stylebox_override(st, UITheme.row(i == _menu_sel, T))
		if i == _menu_sel and i != _last_menu_sel:
			UITheme.bounce(bt, 0.03)
		bt.add_theme_color_override("font_color", col)
		bt.add_theme_color_override("font_hover_color", col)
		bt.add_theme_color_override("font_pressed_color", col)
	_last_menu_sel = _menu_sel
	menu_desc.text = _menu_opts[_menu_sel].get("desc", "") if not _menu_opts.is_empty() else ""
	menu_desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var tl: Dictionary = _menu_opts[_menu_sel].get("tl", {}) if not _menu_opts.is_empty() else {}
	if tl != _tl_shown:   # 11/26: the turn bar shows what this move would do to the turn order
		_tl_shown = tl
		_timeline(tl)

func _confirm_menu() -> void:
	var o: Dictionary = _menu_opts[_menu_sel]
	if o.get("off", false):
		sfx("miss")
		return
	sfx("select")
	_menu_done.emit(o["v"])

# Plays Dulbmeethus' cutscene full-screen (16:9 kept, black bars on other window shapes, music ducked) and returns
# a white cover that is still up, so the battle can fade in from the white-out (see _strike_reveal). Press interact
# / back / click after a moment to skip. Returns null (nothing shown) in headless runs (explorer bot, tours) or if
# the video can't load, so fights never get stuck on it.
func _strike_cutscene() -> ColorRect:
	if DisplayServer.get_name() == "headless" or OS.get_environment("NO_CUTSCENE") != "":
		return null
	if not ResourceLoader.exists(STRIKE_VIDEO):
		return null
	var stream = load(STRIKE_VIDEO)
	if stream == null:
		return null
	var cover := ColorRect.new()
	cover.color = Color.BLACK
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(cover)
	var frame := AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.add_child(frame)
	var vp := VideoStreamPlayer.new()
	vp.stream = stream
	vp.expand = true
	vp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if AudioServer.get_bus_index("SFX") != -1:
		vp.bus = &"SFX"
	frame.add_child(vp)
	var skip_lbl := Label.new()
	skip_lbl.text = "E / Esc: skip"
	skip_lbl.modulate = Color(1, 1, 1, 0.0)
	skip_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_lbl.offset_left = -170; skip_lbl.offset_top = -40; skip_lbl.offset_right = -16; skip_lbl.offset_bottom = -12
	skip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cover.add_child(skip_lbl)
	_strike_vp = vp
	_strike_skip = false
	var mus := AudioServer.get_bus_index("Music")   # the song drops out while he's on screen
	var mus_db := AudioServer.get_bus_volume_db(mus) if mus != -1 else 0.0
	if mus != -1:
		AudioServer.set_bus_volume_db(mus, -60.0)
	vp.play()
	_strike_t0 = Time.get_ticks_msec()
	while vp.is_playing() and not _strike_skip and Time.get_ticks_msec() - _strike_t0 < 14000:   # watchdog: the clip is 10 s
		if Time.get_ticks_msec() - _strike_t0 > 1200 and skip_lbl.modulate.a == 0.0:
			create_tween().tween_property(skip_lbl, "modulate:a", 0.6, 0.4)
		await get_tree().process_frame
	vp.stop()
	vp.queue_free()
	skip_lbl.queue_free()
	_strike_vp = null
	if mus != -1:
		AudioServer.set_bus_volume_db(mus, mus_db)
	cover.color = Color.WHITE   # the video ends on a white-out, so the cover takes over from there
	return cover

# fades the white cover away to reveal the battle, then removes it
func _strike_reveal(cover: ColorRect) -> void:
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(cover, "color:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(cover.queue_free)

func _input(ev: InputEvent) -> void:
	if _strike_vp != null:   # cutscene running: only skipping works
		if (ev.is_action_pressed("interact") or _is_back(ev) or (ev is InputEventMouseButton and ev.pressed)) and Time.get_ticks_msec() - _strike_t0 > 600:
			_strike_skip = true   # (not in the first 0.6 s, so mashing E before it starts doesn't skip it)
		get_viewport().set_input_as_handled()
		return
	if not MenuUI.stack.is_empty():   # the tutorial or a yes/no box is on top
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_H and _menu_active:   # replay the combat tutorial
		get_viewport().set_input_as_handled()
		await CombatTutorial.show_over(lv.hud).closed
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_L:   # battle log history
		get_viewport().set_input_as_handled()
		_toggle_log()
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_T:
		Game.timed_auto = not Game.timed_auto
		_update_hint()
		lv.show_toast("Timed hits: %s" % ("AUTO" if Game.timed_auto else "MANUAL"))
		get_viewport().set_input_as_handled()
		return
	if _menu_active:
		if ev.is_action_pressed("move_forward") or ev.is_action_pressed("ui_up"):
			_menu_sel = (_menu_sel + _menu_opts.size() - 1) % _menu_opts.size()
			UITheme.key_nav(); sfx("move"); _render_menu()
		elif ev.is_action_pressed("move_back") or ev.is_action_pressed("ui_down"):
			_menu_sel = (_menu_sel + 1) % _menu_opts.size()
			UITheme.key_nav(); sfx("move"); _render_menu()
		elif ev.is_action_pressed("interact"):
			_confirm_menu()
		elif _is_back(ev) and get_meta("can_back", false):
			_menu_done.emit(null)
		else:
			return
		get_viewport().set_input_as_handled()

func _is_back(ev: InputEvent) -> bool:
	if ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B:   # controller B = back
		return true
	return ev is InputEventKey and ev.pressed and ev.physical_keycode in [KEY_Q, KEY_ESCAPE, KEY_BACKSPACE]

# Pick a unit with A/D (or W/S), E to confirm, Q to go back. Returns the battle unit or null.
func _pick_target(list: Array, allies: bool, pv: Callable = Callable()):   # pv(target) -> damage preview text
	var opts := list.filter(func(u): return allies or u["hp"] > 0)
	if opts.is_empty():
		return null
	if opts.size() == 1 and not allies:
		return opts[0]
	var i := 0
	if allies:   # start on whoever's hurt the most
		for j in opts.size():
			if float(opts[j]["hp"]) / opts[j]["max_hp"] < float(opts[i]["hp"]) / opts[i]["max_hp"]:
				i = j
	menu_panel.visible = true
	menu_title.text = "Pick a teammate" if allies else "Pick a target"
	for c in menu_list.get_children():
		c.queue_free()
	_menu_btns = []
	menu_desc.text = "A/D to switch · E to confirm · Q to go back"
	await get_tree().process_frame
	while true:
		var u: Dictionary = opts[i]
		_point(target_marker, nodes[u["key"]])
		menu_title.text = "%s:  %s  (%d/%d)" % ["Teammate" if allies else "Target", u["name"], u["hp"], u["max_hp"]]
		var pt: String = pv.call(u) if pv.is_valid() else ""
		menu_desc.text = (pt + "\n" if pt != "" else "") + "A/D to switch · E to confirm · Q to go back"
		await get_tree().process_frame
		if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_forward") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_up"):
			i = (i + opts.size() - 1) % opts.size(); sfx("move")
		elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("move_back") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_down"):
			i = (i + 1) % opts.size(); sfx("move")
		elif Input.is_action_just_pressed("interact"):
			_point(target_marker, null)
			menu_panel.visible = false
			return opts[i]
		elif Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_ESCAPE) or Input.is_key_pressed(KEY_BACKSPACE) or Input.is_joy_button_pressed(0, JOY_BUTTON_B):
			_point(target_marker, null)
			menu_panel.visible = false
			await lv.wait(0.15)
			return null
	return null

# Shrinking ring: press E/Space when it lines up. kind = "attack" or "block".
class Ring extends Control:
	var r := 160.0
	var goal := 44.0
	var col := Color.WHITE
	func _draw() -> void:
		draw_arc(Vector2.ZERO, goal, 0, TAU, 48, Color(1, 1, 1, 0.9), 5.0, true)
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, col, 4.0, true)

func _timed(n: Unit, kind: String) -> String:
	var r := await _timed_inner(n, kind)
	sfx("cmb_whoosh_%d" % randi_range(1, 3), 1.1 if kind == "attack" else 0.9)
	return r

func _timed_inner(n: Unit, kind: String) -> String:
	var ring := Ring.new()
	ring.col = GOLD if kind == "attack" else Color("#ff8a5a")
	root.add_child(ring)
	var p := lv.cam.unproject_position(n.global_position + Vector3(0, n.height_m * (0.5 if key != "giant" or kind == "block" else 0.45), 0))
	ring.position = p
	var tip := lv._label("HIT!" if kind == "attack" else "BLOCK!", Vector2.ZERO, 20, ring.col, 6)
	tip.position = p + Vector2(-30, -200)
	root.add_child(tip)
	var win: float = D.DIFFICULTY[Game.difficulty]["window"]
	var dur := 0.85 * (1.15 if kind == "block" else 1.0)
	var tt := 0.0
	var result := ""
	var pressed := false
	var auto_at := -1.0
	if auto_play:
		auto_at = dur
	elif Game.timed_auto:
		auto_at = dur * randf_range(0.93, 1.0)
	while tt < dur + 0.3:
		await get_tree().process_frame
		tt += get_process_delta_time()
		ring.r = lerpf(160.0, 44.0, tt / dur)
		ring.queue_redraw()
		var hit := Input.is_action_just_pressed("interact") if auto_at < 0.0 else tt >= auto_at
		if hit:
			pressed = true
			var d: float = abs(ring.r - ring.goal)
			if d <= 8.0 * win: result = "perfect"
			elif d <= 22.0 * win: result = "good"
			else: result = "mid" if kind == "attack" else ""
			break
	if not pressed:
		result = "mid" if kind == "attack" else ""
	ring.queue_free()
	tip.queue_free()
	if result != "" and result != "mid":
		sfx("crit" if result == "perfect" else "select")
	return result

func _roll_dice(u: Dictionary, count: int) -> Array:
	var rolls := []
	var no_ones: bool = u["gear"].get("no_ones", false)
	for i in count:
		rolls.append(randi_range(2 if no_ones else 1, 6))
	_say("%s rolls %s… (on some dice shi)" % [u["name"], "the d6" if count == 1 else "TWO dice"])
	await _show_dice(rolls)
	return rolls

func _show_dice(rolls: Array, sides := 6) -> void:   # sides 20 = a death save
	var box := HBoxContainer.new()
	box.anchor_left = 0.5; box.anchor_right = 0.5; box.anchor_top = 0.42
	box.offset_left = -150; box.offset_right = 150
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	root.add_child(box)
	var faces := []
	for r in rolls:
		var pc := PanelContainer.new()
		pc.add_theme_stylebox_override("panel", _box(Color(0.95, 0.93, 0.88), Color(0.1, 0.1, 0.1), 3))
		pc.custom_minimum_size = Vector2(96, 96)
		var l := lv._label("?", Vector2.ZERO, 58, Color(0.1, 0.08, 0.1), 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pc.add_child(l)
		box.add_child(pc)
		faces.append(l)
	if sounds.has("dice_real"):
		sfx("dice_real", 1.0)
	for k in 9:
		if not sounds.has("dice_real"):
			sfx("dice", 1.0 + k * 0.05)
		for l in faces:
			l.text = str(randi_range(1, sides))
		await lv.wait(0.07)
	for i in rolls.size():
		faces[i].text = str(rolls[i])
		faces[i].add_theme_color_override("font_color", Color("#c0392b") if rolls[i] in [1, sides] else Color(0.1, 0.08, 0.1))
	sfx("boing" if 1 in rolls and sounds.has("boing") else "bonk", 1.0 if 1 in rolls else 0.7)   # a 1: boing
	await lv.wait(0.9)
	box.queue_free()

func _ask_67() -> bool:
	if auto_play:
		return true
	var v = await _menu("You rolled a 6… do the 6-7? (once per game)", [
		{ "text": "DO THE 6-7", "desc": "67 damage to every enemy. You can only ever do this once.", "v": true, "hot": true },
		{ "text": "Nah, save it", "desc": "Keep the normal roll.", "v": false },
	], false)
	return v

# ================================================================== the end
var knocked_out: Array = []   # names knocked out when the fight ended (Level.fight tells you they got up at 1 HP)

func _outro(res: String) -> void:
	if res == "lose":
		Game.achieve("cooked")   # "You got cooked": lose your first fight
	for p in pile:   # tidy up the throw pile
		if is_instance_valid(p["node"]): p["node"].queue_free()
	pile = []
	# carry HP back out: damage stays, knocked out = back up at 1 HP (a loss heals everyone in Level._defeat,
	# and a level up in _results refills everyone)
	for p in b.party:
		if p["hp"] <= 0: knocked_out.append(p["name"])
		if Game.max_hp(p["id"]) > 0:
			Game.hurt[p["id"]] = p["max_hp"] - maxi(1, p["hp"])
			if Game.hurt[p["id"]] <= 0: Game.hurt.erase(p["id"])
	# carry items back out
	for id in b.bags:   # what's left in each fighter's bag
		for k in D.FIGHT_ITEMS:
			if b.bags[id].has(k): Game.set_count(id, k, b.bags[id][k])
	Game.used67 = b.used67
	if int(Game.flags.get("fadedFights", 0)) > 0:   # puff puff pass with Deloye: 3 fights of Faded
		Game.flags["fadedFights"] = int(Game.flags["fadedFights"]) - 1
	_refresh()
	if res == "win" or res == "talked":
		await _results(res)
	elif res == "fled":
		await lv.wait(0.6)
	# clean up the stage
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.3)
	await tw.finished
	root.queue_free()
	actor_marker.queue_free()
	target_marker.queue_free()
	for k in nodes:
		var n: Unit = nodes[k]
		if not is_instance_valid(n):
			continue
		lv.unknock(n)
		n.remove_meta("in_fight")
		n.remove_meta("fight_face")
		n.remove_meta("attacking")
		n.set_meta("tint", base_tint[k])
		if lv.party.has(n) or n.id == "chief":
			n.restore_views()
		else:
			n.views = saved_pose[n][0].duplicate()
			n.height_m = saved_pose[n][1]
			n.view = ""
			n.set_view("front")
		n.sprite.flip_h = false
	for n in spawned:
		lv.npcs.erase(n)
		n.queue_free()
	for k in sounds:
		sounds[k].queue_free()
	lv.busy = saved["busy"]
	lv.follow_enabled = saved["follow"]
	lv.switch_enabled = saved["switch"]
	lv.zoom = saved["zoom"]
	lv.cam_height = saved["cam_height"]
	lv.cam_look_h = saved["cam_look_h"]
	lv.focus_override = saved["focus"]
	lv.cam_locked = saved["locked"]
	lv.objective_lbl.visible = saved["objective"]
	lv.help_lbl.visible = true
	lv.title_box.visible = true
	lv.minimap.visible = true
	if saved["box"]:
		lv.dialogue.show_box()
	queue_free()

# ---- victory screen bits
var loot_icons: Array = []
func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", 6)
	return r

func _row_label(text: String, size: int, color: Color) -> Label:
	var l := _pl(text, size, color, 5)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _coin_icon(px: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = InventoryUI.coin_texture()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return t

# A found item's picture (or initials). Hover it to see what it is and what it does.
func _loot_icon(gear_id: String) -> Control:
	var G: Dictionary = D.GEAR.get(gear_id, {})
	var box := Panel.new()
	box.custom_minimum_size = Vector2(60, 60)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1c1815"); sb.border_color = Color("#b8913a"); sb.set_border_width_all(2); sb.set_corner_radius_all(6)
	box.add_theme_stylebox_override("panel", sb)
	var tex: Texture2D = lv.item_icon(gear_id)
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(5, 5); t.size = Vector2(50, 50)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(t)
	else:
		var ini := ""
		for w in G.get("name", gear_id).split(" ", false):
			if ini.length() < 3 and w[0] == w[0].to_upper() and w[0] != "(":
				ini += w[0]
		var l := lv._label(ini, Vector2.ZERO, 18, Color("#e8d9b5"), 4)
		l.size = Vector2(60, 60); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	# hover card
	var tip := PanelContainer.new()
	tip.add_theme_stylebox_override("panel", _tip_box())
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip.z_index = 10
	var tc := VBoxContainer.new()
	tc.add_theme_constant_override("separation", 2)
	tip.add_child(tc)
	tc.add_child(_pl(G.get("name", gear_id), 20, GOLD, 4))
	tc.add_child(_pl(G.get("slot", "trinket").capitalize(), 14, Color(1, 1, 1, 0.6), 3))
	var d := _pl(G.get("desc", ""), 15, Color.WHITE, 3)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	tc.add_child(d)
	for s in InventoryUI.gear_stat_lines(G):
		tc.add_child(_pl("• " + s, 15, Color("#7dff8a"), 3))
	tc.add_child(_pl("Equip it in your inventory (Tab)", 13, Color(1, 1, 1, 0.55), 3))
	root.add_child(tip)
	box.mouse_entered.connect(func():
		tip.visible = true
		tip.reset_size()
		var r := box.get_global_rect()
		tip.global_position = Vector2(r.get_center().x - tip.size.x / 2.0, r.position.y - tip.size.y - 8))
	box.mouse_exited.connect(func(): tip.visible = false)
	box.tree_exiting.connect(func(): if is_instance_valid(tip): tip.queue_free())
	return box

# Gold from a fight: every enemy's "gold" (win) or half of it (talked), give or take 20%.
static func fight_gold(def: Dictionary, res: String) -> int:
	if res != "win" and res != "talked":
		return 0
	var total := 0
	for E in def.get("enemies", []):
		total += int(E.get("gold", 0))
	if res == "talked":
		total = int(total * 0.5)
	return int(round(total * randf_range(0.8, 1.2))) if total > 0 else 0

func _results(res: String) -> void:
	var gr: Dictionary = b.grade() if res == "win" else {}   # victory grade (11/26): better grade, more gold and XP
	var xp: int = int(round(fdef["xp"] * (1.0 if res == "win" else 0.5) * gr.get("xp", 1.0)))
	var ups := Game.add_xp(xp)
	if not ups.is_empty(): knocked_out.clear()   # level up refilled everyone
	var gold := int(round(fight_gold(fdef, res) * gr.get("gold", 1.0)))
	Game.add_gold(gold)
	var found: Array = []   # gear ids picked up this fight
	if res == "win" and fdef.has("loot"):   # one gear id, or a list of them
		var loot: Array = fdef["loot"] if fdef["loot"] is Array else [fdef["loot"]]
		for g in loot:
			if Game.give_gear(g):
				found.append(g)
	sfx("ready", 0.9)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	var ph := 190 if gr.is_empty() else 240
	panel.offset_left = -330; panel.offset_right = 330; panel.offset_top = -ph; panel.offset_bottom = ph
	panel.add_theme_stylebox_override("panel", UITheme.panel(0.96, _th()))
	root.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var line := func(text: String, size: int, color: Color) -> void:
		var l := _pl(text, size, color, 5)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(620, 0)
		col.add_child(l)
	if res == "win":
		line.call("VICTORY!!!", 44, GOLD)
		var grow := _row()   # GRADE  A   +25% gold · +10% XP
		grow.add_child(_row_label("GRADE ", 24, Color.WHITE))
		var glet := _row_label(gr["letter"], 50, Color(gr["color"]))
		grow.add_child(glet)
		_slam_in(glet)
		var bonus := []
		if gr["gold"] > 1.0: bonus.append("+%d%% gold" % int(round((gr["gold"] - 1.0) * 100)))
		if gr["xp"] > 1.0: bonus.append("+%d%% XP" % int(round((gr["xp"] - 1.0) * 100)))
		grow.add_child(_row_label("    " + (" · ".join(bonus) if not bonus.is_empty() else "(no bonus)"), 20, Color(gr["color"])))
		col.add_child(grow)
		var st: Dictionary = b.stats
		var srank: String = D.S_RANK_LOOT.get(key, "")   # 11/26: first S on a boss gives its trinket
		if gr["letter"] == "S" and srank != "" and not Game.flag("srank_" + key):
			Game.set_flag("srank_" + key)
			if Game.give_gear(srank):
				line.call("S-RANK REWARD: %s (check your inventory)" % D.GEAR[srank]["name"], 20, Color("#ffd84a"))
		line.call("HP left %d/40 · Timing %d/25 · No knockouts %d/15 · Style %d/20  (%d team-ups, %d breaks, %d combos, %d weak-spot hits)" % [gr["hp"], gr["timing"], gr["kos"], gr["style"], st["combos"], st["breaks"], st["payoffs"], st["weak_hits"]], 14, Color(1, 1, 1, 0.65))
	else:
		line.call("TALKED IT OUT", 40, GREEN)
		line.call("(Half XP and gold for being reasonable)", 18, Color(1, 1, 1, 0.7))
	if gold > 0:   # +20 (coin)   ·   Total Gold: 67 (coin)
		var row := _row()
		row.add_child(_row_label("+%d" % gold, 24, GOLD))
		row.add_child(_coin_icon(24))
		row.add_child(_row_label("     ·     Total Gold: %d" % Game.gold, 20, Color(1, 1, 1, 0.85)))
		row.add_child(_coin_icon(20))
		col.add_child(row)
	line.call("+%d XP   ·   Level %d   (%s)" % [xp, Game.level, "%d to next" % Game.xp_to_next() if Game.xp_to_next() > 0 else "max"], 20, Color.WHITE)
	for lvn in ups:
		line.call("LEVEL UP! The trio is now Level %d. (+10%% HP and damage, everyone fully healed)" % lvn, 20, GREEN)   # (the level-up jingle plays from Game.leveled_up)
		if lvn == 3:
			line.call("New moves: Bussy Mist · Jean Paul Gaultier · Gust of Wind", 18, Color("#fff07a"))
	if not found.is_empty():   # Found: [icon] [icon]  (hover for details)
		var row := _row()
		row.add_child(_row_label("Found:", 22, Color("#8ad8ff")))
		for g in found:
			var ic := _loot_icon(g)
			row.add_child(ic)
			loot_icons.append(ic)
		col.add_child(row)
	line.call("", 8, Color.WHITE)
	line.call("Press E to continue", 16, Color(1, 1, 1, 0.6))
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = Vector2(330, ph)
	create_tween().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for p in b.alive(b.party):
		lv.hop(nodes[p["key"]], 0.5)
	await lv.wait(0.8)
	if auto_play:
		await lv.wait(1.2)
		if OS.get_environment("SHOT_DIR") != "":
			await lv.shot("fight_%s_results" % key)
			if not loot_icons.is_empty():   # test: show the hover card too
				loot_icons[0].mouse_entered.emit()
				await lv.wait(0.3)
				await lv.shot("fight_%s_results_hover" % key)
		return
	while not Input.is_action_just_pressed("interact"):
		await get_tree().process_frame
