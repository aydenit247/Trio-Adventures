extends Control
class_name ShopUI

# Haggle's market stall in the village square (Asar's stock list). Click an item (or W/S) and Buy (E).
# Food goes into the bag of whoever you're controlling; gear goes to them too (equip it from Tab).
# Opened from village_buildings.gd ("open_shop" action):  await ShopUI.open_shop(lv)

signal closed

const CombatD = preload("res://scripts/combat/combat_data.gd")

const W := 900.0
const H := 560.0
const GOLD := Color("#e8b923")
const INK := Color("#f3e3b0")
# id, kind (item = goes in a bag, gear = one of a kind), price in gold
const STOCK := [
	["beer", "item", 8], ["bowl", "item", 15],
	["mouthwash", "item", 12], ["bubble", "item", 18], ["energy", "item", 22],   # 11/26 fight items (prices DRAFT)
	["pot_lid", "gear", 25], ["jordan9s", "gear", 30], ["goblin_tooth", "gear", 45], ["rock", "gear", 3],
	# the top shelf (Ebain 11/24: really expensive, worth coming back for)
	["air_forces", "gear", 220], ["gold_chain", "gear", 280], ["king_helm", "gear", 320], ["designer_mail", "gear", 400], ["golden_ladle", "gear", 650],
]

var lv: Node
var stock: Array = STOCK
var shop_title := "HAGGLE'S STALL"
var broke_line := "Haggle: \"No gold, no goods. No haggling.\""
var discount := 1.0
var root: Control
var rows: Array = []
var scroll: ScrollContainer
var sel := 0
var gold_lbl: Label
var who_lbl: Label
var big_icon: TextureRect
var name_lbl: Label
var desc_lbl: Label
var price_lbl: Label
var buy_btn: Button
var note_lbl: Label
var _opened_at := 0
var _font: Font

# opts (all optional): stock (same shape as STOCK), title, broke (line when you can't pay), discount (0.5 = half price)
static func open_shop(level: Node, opts := {}) -> void:
	level.busy = true
	level.freeze_all(true)
	level.dialogue.hide_box()
	var ui := ShopUI.new()
	ui.lv = level
	ui.stock = opts.get("stock", STOCK)
	ui.shop_title = opts.get("title", ui.shop_title)
	ui.broke_line = opts.get("broke", ui.broke_line)
	ui.discount = opts.get("discount", 1.0)
	level.hud.add_child(ui)
	ui._build()
	if level.shots_mode:   # automated tour: show it, buy a Beezy, close
		await level.wait(0.8)
		ui._buy()
		await level.wait(0.4)
		await level.shot("b_shop")
		ui.close()
	else:
		await ui.closed
	level.freeze_all(false)
	level.busy = false

func _build() -> void:
	_opened_at = Engine.get_process_frames()
	MenuUI.stack.append(self)
	UITheme.play("page")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var cz := FontVariation.new()
	cz.base_font = load("res://assets/fonts/Cinzel.ttf")
	cz.variation_embolden = 0.6
	_font = cz
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
	frame.add_theme_stylebox_override("panel", _box(Color("#3b2614"), Color("#24170b"), 6, 8, true))
	root.add_child(frame)
	# striped awning across the top, like the stall
	var awn := Control.new()
	awn.position = Vector2(0, 0); awn.size = Vector2(W, 64)
	awn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	awn.draw.connect(func():
		var n := 12
		for i in n:
			awn.draw_rect(Rect2(i * W / n, 0, W / n, 52), Color("#b8322a") if i % 2 == 0 else Color("#efe3c2"))
		for i in n:   # scalloped edge
			awn.draw_circle(Vector2((i + 0.5) * W / n, 52), W / n * 0.5, Color("#b8322a") if i % 2 == 0 else Color("#efe3c2")))
	root.add_child(awn)
	var title := _lbl(shop_title, 30, Color("#2b1d10"), _font, 0)
	title.position = Vector2(0, 8); title.size = Vector2(W, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	var sub := _lbl("(no haggling)", 15, Color(1, 1, 1, 0.7), null, 4)
	sub.position = Vector2(0, 92); sub.size = Vector2(W, 20)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(sub)
	# gold
	var coin := TextureRect.new()
	coin.texture = InventoryUI.coin_texture()
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.position = Vector2(W - 170, 88); coin.size = Vector2(26, 26)
	root.add_child(coin)
	gold_lbl = _lbl("", 22, GOLD, _font, 5)
	gold_lbl.position = Vector2(W - 138, 86)
	root.add_child(gold_lbl)
	who_lbl = _lbl("", 15, Color(1, 1, 1, 0.75), null, 4)
	who_lbl.position = Vector2(34, 92)
	root.add_child(who_lbl)
	# item list (left)
	scroll = ScrollContainer.new()   # scrolls: the top shelf made the list longer than the box (11 items)
	scroll.position = Vector2(30, 128); scroll.size = Vector2(446, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for i in stock.size():
		var r := Panel.new()
		r.custom_minimum_size = Vector2(430, 56)
		r.mouse_filter = Control.MOUSE_FILTER_STOP
		r.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx := i
		r.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				sel = idx; _refresh()
				if ev.double_click: _buy())
		list.add_child(r)
		var ic := TextureRect.new()
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.position = Vector2(8, 4); ic.size = Vector2(48, 48)
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(ic)
		var nm := _lbl("", 19, INK, _font, 0)
		nm.position = Vector2(66, 15)
		r.add_child(nm)
		var pr := _lbl("", 19, GOLD, _font, 0)
		pr.position = Vector2(330, 15); pr.size = Vector2(88, 24)
		pr.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		r.add_child(pr)
		rows.append({ "panel": r, "icon": ic, "name": nm, "price": pr })
	# details (right)
	var det := Panel.new()
	det.position = Vector2(480, 128); det.size = Vector2(390, 380)
	det.add_theme_stylebox_override("panel", _box(Color("#efe3c2"), Color("#8a6a3a"), 2, 4))
	det.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(det)
	big_icon = TextureRect.new()
	big_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	big_icon.position = Vector2(135, 16); big_icon.size = Vector2(120, 120)
	det.add_child(big_icon)
	name_lbl = _lbl("", 24, Color("#2b1d10"), _font, 0)
	name_lbl.position = Vector2(16, 142); name_lbl.size = Vector2(358, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.add_child(name_lbl)
	desc_lbl = _lbl("", 17, Color("#3b2a18"), null, 0)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(358, 0)
	desc_lbl.position = Vector2(16, 180)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.add_child(desc_lbl)
	price_lbl = _lbl("", 22, Color("#7a5a10"), _font, 0)
	price_lbl.position = Vector2(16, 268); price_lbl.size = Vector2(358, 30)
	price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.add_child(price_lbl)
	buy_btn = Button.new()
	buy_btn.text = "Buy"
	buy_btn.position = Vector2(120, 308); buy_btn.size = Vector2(150, 50)
	buy_btn.focus_mode = Control.FOCUS_NONE
	buy_btn.add_theme_font_override("font", _font)
	buy_btn.add_theme_font_size_override("font_size", 22)
	for st in ["normal", "hover", "pressed", "disabled"]:
		buy_btn.add_theme_stylebox_override(st, _box(Color("#3b2614") if st != "hover" else Color("#5a3a1f"), GOLD if st == "hover" else Color("#8a6a3a"), 2, 6))
	buy_btn.add_theme_color_override("font_color", Color("#ffdf8a"))
	buy_btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	buy_btn.pressed.connect(_buy)
	det.add_child(buy_btn)
	note_lbl = _lbl("", 16, Color(1, 1, 1, 0.85), null, 4)
	note_lbl.position = Vector2(0, H - 42); note_lbl.size = Vector2(W, 22)
	note_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(note_lbl)
	var keys := _lbl("W/S choose  ·  E buy  ·  Esc close", 14, Color(1, 1, 1, 0.55), null, 4)
	keys.position = Vector2(0, H - 22); keys.size = Vector2(W, 18)
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(keys)
	_refresh()

# ---- data
func _price(i: int) -> int:
	return maxi(1, int(round(stock[i][2] * discount)))

# "item" ids are bag items: heal items (CombatD.ITEMS) or permanent boosts (CombatD.BOOSTS)
func _item_def(id: String) -> Dictionary:
	return CombatD.ITEMS[id] if CombatD.ITEMS.has(id) else CombatD.BOOSTS[id]

func _name(i: int) -> String:
	var id: String = stock[i][0]
	return _item_def(id)["name"] if stock[i][1] == "item" else CombatD.GEAR[id]["name"]

func _desc(i: int) -> String:
	var id: String = stock[i][0]
	if stock[i][1] == "item":
		return _item_def(id)["desc"]
	var G: Dictionary = CombatD.GEAR[id]
	return G["desc"] + "\n(" + Game.SLOT_NAMES.get(G["slot"], G["slot"].capitalize()) + ")" if G["slot"] != "trinket" else G["desc"] + "\n(Trinket)"

func _owned(i: int) -> bool:
	return stock[i][1] == "gear" and Game.gear_owned.has(stock[i][0])

func _icon(id: String) -> Texture2D:
	var t: Texture2D = lv.item_icon(id)
	return t if t else _placeholder()

static var _ph: Texture2D
static func _placeholder() -> Texture2D:   # until the item picture exists: a little crate with a "?"
	if _ph == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(10, 56):
			for x in range(8, 56):
				var edge := x < 11 or x > 52 or y < 13 or y > 52
				img.set_pixel(x, y, Color("#5a3a1f") if edge else Color("#8a6a3a"))
		for y in range(20, 46):   # "?"
			for x in range(28, 36):
				if (y < 24) or (y > 28 and y < 36 and x > 30) or y > 40:
					img.set_pixel(x, y, Color("#efe3c2"))
		_ph = ImageTexture.create_from_image(img)
	return _ph

func _refresh() -> void:
	if scroll and sel < rows.size():
		scroll.ensure_control_visible.call_deferred(rows[sel]["panel"])
	gold_lbl.text = str(Game.gold)
	who_lbl.text = "Buying for: %s" % CombatD.PARTY[Game.active_fighter]["name"]
	for i in rows.size():
		var r: Dictionary = rows[i]
		r["icon"].texture = _icon(stock[i][0])
		r["name"].text = _name(i)
		var owned := _owned(i)
		r["price"].text = "OWNED" if owned else "%d g" % _price(i)
		r["price"].add_theme_color_override("font_color", Color(1, 1, 1, 0.45) if owned else (GOLD if Game.gold >= _price(i) else Color("#ff6a5a")))
		r["panel"].add_theme_stylebox_override("panel", _box(Color("#5a3a1f") if i == sel else Color("#2a1b0e"), GOLD if i == sel else Color("#4a3320"), 2, 6))
	big_icon.texture = _icon(stock[sel][0])
	name_lbl.text = _name(sel)
	desc_lbl.text = _desc(sel)
	var have := ""
	if stock[sel][1] == "item":
		have = "   (you have %d)" % Game.count(stock[sel][0])
	price_lbl.text = ("Already yours" if _owned(sel) else "%d gold" % _price(sel)) + have
	buy_btn.disabled = _owned(sel) or Game.gold < _price(sel)

func _buy() -> void:
	if _owned(sel) or Game.gold < _price(sel):
		note_lbl.text = broke_line if not _owned(sel) else "You already have that."
		return
	var id: String = stock[sel][0]
	Game.add_gold(-_price(sel))
	Game.set_flag("bought_" + id)   # achievements: flag:bought_golden_ladle, flag:bought_jordan9s
	var who: String = Game.active_fighter
	var nm: String = CombatD.PARTY[who]["name"]
	if stock[sel][1] == "item":
		Game.add_item(id, 1, who)
		note_lbl.text = "%s got: %s" % [nm, _name(sel)]
	else:
		Game.give_gear(id, who)
		note_lbl.text = "%s got: %s (equip it from Tab)" % [nm, _name(sel)]
	if lv.play_sound("ui_chaching", -5.0) == null:   # 11/27 sound batch 4: cha-ching (old click if the file's missing)
		lv.ui_sfx.play()
	_refresh()

# ---- input
func _input(ev: InputEvent) -> void:
	if MenuUI.stack.is_empty() or MenuUI.stack.back() != self:
		return
	if Engine.get_process_frames() - _opened_at < 2:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		# the wheel scrolls the shop list (Asar 11/25: it used to zoom the camera behind the shop)
		sel = (sel + (1 if ev.button_index == MOUSE_BUTTON_WHEEL_DOWN else -1) + stock.size()) % stock.size()
		_refresh(); UITheme.play("move")
		get_viewport().set_input_as_handled()
		return
	if not ev.is_pressed() or ev.is_echo() or ev is InputEventMouse:
		return
	if ev.is_action_pressed("pause") or ev.is_action_pressed("ui_cancel") or ev.is_action_pressed("party_menu") \
			or (ev is InputEventJoypadButton and ev.button_index == JOY_BUTTON_B):
		close()
	elif ev.is_action_pressed("interact") or ev.is_action_pressed("ui_accept"):
		_buy()
	elif ev.is_action_pressed("move_back") or ev.is_action_pressed("ui_down"):
		sel = (sel + 1) % stock.size(); _refresh(); UITheme.play("move")
	elif ev.is_action_pressed("move_forward") or ev.is_action_pressed("ui_up"):
		sel = (sel - 1 + stock.size()) % stock.size(); _refresh(); UITheme.play("move")
	else:
		return
	get_viewport().set_input_as_handled()

func close() -> void:
	if not is_inside_tree():
		return
	MenuUI.stack.erase(self)
	UITheme.play("back")
	closed.emit()
	queue_free()

func _exit_tree() -> void:
	MenuUI.stack.erase(self)

func _lbl(text: String, size: int, color: Color, font: Font, outline: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color.BLACK)
		l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _box(bg: Color, border: Color, w: int, radius: int, shadow := false) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(w)
	sb.set_corner_radius_all(radius)
	if shadow:
		sb.shadow_color = Color(0, 0, 0, 0.6); sb.shadow_size = 24
	return sb
