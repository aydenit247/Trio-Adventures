# Dialogue box: portrait, name, typewriter text, choices, and the same robot TTS voices as the web game.
# Lines with a real recording (see voice_lines.gd) play that instead of TTS.
#   await dialogue.run(steps, main)
extends CanvasLayer
class_name Dialogue

const CHARS := {
	"skorn":    { "name": "Skorn", "color": Color("#b07cff"), "pitch": 0.4, "rate": 1.15 },
	"lykor":    { "name": "Lykor", "color": Color("#ffd86a"), "pitch": 1.4, "rate": 0.95 },
	"xylo":     { "name": "Xylo", "color": Color("#ff6a5a"), "pitch": 0.6, "rate": 0.85 },
	"goblin":   { "name": "Goblin", "color": Color("#7dcf5a"), "pitch": 2.0, "rate": 1.4 },
	"goblins":  { "name": "Goblins", "color": Color("#7dcf5a"), "pitch": 2.0, "rate": 1.5, "portrait": "goblin" },
	"chief":    { "name": "Chief Bogdrinker", "color": Color("#9bc25a"), "pitch": 1.55, "rate": 1.1 },
	"dulbers":  { "name": "Dulbers Frint", "color": Color("#8fb0c8"), "pitch": 1.7, "rate": 1.3 },
	"dulbers_demon": { "name": "Dulbers Frint (Demon)", "color": Color("#c06bff"), "pitch": 0.1, "rate": 0.75 },
	"mattias":  { "name": "Metocin Mattias", "color": Color("#6aa8ff"), "pitch": 0.8, "rate": 0.85 },
	"giant":    { "name": "Diddy Chud Giant", "color": Color("#d9a46a"), "pitch": 0.0, "rate": 0.65 },
	"narrator": { "name": "", "color": Color("#c9c0e8"), "pitch": 1.0, "rate": 1.0 },
}
const GOLD := Color("#e8b923")

# Per-speaker boost for recordings that came out quieter than the rest (Asar 11/22: Mattias was ~10 dB under Skorn).
const VOICE_GAIN_DB := { "mattias": 9.0 }

signal _next
signal _picked(i: int)

var active := false
var can_leave := false   # optional conversations: Esc ends them (Asar). Set by Level.start, never in story scenes.
var left := false        # true when the last conversation was ended with Esc
var tts_on := true
var panel: PanelContainer
var portrait: TextureRect
var portrait_frame: PanelContainer
var name_lbl: Label
var text_lbl: RichTextLabel
var choice_box: VBoxContainer
var hint: Label
var _typing: Tween
var _choices: Array = []
var _sel := 0
var _voices: PackedStringArray = []
var _vo: AudioStreamPlayer   # plays recorded voice lines
# Robot-voice queue (see "Voices" at the bottom). Newest line wins; older queued lines are dropped.
var _tts_queue: Array = []          # sentences of the newest line still to speak: [{text, voice, vol, pitch, rate}]
var _pending_rec: AudioStream       # a recording waiting for the robot to finish its current sentence
var _tts_grace_until := 0           # msec: treat the robot as talking right after tts_speak (is_speaking can lag)

func _ready() -> void:
	layer = 10
	_build()
	panel.visible = false
	_vo = AudioStreamPlayer.new()
	add_child(_vo)
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		_voices = DisplayServer.tts_get_voices_for_language("en")

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 1.0; panel.anchor_bottom = 1.0
	panel.offset_left = -600; panel.offset_right = 600; panel.offset_top = -214; panel.offset_bottom = -18
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.045, 0.11, 0.93)
	sb.border_color = GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 18; sb.content_margin_right = 22; sb.content_margin_top = 14; sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.5); sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	portrait_frame = PanelContainer.new()
	var pf := StyleBoxFlat.new()
	pf.bg_color = Color(0, 0, 0, 0.4); pf.border_color = GOLD; pf.set_border_width_all(2); pf.set_corner_radius_all(10)
	portrait_frame.add_theme_stylebox_override("panel", pf)
	portrait_frame.custom_minimum_size = Vector2(164, 164)
	row.add_child(portrait_frame)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.custom_minimum_size = Vector2(160, 160)
	portrait_frame.add_child(portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	row.add_child(col)

	name_lbl = Label.new()
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	name_lbl.add_theme_constant_override("outline_size", 6)
	col.add_child(name_lbl)

	text_lbl = RichTextLabel.new()
	text_lbl.bbcode_enabled = true
	text_lbl.fit_content = false
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_lbl.scroll_active = false
	text_lbl.add_theme_font_size_override("normal_font_size", 24)
	text_lbl.add_theme_font_size_override("italics_font_size", 24)
	text_lbl.add_theme_color_override("default_color", Color("#f4efff"))
	col.add_child(text_lbl)

	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 4)
	col.add_child(choice_box)

	hint = Label.new()
	hint.text = "E / Space  >"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("#a49cc4"))
	col.add_child(hint)

func run(steps: Array, ctx: Node) -> void:
	left = false
	hint.text = "E / Space  >     Esc: leave" if can_leave else "E / Space  >"
	active = true
	panel.visible = true
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)
	await _run_steps(steps, ctx)
	panel.visible = false
	stop_voice()
	active = false

func _run_steps(steps: Array, ctx: Node) -> void:
	for s in steps:
		if left:   # Esc: stop here (the rest of the conversation, and anything it would have started, is skipped)
			return
		if s.has("do"):
			await ctx.do_action(s["do"])
		elif s.has("choice"):
			var opts: Array = s["choice"].filter(func(o): return not o.has("if") or Game.flag(o["if"]))
			var i: int = await ask(opts)
			if i < 0:
				return
			if opts[i].has("outcome"):   # counts toward "Outcomes x/17" on the title screen (progress_data.gd)
				Game.unlock(opts[i]["outcome"])
			await _run_steps(opts[i]["steps"], ctx)
		elif s.has("if"):
			if Game.flag(s["if"]):
				await _run_steps(s["steps"], ctx)
		elif s.has("if_not"):
			if not Game.flag(s["if_not"]):
				await _run_steps(s["steps"], ctx)
		else:
			await say(s)

# Hide/show the box mid-dialogue (e.g. while the player sneaks during a scene)
func hide_box() -> void:
	panel.visible = false
	stop_voice()

func show_box() -> void:
	panel.visible = true

func say(s: Dictionary) -> void:
	var who: String = s.get("who", "narrator")
	var c: Dictionary = CHARS.get(who, CHARS["narrator"])
	var thought: bool = s.get("thought", false)
	var line: String = s.get("line", "")
	name_lbl.text = s.get("name", c["name"]) + ("  (thinking)" if thought else "")   # "name" = one-off speaker (e.g. a named goblin)
	name_lbl.add_theme_color_override("font_color", c["color"])
	var tex := _portrait(s.get("portrait", c.get("portrait", who)), s.get("mood", ""))
	portrait.texture = tex
	portrait_frame.visible = tex != null
	_clear_choices()
	hint.visible = true
	text_lbl.visible = true
	if who == "narrator":
		text_lbl.text = "[center][i]%s[/i][/center]" % line
	elif thought:
		text_lbl.text = "[i][color=#c9c0e8]%s[/color][/i]" % line
	else:
		text_lbl.text = line
	var speed: float = Game.TEXT_SPEED_MULT[Game.text_speed]   # Settings → Text speed (0 = instant)
	if speed <= 0.0:
		text_lbl.visible_ratio = 1.0
		_typing = null
	else:
		text_lbl.visible_ratio = 0.0
		_typing = create_tween()
		_typing.tween_property(text_lbl, "visible_ratio", 1.0, max(0.2, line.length() * 0.022 * speed))
	_speak(who, line, thought)
	await _next

func ask(opts: Array) -> int:
	_clear_choices()
	hint.visible = false
	text_lbl.visible = false
	panel.offset_top = -214 - max(0, opts.size() - 3) * 34   # grow the box for long choice lists
	_choices = []
	for o in opts:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 23)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		var idx := _choices.size()
		l.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_sel = idx
				_picked.emit(idx)
		)
		l.mouse_entered.connect(func(): _sel = idx; _render_choices())
		choice_box.add_child(l)
		_choices.append({ "label": l, "text": o["text"] })
	_sel = 0
	_render_choices()
	var i: int = await _picked
	_clear_choices()
	panel.offset_top = -214
	return i

func _render_choices() -> void:
	for i in _choices.size():
		var l: Label = _choices[i]["label"]
		l.text = ("> " if i == _sel else "   ") + "%d.  %s" % [i + 1, _choices[i]["text"]]
		l.add_theme_color_override("font_color", GOLD if i == _sel else Color("#f4efff"))

func _clear_choices() -> void:
	for ch in choice_box.get_children():
		ch.queue_free()
	_choices = []

func _unhandled_input(ev: InputEvent) -> void:
	if not active:
		return
	if can_leave and not left and (ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel")):
		left = true
		stop_voice()
		if not _choices.is_empty():
			_picked.emit(-1)
		else:
			if _typing and _typing.is_running():
				_typing.kill()
			_next.emit()
		get_viewport().set_input_as_handled()
		return
	if not _choices.is_empty():
		if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
			_sel = (_sel + _choices.size() - 1) % _choices.size(); _render_choices()
		elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
			_sel = (_sel + 1) % _choices.size(); _render_choices()
		elif ev.is_action_pressed("interact"):
			_picked.emit(_sel)
		elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode >= KEY_1 and ev.keycode <= KEY_9:
			var n: int = ev.keycode - KEY_1   # number keys pick a choice directly
			if n < _choices.size():
				_sel = n
				_render_choices()
				_picked.emit(n)
		get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("interact") or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		if _typing and _typing.is_running():
			_typing.kill()
			text_lbl.visible_ratio = 1.0
		else:
			_next.emit()
		get_viewport().set_input_as_handled()

func _portrait(who: String, mood: String) -> Texture2D:
	for key in ["%s_%s" % [who, mood], who]:
		var p := "res://assets/portraits/%s.png" % key
		if ResourceLoader.exists(p):
			return load(p)
	return null

# ---------------------------------------------------------------- Voices
# NEVER call DisplayServer.tts_stop() or tts_speak(..., interrupt=true) here.
# Godot 4.7's Windows TTS driver (OneCore) can deadlock when a line is cut off at the same moment it finishes
# playing on its own: the "playback ended" callback and the stop both close the same MediaPlayer from two threads.
# The whole game hangs (needs Task Manager). So the robot voice is never interrupted.
#
# Skipping used to leave the next line silent: the robot was still reading the skipped line, so the next one was
# dropped. Now the robot reads a line one sentence at a time, and the newest line waits in _tts_queue until the
# current sentence ends. After a skip you hear at most the rest of one sentence, then the new line. Skipping
# several lines quickly only queues the last one. Recorded lines (AudioStreamPlayer) are safe to stop, so they
# cut each other off instantly; a recording that arrives mid robot-sentence waits for that sentence to end.
func stop_voice() -> void:
	_tts_queue.clear()
	_pending_rec = null
	if _vo:
		_vo.stop()

func _speak(who: String, line: String, thought: bool) -> void:
	_tts_queue.clear()   # newest line wins
	_pending_rec = null
	if _vo:
		_vo.stop()
	if not tts_on or Game.voice_vol <= 0.01:
		return
	var rec := VoiceLines.stream_for(line)   # thoughts too: the studio bakes their echo in
	if rec:
		_vo.volume_db = linear_to_db(Game.voice_vol) + VOICE_GAIN_DB.get(who, 0.0)
		_pending_rec = rec
		_pump()
		return
	if _voices.is_empty():
		return
	var clean := line.replace("…", ", ").replace("*", "")
	for pair in [["\\bshi\\b", "shee"], ["\\bdoe\\b", "dough"], ["\\by'all\\b", "yall"]]:
		var re := RegEx.create_from_string("(?i)" + pair[0])
		clean = re.sub(clean, pair[1], true)
	var c: Dictionary = CHARS.get(who, CHARS["narrator"])
	var v := _voices[CHARS.keys().find(who) % _voices.size()]
	var vol := int((45 if thought else 80) * Game.voice_vol)
	for part in sentences(clean):
		_tts_queue.append({ "text": part, "voice": v, "vol": vol, "pitch": c["pitch"], "rate": c["rate"] })
	_pump()

func _process(_dt: float) -> void:
	if _pending_rec or not _tts_queue.is_empty():
		_pump()

# Starts the next queued voice piece once the robot is quiet.
func _pump() -> void:
	if _tts_busy():
		return
	if _pending_rec:
		_vo.stream = _pending_rec
		_pending_rec = null
		_tts_queue.clear()
		_vo.play()
	elif not _tts_queue.is_empty():
		var q: Dictionary = _tts_queue.pop_front()
		_tts_say(q)

func _tts_busy() -> bool:
	return Time.get_ticks_msec() < _tts_grace_until or DisplayServer.tts_is_speaking()

func _tts_say(q: Dictionary) -> void:
	_tts_grace_until = Time.get_ticks_msec() + 150
	DisplayServer.tts_speak(q["text"], q["voice"], q["vol"], q["pitch"], q["rate"], 0, false)

# Splits a line into speakable pieces: sentences, with very long ones split at commas and tiny ones ("Aight.")
# glued to the next so the robot doesn't pause after every word.
static func sentences(text: String) -> PackedStringArray:
	var raw: PackedStringArray = []
	for m in RegEx.create_from_string("[^.!?]+[.!?]*|[.!?]+").search_all(text):
		var sen := m.get_string().strip_edges()
		if sen.length() > 90:
			for bit in sen.split(", "):
				raw.append(bit.strip_edges())
		else:
			raw.append(sen)
	var out: PackedStringArray = []
	var carry := ""
	for r in raw:
		var t := (carry + " " + r).strip_edges() if carry != "" else r
		if t.replace(",", "").strip_edges().is_empty():
			continue
		if t.length() < 14:
			carry = t
		else:
			out.append(t)
			carry = ""
	if carry != "" and not carry.replace(",", "").strip_edges().is_empty():
		if out.is_empty():
			out.append(carry)
		else:
			out[out.size() - 1] += " " + carry
	return out
