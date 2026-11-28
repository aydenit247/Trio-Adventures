extends Node
# Checks the 11/27 AAA batch without playing: Bestiary matching/saving, the "Previously on" beats, fast-travel rules
# on the World map, the new settings, and the updater staying off outside a Windows build.
#   godot --headless --path godot res://tools/test_aaa.tscn   → "AAA TEST: ALL OK"
# It clears the saved bestiary first, so don't run it on a PC with a real one.
var fails := 0

func check(label: String, ok: bool) -> void:
	if not ok:
		fails += 1
	print(("PASS " if ok else "FAIL ") + label)

func _ready() -> void:
	await get_tree().process_frame
	Game.title_mode = false
	Game.reset()
	# --- Bestiary: every enemy in every fight maps to an entry, entries are unique, saving works
	Bestiary.reset_for_tests()
	var ids := {}
	for en in Bestiary.ENTRIES:
		check("unique bestiary id " + en["id"], not ids.has(en["id"]))
		ids[en["id"]] = true
		check("picture exists for " + en["id"], ResourceLoader.exists("res://assets/characters/%s.png" % en["tex"]))
	var used := {}
	for fk in CombatData.FIGHTS:
		var f: Dictionary = CombatData.FIGHTS[fk]
		for e in f.get("enemies", []) + f.get("adds", []):
			var id := Bestiary.id_for(e)
			check("fight %s enemy %s %s has an entry" % [fk, e["name"], e.get("tag", "")], id != "")
			used[id] = true
	for en in Bestiary.ENTRIES:
		check("entry %s is reachable" % en["id"], used.has(en["id"]))
	check("dulbers demon vs regular", Bestiary.id_for(CombatData.FIGHTS["dulbers"]["enemies"][0]) == "dulbers_demon" and Bestiary.id_for(CombatData.FIGHTS["dulbers_ambush"]["enemies"][0]) == "dulbers")
	check("employee add", Bestiary.id_for(CombatData.FIGHTS["dulbers"]["adds"][0]) == "mart_employee")
	check("nothing seen at start", Bestiary.seen_count() == 0)
	Bestiary.saw(CombatData.FIGHTS["goblin_patrol"]["enemies"])
	check("saw 3 patrol goblins", Bestiary.seen_count() == 3)
	Bestiary.beat(CombatData.FIGHTS["goblins"]["enemies"])
	check("beat 3 goblins counts 3", Bestiary.beaten("goblin") == 3)
	Bestiary._loaded = false
	Bestiary._seen = {}
	Bestiary._beaten = {}
	check("bestiary saved + reloaded", Bestiary.seen_count() == 4 and Bestiary.beaten("goblin") == 3)
	Bestiary.reset_for_tests()
	# --- Recap beats: built from this run, in story order
	Game.reset()
	check("no beats on a fresh run", Recap.beats().is_empty())
	Game.flags["campLit"] = true
	Game.flags["way_village"] = "chug"
	Game.flags["way_troll"] = "good"
	Game.flags["way_mart"] = "refuse"
	var bt := Recap.beats()
	var heads := bt.map(func(b): return b["head"])
	check("recap order camp, troll, throne, mart: %s" % [heads], heads == ["THE CAMP", "THE BRIDGE TROLL", "THE GOBLIN THRONE", "METOCY MART"])
	check("recap beat has outcome text", str(bt[2]["big"]).begins_with("Challenged the Chief"))
	check("recap beat has a quote", bt[2].has("quote"))
	# --- fast travel rules (MapUI.can_travel needs a level: use a stub with area_key/can_resume)
	Game.reset()
	var m := MapUI.new()
	m.lv = StubLevel.new()
	add_child(m.lv)
	check("nothing to travel to on a new game", m.travel_targets().is_empty())
	Game.visited = ["camp", "trail", "village", "mart"]
	Game.flags["campDone"] = true
	Game.flags["trailDone"] = true
	Game.flags["villageOpen"] = true
	check("camp/trail/village travelable, not mart (story not done), not here: %s" % [m.travel_targets()], m.travel_targets() == ["camp", "trail"])
	Game.flags["martDone"] = true
	Game.visited.append("ruins")
	Game.flags["ruinsStarted"] = true
	check("mart + ruins once done: %s" % [m.travel_targets()], m.travel_targets() == ["camp", "trail", "mart", "ruins"])
	check("travel ok in free roam", m.travel_ok())
	m.lv.roam = false
	check("no travel during a scene", not m.travel_ok())
	for k in MapUI.FAST:
		check("fast travel scene exists " + k, ResourceLoader.exists(MapUI.FAST[k][0]))
	m.free()
	# --- settings + updater
	check("Ultra quality exists", Game.QUALITY.size() == 4)
	check("updater off outside Windows builds", not Updater.enabled())
	check("color grade curve", AreaFx._curve(Color(0, 0, 0), Color(1, 1, 1)) is GradientTexture1D)
	print("AAA TEST: ALL OK" if fails == 0 else "AAA TEST: %d FAILED" % fails)
	get_tree().quit()

class StubLevel extends Node:
	var roam := true
	var t := 0.0
	var leader = null
	func area_key() -> String: return "village"
	func can_resume() -> bool: return roam
