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
var equipped := {}                # fighter id -> gear id
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

func start_quest(id: String, title: String, note: String) -> void:
	if not quests.has(id):
		quests[id] = { "title": title, "note": note, "state": "active" }

func finish_quest(id: String) -> void:
	if quests.has(id):
		quests[id]["state"] = "done"

func quest_state(id: String) -> String:
	return quests[id]["state"] if quests.has(id) else ""

func goto(path: String) -> void:
	get_tree().change_scene_to_file(path)
