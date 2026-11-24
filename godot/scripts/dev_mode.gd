# Developer / test mode (press F1 anywhere outside a fight).
#   Dialogue: Normal · Choices only · Skip all (auto-picks a choice) · Only lines from one character
#   Dialogue viewer: read every line of any scene script without playing it
#   Jump to any scene · give XP / items / gear · auto-win fights
# The skipping happens here, before lines reach the dialogue box, so dialogue.gd itself is untouched.
class_name DevMode
extends Node

const MODES := ["normal", "choices", "skip", "only:skorn", "only:lykor", "only:xylo", "only:goblins", "only:dulbers", "only:mattias_giant", "only:narrator"]
const MODE_LABELS := {
	"normal": "Normal",
	"choices": "Choices only (lines skipped)",
	"skip": "Skip ALL (auto-picks a choice)",
	"only:skorn": "Only Skorn's lines",
	"only:lykor": "Only Lykor's lines",
	"only:xylo": "Only Xylo's lines",
	"only:goblins": "Only goblin lines (Chief, goblins, named goblins)",
	"only:dulbers": "Only Dulbers' lines",
	"only:mattias_giant": "Only Mattias + the Giant",
	"only:narrator": "Only narrator lines",
}
const SCRIPTS := {
	"Camp (Scene 1)": "res://scripts/camp_script.gd",
	"Goblin Woods Trail": "res://scripts/trail_script.gd",
	"Goblin Village (Scene 2)": "res://scripts/village_script.gd",
	"Village buildings": "res://scripts/village_rooms_script.gd",
	"Metocy Mart (Scene 3)": "res://scripts/mart_script.gd",
	"The Pass (Scene 4)": "res://scripts/pass_script.gd",
	"Summit Path + Wizard's Lair (Scene 5)": "res://scripts/summit_script.gd",
}
const SCENES := [["Camp (Scene 1)", "res://main.tscn"], ["Goblin Woods Trail", "res://trail.tscn"], ["Goblin Village (Scene 2)", "res://village.tscn"], ["Metocy Mart (Scene 3)", "res://mart.tscn"], ["Old Ruins (side path)", "res://ruins.tscn"], ["Rat Cave (side path)", "res://cave.tscn"], ["The Pass (Scene 4)", "res://pass.tscn"], ["Summit Path + Wizard's Lair (Scene 5)", "res://summit.tscn"], ["Deloye Lore Library (secret)", "res://deloye_library.tscn"]]

# ================================================================ dialogue filtering (used by Level.run_dialogue)
static func active() -> bool:
	return Game.dev_dialogue != "normal"

static func shows(s: Dictionary) -> bool:
	var m: String = Game.dev_dialogue
	if m == "normal":
		return true
	if not m.begins_with("only:"):
		return false
	var who: String = s.get("who", "narrator")
	match m.substr(5):
		"goblins": return who in ["goblin", "goblins", "chief"]
		"dulbers": return who in ["dulbers", "dulbers_demon"]
		"mattias_giant": return who in ["mattias", "giant"]
		var w: return who == w
	return false

static func run(lv: Node, steps: Array) -> void:
	var d = lv.dialogue
	d.active = true
	d.panel.visible = false
	await walk(lv, steps)
	d.panel.visible = false
	d.stop_voice()
	d.active = false

static func walk(lv: Node, steps: Array) -> void:
	var d = lv.dialogue
	for s in steps:
		if s.has("do"):
			await lv.do_action(s["do"])
		elif s.has("choice"):
			var opts: Array = s["choice"].filter(func(o): return not o.has("if") or Game.flag(o["if"]))
			if opts.is_empty():
				continue
			var i := 0
			if Game.dev_dialogue == "skip":
				i = clampi(Game.dev_pick - 1, 0, opts.size() - 1)
				lv.show_toast("(dev) picked: %s" % opts[i]["text"], 1.6)
				await lv.get_tree().process_frame
			else:
				d.panel.visible = true
				i = await d.ask(opts)
			if opts[i].has("outcome"):
				ProgressData.pick_outcome(opts[i]["outcome"])
			await walk(lv, opts[i]["steps"])
		elif s.has("if"):
			if Game.flag(s["if"]):
				await walk(lv, s["steps"])
		elif s.has("if_not"):
			if not Game.flag(s["if_not"]):
				await walk(lv, s["steps"])
		elif shows(s):
			d.panel.visible = true
			await d.say(s)
		else:
			d.panel.visible = false

# ================================================================ the F1 menu
var lv: Node
var root: Control
var rows: Array = []
var sel := 0
var view_mode := false
var view_keys: Array = []
var view_i := 0
var view_txt: RichTextLabel
var view_title: Label

func open(level: Node) -> void:
	lv = level
	lv.busy = true
	lv.freeze_all(true)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	lv.hud.add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := _panel(820, 560)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	col.add_child(lv._label("DEVELOPER MODE", Vector2.ZERO, 30, Color("#7dff8a"), 6))
	col.add_child(lv._label("For testing. W/S choose · A/D change · E do it · F1 or Esc close", Vector2.ZERO, 14, Color(1, 1, 1, 0.6), 3))
	for i in 9:
		var l: Label = lv._label("", Vector2.ZERO, 20, Color.WHITE, 4)
		col.add_child(l)
		rows.append(l)
	_render()
	await get_tree().process_frame
	await get_tree().process_frame
	while is_instance_valid(root):
		await get_tree().process_frame
		if view_mode:
			_view_input()
			continue
		if Input.is_action_just_pressed("move_forward"): sel = (sel + rows.size() - 1) % rows.size(); _render()
		elif Input.is_action_just_pressed("move_back"): sel = (sel + 1) % rows.size(); _render()
		elif Input.is_action_just_pressed("move_left"): _change(-1)
		elif Input.is_action_just_pressed("move_right"): _change(1)
		elif Input.is_action_just_pressed("interact"): _do()
		elif Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("dev_menu"):
			close()

var scene_i := 0
func _render() -> void:
	var txt := [
		"Dialogue:  < %s >" % MODE_LABELS[Game.dev_dialogue],
		"Skip-all picks choice #  < %d >" % Game.dev_pick,
		"Dialogue viewer (read every line of a scene)  [E]",
		"Jump to scene:  < %s >  [E]" % SCENES[scene_i][0],
		"Fights:  < %s >" % ("AUTO-WIN (skip fights)" if Game.dev_autowin else "Normal"),
		"+100 XP  [E]   (now Level %d, %d XP)" % [Game.level, Game.xp],
		"Give items: +3 Beezy, +2 Chipotle Bowls  [E]",
		"Give all gear + flags hasMidtocy / goblinAllies  [E]",
		"Close",
	]
	for i in rows.size():
		rows[i].text = ("> " if i == sel else "   ") + txt[i]
		rows[i].add_theme_color_override("font_color", Color("#7dff8a") if i == sel else Color.WHITE)

func _change(d: int) -> void:
	lv.ui_sfx.play()
	match sel:
		0: Game.dev_dialogue = MODES[(MODES.find(Game.dev_dialogue) + d + MODES.size()) % MODES.size()]
		1: Game.dev_pick = clampi(Game.dev_pick + d, 1, 5)
		3: scene_i = (scene_i + d + SCENES.size()) % SCENES.size()
		4: Game.dev_autowin = not Game.dev_autowin
	_render()

func _do() -> void:
	lv.ui_sfx.play()
	match sel:
		0, 1, 4: _change(1)
		2: _open_viewer()
		3:
			close()
			Game.goto(SCENES[scene_i][1])
		5:
			var ups: Array = Game.add_xp(100)
			if not ups.is_empty():
				lv.show_toast("(dev) Level %d" % Game.level)
			_render()
		6:
			Game.add_item("beer", 3)
			Game.add_item("bowl", 2)
			lv.show_toast("(dev) %s got Beezy ×3 · Bowl ×2 (now %d · %d)" % [Game.active_fighter.capitalize(), Game.count("beer", Game.active_fighter), Game.count("bowl", Game.active_fighter)])
		7:
			for g in CombatData.GEAR.keys():
				Game.give_gear(g)
			Game.set_flag("hasMidtocy")
			Game.set_flag("goblinAllies")
			lv.show_toast("(dev) All gear found (equip with I) · hasMidtocy · goblinAllies")
		8: close()

func close() -> void:
	if is_instance_valid(root):
		root.queue_free()
	lv.busy = false
	lv.freeze_all(false)
	lv.interact_cooldown = 0.3
	queue_free()

# ---------------------------------------------------------------- dialogue viewer
func _open_viewer() -> void:
	view_mode = true
	view_keys = SCRIPTS.keys()
	var p := _panel(1100, 640)
	p.name = "Viewer"
	var col := VBoxContainer.new()
	p.add_child(col)
	var title: Label = lv._label("", Vector2.ZERO, 22, Color("#7dff8a"), 5)
	view_title = title
	col.add_child(title)
	view_txt = RichTextLabel.new()
	view_txt.bbcode_enabled = true
	view_txt.custom_minimum_size = Vector2(1060, 560)
	view_txt.scroll_active = true
	view_txt.add_theme_font_size_override("normal_font_size", 15)
	view_txt.add_theme_font_size_override("bold_font_size", 15)
	col.add_child(view_txt)
	_view_render()

func _view_render() -> void:
	var key: String = view_keys[view_i]
	view_title.text = "%s   ·   A/D other scene · W/S scroll · Q back   (filter: %s)" % [key, MODE_LABELS[Game.dev_dialogue] if Game.dev_dialogue.begins_with("only:") else "everyone"]
	var scr: GDScript = load(SCRIPTS[key])
	var out := ""
	var consts: Dictionary = scr.get_script_constant_map()
	for name in consts:
		var v = consts[name]
		if v is Array and not v.is_empty() and v[0] is Dictionary:
			var block := _flatten(v, 0)
			if block != "":
				out += "\n[b][color=#e8b923]== %s ==[/color][/b]\n%s" % [name, block]
	view_txt.text = out if out != "" else "(no lines match this filter)"
	view_txt.scroll_to_line(0)

func _flatten(steps: Array, depth: int) -> String:
	var out := ""
	var pad := "    ".repeat(depth)
	for s in steps:
		if not s is Dictionary:
			continue
		if s.has("choice"):
			for o in s["choice"]:
				var inner := _flatten(o["steps"], depth + 1)
				out += "%s[color=#8ad8ff]> %s%s[/color]\n%s" % [pad, o["text"], "  (if %s)" % o["if"] if o.has("if") else "", inner]
		elif s.has("if") or s.has("if_not"):
			var inner := _flatten(s["steps"], depth + 1)
			if inner != "":
				out += "%s[color=#a49cc4](if %s%s)[/color]\n%s" % [pad, "" if s.has("if") else "NOT ", s.get("if", s.get("if_not", "")), inner]
		elif s.has("do"):
			continue
		elif s.has("line"):
			var filt: bool = Game.dev_dialogue.begins_with("only:")
			if filt and not shows(s):
				continue
			var who: String = s.get("name", s.get("who", "narrator"))
			out += "%s[b]%s:[/b] %s\n" % [pad, who.capitalize() if not s.has("name") else who, s["line"]]
	return out

func _view_input() -> void:
	if Input.is_action_just_pressed("move_left"): view_i = (view_i + view_keys.size() - 1) % view_keys.size(); _view_render()
	elif Input.is_action_just_pressed("move_right"): view_i = (view_i + 1) % view_keys.size(); _view_render()
	elif Input.is_action_pressed("move_forward"): view_txt.get_v_scroll_bar().value -= 14
	elif Input.is_action_pressed("move_back"): view_txt.get_v_scroll_bar().value += 14
	elif Input.is_key_pressed(KEY_Q) or Input.is_action_just_pressed("pause"):
		root.get_node("Viewer").queue_free()
		view_mode = false
		await get_tree().process_frame

func _panel(w: float, h: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5; panel.anchor_right = 0.5; panel.anchor_top = 0.5; panel.anchor_bottom = 0.5
	panel.offset_left = -w / 2; panel.offset_right = w / 2; panel.offset_top = -h / 2; panel.offset_bottom = h / 2
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.04, 0.97)
	sb.border_color = Color("#7dff8a")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 16; sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)
	return panel
