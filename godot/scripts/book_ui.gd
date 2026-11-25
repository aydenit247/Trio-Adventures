# BookUI: read one of the Deloye library's books (Ebain 11/25: a book screen, not read out loud). Two parchment pages
# side by side with a spine; A/D or ←/→ (or the buttons) turn a spread, Esc / E / B closes. Text: LibraryBooks.
#   await BookUI.read(level, "on_metocy")
class_name BookUI
extends Control

signal closed

const LB = preload("res://scripts/library_books.gd")
const P := UITheme.PARCHMENT
const W := 1040.0
const H := 640.0

var book_id := ""
var spread := 0          # left page index = spread * 2
var pages: Array = []
var title_lbl: Label
var left: RichTextLabel
var right: RichTextLabel
var left_no: Label
var right_no: Label
var prev_b: Button
var next_b: Button
var _at := 0

static func read(level: Node, id: String) -> void:
	if not LB.BOOKS.has(id):
		return
	level.busy = true
	level.freeze_all(true)
	level.dialogue.hide_box()
	var ui := BookUI.new()
	ui.book_id = id
	level.hud.add_child(ui)
	ui._build()
	if level.shots_mode:   # automated tour: show the first spread and the last, then close
		await level.wait(0.8)
		await level.shot("book_%s_1" % id)
		ui.spread = ui._last_spread()
		ui._render()
		await level.wait(0.4)
		await level.shot("book_%s_end" % id)
		ui.close()
	else:
		await ui.closed
	level.freeze_all(false)
	level.busy = false

func _last_spread() -> int:
	return int((pages.size() - 1) / 2)

func _build() -> void:
	var B: Dictionary = LB.BOOKS[book_id]
	pages = B["pages"]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var book := PanelContainer.new()
	book.add_theme_stylebox_override("panel", UITheme.panel(0.99, P))
	book.anchor_left = 0.5; book.anchor_right = 0.5; book.anchor_top = 0.5; book.anchor_bottom = 0.5
	book.offset_left = -W / 2; book.offset_right = W / 2; book.offset_top = -H / 2; book.offset_bottom = H / 2
	add_child(book)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	book.add_child(v)
	title_lbl = UITheme.lbl(B["title"], 26, "accent", UITheme.head_font(), P)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_lbl)
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 26)
	v.add_child(h)
	var lcol := _page_col()
	h.add_child(lcol[0])
	left = lcol[1]; left_no = lcol[2]
	var spine := ColorRect.new()
	spine.color = Color(UITheme.c("edge2", P), 0.6)
	spine.custom_minimum_size.x = 2
	h.add_child(spine)
	var rcol := _page_col()
	h.add_child(rcol[0])
	right = rcol[1]; right_no = rcol[2]
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 24)
	v.add_child(foot)
	prev_b = UITheme.button("◀  Back", 15)
	prev_b.pressed.connect(func(): _turn(-1))
	foot.add_child(prev_b)
	var hint := UITheme.lbl("A/D or ←/→ turn the page · Esc close", 13, "faint", null, P)
	foot.add_child(hint)
	next_b = UITheme.button("Next  ▶", 15)
	next_b.pressed.connect(func(): _turn(1))
	foot.add_child(next_b)
	var close_b := UITheme.button("Close", 15)
	close_b.pressed.connect(close)
	foot.add_child(close_b)
	MenuUI.stack.append(self)
	_at = Engine.get_process_frames()
	UITheme.play("page")
	_render()
	book.size = Vector2(W, H)
	UITheme.pop_in(book)

# one page: the text (BBCode) + its page number at the bottom
func _page_col() -> Array:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size.x = (W - 90.0) / 2.0   # a width up front, or the wrapped text measures one letter per line
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = false
	t.scroll_active = true   # (a page that runs long scrolls instead of growing the book)
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_color_override("default_color", UITheme.c("text", P))
	t.add_theme_font_size_override("normal_font_size", UITheme.fs(19))
	t.add_theme_font_size_override("bold_font_size", UITheme.fs(19))
	t.add_theme_font_size_override("italics_font_size", UITheme.fs(19))
	t.add_theme_font_override("bold_font", UITheme.row_font())
	t.add_theme_constant_override("line_separation", 4)
	col.add_child(t)
	var no := UITheme.lbl("", 13, "dim", null, P)
	no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(no)
	return [col, t, no]

func _render() -> void:
	var i := spread * 2
	left.text = pages[i] if i < pages.size() else ""
	right.text = pages[i + 1] if i + 1 < pages.size() else ""
	left.scroll_to_line(0)
	right.scroll_to_line(0)
	left_no.text = str(i + 1) if i < pages.size() else ""
	right_no.text = str(i + 2) if i + 1 < pages.size() else ""
	prev_b.disabled = spread == 0
	next_b.disabled = spread >= _last_spread()

func _turn(d: int) -> void:
	var s := clampi(spread + d, 0, _last_spread())
	if s == spread:
		UITheme.play("back")
		return
	spread = s
	UITheme.play("page")
	_render()

func close() -> void:
	UITheme.play("back")
	MenuUI.stack.erase(self)
	closed.emit()
	queue_free()

func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self or Engine.get_process_frames() - _at < 2:
		return
	if not (ev is InputEventKey or ev is InputEventJoypadButton or ev is InputEventJoypadMotion):
		return
	var handled := true
	if ev.is_action_pressed("ui_left") or ev.is_action_pressed("move_left"):
		UITheme.key_nav(); _turn(-1)
	elif ev.is_action_pressed("ui_right") or ev.is_action_pressed("move_right"):
		UITheme.key_nav(); _turn(1)
	elif ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("pause") or ev.is_action_pressed("interact") or (ev is InputEventJoypadButton and ev.pressed and ev.button_index == JOY_BUTTON_B):
		close()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
