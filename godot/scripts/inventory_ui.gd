# Inventory window (Tab): a "Deloye Lore" parchment page in a smaller window, with the game still visible
# (blurred) around it. Shows one fighter at a time with 7 gear slots, the shared bag, gold, and a quest page.
#
#   var inv := InventoryUI.open(level.hud, level)
#   await inv.closed
#
# Keys: WASD/arrows move · E/Enter/Space or click = equip / take off · Q (or LB/RB, or the arrows by the name)
# = next fighter · J = quests · Tab / Esc / B = close.
extends Control
class_name InventoryUI

const CombatD = preload("res://scripts/combat/combat_data.gd")

signal closed

const W := 1000.0
const H := 620.0
const BAG_COLS := 10
const BAG_ROWS := 3
const CELL := 50.0
const GAP := 2.0
const INK := Color("#2b1d10")
const INK_SOFT := Color("#5a4630")
const GOLD := Color("#e8b923")
const DARK := Color("#1d1814")

# where each gear slot sits on the page (top-left of a 78px slot; label goes under it)
const SLOT_POS := {
	"helmet": Vector2(278, 86), "armor": Vector2(278, 206),
	"shoes": Vector2(616, 86), "shield": Vector2(616, 206),
	"weapon": Vector2(66, 370),
	"trinket1": Vector2(826, 334), "trinket2": Vector2(826, 448),
}
const SLOT_SIZE := 78.0

var lv: Node
var fighters: Array = []
var who := 0                    # index into fighters
var cells: Array = []           # [{ "kind": "slot"/"bag", "slot"/"i", "rect": Rect2, "node": Control }]
var sel := 0
var bag: Array = []             # [{ "id", "kind": "gear"/"use"/"key", "name", "desc", "count", "icon": Texture2D }]
var page := "gear"              # or "quests"
var note := ""                  # one-off message (e.g. "Equipped on Lykor")

var root: Control               # the window (parchment page lives inside)
var pagebox: Control            # everything that's redrawn
var info_lbl: Label             # description of what's selected (details card)
var info_name: Label
var info_hint: Label
var serif: SystemFont
var serif_bold: Font           # Cinzel (title + labels, like the mockup)
var script_font: Font          # Pinyon Script (the handwriting on the page + signature)
var coin_tex: Texture2D
var _opened_at := 0

static func open(parent: Node, level: Node) -> InventoryUI:
	var m := InventoryUI.new()
	m.lv = level
	parent.add_child(m)
	m._build()
	return m

func _build() -> void:
	_opened_at = Engine.get_process_frames()
	MenuUI.stack.append(self)   # so no MenuUI underneath reacts to our keys
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	fighters = lv.party_ids_for_menu()
	if lv.leader and fighters.has(lv.leader.id):
		who = fighters.find(lv.leader.id)
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Cinzel", "Trajan Pro", "Georgia", "Palatino Linotype", "Book Antiqua", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
	var cz := FontVariation.new()
	cz.base_font = load("res://assets/fonts/Cinzel.ttf")
	cz.variation_opentype = { TextServerManager.get_primary_interface().name_to_tag("wght"): 700 }
	serif_bold = cz
	script_font = load("res://assets/fonts/PinyonScript-Regular.ttf")
	coin_tex = coin_texture()

	# the game behind us, blurred and dimmed (like Minecraft's inventory)
	var blur := ColorRect.new()
	blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = BLUR_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	blur.material = mat
	add_child(blur)

	# iron frame
	root = Control.new()
	root.anchor_left = 0.5; root.anchor_right = 0.5; root.anchor_top = 0.5; root.anchor_bottom = 0.5
	root.offset_left = -W / 2; root.offset_right = W / 2; root.offset_top = -H / 2; root.offset_bottom = H / 2
	add_child(root)
	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("#2a2420"); fs.border_color = Color("#4d443b"); fs.set_border_width_all(4); fs.set_corner_radius_all(10)
	fs.shadow_color = Color(0, 0, 0, 0.6); fs.shadow_size = 24
	frame.add_theme_stylebox_override("panel", fs)
	root.add_child(frame)
	# parchment
	var parch := ColorRect.new()
	parch.position = Vector2(14, 14); parch.size = Vector2(W - 28, H - 28)
	parch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := Shader.new()
	ps.code = PARCHMENT_SHADER
	var pm := ShaderMaterial.new()
	pm.shader = ps
	parch.material = pm
	root.add_child(parch)
	var trim := Panel.new()   # thin gold line just inside the iron
	trim.position = Vector2(9, 9); trim.size = Vector2(W - 18, H - 18)
	trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts := StyleBoxFlat.new()
	ts.draw_center = false; ts.border_color = Color(GOLD, 0.55); ts.set_border_width_all(2); ts.set_corner_radius_all(6)
	trim.add_theme_stylebox_override("panel", ts)
	root.add_child(trim)
	for c in [Vector2(2, 2), Vector2(W - 26, 2), Vector2(2, H - 26), Vector2(W - 26, H - 26)]:   # corner studs
		var stud := Panel.new()
		stud.position = c; stud.size = Vector2(24, 24)
		stud.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color("#3b332c"); ss.border_color = GOLD; ss.set_border_width_all(2); ss.set_corner_radius_all(4)
		stud.add_theme_stylebox_override("panel", ss)
		stud.rotation = 0.0
		root.add_child(stud)

	pagebox = Control.new()
	pagebox.position = Vector2(14, 14); pagebox.size = Vector2(W - 28, H - 28)
	root.add_child(pagebox)
	_rebuild()

# ---------------------------------------------------------------- drawing

func _rebuild() -> void:
	for ch in pagebox.get_children():
		ch.queue_free()
	cells = []
	var pw: float = pagebox.size.x
	# old handwriting covering the page (Deloye Lore, in cursive) — behind everything else
	var hand := _txt(HANDWRITING + " " + HANDWRITING, Vector2(26, 64), 31, Color(0.22, 0.15, 0.08, 0.5 if page == "gear" else 0.22), script_font)
	hand.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hand.custom_minimum_size = Vector2(pw - 52, 0); hand.size = Vector2(pw - 52, pagebox.size.y - 70)
	hand.clip_text = true
	hand.add_theme_constant_override("line_spacing", -6)
	# title + flourish
	var title := _txt("DELOYE LORE", Vector2(0, 6), 46, INK, serif_bold)
	title.size = Vector2(pw, 56); title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(Vector2(pw / 2 - 170, 62), 340, Color(INK, 0.7))
	var dia := ColorRect.new(); dia.color = GOLD; dia.size = Vector2(9, 9); dia.position = Vector2(pw / 2 - 4.5, 58); dia.rotation_degrees = 45
	dia.pivot_offset = Vector2(4.5, 4.5); dia.mouse_filter = Control.MOUSE_FILTER_IGNORE; pagebox.add_child(dia)
	# page tabs (top left) and level (top right)
	_tab("GEAR", Vector2(22, 16), page == "gear", func(): _set_page("gear"))
	_tab("QUESTS  (J)", Vector2(92, 16), page == "quests", func(): _set_page("quests"))
	var lvl := _txt("Level %d   ·   XP %d%s" % [Game.level, Game.xp, ("   (%d to next)" % Game.xp_to_next()) if Game.xp_to_next() > 0 else ""], Vector2(pw - 330, 18), 15, INK_SOFT, serif)
	lvl.size = Vector2(310, 20); lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# close button (top right of the window)
	var x := Button.new()
	x.text = "✕"; x.flat = false; x.focus_mode = Control.FOCUS_NONE
	x.position = Vector2(pw - 2, -26); x.size = Vector2(36, 32)
	x.add_theme_color_override("font_color", Color.WHITE)
	var xs := StyleBoxFlat.new(); xs.bg_color = Color("#8e1f17"); xs.border_color = GOLD; xs.set_border_width_all(2); xs.set_corner_radius_all(5)
	x.add_theme_stylebox_override("normal", xs); x.add_theme_stylebox_override("hover", xs); x.add_theme_stylebox_override("pressed", xs)
	x.pressed.connect(close)
	pagebox.add_child(x)
	# signature
	var sig := _txt("-signed xylo", Vector2(pw - 230, pagebox.size.y - 44), 34, INK, script_font)
	sig.size = Vector2(210, 40); sig.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if page == "quests":
		_draw_quests()
	else:
		_draw_gear()
	sel = clampi(sel, 0, max(0, cells.size() - 1))
	_show_sel()

func _draw_gear() -> void:
	var pw: float = pagebox.size.x
	var fid: String = fighters[who]
	var P: Dictionary = CombatD.PARTY[fid]
	# portrait
	var pf := _framed(Rect2(386, 76, 200, 230), Color(0.07, 0.06, 0.05, 0.92))
	var tex_path := "res://assets/characters/%s.png" % ("goblin_chief" if fid == "chief" else fid)
	if ResourceLoader.exists(tex_path):
		var t := TextureRect.new()
		t.texture = load(tex_path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(8, 6); t.size = Vector2(184, 216)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pf.add_child(t)
	var S: Dictionary = Game.gear_stats(fid)
	var hp_now := Game.hp(fid)
	var hp_max := Game.max_hp(fid)
	# stats panel (right of the shoes/shield): Health blue · Armor white · Speed yellow · Damage red
	var sp := _framed(Rect2(726, 86, 226, 196), Color(0.16, 0.13, 0.1, 0.9))
	var head := _txt("STATS", Vector2(0, 8), 18, GOLD, serif_bold, sp)
	head.size = Vector2(226, 24); head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rows := [
		["Health", "%d/%d" % [hp_now, hp_max], Color("#ff6a5a") if hp_now <= hp_max * 0.3 else Color("#5ab4ff")],
		["Armor", str(S["armor"]), Color.WHITE],
		["Speed", str(P["spd"] + S["spd"]), Color("#ffd84a")],
		["Damage", "+%d%%" % int(round(S["power"] * 100)), Color("#ff5a4a")],
	]
	for k in rows.size():
		var y := 42 + k * 36
		var nl := _txt(rows[k][0] + ":", Vector2(18, y), 21, rows[k][2], serif_bold, sp)
		nl.size = Vector2(120, 28)
		nl.add_theme_color_override("font_outline_color", Color.BLACK); nl.add_theme_constant_override("outline_size", 4)
		var vl := _txt(rows[k][1], Vector2(110, y), 21, rows[k][2], serif_bold, sp)
		vl.size = Vector2(98, 28); vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_color_override("font_outline_color", Color.BLACK); vl.add_theme_constant_override("outline_size", 4)
	# name plate with arrows
	var plate := _framed(Rect2(406, 312, 160, 28), Color("#2a2420"))
	var nm := _txt(P["name"], Vector2(0, 1), 18, GOLD, serif_bold, plate)
	nm.size = Vector2(160, 24); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if fighters.size() > 1:
		_arrow("◀", Vector2(380, 310), func(): _switch(-1))
		_arrow("▶", Vector2(568, 310), func(): _switch(1))
	# gear slots
	var eq: Dictionary = Game.slots_of(fid)
	for s in Game.GEAR_SLOTS:
		var p: Vector2 = SLOT_POS[s]
		var r := Rect2(p, Vector2(SLOT_SIZE, SLOT_SIZE))
		var box := _slot_box(r, eq.get(s, ""), 0)
		var lab := _txt(Game.SLOT_NAMES[s].to_upper(), Vector2(p.x - 20, p.y + SLOT_SIZE + 2), 15, INK, serif_bold)
		lab.size = Vector2(SLOT_SIZE + 40, 20); lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cells.append({ "kind": "slot", "slot": s, "rect": r, "node": box })
	# bag
	bag = _bag_items()
	var bw := BAG_COLS * CELL + (BAG_COLS - 1) * GAP
	var bx := (pw - bw) / 2.0
	var by := 396.0
	var banner := _framed(Rect2(pw / 2 - 90, by - 34, 180, 26), Color("#2a2420"))
	var bt := _txt("INVENTORY", Vector2(0, 2), 16, GOLD, serif_bold, banner)
	bt.size = Vector2(180, 22); bt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var well := Panel.new()   # dark tray behind the grid
	well.position = Vector2(bx - 8, by - 8); well.size = Vector2(bw + 16, BAG_ROWS * CELL + (BAG_ROWS - 1) * GAP + 40)
	well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wsb := StyleBoxFlat.new(); wsb.bg_color = Color(0.11, 0.09, 0.08, 0.92); wsb.border_color = Color("#4d443b"); wsb.set_border_width_all(3); wsb.set_corner_radius_all(6)
	well.add_theme_stylebox_override("panel", wsb)
	pagebox.add_child(well)
	for i in BAG_COLS * BAG_ROWS:
		var c := Vector2(bx + (i % BAG_COLS) * (CELL + GAP), by + (i / BAG_COLS) * (CELL + GAP))
		var r := Rect2(c, Vector2(CELL, CELL))
		var it: Dictionary = bag[i] if i < bag.size() else {}
		var box := _slot_box(r, "", 1, it)
		cells.append({ "kind": "bag", "i": i, "rect": r, "node": box })
	# footer: bag count + gold
	var fy := by + BAG_ROWS * (CELL + GAP) + 6
	var used := 0
	for it in bag: used += 1
	var bc := _txt("Bag  %d / %d" % [used, BAG_COLS * BAG_ROWS], Vector2(bx + 2, fy), 15, Color("#d8c7a4"), serif)
	bc.size = Vector2(200, 20)
	var coin := TextureRect.new()
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin.texture = coin_tex; coin.size = Vector2(20, 20); coin.position = Vector2(bx + bw - 118, fy + 1)
	pagebox.add_child(coin)
	var gl := _txt("%d Gold" % Game.gold, Vector2(bx + bw - 96, fy - 1), 17, GOLD, serif_bold)
	gl.size = Vector2(96, 22); gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gl.add_theme_color_override("font_outline_color", Color.BLACK); gl.add_theme_constant_override("outline_size", 4)
	# details card (left): what's selected + what E does
	var card := _framed(Rect2(22, 86, 232, 250), Color(0.16, 0.13, 0.1, 0.9))
	info_name = _txt("", Vector2(12, 10), 18, GOLD, serif_bold, card)
	info_name.size = Vector2(208, 46); info_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_lbl = _txt("", Vector2(12, 66), 14, Color("#eadbb8"), serif, card)
	info_lbl.size = Vector2(208, 104); info_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_hint = _txt("", Vector2(12, 174), 14, Color("#ffd27a"), serif_bold, card)
	info_hint.size = Vector2(208, 44); info_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var keys := _txt("Right-click: view / give  ·  Q: next  ·  Tab: close", Vector2(12, 226), 12, Color(1, 1, 1, 0.5), serif, card)
	keys.size = Vector2(208, 18)

func _draw_quests() -> void:
	var pw: float = pagebox.size.x
	var head := _txt("QUESTS", Vector2(0, 86), 26, INK, serif_bold)
	head.size = Vector2(pw, 32); head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var txt := ""
	if Game.quests.is_empty():
		txt = "No quests yet. Talk to people. Somebody always needs a spoon found."
	for q in Game.quests.values():
		if q["state"] == "done":
			txt += "✓  %s  (done)\n\n" % q["title"]
		else:
			txt += "•  %s\n     %s\n\n" % [q["title"], q["note"]]
	var body := _txt(txt.strip_edges(), Vector2(120, 132), 17, INK, serif)
	body.size = Vector2(pw - 240, 400)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var back := _txt("J or click GEAR to go back · Tab to close", Vector2(40, pagebox.size.y - 34), 15, INK_SOFT, serif)
	back.size = Vector2(400, 24)
	info_lbl = null

# a gear slot or bag cell. style 0 = big gear slot, 1 = bag cell.
func _slot_box(r: Rect2, gear_id: String, style: int, item := {}) -> Panel:
	var box := Panel.new()
	box.position = r.position; box.size = r.size
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2b2621") if style == 0 else Color("#1c1815")
	sb.border_color = Color("#6b5b45") if style == 0 else Color("#3d352d")
	sb.set_border_width_all(3 if style == 0 else 2); sb.set_corner_radius_all(6 if style == 0 else 3)
	box.add_theme_stylebox_override("panel", sb)
	box.set_meta("sb", sb)
	pagebox.add_child(box)
	var id := gear_id if gear_id != "" else str(item.get("id", ""))
	var tex: Texture2D = lv.item_icon(id) if id != "" else null
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var m := 7.0 if style == 0 else 4.0
		t.position = Vector2(m, m); t.size = r.size - Vector2(m, m) * 2
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(t)
	elif id != "":   # no picture yet: initials
		var nm: String = CombatD.GEAR.get(id, {}).get("name", item.get("name", id))
		var ini := ""
		for w in nm.split(" ", false):
			if ini.length() < 3 and w[0] == w[0].to_upper() and w[0] != "(":
				ini += w[0]
		var l := _txt(ini, Vector2.ZERO, 22 if style == 0 else 15, Color("#e8d9b5"), serif_bold, box)
		l.size = r.size; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if int(item.get("count", 0)) > 1:
		var cnt := Label.new()
		cnt.text = str(item["count"])
		cnt.add_theme_font_size_override("font_size", 13)
		cnt.add_theme_color_override("font_color", Color.WHITE)
		cnt.add_theme_color_override("font_outline_color", Color.BLACK); cnt.add_theme_constant_override("outline_size", 4)
		cnt.position = Vector2(r.size.x - 18, r.size.y - 19); cnt.size = Vector2(16, 16)
		cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cnt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(cnt)
	var idx := cells.size()
	box.mouse_entered.connect(func(): sel = idx; _show_sel())
	box.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			sel = idx
			_activate()
		elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			sel = idx
			_show_sel()
			_open_item_menu(idx, get_global_mouse_position()))
	return box

# everything in the shared bag, in a stable order
func _bag_items() -> Array:   # what the fighter on screen carries (everyone has their own bag)
	var fid: String = fighters[who]
	var out := []
	for k in ["beer", "bowl"]:
		if Game.count(k, fid) > 0:
			out.append({ "id": k, "kind": "use", "name": CombatD.ITEMS[k]["name"], "desc": CombatD.ITEMS[k]["desc"], "count": Game.count(k, fid) })
	for k in CombatD.BOOSTS:
		if Game.count(k, fid) > 0:
			var B: Dictionary = CombatD.BOOSTS[k]
			out.append({ "id": k, "kind": "boost", "name": B["name"], "desc": B["desc"], "count": Game.count(k, fid) })
	for g in Game.gear_in_bag(fid):
		if CombatD.GEAR.has(g):
			var G: Dictionary = CombatD.GEAR[g]
			out.append({ "id": g, "kind": "gear", "name": G.get("name", g), "desc": G.get("desc", ""), "count": 1 })
	var keys := []
	if Game.flag("hasMap"):
		keys.append({ "id": "metocy_map", "kind": "key", "name": "Metocy Map (firestarter)", "desc": "The map to the metocy. Lykor packed it. Skorn has other plans for it.", "count": 1 })
	if Game.flag("hasMidtocy"):
		keys.append({ "id": "midtocy", "kind": "key", "name": "Midtocy", "desc": "The fake metocy. Skorn swears it's fine. It is not fine.", "count": 1 })
	if Game.flag("luckySpoonFound") and Game.quest_state("lucky_spoon") == "active":
		keys.append({ "id": "lucky_spoon", "kind": "key", "name": "Grubnik's Lucky Spoon", "desc": "Covered in patrol grease. Grubnik misses it.", "count": 1 })
	var spoons := int(Game.flags.get("spoons_found", 0))
	if spoons > 0 and not Game.gear_owned.has("spoon_mail"):
		keys.append({ "id": "shiny_spoon", "kind": "key", "name": "Shiny Spoons", "desc": "For Clank the Spoonsmith. 3 = a weapon, 5 = armor.", "count": spoons })
	for k in keys:
		if Game.owner_of_key(k["id"]) == fid:
			out.append(k)
	return out

# ---------------------------------------------------------------- selection + actions

func _show_sel() -> void:
	for i in cells.size():
		var sb: StyleBoxFlat = cells[i]["node"].get_meta("sb")
		var on := i == sel
		var base := Color("#6b5b45") if cells[i]["kind"] == "slot" else Color("#3d352d")
		sb.border_color = GOLD if on else base
	if info_lbl == null or page != "gear":
		return
	var d := _describe(sel)
	info_name.text = d[0]; info_lbl.text = d[1]; info_hint.text = note if note != "" else d[2]

func _describe(i: int) -> Array:   # [name, description, what E does]
	if i < 0 or i >= cells.size():
		return ["", "", ""]
	var c: Dictionary = cells[i]
	var fname: String = CombatD.PARTY[fighters[who]]["name"]
	if c["kind"] == "slot":
		var sname: String = Game.SLOT_NAMES[c["slot"]]
		var g: String = Game.slots_of(fighters[who]).get(c["slot"], "")
		if g == "":
			return ["%s (empty)" % sname, "Nothing here yet. Pick something from the bag that fits this slot.", ""]
		var G: Dictionary = CombatD.GEAR[g]
		return [G["name"], "%s slot\n\n%s" % [sname, G["desc"]], "[E] Take off"]
	if c["i"] >= bag.size():
		return ["Empty", "An empty spot in the bag.", ""]
	var it: Dictionary = bag[c["i"]]
	match it["kind"]:
		"gear":
			var t := Game.gear_type(it["id"])
			return [it["name"], "%s\n\n%s" % [t.capitalize(), it["desc"]], "[E] Equip on %s" % fname]
		"use":
			var heal_n := int(CombatD.ITEMS.get(it["id"], {}).get("heal", 0))
			if heal_n > 0:
				var full := Game.hp(fighters[who]) >= Game.max_hp(fighters[who])
				return ["%s ×%d" % [it["name"], it["count"]], it["desc"] + "\n\nWorks here too: heals %d outside fights." % heal_n,
					("%s is at full HP" % fname) if full else "[E] %s (+%d HP to %s)" % [_heal_verb(it["id"]), heal_n, fname]]
			return ["%s ×%d" % [it["name"], it["count"]], it["desc"] + "\n\nUse it during fights (Items).", ""]
		"boost":
			return [it["name"] + ((" ×%d" % it["count"]) if it["count"] > 1 else ""), it["desc"], "[E] Use on %s (permanent)" % fname]
		_:
			return [it["name"] + ((" ×%d" % it["count"]) if it["count"] > 1 else ""), it["desc"], ""]

func _activate() -> void:
	if page != "gear" or sel >= cells.size():
		return
	var c: Dictionary = cells[sel]
	var fid: String = fighters[who]
	var fname: String = CombatD.PARTY[fid]["name"]
	note = ""
	if c["kind"] == "slot":
		var g: String = Game.slots_of(fid).get(c["slot"], "")
		if g != "":
			Game.unequip(fid, c["slot"])
			note = "Took off %s." % CombatD.GEAR[g]["name"]
			_click()
	elif c["i"] < bag.size():
		var it: Dictionary = bag[c["i"]]
		if it["kind"] == "gear":
			var s: String = Game.equip(fid, it["id"])
			if s != "":
				note = "%s equipped %s (%s)." % [fname, it["name"], Game.SLOT_NAMES[s]]
				_click()
		elif it["kind"] == "use" and int(CombatD.ITEMS.get(it["id"], {}).get("heal", 0)) > 0:
			_heal_with(fid, it)
		elif it["kind"] == "boost":
			if Game.use_boost(fid, it["id"]):
				note = "%s used %s. %s" % [fname, it["name"], ", ".join(gear_stat_lines(CombatD.BOOSTS[it["id"]]))]
				_click()
	_rebuild()
	note = ""

func _heal_verb(id: String) -> String:
	return "Drink" if id == "beer" else "Eat"

func _heal_with(fid: String, it: Dictionary) -> void:
	var fname: String = CombatD.PARTY[fid]["name"]
	var got := Game.use_heal_item(fid, it["id"])
	if got > 0:
		note = "%s %s %s. +%d HP (%d/%d)." % [fname, "drank a" if it["id"] == "beer" else "ate a", it["name"], got, Game.hp(fid), Game.max_hp(fid)]
		_click()
	else:
		note = "%s is already at full HP." % fname

func _switch(d: int) -> void:
	if fighters.size() < 2:
		return
	who = (who + d + fighters.size()) % fighters.size()
	_click()
	_rebuild()

func _set_page(p: String) -> void:
	page = p
	_click()
	_rebuild()

func _move(dir: Vector2) -> void:
	if cells.is_empty():
		return
	var from: Vector2 = cells[sel]["rect"].get_center()
	var best := -1
	var best_score := INF
	for i in cells.size():
		if i == sel:
			continue
		var d: Vector2 = cells[i]["rect"].get_center() - from
		var along := d.dot(dir)
		if along <= 4.0:
			continue
		var side := absf(d.dot(Vector2(dir.y, dir.x)))
		var score := along + side * 2.5
		if score < best_score:
			best_score = score
			best = i
	if best >= 0:
		sel = best
		_show_sel()

func _click() -> void:
	if lv and lv.get("ui_sfx"):
		lv.ui_sfx.play()

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self:
		return
	if Engine.get_process_frames() - _opened_at < 2:   # the key press that opened us
		return
	if popup_layer:   # right-click menu or the big picture is open: any back/confirm key closes it, nothing else gets through
		if ev.is_pressed() and not ev.is_echo() and not ev is InputEventMouse:
			if ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
				if popup_view_idx >= 0:
					var i := popup_view_idx
					_close_popup()
					_view_item(i)
				else:
					_close_popup()
			elif ev.is_action_pressed("party_menu") or ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel") or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B):
				_close_popup()
			get_viewport().set_input_as_handled()
		return
	var handled := true
	if ev is InputEventJoypadButton and ev.pressed and ev.button_index in [JOY_BUTTON_B]:
		close()
	elif ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_LEFT_SHOULDER:
		_switch(-1)
	elif ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		_switch(1)
	elif ev.is_action_pressed("party_menu") or ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel"):
		close()
	elif ev.is_action_pressed("switch"):
		_switch(1)
	elif ev is InputEventKey and ev.pressed and not ev.echo and ev.physical_keycode == KEY_J:
		_set_page("quests" if page == "gear" else "gear")
	elif ev.is_action_pressed("move_forward") or ev.is_action_pressed("ui_up"):
		_move(Vector2.UP)
	elif ev.is_action_pressed("move_back") or ev.is_action_pressed("ui_down"):
		_move(Vector2.DOWN)
	elif ev.is_action_pressed("move_left") or ev.is_action_pressed("ui_left"):
		_move(Vector2.LEFT)
	elif ev.is_action_pressed("move_right") or ev.is_action_pressed("ui_right"):
		_move(Vector2.RIGHT)
	elif ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
		_activate()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- right-click menu + big picture

var popup_layer: Control          # right-click menu or picture viewer (only one at a time)
var popup_view_idx := -1          # which cell the open right-click menu is for (-1 = viewer is open instead)

# What's in a cell: { id, name } or {} if it's empty
func _item_at(i: int) -> Dictionary:
	if i < 0 or i >= cells.size():
		return {}
	var c: Dictionary = cells[i]
	if c["kind"] == "slot":
		var g: String = Game.slots_of(fighters[who]).get(c["slot"], "")
		return { "id": g, "name": CombatD.GEAR[g]["name"], "count": 1, "kind": "gear" } if g != "" else {}
	if c["i"] < bag.size():
		return bag[c["i"]]
	return {}

# Fighters who are actually here to hand things to (Skorn isn't, while he's sitting on the goblin throne)
func _give_targets() -> Array:
	var out := []
	for f in fighters:
		if f == fighters[who]:
			continue
		if f == "chief":
			if Game.flag("goblinAllies"):
				out.append(f)
			continue
		for u in lv.party:
			if u.id == f:
				out.append(f)
	return out

func _give(i: int, to: String, n: int) -> void:
	var it := _item_at(i)
	if it.is_empty():
		return
	var from: String = fighters[who]
	if Game.give_item(from, to, it["id"], n):
		note = "Gave %s%s to %s." % [it["name"], (" ×%d" % n) if n > 1 else "", CombatD.PARTY[to]["name"]]
		_click()
	_rebuild()
	note = ""

func _popup_base(dim: float) -> Control:
	_close_popup()
	popup_layer = Control.new()
	popup_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup_layer.add_child(shade)
	popup_layer.gui_input.connect(func(ev):   # click outside = close
		if ev is InputEventMouseButton and ev.pressed:
			_close_popup())
	add_child(popup_layer)
	return popup_layer

func _close_popup() -> void:
	if popup_layer:
		popup_layer.queue_free()
		popup_layer = null
	popup_view_idx = -1

func _open_item_menu(i: int, at: Vector2) -> void:
	if page != "gear" or _item_at(i).is_empty():
		return
	var layer := _popup_base(0.0)
	popup_view_idx = i
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#1d1814"); sb.border_color = GOLD; sb.set_border_width_all(2); sb.set_corner_radius_all(5)
	sb.content_margin_left = 4; sb.content_margin_right = 4; sb.content_margin_top = 4; sb.content_margin_bottom = 4
	box.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	box.add_child(col)
	col.add_child(_menu_button("View", func():
		_close_popup()
		_view_item(i)))
	var it := _item_at(i)
	var heal_n := int(CombatD.ITEMS.get(it.get("id", ""), {}).get("heal", 0))
	if it.get("kind", "") == "use" and heal_n > 0:
		var fid: String = fighters[who]
		var hb := _menu_button("%s (+%d HP)" % [_heal_verb(it["id"]), heal_n], func():
			_close_popup()
			_heal_with(fid, _item_at(i))
			_rebuild()
			note = "")
		if Game.hp(fid) >= Game.max_hp(fid):
			hb.text = "%s (full HP)" % _heal_verb(it["id"]); hb.disabled = true
		col.add_child(hb)
	var n: int = int(it.get("count", 1))
	for to in _give_targets():
		var nm: String = CombatD.PARTY[to]["name"]
		var t: String = to
		if n > 1:
			col.add_child(_menu_button("Give 1 to %s" % nm, func():
				_close_popup()
				_give(i, t, 1)))
			col.add_child(_menu_button("Give all (%d) to %s" % [n, nm], func():
				_close_popup()
				_give(i, t, n)))
		else:
			col.add_child(_menu_button("Give to %s" % nm, func():
				_close_popup()
				_give(i, t, 1)))
	layer.add_child(box)
	box.reset_size()
	var vp := get_viewport_rect().size
	box.position = (at - global_position + Vector2(4, 4)).clamp(Vector2(8, 8), vp - box.size - Vector2(8, 8))   # stay on screen
	_click()

func _menu_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text; b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(190, 32)
	b.add_theme_font_override("font", serif_bold); b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color("#f3e3b0")); b.add_theme_color_override("font_hover_color", GOLD)
	var bs := StyleBoxFlat.new(); bs.bg_color = Color(0, 0, 0, 0); bs.content_margin_left = 8
	var bh := StyleBoxFlat.new(); bh.bg_color = Color(1, 1, 1, 0.08); bh.content_margin_left = 8
	b.add_theme_stylebox_override("normal", bs); b.add_theme_stylebox_override("hover", bh); b.add_theme_stylebox_override("pressed", bh)
	b.pressed.connect(cb)
	return b

# The item's picture, big, over everything. Click / Esc / E / Tab closes it.
func _view_item(i: int) -> void:
	var it := _item_at(i)
	if it.is_empty():
		return
	var layer := _popup_base(0.72)
	popup_view_idx = -1
	var vp := get_viewport_rect().size
	var frame := Panel.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color("#1d1814"); fs.border_color = GOLD; fs.set_border_width_all(3); fs.set_corner_radius_all(10)
	fs.shadow_color = Color(0, 0, 0, 0.6); fs.shadow_size = 20
	frame.add_theme_stylebox_override("panel", fs)
	frame.size = Vector2(560, 600)
	frame.position = (vp - frame.size) / 2.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(frame)
	var tex: Texture2D = lv.item_icon(it["id"])
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.position = Vector2(24, 24); t.size = Vector2(512, 480)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(t)
	else:
		var none := _txt("(no picture yet)", Vector2(0, 230), 22, Color(1, 1, 1, 0.5), serif, frame)
		none.size = Vector2(560, 30); none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nm := _txt(it["name"], Vector2(0, 514), 26, GOLD, serif_bold, frame)
	nm.size = Vector2(560, 34); nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint := _txt("Click anywhere or press Esc to close", Vector2(0, 554), 14, Color(1, 1, 1, 0.5), serif, frame)
	hint.size = Vector2(560, 20); hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_click()

func close() -> void:
	if not is_inside_tree():
		return
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)

# ---------------------------------------------------------------- little helpers

func _txt(t: String, pos: Vector2, size: int, color: Color, font: Font, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if parent == null and font != script_font and (color == INK or color == INK_SOFT):   # stay readable over the handwriting
		l.add_theme_color_override("font_outline_color", Color(0.88, 0.8, 0.63, 0.9))
		l.add_theme_constant_override("outline_size", 6)
	(parent if parent else pagebox).add_child(l)
	return l

func _line(pos: Vector2, w: float, color: Color) -> void:
	var r := ColorRect.new()
	r.color = color; r.position = pos; r.size = Vector2(w, 2)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pagebox.add_child(r)

func _framed(r: Rect2, bg: Color) -> Panel:
	var p := Panel.new()
	p.position = r.position; p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = Color("#b8913a"); sb.set_border_width_all(2); sb.set_corner_radius_all(5)
	p.add_theme_stylebox_override("panel", sb)
	pagebox.add_child(p)
	return p

func _tab(t: String, pos: Vector2, on: bool, cb: Callable) -> void:
	var b := Button.new()
	b.text = t; b.focus_mode = Control.FOCUS_NONE
	b.position = pos; b.add_theme_font_override("font", serif_bold); b.add_theme_font_size_override("font_size", 14)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2a2420") if on else Color(0, 0, 0, 0.08); sb.border_color = Color("#b8913a"); sb.set_border_width_all(1); sb.set_corner_radius_all(4)
	sb.content_margin_left = 8; sb.content_margin_right = 8; sb.content_margin_top = 2; sb.content_margin_bottom = 2
	for s in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(s, sb)
	b.add_theme_color_override("font_color", GOLD if on else INK)
	b.add_theme_color_override("font_hover_color", GOLD if on else INK_SOFT)
	b.pressed.connect(cb)
	pagebox.add_child(b)

func _arrow(t: String, pos: Vector2, cb: Callable) -> void:
	var b := Button.new()
	b.text = t; b.flat = true; b.focus_mode = Control.FOCUS_NONE
	b.position = pos; b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", INK); b.add_theme_color_override("font_hover_color", Color("#8a5a10"))
	b.pressed.connect(cb)
	pagebox.add_child(b)

# The gold coin icon (inventory, victory screen). Made once, shared.
static var _coin: Texture2D
static func coin_texture() -> Texture2D:
	if _coin == null:
		_coin = _make_coin()
	return _coin

# A gear piece's numbers as short lines ("+25 max HP", "+10% damage"...)
static func gear_stat_lines(G: Dictionary) -> Array:
	var out := []
	if G.get("armor", 0): out.append("+%d armor (each hit does %d less)" % [G["armor"], G["armor"]])
	if G.get("hp", 0): out.append("+%d max HP" % G["hp"])
	if G.get("power", 0.0): out.append("+%d%% damage" % int(round(G["power"] * 100)))
	if G.get("spd", 0): out.append("+%d speed" % G["spd"])
	if G.get("meter", 1.0) != 1.0: out.append("+%d%% meter gain" % int(round((G["meter"] - 1.0) * 100)))
	if G.get("start", 0): out.append("Start fights with %d meter" % G["start"])
	if G.get("no_ones", false): out.append("Crash Out dice never roll a 1")
	if G.get("gouge_proof", false): out.append("Immune to Price Gouged")
	return out

static func _make_coin() -> Texture2D:
	var n := 40
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0 - 0.5, n / 2.0 - 0.5)
	for y in n:
		for x in n:
			var d := Vector2(x, y).distance_to(c) / (n / 2.0)
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var shade := 1.0 - 0.35 * clampf((x + y) / float(n * 2), 0.0, 1.0)
				var col := Color("#f5c842") * shade if d < 0.78 else Color("#a87a12")
				if d > 0.62 and d < 0.7:
					col = Color("#c99a1e")
				col.a = clampf((1.0 - d) * n / 2.0, 0.0, 1.0)
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)

# DRAFT: filler "lore" in cursive behind the page. Mostly unreadable on purpose (Deloye Lore has little to no lore).
const HANDWRITING := "In the year of the Third Spoon the Mogging Elf did walk upon the Pass, and the giant did sleep, for it was a Tuesday. Chapter eight thousand seven hundred eighty four, Section B twelve, sayeth that the metocy groweth only where no one is looking, and that the dragon who readeth this shall be called a nerd by the orc. Here endeth nothing, for nothing was ever begun. And lo, the goblins were between jobs, and the demon did sell capsules with no refunds, and the elf did condition his hair most thoroughly. Of the lore there is little, and of the little there is less. Volume nine is signed by nobody. In the year of the Fourth Spoon the orc did burn the map, and the map was the lore, and the lore was gone, and the dragon wept upon his book. Chapter eight thousand seven hundred eighty five is blank. It is the best chapter. Here endeth the chapter, and here beginneth the same chapter again, for the scribe had forgotten he had written it. In the year of the Third Spoon the Mogging Elf did walk upon the Pass, and the giant did sleep, for it was a Tuesday, and verily it was still a Tuesday."

const BLUR_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * 2.5;
	vec3 c = vec3(0.0);
	float w = 0.0;
	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			float k = exp(-float(x * x + y * y) / 10.0);
			c += texture(screen_tex, SCREEN_UV + vec2(float(x), float(y)) * px).rgb * k;
			w += k;
		}
	}
	COLOR = vec4(c / w * 0.72, 1.0);
}
"""

const PARCHMENT_SHADER := """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; } return v; }
void fragment() {
	vec2 uv = UV;
	vec3 base = vec3(0.87, 0.79, 0.62);
	float n = fbm(uv * vec2(9.0, 6.0));
	float stains = smoothstep(0.55, 0.85, fbm(uv * 3.0 + 7.3));
	vec3 col = base * (0.86 + 0.22 * n) - vec3(0.10, 0.10, 0.08) * stains;
	vec2 e = min(uv, 1.0 - uv);
	float edge = smoothstep(0.0, 0.10, min(e.x * 0.62, e.y));
	col = mix(vec3(0.42, 0.29, 0.15), col, 0.45 + 0.55 * edge);
	COLOR = vec4(col, 1.0);
}
"""
