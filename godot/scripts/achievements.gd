# Achievements (Ebain 11/23): a popup in the top-right when you do something. Kept across every playthrough
# in user://achievements.cfg (New Game never resets them).
#
# TO ADD ONE: add a line to LIST below. "when" says what unlocks it (no other code needed for the first two):
#   "progress:<id>"  any id from progress_data.gd: story outcomes ("village_chug"), quests ("quest_bar_tab"), "chapter1"…
#   "flag:<name>"    any story flag the moment it's set (Game.set_flag), e.g. "flag:skornKing"
#   "manual"         you call Game.achieve("<id>") yourself from any script (for things with no flag, like "fell 10 times")
#   "all:<id>,<id>"  every one of these progress ids found (across playthroughs): "all:loot_0,loot_1,…"
#   "count:<key>:<n>" the counter <key> reached n. Bump it with Game.ach.bump("<key>") (saved across playthroughs)
#   "pct:100"        every progress item found (100% completion)
# "hidden": true shows "???" in the list until it's unlocked (for spoilers / secret ones).
#
# Ebain's batch (11/25): the names marked "# Ebain" are his words; descriptions and the three Pass names are # DRAFT.
# The first six are older # DRAFT examples.
class_name Achievements
extends CanvasLayer

const SAVE_PATH := "user://achievements.cfg"

const LIST := [
	{ "id": "first_fire", "name": "Arsonist (Affectionate)", "desc": "Burned the map to start the fire.", "when": "flag:campLit" }, # DRAFT
	{ "id": "chug_king", "name": "Steel Liver", "desc": "Challenged the Chief to a chug-off.", "when": "progress:village_chug" }, # DRAFT
	{ "id": "purple_king", "name": "Long Live the Purple King", "desc": "Crowned Skorn king of the goblins.", "when": "progress:village_skorn_king" }, # DRAFT
	{ "id": "bar_tab", "name": "Fiscally Responsible", "desc": "Settled the bar tab.", "when": "progress:quest_bar_tab" }, # DRAFT
	{ "id": "chapter1", "name": "On Some Type Shi", "desc": "Finished Chapter 1.", "when": "progress:chapter1", "hidden": true }, # DRAFT
	{ "id": "lore_accurate", "name": "Lore Accurate", "desc": "Found the Deloye Lore library.", "when": "progress:deloye_found", "hidden": true }, # DRAFT (name)
	# --- Ebain 11/25
	{ "id": "sneaky_shi", "name": "On Some Sneaky Shi", "desc": "Snuck past Diddy Chud Giant.", "when": "flag:sneakWon" }, # Ebain (name), DRAFT (desc)
	{ "id": "good_boy", "name": "Good boy", "desc": "Swore loyalty to Dulbmeethus. Dulbers approves.", "when": "progress:ambush_apologize", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "slopbowl", "name": "Slopbowl Consumer", "desc": "Ate 3 Chipotle Bowls.", "when": "count:bowl:3" }, # Ebain (name), DRAFT (desc)
	{ "id": "neuralinked", "name": "Neuralinked", "desc": "Got the Deloye Lore Neuralink.", "when": "flag:deloyeGift", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "crunk", "name": "Crunk", "desc": "Drank 3 beezy.", "when": "count:beer:3" }, # Ebain (name), DRAFT (desc)
	{ "id": "lore_specialist", "name": "Deloye Lore Specialist", "desc": "Found all 5 secret Lost Deloye Lore pages.",
		"when": "all:lostpage_camp,lostpage_trail,lostpage_village,lostpage_mart,lostpage_pass", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "six_seven", "name": "6-7!!!!!", "desc": "Did the 6-7.", "when": "manual", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "hear_me_doe", "name": "Yall could hear me doe?", "desc": "Dulbmeethus pulls up to help yo ahh.", "when": "manual", "hidden": true }, # Ebain
	{ "id": "trail_mix", "name": "Trail Mix", "desc": "Found all 6 loot spots on the trail.",
		"when": "all:loot_0,loot_1,loot_2,loot_3,loot_4,loot_5" }, # Ebain
	{ "id": "dulbers_boy", "name": "Hey guys it's your boy", "desc": "Met Dulbers Frint.", "when": "flag:dulbersMet" }, # Ebain (name), DRAFT (desc)
	{ "id": "aight_bet", "name": "Aight. Bet.", "desc": "Woke up Diddy Chud Giant.", "when": "flag:giantWoke" }, # DRAFT (Ebain liked the Pass ones)
	{ "id": "lore_session", "name": "Lore Session", "desc": "Out-lored a giant.", "when": "flag:loreWon" }, # DRAFT
	{ "id": "diddy_slap", "name": "The Slap Heard Round the Pass", "desc": "Slapped Diddy Chud awake.", "when": "progress:pass_fight" }, # DRAFT
	{ "id": "geeking", "name": "Geeking off that midtocy", "desc": "Lost to Metocin Mattias.", "when": "flag:endingCooked", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "mattias_slayer", "name": "Slayer of Metocin Mattias", "desc": "Beat Mattias.", "when": "flag:mattiasBeaten", "hidden": true }, # Ebain
	{ "id": "metocy_party", "name": "On some metocy shi", "desc": "Gave every goblin metocy.", "when": "flag:endingParty", "hidden": true }, # Ebain (name), DRAFT (desc)
	{ "id": "tactical_retreat", "name": "Tactical retreat", "desc": "Ran from 5 fights.", "when": "count:fled:5" }, # Ebain (name), DRAFT (desc)
	{ "id": "hundred", "name": "100%", "desc": "Hit 100% completion. I sincerely thank you for enjoying the game this much.", "when": "pct:100", "hidden": true }, # Ebain (also unlocks the 100% song, not made yet)
	{ "id": "ladle_shi", "name": "On Some Ladle Shi", "desc": "Bought The Golden Ladle.", "when": "flag:bought_golden_ladle" }, # Ebain (name), DRAFT (desc)
	{ "id": "drip", "name": "U had said drip?", "desc": "Bought the Jordan 9's.", "when": "flag:bought_jordan9s" }, # Ebain (name), DRAFT (desc)
	{ "id": "cooked", "name": "You got cooked", "desc": "Lost your first fight.", "when": "manual" }, # Ebain (name), DRAFT (desc)
]

var got := {}            # id -> true
var counts := {}         # counter key -> n (beer, bowl, fled), saved across playthroughs
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
	if cf.has_section("counts"):
		for k in cf.get_section_keys("counts"):
			counts[k] = int(cf.get_value("counts", k, 0))
	_sfx = AudioStreamPlayer.new()
	_sfx.volume_db = -5.0
	if ResourceLoader.exists("res://assets/sounds/sting_achievement.ogg"):   # 11/27 sound batch 4 (was sfx_reward)
		_sfx.stream = load("res://assets/sounds/sting_achievement.ogg")
	elif ResourceLoader.exists("res://assets/sounds/sfx_reward.ogg"):
		_sfx.stream = load("res://assets/sounds/sfx_reward.ogg")
	add_child(_sfx)

# Called by Game for every progress unlock and flag. Unlocks any achievement whose "when" matches.
func event(trigger: String) -> void:
	var is_progress := trigger.begins_with("progress:")
	for a in LIST:
		var w: String = a["when"]
		if w == trigger:
			give(a["id"])
		elif is_progress and w.begins_with("all:"):
			_check_all(a, trigger)
	if is_progress:
		_check_pct.call_deferred()   # after Game.unlock has recorded the id

# "all:" achievements: every listed progress id found. Game.unlock calls event() BEFORE it records the id, so the
# id that triggered this event counts as found.
func _check_all(a: Dictionary, trigger: String) -> void:
	for id in a["when"].substr(4).split(","):
		if not (Game.progress.has(id) or trigger == "progress:" + id):
			return
	give(a["id"])

func _check_pct() -> void:
	if not ProgressData.ITEMS.all(func(it): return Game.progress.has(it[0])):
		return
	for a in LIST:
		if a["when"] == "pct:100":
			give(a["id"])

# Counters for "count:<key>:<n>" achievements (beer/bowl eaten, fights fled). Saved across playthroughs.
func bump(key: String, n := 1) -> void:
	if Game.title_mode:
		return
	counts[key] = int(counts.get(key, 0)) + n
	_save()
	for a in LIST:
		var p: PackedStringArray = String(a["when"]).split(":")
		if p.size() == 3 and p[0] == "count" and p[1] == key and counts[key] >= int(p[2]):
			give(a["id"])

func _save() -> void:
	var cf := ConfigFile.new()
	for k in got:
		cf.set_value("got", k, true)
	for k in counts:
		cf.set_value("counts", k, counts[k])
	cf.save(SAVE_PATH)

func give(id: String) -> void:
	if got.has(id) or Game.title_mode:
		return
	var a = find(id)
	if a == null:
		push_warning("Achievement '%s' isn't in achievements.gd LIST" % id)
		return
	got[id] = true
	_save()
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
