# UITheme: the look of every menu (Ebain 11/24: "BG3 serious + goofy bits").
# Three themes (Settings → Display & UI → Theme): Gold & Night (default), Parchment, Wizard Arcane.
#   UITheme.c("accent")        a color from the current theme (keys in T below)
#   UITheme.panel()            the ornate panel style (chamfered corners, double gold frame, corner diamonds)
#   UITheme.row(on)            a menu row's background (selected = glowing bar with a diamond)
#   UITheme.lbl(text, 22)      a Label in the theme's font + colors; UITheme.fs(22) = size × Settings text size
#   UITheme.play("pick")       menu sounds: move · pick · back · open · page · rewind (synth or Ebain's recordings in FILES, SFX bus)
#   UITheme.bounce(control)    the little hover bounce (off when Settings → Menu animations = Calm)
# Game.ui_changed fires when the theme/sizes change, so open menus restyle themselves.
class_name UITheme
extends RefCounted

const NAMES := ["Gold & Night", "Parchment", "Wizard Arcane"]
const T := [
	{   # Gold & Night: BG3-ish dark panel, warm gold trim
		"bg": Color("#16111f"), "bg2": Color("#08060d"), "edge": Color("#c9a14a"), "edge2": Color("#6e5526"),
		"accent": Color("#ffd36b"), "text": Color("#f3ead2"), "dim": Color("#b8ad95"), "faint": Color(1, 1, 1, 0.42),
		"hi": Color("#c9a14a"), "outline": Color(0, 0, 0, 0.9), "note": Color("#d9cba6"), "bad": Color("#ff7a6a"),
		"track": Color(1, 1, 1, 0.14),
	},
	{   # Parchment: aged paper, brown ink, red wax accents
		"bg": Color("#f0e2bd"), "bg2": Color("#d6c08e"), "edge": Color("#5a3a1f"), "edge2": Color("#9a7a48"),
		"accent": Color("#8b1e1e"), "text": Color("#2b1d10"), "dim": Color("#5b4630"), "faint": Color(0.17, 0.11, 0.06, 0.5),
		"hi": Color("#8b1e1e"), "outline": Color(0, 0, 0, 0), "note": Color("#4a3520"), "bad": Color("#a02a1a"),
		"track": Color(0.2, 0.12, 0.05, 0.18),
	},
	{   # Wizard Arcane: deep violet, glowing blue runes
		"bg": Color("#170e31"), "bg2": Color("#08041a"), "edge": Color("#9a80ff"), "edge2": Color("#3f2d8a"),
		"accent": Color("#8fe3ff"), "text": Color("#ece6ff"), "dim": Color("#b3a8de"), "faint": Color(1, 1, 1, 0.42),
		"hi": Color("#8f74ff"), "outline": Color(0, 0, 0, 0.9), "note": Color("#c9bff0"), "bad": Color("#ff7aa0"),
		"track": Color(1, 1, 1, 0.14),
	},
]
const PARCHMENT := 1

static func pal(theme := -1) -> Dictionary:
	return T[clampi(Game.ui_theme if theme < 0 else theme, 0, T.size() - 1)]

static func c(key: String, theme := -1) -> Color:
	return pal(theme)[key]

static func fs(px: float) -> int:
	return roundi(px * Game.text_scale)

# ---------------------------------------------------------------- fonts
static var _head: FontVariation
static var _row: FontVariation

static func head_font() -> Font:   # titles: Cinzel, heavier, spaced out
	if _head == null:
		_head = FontVariation.new()
		_head.base_font = load("res://assets/fonts/Cinzel.ttf")
		_head.variation_embolden = 0.7
		_head.spacing_glyph = 2
	return _head

static func row_font() -> Font:    # menu rows: Cinzel
	if _row == null:
		_row = FontVariation.new()
		_row.base_font = load("res://assets/fonts/Cinzel.ttf")
		_row.variation_embolden = 0.35
		_row.spacing_glyph = 1
	return _row

# A themed Label. color = a theme key ("text", "accent"…) or a Color. font = null → default (readable small text).
static func lbl(text: String, size: float, color: Variant = "text", font: Font = null, theme := -1) -> Label:
	var l := Label.new()
	l.text = text
	style_lbl(l, size, color, font, theme)
	return l

static func style_lbl(l: Label, size: float, color: Variant = "text", font: Font = null, theme := -1) -> void:
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", c(color, theme) if color is String else color)
	var ol := c("outline", theme)
	l.add_theme_color_override("font_outline_color", ol)
	l.add_theme_constant_override("outline_size", 0 if ol.a < 0.05 else maxi(3, roundi(size / 6.0)))
	if font:
		l.add_theme_font_override("font", font)

# ---------------------------------------------------------------- styles
static func panel(alpha := 0.96, theme := -1) -> StyleBox:
	var b := OrnateBox.new()
	var p := pal(theme)
	b.fill = Color(p["bg"], alpha)
	b.fill2 = Color(p["bg2"], alpha)
	b.edge = p["edge"]
	b.edge2 = p["edge2"]
	return b

static func row(on: bool, theme := -1) -> StyleBox:
	var b := RowBox.new()
	b.on = on
	b.hi = c("hi", theme)
	b.mark = c("accent", theme)
	return b

# A small themed button (Library "Lyrics", etc.)
static func button(text: String, size := 17.0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	style_button(b, size)
	return b

static func style_button(b: Button, size := 17.0) -> void:
	b.add_theme_font_override("font", row_font())
	b.add_theme_font_size_override("font_size", fs(size))
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		var hot: bool = st == "hover" or st == "pressed"
		sb.bg_color = Color(c("hi"), 0.38 if hot else 0.14)
		sb.border_color = c("accent") if hot else c("edge2")
		sb.set_border_width_all(2 if hot else 1)
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 12; sb.content_margin_right = 12; sb.content_margin_top = 3; sb.content_margin_bottom = 3
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", c("text"))
	b.add_theme_color_override("font_hover_color", c("accent"))
	b.add_theme_color_override("font_pressed_color", c("accent"))
	b.add_theme_color_override("font_disabled_color", c("faint"))

# ---------------------------------------------------------------- mouse hover (Ebain: "finicky, it jumps to the next one")
# A row only takes the highlight from the mouse on REAL mouse movement (an InputEventMouseMotion), never from
# mouse_entered: that one also fires when the layout shifts under a still cursor (a note changes height, a row
# bounces), which made the selection hop. After keyboard/controller navigation the mouse must travel a few pixels
# before it takes over again, so a bumped desk doesn't undo your arrow-key choice.
static var _hover_acc := 99.0

static func key_nav() -> void:   # call when the keyboard/controller moves the selection
	_hover_acc = 0.0

static func hover_moved(ev: InputEvent) -> bool:
	if not (ev is InputEventMouseMotion):
		return false
	_hover_acc += ev.relative.length()
	return _hover_acc > 8.0

# ---------------------------------------------------------------- motion
static func bounce(n: Control, amount := 0.05) -> void:
	if not Game.ui_bouncy or not is_instance_valid(n) or not n.is_inside_tree():
		return
	n.pivot_offset = Vector2(0, n.size.y * 0.5)
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2(1.0 + amount, 1.0 + amount), 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(n, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func squash(n: Control) -> void:   # on pick: a quick press-in
	if not Game.ui_bouncy or not is_instance_valid(n) or not n.is_inside_tree():
		return
	n.pivot_offset = n.size * 0.5
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2(0.96, 0.96), 0.05)
	tw.tween_property(n, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

static func pop_in(n: Control) -> void:    # a panel appearing
	n.modulate.a = 0.0
	n.pivot_offset = n.size * 0.5
	n.scale = Vector2(0.94, 0.94) if Game.ui_bouncy else Vector2.ONE
	var tw := n.create_tween().set_parallel()
	tw.tween_property(n, "modulate:a", 1.0, 0.16)
	if Game.ui_bouncy:
		tw.tween_property(n, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ---------------------------------------------------------------- sounds (made in code, cached)
static var _players := {}
# Real recordings that replace a synth sound (Ebain's sfx pack, 11/26). Others stay made in code.
const FILES := { "move": "res://assets/sounds/ui_switch.ogg", "page": "res://assets/sounds/sfx_page_flip.ogg",
	"rewind": "res://assets/sounds/sfx_pages_rewind.ogg" }   # rewind: dialogue Backspace (go back a line)
static var _streams := {}

static func play(kind: String, pitch := 1.0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var p: AudioStreamPlayer = _players.get(kind)
	if p == null or not is_instance_valid(p):
		var root := (Engine.get_main_loop() as SceneTree).root
		p = AudioStreamPlayer.new()
		p.stream = load(FILES[kind]) if FILES.has(kind) and ResourceLoader.exists(FILES[kind]) else _sound(kind)
		p.bus = &"SFX"
		p.max_polyphony = 3
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		p.volume_db = { "move": -17.0, "pick": -11.0, "back": -12.0, "open": -13.0, "page": -9.0, "rewind": -11.0 }.get(kind, -12.0)
		root.add_child.call_deferred(p)
		_players[kind] = p
		await p.ready
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()

static func _sound(kind: String) -> AudioStreamWAV:
	if _streams.has(kind):
		return _streams[kind]
	var rate := 22050
	var s := PackedFloat32Array()
	match kind:
		"move":   # soft wooden tick
			s = _tone(rate, 0.045, [[1650.0, 0.6], [3300.0, 0.15]], 90.0)
			var n := _noise(rate, 0.012, 0.35, 0.5)
			for i in n.size():
				s[i] += n[i]
		"pick":   # two-note chime, rising
			s = _tone(rate, 0.11, [[660.0, 0.5], [1320.0, 0.18]], 22.0)
			s.append_array(_tone(rate, 0.24, [[990.0, 0.55], [1980.0, 0.2], [2970.0, 0.06]], 12.0))
		"back":   # two-note, falling
			s = _tone(rate, 0.08, [[560.0, 0.45], [1120.0, 0.1]], 28.0)
			s.append_array(_tone(rate, 0.16, [[420.0, 0.45], [840.0, 0.1]], 18.0))
		"open":   # low swell + shimmer
			s = _tone(rate, 0.32, [[220.0, 0.35], [440.0, 0.2], [1760.0, 0.05]], 7.0, 0.05)
		"page":   # paper flip: filtered noise that swells and dies
			s = _noise(rate, 0.2, 0.16, 0.7, true)
	_streams[kind] = _wav(rate, s)
	return _streams[kind]

static func _tone(rate: int, secs: float, partials: Array, decay: float, attack := 0.004) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(rate * secs))
	for i in out.size():
		var t := float(i) / rate
		var env := minf(1.0, t / attack) * exp(-t * decay)
		var v := 0.0
		for p in partials:
			v += sin(TAU * p[0] * t) * p[1]
		out[i] = v * env
	return out

static func _noise(rate: int, secs: float, lowpass: float, vol: float, swell := false) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(rate * secs))
	var y := 0.0
	for i in out.size():
		var t := float(i) / out.size()
		y += (randf_range(-1.0, 1.0) - y) * lowpass
		var env := sin(PI * t) * (0.6 + 0.4 * sin(TAU * 18.0 * t)) if swell else exp(-t * 6.0)
		out[i] = y * env * vol * 2.0
	return out

static func _wav(rate: int, s: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w

# ---------------------------------------------------------------- drawn pieces
# The panel: chamfered corners, vertical gradient, outer + inner frame, corner diamonds, a gem on top.
class OrnateBox extends StyleBox:
	var fill := Color.BLACK
	var fill2 := Color.BLACK
	var edge := Color.WHITE
	var edge2 := Color.GRAY
	var cut := 12.0

	func _init() -> void:
		content_margin_left = 32; content_margin_right = 32
		content_margin_top = 24; content_margin_bottom = 20

	func _shape(r: Rect2, k: float) -> PackedVector2Array:
		var a := r.position
		var b := r.end
		return PackedVector2Array([Vector2(a.x + k, a.y), Vector2(b.x - k, a.y), Vector2(b.x, a.y + k), Vector2(b.x, b.y - k),
			Vector2(b.x - k, b.y), Vector2(a.x + k, b.y), Vector2(a.x, b.y - k), Vector2(a.x, a.y + k)])

	func _draw(ci: RID, r: Rect2) -> void:
		var rs := RenderingServer
		for i in 3:   # soft drop shadow
			rs.canvas_item_add_polygon(ci, _offset(_shape(r.grow(2.0 + i * 4.0), cut + 3.0 + i * 3.0), Vector2(0, 6)), [Color(0, 0, 0, 0.12 * fill.a)])
		var pts := _shape(r, cut)
		var cols := PackedColorArray()
		for p in pts:
			cols.append(fill.lerp(fill2, clampf((p.y - r.position.y) / maxf(r.size.y, 1.0), 0.0, 1.0)))
		rs.canvas_item_add_polygon(ci, pts, cols)
		var outer := pts.duplicate()
		outer.append(pts[0])
		rs.canvas_item_add_polyline(ci, outer, [edge], 2.0, true)
		var inner := _shape(r.grow(-6.0), cut - 3.0)
		inner.append(inner[0])
		rs.canvas_item_add_polyline(ci, inner, [Color(edge2, 0.9)], 1.0, true)
		var g := r.grow(-6.0)
		for p in [g.position, Vector2(g.end.x, g.position.y), g.end, Vector2(g.position.x, g.end.y)]:
			_diamond(ci, p, 4.0, edge)
		var top := Vector2(r.get_center().x, r.position.y)   # gem on the top edge, with fading wings
		for side in [-1.0, 1.0]:
			rs.canvas_item_add_polyline(ci, [top + Vector2(side * 10.0, 0), top + Vector2(side * minf(90.0, r.size.x * 0.25), 0)], [edge, Color(edge, 0.0)], 3.0, true)
		_diamond(ci, top, 7.0, edge)
		_diamond(ci, top, 3.5, fill2.lerp(edge, 0.25))

	func _offset(p: PackedVector2Array, d: Vector2) -> PackedVector2Array:
		for i in p.size():
			p[i] += d
		return p

	func _diamond(ci: RID, c: Vector2, s: float, col: Color) -> void:
		RenderingServer.canvas_item_add_polygon(ci, [c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)], [col])

# A menu row: selected = a glowing bar fading to the right, a bright edge on the left and a diamond marker.
class RowBox extends StyleBox:
	var on := false
	var hi := Color.WHITE
	var mark := Color.WHITE

	func _init() -> void:
		content_margin_left = 30; content_margin_right = 12
		content_margin_top = 3; content_margin_bottom = 3

	func _draw(ci: RID, r: Rect2) -> void:
		if not on:
			return
		var rs := RenderingServer
		var a := r.position
		var b := r.end
		rs.canvas_item_add_polygon(ci, [a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)],
			[Color(hi, 0.42), Color(hi, 0.0), Color(hi, 0.0), Color(hi, 0.42)])
		rs.canvas_item_add_polyline(ci, [a + Vector2(0, 1), Vector2(b.x, a.y + 1)], [Color(mark, 0.6), Color(mark, 0.0)], 1.0)
		rs.canvas_item_add_polyline(ci, [Vector2(a.x, b.y - 1), b - Vector2(0, 1)], [Color(mark, 0.6), Color(mark, 0.0)], 1.0)
		rs.canvas_item_add_rect(ci, Rect2(a, Vector2(3, r.size.y)), mark)
		var cy := r.get_center().y
		var c := Vector2(a.x + 15, cy)
		rs.canvas_item_add_polygon(ci, [c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)], [mark])

# Small drawn icons (fonts don't have these glyphs): play, pause, lock, left/right arrows, note.
class Icon extends Control:
	var kind := "play"
	var col := Color.WHITE

	func _init(k := "play", sz := 18.0) -> void:
		kind = k
		custom_minimum_size = Vector2(sz, sz)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func set_kind(k: String, c: Color) -> void:
		if k != kind or c != col:
			kind = k
			col = c
			queue_redraw()

	func _draw() -> void:
		var s := size
		var m := s * 0.5
		match kind:
			"play":
				draw_colored_polygon([Vector2(s.x * 0.22, s.y * 0.12), Vector2(s.x * 0.88, m.y), Vector2(s.x * 0.22, s.y * 0.88)], col)
			"pause":
				draw_rect(Rect2(s.x * 0.2, s.y * 0.14, s.x * 0.22, s.y * 0.72), col)
				draw_rect(Rect2(s.x * 0.58, s.y * 0.14, s.x * 0.22, s.y * 0.72), col)
			"lock":
				draw_rect(Rect2(s.x * 0.18, s.y * 0.45, s.x * 0.64, s.y * 0.45), col)
				draw_arc(Vector2(m.x, s.y * 0.45), s.x * 0.22, PI, TAU, 12, col, 2.5)
			"left":
				draw_colored_polygon([Vector2(s.x * 0.75, s.y * 0.2), Vector2(s.x * 0.25, m.y), Vector2(s.x * 0.75, s.y * 0.8)], col)
			"right":
				draw_colored_polygon([Vector2(s.x * 0.25, s.y * 0.2), Vector2(s.x * 0.75, m.y), Vector2(s.x * 0.25, s.y * 0.8)], col)
			"note":
				draw_circle(Vector2(s.x * 0.32, s.y * 0.76), s.x * 0.17, col)
				draw_circle(Vector2(s.x * 0.78, s.y * 0.66), s.x * 0.17, col)
				draw_rect(Rect2(s.x * 0.44, s.y * 0.16, s.x * 0.07, s.y * 0.6), col)
				draw_rect(Rect2(s.x * 0.9, s.y * 0.06, s.x * 0.07, s.y * 0.6), col)
				draw_colored_polygon([Vector2(s.x * 0.44, s.y * 0.16), Vector2(s.x * 0.97, s.y * 0.06), Vector2(s.x * 0.97, s.y * 0.2), Vector2(s.x * 0.44, s.y * 0.3)], col)

# A divider under titles: a line fading out both ways with a diamond in the middle.
class Divider extends Control:
	func _init(w := 0.0) -> void:
		custom_minimum_size = Vector2(w, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var y := size.y * 0.5
		var mid := size.x * 0.5
		var e := UITheme.c("edge")
		draw_polyline_colors([Vector2(mid * 0.1, y), Vector2(mid - 10, y)], [Color(e, 0.0), e], 1.5, true)
		draw_polyline_colors([Vector2(mid + 10, y), Vector2(size.x - mid * 0.1, y)], [e, Color(e, 0.0)], 1.5, true)
		draw_colored_polygon([Vector2(mid, y - 5), Vector2(mid + 5, y), Vector2(mid, y + 5), Vector2(mid - 5, y)], UITheme.c("accent"))
