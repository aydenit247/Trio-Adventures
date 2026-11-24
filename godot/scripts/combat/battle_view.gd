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
const PORTRAIT := { "goblin": "goblin", "dulbers": "dulbers_demon", "giant": "giant_angry" }
const GOLD := Color("#e8b923")
const RED := Color("#ff6a5a")
const GREEN := Color("#7dff8a")
const PURPLE := Color("#c79bff")

var lv: Level
var b: Battle
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
var ebars := {}          # key -> { hp, st, name }
var pbars := {}          # key -> { hp, hp_lbl, meter, st, card }
var actor_marker: MeshInstance3D
var target_marker: MeshInstance3D

# menu state
var _menu_opts: Array = []
var _menu_sel := 0
var _menu_btns: Array = []
var _menu_active := false
signal _menu_done(value)

func _init() -> void:
	name = "BattleView"

# ================================================================== entry
func run(fight_key: String, o: Dictionary = {}) -> String:
	lv = get_parent()
	key = fight_key
	fdef = D.FIGHTS[key]
	cinematic = fdef.get("boss", false)
	speed = 1.0 if cinematic else 0.7
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
	})
	if auto_play and OS.get_environment("AUTO_LOSE") != "":
		for p in b.party:
			p["hp"] = 1
		for id in b.bags: b.bags[id] = { "beer": 0, "bowl": 0 }
		b.emergency_given = true
		b.used67 = true
	_make_sounds()
	_save_state()
	_place(party_units, o.get("enemies", []), o.get("center", null))
	if "skorn" in ids:
		_spawn_pile()   # real stuff for Skorn's Throw Anything (Asar: throw objects, not words)
	_build_ui()
	await _intro()
	var res := await _loop()
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
	center = c
	var np := party_units.size()
	for i in np:
		var u: Unit = party_units[i]
		var k: String = b.party[i]["key"]
		nodes[k] = u
		spots[k] = center - right * (1.9 + i * 1.15) + fwd * (0.55 if i % 2 == 1 else 0.0)
	var ne := enemy_nodes.size()
	for i in ne:
		var k: String = b.enemies[i]["key"]
		nodes[k] = enemy_nodes[i]
		if giant:
			spots[k] = center + right * 4.6 + fwd * 1.8
		else:
			spots[k] = center + right * (1.9 + i * 1.15) + fwd * (0.55 if i % 2 == 1 else 0.0)
	for k in nodes:
		var u: Unit = nodes[k]
		base_tint[k] = u.get_meta("tint") if u.has_meta("tint") else Color.WHITE
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
	sounds["shi"] = lv._sfx(load("res://assets/voices/lykor/on_some_type_shit.mp3"), linear_to_db(maxf(Game.voice_vol, 0.01)))   # Asar's Lykor take (same file as his Mart line), at the Voice volume

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
	banner.anchor_left = 0.5; banner.anchor_right = 0.5; banner.anchor_top = 0.32
	banner.offset_left = -600; banner.offset_right = 600
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner.modulate.a = 0.0
	root.add_child(banner)

	enemy_box = VBoxContainer.new()
	enemy_box.anchor_left = 1.0; enemy_box.anchor_right = 1.0
	enemy_box.offset_left = -330; enemy_box.offset_right = -18; enemy_box.offset_top = 92
	enemy_box.add_theme_constant_override("separation", 6)
	root.add_child(enemy_box)
	for e in b.enemies:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		var nm := lv._label("%s %s" % [e["name"], e["tag"]], Vector2.ZERO, 17, Color("#ffcf9a"), 5)
		col.add_child(nm)
		var hp := _bar(RED, Vector2(300, 14))
		hp.max_value = e["max_hp"]
		hp.value = e["hp"]
		col.add_child(hp)
		var st := _status_row(14)
		col.add_child(st)
		enemy_box.add_child(col)
		ebars[e["key"]] = { "hp": hp, "st": st, "name": nm, "col": col }

	party_box = HBoxContainer.new()
	party_box.anchor_top = 1.0; party_box.anchor_bottom = 1.0
	party_box.offset_left = 18; party_box.offset_top = -138; party_box.offset_bottom = -40
	party_box.add_theme_constant_override("separation", 8)
	root.add_child(party_box)
	for p in b.party:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(196, 0)
		card.add_theme_stylebox_override("panel", _box(Color(0.06, 0.05, 0.12, 0.88), Color(1, 1, 1, 0.15), 2))
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
		col.add_child(lv._label(p["name"] if p["id"] != "chief" else "The Chief", Vector2.ZERO, 16, GOLD, 4))
		var hp_lbl := lv._label("", Vector2.ZERO, 12, Color(1, 1, 1, 0.85), 3)
		col.add_child(hp_lbl)
		var hp := _bar(GREEN, Vector2(120, 10))
		hp.max_value = p["max_hp"]
		col.add_child(hp)
		var meter := _bar(Color("#ffb13a"), Vector2(120, 7))
		meter.max_value = 100
		col.add_child(meter)
		var st := _status_row(12)
		col.add_child(st)
		party_box.add_child(card)
		pbars[p["key"]] = { "hp": hp, "hp_lbl": hp_lbl, "meter": meter, "st": st, "card": card }

	menu_panel = PanelContainer.new()
	menu_panel.anchor_left = 1.0; menu_panel.anchor_right = 1.0; menu_panel.anchor_top = 1.0; menu_panel.anchor_bottom = 1.0
	menu_panel.offset_left = -400; menu_panel.offset_right = -18; menu_panel.offset_bottom = -40
	menu_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	menu_panel.add_theme_stylebox_override("panel", _box(Color(0.06, 0.045, 0.11, 0.94), GOLD, 3))
	var mcol := VBoxContainer.new()
	mcol.add_theme_constant_override("separation", 2)
	menu_panel.add_child(mcol)
	menu_title = lv._label("", Vector2.ZERO, 19, GOLD, 5)
	mcol.add_child(menu_title)
	menu_list = VBoxContainer.new()
	menu_list.add_theme_constant_override("separation", 0)
	mcol.add_child(menu_list)
	menu_desc = lv._label("", Vector2.ZERO, 14, Color(1, 1, 1, 0.75), 3)
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

func _update_hint() -> void:
	hint.text = "W/S choose · E select · Q back · T timed hits: %s" % ("AUTO" if Game.timed_auto else "MANUAL")

func _box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 8; sb.content_margin_bottom = 8
	return sb

func _bar(color: Color, sz: Vector2) -> ProgressBar:
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
	pb.add_theme_stylebox_override("background", bg)
	return pb

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
		create_tween().tween_property(pb["hp"], "value", p["hp"], 0.3)
		pb["hp_lbl"].text = "%s %d/%d" % [p["P"]["hp_label"], p["hp"], p["max_hp"]]
		create_tween().tween_property(pb["meter"], "value", p["meter"], 0.3)
		pb["meter"].tooltip_text = p["P"]["meter_label"]
		_set_status(pb["st"], _status_chips(p) if p["hp"] > 0 else [["KNOCKED OUT", "Out cold. A Beezy or a Chipotle Bowl from Items brings them back.", false]])
		var fill: StyleBoxFlat = pb["meter"].get_theme_stylebox("fill")
		fill.bg_color = Color("#fff07a") if p["meter"] >= 100 else Color("#ffb13a")
		pb["card"].modulate = Color(1, 1, 1, 1) if p["hp"] > 0 else Color(0.6, 0.6, 0.6, 0.8)
	for e in b.enemies:
		var eb: Dictionary = ebars[e["key"]]
		create_tween().tween_property(eb["hp"], "value", e["hp"], 0.35)
		var chips := _status_chips(e)
		if e.get("eat_pending", false): chips.push_front(["HOLDING A CHIPOTLE BOWL", "He's about to eat it and heal. Stun or charm him first and he drops it.", false])
		if e.get("sit_pending", false): chips.push_front(["GETTING READY TO SIT", "He sits on someone next turn. Stun or charm him first and he sits on his own foot.", false])
		_set_status(eb["st"], chips)
		eb["col"].modulate = Color(1, 1, 1, 1) if e["hp"] > 0 else Color(1, 1, 1, 0.35)
	_timeline()

# ---- status chips: each status is its own word you can hover to see what it does
func _status_chips(u: Dictionary) -> Array:   # [[label, description, good], ...]
	var out := []
	for k in u["st"]:
		if D.STATUS.has(k):
			out.append([D.STATUS[k]["label"], D.STATUS[k]["desc"], D.STATUS[k]["good"]])
	if u.get("defending", false): out.append(["DEFENDING", "Bracing. Takes half damage, but enemies usually go after them.", true])
	if u.get("tripping", false): out.append(["TRIPPING", "Moves can misfire (22%), but sometimes land a Tweak Crit for double damage.", false])
	if u["side"] == "party" and b.hype > 0: out.append(["HYPED ×%d" % b.hype, "The party's next %d attacks hit 50%% harder." % b.hype, true])
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
		var l := lv._label(c[0], Vector2.ZERO, row.get_meta("size"), GREEN if c[2] else PURPLE, 3)
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
		status_tip.add_theme_stylebox_override("panel", _box(Color(0.08, 0.06, 0.12, 0.97), GOLD, 2))
		status_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_tip.z_index = 20
		var tc := VBoxContainer.new()
		tc.add_theme_constant_override("separation", 2)
		status_tip.add_child(tc)
		tc.add_child(lv._label("", Vector2.ZERO, 18, GOLD, 4))
		var d := lv._label("", Vector2.ZERO, 15, Color.WHITE, 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(260, 0)
		tc.add_child(d)
		root.add_child(status_tip)
	var tc: VBoxContainer = status_tip.get_child(0)
	tc.get_child(0).text = chip[0]
	tc.get_child(0).add_theme_color_override("font_color", GREEN if chip[2] else PURPLE)
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

func _timeline() -> void:
	for c in timeline.get_children():
		c.queue_free()
	var pv := b.preview(8)
	for i in pv.size():
		var u: Dictionary = pv[i]["u"]
		var pc := PanelContainer.new()
		var sz := 54 if i == 0 else 42
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.6)
		sb.border_color = GOLD if u["side"] == "party" else RED
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

# ================================================================== flow
func _intro() -> void:
	await lv.wait(0.9 * speed)
	for k in nodes:
		var u: Unit = nodes[k]
		u.global_position = spots[k]
		u.remove_meta("goal")
		u.set_view("front")
		u.sprite.flip_h = b.enemies.any(func(e): return e["key"] == k)
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
	await _recover(u)

func _choose(u: Dictionary) -> Dictionary:
	if auto_play:
		await lv.wait(0.4)
		return _auto_action(u)
	while true:
		var opts := []
		var mv: Dictionary = u["moves"]
		opts.append({ "text": "Attack: " + mv["main"]["name"], "desc": mv["main"]["desc"], "v": "main" })
		for slot in ["special", "bonus", "extra"]:
			if not mv.has(slot):
				continue
			var cd: int = u["cds"].get(slot, 0)
			var label: String = { "special": "Special", "bonus": "Bonus", "extra": "New" }[slot]
			opts.append({ "text": "%s: %s%s" % [label, mv[slot]["name"], "  (ready in %d)" % cd if cd > 0 else ""], "desc": mv[slot]["desc"], "v": slot, "off": cd > 0 })
		if u["meter"] >= 100:
			opts.append({ "text": "ULTIMATE: " + mv["ult"]["name"], "desc": mv["ult"]["desc"], "v": "ult", "hot": true })
		else:
			opts.append({ "text": "Ultimate: %s  (%d%%)" % [mv["ult"]["name"], u["meter"]], "desc": "Fill %s to 100 by dealing damage, landing timed hits and taking hits. " % u["P"]["meter_label"] + mv["ult"]["desc"], "v": "ult", "off": true })
		var combos := b.combos_for(u)
		if not combos.is_empty():
			opts.append({ "text": "Team-Up!", "desc": "Spend meter with a friend for a combo move.", "v": "combo", "hot": true })
		var nb := b.item_count(u["id"], "beer")
		var nw := b.item_count(u["id"], "bowl")
		opts.append({ "text": "Items  (Beezy %d · Bowl %d)" % [nb, nw], "desc": "Heal or revive someone with %s's own items." % u["name"], "v": "item", "off": nb + nw == 0 })
		opts.append({ "text": "Defend", "desc": "Half damage, enemies aim at you, cooldowns tick faster, +meter.", "v": "defend" })
		if not b.talk_options(u).is_empty():
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
					var t = await _pick_target(b.party, true)
					if t != null: act = { "type": "move", "slot": pick, "target": t }
				else:
					var t = await _pick_target(b.alive(b.enemies), false)
					if t != null: act = { "type": "move", "slot": pick, "target": t }
			"combo":
				var copts := []
				for c in combos:
					copts.append({ "text": "%s (%d meter each)" % [c["name"], c["cost"]], "desc": c["desc"], "v": c })
				var c = await _menu("Team-Up", copts, true)
				if c != null:
					var t = b.alive(b.enemies)[0] if c.get("aoe", false) else await _pick_target(b.alive(b.enemies), false)
					if t != null: act = { "type": "combo", "combo": c, "target": t }
			"item":
				var iopts := []
				for k in ["beer", "bowl"]:
					if b.item_count(u["id"], k) > 0:
						iopts.append({ "text": "%s ×%d" % [D.ITEMS[k]["name"], b.item_count(u["id"], k)], "desc": D.ITEMS[k]["desc"], "v": k })
				var it = await _menu("Items", iopts, true)
				if it != null:
					var t = await _pick_target(b.party, true)
					if t != null: act = { "type": "item", "item": it, "target": t }
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

func _auto_action(u: Dictionary) -> Dictionary:
	var foes := b.alive(b.enemies)
	var t: Dictionary = foes[0]
	for f in foes:
		if f["hp"] < t["hp"]: t = f
	for p in b.party:
		if p["hp"] < p["max_hp"] * 0.3:
			if b.item_count(u["id"], "bowl") > 0: return { "type": "item", "item": "bowl", "target": p }
			if b.item_count(u["id"], "beer") > 0: return { "type": "item", "item": "beer", "target": p }
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
	for box in [party_box, enemy_box, menu_panel]:
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
	for box in [party_box, enemy_box, menu_panel]:
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
	var it := b.enemy_plan(e)
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
		block = await _timed(tn if not aoe else nodes[b.alive(b.party)[0]["key"]], "block")
		await _play(b.enemy_resolve(e, it, block))
		await lv.wait(0.15)
		var tw2 := create_tween()
		tw2.tween_property(n, "global_position", home, 0.25 * speed)
		await tw2.finished
	else:
		lv.hop(n, 0.3)
		await _play(b.enemy_resolve(e, it, ""))
	_point(actor_marker, null)

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
			sfx(ev.get("sound", "hit"))
			flash_unit(n, Color(2.5, 2.5, 2.5), 0.12)
			_kick(n)
			_float(n, "-%d" % ev["amt"], Color("#ffd27a") if not q else Color("#ffe8b0"), 1.0 if not q else 0.8)
			if ev.get("label", "") != "":
				_float(n, ev["label"], GREEN if ev["label"] == "PERFECT!" else Color.WHITE, 0.8, 0.6)
			if ev.get("shake", false): lv.shake = 0.5
			await lv.wait((0.22 if q else 0.65) * speed)
		"hurt":
			sfx("hit", 0.8)
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
			sfx("heal")
			lv.hop(n, 0.4)
			await lv.wait(1.0 * speed)
		"ko":
			sfx("low")
			lv.knock(n, -80.0, 0.35)
			flash_unit(n, Color(0.55, 0.55, 0.6), 99.0)
			_say("%s is knocked out!" % ev["u"]["name"])
			await lv.wait(0.9 * speed)
		"meter_full":
			sfx("ready")
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
			_float(_node(ev["target"]), D.ITEMS[ev["item"]]["name"], Color("#8ad8ff"), 0.8, 0.5)
			sfx("gulp")
			await lv.wait(0.4)
		"chaos":
			var c: Dictionary = ev["c"]
			flash(0.5, Color(0.8, 0.6, 1.0))
			_say(c["title"])
			await _banner("CHAOS EVENT", PURPLE, 1.6)
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
			_say(ev["text"])
			sfx("throw", 1.4)
			await _banner("GOT AWAY", Color("#8ad8ff"), 1.2)
		"dice":
			_say(ev["text"])
			await _show_dice(ev["rolls"])

# ------------------------------------------------------------------ little effects
func _say(text: String) -> void:
	log_lbl.text = text

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
		bt.mouse_entered.connect(func(): _menu_sel = i; _render_menu())
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

func _render_menu() -> void:
	for i in _menu_btns.size():
		var o: Dictionary = _menu_opts[i]
		var bt: Button = _menu_btns[i]
		var col := Color.WHITE
		if o.get("off", false): col = Color(1, 1, 1, 0.35)
		elif o.get("hot", false): col = Color("#fff07a")
		if i == _menu_sel: col = GOLD if not o.get("off", false) else Color(0.9, 0.75, 0.3, 0.5)
		bt.text = ("> " if i == _menu_sel else "   ") + o["text"]
		bt.add_theme_color_override("font_color", col)
		bt.add_theme_color_override("font_hover_color", col)
		bt.add_theme_color_override("font_pressed_color", col)
	menu_desc.text = _menu_opts[_menu_sel].get("desc", "") if not _menu_opts.is_empty() else ""
	menu_desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP

func _confirm_menu() -> void:
	var o: Dictionary = _menu_opts[_menu_sel]
	if o.get("off", false):
		sfx("miss")
		return
	sfx("select")
	_menu_done.emit(o["v"])

func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_T:
		Game.timed_auto = not Game.timed_auto
		_update_hint()
		lv.show_toast("Timed hits: %s" % ("AUTO" if Game.timed_auto else "MANUAL"))
		get_viewport().set_input_as_handled()
		return
	if _menu_active:
		if ev.is_action_pressed("move_forward") or ev.is_action_pressed("ui_up"):
			_menu_sel = (_menu_sel + _menu_opts.size() - 1) % _menu_opts.size()
			sfx("move"); _render_menu()
		elif ev.is_action_pressed("move_back") or ev.is_action_pressed("ui_down"):
			_menu_sel = (_menu_sel + 1) % _menu_opts.size()
			sfx("move"); _render_menu()
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
func _pick_target(list: Array, allies: bool):
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

func _show_dice(rolls: Array) -> void:
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
	for k in 9:
		sfx("dice", 1.0 + k * 0.05)
		for l in faces:
			l.text = str(randi_range(1, 6))
		await lv.wait(0.07)
	for i in rolls.size():
		faces[i].text = str(rolls[i])
		faces[i].add_theme_color_override("font_color", Color("#c0392b") if rolls[i] in [1, 6] else Color(0.1, 0.08, 0.1))
	sfx("bonk", 0.7)
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
		Game.set_count(id, "beer", b.bags[id]["beer"])
		Game.set_count(id, "bowl", b.bags[id]["bowl"])
	Game.used67 = b.used67
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
	var l := lv._label(text, Vector2.ZERO, size, color, 5)
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
	tip.add_theme_stylebox_override("panel", _box(Color(0.08, 0.06, 0.12, 0.97), GOLD, 2))
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip.z_index = 10
	var tc := VBoxContainer.new()
	tc.add_theme_constant_override("separation", 2)
	tip.add_child(tc)
	tc.add_child(lv._label(G.get("name", gear_id), Vector2.ZERO, 20, GOLD, 4))
	tc.add_child(lv._label(G.get("slot", "trinket").capitalize(), Vector2.ZERO, 14, Color(1, 1, 1, 0.6), 3))
	var d := lv._label(G.get("desc", ""), Vector2.ZERO, 15, Color.WHITE, 3)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	tc.add_child(d)
	for s in InventoryUI.gear_stat_lines(G):
		tc.add_child(lv._label("• " + s, Vector2.ZERO, 15, Color("#7dff8a"), 3))
	tc.add_child(lv._label("Equip it in your inventory (Tab)", Vector2.ZERO, 13, Color(1, 1, 1, 0.55), 3))
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
	var xp: int = int(round(fdef["xp"] * (1.0 if res == "win" else 0.5)))
	var ups := Game.add_xp(xp)
	if not ups.is_empty(): knocked_out.clear()   # level up refilled everyone
	var gold := fight_gold(fdef, res)
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
	panel.offset_left = -330; panel.offset_right = 330; panel.offset_top = -190; panel.offset_bottom = 190
	panel.add_theme_stylebox_override("panel", _box(Color(0.05, 0.04, 0.1, 0.95), GOLD, 3))
	root.add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var line := func(text: String, size: int, color: Color) -> void:
		var l := lv._label(text, Vector2.ZERO, size, color, 5)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(620, 0)
		col.add_child(l)
	if res == "win":
		line.call("VICTORY!!!", 44, GOLD)
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
		line.call("LEVEL UP! The trio is now Level %d. (+10%% HP and damage, everyone fully healed)" % lvn, 20, GREEN)
		lv.play_sound("sfx_reward", -2.0)
		if lvn == 3:
			line.call("New moves: Belly Bump · Conditioner Mist · Citation Needed", 18, Color("#fff07a"))
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
	panel.pivot_offset = Vector2(330, 190)
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
