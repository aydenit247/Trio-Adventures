extends Control
class_name JobBoardUI

# The village Job Board as a real screen (Asar): a wooden board with paper notes pinned to it.
# Click a note (or arrows + E) to read it up close. Real jobs have a "Take job" button that starts the quest.
# Esc / Tab / Q closes. Opened from village_buildings.gd ("job_board" action) with:  await JobBoardUI.show_board(lv, vb)

signal closed

const R = preload("res://scripts/village_rooms_script.gd")
const W := 980.0
const H := 600.0
const INK := Color("#2b1d10")
const GOLD := Color("#e8b923")

# The postings. text = what's written on it. job = quest id it starts (real jobs only). spoon = just a drawing of a spoon.
const NOTES := [
	{ "head": "WANTED", "text": "Goblin. Must be a goblin.\nPay: no." }, # DRAFT (from the old board lines)
	{ "spoon": true },
	{ "head": "HELP WANTED", "text": "at the Metocy Mart.\nMust not ask questions. Must not ask about the questions.\n— D.F." }, # DRAFT
	{ "head": "LOST: LUCKY SPOON", "text": "VERY LUCKY. REWARD.\nSEE GRUBNIK\n(I'm right here.)", "job": "lucky_spoon" }, # DRAFT
	{ "head": "BODYGUARD NEEDED", "text": "for the Diddy Chud Giant's nap.\nPay: you get to live." }, # DRAFT
	{ "head": "CHALLENGERS WANTED", "text": "Think your little lore book beats my prophecies?\nShaman's Tent.\n— Wuzzle", "job": "lore_off" }, # DRAFT
	{ "spoon": true },
	{ "head": "CAN YOU HOLD YOUR BEEZY?", "text": "Prove it. The bar.\n— Gulpo\n(undefeated)", "job": "chug_rematch" }, # DRAFT
]
# Where each job sends you (shown after you take it)
const JOB_WHERE := {
	"lucky_spoon": "Talk to Grubnik, he's standing right by the board.",
	"lore_off": "Head into the Shaman's Tent.",
	"chug_rematch": "Gulpo is in the Unemployment Office & Bar.",
}

var lv: Node
var vb: Node
var root: Control
var board: Control
var cards: Array = []       # Panel per note
var sel := 0
var reading := -1           # note index shown up close, -1 = board view
var close_up: Control
var taken := ""             # quest id taken this visit (the caller follows up, e.g. Grubnik talks)
var _opened_at := 0
var _font: Font
var _hand: Font

static func show_board(level: Node, buildings: Node) -> void:
	level.busy = true
	level.freeze_all(true)
	var ui := JobBoardUI.new()
	ui.lv = level
	ui.vb = buildings
	level.hud.add_child(ui)
	ui._build()
	if level.shots_mode:   # automated tour: show it, read Grubnik's note, close
		await level.wait(1.0)
		await level.shot("b_01_board_ui")
		ui._open(3)
		await level.wait(0.6)
		await level.shot("b_01b_board_note")
		ui._close_note()
		var job0 := ui.taken
		ui.close()
		level.freeze_all(false)
		level.busy = false
		return
	await ui.closed
	var job := ui.taken
	level.freeze_all(false)
	if job == "lucky_spoon":   # Grubnik heard you take his posting
		await level.run_nested(R.GRUBNIK_ASK)
	elif job != "":
		level.show_toast("Job taken: %s. %s" % [R.QUESTS[job][0], JOB_WHERE.get(job, "")], 3.0)
	if not Game.flag("boardRead"):
		Game.set_flag("boardRead")
		await level.run_nested([R.JOB_BOARD.back()])   # Xylo: "The economy here is in shambles."
	level.busy = false

func _build() -> void:
	_opened_at = Engine.get_process_frames()
	MenuUI.stack.append(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cz := FontVariation.new()
	cz.base_font = load("res://assets/fonts/Cinzel.ttf")
	cz.variation_embolden = 0.6
	_font = cz
	_hand = ThemeDB.fallback_font
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = InventoryUI.BLUR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	dim.material = mat
	add_child(dim)

	root = Control.new()
	root.anchor_left = 0.5; root.anchor_right = 0.5; root.anchor_top = 0.5; root.anchor_bottom = 0.5
	root.offset_left = -W / 2; root.offset_right = W / 2; root.offset_top = -H / 2; root.offset_bottom = H / 2
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# the board: dark wood frame, planks inside
	board = Control.new()
	board.size = Vector2(W, H)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.draw.connect(_draw_board)
	root.add_child(board)
	var title := _lbl("JOB BOARD", 34, Color("#ffdf8a"), _font, 8)
	title.position = Vector2(0, 14); title.size = Vector2(W, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var keys := _lbl("Click a note to read it  ·  Esc: close", 15, Color(1, 1, 1, 0.75), null, 4)
	keys.position = Vector2(0, H - 34); keys.size = Vector2(W, 20)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(keys)

	var rng := RandomNumberGenerator.new()
	rng.seed = 1122
	var cols := 4
	for i in NOTES.size():
		var n: Dictionary = NOTES[i]
		var c := Panel.new()
		var sz := Vector2(rng.randf_range(184, 198), rng.randf_range(214, 228))
		c.size = sz
		c.pivot_offset = sz * 0.5
		var cell := Vector2(80 + (i % cols) * 214, 78 + int(i / cols) * 248)
		c.position = cell + Vector2(rng.randf_range(-10, 10), rng.randf_range(-6, 12))
		c.rotation = rng.randf_range(-0.08, 0.08)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		c.add_theme_stylebox_override("panel", _paper(Color("#e9dcb8") * rng.randf_range(0.9, 1.0)))
		var idx := i
		c.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: _open(idx))
		c.mouse_entered.connect(func(): sel = idx; _refresh())
		root.add_child(c)
		cards.append(c)
		_fill_note(c, n, false)
	_refresh()

func _fill_note(c: Control, n: Dictionary, big: bool) -> void:
	var pad := 14.0 if not big else 30.0
	if n.get("spoon", false):   # "Most of the postings are just pictures of spoons."
		var t := TextureRect.new()
		t.texture = load("res://assets/items/spoon.png")
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(pad, pad + 6); t.size = c.size - Vector2(pad * 2, pad * 2 + 6)
		t.modulate = Color(0.45, 0.35, 0.25, 0.85)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(t)
	else:   # heading + body stacked, wrapped to the paper's width
		var box := VBoxContainer.new()
		box.position = Vector2(pad, pad + 6)
		box.custom_minimum_size = Vector2(c.size.x - pad * 2, 0)
		box.size = Vector2(c.size.x - pad * 2, c.size.y - pad * 2)
		box.add_theme_constant_override("separation", 8 if not big else 18)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(box)
		var hd := _lbl(n["head"], 16 if not big else 30, INK, _font, 0)
		hd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hd.custom_minimum_size = Vector2(c.size.x - pad * 2, 0)
		hd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hd)
		var body := _lbl(n["text"], 13 if not big else 24, INK.lightened(0.15), _hand, 0)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(c.size.x - pad * 2, 0)
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(body)
	var job: String = n.get("job", "")
	if job != "":
		var st := Game.quest_state(job)
		var stamp := _lbl("DONE" if st == "done" else ("TAKEN" if st != "" else "JOB"), 14 if not big else 22,
			Color("#3a8a3a") if st == "done" else (Color("#b03020") if st != "" else Color("#2a5aa0")), _font, 0)
		stamp.position = Vector2(c.size.x - (70 if not big else 120), c.size.y - (30 if not big else 48))
		stamp.rotation = -0.18
		c.add_child(stamp)
	# the pin
	var pin := Control.new()
	pin.position = Vector2(c.size.x * 0.5, 8)
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.draw.connect(func():
		pin.draw_circle(Vector2(2, 3), 7, Color(0, 0, 0, 0.35))
		pin.draw_circle(Vector2.ZERO, 7, Color("#c0392b"))
		pin.draw_circle(Vector2(-2, -2), 2.5, Color(1, 1, 1, 0.6)))
	c.add_child(pin)

func _refresh() -> void:
	for i in cards.size():
		var c: Panel = cards[i]
		c.scale = Vector2.ONE * (1.06 if i == sel and reading < 0 else 1.0)
		c.z_index = 1 if i == sel else 0

# ---- reading one note up close
func _open(i: int) -> void:
	if reading >= 0:
		return
	reading = i
	sel = i
	lv.ui_sfx.play()
	close_up = Control.new()
	close_up.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_up.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_up.add_child(shade)
	add_child(close_up)
	var n: Dictionary = NOTES[i]
	var p := Panel.new()
	p.size = Vector2(440, 440)
	p.position = get_viewport_rect().size * 0.5 - p.size * 0.5 - Vector2(0, 30)
	p.pivot_offset = p.size * 0.5
	p.rotation = cards[i].rotation * 0.5
	p.add_theme_stylebox_override("panel", _paper(Color("#efe3c2")))
	close_up.add_child(p)
	_fill_note(p, n, true)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.position = Vector2(p.position.x, p.position.y + p.size.y + 22)
	row.size = Vector2(p.size.x, 46)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	close_up.add_child(row)
	var job: String = n.get("job", "")
	if job != "" and Game.quest_state(job) == "":
		var take := _button("Take job")
		take.pressed.connect(func(): _take(job))
		row.add_child(take)
		take.grab_focus()
	var back := _button("Back")
	back.pressed.connect(_close_note)
	row.add_child(back)
	if row.get_child_count() == 1:
		back.grab_focus()

func _close_note() -> void:
	if close_up:
		close_up.queue_free()
		close_up = null
	reading = -1
	_refresh()

func _take(job: String) -> void:
	taken = job
	if job != "lucky_spoon":   # Grubnik's starts when he talks to you (his dialogue starts the quest)
		if job == "lore_off":
			Game.set_flag("loreOffOpen")
		Game.start_quest(job, R.QUESTS[job][0], R.QUESTS[job][1])
	lv.ui_sfx.play()
	close()

# ---- input
func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self:
		return
	if Engine.get_process_frames() - _opened_at < 2:
		return
	if not ev.is_pressed() or ev.is_echo() or ev is InputEventMouse:
		return
	var cancel: bool = ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("party_menu") \
		or ev.is_action_pressed("switch") or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B)
	if reading >= 0:
		if cancel:
			_close_note()
			get_viewport().set_input_as_handled()
		return   # buttons handle E / Enter / clicks themselves
	if cancel:
		close()
	elif ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
		_open(sel)
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("move_right"):
		sel = (sel + 1) % cards.size(); _refresh()
	elif ev.is_action_pressed("ui_left") or ev.is_action_pressed("move_left"):
		sel = (sel - 1 + cards.size()) % cards.size(); _refresh()
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
		sel = mini(sel + 4, cards.size() - 1); _refresh()
	elif ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
		sel = maxi(sel - 4, 0); _refresh()
	else:
		return
	get_viewport().set_input_as_handled()

func close() -> void:
	if not is_inside_tree():
		return
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)

# ---- drawing + helpers
func _draw_board() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(W, H))
	board.draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.5))
	board.draw_rect(r, Color("#3b2614"))
	var inner := r.grow(-26)
	var plank_h := inner.size.y / 6.0
	for k in 6:
		var c := Color("#6b4626").lerp(Color("#5a3a1f"), float(k % 2)) * (0.92 + 0.08 * sin(k * 2.3))
		board.draw_rect(Rect2(inner.position + Vector2(0, k * plank_h), Vector2(inner.size.x, plank_h - 2)), c)
		board.draw_line(inner.position + Vector2(0, (k + 1) * plank_h - 1), inner.position + Vector2(inner.size.x, (k + 1) * plank_h - 1), Color(0, 0, 0, 0.35), 2.0)
	for p in [inner.position + Vector2(10, 10), inner.position + Vector2(inner.size.x - 10, 10), inner.end - Vector2(10, 10), Vector2(inner.position.x + 10, inner.end.y - 10)]:
		board.draw_circle(p, 5, Color("#8a8a8a"))
	board.draw_rect(r, Color("#24170b"), false, 6.0)

func _paper(c: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(3, 4)
	return sb

func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_font_override("font", _font)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#3b2614") if st == "normal" else Color("#5a3a1f")
		sb.border_color = GOLD if st != "normal" else Color("#8a6a3a")
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", Color("#ffdf8a"))
	return b

func _lbl(text: String, size: int, color: Color, font: Font, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
