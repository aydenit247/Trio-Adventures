# ScrapbookUI: Library → Scrapbook (Ebain 11/24). A page for every story outcome (progress_data.gd, the ones with
# "story" = true): what you did, the choice you picked, and the line said right after it (with its recording).
# Outcomes you haven't found show "???" and a hint. Unlocks are the same saved ones as the title's Outcomes x/N.
# The choice text and quoted lines are read from the dialogue scripts (ScriptScan), never copied here.
#   ScrapbookUI.open(ui_canvas_layer)  →  await page.closed
class_name ScrapbookUI
extends Control

signal closed

# [section title, outcome id prefix, note shown in that section]
const SECTIONS := [
	["The Goblin Throne", "village_", ""],
	["The Bridge Troll", "troll_", ""],
	["Metocy Mart", "mart_", ""],
	["The Rat Colony", "rats_", "A side path: the Old Ruins, off the road by the Metocy Mart."],
	["The Mountain Pass", "pass_", ""],
	["Dulbers' Ambush", "ambush_", "Only happens on runs where Dulbers got away from the Mart."],
	["The Wizard's Lair", "castle_", ""],
]
# Hints for outcomes you haven't found yet. All # DRAFT: Ebain rewrites these.
const HINTS := {
	"village_speech": "Lykor has a way with words. Allegedly.",
	"village_chug": "The Chief looks thirsty. Are you?",
	"village_skorn_king": "Every throne needs a king. Does it have to be Lykor?",
	"village_sneak": "Who says you have to stay?",
	"village_negotiate": "Skorn has a very persuasive hand.",
	"troll_good": "Be nice to the troll.",
	"troll_bad": "Be rude to the troll.",
	"mart_everyone": "Sharing is caring.",
	"mart_skorn_first": "Somebody has to go first.",
	"mart_refuse": "Just say no. Dulbers will take it well. Probably.",
	"mart_xylo": "Xylo has read about this. Xylo has read about everything.",
	"mart_goblins": "Goblins will eat anything.",
	"rats_fight": "The rats look tough. They are not.",
	"rats_king": "The colony needs a new king. Skorn is available.",
	"rats_trade": "Rats love a business deal.",
	"rats_lore": "The Rat King thinks he knows lore. Xylo knows more lore.",
	"rats_mog": "Rats have eyes. Lykor has a jawline.",
	"pass_midtocy": "Got something to throw?",
	"pass_sneak": "Tiptoe. Do NOT breathe.",
	"pass_lore": "Nothing puts a giant to sleep like a good book.",
	"pass_fight": "What if you just... didn't sneak?",
	"pass_bogdrinker": "Family talks family down.",
	"ambush_apologize": "Dulbers wants respect. Give him a LOT of it.",
	"ambush_fight": "He's not that big anymore.",
	"ambush_fentocy": "Dulbers is a businessman. Make him an offer.",
	"ambush_mattias": "Somebody up the mountain could help.",
	"castle_bet": "Mattias is offering. Just say yes.",
	"castle_too": "Don't party alone.",
	"castle_bad": "One word. Starts with B.",
	"castle_punch": "Violence is always an option.",
	"castle_bowl": "Everything is better in a Chipotle Bowl.",
}
# The secret page (DELOYE_PLAN.md): its own section at the very end, "???" until you've found the library.
# Not a story outcome, so it isn't in the "x / N moments" count or the 100 completion points.
const SECRET_ID := "deloye_found"
const SECRET_HINT := "Flush."   # DRAFT
const SECRET_TEXT := "Five lost pages. One outhouse. One flush. A library full of lore about nothing, and the guy who wrote it, spinning in the middle."   # DRAFT

var entries: Array = []      # [{ id, title, section }]
var sel := 0
var _rows: Array = []
var list: VBoxContainer
var scroll: ScrollContainer
var page: VBoxContainer
var player: AudioStreamPlayer
var _at := 0
const P := UITheme.PARCHMENT   # the scrapbook is always a paper book

static func open(parent: Node) -> ScrapbookUI:
	var s := ScrapbookUI.new()
	parent.add_child(s)
	s._build()
	s._pen()
	return s

# (Ebain's sfx pack) a second of pen on paper when the Scrapbook opens
func _pen() -> void:
	if DisplayServer.get_name() == "headless" or not ResourceLoader.exists("res://assets/sounds/sfx_pen.ogg"):
		return
	var a := AudioStreamPlayer.new()
	a.stream = load("res://assets/sounds/sfx_pen.ogg")
	a.volume_db = -14.0
	a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(a)
	a.play()
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.9)
	tw.tween_property(a, "volume_db", -60.0, 0.4)
	tw.tween_callback(a.queue_free)

static func story_items() -> Array:
	return ProgressData.ITEMS.filter(func(it): return it[3])

static func found_count() -> int:
	return story_items().filter(func(it): return Game.progress.has(it[0])).size()

func _build() -> void:
	for sec in SECTIONS:
		for it in story_items():
			if String(it[0]).begins_with(sec[1]):
				entries.append({ "id": it[0], "title": it[1], "section": sec[0], "note": sec[2] })
	var secret_got: bool = Game.progress.has(SECRET_ID)
	entries.append({ "id": SECRET_ID, "title": "Found the Deloye Lore library", "section": "The Deloye Lore Library" if secret_got else "? ? ?", "note": "", "secret": true })
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var book := PanelContainer.new()
	book.add_theme_stylebox_override("panel", UITheme.panel(0.99, P))
	book.anchor_left = 0.5; book.anchor_right = 0.5; book.anchor_top = 0.5; book.anchor_bottom = 0.5
	book.offset_left = -500; book.offset_right = 500; book.offset_top = -315; book.offset_bottom = 315
	add_child(book)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	book.add_child(v)
	var t := UITheme.lbl("SCRAPBOOK", 30, "accent", UITheme.head_font(), P)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := UITheme.lbl("%d / %d moments found" % [found_count(), story_items().size()], 16, "dim", null, P)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	scroll = ScrollContainer.new()   # left page: the list
	scroll.custom_minimum_size.x = 380
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	var spine := ColorRect.new()   # the book's spine
	spine.color = Color(UITheme.c("edge2", P), 0.6)
	spine.custom_minimum_size.x = 2
	h.add_child(spine)
	page = VBoxContainer.new()     # right page: the moment
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# (Ebain 11/24: "scrapbook is not scrollable") without a width, the page's autowrap labels measured one letter per
	# line, the book grew ~2700 px tall off the screen and the list never needed to scroll. Give the page its width.
	page.custom_minimum_size.x = 520
	page.add_theme_constant_override("separation", 10)
	h.add_child(page)
	var hint := UITheme.lbl("W/S or ↑/↓ choose · E play the line · Esc back", 13, "faint", null, P)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var last_sec := ""
	for i in entries.size():
		var e: Dictionary = entries[i]
		if e["section"] != last_sec:
			last_sec = e["section"]
			var hd := UITheme.lbl(last_sec.to_upper(), 15, "accent", UITheme.head_font(), P)
			hd.custom_minimum_size.y = 30
			hd.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			list.add_child(hd)
		var got: bool = Game.progress.has(e["id"])
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_PASS   # PASS, not STOP: the mouse wheel has to reach the ScrollContainer
		var l := UITheme.lbl(e["title"] if got else "? ? ?", 17, "text" if got else "faint", UITheme.row_font(), P)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		var idx := i
		row.gui_input.connect(func(ev):
			if UITheme.hover_moved(ev) and sel != idx:
				sel = idx
				_render()
			elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				sel = idx
				_render())
		list.add_child(row)
		_rows.append(row)
	player = AudioStreamPlayer.new()
	player.volume_db = linear_to_db(maxf(Game.voice_vol, 0.01))
	add_child(player)
	MenuUI.stack.append(self)
	_at = Engine.get_process_frames()
	UITheme.play("page")
	_render()
	book.size = Vector2(1000, 630)
	UITheme.pop_in(book)
	_resettle(book)

# The first layout measures the autowrap labels at width 0 (very tall), the book grows to fit, and a Control never
# shrinks back by itself, so the list had nothing to scroll. Put the book back to its real size once it's laid out.
func _resettle(book: Control) -> void:
	for i in 2:
		await get_tree().process_frame
	if not is_instance_valid(book):
		return
	book.offset_left = -500; book.offset_right = 500; book.offset_top = -315; book.offset_bottom = 315
	book.size = Vector2(1000, 630)

func _render() -> void:
	for i in _rows.size():
		_rows[i].add_theme_stylebox_override("panel", UITheme.row(i == sel, P))
	if sel < _rows.size():
		scroll.ensure_control_visible.call_deferred(_rows[sel])
	for c in page.get_children():
		c.queue_free()
	if entries.is_empty():
		return
	var e: Dictionary = entries[sel]
	var got: bool = Game.progress.has(e["id"])
	page.add_child(UITheme.lbl(e["section"].to_upper(), 14, "dim", UITheme.head_font(), P))
	var title := UITheme.lbl(e["title"] if got else "? ? ?", 26, "text", UITheme.row_font(), P)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(title)
	var dv := ColorRect.new()
	dv.color = Color(UITheme.c("edge2", P), 0.7)
	dv.custom_minimum_size = Vector2(0, 1)
	page.add_child(dv)
	if not got:
		var hl := UITheme.lbl("Hint: " + (SECRET_HINT if e.get("secret", false) else HINTS.get(e["id"], "Try a different choice.")), 18, "dim", null, P)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(hl)
		if e["note"] != "":
			var nl := UITheme.lbl(e["note"], 15, "faint", null, P)
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			page.add_child(nl)
		return
	if e.get("secret", false):   # the secret page: its own text + Deloye's first words
		var st := UITheme.lbl(SECRET_TEXT, 18, "text", null, P)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(st)
		page.add_child(UITheme.lbl("Deloye", 16, "accent", UITheme.row_font(), P))
		var dq := UITheme.lbl(_first_deloye_line(), 19, "text", null, P)
		dq.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(dq)
		return
	var info := ScriptScan.outcome(e["id"])
	if info.get("choice", "") != "":
		page.add_child(UITheme.lbl("You picked", 15, "dim", UITheme.row_font(), P))
		var ch := UITheme.lbl("“%s”" % info["choice"], 20, "accent", null, P)
		ch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(ch)
	if info.get("line", "") != "":
		var gap := Control.new()
		gap.custom_minimum_size.y = 8
		page.add_child(gap)
		var qrow := HBoxContainer.new()
		qrow.add_theme_constant_override("separation", 10)
		page.add_child(qrow)
		qrow.add_child(UITheme.lbl(info["name"], 16, "accent", UITheme.row_font(), P))
		if info["path"] != "":
			var b := UITheme.button("Play", 14)
			b.pressed.connect(_play)
			qrow.add_child(b)
		var q := UITheme.lbl(info["line"], 19, "text", null, P)
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(q)

func _first_deloye_line() -> String:
	for st in load("res://scripts/deloye_script.gd").PASS:   # (Ebain's script 11/25: "You could pass that shit?")
		if st.get("who", "") == "deloye":
			return st["line"]
	return ""

func _play() -> void:
	var e: Dictionary = entries[sel]
	if not Game.progress.has(e["id"]) or e.get("secret", false):
		UITheme.play("back")
		return
	var info := ScriptScan.outcome(e["id"])
	if info.get("path", "") != "":
		player.stream = load(info["path"])
		player.play()

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
		return
	if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
		return
	var handled := true
	if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
		sel = maxi(sel - 1, 0); UITheme.key_nav(); UITheme.play("move"); player.stop(); _render()
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
		sel = mini(sel + 1, entries.size() - 1); UITheme.key_nav(); UITheme.play("move"); player.stop(); _render()
	elif ev.is_action_pressed("ui_accept") or ev.is_action_pressed("interact"):
		_play()
	elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause") or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		player.stop()
		UITheme.play("back")
		MenuUI.stack.erase(self)
		closed.emit()
		queue_free()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)
