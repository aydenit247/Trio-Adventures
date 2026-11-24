extends Control
class_name Minimap

# Top-left minimap (Asar). Simple shapes: the area, its clearing and paths, fog where you haven't been, and dots.
# It turns with the camera, so "up" on the minimap is the way the camera looks.
# Dot colors (Asar): Xylo red, Skorn purple, Lykor yellow, buildings blue, NPCs white, heal spots green,
# objective = gold star, Diddy Chud Giant = big pulsing star. Points come from Level.map_points().

const SIZE := 200.0          # whole widget, frame included
const PAD := 11.0            # frame thickness
const METERS := 46.0         # how much world the view shows across
const GOLD := Color("#e8b923")

const COLORS := {
	"xylo": Color("#e8413a"), "skorn": Color("#a259e8"), "lykor": Color("#f5d327"), "chief": Color("#ff9a3c"),
	"building": Color("#3f8cff"), "npc": Color("#ffffff"), "heal": Color("#3ee66b"),
	"objective": Color("#ffd75a"), "giant": Color("#ff5a2a"),
}
const GROUND := Color("#24331f")
const WALK := Color("#34492b")
const PATH := Color("#8a7350")
const FOG := Color(0.05, 0.05, 0.07, 0.86)

var lv: Node
var view: Control
var heading := {}             # unit -> last direction it moved (world x/z), for the leader's arrow
var fog_tex: ImageTexture
var _fog_sum := -1
var _fog_t := 0.0

func _ready() -> void:
	position = Vector2(16, 16)
	size = Vector2(SIZE, SIZE + 18)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	view = Control.new()
	view.position = Vector2(PAD, PAD)
	view.size = Vector2(SIZE - PAD * 2, SIZE - PAD * 2)
	view.clip_contents = true
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # soft fog edges
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.draw.connect(_draw_view)
	add_child(view)
	var hint := Label.new()
	hint.text = "M  map"
	hint.position = Vector2(0, SIZE + 1)
	hint.size = Vector2(SIZE, 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 4)
	add_child(hint)

func _process(delta: float) -> void:
	if not visible or lv == null:
		return
	for u in lv.party:
		if is_instance_valid(u):
			var v := Vector2(u.velocity.x, u.velocity.z)
			if v.length() > 0.5:
				heading[u] = v.normalized()
	_fog_t -= delta
	if _fog_t <= 0.0:
		_fog_t = 0.4
		_update_fog()
	view.queue_redraw()
	queue_redraw()

# ---- shared helpers (MapUI uses them too)
static func fog_texture(level: Node, old: ImageTexture) -> ImageTexture:
	var g: Vector2i = level.seen_grid()
	var a: PackedByteArray = level.seen_cells()
	var img := Image.create(maxi(g.x, 1), maxi(g.y, 1), false, Image.FORMAT_RGBA8)
	for y in g.y:
		for x in g.x:
			img.set_pixel(x, y, Color(FOG, 0.0) if a[y * g.x + x] != 0 else FOG)
	if old and old.get_width() == img.get_width() and old.get_height() == img.get_height():
		old.update(img)
		return old
	return ImageTexture.create_from_image(img)

func _update_fog() -> void:
	var a: PackedByteArray = lv.seen_cells()
	var sum := 0
	for b in a:
		sum += b
	if sum == _fog_sum and fog_tex:
		return
	_fog_sum = sum
	fog_tex = fog_texture(lv, fog_tex)

# Draws the ground, clearing, paths and fog in world x/z units. Call after draw_set_transform_matrix(world -> screen).
static func draw_terrain(c: CanvasItem, level: Node, fog: ImageTexture, px_per_m: float) -> void:
	var r: Rect2 = level.map_rect()
	c.draw_rect(r.grow(60.0), GROUND)
	c.draw_rect(r, WALK)
	if level.clear_radius > 0.0:
		c.draw_circle(level.clear_center, level.clear_radius, PATH.darkened(0.15))
	var pts: PackedVector2Array = level.path_pts
	if pts.size() >= 2:
		c.draw_polyline(pts, PATH, level.path_width * 2.0, true)
		for p in pts:
			c.draw_circle(p, level.path_width, PATH)
	if fog:
		c.draw_texture_rect(fog, Rect2(r.position, Vector2(fog.get_width(), fog.get_height()) * level.SEEN_CELL), false)

static func star_points(center: Vector2, r_out: float, r_in: float, rot := -PI / 2.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 10:
		var r := r_out if i % 2 == 0 else r_in
		out.append(center + Vector2.RIGHT.rotated(rot + i * PI / 5.0) * r)
	return out

# One dot. at = screen position, dir = screen direction the leader faces (arrow), t = time for pulsing.
static func draw_point(c: CanvasItem, kind: String, at: Vector2, scale: float, t: float, leader := false, dir := Vector2.UP) -> void:
	var col: Color = COLORS.get(kind, COLORS["npc"])
	match kind:
		"objective":
			c.draw_colored_polygon(star_points(at, 8.5 * scale, 3.8 * scale), Color.BLACK)
			c.draw_colored_polygon(star_points(at, 7.0 * scale, 3.0 * scale), col)
		"giant":
			var p := 1.0 + 0.22 * sin(t * 5.0)
			c.draw_circle(at, 15.0 * scale * p, Color(col, 0.22))
			c.draw_colored_polygon(star_points(at, 13.0 * scale * p, 5.6 * scale * p), Color.BLACK)
			c.draw_colored_polygon(star_points(at, 11.0 * scale * p, 4.6 * scale * p), col)
		"building":
			c.draw_circle(at, 5.6 * scale, Color.BLACK)
			c.draw_circle(at, 4.4 * scale, col)
		"heal":
			c.draw_circle(at, 5.4 * scale, Color.BLACK)
			c.draw_circle(at, 4.3 * scale, col)
		"npc":
			c.draw_circle(at, 3.9 * scale, Color.BLACK)
			c.draw_circle(at, 2.9 * scale, col)
		_:   # party members
			if leader:
				var d := dir.normalized() if dir.length() > 0.01 else Vector2.UP
				var side := Vector2(-d.y, d.x)
				var tri := PackedVector2Array([at + d * 9.0 * scale, at - d * 5.0 * scale + side * 6.5 * scale, at - d * 2.5 * scale, at - d * 5.0 * scale - side * 6.5 * scale])
				var big := PackedVector2Array()
				for q in tri:
					big.append(at + (q - at) * 1.3)
				c.draw_colored_polygon(big, Color.BLACK)
				c.draw_colored_polygon(tri, col)
			else:
				c.draw_circle(at, 5.4 * scale, Color.BLACK)
				c.draw_circle(at, 4.3 * scale, col)

# ---- the minimap itself
func _world_to_view(p: Vector3, center: Vector3, s: float) -> Vector2:
	return Vector2(p.x - center.x, p.z - center.z).rotated(lv.yaw) * s + view.size * 0.5

func _draw_view() -> void:
	if lv == null or lv.leader == null:
		return
	var vs := view.size
	var place: String = lv.map_place()
	if place != "":   # inside a building: no world map, just where you are
		view.draw_rect(Rect2(Vector2.ZERO, vs), GROUND.darkened(0.3))
		var f := ThemeDB.fallback_font
		view.draw_string(f, Vector2(0, vs.y * 0.45), "Inside", HORIZONTAL_ALIGNMENT_CENTER, vs.x, 15, Color(1, 1, 1, 0.6))
		view.draw_string(f, Vector2(4, vs.y * 0.45 + 24), place, HORIZONTAL_ALIGNMENT_CENTER, vs.x - 8, 17, GOLD)
		return
	var s := vs.x / METERS
	var center: Vector3 = lv.leader.global_position
	# world (x, z) -> view: translate, rotate with the camera, scale
	var xf := Transform2D(lv.yaw, Vector2(s, s), 0.0, vs * 0.5) * Transform2D(0.0, Vector2(-center.x, -center.z))
	view.draw_set_transform_matrix(xf)
	draw_terrain(view, lv, fog_tex, s)
	view.draw_set_transform_matrix(Transform2D.IDENTITY)
	var edge := Rect2(Vector2(10, 10), vs - Vector2(20, 20))
	var tt: float = lv.t
	var seen: PackedByteArray = lv.seen_cells()
	for pt in lv.map_points():
		var at := _world_to_view(pt["pos"], center, s)
		var kind: String = pt["kind"]
		if not Rect2(Vector2.ZERO, vs).grow(-2).has_point(at):
			if kind in ["objective", "giant"]:   # off the minimap: pin to the edge so you know which way to go
				at = Vector2(clampf(at.x, edge.position.x, edge.end.x), clampf(at.y, edge.position.y, edge.end.y))
			else:
				continue
		if kind in ["building", "npc", "heal"] and not _seen_at(pt["pos"], seen):
			continue   # still in the fog
		var dir := Vector2.UP
		if pt.get("leader", false):
			var h: Vector2 = heading.get(pt["unit"], Vector2(0, -1))
			dir = h.rotated(lv.yaw)
		draw_point(view, kind, at, 1.0, tt, pt.get("leader", false), dir)

func _seen_at(p: Vector3, seen: PackedByteArray) -> bool:
	var r: Rect2 = lv.map_rect()
	var g: Vector2i = lv.seen_grid()
	var c := Vector2i(int((p.x - r.position.x) / lv.SEEN_CELL), int((p.z - r.position.y) / lv.SEEN_CELL))
	if c.x < 0 or c.y < 0 or c.x >= g.x or c.y >= g.y:
		return true
	return seen[c.y * g.x + c.x] != 0

# The frame: the themed ornate panel (UITheme, follows Settings → Menu theme) and a little compass needle
# (red = north) that turns with the camera.
func _draw() -> void:
	var r := Rect2(Vector2.ZERO, Vector2(SIZE, SIZE))
	draw_style_box(UITheme.panel(0.95), r)
	draw_rect(Rect2(Vector2(PAD - 1, PAD - 1), Vector2(SIZE - PAD * 2 + 2, SIZE - PAD * 2 + 2)), Color.BLACK, false, 2.0)
	var edge_c := UITheme.c("edge")
	# compass in the bottom-right stud area, overlapping the frame
	var cc := Vector2(SIZE - 24, SIZE - 24)
	draw_circle(cc, 15.0, UITheme.c("bg2"))
	draw_arc(cc, 15.0, 0, TAU, 32, edge_c, 2.0, true)
	var north := Vector2(0, -1).rotated(lv.yaw if lv else 0.0)   # world -z (north) on the minimap
	var side := Vector2(-north.y, north.x)
	draw_colored_polygon(PackedVector2Array([cc + north * 11, cc + side * 4, cc - side * 4]), Color("#e8413a"))
	draw_colored_polygon(PackedVector2Array([cc - north * 11, cc + side * 4, cc - side * 4]), Color("#d8d0c0"))
	draw_circle(cc, 2.0, edge_c)
	var f := ThemeDB.fallback_font
	draw_string(f, cc + north * 21 - Vector2(4, -5), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, edge_c)

static func _box(bg: Color, border: Color, w: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.draw_center = bg.a > 0.0
	sb.border_color = border
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	return sb
