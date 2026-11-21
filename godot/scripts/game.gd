# Global game state (autoload "Game"): story flags, items, XP/levels, gear and settings that carry between areas.
extends Node

const LEVELS := [0, 0, 50, 120, 220, 350, 520, 740, 1000, 1300, 1650]

# Story flags, same names as the web game:
# goblinAllies, skornKing, chugWon, lykorDethroned, foreheadLoser, bag_checked, ...
var flags := {}
var inv := { "beer": 0, "bowl": 0 }
var tts_on := true

# progression (shared party level, like the web version)
var xp := 0
var level := 1
var gear_owned: Array = []        # gear ids found so far
var equipped := {}                # fighter id -> { slot -> gear id }   (slots: GEAR_SLOTS below; gear slot types in CombatD.GEAR)
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

func reset() -> void:
	flags = {}
	inv = { "beer": 0, "bowl": 0 }
	xp = 0
	level = 1
	gear_owned = []
	equipped = {}
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
	return out

func xp_to_next() -> int:
	return LEVELS[level + 1] - xp if level + 1 < LEVELS.size() else 0

func give_gear(id: String) -> bool:
	if gear_owned.has(id):
		return false
	gear_owned.append(id)
	return true

func add_gold(n: int) -> void:
	gold = max(0, gold + n)

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
	return slot

# Everything a fighter's gear adds up to, in the same shape as one CombatD.GEAR entry (battle.gd reads this).
func gear_stats(fighter: String) -> Dictionary:
	var out := { "hp": 0, "power": 0.0, "spd": 0, "start": 0, "meter": 1.0 }
	for s in slots_of(fighter):
		var G: Dictionary = CombatD.GEAR.get(slots_of(fighter)[s], {})
		out["hp"] += G.get("hp", 0)
		out["power"] += G.get("power", 0.0)
		out["spd"] += G.get("spd", 0)
		out["start"] = mini(100, out["start"] + G.get("start", 0))
		out["meter"] *= G.get("meter", 1.0)
		for k in ["no_ones", "gouge_proof"]:
			if G.get(k, false):
				out[k] = true
	return out

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
var cam_speed := 1.0              # camera turn speed multiplier (0.4 .. 2.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	cam_speed = cf.get_value("game", "cam_speed", cam_speed)
	difficulty = cf.get_value("game", "difficulty", difficulty)
	timed_auto = cf.get_value("game", "timed_auto", timed_auto)

func save_settings() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "master", master_vol)
	cf.set_value("audio", "voice", voice_vol)
	cf.set_value("audio", "voices_on", tts_on)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "vsync", vsync)
	cf.set_value("display", "quality", quality)
	cf.set_value("game", "text_speed", text_speed)
	cf.set_value("game", "cam_speed", cam_speed)
	cf.set_value("game", "difficulty", difficulty)
	cf.set_value("game", "timed_auto", timed_auto)
	cf.save(SETTINGS_PATH)

# Audio + window. (Graphics quality is applied per area by Level.apply_graphics().)
func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(master_vol, 0.0001)))
	AudioServer.set_bus_mute(0, master_vol <= 0.001)
	if DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != want and not (want == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
			DisplayServer.window_set_mode(want)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var lv = get_tree().current_scene if get_tree() else null
	if lv and lv.has_method("apply_graphics"):
		lv.apply_graphics()

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
		"flags": flags.duplicate(true), "inv": inv.duplicate(true), "xp": xp, "level": level,
		"gear_owned": gear_owned.duplicate(), "equipped": equipped.duplicate(true), "gold": gold, "used67": used67,
		"forehead": forehead, "quests": quests.duplicate(true),
	}

func apply_state(d: Dictionary) -> void:
	reset()
	flags = d.get("flags", {}).duplicate(true)
	inv = d.get("inv", { "beer": 0, "bowl": 0 }).duplicate(true)
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	gear_owned = d.get("gear_owned", []).duplicate()
	equipped = _migrate_equipped(d.get("equipped", {}))
	gold = int(d.get("gold", 0))
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
