# "Previously on Trio Adventures…" (Ebain 11/27). Plays once when you Continue / Load from the title screen
# (Game.recap_pending, set by Game.load_game; Level._recap() calls Recap.play). Built from THIS run's flags, so it's
# different every time: the last few story beats you actually played (newest last), each with the real voice line
# said right after that choice (ScriptScan.outcome), then "where you left off" with the objective.
# E = next card · Esc = skip it all. Settings → Gameplay → "Previously on" turns it off.
# Card text is DRAFT (Ebain rewrites); quotes are the game's own lines.
extends CanvasLayer
class_name Recap

signal finished

const GOLD := Color("#f0c24a")
const CREAM := Color("#f3e6c4")
const DIM := Color(0.85, 0.82, 0.74, 0.75)
const MAX_BEATS := 4
const CARD_SECS := 3.6

# Story order. [header, per-run way_<scene> flag] (text from ProgressData.ITEMS) or [header, "", callable-ish key]
const ORDER := [
	["THE CAMP", "#camp"],
	["THE BRIDGE TROLL", "troll"],
	["THE GOBLIN THRONE", "village"],
	["METOCY MART", "mart"],
	["THE RAT COLONY", "rats"],
	["THE DELOYE LORE LIBRARY", "#library"],
	["THE MOUNTAIN PASS", "pass"],
	["THE SUMMIT PATH", "#summit"],
	["DULBERS' AMBUSH", "ambush"],
]

var lv: Node
var stage: Control
var bg: ColorRect
var bars: Array = []
var hint: Label
var _vo: AudioStreamPlayer
var _skip_all := false
var _next := false

static func play(level: Node) -> void:
	var r := Recap.new()
	r.lv = level
	level.add_child(r)
	await r.finished

# ---------------------------------------------------------------- what happened this run
# Each beat: { head, big, quote?, who?, name?, voice? }
static func beats() -> Array:
	var out := []
	for o in ORDER:
		var key: String = o[1]
		var b := {}
		if key.begins_with("#"):
			b = _special(key)
		else:
			var way := str(Game.flags.get("way_" + key, ""))
			if way != "":
				var id := key + "_" + way
				var did := id
				for it in ProgressData.ITEMS:
					if it[0] == id:
						did = it[1]
				b = { "big": did + "." if not did.ends_with(".") and not did.ends_with("\"") else did }
				var info := ScriptScan.outcome(id)
				if str(info.get("line", "")) != "":
					b["quote"] = info["line"]
					b["who"] = str(info.get("who", ""))
					b["name"] = str(info.get("name", ""))
					b["voice"] = info["line"]
		if not b.is_empty():
			b["head"] = o[0]
			out.append(b)
	return out

static func _special(key: String) -> Dictionary:   # beats with no choice flag (DRAFT text)
	match key:
		"#camp":
			if Game.flag("campLit"):
				return { "big": "Skorn burned the map to start the fire.", "who": "skorn" }   # DRAFT
		"#library":
			if Game.flag("deloyeBad"):
				return { "big": "Xylo told Deloye \"Bad.\" Deloye has not forgotten.", "who": "deloye" }   # DRAFT
			if Game.flag("deloyeGift"):
				return { "big": "Deloye gave Xylo the Deloye Lore Neuralink.", "who": "deloye" }   # DRAFT
			if Game.flag("libEntered"):
				return { "big": "The trio got flushed into a secret library.", "who": "xylo" }   # DRAFT
		"#summit":
			if Game.flag("summitHalfway") and str(Game.flags.get("way_ambush", "")) == "":
				return { "big": "Halfway up the mountain. Mattias is waiting.", "who": "mattias" }   # DRAFT
	return {}

# ---------------------------------------------------------------- the show
func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var blur := ColorRect.new()
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = InventoryUI.BLUR_SHADER
	blur.material = mat
	add_child(blur)
	bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.025, 0.04, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var vig := ColorRect.new()   # soft vignette
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = Shader.new()
	vm.shader.code = "shader_type canvas_item;\nvoid fragment(){ vec2 d = UV - 0.5; COLOR = vec4(0,0,0, smoothstep(0.25, 0.85, length(d * vec2(1.3, 1.0))) * 0.8); }"
	vig.material = vm
	add_child(vig)
	for top in [true, false]:   # cinematic letterbox bars slide in
		var r := ColorRect.new()
		r.color = Color.BLACK
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_right = 1.0
		if top:
			r.offset_bottom = 0.0
		else:
			r.anchor_top = 1.0; r.anchor_bottom = 1.0
		add_child(r)
		bars.append(r)
	stage = Control.new()
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	hint = _lbl("E next  ·  Esc skip", 15, DIM)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.position += Vector2(-200, -34)
	hint.modulate.a = 0.0
	add_child(hint)
	_vo = AudioStreamPlayer.new()
	_vo.volume_db = linear_to_db(maxf(Game.voice_vol, 0.001))
	add_child(_vo)
	_run.call_deferred()

func _run() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(bg, "color:a", 0.62, 0.8)
	tw.tween_property(bars[0], "offset_bottom", 74.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(bars[1], "offset_top", -74.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(hint, "modulate:a", 1.0, 0.8)
	if lv and lv.has_method("play_sound"):
		lv.play_sound("sting_area", -6.0)
	await tw.finished
	await _title_card()
	var all := beats()
	for b in all.slice(maxi(0, all.size() - MAX_BEATS)):
		if _skip_all:
			break
		await _beat_card(b)
	if not _skip_all:
		await _left_off_card()
	await _close()

func _title_card() -> void:
	var box := _col()
	box.add_child(_center(_lbl("PREVIOUSLY ON", 24, GOLD, UITheme.head_font(), 10)))
	var t := _center(_lbl("TRIO ADVENTURES", 64, CREAM, UITheme.head_font(), 6))
	box.add_child(t)
	await _show(box, 2.2, true)

func _beat_card(b: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 46)
	var por := _portrait(str(b.get("who", "")))
	if por:
		row.add_child(por)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 12)
	col.custom_minimum_size.x = 640 if por else 900
	col.add_child(_lbl(str(b["head"]), 18, GOLD, UITheme.head_font(), 6))
	var big := _lbl(str(b["big"]), 34, CREAM, UITheme.head_font())
	big.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	big.custom_minimum_size.x = col.custom_minimum_size.x
	col.add_child(big)
	if b.has("quote"):
		var q := _lbl("\"%s\"" % b["quote"], 23, Color(0.93, 0.91, 0.86))
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.custom_minimum_size.x = col.custom_minimum_size.x
		col.add_child(q)
		if str(b.get("name", "")) != "":
			col.add_child(_lbl("— " + str(b["name"]), 17, DIM))
	row.add_child(col)
	var wrap := _col()
	wrap.add_child(row)
	if b.has("voice"):
		var st := VoiceLines.stream_for(str(b["voice"]))
		if st:
			_vo.stream = st
			_vo.play()
	await _show(wrap, CARD_SECS)

func _left_off_card() -> void:
	var box := _col()
	box.add_child(_center(_lbl("WHERE YOU LEFT OFF", 18, GOLD, UITheme.head_font(), 6)))
	var place := ""
	if lv and str(lv.get("subtitle")) != "":
		place = str(lv.subtitle).get_slice("— ", 1) if "— " in str(lv.subtitle) else str(lv.subtitle)
	if place != "":
		box.add_child(_center(_lbl(place, 40, CREAM, UITheme.head_font())))
	var obj := ""
	if lv and lv.get("objective_lbl") and lv.objective_lbl.visible:
		obj = lv.objective_lbl.text
	if obj != "":
		var o := _center(_lbl(obj, 22, Color(0.93, 0.91, 0.86)))
		o.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		o.custom_minimum_size.x = 900
		box.add_child(o)
	box.add_child(_gap(8))
	var bits := ["Level %d" % Game.level, "%d gold" % Game.gold, "%d%% complete" % Game.completion_pct()]
	if LostPages.count() > 0:
		bits.append("Lost Pages %d/%d" % [LostPages.count(), LostPages.AREAS.size()])
	box.add_child(_center(_lbl("  ·  ".join(bits), 18, DIM)))
	await _show(box, 2.6)

# Fades a card in, waits (E skips ahead once it's been up a moment, voice keeps the card up), fades it out.
func _show(c: Control, secs: float, slow := false) -> void:
	c.modulate.a = 0.0
	c.scale = Vector2(0.97, 0.97)
	stage.add_child(c)
	c.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	var tw := create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, 0.7 if slow else 0.45)
	tw.tween_property(c, "scale", Vector2(1.0, 1.0), secs + 1.0).set_trans(Tween.TRANS_SINE)   # slow push-in
	UITheme.play("page")
	_next = false
	var t := 0.0
	while not _skip_all:
		await get_tree().process_frame
		t += get_process_delta_time()
		if _next and t > 0.5:
			break
		if t > secs and not _vo.playing:
			break
		if t > secs + 10.0:
			break
	_vo.stop()
	var out := create_tween()
	out.tween_property(c, "modulate:a", 0.0, 0.35)
	await out.finished
	c.queue_free()

func _close() -> void:
	_vo.stop()
	for c in stage.get_children():
		c.queue_free()
	var tw := create_tween().set_parallel()
	tw.tween_property(bg, "color:a", 0.0, 0.6)
	tw.tween_property(bars[0], "offset_bottom", 0.0, 0.6)
	tw.tween_property(bars[1], "offset_top", 0.0, 0.6)
	tw.tween_property(hint, "modulate:a", 0.0, 0.3)
	for c in get_children():
		if c is ColorRect and c.material:
			tw.tween_property(c, "modulate:a", 0.0, 0.6)
	await tw.finished
	finished.emit()
	queue_free()

func _input(ev: InputEvent) -> void:
	if not ev.is_pressed() or ev.is_echo():
		return
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel") or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B):
		_skip_all = true
	elif ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept") or (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT):
		_next = true
	get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- helpers
func _portrait(who: String) -> Control:
	if who == "" or who == "narrator":
		return null
	var p := "res://assets/portraits/%s.png" % who
	if not ResourceLoader.exists(p):
		return null
	var frame := Panel.new()
	frame.custom_minimum_size = Vector2(300, 300)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_color = GOLD
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 18
	frame.add_theme_stylebox_override("panel", sb)
	frame.clip_contents = true
	var tex := TextureRect.new()
	tex.texture = load(p)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.position = Vector2(3, 3)
	tex.size = Vector2(294, 294)
	tex.pivot_offset = Vector2(147, 147)
	frame.add_child(tex)
	create_tween().tween_property(tex, "scale", Vector2(1.08, 1.08), CARD_SECS + 1.5).from(Vector2(1.0, 1.0)).set_trans(Tween.TRANS_SINE)   # Ken Burns
	return frame

func _col() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return box

func _gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = px
	return c

func _center(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _lbl(text: String, size: int, color: Color, font: Font = null, spacing := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	if font:
		if spacing != 0:
			var fv := FontVariation.new()
			fv.base_font = font
			fv.spacing_glyph = spacing
			l.add_theme_font_override("font", fv)
		else:
			l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
