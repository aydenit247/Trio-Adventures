# VoiceLinesUI: Library → Voice Lines (Ebain 11/24). Every recorded line in the game, a tab per character and a
# search box. Lines come from ScriptScan.voice_lines() (the dialogue scripts + the voices folders).
#   Type to search · ↑/↓ choose · Enter or click play/stop · Tab / Shift+Tab (or LB/RB) switch character · Esc back
#   VoiceLinesUI.open(ui_canvas_layer)  →  await page.closed
class_name VoiceLinesUI
extends Control

signal closed

var lines: Array = []        # all
var shown: Array = []        # after tab + search
var tab := 0                 # 0 = All, then ScriptScan.CATS
var sel := 0
var playing := -1            # index into shown
var tabs: Array = []         # [label, count]
var tab_btns: Array = []
var search: LineEdit
var list: VBoxContainer
var scroll: ScrollContainer
var count_lbl: Label
var player: AudioStreamPlayer
var _rows: Array = []
var _at := 0

static func open(parent: Node) -> VoiceLinesUI:
	var v := VoiceLinesUI.new()
	parent.add_child(v)
	v._build()
	return v

func _build() -> void:
	lines = ScriptScan.voice_lines()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel(0.97))
	p.anchor_left = 0.5; p.anchor_right = 0.5; p.anchor_top = 0.5; p.anchor_bottom = 0.5
	p.offset_left = -500; p.offset_right = 500; p.offset_top = -320; p.offset_bottom = 320
	add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var t := UITheme.lbl("LIBRARY  ·  VOICE LINES", 28, "accent", UITheme.head_font())
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(UITheme.Divider.new())
	# character tabs
	tabs = [["All", lines.size()]]
	for c in ScriptScan.CATS + [["Others", []]]:
		var n := lines.filter(func(l): return l["cat"] == c[0]).size()
		if n > 0:
			tabs.append([c[0], n])
	var tb := HFlowContainer.new()
	tb.add_theme_constant_override("h_separation", 6)
	tb.alignment = FlowContainer.ALIGNMENT_CENTER
	v.add_child(tb)
	for i in tabs.size():
		var b := UITheme.button("%s  %d" % tabs[i], 15)
		var idx := i
		b.pressed.connect(func(): _set_tab(idx))
		tb.add_child(b)
		tab_btns.append(b)
	# search
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 10)
	v.add_child(sh)
	sh.add_child(UITheme.lbl("Search", 17, "dim", UITheme.row_font()))
	search = LineEdit.new()
	search.placeholder_text = "type any words from a line…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", UITheme.fs(17))
	var se := StyleBoxFlat.new()
	se.bg_color = Color(UITheme.c("bg2"), 0.9)
	se.border_color = UITheme.c("edge2")
	se.set_border_width_all(1)
	se.set_corner_radius_all(4)
	se.content_margin_left = 10; se.content_margin_right = 10; se.content_margin_top = 4; se.content_margin_bottom = 4
	search.add_theme_stylebox_override("normal", se)
	var sf: StyleBoxFlat = se.duplicate()
	sf.border_color = UITheme.c("accent")
	search.add_theme_stylebox_override("focus", sf)
	search.add_theme_color_override("font_color", UITheme.c("text"))
	search.add_theme_color_override("font_placeholder_color", UITheme.c("faint"))
	search.add_theme_color_override("caret_color", UITheme.c("accent"))
	search.text_changed.connect(func(_t): _filter())
	sh.add_child(search)
	count_lbl = UITheme.lbl("", 15, "dim")
	sh.add_child(count_lbl)
	# the list
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 1)
	scroll.add_child(list)
	var hint := UITheme.lbl("Type to search · ↑/↓ choose · Enter or click to play / stop · Tab or LB/RB: next character · Esc back", 13, "faint")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	player = AudioStreamPlayer.new()   # Master bus, like dialogue voice lines: Voice volume applies
	player.volume_db = linear_to_db(maxf(Game.voice_vol, 0.01))
	player.finished.connect(func(): playing = -1; _render())
	add_child(player)
	MenuUI.stack.append(self)
	_at = Engine.get_process_frames()
	UITheme.play("page")
	_filter()
	search.grab_focus.call_deferred()
	p.size = Vector2(1000, 640)
	UITheme.pop_in(p)

func _set_tab(i: int) -> void:
	tab = (i + tabs.size()) % tabs.size()
	UITheme.play("page")
	_filter()

func _filter() -> void:
	var q := search.text.strip_edges().to_lower()
	var words := q.split(" ", false)
	shown = lines.filter(func(l):
		if tab > 0 and l["cat"] != tabs[tab][0]:
			return false
		var hay: String = (l["text"] + " " + l["name"]).to_lower()
		for w in words:
			if not w in hay:
				return false
		return true)
	_stop()
	for c in list.get_children():
		c.queue_free()
	_rows = []
	for i in shown.size():
		var l: Dictionary = shown[i]
		var row := PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var ic := UITheme.Icon.new("play", 16)
		h.add_child(ic)
		var nm := UITheme.lbl(l["name"], 16, "accent", UITheme.row_font())
		nm.custom_minimum_size.x = 190
		nm.clip_text = true
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(nm)
		var tx := UITheme.lbl(l["text"], 16, "text")
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(tx)
		var idx := i
		row.gui_input.connect(func(ev):
			if UITheme.hover_moved(ev) and sel != idx:
				sel = idx
				_render()
			elif ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				sel = idx
				_toggle())
		list.add_child(row)
		_rows.append({ "row": row, "icon": ic })
	sel = clampi(sel, 0, maxi(shown.size() - 1, 0))
	count_lbl.text = "%d line%s" % [shown.size(), "" if shown.size() == 1 else "s"]
	if shown.is_empty():
		var none := UITheme.lbl("No lines match. Try fewer words.", 17, "dim")
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(none)
	_render()

func _render() -> void:
	for i in tab_btns.size():
		tab_btns[i].add_theme_color_override("font_color", UITheme.c("accent") if i == tab else UITheme.c("text"))
		var sb: StyleBoxFlat = tab_btns[i].get_theme_stylebox("normal").duplicate()
		sb.bg_color = Color(UITheme.c("hi"), 0.45 if i == tab else 0.14)
		sb.border_color = UITheme.c("accent") if i == tab else UITheme.c("edge2")
		tab_btns[i].add_theme_stylebox_override("normal", sb)
	for i in _rows.size():
		_rows[i]["row"].add_theme_stylebox_override("panel", UITheme.row(i == sel))
		_rows[i]["icon"].set_kind("pause" if i == playing else "play", UITheme.c("accent") if i == sel or i == playing else UITheme.c("dim"))
	if sel < _rows.size():
		scroll.ensure_control_visible.call_deferred(_rows[sel]["row"])

func _toggle() -> void:
	if sel >= shown.size():
		return
	if playing == sel:
		_stop()
	else:
		player.stream = load(shown[sel]["path"])
		player.play()
		playing = sel
		UITheme.play("pick")
	_render()

func _stop() -> void:
	if player:
		player.stop()
	playing = -1

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
		return
	var key := ev as InputEventKey
	var handled := true
	if key and key.pressed and key.keycode in [KEY_UP, KEY_DOWN]:
		sel = clampi(sel + (1 if key.keycode == KEY_DOWN else -1), 0, maxi(shown.size() - 1, 0))
		UITheme.key_nav(); UITheme.play("move"); _render()
	elif key and key.pressed and not key.echo and key.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		_toggle()
	elif key and key.pressed and not key.echo and key.keycode == KEY_TAB:
		_set_tab(tab + (-1 if key.shift_pressed else 1))
	elif key and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		_close()
	elif ev is InputEventJoypadButton and ev.pressed:
		match ev.button_index:
			JOY_BUTTON_DPAD_UP: sel = maxi(sel - 1, 0); UITheme.key_nav(); _render()
			JOY_BUTTON_DPAD_DOWN: sel = mini(sel + 1, maxi(shown.size() - 1, 0)); UITheme.key_nav(); _render()
			JOY_BUTTON_A: _toggle()
			JOY_BUTTON_B: _close()
			JOY_BUTTON_LEFT_SHOULDER: _set_tab(tab - 1)
			JOY_BUTTON_RIGHT_SHOULDER: _set_tab(tab + 1)
			_: handled = false
	else:
		handled = false   # everything else (letters) goes to the search box
	if handled:
		get_viewport().set_input_as_handled()

func _close() -> void:
	_stop()
	UITheme.play("back")
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)
