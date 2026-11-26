# One menu panel that works the same everywhere (title, pause, settings, save/load, confirm boxes):
# keyboard (W/S or arrows, A/D change, E/Enter/Space pick, Esc back), controller (stick/d-pad, A pick, B back)
# and mouse (hover to select, click to pick, click left/right half of an option to change it).
# Looks come from UITheme (ui_theme.gd): ornate panel, glowing selected row, bounce + sounds. Restyles live on Game.ui_changed.
#
#   var m := MenuUI.open(parent_canvas_layer, "PAUSED", rows, { "w": 620 })
#   rows = [ { "text": "Resume", "pick": func(): ... },
#            { "text": func(): return "Volume:  < %d%% >" % v, "change": func(d): ... },   # "Name:  < value >" shows as name + ‹ value ›
#            { "text": "Music", "value": func(): return "80%", "change": ... },          # or give the value directly
#            { "text": "Load", "pick": ..., "enabled": func(): return has_save },
#            { "text": "Song", "icon": func(): return "play", "side": { "text": "Lyrics", "pick": func(): ... } } ]  # side: L / Y
#            optional second button "side2" (same shape): K / controller X
#   row "arrows": false hides the ‹ › around the value even when the row has "change" (Library songs)
#   opts: w, title, font (row size), dim, dim_alpha, panel_alpha, anchor_x/y, hint, footer (a Control under the rows), silent
#   await m.closed            # emitted when the menu goes away (Esc/B or m.close())
extends Control
class_name MenuUI

signal closed

const GOLD := Color("#e8b923")
static var stack: Array = []      # open menus, top one gets input

var rows: Array = []
var sel := 0
var labels: Array = []            # each row's name Label
var hint_lbl: Label
var note_lbl: Label
var on_back: Callable             # what Esc/B does (default: close)
var base_note := ""               # shown when the selected row has no note of its own
var _opened_at := 0
var panel: PanelContainer
var title_lbl: Label
var _rows_ui: Array = []          # per row: { panel, name, val, la, ra, icon, side, side2 }
var _opts := {}
var _font := 23.0
var _shown := false
var _note_size := 15.0
var _note_color: Variant = "note"
var _dividers: Array = []
var _last_sel := -1

static var _pair := RegEx.create_from_string("^(.*?):\\s+<\\s*(.*?)\\s*>$")

static func open(parent: Node, title: String, the_rows: Array, opts := {}) -> MenuUI:
	var m := MenuUI.new()
	parent.add_child(m)
	m._build(title, the_rows, opts)
	return m

func _build(title: String, the_rows: Array, opts: Dictionary) -> void:
	rows = the_rows
	_opts = opts
	_font = float(opts.get("font", 23))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)   # (plain set_anchors_preset leaves us 0×0 when added first)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if opts.get("dim", true):
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, opts.get("dim_alpha", 0.55))
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
	var w: float = opts.get("w", 640.0)
	panel = PanelContainer.new()
	var ax: float = opts.get("anchor_x", 0.5)
	var ay: float = opts.get("anchor_y", 0.5)
	panel.anchor_left = ax; panel.anchor_right = ax; panel.anchor_top = ay; panel.anchor_bottom = ay
	panel.offset_left = -w / 2; panel.offset_right = w / 2
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	panel.add_child(col)
	if title != "":
		title_lbl = Label.new()
		title_lbl.text = title
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(title_lbl)
		var dv := UITheme.Divider.new()
		col.add_child(dv)
		_dividers.append(dv)
	for i in rows.size():
		col.add_child(_make_row(i))
	if opts.has("footer"):
		col.add_child(opts["footer"])
	note_lbl = Label.new()
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_lbl.visible = false
	col.add_child(note_lbl)
	hint_lbl = Label.new()
	hint_lbl.text = opts.get("hint", "W/S or ↑/↓ choose · A/D change · E pick · Esc back · mouse works too")
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint_lbl)
	sel = 0
	while sel < rows.size() - 1 and not _enabled(sel):
		sel += 1
	_last_sel = sel
	_restyle()
	Game.ui_changed.connect(_restyle)
	stack.append(self)
	_opened_at = Engine.get_process_frames()
	if not opts.get("silent", false):
		UITheme.play("page")

func _make_row(i: int) -> Control:
	var rp := PanelContainer.new()
	rp.mouse_filter = Control.MOUSE_FILTER_STOP
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rp.add_child(hb)
	var nl := Label.new()
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(nl)
	var la := UITheme.Icon.new("left", 13)
	var val := Label.new()
	val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ra := UITheme.Icon.new("right", 13)
	hb.add_child(la); hb.add_child(val); hb.add_child(ra)
	var ic: UITheme.Icon = null
	if rows[i].has("icon"):
		ic = UITheme.Icon.new("play", 18)
		hb.add_child(ic)
	var side: Button = null
	if rows[i].has("side"):
		side = UITheme.button(str(rows[i]["side"].get("text", "More")), 15)
		side.pressed.connect(func(): _side(i))
		hb.add_child(side)
	var side2: Button = null
	if rows[i].has("side2"):
		side2 = UITheme.button(str(rows[i]["side2"].get("text", "More")), 15)
		side2.pressed.connect(func(): _side(i, "side2"))
		hb.add_child(side2)
	var idx := i
	rp.gui_input.connect(func(ev): _row_click(idx, rp, ev))
	labels.append(nl)
	_rows_ui.append({ "panel": rp, "content": hb, "name": nl, "val": val, "la": la, "ra": ra, "icon": ic, "side": side, "side2": side2 })
	return rp

func _restyle() -> void:
	if not is_instance_valid(panel):
		return
	panel.add_theme_stylebox_override("panel", UITheme.panel(_opts.get("panel_alpha", 0.96)))
	if title_lbl:
		UITheme.style_lbl(title_lbl, 30, "accent", UITheme.head_font())
	for r in _rows_ui:
		UITheme.style_lbl(r["name"], _font, "text", UITheme.row_font())
		UITheme.style_lbl(r["val"], _font * 0.92, "text", UITheme.row_font())
		r["val"].custom_minimum_size.x = UITheme.fs(_font * 4.2)
		for k in ["side", "side2"]:
			if r[k]:
				UITheme.style_button(r[k], _font * 0.66)
	UITheme.style_lbl(note_lbl, _note_size, _note_color)
	UITheme.style_lbl(hint_lbl, 13, "faint")
	_reserve_note()
	for d in _dividers:
		d.queue_redraw()
	_render()

# Keep room for the tallest note, so the panel doesn't change height (and slide rows under the mouse) as you move.
func _reserve_note() -> void:
	var font: Font = note_lbl.get_theme_font("font")
	var size: int = note_lbl.get_theme_font_size("font_size")
	var w: float = maxf(float(_opts.get("w", 640.0)) - 72.0, 200.0)
	var tallest := 0.0
	for t in [base_note] + rows.map(func(r): var n = r.get("note", ""); return str(n.call() if n is Callable else n)):
		if str(t) != "":
			tallest = maxf(tallest, font.get_multiline_string_size(str(t), HORIZONTAL_ALIGNMENT_CENTER, w, size).y)
	note_lbl.custom_minimum_size.y = ceilf(tallest) + 4.0 if tallest > 0.0 else 0.0

func _enabled(i: int) -> bool:
	var e = rows[i].get("enabled", true)
	return e.call() if e is Callable else bool(e)

func _text(i: int) -> String:
	var t = rows[i].get("text", "")
	return t.call() if t is Callable else str(t)

func _on_top() -> bool:
	return not stack.is_empty() and stack.back() == self

func _render() -> void:
	for i in rows.size():
		var on := i == sel
		var en := _enabled(i)
		var r: Dictionary = _rows_ui[i]
		var nm := _text(i)
		var v := ""
		if rows[i].has("value"):
			var vv = rows[i]["value"]
			v = str(vv.call() if vv is Callable else vv)
		else:
			var m := _pair.search(nm)
			if m:
				nm = m.get_string(1)
				v = m.get_string(2)
		r["name"].text = nm
		r["val"].text = v
		r["val"].visible = v != ""
		var arrows: bool = v != "" and rows[i].has("change") and rows[i].get("arrows", true)
		var c := UITheme.c("accent") if on else UITheme.c("text")
		if not en:
			c = UITheme.c("faint")
		r["name"].add_theme_color_override("font_color", c)
		r["val"].add_theme_color_override("font_color", UITheme.c("accent") if on and en else (UITheme.c("dim") if en else UITheme.c("faint")))
		for a in ["la", "ra"]:
			r[a].visible = arrows
			r[a].set_kind(r[a].kind, Color(UITheme.c("accent"), 1.0 if on else 0.35))
		if r["icon"]:
			var k = rows[i]["icon"]
			k = k.call() if k is Callable else k
			r["icon"].visible = str(k) != ""
			r["icon"].set_kind(str(k), c)
		for k in ["side", "side2"]:
			if r[k]:
				var se = rows[i][k].get("enabled", true)
				r[k].disabled = not (se.call() if se is Callable else bool(se))
		r["panel"].add_theme_stylebox_override("panel", UITheme.row(on))
	if sel != _last_sel and sel < _rows_ui.size():
		UITheme.bounce(_rows_ui[sel]["content"])   # the content hops, the row's mouse area stays put
		if _shown:
			UITheme.play("move")
		_last_sel = sel
	var n = rows[sel].get("note", "") if rows.size() > 0 else ""
	n = n.call() if n is Callable else n
	if n == "":
		n = base_note
	note_lbl.text = n
	note_lbl.visible = n != "" or note_lbl.custom_minimum_size.y > 0.0
	_recenter.call_deferred()

# keep the panel centred on its anchor as rows/notes change height
func _recenter() -> void:
	if not is_instance_valid(panel):
		return
	var sz := panel.get_combined_minimum_size()
	var w: float = maxf(float(_opts.get("w", 640.0)), sz.x)
	panel.offset_left = -w / 2.0
	panel.offset_right = w / 2.0
	panel.offset_top = -sz.y / 2.0
	panel.offset_bottom = sz.y / 2.0
	if not _shown:
		_shown = true
		panel.size = Vector2(w, sz.y)
		UITheme.pop_in(panel)

func refresh() -> void:
	_render()

func set_note(text: String) -> void:
	base_note = text
	if text != "":
		_reserve_note()
	_render()

# confirm boxes: a bigger, warmer note
func big_note(size := 20.0) -> void:
	_note_size = size
	_note_color = "text"
	_restyle()

func _exit_tree() -> void:
	stack.erase(self)

func close() -> void:
	stack.erase(self)
	closed.emit()
	queue_free()

func _move(d: int) -> void:
	UITheme.key_nav()
	for k in rows.size():
		sel = (sel + d + rows.size()) % rows.size()
		if _enabled(sel):
			break
	_render()

func _pick() -> void:
	if not _enabled(sel):
		return
	UITheme.play("pick")
	UITheme.squash(_rows_ui[sel]["content"])
	var r: Dictionary = rows[sel]
	if r.has("pick"):
		r["pick"].call()
	elif r.has("change"):
		r["change"].call(1)
	if is_instance_valid(self) and not is_queued_for_deletion():
		_render()

func _change(d: int) -> void:
	var r: Dictionary = rows[sel]
	if r.has("change") and _enabled(sel):
		UITheme.play("move", 1.15 if d > 0 else 0.9)
		r["change"].call(d)
		if is_instance_valid(self) and not is_queued_for_deletion():
			_render()
			var ui: Dictionary = _rows_ui[sel]
			UITheme.bounce(ui["val"], 0.12)

func _side(i: int, key := "side") -> void:
	if not _on_top() or not rows[i].has(key):
		return
	var s: Dictionary = rows[i][key]
	var se = s.get("enabled", true)
	if not (se.call() if se is Callable else bool(se)):
		return
	UITheme.play("pick")
	s["pick"].call()

func _back() -> void:
	UITheme.play("back")
	if on_back.is_valid():
		on_back.call()
	else:
		close()

func _row_click(i: int, row: Control, ev: InputEvent) -> void:
	if UITheme.hover_moved(ev):   # real mouse movement only (see UITheme.hover_moved)
		if _enabled(i) and sel != i and _on_top():
			sel = i
			_render()
		return
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if not _on_top() or not _enabled(i):
		return
	sel = i
	if rows[i].has("change") and not rows[i].has("pick"):
		_change(-1 if ev.position.x < row.size.x * 0.5 else 1)
	else:
		_pick()
	accept_event()

func _input(ev: InputEvent) -> void:
	if not _on_top() or not visible:
		return
	if Engine.get_process_frames() - _opened_at < 2:   # the key press that opened us
		return
	if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
		return
	var handled := true
	if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
		_move(-1)
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
		_move(1)
	elif ev.is_action_pressed("ui_left") or ev.is_action_pressed("move_left"):
		_change(-1)
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("move_right"):
		_change(1)
	elif ev.is_action_pressed("ui_accept") or ev.is_action_pressed("interact"):
		_pick()
	elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause"):
		_back()
	elif rows.size() > 0 and rows[sel].has("side") and ((ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_L) \
			or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_Y)):
		_side(sel)
	elif rows.size() > 0 and rows[sel].has("side2") and ((ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_K) \
			or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_X)):
		_side(sel, "side2")
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- shared menus

# Yes/No box. Returns true for yes.
static func confirm(parent: Node, question: String, yes := "Yes", no := "No") -> bool:
	var box := { "yes": false, "m": null }
	var m := open(parent, "", [
		{ "text": yes, "pick": func(): box["yes"] = true; box["m"].close() },
		{ "text": no, "pick": func(): box["m"].close() },
	], { "w": 560, "hint": "E pick · Esc cancel" })
	box["m"] = m
	m.big_note()
	m.sel = 1
	m.set_note(question)
	await m.closed
	return box["yes"]

# Settings: a list of sections, each opens its own page (Ebain 11/24 UI overhaul).
static func open_settings(parent: Node) -> MenuUI:
	var box := { "m": null }
	var sub := func(page: Callable):
		var top: MenuUI = box["m"]
		top.visible = false
		var s: MenuUI = page.call(parent)
		await s.closed
		if is_instance_valid(top):
			top.visible = true
			top.refresh()
	var rows := [
		{ "text": "Audio", "pick": func(): await sub.call(_settings_audio), "note": "Volume for music, sound effects and voices." },
		{ "text": "Display & UI", "pick": func(): await sub.call(_settings_display), "note": "Menu theme, UI size, text size, window and graphics." },
		{ "text": "Dialogue", "pick": func(): await sub.call(_settings_dialogue), "note": "Text speed, the E buffer, going back a line, dialogue speed." },
		{ "text": "Gameplay", "pick": func(): await sub.call(_settings_gameplay), "note": "Camera, combat difficulty, timed hits, battle speed." },
		{ "text": "Controls", "pick": func(): await sub.call(_settings_controls), "note": "Change the keyboard keys. The controller layout stays the same." },
		{ "text": "Back", "pick": func(): box["m"].close() },
	]
	box["m"] = open(parent, "SETTINGS", rows, { "w": 520, "font": 24 })
	return box["m"]

static func _changed() -> void:
	Game.apply_settings()
	Game.save_settings()

static func _pct(v: float) -> String:
	return "%d%%" % roundi(v * 100.0)

static func _page(parent: Node, title: String, rows: Array, w := 700.0) -> MenuUI:
	var box := { "m": null }
	rows.append({ "text": "Back", "pick": func(): box["m"].close() })
	box["m"] = open(parent, title, rows, { "w": w, "font": 21 })
	return box["m"]

static func _vol_row(label: String, prop: String, note := "") -> Dictionary:
	return { "text": label, "value": func(): return _pct(Game.get(prop)), "note": note,
		"change": func(d): Game.set(prop, clampf(snappedf(Game.get(prop) + d * 0.1, 0.1), 0.0, 1.0)); _changed() }

static func _settings_audio(parent: Node) -> MenuUI:
	return _page(parent, "AUDIO", [
		_vol_row("Master volume", "master_vol"),
		_vol_row("Music", "music_vol", "Title song, area songs and the Library."),
		_vol_row("Sound effects", "sfx_vol", "Fights, doors, coins, menus, ambience."),
		_vol_row("Voice volume", "voice_vol", "Recorded lines and the robot voice."),
		{ "text": "Voices", "value": func(): return "ON" if Game.tts_on else "OFF",
		  "change": func(_d):
				Game.tts_on = not Game.tts_on
				var lv = parent.get_tree().current_scene
				if lv and "dialogue" in lv and lv.dialogue:
					lv.dialogue.tts_on = Game.tts_on
				_changed() },
		{ "text": "Area music", "value": func(): return "Play once" if Game.music_once else "Loop",
		  "change": func(_d): Game.music_once = not Game.music_once; _changed(),
		  "note": "Play once: an area's song plays through one time, then it's quiet until you come back." },
	])

static func _settings_display(parent: Node) -> MenuUI:
	return _page(parent, "DISPLAY & UI", [
		{ "text": "Menu theme", "value": func(): return UITheme.NAMES[Game.ui_theme],
		  "change": func(d): Game.ui_theme = (Game.ui_theme + d + UITheme.NAMES.size()) % UITheme.NAMES.size(); _changed(),
		  "note": "Gold & Night · Parchment · Wizard Arcane. Changes every menu right away." },
		{ "text": "UI size", "value": func(): return _pct(Game.ui_scale),
		  "change": func(d): Game.ui_scale = clampf(snappedf(Game.ui_scale + d * 0.05, 0.05), 0.8, 1.3); _changed(),
		  "note": "Scales every menu, the HUD and the dialogue box. Bigger = easier on a TV." },
		{ "text": "Text size", "value": func(): return _pct(Game.text_scale),
		  "change": func(d): Game.text_scale = clampf(snappedf(Game.text_scale + d * 0.05, 0.05), 0.85, 1.3); _changed(),
		  "note": "Menu text on its own, on top of UI size." },
		{ "text": "Menu animations", "value": func(): return "Bouncy" if Game.ui_bouncy else "Calm",
		  "change": func(_d): Game.ui_bouncy = not Game.ui_bouncy; _changed(),
		  "note": "Bouncy: menu rows hop when you pick them. Calm: no motion." },
		{ "text": "Window", "value": func(): return "Fullscreen" if Game.fullscreen else "Windowed",
		  "change": func(_d): Game.fullscreen = not Game.fullscreen; _changed(),
		  "note": "Tip: F11 or Alt+Enter switches anytime." },
		{ "text": "VSync", "value": func(): return "ON" if Game.vsync else "OFF",
		  "change": func(_d): Game.vsync = not Game.vsync; _changed(),
		  "note": "ON = smooth, no tearing. OFF = a bit less input lag." },
		{ "text": "Graphics", "value": func(): return Game.QUALITY[Game.quality],
		  "change": func(d): Game.quality = (Game.quality + d + 3) % 3; _changed(),
		  "note": "Low turns off fog, soft shadows and ambient shading and renders at 75% — use it on laptops." },
	])

static func _settings_dialogue(parent: Node) -> MenuUI:
	return _page(parent, "DIALOGUE", [
		{ "text": "Text speed", "value": func(): return Game.TEXT_SPEED[Game.text_speed],
		  "change": func(d): Game.text_speed = (Game.text_speed + d + 4) % 4; _changed() },
		{ "text": "Dialogue buffer", "value": func(): return Game.DLG_BUFFER[Game.dlg_buffer],
		  "change": func(d): Game.dlg_buffer = (Game.dlg_buffer + d + 4) % 4; _changed(),
		  "note": "How long a line must be on screen before E moves to the next one. Stops mashing through jokes." },
		{ "text": "Go back (Backspace)", "value": func(): return "ON" if Game.dlg_back else "OFF",
		  "change": func(_d): Game.dlg_back = not Game.dlg_back; _changed(),
		  "note": "Backspace replays the previous line. It can't go back past a choice or a scene event." },
		{ "text": "Dialogue speed", "value": func(): return "%sx" % str(snappedf(Game.dlg_speed, 0.01)),
		  "change": func(d): Game.dlg_speed = clampf(Game.dlg_speed + d * 0.25, Game.DLG_SPEED_MIN, Game.DLG_SPEED_MAX); _changed(),
		  "note": "Voices and text, 0.5x to 3x (voices keep their pitch). Also a slider on the dialogue box." },
	])

static func _settings_gameplay(parent: Node) -> MenuUI:
	var CombatD = load("res://scripts/combat/combat_data.gd")
	return _page(parent, "GAMEPLAY", [
		{ "text": "Camera turn speed", "value": func(): return _pct(Game.cam_speed),
		  "change": func(d): Game.cam_speed = clampf(snappedf(Game.cam_speed + d * 0.2, 0.2), 0.4, 2.0); _changed() },
		{ "text": "Combat difficulty", "value": func(): return CombatD.DIFFICULTY[Game.difficulty]["label"],
		  "change": func(d): Game.difficulty = (Game.difficulty + d + 3) % 3; _changed() },
		{ "text": "Timed hits", "value": func(): return "AUTO" if Game.timed_auto else "MANUAL",
		  "change": func(_d): Game.timed_auto = not Game.timed_auto; _changed(),
		  "note": "MANUAL: press E when the ring lines up. AUTO: hits and blocks land on their own." },
		{ "text": "Battle speed", "value": func(): return Game.BATTLE_SPEED[Game.battle_speed][0],
		  "change": func(d): Game.battle_speed = clampi(Game.battle_speed + d, 0, Game.BATTLE_SPEED.size() - 1); _changed(),
		  "note": "How fast attacks, pauses and fight text play out. Timed-hit rings stay the same speed." },
	])

static func _settings_controls(parent: Node) -> MenuUI:
	var box := { "m": null }
	var rows := []
	for a in Keybinds.ACTIONS:
		var act: String = a[0]
		rows.append({ "text": a[1],
			"value": func(): return "press a key…" if box.get("wait") == act else Keybinds.key_name(Keybinds.key_of(act)),
			"pick": func(): _capture_key(box, act),
			"note": "E to change, then press the new key (Esc cancels). Space and Enter always work too." if act == "interact" else "E to change, then press the new key (Esc cancels)." })
	rows.append({ "text": "Reset to defaults", "pick": func():
		Keybinds.reset_all()
		Game.save_settings()
		box["m"].set_note("Keys reset.") })
	box["m"] = _page(parent, "CONTROLS", rows, 640.0)
	return box["m"]

# Wait for one key press, then bind it. A tiny node on top of MenuUI.stack eats the input meanwhile.
static func _capture_key(box: Dictionary, act: String) -> void:
	var m: MenuUI = box["m"]
	var cap := KeyCapture.new()
	box["wait"] = act
	m.add_child(cap)
	stack.append(cap)
	m.set_note("Press a key for %s…  (Esc cancels)" % act.replace("_", " "))
	var k: int = await cap.got
	stack.erase(cap)
	cap.queue_free()
	box.erase("wait")
	if not is_instance_valid(m):
		return
	if k == KEY_NONE:
		m.set_note("")
	elif k in Keybinds.RESERVED:
		m.set_note("That key is taken (Esc = pause, F1 = dev menu, F11 = fullscreen).")
	else:
		var swapped := Keybinds.set_key(act, k)
		Game.save_settings()
		m.set_note(("Swapped: %s now uses %s." % [swapped, Keybinds.key_name(Keybinds.key_of(_act_of(swapped)))]) if swapped != "" else "")
	m.refresh()

static func _act_of(label: String) -> String:
	for a in Keybinds.ACTIONS:
		if a[1] == label:
			return a[0]
	return ""

class KeyCapture extends Node:
	signal got(k: int)
	var _at := 0
	func _ready() -> void:
		_at = Engine.get_process_frames()
	func _input(ev: InputEvent) -> void:
		if Engine.get_process_frames() - _at < 2 or not (ev is InputEventKey) or not ev.pressed or ev.echo:
			return
		get_viewport().set_input_as_handled()
		var k: int = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
		got.emit(KEY_NONE if k == KEY_ESCAPE else k)

# Save / load slot list. mode = "save" or "load". lv = the current Level (needed to save).
static func open_slots(parent: Node, mode: String, lv: Node = null) -> MenuUI:
	var box := { "m": null }
	var rows := []
	for slot in Game.SLOTS:
		if mode == "save" and slot == "auto":
			continue
		var s: String = slot
		rows.append({
			"text": func():
				var d := Game.read_save(s)
				var name := "Autosave" if s == "auto" else "Slot " + s
				if d.is_empty():
					return "%s:  — empty —" % name
				var where: String = String(d.get("label", "")).split(" — ")[-1] if " — " in String(d.get("label", "")) else String(d.get("label", ""))
				return "%s:  %s · Lv %d · %s" % [name, where.left(30), int(d.get("level", 1)), Game.save_when(float(d["time"]))],
			"enabled": func(): return mode == "save" or not Game.read_save(s).is_empty(),
			"pick": func():
				if mode == "save":
					if not Game.read_save(s).is_empty():
						if not await MenuUI.confirm(parent, "Overwrite Slot %s?" % s, "Overwrite", "Cancel"):
							return
					var ok := Game.save_game(s, lv)
					box["m"].set_note(("Saved to Slot %s." % s) if ok else "Couldn't save (disk problem?).")
				else:
					box["m"].close()
					Game.load_game(s),
		})
	rows.append({ "text": "Back", "pick": func(): box["m"].close() })
	var m := open(parent, "SAVE GAME" if mode == "save" else "LOAD GAME", rows, { "w": 760, "font": 21 })
	box["m"] = m
	if mode == "save" and lv and lv.has_method("can_resume") and not lv.can_resume():
		m.set_note("You're mid-scene, so this saves from the start of this area (%s)." % String(lv.subtitle).split(" — ")[-1])
	return m
