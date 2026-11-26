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
	# the rat cave + Charis (RUINS_PLAN.md). Names are # DRAFT (Ebain renames)
	"rat":      { "name": "Rat", "color": Color("#b8a48c"), "pitch": 2.0, "rate": 1.6 },
	"rats":     { "name": "Rats", "color": Color("#b8a48c"), "pitch": 2.0, "rate": 1.7, "portrait": "rat" },
	"rat_king": { "name": "King Nibbsworth III", "color": Color("#d9a85a"), "pitch": 1.2, "rate": 0.8 },
	"rat_trader": { "name": "Scrounge", "color": Color("#a8c07a"), "pitch": 1.7, "rate": 1.45 },
	"charis":   { "name": "Charis", "color": Color("#e08ac8"), "pitch": 1.2, "rate": 1.0 },
	# the secret Deloye Lore library (DELOYE_PLAN.md): chill, earbuds in. Voice is a placeholder robot until Ebain picks one
	"deloye":   { "name": "Deloye", "color": Color("#c9b8ff"), "pitch": 0.9, "rate": 0.85 },
	"narrator": { "name": "", "color": Color("#c9c0e8"), "pitch": 1.0, "rate": 1.0 },
	# the Bridge Troll (Ebain 11/26): Chief Bogdrinker's voice, lowered ("voice_as" picks the Chief's robot voice; it's last
	# in the table so it doesn't shift anyone else's robot voice)
	"troll":    { "name": "Bridge Troll", "color": Color("#8a9a6a"), "pitch": 0.55, "rate": 0.9, "voice_as": "chief", "portrait": "troll" },
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
var foot: HBoxContainer          # bottom row: speed-mode button/confirm on the left, key hint on the right
var _speed_box: HBoxContainer     # "Speed" + slider (0.5x–3x) + "1.5x", bottom-left of the box
var _speed_slider: HSlider
var _speed_val: Label
var _ready_at := 0               # msec: E can't advance before this (the buffer)
var _back_ok := false            # the step before this line is a plain line, so Backspace can replay it
var _back_req := false
var _choices: Array = []
var name_line: Control
var _speed_q: Label   # "Speed" caption
var _who := ""                   # current speaker (for restyling the name color)
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
	panel.offset_left = -600; panel.offset_right = 600; panel.offset_top = -_box_h(); panel.offset_bottom = -18
	root.add_child(panel)   # looks: _restyle() (UITheme, follows Settings → Menu theme / Text size)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	portrait_frame = PanelContainer.new()
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
	col.add_child(name_lbl)
	name_line = UITheme.Divider.new()   # a thin ornament line under the speaker's name
	name_line.custom_minimum_size = Vector2(260, 8)
	name_line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(name_line)

	text_lbl = RichTextLabel.new()
	text_lbl.bbcode_enabled = true
	text_lbl.fit_content = false
	text_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_lbl.scroll_active = false
	col.add_child(text_lbl)

	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 4)
	col.add_child(choice_box)

	foot = HBoxContainer.new()
	foot.add_theme_constant_override("separation", 10)
	col.add_child(foot)
	# Speed slider (Ebain 11/24): one click/drag, no Yes/No. Changes voices + text typing, 0.5x to 3x.
	_speed_box = HBoxContainer.new()
	_speed_box.add_theme_constant_override("separation", 8)
	foot.add_child(_speed_box)
	_speed_q = Label.new()
	_speed_q.text = "Speed"
	_speed_box.add_child(_speed_q)
	_speed_slider = HSlider.new()
	_speed_slider.min_value = Game.DLG_SPEED_MIN
	_speed_slider.max_value = Game.DLG_SPEED_MAX
	_speed_slider.step = 0.25
	_speed_slider.custom_minimum_size = Vector2(150, 18)
	_speed_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_speed_slider.focus_mode = Control.FOCUS_NONE   # E / Space / arrows never move it
	_speed_slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_speed_slider.value = Game.dlg_speed
	_speed_slider.value_changed.connect(_set_speed)
	_speed_slider.drag_ended.connect(func(_c): Game.save_settings())
	_speed_box.add_child(_speed_slider)
	_speed_val = Label.new()
	_speed_val.custom_minimum_size.x = 44
	_speed_box.add_child(_speed_val)
	hint = Label.new()
	hint.text = "E / Space  >"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	foot.add_child(hint)
	_refresh_speed_btn()
	_restyle()
	Game.ui_changed.connect(_restyle)

# Colors, fonts and sizes from UITheme. Runs again when Settings change the theme or text size.
func _restyle() -> void:
	var sb := UITheme.panel(0.94)
	sb.content_margin_left = 22; sb.content_margin_right = 26; sb.content_margin_top = 18; sb.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", sb)
	var pf := StyleBoxFlat.new()
	pf.bg_color = Color(UITheme.c("bg2"), 0.6)
	pf.border_color = UITheme.c("edge")
	pf.set_border_width_all(2)
	pf.set_corner_radius_all(4)
	pf.set_expand_margin_all(3)
	pf.shadow_color = Color(0, 0, 0, 0.35); pf.shadow_size = 6
	portrait_frame.add_theme_stylebox_override("panel", pf)
	UITheme.style_lbl(name_lbl, 26, "text", UITheme.row_font())
	if _who != "":
		name_lbl.add_theme_color_override("font_color", _name_color(_who))
	name_line.queue_redraw()
	text_lbl.add_theme_font_size_override("normal_font_size", UITheme.fs(24))
	text_lbl.add_theme_font_size_override("italics_font_size", UITheme.fs(24))
	text_lbl.add_theme_color_override("default_color", UITheme.c("text"))
	var ol := UITheme.c("outline")
	text_lbl.add_theme_color_override("font_outline_color", ol)
	text_lbl.add_theme_constant_override("outline_size", 0 if ol.a < 0.05 else 3)
	UITheme.style_lbl(_speed_q, 15, "dim")
	UITheme.style_lbl(_speed_val, 15, "accent")
	_style_slider()
	UITheme.style_lbl(hint, 15, "dim")
	if _choices.is_empty():
		panel.offset_top = -_box_h()
	else:
		_render_choices()

# The speed slider: a thin rounded track, filled in the accent color up to a round knob.
func _style_slider() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(UITheme.c("edge"), 0.55)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3; track.content_margin_bottom = 3
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = UITheme.c("accent")
	_speed_slider.add_theme_stylebox_override("slider", track)
	_speed_slider.add_theme_stylebox_override("grabber_area", fill)
	_speed_slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	var knob := _knob(UITheme.c("accent"), 14)
	_speed_slider.add_theme_icon_override("grabber", knob)
	_speed_slider.add_theme_icon_override("grabber_highlight", _knob(UITheme.c("text"), 16))

static func _knob(col: Color, d: int) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d * 0.5
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - dist, 0.0, 1.0)
			img.set_pixel(x, y, Color(col, a))
	return ImageTexture.create_from_image(img)

# Box height: 214 px at 100% text size, taller with bigger text so 3 lines still fit.
# Long lines shrink to fit the box instead of running off the bottom (Asar 11/25: Mattias's long line lost
# "past"). Starts at the normal size (Settings text size) and steps down until the wrapped text fits.
func _fit_text(line: String) -> void:
	var base := UITheme.fs(24)
	var font: Font = text_lbl.get_theme_font("normal_font")
	var w := text_lbl.size.x
	var h := text_lbl.size.y
	var fs := base
	if font and w > 50.0 and h > 20.0:
		var plain := line.replace("[i]", "").replace("[/i]", "")
		while fs > int(base * 0.6) and font.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, w, fs).y > h:
			fs -= 1
	text_lbl.add_theme_font_size_override("normal_font_size", fs)
	text_lbl.add_theme_font_size_override("italics_font_size", fs)

func _box_h() -> float:
	return 214.0 + maxf(0.0, Game.text_scale - 1.0) * 220.0

# A speaker's name color, darkened on light themes (Parchment) so it stays readable on paper.
func _name_color(who: String) -> Color:
	var c: Color = CHARS.get(who, CHARS["narrator"])["color"]
	return c.darkened(0.55) if UITheme.c("bg").get_luminance() > 0.5 else c

# Small clickable buttons in the bottom row. No keyboard focus, so E / Space never "presses" them.
func _foot_button(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", UITheme.fs(15))
	b.add_theme_color_override("font_color", UITheme.c("dim"))
	b.add_theme_color_override("font_hover_color", UITheme.c("accent"))
	b.pressed.connect(cb)
	return b

func _set_speed(v: float) -> void:
	Game.dlg_speed = clampf(v, Game.DLG_SPEED_MIN, Game.DLG_SPEED_MAX)
	_refresh_speed_btn()
	_apply_voice_speed()
	if _typing and _typing.is_running():   # the line being typed right now speeds up too
		_typing.set_speed_scale(Game.dlg_speed)

func _refresh_speed_btn() -> void:
	if not is_equal_approx(_speed_slider.value, Game.dlg_speed):
		_speed_slider.set_value_no_signal(Game.dlg_speed)
	_speed_val.text = "%sx" % str(snappedf(Game.dlg_speed, 0.01))

# Footer hint: Backspace shows only when going back is possible for this line.
func _hint_text() -> String:
	var parts: Array = []
	if Game.dlg_back and _back_ok:
		parts.append("Backspace: back")
	if can_leave:
		parts.append("Esc: leave")
	parts.append("E / Space  >")
	return "     ".join(parts)

# The buffer: E can't advance until the line has been fully on screen for a moment (none in speed mode).
func _arm_buffer() -> void:
	var sec: float = Game.DLG_BUFFER_SEC[Game.dlg_buffer] / Game.dlg_speed   # faster dialogue = shorter buffer
	_ready_at = Time.get_ticks_msec() + int(sec * 1000.0)


func run(steps: Array, ctx: Node) -> void:
	left = false
	_refresh_speed_btn()
	active = true
	panel.visible = true
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)
	await _run_steps(steps, ctx)
	panel.visible = false
	stop_voice()
	active = false

func _run_steps(steps: Array, ctx: Node) -> void:
	var i := 0
	while i < steps.size():
		var s: Dictionary = steps[i]
		if left:   # Esc: stop here (the rest of the conversation, and anything it would have started, is skipped)
			return
		if s.has("do"):
			await ctx.do_action(s["do"])
		elif s.has("choice"):
			var opts: Array = s["choice"].filter(func(o): return not o.has("if") or Game.flag(o["if"]))
			var pick: int = await ask(opts)
			if pick < 0:
				return
			if opts[pick].has("outcome"):   # counts toward "Outcomes x/N" on the title screen (progress_data.gd)
				ProgressData.pick_outcome(opts[pick]["outcome"])   # + per-run flag way_<scene> (summit lines use it)
			await _run_steps(opts[pick]["steps"], ctx)
		elif s.has("if"):
			if Game.flag(s["if"]):
				await _run_steps(s["steps"], ctx)
		elif s.has("if_not"):
			if not Game.flag(s["if_not"]):
				await _run_steps(s["steps"], ctx)
		else:
			# Backspace replays the previous line, but only if that step is also a plain line: going back over an
			# action (camera, fight, item...) or a choice would run it twice, so it's not allowed.
			_back_ok = i > 0 and _is_line(steps[i - 1])
			await say(s)
			_back_ok = false
			if _back_req:
				_back_req = false
				if i > 0 and _is_line(steps[i - 1]):
					i -= 1
					continue
		i += 1

func _is_line(s: Dictionary) -> bool:
	return not (s.has("do") or s.has("choice") or s.has("if") or s.has("if_not"))

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
	_who = who
	name_lbl.add_theme_color_override("font_color", _name_color(who))
	name_line.visible = name_lbl.text != ""
	var tex := _portrait(s.get("portrait", c.get("portrait", who)), s.get("mood", ""))
	portrait.texture = tex
	portrait_frame.visible = tex != null
	_clear_choices()
	hint.visible = true
	hint.text = _hint_text()
	foot.visible = true
	text_lbl.visible = true
	if who == "narrator":
		text_lbl.text = "[center][i]%s[/i][/center]" % line
	elif thought:
		text_lbl.text = "[i][color=#%s]%s[/color][/i]" % [UITheme.c("note").to_html(false), line]
	else:
		text_lbl.text = line
	_fit_text(line)
	var speed: float = Game.TEXT_SPEED_MULT[Game.text_speed]   # Settings → Text speed (0 = instant)
	if speed <= 0.0:
		text_lbl.visible_ratio = 1.0
		_typing = null
		_arm_buffer()
	else:
		text_lbl.visible_ratio = 0.0
		_typing = create_tween()
		_typing.tween_property(text_lbl, "visible_ratio", 1.0, max(0.2, line.length() * 0.022 * speed))
		_typing.set_speed_scale(Game.dlg_speed)   # dialogue speed slider
		_typing.finished.connect(_arm_buffer)   # buffer starts when the line is fully shown
	_speak(who, line, thought, str(s.get("voice", "")) != "none")
	await _next

func ask(opts: Array) -> int:
	_clear_choices()
	hint.visible = false
	foot.visible = false
	text_lbl.visible = false
	panel.offset_top = -_box_h() - max(0, opts.size() - 3) * int(UITheme.fs(23) * 1.6)   # grow the box for long choice lists
	name_line.visible = false
	_choices = []
	for o in opts:
		var row := PanelContainer.new()   # themed row: glowing bar + diamond when selected (like the menus)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var l := Label.new()
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(l)
		var idx := _choices.size()
		row.gui_input.connect(func(ev):
			if UITheme.hover_moved(ev):   # only real mouse movement moves the highlight (no jumping)
				if _sel != idx:
					_sel = idx
					_render_choices()
					UITheme.play("move")
			elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_sel = idx
				UITheme.play("pick")
				_picked.emit(idx)
		)
		choice_box.add_child(row)
		_choices.append({ "label": l, "row": row, "text": o["text"] })
	_sel = 0
	_last_sel = -1
	_render_choices()
	var i: int = await _picked
	_clear_choices()
	panel.offset_top = -_box_h()
	return i

var _last_sel := -1
func _render_choices() -> void:
	for i in _choices.size():
		var l: Label = _choices[i]["label"]
		l.text = "%d.   %s" % [i + 1, _choices[i]["text"]]
		UITheme.style_lbl(l, 23, "accent" if i == _sel else "text")
		_choices[i]["row"].add_theme_stylebox_override("panel", UITheme.row(i == _sel))
	if _sel != _last_sel and _sel >= 0 and _sel < _choices.size():
		UITheme.bounce(_choices[_sel]["label"], 0.04)
		_last_sel = _sel

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
			_sel = (_sel + _choices.size() - 1) % _choices.size(); UITheme.key_nav(); UITheme.play("move"); _render_choices()
		elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
			_sel = (_sel + 1) % _choices.size(); UITheme.key_nav(); UITheme.play("move"); _render_choices()
		elif ev.is_action_pressed("interact"):
			UITheme.play("pick")
			_picked.emit(_sel)
		elif ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode >= KEY_1 and ev.keycode <= KEY_9:
			var n: int = ev.keycode - KEY_1   # number keys pick a choice directly
			if n < _choices.size():
				_sel = n
				_render_choices()
				_picked.emit(n)
		get_viewport().set_input_as_handled()
		return
	if ev is InputEventKey and ev.pressed and not ev.echo and ev.keycode == KEY_BACKSPACE:
		if Game.dlg_back and _back_ok and not _back_req:   # replay the previous line
			_back_req = true
			if _typing and _typing.is_running():
				_typing.kill()
			_next.emit()
		get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("interact") or (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT):
		if _typing and _typing.is_running():
			_typing.kill()
			text_lbl.visible_ratio = 1.0
			_arm_buffer()   # skipping the typing counts as showing the line: the next press waits out the buffer
		elif Time.get_ticks_msec() >= _ready_at:
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

# use_rec = false: a step marked "voice": "none" never borrows a recording that happens to have the same words
# (recordings are matched by text alone, e.g. the troll's "Aight bet" vs the giant's "Aight. Bet.") (Asar 11/24)
func _speak(who: String, line: String, thought: bool, use_rec := true) -> void:
	_tts_queue.clear()   # newest line wins
	_pending_rec = null
	if _vo:
		_vo.stop()
	if not tts_on or Game.voice_vol <= 0.01:
		return
	var rec := VoiceLines.stream_for(line) if use_rec else null   # thoughts too: the studio bakes their echo in
	if rec:
		_vo.volume_db = linear_to_db(Game.voice_vol) + VOICE_GAIN_DB.get(who, 0.0)
		# Dialogue speed (slider, 0.5x–3x): play faster/slower through a bus that shifts the pitch back, so it
		# doesn't sound like a chipmunk (or a slowed-down demon).
		_apply_voice_speed()
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
	var v := _voices[CHARS.keys().find(c.get("voice_as", who)) % _voices.size()]
	var vol := int((45 if thought else 80) * Game.voice_vol)
	for part in sentences(clean):
		_tts_queue.append({ "text": part, "voice": v, "vol": vol, "pitch": c["pitch"], "rate": clampf(c["rate"] * Game.dlg_speed, 0.1, 10.0) })
	_pump()

func _apply_voice_speed() -> void:
	if _vo == null:
		return
	var x: float = Game.dlg_speed
	_vo.pitch_scale = x
	_vo.bus = &"Master" if is_equal_approx(x, 1.0) else _fast_bus(x)

static func _fast_bus(x: float) -> StringName:
	var i := AudioServer.get_bus_index("VoiceFast")
	if i == -1:
		AudioServer.add_bus()
		i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, "VoiceFast")
		AudioServer.set_bus_send(i, &"Master")
		AudioServer.add_bus_effect(i, AudioEffectPitchShift.new())
	var fx := AudioServer.get_bus_effect(i, 0) as AudioEffectPitchShift
	if fx and not is_equal_approx(fx.pitch_scale, 1.0 / x):
		fx.pitch_scale = 1.0 / x
	return &"VoiceFast"

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
