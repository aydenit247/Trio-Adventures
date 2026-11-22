extends Control
class_name MapUI

# M: the big map (Asar). Two tabs:
#   Area  - this whole area, north up, with the same dots as the minimap and fog over places you haven't walked yet.
#   World - the journey (Camp → Goblin Village → Metocy Mart → The Pass), fog over areas you haven't been to.
# Q/E or ←/→ (or click a tab) switches tabs. M, Tab or Esc closes. Hover a dot to see what it is.

signal closed

const W := 1040.0
const H := 640.0
const GOLD := Color("#e8b923")
const INK := Color("#f3e3b0")
const WORLD := [   # area key, name, spot on the world tab (inside the map box)
	["camp", "The Camp", Vector2(0.14, 0.78)],
	["village", "Goblin Village", Vector2(0.36, 0.38)],
	["mart", "Metocy Mart", Vector2(0.62, 0.62)],
	["pass", "The Pass", Vector2(0.86, 0.24)],
]

var lv: Node
var tab := "area"
var root: Control
var box: Control          # where the map is drawn
var legend: VBoxContainer
var tabs := {}            # name -> Button
var hover_lbl: Label
var fog_tex: ImageTexture
var _opened_at := 0
var _hits: Array = []     # [[screen pos, name]] for hovering

static func open(parent: Node, level: Node) -> MapUI:
	var m := MapUI.new()
	m.lv = level
	parent.add_child(m)
	m._build()
	return m

func _build() -> void:
	_opened_at = Engine.get_process_frames()
	MenuUI.stack.append(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var blur := ColorRect.new()
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = InventoryUI.BLUR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	blur.material = mat
	add_child(blur)

	root = Control.new()
	root.anchor_left = 0.5; root.anchor_right = 0.5; root.anchor_top = 0.5; root.anchor_bottom = 0.5
	root.offset_left = -W / 2; root.offset_right = W / 2; root.offset_top = -H / 2; root.offset_bottom = H / 2
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _box(Color("#2a2420"), Color("#4d443b"), 4, 10, true))
	root.add_child(frame)
	var trim := Panel.new()
	trim.position = Vector2(9, 9); trim.size = Vector2(W - 18, H - 18)
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trim.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), Color(GOLD, 0.55), 2, 6))
	root.add_child(trim)
	for c in [Vector2(2, 2), Vector2(W - 26, 2), Vector2(2, H - 26), Vector2(W - 26, H - 26)]:
		var stud := Panel.new()
		stud.position = c; stud.size = Vector2(24, 24)
		stud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stud.add_theme_stylebox_override("panel", _box(Color("#3b332c"), GOLD, 2, 4))
		root.add_child(stud)

	var title := _lbl("MAP", 30, GOLD, 7)
	title.position = Vector2(36, 18)
	root.add_child(title)
	var tb := HBoxContainer.new()
	tb.position = Vector2(150, 24)
	tb.add_theme_constant_override("separation", 8)
	root.add_child(tb)
	for k in ["area", "world"]:
		var b := Button.new()
		b.text = "Area" if k == "area" else "World"
		b.custom_minimum_size = Vector2(110, 34)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(func(): _set_tab(k))
		tb.add_child(b)
		tabs[k] = b
	var keys := _lbl("Q/E: switch tab  ·  M / Esc: close", 14, Color(1, 1, 1, 0.6), 4)
	keys.position = Vector2(W - 300, 30)
	keys.size = Vector2(264, 20)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(keys)

	box = Control.new()
	box.position = Vector2(30, 72); box.size = Vector2(W - 260, H - 102)
	box.clip_contents = true
	box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # soft fog edges
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.draw.connect(_draw_box)
	box.gui_input.connect(_box_input)
	root.add_child(box)
	var edge := Panel.new()
	edge.position = box.position - Vector2(2, 2); edge.size = box.size + Vector2(4, 4)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0), Color.BLACK, 2, 2))
	root.add_child(edge)

	legend = VBoxContainer.new()
	legend.position = Vector2(W - 210, 80); legend.size = Vector2(180, H - 120)
	legend.add_theme_constant_override("separation", 6)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(legend)

	hover_lbl = _lbl("", 16, Color.WHITE, 5)
	hover_lbl.visible = false
	hover_lbl.z_index = 5
	root.add_child(hover_lbl)
	fog_tex = Minimap.fog_texture(lv, null)
	_set_tab("area")

func _set_tab(k: String) -> void:
	tab = k
	for n in tabs:
		var on: bool = n == k
		tabs[n].add_theme_stylebox_override("normal", _box(Color("#4a3c22") if on else Color("#1d1814"), GOLD if on else Color("#4d443b"), 2, 5))
		tabs[n].add_theme_stylebox_override("hover", _box(Color("#5a4a2a"), GOLD, 2, 5))
		tabs[n].add_theme_stylebox_override("pressed", _box(Color("#5a4a2a"), GOLD, 2, 5))
		tabs[n].add_theme_color_override("font_color", GOLD if on else Color(1, 1, 1, 0.75))
	_build_legend()
	hover_lbl.visible = false
	box.queue_redraw()

func _process(_d: float) -> void:
	box.queue_redraw()   # pulsing giant star / "you are here"

# ---------------------------------------------------------------- drawing
func _area_xf() -> Array:   # [Transform2D world->box, px per meter]
	var r: Rect2 = lv.map_rect()
	var s: float = minf((box.size.x - 40) / r.size.x, (box.size.y - 40) / r.size.y)
	var off: Vector2 = (box.size - r.size * s) * 0.5 - r.position * s
	return [Transform2D(0.0, Vector2(s, s), 0.0, off), s]

func _draw_box() -> void:
	_hits = []
	if tab == "area":
		_draw_area()
	else:
		_draw_world()

func _draw_area() -> void:
	var place: String = lv.map_place()
	var a := _area_xf()
	var xf: Transform2D = a[0]
	var s: float = a[1]
	box.draw_set_transform_matrix(xf)
	Minimap.draw_terrain(box, lv, fog_tex, s)
	box.draw_set_transform_matrix(Transform2D.IDENTITY)
	var seen: PackedByteArray = lv.seen_cells()
	var r: Rect2 = lv.map_rect()
	var g: Vector2i = lv.seen_grid()
	for pt in lv.map_points():
		var kind: String = pt["kind"]
		var p: Vector3 = pt["pos"]
		if place != "" and kind in ["skorn", "lykor", "xylo", "chief"]:
			p = lv.map_place_door()   # inside a building: show the party at its door
			if p == Vector3.INF: continue
		var c := Vector2i(int((p.x - r.position.x) / lv.SEEN_CELL), int((p.z - r.position.y) / lv.SEEN_CELL))
		var hidden := c.x >= 0 and c.y >= 0 and c.x < g.x and c.y < g.y and seen[c.y * g.x + c.x] == 0
		if hidden and kind in ["building", "npc", "heal"]:
			continue
		var at := xf * Vector2(p.x, p.z)
		var dir := Vector2.UP
		if pt.get("leader", false) and lv.minimap:
			dir = lv.minimap.heading.get(pt["unit"], Vector2(0, -1))
		Minimap.draw_point(box, kind, at, 1.4, lv.t, pt.get("leader", false), dir)
		_hits.append([at, pt.get("name", "")])
	var f := ThemeDB.fallback_font
	box.draw_string(f, Vector2(14, 28), _area_name(lv.area_key()) + ("  ·  inside " + place if place != "" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)
	box.draw_string(f, Vector2(14, box.size.y - 12), "Dark = places you haven't explored yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.55))

func _draw_world() -> void:
	var bs := box.size
	box.draw_rect(Rect2(Vector2.ZERO, bs), Minimap.GROUND)
	var f := ThemeDB.fallback_font
	var here: String = lv.area_key()
	var pts := []
	for w in WORLD:
		pts.append(Vector2(w[2].x * bs.x, w[2].y * bs.y))
	# the trail between areas (dashed)
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 16.0)
		for k in n:
			if k % 2 == 0:
				box.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), Minimap.PATH, 5.0, true)
	for i in WORLD.size():
		var key: String = WORLD[i][0]
		var p: Vector2 = pts[i]
		var been: bool = Game.visited.has(key) or key == here
		if been:
			box.draw_circle(p, 34, Color.BLACK)
			box.draw_circle(p, 30, Minimap.WALK.lightened(0.15))
			box.draw_arc(p, 30, 0, TAU, 40, GOLD, 3.0, true)
			box.draw_string(f, p + Vector2(-110, 58), WORLD[i][1], HORIZONTAL_ALIGNMENT_CENTER, 220, 20, INK)
			if key == here:
				var pulse := 1.0 + 0.15 * sin(lv.t * 4.0)
				var col: Color = Minimap.COLORS.get(lv.leader.id if lv.leader else "skorn", GOLD)
				box.draw_circle(p, 12 * pulse, Color.BLACK)
				box.draw_circle(p, 9 * pulse, col)
				box.draw_string(f, p + Vector2(-110, -44), "You are here", HORIZONTAL_ALIGNMENT_CENTER, 220, 16, GOLD)
			else:
				box.draw_circle(p, 6, INK)
			_hits.append([p, WORLD[i][1]])
		else:   # fog: a clump of soft grey clouds and ???
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(key)
			for k in 14:
				var o := Vector2(rng.randf_range(-62, 62), rng.randf_range(-34, 34))
				box.draw_circle(p + o, rng.randf_range(22, 36), Color(0.62, 0.64, 0.7, 0.16))
			box.draw_circle(p, 44, Color(0.08, 0.08, 0.1, 0.75))
			box.draw_string(f, p + Vector2(-60, 9), "???", HORIZONTAL_ALIGNMENT_CENTER, 120, 26, Color(1, 1, 1, 0.55))
	box.draw_string(f, Vector2(14, 28), "The Journey", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GOLD)

func _area_name(k: String) -> String:
	for w in WORLD:
		if w[0] == k: return w[1]
	return k.capitalize()

# ---------------------------------------------------------------- legend
func _build_legend() -> void:
	for c in legend.get_children():
		c.queue_free()
	legend.add_child(_lbl("Legend", 20, GOLD, 5))
	if tab == "world":
		legend.add_child(_lbl("Areas you've been to\nshow up. The rest is\nstill in the fog.", 15, Color(1, 1, 1, 0.8), 4))
		return
	var have := {}
	for pt in lv.map_points():
		have[pt["kind"]] = true
	var rows := [["skorn", "Skorn"], ["lykor", "Lykor"], ["xylo", "Xylo"], ["chief", "Chief Bogdrinker"], ["npc", "People"],
		["building", "Buildings"], ["heal", "Heal / rest spot"], ["objective", "Objective"], ["giant", "Diddy Chud Giant"]]
	for r in rows:
		if not have.has(r[0]):
			continue
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(26, 24)
		var kind: String = r[0]
		icon.draw.connect(func(): Minimap.draw_point(icon, kind, Vector2(13, 12), 1.0 if kind != "giant" else 0.75, lv.t))
		h.add_child(icon)
		h.add_child(_lbl(r[1], 16, Color.WHITE, 4))
		legend.add_child(h)
	legend.add_child(_lbl("\nThe arrow is who\nyou're controlling.", 14, Color(1, 1, 1, 0.6), 4))

# ---------------------------------------------------------------- input
func _box_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var best := ""
		var bd := 14.0
		for h in _hits:
			var d: float = h[0].distance_to(ev.position)
			if d < bd and h[1] != "":
				bd = d
				best = h[1]
		hover_lbl.visible = best != ""
		if best != "":
			hover_lbl.text = best
			hover_lbl.position = box.position + ev.position + Vector2(14, -26)

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self:
		return
	if Engine.get_process_frames() - _opened_at < 2:
		return
	if not ev.is_pressed() or ev.is_echo() or ev is InputEventMouse:
		return
	if ev.is_action_pressed("map") or ev.is_action_pressed("party_menu") or ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel") \
			or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B):
		close()
	elif ev.is_action_pressed("switch") or ev.is_action_pressed("interact") or ev.is_action_pressed("ui_left") or ev.is_action_pressed("ui_right") \
			or (ev is InputEventKey and ev.physical_keycode in [KEY_E, KEY_Q]) \
			or (ev is InputEventJoypadButton and ev.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]):
		_set_tab("world" if tab == "area" else "area")
	get_viewport().set_input_as_handled()

func close() -> void:
	if not is_inside_tree():
		return
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)

# ---------------------------------------------------------------- helpers
func _lbl(text: String, size: int, color: Color, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _box(bg: Color, border: Color, w: int, radius: int, shadow := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.draw_center = bg.a > 0.0
	sb.border_color = border
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(radius)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.6); sb.shadow_size = 24
	return sb
