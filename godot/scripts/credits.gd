# Credits: the end credits roll (Ebain 11/26). Same roll after every Chapter 1 ending.
# Part 1 is about THIS run: a few cards that fade in and out (the ending, each story choice you picked with the line
# said right after it, playing its recording, what else happened, your stats). Part 2 is a classic scrolling roll
# (logo, cast with portraits, crew, music, tools, thanks) timed to end with the song, stopping on "Thanks for playing".
#   await Credits.roll(level, { "ending": "party", "facts": ["Every goblin got metocy.", …] })
# Controls: E skips a run card / hold E speeds up the roll · Esc twice skips everything · E at the end continues.
# All the roll text below is # DRAFT (Ebain/Asar: edit ROLL freely, it's just data).
class_name Credits
extends CanvasLayer

signal finished

const SONG := "res://assets/music/prophecy_of_metocy.ogg"   # DRAFT pick: the title theme, played once, not looped
const MUSIC_DB := -6.0
const GOLD := Color("#e8c66a")
const CREAM := Color("#f3e3b0")
const DIM := Color(0.75, 0.7, 0.6)
const CARD_SECS := 4.2         # how long a run card stays up (longer if its voice line runs over)
const MIN_ROLL_SECS := 40.0    # the scrolling part never goes faster than this
const MAX_SPEED := 150.0       # px per second (x4 while E is held)

# One title per ending (summit.gd `ending`). # DRAFT
const ENDING_NAMES := {
	"bad": "Ending: \"Oh okay.\"",
	"cooked": "Ending: Cooked",
	"normal": "Ending: Metocy Acquired",
	"party": "Ending: Metocy For Everybody",
}
# [run card title, per-run flag way_<scene>] in story order. The text comes from ProgressData.ITEMS + ScriptScan.
const RUN_SCENES := [
	["The Goblin Throne", "village"],
	["The Bridge Troll", "troll"],
	["Metocy Mart", "mart"],
	["The Rat Colony", "rats"],
	["The Mountain Pass", "pass"],
	["Dulbers' Ambush", "ambush"],
	["The Wizard's Lair", "castle"],
]

# The roll. Entries:
#   ["logo"] · ["gap", px] · ["head", "SECTION"] · ["name", "Big Name"] · ["role", "Job", "Name"]
#   ["cast", "portrait id", "Character", "credit"] · ["note", "small italic-ish line"] · ["end"] (where the roll stops)
# DRAFT, all of it. Facts about who did what are from HANDOFF / COLLAB.
const ROLL := [
	["logo"],
	["gap", 40],
	["note", "Chapter 1"],
	["gap", 160],
	["head", "A GAME BY"],
	["name", "Ebain"],
	["gap", 50],
	["head", "CO-DEVELOPED WITH"],
	["name", "Asar"],
	["gap", 140],
	["head", "STARRING"],
	["cast", "skorn", "Skorn", "as himself"],
	["cast", "lykor", "Lykor", "as himself (and his jawline)"],
	["cast", "xylo", "Xylo", "as himself, citing sources"],
	["gap", 90],
	["head", "ALSO STARRING"],
	["cast", "mattias", "Metocin Mattias", "the wizard"],
	["cast", "dulbers", "Dulbers Frint", "Metocy Mart management"],
	["cast", "chief", "Chief Bogdrinker", "400-year chug champion"],
	["cast", "giant", "Diddy Chud", "the Giant (mostly asleep)"],
	["cast", "troll", "The Bridge Troll", "it's good"],
	["cast", "rat_king", "The Rat King", "lore enjoyer"],
	["cast", "rat_trader", "Scrounge", "rat businessman"],
	["cast", "charis", "Charis", "has a house"],
	["cast", "deloye", "Deloye", "spinning"],
	["gap", 50],
	["role", "Haggle, Grubnik, Gulpo, Wuzzle, Big Thumbs, Sludge", "the Goblin Village"],
	["role", "The Goblin Band", "drums, horn, lute"],
	["role", "Lil Nibbs", "a good boy"],
	["role", "Morgana (Bahgoots)", "the cat"],
	["role", "Dulbmeethus", "watching, 6.7% of the time"],
	["gap", 140],
	["head", "STORY & DIALOGUE"],
	["name", "Ebain"],
	["role", "Additional dialogue", "Asar"],
	["gap", 70],
	["head", "MUSIC"],
	["note", "Every song written and made by Ebain"],
	["role", "Prophecy of Metocy", "Ebain"],
	["role", "The Mogging Elf", "Ebain"],
	["role", "The Hymn of Metocin Mattias", "Ebain"],
	["role", "The Tale of Diddy Chud", "Ebain"],
	["role", "Deloye Lore", "Ebain"],
	["gap", 70],
	["head", "VOICES"],
	["role", "Narrator", "Asar"],
	["role", "Lykor & Xylo", "Asar"],
	["role", "Dulbers Frint", "Asar"],
	["role", "The Goblins", "Asar"],
	["role", "Deloye", "Ebain"],
	["role", "Voice studio (Emberstage)", "Ebain"],
	["gap", 70],
	["head", "ART"],
	["role", "Character art & cutscenes", "Ebain"],
	["role", "Item art", "Asar"],
	["role", "3D trio & props", "Asar"],
	["role", "Dulbmeethus' lightning", "Ebain"],
	["gap", 70],
	["head", "SOUND"],
	["role", "Sound effects", "Ebain & Asar"],
	["role", "Snoring", "Diddy Chud"],
	["gap", 70],
	["head", "DESIGN"],
	["role", "Story, quests & endings", "Ebain"],
	["role", "Combat", "Ebain & Asar"],
	["role", "Achievements", "Ebain"],
	["role", "Explorer bot & dialogue map", "Asar"],
	["gap", 70],
	["head", "BUILT WITH HELP FROM"],
	["role", "Code, cutouts & sounds", "Claude (Anthropic)"],
	["role", "Docs", "Grok"],
	["gap", 70],
	["head", "MADE WITH"],
	["name", "Godot Engine"],
	["note", "godotengine.org · MIT license"],
	["gap", 24],
	["role", "Models & textures", "Poly Haven (CC0)"],
	["role", "Fonts", "Cinzel, Pinyon Script (SIL OFL)"],
	["role", "3D models", "Meshy"],
	["role", "Pictures & video", "Gemini"],
	["role", "Songs", "Google Flow Music"],
	["role", "Voice cloning", "ChatterboxTTS"],
	["gap", 140],
	["head", "SPECIAL THANKS"],
	["name", "Everyone who played"],
	["note", "and the goblins, who were harmed (several)"],
	["gap", 260],
	["end"],
]

var lv: Node
var run := {}
var bg: ColorRect
var stage: Control
var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var skip_lbl: Label
var _skip_armed := 0.0
var _skipped := false
var _started_ms := 0
var _fast := false   # tours: no waiting
var _card_n := 0
var _shots := false

static func roll(level: Node, run_info: Dictionary) -> void:
	var c := Credits.new()
	c.lv = level
	c.run = run_info
	level.add_child(c)
	await c.finished
	c.queue_free()

func _ready() -> void:
	layer = 96   # over the screen fade (20) and video cutscenes (95)
	# tours and headless runs (the explorer bot) don't sit through the whole roll: a few frames and done
	_fast = (lv != null and lv.get("shots_mode") == true) or DisplayServer.get_name() == "headless"
	_shots = lv != null and lv.get("shots_mode") == true and lv.has_method("shot")
	bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	skip_lbl = _lbl("Press Esc again to skip the credits", 16, DIM)
	skip_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_lbl.position += Vector2(-360, -40)
	skip_lbl.modulate.a = 0.0
	add_child(skip_lbl)
	voice = AudioStreamPlayer.new()
	voice.volume_db = linear_to_db(maxf(Game.voice_vol, 0.001))
	add_child(voice)
	_run.call_deferred()

func _run() -> void:
	create_tween().tween_property(bg, "color:a", 1.0, 1.2)
	await _wait(1.4)
	_start_music()
	_started_ms = Time.get_ticks_msec()
	for card in _run_cards():
		if _skipped:
			break
		await _show_card(card)
	if not _skipped:
		await _scroll()
	if not _skipped and not _fast:
		await _wait_continue()
	await _close()

# ---------------------------------------------------------------- part 1: this run
func _run_cards() -> Array:
	var cards := []
	cards.append({ "big": "END OF CHAPTER 1", "sub": ENDING_NAMES.get(str(run.get("ending", "normal")), "") })
	for s in RUN_SCENES:
		var way := str(Game.flags.get("way_" + s[1], ""))
		if way == "":
			continue
		var id: String = s[1] + "_" + way
		var did := id
		for it in ProgressData.ITEMS:
			if it[0] == id:
				did = it[1]
		var info := ScriptScan.outcome(id)
		var c := { "head": s[0].to_upper(), "big": did }
		if str(info.get("line", "")) != "":
			c["quote"] = "\"%s\"" % info["line"]
			c["who"] = str(info.get("name", ""))
			c["voice"] = info["line"]
		cards.append(c)
	var facts: Array = run.get("facts", [])
	if not facts.is_empty():
		cards.append({ "head": "ALSO, THIS RUN", "lines": facts.slice(0, 8) })
	cards.append({ "head": "YOUR RUN", "stats": _stats() })
	return cards

func _stats() -> Array:
	var rows := []
	rows.append(["Level", str(Game.level)])
	rows.append(["Gold", str(Game.gold)])
	rows.append(["Gear found", str(Game.gear_owned.size())])
	rows.append(["Lost Pages", "%d / %d" % [LostPages.count(), LostPages.AREAS.size()]])
	if Game.ach:
		rows.append(["Achievements", "%d / %d" % [Game.ach.count(), Game.ach.LIST.size()]])
	rows.append(["Outcomes found", "%d / %d" % [Game.outcomes_found(), Game.outcomes_total()]])
	rows.append(["Complete", "%d%%" % Game.completion_pct()])
	rows.append(["Difficulty", ["Chill", "Normal", "Crashout"][clampi(Game.difficulty, 0, 2)]])
	return rows

func _show_card(c: Dictionary) -> void:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if c.has("head"):
		box.add_child(_center(_lbl(c["head"], 20, GOLD, UITheme.head_font(), 6)))
	if c.has("big"):
		var b := _center(_lbl(c["big"], 40 if not c.has("head") else 32, CREAM, UITheme.head_font()))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 1000
		box.add_child(b)
	if c.has("sub"):
		box.add_child(_center(_lbl(c["sub"], 22, GOLD)))
	if c.has("quote"):
		box.add_child(_gap(10))
		var q := _center(_lbl(c["quote"], 24, Color(0.92, 0.9, 0.85)))
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.custom_minimum_size.x = 900
		box.add_child(q)
		if c.get("who", "") != "":
			box.add_child(_center(_lbl("— " + c["who"], 18, DIM)))
	for l in c.get("lines", []):
		box.add_child(_center(_lbl(l, 22, Color(0.92, 0.9, 0.85))))
	if c.has("stats"):
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 60)
		g.add_theme_constant_override("v_separation", 8)
		for r in c["stats"]:
			var k := _lbl(r[0], 22, DIM)
			k.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			k.custom_minimum_size.x = 280
			g.add_child(k)
			var v := _lbl(r[1], 22, CREAM, UITheme.head_font())
			v.custom_minimum_size.x = 280
			g.add_child(v)
		var cc := CenterContainer.new()
		cc.add_child(g)
		box.add_child(cc)
	box.modulate.a = 0.0
	stage.add_child(box)
	create_tween().tween_property(box, "modulate:a", 1.0, 0.7)
	if c.has("voice"):
		var st := VoiceLines.stream_for(c["voice"])
		if st:
			voice.stream = st
			voice.play()
			_duck(true)
	if _fast:
		await _wait(0.8)
		if _shots:
			_card_n += 1
			await lv.shot("credits_card_%d" % _card_n)
	else:
		var t := 0.0
		await get_tree().process_frame
		while not _skipped:
			t += get_process_delta_time()
			if t > 0.8 and Input.is_action_just_pressed("interact"):
				break
			if t > CARD_SECS and not voice.playing:
				break
			if t > CARD_SECS + 12.0:
				break
			await get_tree().process_frame
	voice.stop()
	_duck(false)
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 0.0, 0.5)
	await tw.finished
	box.queue_free()

# ---------------------------------------------------------------- part 2: the roll
func _scroll() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(col)
	var vw := get_viewport().get_visible_rect().size
	col.custom_minimum_size.x = vw.x
	var end_node: Control = null
	for e in ROLL:
		var n := _entry(e)
		if n:
			col.add_child(n)
			if e[0] == "end":
				end_node = n
	col.position = Vector2(0, vw.y + 20)
	await get_tree().process_frame
	await get_tree().process_frame
	var stop_y := vw.y * 0.5 - (end_node.position.y + end_node.size.y * 0.5) if end_node else -col.size.y
	var dist := col.position.y - stop_y
	var left := MIN_ROLL_SECS
	if music and music.stream:   # finish the roll as the song ends (with a few seconds of the final card)
		left = maxf(MIN_ROLL_SECS, music.stream.get_length() - (Time.get_ticks_msec() - _started_ms) / 1000.0 - 5.0)
	var speed := clampf(dist / left, 40.0, MAX_SPEED)
	if _fast:
		for k in 7:
			col.position.y = lerpf(vw.y, stop_y, k / 6.0)
			await get_tree().process_frame
			if _shots:
				await lv.shot("credits_roll_%d" % k)
		return
	while col.position.y > stop_y and not _skipped:
		var mult := 4.0 if Input.is_action_pressed("interact") else 1.0
		col.position.y = maxf(stop_y, col.position.y - speed * mult * get_process_delta_time())
		await get_tree().process_frame

func _entry(e: Array) -> Control:
	match e[0]:
		"gap":
			return _gap(e[1])
		"logo":
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 0)
			v.add_child(_center(_lbl("TRIO", 92, GOLD, UITheme.head_font(), 10)))
			v.add_child(_center(_lbl("ADVENTURES", 54, CREAM, UITheme.head_font(), 8)))
			return v
		"head":
			var h := _center(_lbl(e[1], 18, GOLD, UITheme.head_font(), 4))
			h.add_theme_constant_override("line_spacing", 0)
			return h
		"name":
			return _center(_lbl(e[1], 34, CREAM, UITheme.head_font()))
		"note":
			return _center(_lbl(e[1], 18, DIM))
		"role":
			return _two(e[1], e[2])
		"cast":
			return _cast(e[1], e[2], e[3])
		"end":
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 12)
			v.add_child(_center(_lbl("Thanks for playing!", 40, GOLD, UITheme.head_font())))
			v.add_child(_center(_lbl("Chapter 2 coming soon.", 22, CREAM)))
			return v
	return null

# "Job ........ Name" style: job right-aligned left of the middle, name left-aligned right of it
func _two(job: String, who: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 36)
	var a := _lbl(job, 20, DIM)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.size_flags_stretch_ratio = 1.0
	var b := _lbl(who, 22, CREAM)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(b)
	return h

func _cast(por: String, who: String, credit: String) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 36)
	var left := HBoxContainer.new()
	left.alignment = BoxContainer.ALIGNMENT_END
	left.add_theme_constant_override("separation", 18)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p := "res://assets/portraits/%s.png" % por
	if ResourceLoader.exists(p):
		var t := TextureRect.new()
		t.texture = load(p)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(84, 84)
		left.add_child(t)
	var n := _lbl(who, 28, CREAM, UITheme.head_font())
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	left.add_child(n)
	var c := _lbl(credit, 20, DIM)
	c.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_FILL
	h.add_child(left)
	h.add_child(c)
	return h

# ---------------------------------------------------------------- the end + skipping
func _wait_continue() -> void:
	var l := _lbl("Press E to continue", 18, DIM)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	l.position += Vector2(-80, -60)
	l.modulate.a = 0.0
	add_child(l)
	create_tween().tween_property(l, "modulate:a", 1.0, 1.0)
	while not _skipped and not Input.is_action_just_pressed("interact"):
		await get_tree().process_frame

func _input(ev: InputEvent) -> void:
	if _fast or not ev.is_action_pressed("pause") and not ev.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if ev.is_echo():
		return
	if _skip_armed > 0.0:
		_skipped = true
		return
	_skip_armed = 2.5
	skip_lbl.modulate.a = 1.0

func _process(delta: float) -> void:
	if _skip_armed > 0.0:
		_skip_armed -= delta
		if _skip_armed <= 0.0:
			create_tween().tween_property(skip_lbl, "modulate:a", 0.0, 0.4)

func _close() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(stage, "modulate:a", 0.0, 1.0)
	if music:
		tw.tween_property(music, "volume_db", -60.0, 1.4)
	await tw.finished
	if music:
		music.stop()
	finished.emit()

# ---------------------------------------------------------------- music + helpers
func _start_music() -> void:
	if not ResourceLoader.exists(SONG):
		return
	var st: AudioStream = load(SONG).duplicate()
	if "loop" in st:
		st.loop = false
	music = AudioStreamPlayer.new()
	music.stream = st
	music.volume_db = -30.0
	music.bus = &"Music"
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", MUSIC_DB, 2.0)

func _duck(on: bool) -> void:
	if music:
		create_tween().tween_property(music, "volume_db", MUSIC_DB - 12.0 if on else MUSIC_DB, 0.4)

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = px
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _lbl(text: String, size: int, color: Color, font: Font = null, spacing := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	if font:
		if spacing > 0:
			var fv := FontVariation.new()
			fv.base_font = font
			fv.spacing_glyph = spacing
			font = fv
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
