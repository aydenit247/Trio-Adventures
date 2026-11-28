# BestiaryUI: Library → Bestiary (Ebain 11/27). Same parchment book as the Scrapbook: the list on the left (grouped by
# where you meet them), the entry on the right with the enemy's picture, weak/resist, how many you've beaten and
# Xylo's notes. Unseen enemies are "? ? ?" with a silhouette. Data + saving: bestiary.gd.
#   BestiaryUI.open(ui_canvas_layer)  →  await page.closed
class_name BestiaryUI
extends Control

signal closed

const P := UITheme.PARCHMENT
var sel := 0
var _rows: Array = []
var list: VBoxContainer
var scroll: ScrollContainer
var page: VBoxContainer
var _at := 0

static func open(parent: Node) -> BestiaryUI:
	var s := BestiaryUI.new()
	parent.add_child(s)
	s._build()
	return s

func _build() -> void:
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
	book.offset_left = -520; book.offset_right = 520; book.offset_top = -320; book.offset_bottom = 320
	add_child(book)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	book.add_child(v)
	var t := UITheme.lbl("DELOYE LORE BESTIARY", 30, "accent", UITheme.head_font(), P)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var sub := UITheme.lbl("%d / %d creatures recorded  ·  notes by Xylo" % [Bestiary.seen_count(), Bestiary.ENTRIES.size()], 16, "dim", null, P)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 18)
	v.add_child(h)
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 330
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	h.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	var spine := ColorRect.new()
	spine.color = Color(UITheme.c("edge2", P), 0.6)
	spine.custom_minimum_size.x = 2
	h.add_child(spine)
	page = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.custom_minimum_size.x = 610   # give autowrap labels a width up front (TIPS: scrapbook)
	page.add_theme_constant_override("separation", 8)
	h.add_child(page)
	var hint := UITheme.lbl("W/S or ↑/↓ choose · Esc back", 13, "faint", null, P)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var last := ""
	for i in Bestiary.ENTRIES.size():
		var e: Dictionary = Bestiary.ENTRIES[i]
		if e["group"] != last:
			last = e["group"]
			var hd := UITheme.lbl(last.to_upper(), 15, "accent", UITheme.head_font(), P)
			hd.custom_minimum_size.y = 30
			hd.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			list.add_child(hd)
		var got := Bestiary.is_seen(e["id"])
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		var l := UITheme.lbl(e["name"] if got else "? ? ?", 17, "text" if got else "faint", UITheme.row_font(), P)
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
	MenuUI.stack.append(self)
	_at = Engine.get_process_frames()
	UITheme.play("page")
	_render()
	book.size = Vector2(1040, 640)
	UITheme.pop_in(book)
	_resettle(book)

func _resettle(book: Control) -> void:
	for i in 2:
		await get_tree().process_frame
	if not is_instance_valid(book):
		return
	book.offset_left = -520; book.offset_right = 520; book.offset_top = -320; book.offset_bottom = 320
	book.size = Vector2(1040, 640)

func _render() -> void:
	for i in _rows.size():
		_rows[i].add_theme_stylebox_override("panel", UITheme.row(i == sel, P))
	if sel < _rows.size():
		scroll.ensure_control_visible.call_deferred(_rows[sel])
	for c in page.get_children():
		c.queue_free()
	var e: Dictionary = Bestiary.ENTRIES[sel]
	var got := Bestiary.is_seen(e["id"])
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	page.add_child(top)
	var pic := TextureRect.new()   # the enemy's art (black silhouette until you've met it)
	pic.custom_minimum_size = Vector2(170, 190)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var p := "res://assets/characters/%s.png" % e["tex"]
	if ResourceLoader.exists(p):
		pic.texture = load(p)
	pic.modulate = Color(e.get("tint", "#ffffff")) if got else Color(0.12, 0.09, 0.07, 0.85)
	top.add_child(pic)
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 6)
	head.custom_minimum_size.x = 420
	top.add_child(head)
	head.add_child(UITheme.lbl(e["group"].to_upper(), 14, "dim", UITheme.head_font(), P))
	var nm := UITheme.lbl(e["name"] if got else "? ? ?", 26, "text", UITheme.row_font(), P)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.custom_minimum_size.x = 420
	head.add_child(nm)
	if not got:
		var hl := UITheme.lbl("Not recorded yet. Fight one and Xylo will write it up.", 17, "dim", null, P)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size.x = 420
		head.add_child(hl)
		return
	head.add_child(UITheme.lbl(e["tag"], 16, "accent", null, P))
	var w: Dictionary = CombatData.WEAKNESS.get(_ai_of(e), {})
	var bits := []
	if w.has("weak"): bits.append("Weak to %s" % CombatData.DTYPE_NAME.get(w["weak"], w["weak"]))
	if w.has("resist"): bits.append("Resists %s" % CombatData.DTYPE_NAME.get(w["resist"], w["resist"]))
	if bits.is_empty(): bits.append("No weak spot")
	head.add_child(UITheme.lbl("  ·  ".join(bits), 16, "text", UITheme.row_font(), P))
	head.add_child(UITheme.lbl("Beaten: %d" % Bestiary.beaten(e["id"]), 15, "dim", null, P))
	var dv := ColorRect.new()
	dv.color = Color(UITheme.c("edge2", P), 0.7)
	dv.custom_minimum_size = Vector2(0, 1)
	page.add_child(dv)
	var tx := UITheme.lbl(e["text"], 18, "text", null, P)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tx.custom_minimum_size.x = 600
	page.add_child(tx)
	var ct := UITheme.lbl(e["cite"], 14, "faint", null, P)
	ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ct.custom_minimum_size.x = 600
	page.add_child(ct)
	page.add_child(UITheme.lbl("— Xylo", 15, "accent", UITheme.row_font(), P))

# The fight ai for an entry (to read its weakness): the first fight enemy that maps to this entry.
func _ai_of(e: Dictionary) -> String:
	for fk in CombatData.FIGHTS:
		var f: Dictionary = CombatData.FIGHTS[fk]
		for en in f.get("enemies", []) + f.get("adds", []):
			if Bestiary.id_for(en) == e["id"]:
				return str(en.get("ai", ""))
	return ""

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
		return
	if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
		return
	var handled := true
	if ev.is_action_pressed("ui_up") or ev.is_action_pressed("move_forward"):
		sel = maxi(sel - 1, 0); UITheme.key_nav(); UITheme.play("move"); _render()
	elif ev.is_action_pressed("ui_down") or ev.is_action_pressed("move_back"):
		sel = mini(sel + 1, Bestiary.ENTRIES.size() - 1); UITheme.key_nav(); UITheme.play("move"); _render()
	elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause") or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
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
