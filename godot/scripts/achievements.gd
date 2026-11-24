# Achievements (Ebain 11/23): a popup in the top-right when you do something. Kept across every playthrough
# in user://achievements.cfg (New Game never resets them).
#
# TO ADD ONE: add a line to LIST below. "when" says what unlocks it (no other code needed for the first two):
#   "progress:<id>"  any id from progress_data.gd: story outcomes ("village_chug"), quests ("quest_bar_tab"), "chapter1"…
#   "flag:<name>"    any story flag the moment it's set (Game.set_flag), e.g. "flag:skornKing"
#   "manual"         you call Game.achieve("<id>") yourself from any script (for things with no flag, like "fell 10 times")
# "hidden": true shows "???" in the list until it's unlocked (for spoilers / secret ones).
#
# Ebain picks the real achievements. The ones below are # DRAFT examples wired to things that already exist.
class_name Achievements
extends CanvasLayer

const SAVE_PATH := "user://achievements.cfg"

const LIST := [
	{ "id": "first_fire", "name": "Arsonist (Affectionate)", "desc": "Burned the map to start the fire.", "when": "flag:campLit" }, # DRAFT
	{ "id": "chug_king", "name": "Steel Liver", "desc": "Challenged the Chief to a chug-off.", "when": "progress:village_chug" }, # DRAFT
	{ "id": "purple_king", "name": "Long Live the Purple King", "desc": "Crowned Skorn king of the goblins.", "when": "progress:village_skorn_king" }, # DRAFT
	{ "id": "bar_tab", "name": "Fiscally Responsible", "desc": "Settled the bar tab.", "when": "progress:quest_bar_tab" }, # DRAFT
	{ "id": "chapter1", "name": "On Some Type Shi", "desc": "Finished Chapter 1.", "when": "progress:chapter1", "hidden": true }, # DRAFT
]

var got := {}            # id -> true
var _queue: Array = []   # popups waiting their turn
var _showing := false
var _sfx: AudioStreamPlayer

func _ready() -> void:
	layer = 60   # above the HUD and the dialogue box
	process_mode = Node.PROCESS_MODE_ALWAYS   # still pops while paused
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK and cf.has_section("got"):
		for k in cf.get_section_keys("got"):
			got[k] = true
	_sfx = AudioStreamPlayer.new()
	if ResourceLoader.exists("res://assets/sounds/sfx_reward.ogg"):
		_sfx.stream = load("res://assets/sounds/sfx_reward.ogg")
	add_child(_sfx)

# Called by Game for every progress unlock and flag. Unlocks any achievement whose "when" matches.
func event(trigger: String) -> void:
	for a in LIST:
		if a["when"] == trigger:
			give(a["id"])

func give(id: String) -> void:
	if got.has(id) or Game.title_mode:
		return
	var a = find(id)
	if a == null:
		push_warning("Achievement '%s' isn't in achievements.gd LIST" % id)
		return
	got[id] = true
	var cf := ConfigFile.new()
	for k in got:
		cf.set_value("got", k, true)
	cf.save(SAVE_PATH)
	_queue.append(a)
	if not _showing:
		_show_next()

func find(id: String):
	for a in LIST:
		if a["id"] == id:
			return a
	return null

func count() -> int:
	return LIST.filter(func(a): return got.has(a["id"])).size()

# Rows for the title screen's Achievements list (MenuUI rows).
func menu_rows() -> Array:
	var rows: Array = []
	for a in LIST:
		var have := got.has(a["id"])
		var secret: bool = a.get("hidden", false) and not have
		rows.append({ "text": "???" if secret else a["name"], "value": "Unlocked" if have else "Locked",
			"note": "Hidden achievement." if secret else a["desc"], "pick": func(): pass })
	return rows

# ---------------------------------------------------------------- the popup
func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var a: Dictionary = _queue.pop_front()
	var p := PanelContainer.new()   # themed (UITheme): ornate panel, Cinzel
	var sb := UITheme.panel(0.95)
	sb.content_margin_left = 24; sb.content_margin_right = 24; sb.content_margin_top = 16; sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	var col := VBoxContainer.new()
	p.add_child(col)
	col.add_child(UITheme.lbl("ACHIEVEMENT UNLOCKED", 13, "accent", UITheme.head_font()))
	col.add_child(UITheme.lbl(a["name"], 22, "text", UITheme.row_font()))
	var ds := UITheme.lbl(a["desc"], 15, "note")
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD
	ds.custom_minimum_size.x = 300
	col.add_child(ds)
	add_child(p)
	# top-right, below the "Controlling: ..." label; slides in from the right edge
	await get_tree().process_frame
	var w := get_viewport().get_visible_rect().size.x
	var x_in := w - p.size.x - 20
	p.position = Vector2(w + 10, 78)
	if _sfx.stream:
		_sfx.play()
	var t := create_tween()
	t.tween_property(p, "position:x", x_in, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(3.5)
	t.tween_property(p, "position:x", w + 10, 0.3).set_ease(Tween.EASE_IN)
	await t.finished
	p.queue_free()
	_show_next()
