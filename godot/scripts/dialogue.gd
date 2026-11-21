# Dialogue box: portrait, name, typewriter text, choices, and the same robot TTS voices as the web game.
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
	"mattias":  { "name": "Metocin Mattias", "color": Color("#6aa8ff"), "pitch": 0.8, "rate": 0.85 },
	"narrator": { "name": "", "color": Color("#c9c0e8"), "pitch": 1.0, "rate": 1.0 },
}
const GOLD := Color("#e8b923")

signal _next
signal _picked(i: int)

var active := false
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

func _ready() -> void:
	layer = 10
	_build()
	panel.visible = false
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
	active = true
	panel.visible = true
	panel.modulate.a = 0.0
	create_tween().tween_property(panel, "modulate:a", 1.0, 0.15)
	await _run_steps(steps, ctx)
	panel.visible = false
	DisplayServer.tts_stop()
	active = false

func _run_steps(steps: Array, ctx: Node) -> void:
	for s in steps:
		if s.has("do"):
			await ctx.do_action(s["do"])
		elif s.has("choice"):
			var opts: Array = s["choice"]
			var i: int = await ask(opts)
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
	DisplayServer.tts_stop()

func show_box() -> void:
	panel.visible = true

func say(s: Dictionary) -> void:
	var who: String = s.get("who", "narrator")
	var c: Dictionary = CHARS.get(who, CHARS["narrator"])
	var thought: bool = s.get("thought", false)
	var line: String = s.get("line", "")
	name_lbl.text = c["name"] + ("  (thinking)" if thought else "")
	name_lbl.add_theme_color_override("font_color", c["color"])
	var tex := _portrait(c.get("portrait", who), s.get("mood", ""))
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
	text_lbl.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(text_lbl, "visible_ratio", 1.0, max(0.25, line.length() * 0.022))
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
		l.text = ("> " if i == _sel else "   ") + _choices[i]["text"]
		l.add_theme_color_override("font_color", GOLD if i == _sel else Color("#f4efff"))

func _clear_choices() -> void:
	for ch in choice_box.get_children():
		ch.queue_free()
	_choices = []

func _unhandled_input(ev: InputEvent) -> void:
	if not active:
		return
	if not _choices.is_empty():
		if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
			_sel = (_sel + _choices.size() - 1) % _choices.size(); _render_choices()
		elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
			_sel = (_sel + 1) % _choices.size(); _render_choices()
		elif ev.is_action_pressed("interact"):
			_picked.emit(_sel)
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

func _speak(who: String, line: String, thought: bool) -> void:
	if not tts_on or _voices.is_empty():
		return
	var clean := line.replace("…", ", ").replace("*", "")
	for pair in [["\\bshi\\b", "shee"], ["\\bdoe\\b", "dough"], ["\\by'all\\b", "yall"]]:
		var re := RegEx.create_from_string("(?i)" + pair[0])
		clean = re.sub(clean, pair[1], true)
	if not clean.strip_edges().is_empty() and clean.strip_edges() != ",":
		var c: Dictionary = CHARS.get(who, CHARS["narrator"])
		var v := _voices[CHARS.keys().find(who) % _voices.size()]
		DisplayServer.tts_speak(clean, v, 45 if thought else 80, c["pitch"], c["rate"], 0, true)
