# One menu panel that works the same everywhere (title, pause, settings, save/load, confirm boxes):
# keyboard (W/S or arrows, A/D change, E/Enter/Space pick, Esc back), controller (stick/d-pad, A pick, B back)
# and mouse (hover to select, click to pick, click left/right half of an option to change it).
#
#   var m := MenuUI.open(parent_canvas_layer, "PAUSED", rows, { "w": 620 })
#   rows = [ { "text": "Resume", "pick": func(): ... },
#            { "text": func(): return "Volume:  < %d%% >" % v, "change": func(d): ... },
#            { "text": "Load", "pick": ..., "enabled": func(): return has_save } ]
#   await m.closed            # emitted when the menu goes away (Esc/B or m.close())
extends Control
class_name MenuUI

signal closed

const GOLD := Color("#e8b923")
static var stack: Array = []      # open menus, top one gets input

var rows: Array = []
var sel := 0
var labels: Array = []
var hint_lbl: Label
var note_lbl: Label
var on_back: Callable             # what Esc/B does (default: close)
var base_note := ""               # shown when the selected row has no note of its own
var sfx: AudioStreamPlayer
var _opened_at := 0
var panel: PanelContainer

static func open(parent: Node, title: String, the_rows: Array, opts := {}) -> MenuUI:
	var m := MenuUI.new()
	parent.add_child(m)
	m._build(title, the_rows, opts)
	return m

func _build(title: String, the_rows: Array, opts: Dictionary) -> void:
	rows = the_rows
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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.11, opts.get("panel_alpha", 0.96))
	sb.border_color = GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 28; sb.content_margin_right = 28; sb.content_margin_top = 18; sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	if title != "":
		col.add_child(_lbl(title, 30, GOLD, 6))
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 4)
		col.add_child(gap)
	for i in rows.size():
		var l := _lbl("", opts.get("font", 23), Color.WHITE, 5)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := i
		l.mouse_entered.connect(func():
			if _enabled(idx) and sel != idx:
				sel = idx
				_render()
		)
		l.gui_input.connect(func(ev): _row_click(idx, l, ev))
		col.add_child(l)
		labels.append(l)
	note_lbl = _lbl("", 15, Color("#c9c0e8"), 3)
	note_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_lbl.visible = false
	col.add_child(note_lbl)
	hint_lbl = _lbl(opts.get("hint", "W/S or ↑/↓ choose · A/D change · E pick · Esc back · mouse works too"), 14, Color(1, 1, 1, 0.5), 3)
	col.add_child(hint_lbl)
	sfx = AudioStreamPlayer.new()
	sfx.stream = Util.chime(990.0, 180, 0.2)
	sfx.volume_db = -12.0
	add_child(sfx)
	sel = 0
	while sel < rows.size() - 1 and not _enabled(sel):
		sel += 1
	_render()
	stack.append(self)
	_opened_at = Engine.get_process_frames()

func _lbl(text: String, size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	return l

func _enabled(i: int) -> bool:
	var e = rows[i].get("enabled", true)
	return e.call() if e is Callable else bool(e)

func _text(i: int) -> String:
	var t = rows[i].get("text", "")
	return t.call() if t is Callable else str(t)

func _render() -> void:
	for i in rows.size():
		var on := i == sel
		labels[i].text = ("›  " if on else "    ") + _text(i)
		var c := GOLD if on else Color.WHITE
		if not _enabled(i):
			c = Color(1, 1, 1, 0.35)
		labels[i].add_theme_color_override("font_color", c)
	var n = rows[sel].get("note", "") if rows.size() > 0 else ""
	n = n.call() if n is Callable else n
	if n == "":
		n = base_note
	note_lbl.text = n
	note_lbl.visible = n != ""
	_recenter.call_deferred()

# keep the panel centred on its anchor as rows/notes change height
func _recenter() -> void:
	if not is_instance_valid(panel):
		return
	var h := panel.get_combined_minimum_size().y
	panel.offset_top = -h / 2.0
	panel.offset_bottom = h / 2.0

func refresh() -> void:
	_render()

func set_note(text: String) -> void:
	base_note = text
	_render()

func _exit_tree() -> void:
	stack.erase(self)

func close() -> void:
	stack.erase(self)
	closed.emit()
	queue_free()

func _move(d: int) -> void:
	for k in rows.size():
		sel = (sel + d + rows.size()) % rows.size()
		if _enabled(sel):
			break
	sfx.pitch_scale = 1.0
	sfx.play()
	_render()

func _pick() -> void:
	if not _enabled(sel):
		return
	sfx.pitch_scale = 1.25
	sfx.play()
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
		sfx.pitch_scale = 1.1
		sfx.play()
		r["change"].call(d)
		_render()

func _row_click(i: int, l: Label, ev: InputEvent) -> void:
	if not (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		return
	if stack.is_empty() or stack.back() != self or not _enabled(i):
		return
	sel = i
	if rows[i].has("change") and not rows[i].has("pick"):
		_change(-1 if ev.position.x < l.size.x * 0.5 else 1)
	else:
		_pick()
	accept_event()

func _input(ev: InputEvent) -> void:
	if stack.is_empty() or stack.back() != self or not visible:
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
		if on_back.is_valid():
			on_back.call()
		else:
			close()
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
	m.note_lbl.add_theme_font_size_override("font_size", 20)
	m.note_lbl.add_theme_color_override("font_color", Color("#f3e3b0"))
	m.sel = 1
	m.set_note(question)
	await m.closed
	return box["yes"]

static func open_settings(parent: Node) -> MenuUI:
	var CombatD = load("res://scripts/combat/combat_data.gd")
	var pct := func(v: float) -> String: return "%d%%" % roundi(v * 100.0)
	var changed := func():
		Game.apply_settings()
		Game.save_settings()
	var rows := [
		{ "text": func(): return "Volume:  < %s >" % pct.call(Game.master_vol),
		  "change": func(d): Game.master_vol = clampf(snappedf(Game.master_vol + d * 0.1, 0.1), 0.0, 1.0); changed.call() },
		{ "text": func(): return "Voice volume:  < %s >" % pct.call(Game.voice_vol),
		  "change": func(d): Game.voice_vol = clampf(snappedf(Game.voice_vol + d * 0.1, 0.1), 0.0, 1.0); changed.call() },
		{ "text": func(): return "Voices:  < %s >" % ("ON" if Game.tts_on else "OFF"),
		  "change": func(_d):
				Game.tts_on = not Game.tts_on
				var lv = parent.get_tree().current_scene
				if lv and "dialogue" in lv and lv.dialogue:
					lv.dialogue.tts_on = Game.tts_on
				changed.call() },
		{ "text": func(): return "Music:  < %s >" % ("Play once" if Game.music_once else "Loop"),
		  "change": func(_d): Game.music_once = not Game.music_once; changed.call(),
		  "note": "Play once: an area's song plays through one time, then it's quiet until you come back." },
		{ "text": func(): return "Text speed:  < %s >" % Game.TEXT_SPEED[Game.text_speed],
		  "change": func(d): Game.text_speed = (Game.text_speed + d + 4) % 4; changed.call() },
		{ "text": func(): return "Dialogue buffer:  < %s >" % Game.DLG_BUFFER[Game.dlg_buffer],
		  "change": func(d): Game.dlg_buffer = (Game.dlg_buffer + d + 4) % 4; changed.call(),
		  "note": "How long a line must be on screen before E moves to the next one. Stops mashing through jokes." },
		{ "text": func(): return "Go back (Backspace):  < %s >" % ("ON" if Game.dlg_back else "OFF"),
		  "change": func(_d): Game.dlg_back = not Game.dlg_back; changed.call(),
		  "note": "Backspace replays the previous line. It can't go back past a choice or a scene event." },
		{ "text": func(): return "Speed mode:  < %s >" % ("ON" if Game.dlg_speed else "OFF"),
		  "change": func(_d): Game.dlg_speed = not Game.dlg_speed; changed.call(),
		  "note": "Spam E to skip and text types 2x faster. Also a button on the dialogue box." },
		{ "text": func(): return "Window:  < %s >" % ("Fullscreen" if Game.fullscreen else "Windowed"),
		  "change": func(_d): Game.fullscreen = not Game.fullscreen; changed.call(),
		  "note": "Tip: F11 or Alt+Enter switches anytime." },
		{ "text": func(): return "VSync:  < %s >" % ("ON" if Game.vsync else "OFF"),
		  "change": func(_d): Game.vsync = not Game.vsync; changed.call(),
		  "note": "ON = smooth, no tearing. OFF = a bit less input lag." },
		{ "text": func(): return "Graphics:  < %s >" % Game.QUALITY[Game.quality],
		  "change": func(d): Game.quality = (Game.quality + d + 3) % 3; changed.call(),
		  "note": "Low turns off fog, soft shadows and ambient shading and renders at 75% — use it on laptops." },
		{ "text": func(): return "Camera turn speed:  < %s >" % pct.call(Game.cam_speed),
		  "change": func(d): Game.cam_speed = clampf(snappedf(Game.cam_speed + d * 0.2, 0.2), 0.4, 2.0); changed.call() },
		{ "text": func(): return "Combat difficulty:  < %s >" % CombatD.DIFFICULTY[Game.difficulty]["label"],
		  "change": func(d): Game.difficulty = (Game.difficulty + d + 3) % 3; changed.call() },
		{ "text": func(): return "Timed hits:  < %s >" % ("AUTO" if Game.timed_auto else "MANUAL"),
		  "change": func(_d): Game.timed_auto = not Game.timed_auto; changed.call(),
		  "note": "MANUAL: press E when the ring lines up. AUTO: hits and blocks land on their own." },
	]
	var box := { "m": null }
	rows.append({ "text": "Back", "pick": func(): box["m"].close() })
	box["m"] = open(parent, "SETTINGS", rows, { "w": 700, "font": 21 })
	return box["m"]

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
