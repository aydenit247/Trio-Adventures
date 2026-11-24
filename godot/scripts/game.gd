# Global game state (autoload "Game"): story flags, items, XP/levels, gear and settings that carry between areas.
extends Node

const LEVELS := [0, 0, 50, 120, 220, 350, 520, 740, 1000, 1300, 1650]

# Story flags, same names as the web game:
# goblinAllies, skornKing, chugWon, lykorDethroned, foreheadLoser, bag_checked, ...
var flags := {}
# Each character carries their own stuff (Asar's call). Use the item functions below, never write these directly.
var bags := {}                    # fighter id -> { item id -> count }   (beer, bowl, BOOSTS items)
var gear_owner := {}              # gear id -> fighter who carries it (worn or in their bag)
var key_owner := {}               # key item id -> fighter (metocy_map, midtocy, lucky_spoon, shiny_spoon)
var active_fighter := "skorn"     # who you're controlling: story rewards with no obvious receiver go to them
const BAG_FIGHTERS := ["skorn", "lykor", "xylo", "chief"]
const KEY_DEFAULT_OWNER := { "metocy_map": "skorn", "midtocy": "skorn" }
var tts_on := true

# progression (shared party level, like the web version)
var xp := 0
var level := 1
var gear_owned: Array = []        # gear ids found so far
var equipped := {}                # fighter id -> { slot -> gear id }   (slots: GEAR_SLOTS below; gear slot types in CombatD.GEAR)
var boosts := {}                  # fighter id -> { hp, meter } from used BOOSTS items (permanent)
var map_seen := {}                # area key -> PackedByteArray of explored map cells (Minimap/MapUI fog)
var visited: Array = []           # area keys you've been to (world map fog)
var hurt := {}                    # fighter id -> HP missing. Damage carries between fights (see max_hp/hp/heal)
var gold := 0                     # currency, dropped by enemies (see "gold" on each enemy in CombatD.FIGHTS)
var used67 := false               # the 6-7 happens once per game
var forehead := ""                # funny penalty text written on the leader's forehead
var quests := {}                  # id -> { title, note, state = "active" | "done" }

# developer / test mode (F1)
var dev_dialogue := "normal"      # see DevMode.MODES
var dev_pick := 1                 # which choice "Skip all" picks
var dev_autowin := false          # fights are skipped and count as won

# settings
var difficulty := 1               # 0 Chill · 1 Normal · 2 Crashout
var timed_auto := false           # timed hits/blocks resolve on their own

func flag(name: String) -> bool:
	return flags.get(name, false)

func set_flag(name: String, value = true) -> void:
	flags[name] = value
	if value and ach:
		ach.event("flag:" + name)   # achievements.gd
	if value and PD.FLAGS.has(name):
		unlock(PD.FLAGS[name])

func reset() -> void:
	flags = {}
	bags = {}
	gear_owner = {}
	key_owner = {}
	active_fighter = "skorn"
	xp = 0
	level = 1
	gear_owned = []
	equipped = {}
	boosts = {}
	hurt = {}
	map_seen = {}
	visited = []
	gold = 0
	used67 = false
	forehead = ""
	quests = {}

# Returns the levels reached (empty if none)
func add_xp(n: int) -> Array:
	xp += n
	var out := []
	while level + 1 < LEVELS.size() and xp >= LEVELS[level + 1]:
		level += 1
		out.append(level)
	if not out.is_empty():
		heal_all()   # leveling up refills everyone
	return out

func xp_to_next() -> int:
	return LEVELS[level + 1] - xp if level + 1 < LEVELS.size() else 0

func give_gear(id: String, to := "") -> bool:
	if gear_owned.has(id):
		return false
	gear_owned.append(id)
	gear_owner[id] = to if to != "" else active_fighter
	return true

# ---- per-character items
func bag(f: String) -> Dictionary:
	if not bags.has(f):
		bags[f] = {}
	return bags[f]

# How many of an item one fighter has (f = "" → the whole party).
func count(id: String, f := "") -> int:
	if f != "":
		return int(bag(f).get(id, 0))
	var n := 0
	for k in bags:
		n += int(bags[k].get(id, 0))
	return n

# Give someone an item (f = "" → whoever you're controlling). Returns who got it.
func add_item(id: String, n := 1, f := "") -> String:
	var who := f if f != "" else active_fighter
	bag(who)[id] = count(id, who) + n
	return who

# Take items (f = "" → from anyone, the one you're controlling first). False if there aren't enough.
func take_item(id: String, n := 1, f := "") -> bool:
	if (count(id, f) if f != "" else count(id)) < n:
		return false
	var order: Array = [f] if f != "" else [active_fighter] + BAG_FIGHTERS
	for who in order:
		while n > 0 and count(id, who) > 0:
			bag(who)[id] = count(id, who) - 1
			n -= 1
	return true

func set_count(f: String, id: String, n: int) -> void:
	bag(f)[id] = maxi(0, n)

# Move an item, a gear piece or a key item from one fighter to another. Gear gets taken off first.
func give_item(from: String, to: String, id: String, n := 1) -> bool:
	if CombatD.GEAR.has(id):
		if gear_owner.get(id, "") != from:
			return false
		var w := wearer(id)
		if not w.is_empty():
			unequip(w[0], w[1])
		gear_owner[id] = to
		return true
	if KEY_DEFAULT_OWNER.has(id) or key_owner.has(id):
		key_owner[id] = to
		return true
	if not take_item(id, n, from):
		return false
	add_item(id, n, to)
	return true

func owner_of_key(id: String) -> String:
	return key_owner.get(id, KEY_DEFAULT_OWNER.get(id, "lykor"))

# Each fighter's beer/bowl for a fight (battle.gd), and writing what's left back afterwards.
func fight_bags(ids: Array) -> Dictionary:
	var out := {}
	for f in ids:
		out[f] = { "beer": count("beer", f), "bowl": count("bowl", f) }
	return out

func gear_in_bag(f: String) -> Array:   # unequipped gear this fighter carries
	var out := []
	for g in gear_owned:
		if gear_owner.get(g, "lykor") == f and wearer(g).is_empty():
			out.append(g)
	return out

signal gold_changed(delta: int)       # (Asar) the level plays the coin sound
signal quest_finished(id: String)     # (Asar) the level plays the reward sound

func add_gold(n: int) -> void:
	var before := gold
	gold = max(0, gold + n)
	if gold != before:
		gold_changed.emit(gold - before)

# ---- equipment: 7 slots per fighter. A slot only takes gear of its type ("trinket" fits either trinket slot).
const GEAR_SLOTS := ["helmet", "armor", "shoes", "shield", "weapon", "trinket1", "trinket2"]
const SLOT_NAMES := { "helmet": "Helmet", "armor": "Armor", "shoes": "Shoes", "shield": "Shield", "weapon": "Weapon", "trinket1": "Trinket 1", "trinket2": "Trinket 2" }
const CombatD = preload("res://scripts/combat/combat_data.gd")

static func slot_type(slot: String) -> String:
	return "trinket" if slot.begins_with("trinket") else slot

func gear_type(gear_id: String) -> String:
	return CombatD.GEAR.get(gear_id, {}).get("slot", "trinket")

func slots_of(fighter: String) -> Dictionary:
	if not equipped.has(fighter) or not equipped[fighter] is Dictionary:
		equipped[fighter] = {}
	return equipped[fighter]

# Who has this gear on, and in which slot: ["lykor", "armor"], or [] if it's in the bag.
func wearer(gear_id: String) -> Array:
	for f in equipped:
		if equipped[f] is Dictionary:
			for s in equipped[f]:
				if equipped[f][s] == gear_id:
					return [f, s]
	return []

func unequip(fighter: String, slot: String) -> void:
	slots_of(fighter).erase(slot)

# Put gear on a fighter. slot "" = pick the right slot (first free trinket slot, else trinket 1).
# Takes it off whoever had it. Returns the slot used, or "" if it doesn't fit.
func equip(fighter: String, gear_id: String, slot := "") -> String:
	var t := gear_type(gear_id)
	if slot == "":
		if t == "trinket":
			var sl := slots_of(fighter)
			slot = "trinket1" if not sl.has("trinket1") else ("trinket2" if not sl.has("trinket2") else "trinket1")
		else:
			slot = t
	if slot_type(slot) != t:
		return ""
	var w := wearer(gear_id)
	if not w.is_empty():
		unequip(w[0], w[1])
	slots_of(fighter)[slot] = gear_id
	gear_owner[gear_id] = fighter
	return slot

# Everything a fighter's gear adds up to, in the same shape as one CombatD.GEAR entry (battle.gd reads this).
func gear_stats(fighter: String) -> Dictionary:
	var out := { "hp": 0, "power": 0.0, "spd": 0, "start": 0, "meter": 1.0, "armor": 0 }
	for s in slots_of(fighter):
		var G: Dictionary = CombatD.GEAR.get(slots_of(fighter)[s], {})
		out["hp"] += G.get("hp", 0)
		out["power"] += G.get("power", 0.0)
		out["spd"] += G.get("spd", 0)
		out["start"] = mini(100, out["start"] + G.get("start", 0))
		out["meter"] *= G.get("meter", 1.0)
		out["armor"] += G.get("armor", 0)
		for k in ["no_ones", "gouge_proof"]:
			if G.get(k, false):
				out[k] = true
	var bo: Dictionary = boosts.get(fighter, {})   # permanent boosts from used items
	out["hp"] += bo.get("hp", 0)
	out["meter"] *= bo.get("meter", 1.0)
	return out

# ---- HP between fights. Stored as HP missing, so max HP can change (level, gear) without breaking it.
# battle.gd computes max HP the same way: (base + gear hp) * (1 + 0.1 per level above 1).
func max_hp(fighter: String) -> int:
	var P: Dictionary = CombatD.PARTY.get(fighter, {})
	if P.is_empty():
		return 0
	return int(round((P["hp"] + gear_stats(fighter).get("hp", 0)) * (1.0 + 0.1 * (level - 1))))

func hp(fighter: String) -> int:
	var m := max_hp(fighter)
	return clampi(m - int(hurt.get(fighter, 0)), 1, m)

func set_hp(fighter: String, value: int) -> void:
	var m := max_hp(fighter)
	var missing := clampi(m - value, 0, m - 1)   # never below 1 HP outside a fight
	if missing <= 0:
		hurt.erase(fighter)
	else:
		hurt[fighter] = missing

# Heals up to n, returns how much it actually healed
func heal(fighter: String, n: int) -> int:
	var before := hp(fighter)
	set_hp(fighter, before + n)
	return hp(fighter) - before

func heal_all() -> void:
	hurt = {}

func anyone_hurt() -> bool:
	for f in hurt:
		if int(hurt[f]) > 0:
			return true
	return false

# Drink/eat a healing item (beer, bowl) outside a fight, from the fighter's own bag. Returns HP healed (0 = not used).
func use_heal_item(fighter: String, id: String) -> int:
	var n := int(CombatD.ITEMS.get(id, {}).get("heal", 0))
	if n <= 0 or count(id, fighter) <= 0 or hp(fighter) >= max_hp(fighter):
		return 0
	take_item(id, 1, fighter)
	return heal(fighter, n)

# Use a BOOSTS item (Backup Conditioner, Deloye Lore Vol. 9) on a fighter: used up, bonus is permanent.
func use_boost(fighter: String, item_id: String) -> bool:
	var B: Dictionary = CombatD.BOOSTS.get(item_id, {})
	if B.is_empty() or count(item_id, fighter) <= 0:   # uses the fighter's own copy
		return false
	take_item(item_id, 1, fighter)
	var bo: Dictionary = boosts.get(fighter, {})
	bo["hp"] = bo.get("hp", 0) + B.get("hp", 0)
	bo["meter"] = bo.get("meter", 1.0) * B.get("meter", 1.0)
	boosts[fighter] = bo
	return true

# Old saves stored one gear id per fighter: move it into the right slot.
func _migrate_equipped(old: Dictionary) -> Dictionary:
	var out := {}
	for f in old:
		if old[f] is Dictionary:
			out[f] = old[f].duplicate()
		elif old[f] is String and old[f] != "":
			var t := gear_type(old[f])
			out[f] = { ("trinket1" if t == "trinket" else t): old[f] }
	return out

func start_quest(id: String, title: String, note: String) -> void:
	if not quests.has(id):
		quests[id] = { "title": title, "note": note, "state": "active" }

func finish_quest(id: String) -> void:
	if quests.has(id):
		if quests[id]["state"] != "done":
			quest_finished.emit(id)
			unlock("quest_" + id)
		quests[id]["state"] = "done"

func quest_state(id: String) -> String:
	return quests[id]["state"] if quests.has(id) else ""

# ================================================================ scene changes (with a loading card)
const LOADING_TIPS := [   # DRAFT — Ebain can rewrite these
	"Tip: Skorn cannot read. Please do not hand Skorn maps.",
	"Tip: Lykor's conditioner is not a healing item. Do not ask him.",
	"Tip: Deloye Lore has 9 volumes and roughly zero lore.",
	"Tip: Goblins are between jobs. All of them. Forever.",
	"Tip: Beezy heals 30. Chipotle Bowls heal 60. Both are a lifestyle.",
	"Tip: Dulbers Frint has a NO REFUNDS policy. He means it.",
	"Tip: If you lose a fight you wake up with something on your forehead.",
	"Tip: Press F1 if you're a developer. Press nothing if you're a legend.",
	"Tip: The giant's eyes are open. He is still asleep. Don't think about it.",
]
var _load_layer: CanvasLayer
var _load_bg: ColorRect
var _load_lbl: Label
var _load_tip: Label
var changing := false

# Walk to another area you've already finished (Asar: go back and forth between areas). The next area resumes in free roam
# at the edge you came from (Level.arrival). If that area isn't finished yet, its story just starts normally.
func travel(path: String, from_key: String, leader_id: String) -> void:
	pending_resume = { "pos": Vector3.INF, "from": from_key, "leader": leader_id, "travel": true }
	goto(path)

func goto(path: String) -> void:
	if changing:
		return
	changing = true
	_ensure_loading_ui()
	_load_tip.text = LOADING_TIPS[randi() % LOADING_TIPS.size()]
	_load_layer.visible = true
	var tw := create_tween()
	tw.tween_property(_load_bg, "modulate:a", 1.0, 0.25)
	await tw.finished
	await get_tree().process_frame   # let the card draw before the (slow) scene build
	await get_tree().process_frame
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_load_bg, "modulate:a", 0.0, 0.45)
	await tw2.finished
	_load_layer.visible = false
	changing = false

func _ensure_loading_ui() -> void:
	if _load_layer:
		return
	_load_layer = CanvasLayer.new()
	_load_layer.layer = 100
	add_child(_load_layer)
	_load_bg = ColorRect.new()
	_load_bg.color = Color(0.03, 0.02, 0.06)
	_load_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_load_bg.modulate.a = 0.0
	_load_layer.add_child(_load_bg)
	_load_lbl = Label.new()
	_load_lbl.text = "Loading…"
	_load_lbl.add_theme_font_size_override("font_size", 34)
	_load_lbl.add_theme_color_override("font_color", Color("#e8b923"))
	_load_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_load_bg.add_child(_load_lbl)
	_load_tip = Label.new()
	_load_tip.add_theme_font_size_override("font_size", 20)
	_load_tip.add_theme_color_override("font_color", Color("#c9c0e8"))
	_load_tip.anchor_left = 0.0; _load_tip.anchor_right = 1.0; _load_tip.anchor_top = 1.0; _load_tip.anchor_bottom = 1.0
	_load_tip.offset_top = -90; _load_tip.offset_bottom = -50
	_load_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_bg.add_child(_load_tip)

# ================================================================ progress across all playthroughs (Asar 11/22)
# "Outcomes x/17 · N% complete" on the title screen. What counts: progress_data.gd. Never reset by New Game.
const PD = preload("res://scripts/progress_data.gd")
const PROGRESS_PATH := "user://progress.cfg"
var progress := {}   # item id -> true

func load_progress() -> void:
	var cf := ConfigFile.new()
	if cf.load(PROGRESS_PATH) == OK and cf.has_section("found"):
		for k in cf.get_section_keys("found"):
			progress[k] = true

func unlock(id: String) -> void:
	if ach and not title_mode:
		ach.event("progress:" + id)   # achievements.gd (before the early return, so new achievements catch up)
	if title_mode or progress.has(id):
		return
	progress[id] = true
	var cf := ConfigFile.new()
	for k in progress:
		cf.set_value("found", k, true)
	cf.save(PROGRESS_PATH)

func outcomes_total() -> int:
	return PD.ITEMS.filter(func(it): return it[3]).size()

func outcomes_found() -> int:
	return PD.ITEMS.filter(func(it): return it[3] and progress.has(it[0])).size()

func completion_pct() -> int:
	var got := 0
	var total := 0
	for it in PD.ITEMS:
		total += it[2]
		if progress.has(it[0]):
			got += it[2]
	return int(round(100.0 * got / maxf(total, 1)))

# ================================================================ settings (saved to user://settings.cfg)
const SETTINGS_PATH := "user://settings.cfg"
const QUALITY := ["Low", "Medium", "High"]
const TEXT_SPEED := ["Slow", "Normal", "Fast", "Instant"]
const TEXT_SPEED_MULT := [1.6, 1.0, 0.5, 0.0]
var master_vol := 0.8             # 0..1
var voice_vol := 1.0              # 0..1 (TTS + recorded lines)
var fullscreen := false
var vsync := true
var quality := 2                  # 0 Low · 1 Medium · 2 High
var text_speed := 1               # index into TEXT_SPEED
var music_once := false           # Settings → Music: play each area song once instead of looping (Ebain's note)
var cam_speed := 1.0              # camera turn speed multiplier (0.4 .. 2.0)
# Dialogue controls (Ebain 11/23). dialogue.gd reads these.
const DLG_BUFFER := ["Off", "Short", "Normal", "Long"]   # wait after a line is fully shown before E can advance
const DLG_BUFFER_SEC := [0.0, 0.2, 0.4, 0.8]
var dlg_buffer := 2               # index into DLG_BUFFER
var dlg_back := true              # Backspace goes back one line
var dlg_speed := false            # speed mode: no buffer (spam E) + 2x text. Turned on with the button on the dialogue box
# UI overhaul (Ebain 11/24): menu theme + sizes (ui_theme.gd), music/SFX buses (made in _make_buses), key rebinding (keybinds.gd)
signal ui_changed                 # theme / sizes changed: open menus restyle
var music_vol := 0.8              # 0..1, the "Music" bus (title, area songs, Library)
var sfx_vol := 0.9                # 0..1, the "SFX" bus (every other sound; dialogue voice lines stay on Voice volume)
var ui_theme := 0                 # index into UITheme.NAMES
var ui_scale := 1.0               # whole UI (root content_scale_factor), 0.8 .. 1.3
var text_scale := 1.0             # menu text, 0.85 .. 1.3
var ui_bouncy := true             # Menu animations: Bouncy / Calm

# Achievements (achievements.gd): the popup layer lives on Game so it survives scene changes.
var ach: Achievements

func achieve(id: String) -> void:
	if ach:
		ach.give(id)

func _ready() -> void:
	ach = Achievements.new()
	add_child(ach)
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(load("res://scripts/crash_reporter.gd").new())   # crash/freeze reports (see crash_reporter.gd)
	load_progress()
	_make_buses()
	load_settings()
	apply_settings()

func _input(ev: InputEvent) -> void:
	# F11 or Alt+Enter: fullscreen, anywhere
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_F11 or (ev.keycode == KEY_ENTER and ev.alt_pressed):
			fullscreen = not fullscreen
			apply_settings()
			save_settings()
			get_viewport().set_input_as_handled()

func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(SETTINGS_PATH) != OK:
		return
	master_vol = cf.get_value("audio", "master", master_vol)
	voice_vol = cf.get_value("audio", "voice", voice_vol)
	tts_on = cf.get_value("audio", "voices_on", tts_on)
	fullscreen = cf.get_value("display", "fullscreen", fullscreen)
	vsync = cf.get_value("display", "vsync", vsync)
	quality = cf.get_value("display", "quality", quality)
	text_speed = cf.get_value("game", "text_speed", text_speed)
	music_once = cf.get_value("audio", "music_once", music_once)
	cam_speed = cf.get_value("game", "cam_speed", cam_speed)
	difficulty = cf.get_value("game", "difficulty", difficulty)
	timed_auto = cf.get_value("game", "timed_auto", timed_auto)
	dlg_buffer = clampi(int(cf.get_value("game", "dlg_buffer", dlg_buffer)), 0, 3)
	dlg_back = cf.get_value("game", "dlg_back", dlg_back)
	dlg_speed = cf.get_value("game", "dlg_speed", dlg_speed)
	music_vol = cf.get_value("audio", "music", music_vol)
	sfx_vol = cf.get_value("audio", "sfx", sfx_vol)
	ui_theme = clampi(int(cf.get_value("ui", "theme", ui_theme)), 0, UITheme.NAMES.size() - 1)
	ui_scale = clampf(float(cf.get_value("ui", "scale", ui_scale)), 0.8, 1.3)
	text_scale = clampf(float(cf.get_value("ui", "text_scale", text_scale)), 0.85, 1.3)
	ui_bouncy = cf.get_value("ui", "bouncy", ui_bouncy)
	Keybinds.load_from(cf)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master", master_vol)
	cf.set_value("audio", "voice", voice_vol)
	cf.set_value("audio", "voices_on", tts_on)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "vsync", vsync)
	cf.set_value("display", "quality", quality)
	cf.set_value("game", "text_speed", text_speed)
	cf.set_value("audio", "music_once", music_once)
	cf.set_value("game", "cam_speed", cam_speed)
	cf.set_value("game", "difficulty", difficulty)
	cf.set_value("game", "timed_auto", timed_auto)
	cf.set_value("game", "dlg_buffer", dlg_buffer)
	cf.set_value("game", "dlg_back", dlg_back)
	cf.set_value("game", "dlg_speed", dlg_speed)
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.set_value("ui", "theme", ui_theme)
	cf.set_value("ui", "scale", ui_scale)
	cf.set_value("ui", "text_scale", text_scale)
	cf.set_value("ui", "bouncy", ui_bouncy)
	Keybinds.save_to(cf)
	cf.save(SETTINGS_PATH)

# Audio + window. (Graphics quality is applied per area by Level.apply_graphics().)
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(master_vol, 0.0001)))
	AudioServer.set_bus_mute(0, master_vol <= 0.001)
	for b in [["Music", music_vol], ["SFX", sfx_vol]]:
		var i := AudioServer.get_bus_index(b[0])
		if i >= 0:
			AudioServer.set_bus_volume_db(i, linear_to_db(maxf(b[1], 0.0001)))
			AudioServer.set_bus_mute(i, b[1] <= 0.001)
	if get_tree():
		get_tree().root.content_scale_factor = ui_scale
	ui_changed.emit()
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var lv = get_tree().current_scene if get_tree() else null
	if lv and lv.has_method("apply_graphics"):
		lv.apply_graphics()

# Music + SFX buses (no bus layout file: made here). Every new AudioStreamPlayer left on Master goes to SFX,
# except dialogue voice lines (dialogue.gd `_vo`, already on Voice volume). Music players set bus = &"Music"
# BEFORE add_child (title.gd, area_music.gd, library_ui.gd). A player with its own bus (pass.gd snore) is left alone.
func _make_buses() -> void:
	for n in ["Music", "SFX"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, &"Master")
	get_tree().node_added.connect(_route_audio)

func _route_audio(n: Node) -> void:
	if not (n is AudioStreamPlayer or n is AudioStreamPlayer3D) or n.bus != &"Master":
		return
	var p := n.get_parent()
	if p and p.get("_vo") == n:
		return
	n.bus = &"SFX"

# ================================================================ saves (user://saves/<slot>.sav)
# A save holds the game state, the area, and — if the area was in free roam — where you stood.
# Story scenes that can't be resumed halfway save the state from when you ENTERED the area instead,
# so loading replays that area from its start (never a half-finished cutscene).
const SAVE_DIR := "user://saves"
const SLOTS := ["auto", "1", "2", "3"]
var area_snapshot := {}           # state when the current area began
var pending_resume := {}          # set by load_game, used once by the next area
var title_mode := false           # the title screen is showing the camp in the background

func state_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true), "bags": bags.duplicate(true), "gear_owner": gear_owner.duplicate(), "key_owner": key_owner.duplicate(), "xp": xp, "level": level,
		"gear_owned": gear_owned.duplicate(), "equipped": equipped.duplicate(true), "boosts": boosts.duplicate(true), "hurt": hurt.duplicate(), "map_seen": map_seen.duplicate(true), "visited": visited.duplicate(), "gold": gold, "used67": used67,
		"forehead": forehead, "quests": quests.duplicate(true),
	}

func apply_state(d: Dictionary) -> void:
	reset()
	flags = d.get("flags", {}).duplicate(true)
	bags = d.get("bags", {}).duplicate(true)
	gear_owner = d.get("gear_owner", {}).duplicate()
	key_owner = d.get("key_owner", {}).duplicate()
	if d.has("inv"):   # old saves had one shared bag: it all goes to Lykor
		for k in d["inv"]:
			if int(d["inv"][k]) > 0:
				add_item(k, int(d["inv"][k]), "lykor")
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	gear_owned = d.get("gear_owned", []).duplicate()
	equipped = _migrate_equipped(d.get("equipped", {}))
	gold = int(d.get("gold", 0))
	boosts = d.get("boosts", {}).duplicate(true)
	hurt = d.get("hurt", {}).duplicate()
	map_seen = d.get("map_seen", {}).duplicate(true)
	visited = d.get("visited", []).duplicate()
	for old_id in CombatD.BOOSTS:   # older saves had these as trinkets: put them in the bag instead
		if gear_owned.has(old_id):
			gear_owned.erase(old_id)
			var w := wearer(old_id)
			if not w.is_empty():
				unequip(w[0], w[1])
			add_item(old_id, 1, "lykor" if old_id == "conditioner" else "xylo")
	for g in gear_owned:   # older saves: gear belongs to whoever wears it, else Lykor
		if not gear_owner.has(g):
			var w2 := wearer(g)
			gear_owner[g] = w2[0] if not w2.is_empty() else "lykor"
	used67 = d.get("used67", false)
	forehead = d.get("forehead", "")
	quests = d.get("quests", {}).duplicate(true)

# Called by every area when it starts (not in title/test mode)
func area_entered(lv: Node) -> void:
	if pending_resume.is_empty():
		area_snapshot = state_dict()
	pending_resume = {}
	save_game("auto", lv)

func save_game(slot: String, lv: Node) -> bool:
	var resume := {}
	if lv.has_method("can_resume") and lv.can_resume():
		resume = { "pos": lv.leader.global_position, "leader": lv.leader.id, "yaw": lv.target_yaw }
	var data := {
		"version": 1,
		"scene": lv.scene_file_path,
		"label": lv.subtitle,
		"time": Time.get_unix_time_from_system(),
		"level": level,
		"state": state_dict() if not resume.is_empty() else area_snapshot,
		"snapshot": area_snapshot,
		"resume": resume,
	}
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var f := FileAccess.open("%s/%s.sav" % [SAVE_DIR, slot], FileAccess.WRITE)
	if f == null:
		return false
	f.store_var(data)
	return true

func read_save(slot: String) -> Dictionary:
	var path := "%s/%s.sav" % [SAVE_DIR, slot]
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = f.get_var()
	return d if d is Dictionary and d.has("scene") else {}

func latest_slot() -> String:
	var best := ""
	var best_t := -1.0
	for s in SLOTS:
		var d := read_save(s)
		if not d.is_empty() and float(d["time"]) > best_t:
			best_t = float(d["time"])
			best = s
	return best

func load_game(slot: String) -> bool:
	var d := read_save(slot)
	if d.is_empty():
		return false
	title_mode = false
	apply_state(d["state"])
	area_snapshot = d.get("snapshot", d["state"]).duplicate(true)
	pending_resume = d.get("resume", {})
	goto(d["scene"])
	return true

func new_game() -> void:
	title_mode = false
	reset()
	area_snapshot = {}
	pending_resume = {}
	goto("res://main.tscn")

static func save_when(t: float) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(int(t) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%d/%d  %d:%02d" % [dt["month"], dt["day"], dt["hour"], dt["minute"]]
